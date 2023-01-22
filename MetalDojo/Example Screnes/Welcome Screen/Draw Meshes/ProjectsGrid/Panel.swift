//
//  Panel.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import MetalKit

class Panel {
  var dots: [Dot]
  var project: ProjectModel
  weak var texture: MTLTexture!

  private let indices: [UInt16] = [
    0, 1, 2,
    2, 1, 3
  ]

  var vertexBuffer: MTLBuffer
  var indexBuffer: MTLBuffer
  var settingsBuffer: MTLBuffer

  init(size: float2, dots: [Dot], project: ProjectModel) {
    self.dots = dots
    self.project = project
    self.vertexBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<float4>.stride * 4
    )!
    self.indexBuffer = Renderer.device.makeBuffer(
      bytes: &indices,
      length: MemoryLayout<UInt16>.stride * 6
    )!
    self.settingsBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<WelcomeScreen_FragmentSettings>.stride
    )!

  }
}

extension Panel {
  func expand(factor: Float, screenWidth: Float, screenHeight: Float) {
    dots[0].targetPos.x += (0 - dots[0].targetPos.x) * factor
    dots[0].targetPos.y += (0 - dots[0].targetPos.y) * factor

    dots[1].targetPos.x += (screenWidth - dots[1].targetPos.x) * factor
    dots[1].targetPos.y += (0 - dots[1].targetPos.y) * factor

    dots[2].targetPos.x += (screenWidth - dots[2].targetPos.x) * factor
    dots[2].targetPos.y += (screenHeight - dots[2].targetPos.y) * factor

    dots[3].targetPos.x += (0 - dots[3].targetPos.x) * factor
    dots[3].targetPos.y += (screenHeight - dots[3].targetPos.y) * factor
  }
  func collapse(factor: Float) {
    dots[0].targetPos.x += (dots[0].mainScreenOldPos.x - dots[0].targetPos.x) * factor
    dots[0].targetPos.y += (dots[0].mainScreenOldPos.y - dots[0].targetPos.y) * factor

    dots[1].targetPos.x += (dots[1].mainScreenOldPos.x - dots[1].targetPos.x) * factor
    dots[1].targetPos.y += (dots[1].mainScreenOldPos.y - dots[1].targetPos.y) * factor

    dots[2].targetPos.x += (dots[2].mainScreenOldPos.x - dots[2].targetPos.x) * factor
    dots[2].targetPos.y += (dots[2].mainScreenOldPos.y - dots[2].targetPos.y) * factor

    dots[3].targetPos.x += (dots[3].mainScreenOldPos.x - dots[3].targetPos.x) * factor
    dots[3].targetPos.y += (dots[2].mainScreenOldPos.y - dots[3].targetPos.y) * factor
  }
  func beforeExpand() {
    for dot in dots {
      dot.cacheMainScreenPos()
    }
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
