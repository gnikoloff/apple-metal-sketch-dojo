//
//  CascadedShadowsMap.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

// swiftlint:disable identifier_name type_body_length function_body_length

import MetalKit

final class CascadedShadowsMap: ExampleScreen {
  private static let CUBES_COUNT = 20
  private static let CUBES_POS_RADIUS: Float = 3.5
  private static let CAMERA_NEAR: Float = 0.05
  private static let CAMERA_FAR: Float = 100
  private static let SHADOW_RESOLUTION = 1024
  private static let SHADOW_CASCADE_LEVELS_COUNT = 3
  private static let SHADOW_CASCADE_ZMULT: Float = 4
  private static var SHADOW_CASCADE_LEVELS: [Float] {
    get {
      return [
        3,
        7,
        16,
        50
      ]
    }
  }
  private static let SUN_POSITION = float3(10, 10, 10)

  var options: Options
  var outputTexture: MTLTexture!
  var outputDepthTexture: MTLTexture!

  var outputPassDescriptor: MTLRenderPassDescriptor
  private let shadowPassDescriptor: MTLRenderPassDescriptor
  private let debugCamPassDescriptor: MTLRenderPassDescriptor

  private let cameraBuffer: MTLBuffer
  private let debugCameraBuffer: MTLBuffer
  private let lightMatricesBuffer: MTLBuffer
  private let frustumPartitionsVertexBuffer: MTLBuffer
  private let frustumPartitionsLightSpaceVertexBuffer: MTLBuffer

  private let floorPipelineState: MTLRenderPipelineState
  private let cubesPipelineState: MTLRenderPipelineState
  private let floorPipelineDebugState: MTLRenderPipelineState
  private let cubesPipelineDebugState: MTLRenderPipelineState

  private var camDebugTexture: MTLTexture!
  private var camDebugDepthTexture: MTLTexture!
  private var shadowDepthTexture: MTLTexture

  private let depthStencilState: MTLDepthStencilState?

  private let floorShadowPipelineState: MTLRenderPipelineState
  private let cubesShadowPipelineState: MTLRenderPipelineState

  private let debugCSMFrustumPipelineState: MTLRenderPipelineState

  private let debugCSMCameraFrustumPipelineState: MTLRenderPipelineState
  private let debugCSMLightSpaceFrustumPipelineState: MTLRenderPipelineState

  private var lightMatrices: [float4x4] = []
  private var debugCamera = PerspectiveCamera()
  private var arcballCamera = ArcballCamera()
  private var cube: Sphere
  private var floor: Plane
  private var csmFrustumDebugger: Cube

  private var texturesDebugger: CascadedShadowsMap_TexturesDebugger

  lazy private var supportsLayerSelection: Bool = {
    Renderer.device.supportsFamily(MTLGPUFamily.mac2) || Renderer.device.supportsFamily(MTLGPUFamily.apple5)
  }()

  lazy private var paramsBuffer: MTLBuffer = {
    Self.createParamsBuffer(lightsCount: 2)
  }()

  lazy private var floorMaterialBuffer: MTLBuffer = {
    var material = Material(
      shininess: 2,
      baseColor: float3(repeating: 1),
      specularColor: float3(1, 0, 0),
      roughness: 0.7,
      metallic: 0.1,
      ambientOcclusion: 0,
      opacity: 1
    )
    return Renderer.device.makeBuffer(bytes: &material, length: MemoryLayout<Material>.stride)!
  }()

  lazy private var lightsBuffer: MTLBuffer = {
    var dirLight = Self.buildDefaultLight()
    dirLight.position = Self.SUN_POSITION
    dirLight.color = float3(repeating: 1)
    var ambientLight = Self.buildDefaultLight()
    ambientLight.type = Ambient
    ambientLight.color = float3(repeating: 0.4)
    return Self.createLightBuffer(lights: [dirLight, ambientLight])
  }()

