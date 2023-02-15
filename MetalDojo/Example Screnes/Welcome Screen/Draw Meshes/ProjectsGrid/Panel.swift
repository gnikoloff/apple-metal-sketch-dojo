//
//  Panel.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import MetalKit
import UIKit

class Panel: Equatable {
  static func == (lhs: Panel, rhs: Panel) -> Bool {
    lhs.uuid == rhs.uuid
  }

  private var uuid = UUID()
  var dots: [Dot]
  var name: String
  var zIndex: Int = 0
  weak var texture: MTLTexture!

  private var uniforms = Uniforms()
  private var width: Float
  private var height: Float
  private var oldDot0Pos = float2.zero

  private var indices: [UInt16] = [
    0, 1, 2,
    2, 1, 3
  ]

  lazy private var vertexBuffer: MTLBuffer = {
    Renderer.device.makeBuffer(
      length: MemoryLayout<float4>.stride * 4
    )!
  }()

  lazy private var debugAABBVertexBuffer: MTLBuffer = {
    Renderer.device.makeBuffer(
      length: MemoryLayout<float2>.stride * 5
    )!
  }()

  lazy private var indexBuffer: MTLBuffer = {
    Renderer.device.makeBuffer(
      bytes: &indices,
      length: MemoryLayout<UInt16>.stride * 6
    )!
  }()

//  lazy private var settingsBuffer: MTLBuffer = {
//    Renderer.device.makeBuffer(
//      length: MemoryLayout<WelcomeScreen_FragmentSettings>.stride
//    )!
//  }()

  init(width: Float, height: Float, dots: [Dot], name: String) {
    self.width = width
    self.height = height
    self.dots = dots
    self.name = name
  }
}

extension Panel {
  func expand(factor: Float, screenWidth: Float, screenHeight: Float) {
    let topLeft = float2.zero
    let topRight = float2(screenWidth, 0)
    let bottomLeft = float2(0, screenHeight)
    let bottomRight = float2(screenWidth, screenHeight)

    let nearestTopLeft = dots.sorted(by: { d0, d1 in
      d0.pos.dist(to: topLeft) < d1.pos.dist(to: topLeft)
    }).first!

    let nearestTopRight = dots.sorted(by: { d0, d1 in
      d0.pos.dist(to: topRight) < d1.pos.dist(to: topRight)
    }).first!

    let nearestBottomLeft = dots.sorted(by: { d0, d1 in
      d0.pos.dist(to: bottomLeft) < d1.pos.dist(to: bottomLeft)
    }).first!

    let nearestBottomRight = dots.sorted(by: { d0, d1 in
      d0.pos.dist(to: bottomRight) < d1.pos.dist(to: bottomRight)
    }).first!

    nearestTopLeft.expandPos.x = 0
    nearestTopLeft.expandPos.y = 0
    nearestTopLeft.physicsMixFactor = 1 - simd_clamp(0, 1, factor * 1)

    nearestTopRight.expandPos.x = screenWidth
    nearestTopRight.expandPos.y = 0
    nearestTopRight.physicsMixFactor = 1 - simd_clamp(0, 1, factor * 2)

    nearestBottomLeft.expandPos.x = 0
    nearestBottomLeft.expandPos.y = screenHeight
    nearestBottomLeft.physicsMixFactor = 1 - simd_clamp(0, 1, factor * 3)

    nearestBottomRight.expandPos.x = screenWidth
    nearestBottomRight.expandPos.y = screenHeight
    nearestBottomRight.physicsMixFactor = 1 - simd_clamp(0, 1, factor * 4)
  }
  func collapse(factor: Float) {
    for i in 0 ..< dots.count {
      let fi = Float(i)
      let dot = dots[i]
      dot.physicsMixFactor = simd_clamp(0, 1, factor * (fi + 1))
    }
  }

  func beforeExpand() {
    // ...
  }

  func afterExpand() {
    // ...
  }

  func beforeClose() {
    for dot in dots {
      dot.targetPosPhysics += float2.random(in: -20 ..< 20)
    }
  }

  func afterClose() {
    // ...
  }

