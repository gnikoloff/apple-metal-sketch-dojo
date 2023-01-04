//
//  FPCamera.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 04.01.23.
//

import CoreGraphics
import simd

struct FPCamera: Camera {
  var transform = Transform()

  var aspect: Float = 1.0
  var fov = Float(70).degreesToRadians
  var near: Float = 0.1
  var far: Float = 100
  var projectionMatrix: float4x4 {
    float4x4(
      projectionFov: fov,
      near: near,
      far: far,
      aspect: aspect)
  }

  mutating func update(size: CGSize) {
    aspect = Float(size.width / size.height)
  }

  var viewMatrix: float4x4 {
    (float4x4(translation: position) *
    float4x4(rotation: rotation)).inverse
  }

  mutating func update(deltaTime: Float) {
//    let transform = updateInput(deltaTime: deltaTime)
//    rotation += transform.rotation
//    position += transform.position
  }
}