  lazy private var cubesInstancesBuffer: MTLBuffer = {
    let buffer = Renderer.device.makeBuffer(
      length: MemoryLayout<float4x4>.stride * Self.CUBES_COUNT * Self.SHADOW_CASCADE_LEVELS_COUNT
    )!
    let buffPointer = buffer
      .contents()
      .bindMemory(to: float4x4.self, capacity: Self.CUBES_COUNT * Self.SHADOW_CASCADE_LEVELS_COUNT)
    let spacer = Float.pi * 2 / Float(Self.CUBES_COUNT)
    for i in 0 ..< Self.CUBES_COUNT {
      let fi = Float(i)
      let x: Float = i % 2 == 0 ? -1 : 1
      let pos = float3(
        cos(fi * spacer) * Self.CUBES_POS_RADIUS,
//        cos(fi * 2) * 3 + 4,
        0,
        sin(fi * spacer) * Self.CUBES_POS_RADIUS
//        0, 0, 0
      )
      for n in 0 ..< Self.SHADOW_CASCADE_LEVELS_COUNT {
        let translateMatrix = float4x4(translation: pos)
        let rotateMatrix = float4x4(eye: pos, center: float3(repeating: 0), up: float3(0, 1, 0))

        buffPointer[i + n * Self.CUBES_COUNT] = translateMatrix
      }
    }
    return buffer
  }()

  lazy private var settingsBuffer: MTLBuffer = {
    var buffer = Renderer.device.makeBuffer(
      length: MemoryLayout<CascadedShadowsMap_Settings>.stride
    )!
    var buffPointer = buffer
      .contents()
      .bindMemory(to: CascadedShadowsMap_Settings.self, capacity: 1)
    let ff: Float = 0
    let cascadePlaneDistances = (
      Self.SHADOW_CASCADE_LEVELS[0],
      Self.SHADOW_CASCADE_LEVELS[1],
      Self.SHADOW_CASCADE_LEVELS[2],
      Self.SHADOW_CASCADE_LEVELS[3]
    )
    let texRes = Float(Self.SHADOW_RESOLUTION)
    buffPointer.pointee = CascadedShadowsMap_Settings(
      cubesCount: uint(Self.CUBES_COUNT),
      cascadesCount: uint(Self.SHADOW_CASCADE_LEVELS_COUNT + 1),
      cascadePlaneDistances: cascadePlaneDistances,
      shadowTexSize: [texRes, texRes]
    )
    return buffer
  }()

