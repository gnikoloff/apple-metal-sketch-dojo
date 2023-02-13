//
//  PointsShadowmap.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 31.12.22.
//

// swiftlint:disable identifier_name

import MetalKit

final class PointsShadowmap: ExampleScreen {


  private static let SHADOW_PASS_LABEL = "Point Shadow Pass"
  private static let FORWARD_PASS_LABEL = "Point ShadowMap Pass"

  var outputTexture: MTLTexture!
  var outputDepthTexture: MTLTexture!
  var outputPassDescriptor: MTLRenderPassDescriptor

  private var cubeRenderPipeline: MTLRenderPipelineState
  private let sphereRenderPipelineFront: MTLRenderPipelineState
  private let sphereRenderPipelineBack: MTLRenderPipelineState
  private let centerSphereRenderPipeline: MTLRenderPipelineState
  private let depthStencilState: MTLDepthStencilState?

  var options: Options
  private var cube: Cube
  private var sphere0: SphereLightCaster
  private var sphere1: SphereLightCaster

  private var perspCameraUniforms = CameraUniforms()
  private var perspCamera = ArcballCamera()

  lazy private var shadowCastersUniformsBuffer: MTLBuffer = {
    var light0 = PointsShadowmap_Light()
    light0.color = float3(0.203, 0.596, 0.858)
    light0.cutoffDistance = 1.3
    var light1 = PointsShadowmap_Light()
    light1.color = float3(0.905, 0.596, 0.235)
    light1.cutoffDistance = 1.3
    var lights = [light0, light1]
    return Renderer.device.makeBuffer(
      bytes: &lights,
      length: MemoryLayout<PointsShadowmap_Light>.stride * 2
    )!
  }()

  init(options: Options) {
    self.options = options
    outputPassDescriptor = MTLRenderPassDescriptor()

    do {
      try cubeRenderPipeline = PointsShadowmapPipelineStates.createForwardPSO(
        colorPixelFormat: Renderer.viewColorFormat,
        isSolidColor: false,
        isShadedAndShadowed: true
      )
      try sphereRenderPipelineFront = PointsShadowmapPipelineStates.createForwardPSO(
        colorPixelFormat: Renderer.viewColorFormat,
        isCutOffAlpha: true
      )
      try sphereRenderPipelineBack = PointsShadowmapPipelineStates.createForwardPSO(
        colorPixelFormat: Renderer.viewColorFormat,
        isSolidColor: true,
        isCutOffAlpha: true
      )
      try centerSphereRenderPipeline = PointsShadowmapPipelineStates.createForwardPSO(
        colorPixelFormat: Renderer.viewColorFormat,
        isSolidColor: true
      )
    } catch {
      fatalError(error.localizedDescription)
    }

    perspCamera.distance = 3

    depthStencilState = Self.buildDepthStencilState()

    cube = Cube(size: [2, 2, 2])
    cube.cullMode = .front

    sphere0 = SphereLightCaster()
    sphere1 = SphereLightCaster()
  }

  func resize(view: MTKView) {
    let size = options.drawableSize
    outputTexture = Self.createOutputTexture(
      size: options.drawableSize,
      label: "PointsShadowmap output texture"
    )
    outputDepthTexture = Self.createDepthOutputTexture(size: size)
    self.perspCamera.update(size: size)
  }

  func updateUniforms() {
    let shadowCasrersUniformsBufferContents = shadowCastersUniformsBuffer
      .contents()
      .bindMemory(to: PointsShadowmap_Light.self, capacity: 2)
    shadowCasrersUniformsBufferContents[0].position = sphere0.position
    shadowCasrersUniformsBufferContents[1].position = sphere1.position
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    perspCamera.update(deltaTime: deltaTime)

    let moveRadius: Float = 0.4
    sphere0.position.x = sin(elapsedTime) * moveRadius
    sphere0.position.y = sin(elapsedTime + 10) * moveRadius
    sphere0.position.z = cos(elapsedTime) * moveRadius

    sphere0.rotation.x = elapsedTime * 0.2
    sphere0.rotation.y = elapsedTime * 0.2
    sphere0.rotation.z = -elapsedTime

    sphere1.position.x = sin(-elapsedTime) * moveRadius
    sphere1.position.y = sin(elapsedTime * 2) * moveRadius
    sphere1.position.z = cos(-elapsedTime + 10) * moveRadius

    sphere1.rotation.x = -elapsedTime * 0.8
    sphere1.rotation.y = elapsedTime * 0.8
    sphere1.rotation.z = -elapsedTime

    perspCameraUniforms.viewMatrix = perspCamera.viewMatrix
    perspCameraUniforms.projectionMatrix = perspCamera.projectionMatrix
    perspCameraUniforms.position = perspCamera.position
  }

  func drawShadowCubeMap(commandBuffer: MTLCommandBuffer) {
    sphere0.cullMode = .none
    sphere0.drawCubeShadow(
      commandBuffer: commandBuffer,
      idx: 0,
      shadowCastersBuffer: shadowCastersUniformsBuffer
    )
    sphere1.cullMode = .none
    sphere1.drawCubeShadow(
      commandBuffer: commandBuffer,
      idx: 1,
      shadowCastersBuffer: shadowCastersUniformsBuffer
    )
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    updateUniforms()

    drawShadowCubeMap(commandBuffer: commandBuffer)

//    guard let descriptor = view.currentRenderPassDescriptor else {
//      return
//    }

//    view.clearColor = MTLClearColor(red: 1, green: 0.2, blue: 1, alpha: 1)

    var camUniforms = perspCameraUniforms

    let descriptor = outputPassDescriptor
    descriptor.colorAttachments[0].texture = outputTexture
    descriptor.colorAttachments[0].loadAction = .clear
    descriptor.colorAttachments[0].storeAction = .store
    descriptor.depthAttachment.texture = outputDepthTexture
    descriptor.depthAttachment.storeAction = .dontCare
//    descriptor.depthAttachment.texture?.pixelFormat = .depth16Unorm

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    renderEncoder.setVertexBytes(
      &camUniforms,
      length: MemoryLayout<CameraUniforms>.stride,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      shadowCastersUniformsBuffer,
      offset: 0,
      index: ShadowCameraUniformsBuffer.index
    )
    renderEncoder.setFragmentTextures(
      [sphere0.cubeShadowTexture, sphere1.cubeShadowTexture],
      range: 0..<2
    )

    renderEncoder.label = PointsShadowmap.FORWARD_PASS_LABEL
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(cubeRenderPipeline)

    cube.instanceCount = 1
    cube.draw(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(centerSphereRenderPipeline)
    sphere0.drawCenterSphere(renderEncoder: renderEncoder)
    sphere1.drawCenterSphere(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(sphereRenderPipelineBack)
    sphere0.cullMode = .front
    sphere0.draw(renderEncoder: renderEncoder)
    sphere1.cullMode = .front
    sphere1.draw(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(sphereRenderPipelineFront)

    sphere0.cullMode = .back
    sphere0.draw(renderEncoder: renderEncoder)
    sphere1.cullMode = .back
    sphere1.draw(renderEncoder: renderEncoder)

    renderEncoder.endEncoding()
  }

  func destroy() {
  }

}
