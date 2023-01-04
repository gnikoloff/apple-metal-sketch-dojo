//
//  Camera.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import CoreGraphics
import simd

protocol Camera: Transformable {
  var projectionMatrix: float4x4 { get }
  var viewMatrix: float4x4 { get }
  mutating func update(size: CGSize)
  mutating func update(deltaTime: Float)
}

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

enum Settings {
  static var rotationSpeed: Float { 2.0 }
  static var translationSpeed: Float { 3.0 }
  static var mouseScrollSensitivity: Float { 0.1 }
  static var mousePanSensitivity: Float { 0.008 }
}

struct ArcballCamera: Camera {
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

  let minDistance: Float = 0.0
  let maxDistance: Float = 40
  var target: float3 = [0, 0, 0]
  var distance: Float = 2.5

  mutating func update(size: CGSize) {
    aspect = Float(size.width / size.height)
  }

  var viewMatrix: float4x4 {
    let matrix: float4x4
    if target == position {
      matrix = (float4x4(translation: target) * float4x4(rotationYXZ: rotation)).inverse
    } else {
      matrix = float4x4(eye: position, center: target, up: [0, 1, 0])
    }
    return matrix
  }

  mutating func update(deltaTime: Float) {
    let input = InputController.shared
    let scrollSensitivity = Settings.mouseScrollSensitivity
    distance -= (input.mouseScroll.x + input.mouseScroll.y)
      * scrollSensitivity
    distance = min(maxDistance, distance)
    distance = max(minDistance, distance)
    input.mouseScroll = .zero
    if input.leftMouseDown {
      let sensitivity = Settings.mousePanSensitivity
      rotation.x += input.mouseDelta.y * sensitivity
      rotation.y += input.mouseDelta.x * sensitivity
      rotation.x = max(-.pi / 2, min(rotation.x, .pi / 2))
      input.mouseDelta = .zero
    }
    let rotateMatrix = float4x4(
      rotationYXZ: [-rotation.x, rotation.y, 0])
    let distanceVector = float4(0, 0, -distance, 0)
    let rotatedVector = rotateMatrix * distanceVector
    position = target + rotatedVector.xyz
  }
}

struct PerspectiveCamera: Camera {
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

  let minDistance: Float = 0.0
  let maxDistance: Float = 40
  var target: float3 = [0, 0, 0]
  var distance: Float = 2.5
  var up: float3 = [0, 1, 0]

  mutating func update(size: CGSize) {
    aspect = Float(size.width / size.height)
  }

  var viewMatrix: float4x4 {
    return float4x4(eye: position, center: target, up: up)
  }

  mutating func update(deltaTime: Float) {
//    let input = InputController.shared
//    let scrollSensitivity = Settings.mouseScrollSensitivity
//    distance -= (input.mouseScroll.x + input.mouseScroll.y)
//      * scrollSensitivity
//    distance = min(maxDistance, distance)
//    distance = max(minDistance, distance)
//    input.mouseScroll = .zero
//    if input.leftMouseDown {
//      let sensitivity = Settings.mousePanSensitivity
//      rotation.x += input.mouseDelta.y * sensitivity
//      rotation.y += input.mouseDelta.x * sensitivity
//      rotation.x = max(-.pi / 2, min(rotation.x, .pi / 2))
//      input.mouseDelta = .zero
//    }
//    let rotateMatrix = float4x4(
//      rotationYXZ: [-rotation.x, rotation.y, 0])
//    let distanceVector = float4(0, 0, -distance, 0)
//    let rotatedVector = rotateMatrix * distanceVector
//    position = target + rotatedVector.xyz
  }
}

//struct FPCamera: Camera {
//  var transform = Transform()
//
//  var aspect: Float = 1.0
//  var fov = Float(70).degreesToRadians
//  var near: Float = 0.1
//  var far: Float = 100
//  var projectionMatrix: float4x4 {
//    float4x4(
//      projectionFov: fov,
//      near: near,
//      far: far,
//      aspect: aspect)
//  }
//
//  mutating func update(size: CGSize) {
//    aspect = Float(size.width / size.height)
//  }
//
//  var viewMatrix: float4x4 {
//    (float4x4(translation: position) *
//    float4x4(rotation: rotation)).inverse
//  }
//
//  mutating func update(deltaTime: Float) {
////    let transform = updateInput(deltaTime: deltaTime)
////    rotation += transform.rotation
////    position += transform.position
//  }
//}

//extension FPCamera: Movement { }

//struct ArcballCamera: Camera {
//  var transform = Transform()
//
//  var aspect: Float = 1.0
//  var fov = Float(70).degreesToRadians
//  var near: Float = 0.1
//  var far: Float = 100
//  var projectionMatrix: float4x4 {
//    float4x4(
//      projectionFov: fov,
//      near: near,
//      far: far,
//      aspect: aspect)
//  }
//
//  let minDistance: Float = 0.0
//  let maxDistance: Float = 40
//  var target: float3 = [0, 0, 0]
//  var distance: Float = 2.5
//
//  mutating func update(size: CGSize) {
//    aspect = Float(size.width / size.height)
//  }
//
//  var viewMatrix: float4x4 {
//    let matrix: float4x4
//    if target == position {
//      matrix = (float4x4(translation: target) * float4x4(rotationYXZ: rotation)).inverse
//    } else {
//      matrix = float4x4(eye: position, center: target, up: [0, 1, 0])
//    }
//    return matrix
//  }
//
//  mutating func update(deltaTime: Float) {
//    let input = InputController.shared
//    let scrollSensitivity = Settings.mouseScrollSensitivity
//    distance -= (input.mouseScroll.x + input.mouseScroll.y)
//      * scrollSensitivity
//    distance = min(maxDistance, distance)
//    distance = max(minDistance, distance)
//    input.mouseScroll = .zero
//    if input.leftMouseDown {
//      let sensitivity = Settings.mousePanSensitivity
//      rotation.x += input.mouseDelta.y * sensitivity
//      rotation.y += input.mouseDelta.x * sensitivity
//      rotation.x = max(-.pi / 2, min(rotation.x, .pi / 2))
//      input.mouseDelta = .zero
//    }
//    let rotateMatrix = float4x4(
//      rotationYXZ: [-rotation.x, rotation.y, 0])
//    let distanceVector = float4(0, 0, -distance, 0)
//    let rotatedVector = rotateMatrix * distanceVector
//    position = target + rotatedVector.xyz
//  }
//}
//
//struct OrthographicCamera: Camera, Movement {
//  var transform = Transform()
//  var aspect: CGFloat = 1
//  var viewSize: CGFloat = 10
//  var near: Float = 0.1
//  var far: Float = 100
//  var center = float3.zero
//
//  var viewMatrix: float4x4 {
//    (float4x4(translation: position) *
//    float4x4(rotation: rotation)).inverse
//  }
//
//  var projectionMatrix: float4x4 {
//    let rect = CGRect(
//      x: -viewSize * aspect * 0.5,
//      y: viewSize * 0.5,
//      width: viewSize * aspect,
//      height: viewSize)
//    return float4x4(orthographic: rect, near: near, far: far)
//  }
//
//  mutating func update(size: CGSize) {
//    aspect = size.width / size.height
//  }
//
//  mutating func update(deltaTime: Float) {
//    let transform = updateInput(deltaTime: deltaTime)
//    position += transform.position
//    let input = InputController.shared
//    let zoom = input.mouseScroll.x + input.mouseScroll.y
//    viewSize -= CGFloat(zoom)
//    input.mouseScroll = .zero
//  }
//}
//
