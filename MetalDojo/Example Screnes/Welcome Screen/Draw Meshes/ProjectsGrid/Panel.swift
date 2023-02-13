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
  var project: ProjectModel
  var zIndex: Int = 0
  weak var texture: MTLTexture!

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

  lazy private var settingsBuffer: MTLBuffer = {
    Renderer.device.makeBuffer(
      length: MemoryLayout<WelcomeScreen_FragmentSettings>.stride
    )!
  }()

  init(size: float2, dots: [Dot], project: ProjectModel) {
    self.dots = dots
    self.project = project
  }
}

extension Panel {
  func expand(factor: Float, screenWidth: Float, screenHeight: Float) {
    dots[0].expandPos.x = 0
    dots[0].expandPos.y = 0

    dots[1].expandPos.x = screenWidth
    dots[1].expandPos.y = 0

    dots[2].expandPos.x = screenWidth
    dots[2].expandPos.y = screenHeight

    dots[3].expandPos.x = 0
    dots[3].expandPos.y = screenHeight

    for i in 0 ..< dots.count {
      let fi = Float(i)
      let dot = dots[i]
      dot.physicsMixFactor = 1 - simd_clamp(0, 1, factor * (fi + 1))
    }
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
    var ptr = settingsBuffer.contents().bindMemory(to: WelcomeScreen_FragmentSettings.self, capacity: 1)
    let width = dots[1].pos.x - dots[0].pos.x
    let height = dots[2].pos.y - dots[0].pos.y
//    let angle = atan2(height, width)
//    print(angle)
    ptr.pointee.surfaceSize = float2(width, height)

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
    encoder.setFragmentBuffer(
      settingsBuffer,
      offset: 0,
      index: FragmentSettingsBuffer.index
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
