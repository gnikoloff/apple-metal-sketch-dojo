//
//  Options.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import Foundation

class Options: ObservableObject {
  static private let OFFSCREEN_MOUSE_POS = CGPoint(x: -2000, y: -2000)

  @Published var activeProjectName: String?
  @Published var projects = [
    ProjectModel(name: PointsShadowmap.SCREEN_NAME),
    ProjectModel(name: InfiniteSpace.SCREEN_NAME),
    ProjectModel(name: AppleMetalScreen.SCREEN_NAME),
    ProjectModel(name: CascadedShadowsMap.SCREEN_NAME)
  ]
  @Published var isProjectTransition = false

  var drawableSize: CGSize = .zero
  var mouse: CGPoint = OFFSCREEN_MOUSE_POS
  var pinchFactor: CGFloat = CGFloat(1)
  var mouseDown: Bool = false

  func resetMousePos() {
    mouse = Self.OFFSCREEN_MOUSE_POS
  }
}
