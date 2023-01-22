//
//  WelcomeScreen.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 02.01.23.
//

import MetalKit

class WelcomeScreen {
  private let label = "Welcome Screen Render Pass"

  private var pipelineState: MTLRenderPipelineState
  private var orthoCameraUniforms = CameraUniforms()
  private var orthoCamera = OrthographicCamera()

  var projectsGrid: ProjectsGrid

  init(options: Options) {
    pipelineState = PipelineState.createWelcomeScreenPSO(
      colorPixelFormat: Renderer.viewColorFormat
    )
    projectsGrid = ProjectsGrid(
      projects: [
        ProjectModel(name: "Whatever"),
        ProjectModel(name: "Whatever"),
        ProjectModel(name: "Whatever")
      ],
      colWidth: 900,
      rowHeight: 400,
      options: options
    )

    orthoCamera.position.z -= 1
  }

  func resize(view: MTKView, size: CGSize) {
    orthoCamera.update(size: size)
  }

  func updateUniforms() {
    orthoCameraUniforms.viewMatrix = orthoCamera.viewMatrix
    orthoCameraUniforms.projectionMatrix = orthoCamera.projectionMatrix
    orthoCameraUniforms.position = orthoCamera.position
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    self.projectsGrid.updateVertices(deltaTime: deltaTime)
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

//    descriptor.colorAttachments[0].loadAction = .clear

    updateUniforms()

    renderEncoder.label = label
    renderEncoder.setRenderPipelineState(pipelineState)

    projectsGrid.draw(
      encoder: renderEncoder,
      cameraUniforms: orthoCameraUniforms
    )

    renderEncoder.endEncoding()
  }
}
