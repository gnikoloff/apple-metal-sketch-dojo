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
  private static let CUBES_POS_RADIUS: Float = 400
  private static let CUBES_SIZE = float3(10, 200, 10)
  private static let FLOOR_SIZE: Float = 1000
  private static let CAMERA_NEAR: Float = 1
  private static let CAMERA_FAR: Float = 1000
  private static let SHADOW_RESOLUTION = 1024
  private static let SHADOW_CASCADE_LEVELS_COUNT = 3
  private static let SHADOW_CASCADE_ZMULT: Float = 4
  private static var SHADOW_CASCADE_LEVELS: [Float] = [200, 450, 750, 1000]
  private static var SUN_POSITION = float3(700, 600, 500)
  private static let MODEL_SCALE: Float = 0.5
  private static let MODEL_OFFSET_Y: Float = 0

  var options: Options
  var outputTexture: MTLTexture!
  var outputDepthTexture: MTLTexture!

  private var isDebugMode = false
  private var time: Float = 0

  private let depthStencilState: MTLDepthStencilState?

  var outputPassDescriptor: MTLRenderPassDescriptor
  private let shadowPassDescriptor: MTLRenderPassDescriptor
  private let debugCamPassDescriptor: MTLRenderPassDescriptor
  private let floorShadowPipelineState: MTLRenderPipelineState
  private let cubesShadowPipelineState: MTLRenderPipelineState
  private let modelShadowPipelineState: MTLRenderPipelineState
  private let floorPipelineState: MTLRenderPipelineState
  private let cubesPipelineState: MTLRenderPipelineState
  private let modelPipelineState: MTLRenderPipelineState

  private let cameraBuffer: MTLBuffer
  private let debugCameraBuffer: MTLBuffer
  private let lightMatricesBuffer: MTLBuffer

  private var camDebugTexture: MTLTexture!
  private var camDebugDepthTexture: MTLTexture!
  private var shadowDepthTexture: MTLTexture

  private var lightMatrices: [float4x4] = []
  private var debugCamera = PerspectiveCamera()
  private var arcballCamera = ArcballCamera()
  private var cube: Cube
  private var floor: Plane
  private var texturesDebugger: CascadedShadowsMap_TexturesDebugger
  private var cameraFrustumDebuger: CascadedShadowsMap_CameraDebugger

  lazy private var supportsLayerSelection: Bool = {
    Renderer.device.supportsFamily(MTLGPUFamily.mac2) || Renderer.device.supportsFamily(MTLGPUFamily.apple5)
  }()

  lazy private var meshMaterialBuffer: MTLBuffer = {
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
      .bindMemory(
        to: float4x4.self,
        capacity: Self.CUBES_COUNT * Self.SHADOW_CASCADE_LEVELS_COUNT
      )
    let spacer = Float.pi * 2 / Float(Self.CUBES_COUNT)
    for i in 0 ..< Self.CUBES_COUNT {
      let fi = Float(i)
      let x: Float = i % 2 == 0 ? -1 : 1
      let pos = float3(
        cos(fi * spacer) * Self.CUBES_POS_RADIUS,
        0,
        sin(fi * spacer) * Self.CUBES_POS_RADIUS
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
      shadowTexSize: [texRes, texRes],
      lightsCount: 2,
      worldSize: float3(Self.FLOOR_SIZE, 100, Self.FLOOR_SIZE),
      time: 0
    )
    return buffer
  }()

  private var model = Model(name: "Arcade_Fighter_1")

  init(options: Options) {
    self.options = options
    do {
      try floorPipelineState = CascadedShadowsMap_PipelineStates.createMeshPSO()
      try cubesPipelineState = CascadedShadowsMap_PipelineStates.createMeshPSO(
        instancesHaveUniquePositions: true
      )
      try modelPipelineState = CascadedShadowsMap_PipelineStates.createPBRPSO(
        isSkeletonAnimation: true
      )
      try floorShadowPipelineState = CascadedShadowsMap_PipelineStates.createShadowPSO()
      try cubesShadowPipelineState = CascadedShadowsMap_PipelineStates.createShadowPSO(
        instancesHaveUniquePositions: true
      )
      try modelShadowPipelineState = CascadedShadowsMap_PipelineStates.createShadowPSO(
        useDefaultMTKVertexLayout: true,
        isSkeletonAnimation: true
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

    arcballCamera.distance = 300
    arcballCamera.rotation = float3(0, -.pi, .pi * 2)
    arcballCamera.maxPolarAngle = -0.1
    debugCamera.position = float3(500, 500, 50)

    cube = Cube(size: Self.CUBES_SIZE)
    cube.position.y = Self.CUBES_SIZE.y / 2
    floor = Plane(size: float3(Self.FLOOR_SIZE, Self.FLOOR_SIZE, 1))

    floor.rotation.x = .pi * 0.5

    texturesDebugger = CascadedShadowsMap_TexturesDebugger(
      cascadesCount: Self.SHADOW_CASCADE_LEVELS_COUNT
    )
    cameraFrustumDebuger = CascadedShadowsMap_CameraDebugger(
      cascadesCount: Self.SHADOW_CASCADE_LEVELS_COUNT
    )
  }

  func getLightSpaceMatrix(idx: Int, nearPlane: Float, farPlane: Float) -> float4x4 {
    arcballCamera.near = nearPlane
    arcballCamera.far = farPlane
    let frustumWorldSpaceCorners = arcballCamera.getFrustumCornersWorldSpace()

    var center = float3(repeating: 0)
    for corner in frustumWorldSpaceCorners {
      center += corner.xyz
    }
    center /= frustumWorldSpaceCorners.count

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
    return projMatrix * viewMatrix
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
    model.update(deltaTime: deltaTime)

    time = elapsedTime
  }

  func updateUniforms() {
    let cameraBuffPtr = cameraBuffer
      .contents()
      .bindMemory(to: CameraUniforms.self, capacity: 1)
    let debugCameraBuffPtr = debugCameraBuffer
      .contents()
      .bindMemory(to: CameraUniforms.self, capacity: 1)
    let settingsBuffPtr = settingsBuffer
      .contents()
      .bindMemory(to: CascadedShadowsMap_Settings.self, capacity: 1)

    cameraBuffPtr.pointee.position = arcballCamera.position
    cameraBuffPtr.pointee.projectionMatrix = arcballCamera.projectionMatrix
    cameraBuffPtr.pointee.viewMatrix = arcballCamera.viewMatrix

    debugCameraBuffPtr.pointee.position = debugCamera.position
    debugCameraBuffPtr.pointee.projectionMatrix = debugCamera.projectionMatrix
    debugCameraBuffPtr.pointee.viewMatrix = debugCamera.viewMatrix

    settingsBuffPtr.pointee.time = time

    cameraBuffPtr.pointee.near = Self.CAMERA_NEAR
    cameraBuffPtr.pointee.far = Self.CAMERA_FAR

    let lightMatricesPtr = lightMatricesBuffer
      .contents()
      .bindMemory(to: float4x4.self, capacity: Self.SHADOW_CASCADE_LEVELS_COUNT)

    for i in 0 ..< Self.SHADOW_CASCADE_LEVELS_COUNT + 1 {
      var lightMatrix: float4x4
      if i == 0 {
        let _lightMatrix = getLightSpaceMatrix(
          idx: i,
          nearPlane: Self.CAMERA_NEAR,
          farPlane: Self.SHADOW_CASCADE_LEVELS[i]
        )
        lightMatrix = _lightMatrix
      } else if i < Self.SHADOW_CASCADE_LEVELS_COUNT {
        let _lightMatrix = getLightSpaceMatrix(
          idx: i,
          nearPlane: Self.SHADOW_CASCADE_LEVELS[i - 1],
          farPlane: Self.SHADOW_CASCADE_LEVELS[i]
        )
        lightMatrix = _lightMatrix
      } else {
        let _lightMatrix = getLightSpaceMatrix(
          idx: i,
          nearPlane: Self.SHADOW_CASCADE_LEVELS[i - 1],
          farPlane: Self.CAMERA_FAR
        )
        lightMatrix = _lightMatrix
      }
      lightMatricesPtr[i] = lightMatrix
    }
    arcballCamera.near = Self.CAMERA_NEAR
    arcballCamera.far = Self.CAMERA_FAR
  }

  func drawShadowScene(commandBuffer: MTLCommandBuffer) {
    shadowPassDescriptor.depthAttachment.texture = shadowDepthTexture
    shadowPassDescriptor.depthAttachment.loadAction = .clear
    shadowPassDescriptor.depthAttachment.storeAction = .store
    shadowPassDescriptor.renderTargetArrayLength = Self.SHADOW_CASCADE_LEVELS_COUNT

    guard let shadowRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowPassDescriptor) else {
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
    cube.draw(renderEncoder: shadowRenderEncoder)

    shadowRenderEncoder.setRenderPipelineState(floorShadowPipelineState)
    floor.instanceCount = Self.SHADOW_CASCADE_LEVELS_COUNT
    floor.draw(renderEncoder: shadowRenderEncoder)

    shadowRenderEncoder.setRenderPipelineState(modelShadowPipelineState)
    model.scale = Self.MODEL_SCALE
    model.position.y = Self.MODEL_OFFSET_Y
    model.instanceCount = Self.SHADOW_CASCADE_LEVELS_COUNT
    model.draw(encoder: shadowRenderEncoder, useTextures: true)

    shadowRenderEncoder.endEncoding()
  }

  func drawDebugScene(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    guard let descriptor = view.currentRenderPassDescriptor else {
      fatalError("Can't create descriptor")
    }
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }
    renderEncoder.setVertexBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setVertexBuffer(
      debugCameraBuffer,
      offset: 0,
      index: DebugCameraBuffer.index
    )
    renderEncoder.setVertexBuffer(
      lightMatricesBuffer,
      offset: 0,
      index: LightsMatricesBuffer.index
    )
    renderEncoder.setVertexBuffer(
      cubesInstancesBuffer,
      offset: 0,
      index: CubeInstancesBuffer.index
    )
    renderEncoder.setVertexBuffer(
      settingsBuffer,
      offset: 0,
      index: SettingsBuffer.index
    )

    renderEncoder.setFragmentBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      meshMaterialBuffer,
      offset: 0,
      index: MaterialBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      lightsBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      settingsBuffer,
      offset: 0,
      index: SettingsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      lightMatricesBuffer,
      offset: 0,
      index: LightsMatricesBuffer.index
    )
    renderEncoder.setFragmentTexture(
      shadowDepthTexture,
      index: ShadowTextures.index
    )

    renderEncoder.setDepthStencilState(depthStencilState)

    renderEncoder.setRenderPipelineState(texturesDebugger.floorPipelineDebugState)
    floor.instanceCount = 1
    floor.draw(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(texturesDebugger.cubesPipelineDebugState)
    cube.instanceCount = Self.CUBES_COUNT
    cube.draw(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(texturesDebugger.modelPipelineDebugState)
    model.scale = Self.MODEL_SCALE
    model.position.y = Self.MODEL_OFFSET_Y
    model.instanceCount = 1
    model.draw(encoder: renderEncoder, useTextures: true)

    cameraFrustumDebuger.draw(camera: arcballCamera, renderEncoder: renderEncoder)
    texturesDebugger.shadowsDepthTexture = shadowDepthTexture
    texturesDebugger.debugCamTexture = camDebugTexture
    texturesDebugger.draw(renderEncoder: renderEncoder)

    renderEncoder.endEncoding()
  }

  func drawMainScene(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    var descriptor: MTLRenderPassDescriptor

    if (isDebugMode) {
      debugCamPassDescriptor.colorAttachments[0].texture = camDebugTexture
      debugCamPassDescriptor.colorAttachments[0].loadAction = .clear
      debugCamPassDescriptor.colorAttachments[0].storeAction = .store
      debugCamPassDescriptor.depthAttachment.texture = camDebugDepthTexture
      debugCamPassDescriptor.depthAttachment.loadAction = .clear
      debugCamPassDescriptor.depthAttachment.storeAction = .store
      descriptor = debugCamPassDescriptor
    } else {
      descriptor = outputPassDescriptor
      descriptor.colorAttachments[0].texture = outputTexture
      descriptor.colorAttachments[0].loadAction = .clear
      descriptor.colorAttachments[0].storeAction = .store
      descriptor.depthAttachment.texture = outputDepthTexture
      descriptor.depthAttachment.storeAction = .dontCare
//      descriptor = view.currentRenderPassDescriptor!
    }

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    renderEncoder.setVertexBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setVertexBuffer(
      debugCameraBuffer,
      offset: 0,
      index: DebugCameraBuffer.index
    )
    renderEncoder.setVertexBuffer(
      lightMatricesBuffer,
      offset: 0,
      index: LightsMatricesBuffer.index
    )
    renderEncoder.setVertexBuffer(
      cubesInstancesBuffer,
      offset: 0,
      index: CubeInstancesBuffer.index
    )
    renderEncoder.setVertexBuffer(
      settingsBuffer,
      offset: 0,
      index: SettingsBuffer.index
    )

    renderEncoder.setFragmentBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      meshMaterialBuffer,
      offset: 0,
      index: MaterialBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      lightsBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      settingsBuffer,
      offset: 0,
      index: SettingsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      lightMatricesBuffer,
      offset: 0,
      index: LightsMatricesBuffer.index
    )
    renderEncoder.setFragmentTexture(
      shadowDepthTexture,
      index: ShadowTextures.index
    )
    renderEncoder.setFragmentTexture(
      camDebugTexture,
      index: CamDebugTexture.index
    )

    renderEncoder.setDepthStencilState(depthStencilState)

    renderEncoder.setRenderPipelineState(floorPipelineState)
    floor.instanceCount = 1
    floor.draw(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(cubesPipelineState)
    cube.instanceCount = Self.CUBES_COUNT
    cube.draw(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(modelPipelineState)
    model.scale = Self.MODEL_SCALE
    model.position.y = Self.MODEL_OFFSET_Y
    model.instanceCount = 1
    model.draw(encoder: renderEncoder, useTextures: true)

    renderEncoder.endEncoding()
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    updateUniforms()
    drawShadowScene(commandBuffer: commandBuffer)
    if isDebugMode {
      drawDebugScene(in: view, commandBuffer: commandBuffer)
    }
    drawMainScene(in: view, commandBuffer: commandBuffer)
  }
}
