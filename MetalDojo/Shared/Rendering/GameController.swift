//
//  GameController.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import MetalKit

final class GameController: NSObject {
  var renderer: Renderer
  var options: Options
  var fps: Double = 0
  var deltaTime: Double = 0
  var lastTime: Double = CFAbsoluteTimeGetCurrent()
  var elapsedTime: Double = 0

  // Screens
  var welcomeScreen: WelcomeScreen
  var screens: [ExampleScreen] = []

  var drawAllScreens = true

  init(metalView: MTKView, options: Options) {
    renderer = Renderer(metalView: metalView)
    self.options = options
    welcomeScreen = WelcomeScreen(options: options)
    super.init()
    metalView.delegate = self
    metalView.framebufferOnly = false
    fps = Double(metalView.preferredFramesPerSecond)

    screens.append(PointsShadowmap(options: options))
    screens.append(InfiniteSpace(options: options))
    screens.append(AppleMetalScreen(options: options))

    let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
      self.drawAllScreens = false
    }
  }
}

extension GameController: MTKViewDelegate {
  func mtkView(_ metalView: MTKView, drawableSizeWillChange size: CGSize) {
    welcomeScreen.resize(view: metalView, size: size)
    options.drawableSize = size

    for screen in screens {
      var screen = screen
      screen.resize(view: metalView)
    }
  }
  func draw(in view: MTKView) {
    let currentTime = CFAbsoluteTimeGetCurrent()
    let dt = currentTime - lastTime
    elapsedTime += dt
    lastTime = currentTime

    welcomeScreen.update(elapsedTime: Float(elapsedTime), deltaTime: Float(dt))

    if drawAllScreens {
      for var screen in screens {
        screen.update(elapsedTime: Float(elapsedTime), deltaTime: Float(dt))
      }
    }

    guard
      var descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else {
      return
    }

    if drawAllScreens {

      for i in 0 ..< screens.count {
        var screen = screens[i]
        let panel = welcomeScreen.projectsGrid.panels[i]
        screen.draw(in: view, commandBuffer: commandBuffer)
        panel.texture = screen.outputTexture
      }
    }


    welcomeScreen.projectsGrid.panels[1].texture = screens[1].outputTexture

    welcomeScreen.draw(in: view, commandBuffer: commandBuffer)

    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()

    options.mouseDown = false
  }

  func dismissSingleProject() {
//    scene.dismissSingleProject()
  }
}
