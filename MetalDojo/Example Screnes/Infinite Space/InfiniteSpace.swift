//
//  InfiniteSpace.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

import MetalKit

class InfiniteSpace: ExampleScreen {
  private var perspCamera = ArcballCamera()
  private var perspCameraUniforms = CameraUniforms()

  private let depthStencilState: MTLDepthStencilState?
  private var cubeRenderPipeline: MTLRenderPipelineState

  var cube: Cube

  init() {
    do {
      try cubeRenderPipeline = InfiniteSpacePipelineStates.createForwardPSO(
        colorPixelFormat: Renderer.viewColorFormat
      )
    } catch {
      fatalError(error.localizedDescription)
    }
    cube = Cube(size: [0.1, 0.1, 1], segments: [1, 1, 10])

    depthStencilState = Renderer.buildDepthStencilState()
  }

  func resize(view: MTKView, size: CGSize) {
    self.perspCamera.update(size: size)
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    perspCamera.update(deltaTime: deltaTime)
  }

  func updateUniforms() {
    perspCameraUniforms.viewMatrix = perspCamera.viewMatrix
    perspCameraUniforms.projectionMatrix = perspCamera.projectionMatrix
    perspCameraUniforms.position = perspCamera.position
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    guard let descriptor = view.currentRenderPassDescriptor else {
      return
    }

//    view.clearColor = MTLClearColor(red: 1, green: 0.2, blue: 1, alpha: 1)

    var camUniforms = perspCameraUniforms
    updateUniforms()

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    renderEncoder.setVertexBytes(
      &camUniforms,
      length: MemoryLayout<CameraUniforms>.stride,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.label = "Infinite Space Demo"
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(cubeRenderPipeline)

    cube.draw(renderEncoder: renderEncoder)

    renderEncoder.endEncoding()
  }

  func destroy() {
  }

}

