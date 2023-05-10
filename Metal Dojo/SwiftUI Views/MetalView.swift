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
  @State private var isDemoInfoOpen: Bool = false
  @State private var isInfoOverlayOpen: Bool = false
  @State private var metalView = MTKView()
  @State private var gameController: GameController?
  @State private var showMainHeader: Bool = false
  @State private var isInstructionViewVisible: Bool = false

  @EnvironmentObject var options: Options

  var body: some View {
    let dragGesture = DragGesture()
      .onChanged { value in
        InputController.shared.touchLocation = value.location
        InputController.shared.touchDelta = CGSize(
          width: value.translation.width - previousTranslation.width,
          height: value.translation.height - previousTranslation.height)
        previousTranslation = value.translation
        options.mouse = value.location.asFloat2()
        options.realMouse = value.location.asFloat2()
        let fdpr = Float(dpr)
        options.mouse.x *= fdpr
        options.mouse.y *= fdpr
        options.realMouse.x *= fdpr
        options.realMouse.y *= fdpr
        InputController.shared.touchLocation = value.location
      }
      .onEnded { _ in
        options.resetMousePos()
        previousTranslation = .zero
      }
    let pinchGesture = MagnificationGesture()
      .onChanged { val in
        let diff = val - scale
        if diff < 0 {
          InputController.shared.pinchFactors[options.activeProjectName]! += 0.1
        } else {
          InputController.shared.pinchFactors[options.activeProjectName]! -= 0.1
        }
        scale = val
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
            options.drawableSize = (geometry.size * dpr).asFloat2()
            gameController = GameController(
              metalView: metalView,
              options: options
            )
          }
          .gesture(simultGesture)
          .onClickGesture { point in
            options.mouse = point.asFloat2()
            options.realMouse = point.asFloat2()
            let fdpr = Float(dpr)
            options.mouse.x *= fdpr
            options.mouse.y *= fdpr

            options.mouseDown = true
          }
      }
      if !options.isHomescreen,
         !options.isProjectTransition {
        DemoHeaderView(
          activeProjectName: options.activeProjectName,
          isDemoInfoOpen: $isDemoInfoOpen,
          gameController: $gameController
        )
        if isDemoInfoOpen {
          DemoInfoView(
            activeProjectName: options.activeProjectName,
            isDemoInfoOpen: $isDemoInfoOpen
          )
        }
      }

      MainHeaderView(isInfoOverlayOpen: $isInfoOverlayOpen, visible: $showMainHeader)
      InfoOverlayView(isInfoOverlayOpen: $isInfoOverlayOpen)
      OrientCameraInstructionView(
        isInstructionViewVisible: $isInstructionViewVisible,
        isDemoInfoOpen: $isDemoInfoOpen
      )
    }
    .onReceive(options.$activeProjectName) { activeProjectName in
      withAnimation {
        self.showMainHeader = activeProjectName == WelcomeScreen.SCREEN_NAME
      }
      if activeProjectName != WelcomeScreen.SCREEN_NAME {
        withAnimation(.linear.delay(0.5)) {
          self.isInstructionViewVisible = true
        }
      } else {
        self.isInstructionViewVisible = false
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
