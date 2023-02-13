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
  var left: Float = -1
  var right: Float = 1
  var top: Float = 1
  var bottom: Float = -1
  var near: Float = 0.1
  var far: Float = 100
  var center = float3.zero
  var target: float3 = [0, 0, 0]
  var up: float3 = [0, 1, 0]

  var viewMatrix: float4x4 {
    return float4x4(eye: position, center: target, up: up)
  }

  var projectionMatrix: float4x4 {
    return float4x4(
      left: left,
      right: right,
      bottom: bottom,
      top: top,
      near: near,
      far: far
    )
  }

  mutating func update(size: CGSize) {
    left = 0
    right = Float(size.width)
    bottom = 0
    top = Float(size.height)
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

