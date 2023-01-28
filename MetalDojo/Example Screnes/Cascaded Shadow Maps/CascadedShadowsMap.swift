//
//  CascadedShadowsMap.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

// swiftlint:disable identifier_name

import MetalKit

final class CascadedShadowsMap: ExampleScreen {
//  private static let BOXES_COUNT = 24
//  private static let ROWS_COUNT = 2
  private static let SHADOW_RESOLUTION = 1024

  var options: Options
  var outputTexture: MTLTexture!
  var outputDepthTexture: MTLTexture!
  var outputPassDescriptor: MTLRenderPassDescriptor

  private let depthStencilState: MTLDepthStencilState?
  private let floorPipelineState: MTLRenderPipelineState
  private let modelPipelineState: MTLRenderPipelineState
  private let cameraBuffer: MTLBuffer
  private var shadowDepthTexture: MTLTexture!
  private let shadowDescriptor: MTLRenderPassDescriptor
  private let shadowPipelineState: MTLRenderPipelineState

  private var shadowCamera = OrthographicCamera()
  private var perspCamera = ArcballCamera()
//  private var plane: Plane
//  private var cube: Cube

//  lazy private var model0: Model = {
//    Model(name: "T-Rex.usdz")
//  }()

  lazy private var supportsLayerSelection: Bool = {
    Renderer.device.supportsFamily(MTLGPUFamily.mac2) || Renderer.device.supportsFamily(MTLGPUFamily.apple5)
  }()

  lazy private var model: Model = {
    Model(name: "city.usdz")
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
    dirLight.position = [-1, 1, -1]
    dirLight.color = float3(repeating: 1)
    var ambientLight = Self.buildDefaultLight()
    ambientLight.type = Ambient
    ambientLight.color = float3(repeating: 0.2)
    return Self.createLightBuffer(lights: [dirLight, ambientLight])
  }()

  init(options: Options) {
    self.options = options

    do {
      try floorPipelineState = CascadedShadowsMap_PipelineStates.createFloorPSO()
      try modelPipelineState = CascadedShadowsMap_PipelineStates.createPBRPSO()
      try shadowPipelineState = CascadedShadowsMap_PipelineStates.createShadowPSO()

    } catch {
      fatalError(error.localizedDescription)
    }

    outputPassDescriptor = MTLRenderPassDescriptor()
    depthStencilState = Self.buildDepthStencilState()
    shadowDescriptor = MTLRenderPassDescriptor()

    cameraBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<CameraUniforms>.stride,
      options: []
    )!

    perspCamera.distance = 10

//    plane = Plane(size: float3(10, 10, 1))
//    plane.rotation.x = .pi * 0.5

//    cube = Cube(size: float3(1, 1, 0.2))

//    model0.scale = 0.002
    model.scale = 0.002
    model.position.x = 2
  }

  func resize(view: MTKView) {
    let size = options.drawableSize
    outputDepthTexture = Self.createDepthOutputTexture(size: size)
    outputTexture = Self.createOutputTexture(
      size: size,
      label: "Cascaded Shadow Maps Output texture"
    )
    shadowDepthTexture = RenderPass.makeTexture(
      size: CGSize(width: Self.SHADOW_RESOLUTION, height: Self.SHADOW_RESOLUTION),
      pixelFormat: .depth32Float,
      label: "Shadow Depth Texture",
      type: .type2DArray
    )
    shadowDepthTexture.sl
    perspCamera.update(size: size)
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    perspCamera.update(deltaTime: deltaTime)
//    model0.update(deltaTime: deltaTime)


    model.update(deltaTime: deltaTime)

    let frustumWorldSpaceCorners = perspCamera.getFrustumCornersWorldSpace()
    var center = float3(repeating: 0)
    for corner in frustumWorldSpaceCorners {
      center += corner.xyz
    }
    center /= (frustumWorldSpaceCorners.count)
    shadowCamera.target = center
    var minX = Float.greatestFiniteMagnitude
    var maxX = -minX
    var minY = Float.greatestFiniteMagnitude
    var maxY = -minY
    var minZ = Float.greatestFiniteMagnitude
    var maxZ = -minZ
    for corner in frustumWorldSpaceCorners {
      let trf = shadowCamera.viewMatrix * corner
      minX = min(minX, trf.x)
      maxX = max(maxX, trf.x)
      minY = min(minY, trf.y)
      maxY = max(maxY, trf.y)
      minZ = min(minZ, trf.z)
      maxZ = max(maxZ, trf.z)
    }
    // Tune this parameter according to the scene
    let zMult: Float = 2
    if minZ < 0 {
      minZ *= zMult
    } else {
      minZ /= zMult
    }
    if maxZ < 0 {
      maxZ /= zMult
    } else {
      maxZ *= zMult
    }
    //    shadowCamera.
    shadowCamera.left = minX
    shadowCamera.right = maxX
    shadowCamera.top = minY
    shadowCamera.bottom = maxY
    shadowCamera.near = minZ
    shadowCamera.far = maxZ
    shadowCamera.aspect = 1
  }

  func updateUniforms() {
    let cameraBuffPtr = cameraBuffer
      .contents()
      .bindMemory(to: CameraUniforms.self, capacity: 1)

    cameraBuffPtr.pointee.position = perspCamera.position
    cameraBuffPtr.pointee.projectionMatrix = perspCamera.projectionMatrix
    cameraBuffPtr.pointee.viewMatrix = perspCamera.viewMatrix
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    updateUniforms()
    let descriptor = view.currentRenderPassDescriptor!
//    let descriptor = outputPassDescriptor
//    descriptor.colorAttachments[0].texture = outputTexture
//    descriptor.colorAttachments[0].loadAction = .clear
//    descriptor.colorAttachments[0].storeAction = .store
//    descriptor.depthAttachment.texture = outputDepthTexture
//    descriptor.depthAttachment.storeAction = .dontCare

    shadowDescriptor.depthAttachment.texture = shadowDepthTexture
    shadowDescriptor.renderTargetArrayLength = 3

    guard let shadowRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowDescriptor) else {
      return
    }

    shadowRenderEncoder.setRenderPipelineState(shadowPipelineState)
    shadowRenderEncoder.setDepthStencilState(depthStencilState)
    model.draw(encoder: shadowRenderEncoder, uniforms: Uniforms())

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    renderEncoder.setVertexBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      floorMaterialBuffer,
      offset: 0,
      index: MaterialBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      lightsBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      paramsBuffer,
      offset: 0,
      index: ParamsBuffer.index
    )

    renderEncoder.setRenderPipelineState(modelPipelineState)
    renderEncoder.setDepthStencilState(depthStencilState)
    model.draw(encoder: renderEncoder, uniforms: Uniforms())

    renderEncoder.endEncoding()
  }

}
