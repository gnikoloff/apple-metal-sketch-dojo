//
//  WelcomeScreen.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 02.01.23.
//

// swiftlint:disable identifier_name

import MetalKit

class WelcomeScreen {
  static var SCREEN_NAME = "Welcome Screen"
  static var cameraZoom: Float = 1

  private var meshPipelineState: MTLRenderPipelineState
  private var ctrlPointsPipelineState: MTLRenderPipelineState
  private var orthoCameraUniforms = CameraUniforms()
  private var orthoCamera = OrthographicCamera()

  var options: Options
  var projectsGrid: ProjectsGrid

  init(options: Options) {
    self.options = options
    do {
      try meshPipelineState = WelcomeScreen_PipelineStates.createWelcomeScreenPSO()
      try ctrlPointsPipelineState = WelcomeScreen_PipelineStates.createWelcomeScreenCtrlPointsPSO()
    } catch {
      fatalError(error.localizedDescription)
    }

    projectsGrid = ProjectsGrid(options: options)

    orthoCamera.position.z -= 1
  }

  func resize(view: MTKView) {
    orthoCamera.left = 0
    orthoCamera.right = options.drawableSize.x
    orthoCamera.bottom = options.drawableSize.y
    orthoCamera.top = 0
  }

  func updateUniforms() {
    orthoCameraUniforms.viewMatrix = orthoCamera.viewMatrix
    orthoCameraUniforms.projectionMatrix = orthoCamera.projectionMatrix
    orthoCameraUniforms.position = orthoCamera.position
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    projectsGrid.updateVertices(deltaTime: deltaTime)
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

    renderEncoder.setRenderPipelineState(meshPipelineState)
    projectsGrid.draw(encoder: renderEncoder, cameraUniforms: orthoCameraUniforms)

    if options.activeProjectName == WelcomeScreen.SCREEN_NAME {
      renderEncoder.setRenderPipelineState(ctrlPointsPipelineState)
      projectsGrid.drawCtrlPoints(encoder: renderEncoder, camUniforms: orthoCameraUniforms)
    }

    renderEncoder.endEncoding()
  }

  func dismissSingleProject() {
    projectsGrid.dismissSingleProject()
  }
}
