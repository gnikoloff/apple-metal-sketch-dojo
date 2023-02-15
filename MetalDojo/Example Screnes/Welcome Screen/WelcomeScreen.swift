//
//  WelcomeScreen.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 02.01.23.
//

import MetalKit

class WelcomeScreen {
//  private let label = "Welcome Screen Render Pass"

  static var cameraZoom: Float = 1

  private var pipelineState: MTLRenderPipelineState
  private var debugAABBPipelineState: MTLRenderPipelineState
  private var orthoCameraUniforms = CameraUniforms()
  private var orthoCamera = OrthographicCamera()
  private var options: Options

  var infoGrid: InfoGrid
  var projectsGrid: ProjectsGrid
  private var screenWidth: Float = 1
  private var screenHeight: Float = 1

  init(options: Options) {
    self.options = options
    do {
      try pipelineState = WelcomeScreen_PipelineStates.createWelcomeScreenPSO(
        colorPixelFormat: Renderer.viewColorFormat
      )
      try debugAABBPipelineState = WelcomeScreen_PipelineStates.createDebugAABBBoxes()
    } catch {
      fatalError(error.localizedDescription)
    }

    projectsGrid = ProjectsGrid(options: options)
    infoGrid = InfoGrid(options: options)

    orthoCamera.position.z -= 1
  }

  func resize(view: MTKView, size: CGSize) {
    let fwidth = Float(size.width)
    let fheight = Float(size.height)
    orthoCamera.left = 0
    orthoCamera.right = fwidth
    orthoCamera.bottom = fheight
    orthoCamera.top = 0
    screenWidth = fwidth
    screenHeight = fheight

  }

  func updateUniforms() {
    orthoCameraUniforms.viewMatrix = orthoCamera.viewMatrix
    orthoCameraUniforms.projectionMatrix = orthoCamera.projectionMatrix
    orthoCameraUniforms.position = orthoCamera.position
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    projectsGrid.updateVertices(deltaTime: deltaTime)
    projectsGrid.testCollisionWith(grid: infoGrid)
    infoGrid.updateVerlet(deltaTime: deltaTime)
    Self.cameraZoom = simd_clamp(Float(options.pinchFactor), 0, 1)
//    orthoCamera.zoom = Self.cameraZoom
    orthoCamera.right = screenWidth * (1 + (1 - Self.cameraZoom))
    orthoCamera.bottom = screenHeight * (1 + (1 - Self.cameraZoom))
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    guard let descriptor = view.currentRenderPassDescriptor else {
      return
    }
    let clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
    descriptor.colorAttachments[0].clearColor = clearColor
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    updateUniforms()

    renderEncoder.setRenderPipelineState(pipelineState)

    infoGrid.draw(encoder: renderEncoder, cameraUniforms: orthoCameraUniforms)
    projectsGrid.draw(encoder: renderEncoder, cameraUniforms: orthoCameraUniforms)

    renderEncoder.setRenderPipelineState(debugAABBPipelineState)
    projectsGrid.drawDebug(encoder: renderEncoder, cameraUniforms: orthoCameraUniforms)
    infoGrid.drawDebug(encoder: renderEncoder, cameraUniforms: orthoCameraUniforms)

    renderEncoder.endEncoding()
  }

  func dismissSingleProject() {
    projectsGrid.dismissSingleProject()
  }
}