  func updateInterleavedArray() {
//    var ptr = settingsBuffer.contents().bindMemory(to: WelcomeScreen_FragmentSettings.self, capacity: 1)
//    let width = dots[1].pos.x - dots[0].pos.x
//    let height = dots[2].pos.y - dots[0].pos.y
////    let angle = atan2(height, width)
////    print(angle)
//    ptr.pointee.surfaceSize = float2(width, height)

    var interleavedArray = vertexBuffer.contents().bindMemory(to: Float.self, capacity: 16)
    interleavedArray[0] = dots[1].pos.x
    interleavedArray[1] = dots[1].pos.y
    interleavedArray[2] = 1
    interleavedArray[3] = 0

    interleavedArray[4] = dots[0].pos.x
    interleavedArray[5] = dots[0].pos.y
    interleavedArray[6] = 0
    interleavedArray[7] = 0

    interleavedArray[8] = dots[2].pos.x
    interleavedArray[9] = dots[2].pos.y
    interleavedArray[10] = 1
    interleavedArray[11] = 1

    interleavedArray[12] = dots[3].pos.x
    interleavedArray[13] = dots[3].pos.y
    interleavedArray[14] = 0
    interleavedArray[15] = 1
//
    let leftMostDot = dots.sorted(by: { d0, d1 in
      d0.pos.x < d1.pos.x
    }).first!
    let rightMostDot = dots.sorted(by: { d0, d1 in
      d0.pos.x > d1.pos.x
    }).first!
    let topMostDot = dots.sorted(by: { d0, d1 in
      d0.pos.y < d1.pos.y
    }).first!
    let bottomMostDot = dots.sorted(by: { d0, d1 in
      d0.pos.y > d1.pos.y
    }).first!

    let center = float3(
      x: (leftMostDot.pos.x + rightMostDot.pos.x) / 2,
      y: (topMostDot.pos.y + bottomMostDot.pos.y) / 2,
      z: 0
    )

    let p1 = dots[0].pos
    let p2 = dots[1].pos
    let p3 = float2(rightMostDot.pos.x, topMostDot.pos.x)

    let angle = .pi / 2 - atan(distance(p1, p3) / distance(p2, p3))

    let rotMatrix = float4x4(rotationZ: angle)

    var interleavedAABBDebugArray = debugAABBVertexBuffer
      .contents()
      .bindMemory(to: float2.self, capacity: 5)

    let translateMatrix = float4x4(translation: center)
    let matrix = translateMatrix * rotMatrix

    let _t0 = matrix * float4(x: -width / 2, y: -height / 2, z: 0, w: 1)
    let _t1 = matrix * float4(x: width / 2, y: -height / 2, z: 0, w: 1)
    let _t2 = matrix * float4(x: width / 2, y: height / 2, z: 0, w: 1)
    let _t3 = matrix * float4(x: -width / 2, y: height / 2, z: 0, w: 1)

    interleavedAABBDebugArray[0] = float2(x: _t0.x, y: _t0.y)
    interleavedAABBDebugArray[1] = float2(x: _t1.x, y: _t1.y)
    interleavedAABBDebugArray[2] = float2(x: _t2.x, y: _t2.y)
    interleavedAABBDebugArray[3] = float2(x: _t3.x, y: _t3.y)
    interleavedAABBDebugArray[4] = interleavedAABBDebugArray[0]

    oldDot0Pos = dots[0].pos
  }

  func drawDebugAABB(
    encoder: MTLRenderCommandEncoder,
    cameraUniforms: CameraUniforms
  ) {
    var camUniforms = cameraUniforms
    encoder.setVertexBytes(
      &camUniforms,
      length: MemoryLayout<CameraUniforms>.stride,
      index: UniformsBuffer.index + 1
    )
    encoder.setVertexBuffer(
      debugAABBVertexBuffer,
      offset: 0,
      index: 0
    )
    encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: 5)
  }

  func draw(
    encoder: MTLRenderCommandEncoder,
    cameraUniforms: CameraUniforms
  ) {
    var camUniforms = cameraUniforms

//    uniforms.uvMatrix = float3x3.makeUvTransform(
//      tx: 0,
//      ty: 0,
//      sx: 1,
//      sy: 1,
//      rotation: angle,
//      cx: 0.5,
//      cy: 0.5
//    )

    encoder.setVertexBytes(
      &camUniforms,
      length: MemoryLayout<CameraUniforms>.stride,
      index: UniformsBuffer.index + 1
    )
    encoder.setVertexBuffer(
      vertexBuffer,
      offset: 0,
      index: 0
    )
//    encoder.setFragmentBuffer(
//      settingsBuffer,
//      offset: 0,
//      index: FragmentSettingsBuffer.index
//    )
    encoder.setFragmentTexture(
      texture,
      index: ProjectTexture.index
    )
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: indices.count,
      indexType: .uint16,
      indexBuffer: indexBuffer,
      indexBufferOffset: 0
    )
  }
}
