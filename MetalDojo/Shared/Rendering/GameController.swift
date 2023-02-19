//
//  GameController.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import MetalKit

final class GameController: NSObject {
  static var fps: Double = 0

  var renderer: Renderer
  var options: Options
  var deltaTime: Double = 0
  var lastTime: Double = CFAbsoluteTimeGetCurrent()
  var elapsedTime: Double = 0

  var welcomeScreen: WelcomeScreen
  var demos: [String: Demo] = [:]

  init(metalView: MTKView, options: Options) {
    renderer = Renderer(metalView: metalView)
    self.options = options
    Self.fps = Double(metalView.preferredFramesPerSecond)
    welcomeScreen = WelcomeScreen(options: options)
    super.init()
    metalView.delegate = self
    metalView.framebufferOnly = false

    demos[PointsShadowmap.SCREEN_NAME] = PointsShadowmap(options: options)
    demos[InfiniteSpace.SCREEN_NAME] = InfiniteSpace(options: options)
    demos[AppleMetalScreen.SCREEN_NAME] = AppleMetalScreen(options: options)
    demos[CascadedShadowsMap.SCREEN_NAME] = CascadedShadowsMap(options: options)
  }
}

extension GameController: MTKViewDelegate {
  func mtkView(_ metalView: MTKView, drawableSizeWillChange size: CGSize) {
    options.drawableSize = float2(x: Float(size.width), y: Float(size.height))
    welcomeScreen.resize(view: metalView)

    for (_, demo) in demos {
      demo.resize(view: metalView)
    }
  }
  func draw(in view: MTKView) {
    let currentTime = CFAbsoluteTimeGetCurrent()
    let dt = currentTime - lastTime
    elapsedTime += dt
    lastTime = currentTime

    let felapsedTime = Float(elapsedTime)
    let fdt = Float(dt)

    welcomeScreen.update(elapsedTime: felapsedTime, deltaTime: fdt)

    if options.isHomescreen {
      for (_, demo) in demos {
        demo.update(elapsedTime: felapsedTime, deltaTime: fdt)
      }
    } else {
      demos[options.activeProjectName]!.update(elapsedTime: felapsedTime, deltaTime: fdt)
    }

    guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else {
      return
    }

    if options.isHomescreen {
      for (key, demo) in demos {
        let panel = welcomeScreen.projectsGrid.panels.first { p in
          p.name == key
        }!
        demo.draw(in: view, commandBuffer: commandBuffer)
        panel.texture = demo.outputTexture
      }
    } else {
      let demo = demos[options.activeProjectName]!
      demo.draw(in: view, commandBuffer: commandBuffer)
      let panel = welcomeScreen.projectsGrid.panels.first { p in
        p.name == options.activeProjectName
      }!
      panel.texture = demo.outputTexture
    }

    welcomeScreen.draw(in: view, commandBuffer: commandBuffer)

    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()

    options.mouseDown = false
    InputController.shared.reset()
  }

  func dismissSingleProject() {
    welcomeScreen.dismissSingleProject()
  }
}
