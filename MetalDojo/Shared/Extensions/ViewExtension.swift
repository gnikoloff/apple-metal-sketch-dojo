//
//  ViewExtension.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 28.12.22.
//

import SwiftUI

extension View {
  func onClickGesture(
    count: Int,
    coordinateSpace: CoordinateSpace = .local,
    perform action: @escaping (CGPoint) -> Void
  ) -> some View {
    gesture(ClickGesture(count: count, coordinateSpace: coordinateSpace)
        .onEnded(perform: action)
    )
  }

  func onClickGesture(
    count: Int,
    perform action: @escaping (CGPoint) -> Void
  ) -> some View {
    onClickGesture(count: count, coordinateSpace: .local, perform: action)
  }

  func onClickGesture(
    perform action: @escaping (CGPoint) -> Void
  ) -> some View {
    onClickGesture(count: 1, coordinateSpace: .local, perform: action)
  }
}
