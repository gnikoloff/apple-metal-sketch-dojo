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
  var name: String
  var zIndex: Int = 0
  weak var texture: MTLTexture!

  private var uniforms = Uniforms()
  private var width: Float
  private var height: Float

  var dotNW: Dot
  var dotNE: Dot
  var dotSE: Dot
  var dotSW: Dot

  var polygon: [float2] {
    [dotNE.pos, dotNE.pos, dotSW.pos, dotSE.pos]
  }

  private var indices: [UInt16] = [
    0, 1, 2,
    2, 1, 3
  ]

  lazy private var vertexBuffer: MTLBuffer = {
    Renderer.device.makeBuffer(
      length: MemoryLayout<float4>.stride * 4
    )!
  }()

  lazy private var indexBuffer: MTLBuffer = {
    Renderer.device.makeBuffer(
      bytes: &indices,
      length: MemoryLayout<UInt16>.stride * 6
    )!
  }()

  init(width: Float, height: Float, dots: [Dot], name: String) {
    self.width = width
    self.height = height
    self.name = name

    self.dotNW = dots[0]
    self.dotNE = dots[1]
    self.dotSE = dots[2]
    self.dotSW = dots[3]
  }
}

extension Panel {
  func expand(factor: Float, screenWidth: Float, screenHeight: Float) {
    let topLeft = float2.zero
    let topRight = float2(screenWidth, 0)
    let bottomLeft = float2(0, screenHeight)
    let bottomRight = float2(screenWidth, screenHeight)

    dotNW.expandPos = topLeft
    dotNW.physicsMixFactor = 1 - simd_clamp(0, 1, factor * 1)

    dotNE.expandPos = topRight
    dotNE.physicsMixFactor = 1 - simd_clamp(0, 1, factor * 2)

    dotSE.expandPos = bottomLeft
    dotSE.physicsMixFactor = 1 - simd_clamp(0, 1, factor * 3)

    dotSW.expandPos = bottomRight
    dotSW.physicsMixFactor = 1 - simd_clamp(0, 1, factor * 3)
  }
  func collapse(factor: Float) {
    dotNW.physicsMixFactor = simd_clamp(0, 1, factor * 1)
    dotNE.physicsMixFactor = simd_clamp(0, 1, factor * 2)
    dotSE.physicsMixFactor = simd_clamp(0, 1, factor * 3)
    dotSW.physicsMixFactor = simd_clamp(0, 1, factor * 4)
  }

  func beforeExpand(screenWidth: Float, screenHeight: Float) {
    // ...
  }

  func afterExpand() {
    // ...
  }

  func beforeClose() {
    dotNW.targetPosPhysics += float2.random(in: -20 ..< 20)
    dotNE.targetPosPhysics += float2.random(in: -20 ..< 20)
    dotSE.targetPosPhysics += float2.random(in: -20 ..< 20)
    dotSW.targetPosPhysics += float2.random(in: -20 ..< 20)
  }

  func afterClose() {
    // ...
  }

  func updateInterleavedArray(uvx: Float, uvy: Float, uvw: Float, uvh: Float) {
    
    let interleavedArray = vertexBuffer
      .contents()
      .bindMemory(to: Float.self, capacity: 16)

    interleavedArray[0] = dotNW.pos.x
    interleavedArray[1] = dotNW.pos.y
    interleavedArray[2] = uvx
    interleavedArray[3] = uvy // 0

    interleavedArray[4] = dotNE.pos.x
    interleavedArray[5] = dotNE.pos.y
    interleavedArray[6] = uvw
    interleavedArray[7] = uvy // 0

    interleavedArray[8] = dotSE.pos.x
    interleavedArray[9] = dotSE.pos.y
    interleavedArray[10] = uvx
    interleavedArray[11] = uvh // 1

    interleavedArray[12] = dotSW.pos.x
    interleavedArray[13] = dotSW.pos.y
    interleavedArray[14] = uvw
    interleavedArray[15] = uvh // 1
  }

  func draw(
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
      vertexBuffer,
      offset: 0,
      index: 0
    )
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
