//
//  Options.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import Foundation
import UIKit

class Options: ObservableObject {
  static private let OFFSCREEN_MOUSE_POS = float2(x: -2000, y: -2000)

  @Published var activeProjectName: String = WelcomeScreen.SCREEN_NAME
  @Published var projects = [
    ProjectModel(name: PointsShadowmap.SCREEN_NAME),
    ProjectModel(name: InfiniteSpace.SCREEN_NAME),
    ProjectModel(name: AppleMetalScreen.SCREEN_NAME),
    ProjectModel(name: CascadedShadowsMap.SCREEN_NAME)
  ]
  @Published var isProjectTransition = false
  @Published var isIphone = UIDevice.current.userInterfaceIdiom == .phone

  var drawableSize: float2 = .zero
  var mouse: float2 = OFFSCREEN_MOUSE_POS
  var realMouse: float2 = .zero
  var mouseDown: Bool = false

  var isHomescreen: Bool {
    get {
      activeProjectName == WelcomeScreen.SCREEN_NAME
    }
  }

  var hasTopNotch: Bool {
      if #available(iOS 11.0, tvOS 11.0, *) {
          return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
      }
      return false
  }

  func resetMousePos() {
    mouse = Self.OFFSCREEN_MOUSE_POS
  }
}
