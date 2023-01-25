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
  private let meshPipelineState: MTLRenderPipelineState
  private let cameraBuffer: MTLBuffer

  private var perspCamera = ArcballCamera()
  private var plane: Plane
  private var cube: Cube

  lazy var skeleton: Model = {
    Model(name: "T-Rex.usdz")
  }()

  lazy private var floorMaterialBuffer: MTLBuffer = {
    let buffer = Renderer.device.makeBuffer(
      length: MemoryLayout<Material>.stride,
      options: []
    )!
    var buffPtr = buffer.contents().bindMemory(to: Material.self, capacity: 1)
    buffPtr.pointee.shininess = 2
    buffPtr.pointee.baseColor = float3(repeating: 1)
    buffPtr.pointee.specularColor = float3(1, 0, 0)
    buffPtr.pointee.roughness = 0.7
    buffPtr.pointee.metallic = 0.1
    buffPtr.pointee.ambientOcclusion = 0
    buffPtr.pointee.opacity = 1
    return buffer
  }()

  lazy private var lightsBuffer: MTLBuffer = {
    var dirLight = Self.buildDefaultLight()
    dirLight.position = [1, 1, 1]
    dirLight.color = float3(repeating: 1)
    var ambientLight = Self.buildDefaultLight()
    ambientLight.type = Ambient
    ambientLight.color = float3(repeating: 0.4)
    return Self.createLightBuffer(lights: [dirLight, ambientLight])
  }()

  init(options: Options) {
    self.options = options

    outputPassDescriptor = MTLRenderPassDescriptor()
    meshPipelineState = CascadedShadowsMap_PipelineStates.createForwardPSO()
    depthStencilState = PipelineState.buildDepthStencilState()

    cameraBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<CameraUniforms>.stride,
      options: []
    )!

    perspCamera.distance = 3

    plane = Plane(size: float3(10, 10, 1))
    plane.rotation.x = .pi * 0.5

    cube = Cube(size: float3(1, 1, 0.2))

    skeleton.scale = 0.002

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
    renderEncoder.setRenderPipelineState(meshPipelineState)

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

    plane.draw(renderEncoder: renderEncoder)
    skeleton.draw(encoder: renderEncoder, uniforms: Uniforms())

    renderEncoder.endEncoding()
  }

}
