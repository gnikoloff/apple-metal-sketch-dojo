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
  
  var body: some Scene {
    WindowGroup {
      MetalView()
        .environmentObject(options)
    }
  }
}
