//
//  InfiniteSpace.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

// swiftlint:disable identifier_name

import MetalKit

class InfiniteSpace: ExampleScreen {
  private var perspCamera = ArcballCamera()
  private var perspCameraUniforms = CameraUniforms()

  private let depthStencilState: MTLDepthStencilState?
  private let cubeRenderPipeline: MTLRenderPipelineState
  private let computePipelineState: MTLComputePipelineState

  private let controlPointsBuffer: MTLBuffer

  var cube: Cube

  init() {
    do {
      try cubeRenderPipeline = InfiniteSpacePipelineStates.createForwardPSO(
        colorPixelFormat: Renderer.viewColorFormat
      )
      try computePipelineState = InfiniteSpacePipelineStates.createComputePSO()
    } catch {
      fatalError(error.localizedDescription)
    }
    
    cube = Cube(size: [0.1, 0.1, 1], segments: [1, 1, 10])

    depthStencilState = Renderer.buildDepthStencilState()

    controlPointsBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<InfiniteSpace_ControlPoint>.stride * 11
    )!
    let controlPointsBufferPointer = controlPointsBuffer
      .contents()
      .bindMemory(to: InfiniteSpace_ControlPoint.self, capacity: 11)
    for i in 0..<11 {
      let fi = Float(i)
      controlPointsBufferPointer[i].position = float3(0, sin(fi)*0.2, fi / 10 - 0.5)
      print(fi / 10 - 0.5)

    }
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

  func updateCompute(commandBuffer: MTLCommandBuffer) {
    guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
      return
    }
    computeEncoder.setComputePipelineState(computePipelineState)
    var width = computePipelineState.threadExecutionWidth
    var height = 1
    let threadsPerThreadGroup = MTLSizeMake(width, height, 1)
    width = 11
    height = 1
    var threadsPerGrid = MTLSizeMake(width, height, 1)

    computeEncoder.setBuffer(
      controlPointsBuffer,
      offset: 0,
      index: ControlPointsBuffer.index
    )

    computeEncoder.dispatchThreads(
      threadsPerGrid,
      threadsPerThreadgroup: threadsPerThreadGroup
    )
    computeEncoder.endEncoding()
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    updateCompute(commandBuffer: commandBuffer)

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
    renderEncoder.setVertexBuffer(
      controlPointsBuffer,
      offset: 0,
      index: ControlPointsBuffer.index
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

