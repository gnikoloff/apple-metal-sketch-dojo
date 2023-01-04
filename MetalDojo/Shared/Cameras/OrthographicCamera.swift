//
//  OrthographicCamera.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 04.01.23.
//

import CoreGraphics
import simd

struct OrthographicCamera: Camera {
  var transform = Transform()
  var aspect: CGFloat = 1
  var viewSize: CGSize = CGSize(width: 10, height: 10)
  var near: Float = 0.1
  var far: Float = 100
  var center = float3.zero

  var viewMatrix: float4x4 {
    (float4x4(translation: position) *
    float4x4(rotation: rotation)).inverse
  }

  var projectionMatrix: float4x4 {
    return float4x4(
      left: 0,
      right: Float(viewSize.width),
      bottom: Float(viewSize.height),
      top: 0,
      near: near,
      far: far
    )
  }

  mutating func update(size: CGSize) {
    aspect = size.width / size.height
    viewSize = size
  }

  mutating func update(deltaTime: Float) {
//    let transform = updateInput(deltaTime: deltaTime)
//    position += transform.position
//    let input = InputController.shared
//    let zoom = input.mouseScroll.x + input.mouseScroll.y
//    viewSize -= CGFloat(zoom)
//    input.mouseScroll = .zero
  }
}

