//
//  MetalDojoApp.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import SwiftUI

@main
struct MetalDojoApp: App {
  @StateObject var options = Options()
  @State private var hasTimeElapsed = false

  private func delay() async {
    try? await Task.sleep(nanoseconds: 1_000)
    hasTimeElapsed = true
  }
  
  var body: some Scene {
    WindowGroup {
      ZStack {
        SplashScreenView()
          .opacity(options.isAnimationReady ? 0 : 1)
          .zIndex(2)
          .task(delay)
        if hasTimeElapsed {
          MetalView()
            .environmentObject(options)
            .zIndex(1)
        }
      }
    }
  }
}
