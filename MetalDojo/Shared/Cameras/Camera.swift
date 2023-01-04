//
//  Camera.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 04.01.23.
//

import CoreGraphics
import simd

protocol Camera: Transformable {
  var projectionMatrix: float4x4 { get }
  var viewMatrix: float4x4 { get }
  mutating func update(size: CGSize)
  mutating func update(deltaTime: Float)
}
