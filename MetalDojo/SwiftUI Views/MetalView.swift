//
//  MetalView.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import SwiftUI
import MetalKit

struct MetalView: View {
  @State private var dpr = UIScreen().scale
  @State private var previousTranslation = CGSize.zero
  @State private var previousScroll: CGFloat = 1
  @State private var scale: CGFloat = 1
  @State private var lastScale: CGFloat = 1
  @State private var isDemoInfoOpen: Bool = false
  @State private var metalView = MTKView()
  @State private var gameController: GameController?

  @EnvironmentObject var options: Options

  var body: some View {
    let dragGesture = DragGesture()
      .onChanged { value in
        InputController.shared.touchLocation = value.location
        InputController.shared.touchDelta = CGSize(
          width: value.translation.width - previousTranslation.width,
          height: value.translation.height - previousTranslation.height)
        previousTranslation = value.translation
        options.mouse = value.location
        options.mouse.x *= dpr
        options.mouse.y *= dpr
        InputController.shared.touchLocation = value.location
      }
      .onEnded { _ in
        options.resetMousePos()
        previousTranslation = .zero
      }
    let pinchGesture = MagnificationGesture()
      .onChanged { val in
        let delta = val / self.lastScale
        lastScale = val
        let newScale = scale * delta
        scale = newScale
        options.pinchFactor = scale
      }
      .onEnded { _ in
        self.lastScale = 1
      }
    let simultGesture = SimultaneousGesture(dragGesture, pinchGesture)
    return ZStack {
      GeometryReader { geometry in
        MetalViewRepresentable(
          metalView: $metalView,
          gameController: gameController
        )
          .ignoresSafeArea(.all)
          .onAppear {
            options.drawableSize = geometry.size * dpr
            gameController = GameController(
              metalView: metalView,
              options: options
            )
          }
          .gesture(simultGesture)
          .onClickGesture { point in
            options.mouse = point
            options.mouse.x *= dpr
            options.mouse.y *= dpr

            options.mouseDown = true
          }
      }
      if let activeProjectName = options.activeProjectName,
         !options.isProjectTransition {
        DemoHeaderView(
          activeProjectName: activeProjectName,
          isDemoInfoOpen: $isDemoInfoOpen,
          gameController: $gameController
        )
        if isDemoInfoOpen {
          DemoInfoView(
            activeProjectName: activeProjectName,
            isDemoInfoOpen: $isDemoInfoOpen
          )
        }
      }
    }
  }
}

struct MetalViewRepresentable: UIViewRepresentable {
  @Binding var metalView: MTKView

  let gameController: GameController?

  func makeUIView(context: Context) -> MTKView {
    metalView
  }

  func updateUIView(_ uiView: MTKView, context: Context) {
    updateMetalView()
  }

  func updateMetalView() {
//    gameController?.options = options
  }
}

struct MetalView_Previews: PreviewProvider {
  static var previews: some View {
    MetalView()
  }
}
