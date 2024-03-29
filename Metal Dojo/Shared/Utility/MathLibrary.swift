//
//  MathLibrary.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable type_name
// swiftlint:disable identifier_name
// swiftlint:disable comma

import simd
import UIKit
import CoreGraphics

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

let π = Float.pi

extension Float {
  var radiansToDegrees: Float {
    (self / π) * 180
  }
  var degreesToRadians: Float {
    (self / 180) * π
  }
}

// MARK: - float4
extension float4x4 {
  // MARK: - Translate
  init(translation: float3) {
    let matrix = float4x4(
      [            1,             0,             0, 0],
      [            0,             1,             0, 0],
      [            0,             0,             1, 0],
      [translation.x, translation.y, translation.z, 1]
    )
    self = matrix
  }

  // MARK: - Scale
  init(scaling: float3) {
    let matrix = float4x4(
      [scaling.x,         0,         0, 0],
      [        0, scaling.y,         0, 0],
      [        0,         0, scaling.z, 0],
      [        0,         0,         0, 1]
    )
    self = matrix
  }

  init(scaling: Float) {
    self = matrix_identity_float4x4
    columns.3.w = 1 / scaling
  }

  // MARK: - Rotate
  init(rotationX angle: Float) {
    let matrix = float4x4(
      [1,           0,          0, 0],
      [0,  cos(angle), sin(angle), 0],
      [0, -sin(angle), cos(angle), 0],
      [0,           0,          0, 1]
    )
    self = matrix
  }

  init(rotationY angle: Float) {
    let matrix = float4x4(
      [cos(angle), 0, -sin(angle), 0],
      [         0, 1,           0, 0],
      [sin(angle), 0,  cos(angle), 0],
      [         0, 0,           0, 1]
    )
    self = matrix
  }

  init(rotationZ angle: Float) {
    let matrix = float4x4(
      [ cos(angle), sin(angle), 0, 0],
      [-sin(angle), cos(angle), 0, 0],
      [          0,          0, 1, 0],
      [          0,          0, 0, 1]
    )
    self = matrix
  }

  init(rotation angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationX * rotationY * rotationZ
  }

  init(rotationYXZ angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationY * rotationX * rotationZ
  }

  // MARK: - Identity
  static var identity: float4x4 {
    matrix_identity_float4x4
  }

  // MARK: - Upper left 3x3
  var upperLeft: float3x3 {
    let x = columns.0.xyz
    let y = columns.1.xyz
    let z = columns.2.xyz
    return float3x3(columns: (x, y, z))
  }

  // MARK: - Left handed projection matrix
  init(projectionFov fov: Float, near: Float, far: Float, aspect: Float, lhs: Bool = true) {
    let y = 1 / tan(fov * 0.5)
    let x = y / aspect
    let z = lhs ? far / (far - near) : far / (near - far)
    let X = float4( x,  0,  0,  0)
    let Y = float4( 0,  y,  0,  0)
    let Z = lhs ? float4( 0,  0,  z, 1) : float4( 0,  0,  z, -1)
    let W = lhs ? float4( 0,  0,  z * -near,  0) : float4( 0,  0,  z * near,  0)
    self.init()
    columns = (X, Y, Z, W)
  }

  // left-handed LookAt
  init(eye: float3, center: float3, up: float3) {
    let z = normalize(center - eye)
    let x = normalize(cross(up, z))
    let y = cross(z, x)

    let X = float4(x.x, y.x, z.x, 0)
    let Y = float4(x.y, y.y, z.y, 0)
    let Z = float4(x.z, y.z, z.z, 0)
    let W = float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)

    self.init()
    columns = (X, Y, Z, W)
  }

  // MARK: - Orthographic matrix
  init(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
    self.init()
    columns = (
      [ 2 / (right - left), 0, 0, 0],
      [0, 2 / (top - bottom), 0, 0],
      [0, 0, 1 / (far - near), 0],
      [(left + right) / (left - right), (top + bottom) / (bottom - top), near / (near - far), 1]
      )
//      let left = Float(rect.origin.x)
//    let right = Float(rect.origin.x + rect.width)
//    let top = Float(rect.origin.y)
//    let bottom = Float(rect.origin.y - rect.height)
//    let X = float4(2 / (right - left), 0, 0, 0)
//    let Y = float4(0, 2 / (top - bottom), 0, 0)
//    let Z = float4(0, 0, 1 / (far - near), 0)
//    let W = float4(
//      (left + right) / (left - right),
//      (top + bottom) / (bottom - top),
//      near / (near - far),
//      1)
//    self.init()
//    columns = (X, Y, Z, W)
  }

  // convert double4x4 to float4x4
  init(_ m: matrix_double4x4) {
    self.init()
    let matrix = float4x4(
      float4(m.columns.0),
      float4(m.columns.1),
      float4(m.columns.2),
      float4(m.columns.3))
    self = matrix
  }
}

