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
  @State private var metalView = MTKView()
  @State private var gameController: GameController?
  @State private var previousTranslation = CGSize.zero
  @State private var previousScroll: CGFloat = 1
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
//        print(value.location.y * 2 / metalView.drawableSize.height)
        options.mouse.x *= dpr
        options.mouse.y *= dpr
        InputController.shared.touchLocation = value.location
//        if abs(value.translation.width) > 1 ||
//          abs(value.translation.height) > 1 {
//          InputController.shared.touchLocation = nil
//        }
//        print(InputController.shared.touchLocation)
      }
      .onEnded { _ in
//        options.mouse = CGPoint(x: -1000, y: -1000)
        previousTranslation = .zero
      }
    return ZStack {
      GeometryReader { geometry in
        MetalViewRepresentable(metalView: $metalView, gameController: gameController)
          .ignoresSafeArea(.all)
          .onAppear {
            options.drawableSize = geometry.size * dpr
            gameController = GameController(
              metalView: metalView,
              options: options
            )
          }
          .gesture(dragGesture)
          .onClickGesture { point in
            options.mouse = point
            options.mouse.x *= dpr
            options.mouse.y *= dpr

            options.mouseDown = true
          }
      }
      if let activeProjectName = options.activeProjectName {
        VStack {
          HStack {
            Button(action: {
              gameController!.dismissSingleProject()
              options.activeProjectName = nil
            }) {
              Text("Back")
            }
            Spacer()
            Text(activeProjectName)
          }
            .padding()
          Spacer()
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
