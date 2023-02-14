//
//  Panel.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import MetalKit

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

//  lazy private var settingsBuffer: MTLBuffer = {
//    Renderer.device.makeBuffer(
//      length: MemoryLayout<WelcomeScreen_FragmentSettings>.stride
//    )!
//  }()

  init(dots: [Dot], name: String) {
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
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index
    )
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