// MARK: - float3x3
extension float3x3 {
  init(normalFrom4x4 matrix: float4x4) {
    self.init()
    columns = matrix.upperLeft.inverse.transpose.columns
  }
  static func makeUvTransform(tx: Float, ty: Float, sx: Float, sy: Float, rotation: Float, cx: Float, cy: Float) -> float3x3 {
    let c = cos(rotation)
    let s = sin(rotation)
    let col0 = float3(sx * c, -sy * c, 0)
    let col1 = float3(sx * c, sy * c, 0)
    let col2 = float3(-sx * (c * cx + s * cy) + cx + tx, -sy * (-s * cx + c * cy) + cy + ty, 1)
    return float3x3(columns: (col0, col1, col2))
  }
}

// MARK: - float2
extension float2 {
  static func * (lhs: float2, rhs: Float) -> float2 {
    float2(lhs.x * rhs, lhs.y * rhs)
  }
  static func - (lhs: float2, rhs: CGPoint) -> float2 {
    float2(lhs.x - Float(rhs.x), lhs.y - Float(rhs.y))
  }
  func asCGSize() -> CGSize {
    return CGSize(width: CGFloat(self.x), height: CGFloat(self.y))
  }
  func isInside(polygon: [float2]) -> Bool {
    var pJ = polygon.last!

    let x = Float(self.x)
    let y = Float(self.y)

    var minX = polygon[0].x
    var maxX = polygon[0].x
    var minY = polygon[0].y
    var maxY = polygon[0].y

    for i in 1 ..< polygon.count {
      let p = polygon[i]

      minX = Swift.min(p.x, minX)
      maxX = Swift.max(p.x, maxX)

      minY = Swift.min(p.y, minY)
      maxY = Swift.max(p.y, maxY)
    }

    if x < minX || x > maxX || y < minY || y > maxY {
      return false
    }

    for pI in polygon {
      if ((pI.y >= y) != (pJ.y >= y)) && (x <= (pJ.x - pI.x) * (y - pI.y) / (pJ.y - pI.y) + pI.x) {
        return true
      }
      pJ = pI
    }

    return false
  }
  func dist(to: float2) -> Float {
    let dx = to.x - self.x
    let dy = to.y - self.y
    return sqrtf(dx * dx + dy * dy)
  }
  func mag() -> Float {
    sqrtf(self.x * self.x + self.y * self.y)
  }
  func magSq() -> Float {
    self.x * self.x + self.y * self.y
  }
  func normalizeTo(length: Float) -> float2 {
    var val = self
    var mag = mag()
    if mag > 0 {
      mag = length / mag
      val *= mag
    }
    return val
  }
}

// MARK: - float3
extension float3 {
  static func /=(lhs: inout float3, rhs: Int) {
    let frhs = Float(rhs)
    lhs = lhs / frhs
  }
  func isParallelTo(_ vecB: float3) -> Bool {
    cross(self, vecB) == float3.zero
  }
}

// MARK: - float4
extension float4 {
  var xyz: float3 {
    get {
      float3(x, y, z)
    }
    set {
      x = newValue.x
      y = newValue.y
      z = newValue.z
    }
  }

  // convert from double4
  init(_ d: SIMD4<Double>) {
    self.init()
    self = [Float(d.x), Float(d.y), Float(d.z), Float(d.w)]
  }
}

// MARK: - CGSize
extension CGSize {
  func asFloat2() -> float2 {
    float2(x: Float(self.width), y: Float(self.height))
  }
}

extension CGSize {
  static func *= (lhs: CGSize, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
  }
  static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
  }
}


// MARK: - CGPoint
extension CGPoint {
  func asFloat2() -> float2 {
    float2(x: Float(self.x), y: Float(self.y))
  }
  static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }
  static func += (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }
  static func * (lhs: CGPoint, rhs: Float) -> CGPoint {
    CGPoint(x: lhs.x * CGFloat(rhs), y: lhs.y * CGFloat(rhs))
  }
}

