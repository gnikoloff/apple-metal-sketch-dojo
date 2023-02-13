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
    do {
      try pipelineState = WelcomeScreen_PipelineStates.createWelcomeScreenPSO(
        colorPixelFormat: Renderer.viewColorFormat
      )
    } catch {
      fatalError(error.localizedDescription)
    }

    let projWidth = Float(options.drawableSize.width) * 0.4
    let projHeight = projWidth * (1 / (16 / 9))
    projectsGrid = ProjectsGrid(
      projects: [
        ProjectModel(name: "Whatever 1"),
        ProjectModel(name: "Whatever 2"),
        ProjectModel(name: "Whatever 3"),
        ProjectModel(name: "Whatever 4")
      ],
      colWidth: projWidth,
      rowHeight: projHeight,
      options: options
    )

    orthoCamera.position.z -= 1
  }

  func resize(view: MTKView, size: CGSize) {
    orthoCamera.left = 0
    orthoCamera.right = Float(size.width)
    orthoCamera.bottom = Float(size.height)
    orthoCamera.top = 0
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

    updateUniforms()

    renderEncoder.label = label
    renderEncoder.setRenderPipelineState(pipelineState)

    projectsGrid.draw(
      encoder: renderEncoder,
      cameraUniforms: orthoCameraUniforms
    )

    renderEncoder.endEncoding()
  }

  func dismissSingleProject() {
    projectsGrid.dismissSingleProject()
  }
}
