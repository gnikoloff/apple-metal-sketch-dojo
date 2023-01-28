//
//  Camera.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 04.01.23.
//

// swiftlint:disable identifier_name

import CoreGraphics
import simd

protocol Camera: Transformable {
  var projectionMatrix: float4x4 { get }
  var viewMatrix: float4x4 { get }
  mutating func update(size: CGSize)
  mutating func update(deltaTime: Float)
}

extension Camera {
  func getFrustumCornersWorldSpace() -> [float4] {
    let inv = (projectionMatrix * viewMatrix).inverse
    var frustumCorners: [float4] = []
    for x in 0 ..< 2 {
      for y in 0 ..< 2 {
        for z in 0 ..< 2 {
          let pt = inv * float4(2.0 * Float(x) - 1.0,
                                2.0 * Float(y) - 1.0,
                                2.0 * Float(z) - 1.0,
                                1.0)
          frustumCorners.append(pt / pt.w)
        }
      }
    }
    return frustumCorners
  }
}
