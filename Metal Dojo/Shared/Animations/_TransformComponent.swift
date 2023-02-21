//
//  TransformComponent.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

import Foundation
import ModelIO

struct TransformComponent {
  let keyTransforms: [float4x4]
  let duration: Float
  var currentTransform: float4x4 = .identity

  init(
    transform: MDLTransformComponent,
    object: MDLObject,
    startTime: TimeInterval,
    endTime: TimeInterval
  ) {
    duration = Float(endTime - startTime)
    let timeStride = stride(
      from: startTime,
      to: endTime,
      by: 1 / TimeInterval(GameController.fps)
    )

    keyTransforms = Array(timeStride).map { time in
      MDLTransform.globalTransform(
        with: object,
        atTime: time)
    }
  }

  mutating func getCurrentTransform(at time: Float) {
    guard duration > 0 else {
      currentTransform = .identity
      return
    }
    let frame = Int(fmod(time, duration) * Float(GameController.fps))
    if frame < keyTransforms.count {
      currentTransform = keyTransforms[frame]
    } else {
      currentTransform = keyTransforms.last ?? .identity
    }
  }
}
