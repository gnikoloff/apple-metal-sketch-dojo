//
//  OrthographicCamera.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 04.01.23.
//

// swiftlint:disable identifier_name

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
  var zoom: Float = 1

  var viewMatrix: float4x4 {
    return float4x4(eye: position, center: target, up: up)
  }

  var projectionMatrix: float4x4 {
    let dx = (self.right - self.left) / (zoom * 2)
    let dy = (self.top - self.bottom) / (zoom * 2)
    let cx = (self.right + self.left) / 2
    let cy = (self.top + self.bottom) / 2
    let left = cx - dx
    let right = cx + dx
    let top = cy + dy
    let bottom = cy - dy

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
//    aspect = size.width / size.height  
  }

  mutating func update(deltaTime: Float, pinchFactor: Float? = 0) {
//    let transform = updateInput(deltaTime: deltaTime)
//    position += transform.position
//    let input = InputController.shared
//    let zoom = input.mouseScroll.x + input.mouseScroll.y
//    viewSize -= CGFloat(zoom)
//    input.mouseScroll = .zero
  }
}

