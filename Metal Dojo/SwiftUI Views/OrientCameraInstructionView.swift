//
//  MoveFingerInstructionView.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 19.02.23.
//

import SwiftUI

struct OrientCameraInstructionView: View {
  @Binding var isInstructionViewVisible: Bool
  @Binding var isDemoInfoOpen: Bool

  @EnvironmentObject var options: Options

  var body: some View {
    let isInfiniteLightDemo = options.activeProjectName == InfiniteSpace.SCREEN_NAME

    let visible = isInstructionViewVisible && !isDemoInfoOpen

    VStack {
      Spacer()
      HStack {
        Spacer()
        HStack {
          Image(systemName: isInfiniteLightDemo ? "arrow.left.arrow.right" : "move.3d")
          Text(isInfiniteLightDemo ? "Move finger horizontally to move camera" : "Use fingers to orient the camera")
        }
        .foregroundColor(.white)
        Spacer()
      }
      .padding(24)
    }
    .opacity(visible ? 1 : 0)
  }
}
