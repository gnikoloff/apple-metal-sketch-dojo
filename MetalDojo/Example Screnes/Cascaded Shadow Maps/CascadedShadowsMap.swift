//
//  CascadedShadowsMap.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

// swiftlint:disable identifier_name

import MetalKit

final class CascadedShadowsMap: ExampleScreen {
  private static let BOXES_COUNT = 24
  private static let ROWS_COUNT = 2

  var options: Options
  var outputTexture: MTLTexture!
  var outputDepthTexture: MTLTexture!
  var outputPassDescriptor: MTLRenderPassDescriptor

  private let depthStencilState: MTLDepthStencilState?
  private let floorPipelineState: MTLRenderPipelineState
  private let modelPipelineState: MTLRenderPipelineState
  private let cameraBuffer: MTLBuffer

  private var perspCamera = ArcballCamera()
  private var plane: Plane
  private var cube: Cube

  lazy private var model0: Model = {
    Model(name: "T-Rex.usdz")
  }()

  lazy private var model1: Model = {
    Model(name: "T-Rex2.usdz")
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

    outputPassDescriptor = MTLRenderPassDescriptor()
    floorPipelineState = CascadedShadowsMap_PipelineStates.createFloorPSO()
    modelPipelineState = CascadedShadowsMap_PipelineStates.createPBRPSO()
    depthStencilState = PipelineState.buildDepthStencilState()

    cameraBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<CameraUniforms>.stride,
      options: []
    )!

    perspCamera.distance = 3

    plane = Plane(size: float3(10, 10, 1))
    plane.rotation.x = .pi * 0.5

    cube = Cube(size: float3(1, 1, 0.2))

    model0.scale = 0.002
    model1.scale = 0.2
    model1.position.x = 2
  }

  func resize(view: MTKView) {
    let size = options.drawableSize
    outputDepthTexture = Self.createDepthOutputTexture(size: size)
    outputTexture = Self.createOutputTexture(
      size: size,
      label: "Cascaded Shadow Maps Output texture"
    )
    perspCamera.update(size: size)
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    perspCamera.update(deltaTime: deltaTime)
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

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    renderEncoder.label = "Cascaded Shadows Map Render Pass"
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(floorPipelineState)

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
    plane.draw(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(modelPipelineState)
    model0.draw(encoder: renderEncoder, uniforms: Uniforms())
    model1.draw(encoder: renderEncoder, uniforms: Uniforms())

    renderEncoder.endEncoding()
  }

}