  init(options: Options) {
    self.options = options

    do {
      try floorPipelineState = CascadedShadowsMap_PipelineStates.createMeshPSO()
      try cubesPipelineState = CascadedShadowsMap_PipelineStates.createMeshPSO(
        instancesHaveUniquePositions: true
      )
      try floorPipelineDebugState = CascadedShadowsMap_PipelineStates.createMeshPSO(
        usesDebugCamera: true
      )
      try cubesPipelineDebugState = CascadedShadowsMap_PipelineStates.createMeshPSO(
        instancesHaveUniquePositions: true,
        usesDebugCamera: true
      )
      try floorShadowPipelineState = CascadedShadowsMap_PipelineStates.createShadowPSO()
      try cubesShadowPipelineState = CascadedShadowsMap_PipelineStates.createShadowPSO(
        instancesHaveUniquePositions: true
      )
      try debugCSMFrustumPipelineState = CascadedShadowsMap_PipelineStates.makeCSMFrustumDebuggerPipelineState()
      try debugCSMCameraFrustumPipelineState = CascadedShadowsMap_PipelineStates.makeCSMVertexlessPipelineState()
      try debugCSMLightSpaceFrustumPipelineState = CascadedShadowsMap_PipelineStates.makeCSMVertexlessPipelineState(
        isLightSpaceFrustumVerticesDebug: true
      )
    } catch {
      fatalError(error.localizedDescription)
    }

    outputPassDescriptor = MTLRenderPassDescriptor()
    shadowPassDescriptor = MTLRenderPassDescriptor()
    debugCamPassDescriptor = MTLRenderPassDescriptor()

    depthStencilState = Self.buildDepthStencilState()

    shadowDepthTexture = TextureController.makeTexture(
      size: CGSize(width: Self.SHADOW_RESOLUTION, height: Self.SHADOW_RESOLUTION),
      pixelFormat: .depth32Float,
      label: "Shadow Depth Texture",
      type: .type2DArray,
      arrayLength: Self.SHADOW_CASCADE_LEVELS_COUNT
    )!

    cameraBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<CameraUniforms>.stride,
      options: []
    )!
    debugCameraBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<CameraUniforms>.stride,
      options: []
    )!
    lightMatricesBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<float4x4>.stride * Self.SHADOW_CASCADE_LEVELS_COUNT,
      options: []
    )!
    frustumPartitionsVertexBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<float3>.stride * 8 * Self.SHADOW_CASCADE_LEVELS_COUNT
    )!
    frustumPartitionsLightSpaceVertexBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<float3>.stride * 8 * Self.SHADOW_CASCADE_LEVELS_COUNT
    )!

    arcballCamera.distance = 6
    debugCamera.position = float3(10, 10, 10)

    cube = Sphere(size: 1)
    floor = Plane(size: float3(20, 20, 1))
    csmFrustumDebugger = Cube(size: float3(repeating: 1), geometryType: .lines)
    csmFrustumDebugger.primitiveType = .line

    floor.position.y = -0.5
    floor.rotation.x = .pi * 0.5

    texturesDebugger = CascadedShadowsMap_TexturesDebugger(
      cascadesCount: Self.SHADOW_CASCADE_LEVELS_COUNT
    )
  }

  func getLightSpaceMatrix(idx: Int, nearPlane: Float, farPlane: Float) -> (float4x4, float3) {
    arcballCamera.near = nearPlane
    arcballCamera.far = farPlane
    let frustumWorldSpaceCorners = arcballCamera.getFrustumCornersWorldSpace()

    let pointsInFrustum = 8
    let frustumVertexBufferPtr = frustumPartitionsVertexBuffer
      .contents()
      .bindMemory(
        to: float3.self,
        capacity: pointsInFrustum * Self.SHADOW_CASCADE_LEVELS_COUNT
      )

    if idx != Self.SHADOW_CASCADE_LEVELS_COUNT + 1 {
      for i in 0 ..< pointsInFrustum {
        frustumVertexBufferPtr[idx * pointsInFrustum + i] = frustumWorldSpaceCorners[i].xyz
      }
    }

    var center = float3(repeating: 0)
    for corner in frustumWorldSpaceCorners {
      center += corner.xyz
    }
    center /= frustumWorldSpaceCorners.count



    let frustumLightSpaceVertexBuffPtr = frustumPartitionsLightSpaceVertexBuffer
      .contents()
      .bindMemory(
        to: float3.self,
        capacity: pointsInFrustum * Self.SHADOW_CASCADE_LEVELS_COUNT
      )


    frustumLightSpaceVertexBuffPtr[idx * pointsInFrustum + 0] = center + float3(-1, 0, 0)
    frustumLightSpaceVertexBuffPtr[idx * pointsInFrustum + 1] = center + float3(1, 0, 0)
    frustumLightSpaceVertexBuffPtr[idx * pointsInFrustum + 2] = center + float3(0, -1, 0)
    frustumLightSpaceVertexBuffPtr[idx * pointsInFrustum + 3] = center + float3(0, 1, 0)
    frustumLightSpaceVertexBuffPtr[idx * pointsInFrustum + 4] = center
    frustumLightSpaceVertexBuffPtr[idx * pointsInFrustum + 5] = center + Self.SUN_POSITION



    let viewMatrix = float4x4(
      eye: center + Self.SUN_POSITION,
      center: center,
      up: float3(0, 1, 0)
    )

    var minX = Float.greatestFiniteMagnitude
    var maxX = -minX
    var minY = Float.greatestFiniteMagnitude
    var maxY = -minY
    var minZ = Float.greatestFiniteMagnitude
    var maxZ = -minZ
    for corner in frustumWorldSpaceCorners {
      let trf = viewMatrix * corner
      minX = min(minX, trf.x)
      maxX = max(maxX, trf.x)
      minY = min(minY, trf.y)
      maxY = max(maxY, trf.y)
      minZ = min(minZ, trf.z)
      maxZ = max(maxZ, trf.z)
    }

    // Tune this parameter according to the scene

    if minZ < 0 {
      minZ *= Self.SHADOW_CASCADE_ZMULT
    } else {
      minZ /= Self.SHADOW_CASCADE_ZMULT
    }
    if maxZ < 0 {
      maxZ /= Self.SHADOW_CASCADE_ZMULT
    } else {
      maxZ *= Self.SHADOW_CASCADE_ZMULT
    }

    let projMatrix = float4x4(
      left: minX,
      right: maxX,
      bottom: minY,
      top: maxY,
      near: minZ,
      far: maxZ
    )

    return (projMatrix * viewMatrix, center +  Self.SUN_POSITION)
//
////    print("minX \(minX) maxX \(maxX) minY \(minY) maxY \(maxY) near \(minZ) far \(maxZ)")
//
  }

  func resize(view: MTKView) {
    let size = options.drawableSize
    outputDepthTexture = Self.createDepthOutputTexture(size: size)
    outputTexture = Self.createOutputTexture(
      size: size,
      label: "Cascaded Shadow Maps Output texture"
    )
    camDebugTexture = TextureController.makeTexture(
      size: size,
      pixelFormat: Renderer.viewColorFormat,
      label: "Debug Arcball Camera texture"
    )
    camDebugDepthTexture = TextureController.makeTexture(
      size: size,
      pixelFormat: .depth32Float,
      label: "Debug Arcball Camera Depth texture"
    )

    arcballCamera.update(size: size)
    debugCamera.update(size: size)
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    arcballCamera.update(deltaTime: deltaTime)

//    model0.update(deltaTime: deltaTime)

//    model.update(deltaTime: deltaTime)

  }

  func updateUniforms() {
    let cameraBuffPtr = cameraBuffer
      .contents()
      .bindMemory(to: CameraUniforms.self, capacity: 1)
    let debugCameraBuffPtr = debugCameraBuffer
      .contents()
      .bindMemory(to: CameraUniforms.self, capacity: 1)

    cameraBuffPtr.pointee.position = arcballCamera.position
    cameraBuffPtr.pointee.projectionMatrix = arcballCamera.projectionMatrix
    cameraBuffPtr.pointee.viewMatrix = arcballCamera.viewMatrix

    debugCameraBuffPtr.pointee.position = debugCamera.position
    debugCameraBuffPtr.pointee.projectionMatrix = debugCamera.projectionMatrix
    debugCameraBuffPtr.pointee.viewMatrix = debugCamera.viewMatrix

    cameraBuffPtr.pointee.near = Self.CAMERA_NEAR
    cameraBuffPtr.pointee.far = Self.CAMERA_FAR

    let lightMatricesPtr = lightMatricesBuffer
      .contents()
      .bindMemory(to: float4x4.self, capacity: Self.SHADOW_CASCADE_LEVELS_COUNT)

    var vectors: [float3] = []
    for i in 0 ..< Self.SHADOW_CASCADE_LEVELS_COUNT + 1 {
      var lightMatrix: float4x4
      if i == 0 {
        let (_lightMatrix, v) = getLightSpaceMatrix(
          idx: i,
          nearPlane: Self.CAMERA_NEAR,
          farPlane: Self.SHADOW_CASCADE_LEVELS[i]
        )
        lightMatrix = _lightMatrix
        vectors.append(v)
      } else if i < Self.SHADOW_CASCADE_LEVELS_COUNT {
        let (_lightMatrix, v) = getLightSpaceMatrix(
          idx: i,
          nearPlane: Self.SHADOW_CASCADE_LEVELS[i - 1],
          farPlane: Self.SHADOW_CASCADE_LEVELS[i]
        )
        lightMatrix = _lightMatrix
        vectors.append(v)
      } else {
        let (_lightMatrix, v) = getLightSpaceMatrix(
          idx: i,
          nearPlane: Self.SHADOW_CASCADE_LEVELS[i - 1],
          farPlane: Self.CAMERA_FAR
        )
        lightMatrix = _lightMatrix
        vectors.append(v)
      }
      lightMatricesPtr[i] = lightMatrix
    }

//    print(vectors[0].isParallelTo(vectors[1]))
//    print(vectors[1].isParallelTo(vectors[2]))
//    print(vectors[2].isParallelTo(vectors[3]))

    arcballCamera.near = Self.CAMERA_NEAR
    arcballCamera.far = Self.CAMERA_FAR
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    updateUniforms()
    let descriptor = view.currentRenderPassDescriptor!

    shadowPassDescriptor.depthAttachment.texture = shadowDepthTexture
    shadowPassDescriptor.depthAttachment.loadAction = .clear
    shadowPassDescriptor.depthAttachment.storeAction = .store
    shadowPassDescriptor.renderTargetArrayLength = Self.SHADOW_CASCADE_LEVELS_COUNT

    guard let shadowRenderEncoder = commandBuffer.makeRenderCommandEncoder(
      descriptor: shadowPassDescriptor
    ) else {
      return
    }

    shadowRenderEncoder.setVertexBuffer(
      lightMatricesBuffer,
      offset: 0,
      index: LightsMatricesBuffer.index
    )
    shadowRenderEncoder.setVertexBuffer(
      cubesInstancesBuffer,
      offset: 0,
      index: CubeInstancesBuffer.index
    )
    shadowRenderEncoder.setVertexBuffer(
      settingsBuffer,
      offset: 0,
      index: SettingsBuffer.index
    )

    shadowRenderEncoder.setDepthStencilState(depthStencilState)

    shadowRenderEncoder.setRenderPipelineState(cubesShadowPipelineState)
    cube.instanceCount = Self.CUBES_COUNT * Self.SHADOW_CASCADE_LEVELS_COUNT
//    cube.cullMode = .front
    cube.draw(renderEncoder: shadowRenderEncoder)
//    cube.cullMode = .back

    shadowRenderEncoder.setRenderPipelineState(floorShadowPipelineState)
    floor.instanceCount = Self.SHADOW_CASCADE_LEVELS_COUNT
//    floor.cullMode = .front
    floor.draw(renderEncoder: shadowRenderEncoder)
//    floor.cullMode = .back



    shadowRenderEncoder.endEncoding()
//
    debugCamPassDescriptor.colorAttachments[0].texture = camDebugTexture
    debugCamPassDescriptor.colorAttachments[0].loadAction = .clear
    debugCamPassDescriptor.colorAttachments[0].storeAction = .store
    debugCamPassDescriptor.depthAttachment.texture = camDebugDepthTexture
    debugCamPassDescriptor.depthAttachment.loadAction = .clear
    debugCamPassDescriptor.depthAttachment.storeAction = .store

//    guard let debugRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: debugCamPassDescriptor) else {
//      return
//    }

    guard let debugRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    debugRenderEncoder.setVertexBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    debugRenderEncoder.setVertexBuffer(
      debugCameraBuffer,
      offset: 0,
      index: DebugCameraBuffer.index
    )
    debugRenderEncoder.setVertexBuffer(
      cubesInstancesBuffer,
      offset: 0,
      index: CubeInstancesBuffer.index
    )
    debugRenderEncoder.setVertexBuffer(
      settingsBuffer,
      offset: 0,
      index: SettingsBuffer.index
    )
    debugRenderEncoder.setVertexBuffer(
      lightMatricesBuffer,
      offset: 0,
      index: LightsMatricesBuffer.index
    )

    debugRenderEncoder.setFragmentBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    debugRenderEncoder.setFragmentBuffer(
      floorMaterialBuffer,
      offset: 0,
      index: MaterialBuffer.index
    )
    debugRenderEncoder.setFragmentBuffer(
      lightsBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    debugRenderEncoder.setFragmentBuffer(
      paramsBuffer,
      offset: 0,
      index: ParamsBuffer.index
    )
    debugRenderEncoder.setFragmentBuffer(
      settingsBuffer,
      offset: 0,
      index: SettingsBuffer.index
    )
    debugRenderEncoder.setFragmentBuffer(
      lightMatricesBuffer,
      offset: 0,
      index: LightsMatricesBuffer.index
    )
    debugRenderEncoder.setFragmentTexture(
      shadowDepthTexture,
      index: ShadowTextures.index
    )

    debugRenderEncoder.setDepthStencilState(depthStencilState)

    debugRenderEncoder.setRenderPipelineState(floorPipelineState)
    floor.instanceCount = 1
    floor.draw(renderEncoder: debugRenderEncoder)

    debugRenderEncoder.setRenderPipelineState(cubesPipelineState)
    cube.instanceCount = Self.CUBES_COUNT
    cube.draw(renderEncoder: debugRenderEncoder)

    texturesDebugger.shadowsDepthTexture = shadowDepthTexture
    texturesDebugger.debugCamTexture = camDebugTexture
    texturesDebugger.draw(encoder: debugRenderEncoder)

    debugRenderEncoder.endEncoding()

//    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
//      return
//    }
//
//    renderEncoder.setVertexBuffer(
//      cameraBuffer,
//      offset: 0,
//      index: CameraUniformsBuffer.index
//    )
//    renderEncoder.setVertexBuffer(
//      debugCameraBuffer,
//      offset: 0,
//      index: DebugCameraBuffer.index
//    )
//    renderEncoder.setVertexBuffer(
//      lightMatricesBuffer,
//      offset: 0,
//      index: LightsMatricesBuffer.index
//    )
//    renderEncoder.setVertexBuffer(
//      cubesInstancesBuffer,
//      offset: 0,
//      index: CubeInstancesBuffer.index
//    )
//
//    renderEncoder.setFragmentBuffer(
//      cameraBuffer,
//      offset: 0,
//      index: CameraUniformsBuffer.index
//    )
//    renderEncoder.setFragmentBuffer(
//      floorMaterialBuffer,
//      offset: 0,
//      index: MaterialBuffer.index
//    )
//    renderEncoder.setFragmentBuffer(
//      settingsBuffer,
//      offset: 0,
//      index: SettingsBuffer.index
//    )
//    renderEncoder.setFragmentBuffer(
//      paramsBuffer,
//      offset: 0,
//      index: ParamsBuffer.index
//    )
//    renderEncoder.setFragmentBuffer(
//      lightMatricesBuffer,
//      offset: 0,
//      index: LightsMatricesBuffer.index
//    )
//    renderEncoder.setFragmentBuffer(
//      lightsBuffer,
//      offset: 0,
//      index: LightBuffer.index
//    )
//
//    renderEncoder.setFragmentTexture(
//      shadowDepthTexture,
//      index: ShadowTextures.index
//    )
//    renderEncoder.setFragmentTexture(
//      camDebugTexture,
//      index: CamDebugTexture.index
//    )
//
//    renderEncoder.setDepthStencilState(depthStencilState)
//
//    renderEncoder.setRenderPipelineState(debugCSMFrustumPipelineState)
//
//    renderEncoder.setRenderPipelineState(floorPipelineDebugState)
//    floor.instanceCount = 1
//    floor.draw(renderEncoder: renderEncoder)
//
//    renderEncoder.setRenderPipelineState(cubesPipelineDebugState)
//    cube.instanceCount = Self.CUBES_COUNT
//    cube.draw(renderEncoder: renderEncoder)
//
//    csmFrustumDebugger.instanceCount = Self.SHADOW_CASCADE_LEVELS_COUNT
//    csmFrustumDebugger.draw(renderEncoder: renderEncoder)
//
////     Draw CSM textures debug
//    renderEncoder.setRenderPipelineState(debugCSMTexturesPipelineState)
//    renderEncoder.drawPrimitives(
//      type: .triangle,
//      vertexStart: 0,
//      vertexCount: 6,
//      instanceCount: Self.SHADOW_CASCADE_LEVELS_COUNT
//    )
//
//    // Draw camera texture debug
//    renderEncoder.setRenderPipelineState(debugArcballCameraViewPipelineState)
//    renderEncoder.drawPrimitives(
//      type: .triangle,
//      vertexStart: 0,
//      vertexCount: 6
//    )
//
//    renderEncoder.setRenderPipelineState(debugCSMCameraFrustumPipelineState)
////
//    renderEncoder.setVertexBuffer(
//      frustumPartitionsVertexBuffer,
//      offset: 0,
//      index: VertexBuffer.index
//    )
//    renderEncoder.drawPrimitives(
//      type: .line,
//      vertexStart: 0,
//      vertexCount: 8,
//      instanceCount: Self.SHADOW_CASCADE_LEVELS_COUNT
//    )
//
//    renderEncoder.setRenderPipelineState(debugCSMLightSpaceFrustumPipelineState)
//    renderEncoder.setVertexBuffer(
//      frustumPartitionsLightSpaceVertexBuffer,
//      offset: 0,
//      index: VertexBuffer.index
//    )
//    renderEncoder.drawPrimitives(
//      type: .line,
//      vertexStart: 0,
//      vertexCount: 8 * Self.SHADOW_CASCADE_LEVELS_COUNT,
//      instanceCount: 1
//    )
//
//    renderEncoder.endEncoding()
  }

}
