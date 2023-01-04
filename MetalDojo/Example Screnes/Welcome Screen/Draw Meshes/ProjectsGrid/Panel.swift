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

  let indices: [UInt16] = [
    0, 1, 2,
    2, 1, 3
  ]
  var vertexBuffer: MTLBuffer
  var indexBuffer: MTLBuffer
  init(dots: [Dot], project: ProjectModel) {
    self.dots = dots
    self.project = project
    self.vertexBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<float4>.stride * 4
    )!
    self.indexBuffer = Renderer.device.makeBuffer(
      bytes: &indices,
      length: MemoryLayout<UInt16>.stride * 6
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
    var interleavedArray = vertexBuffer.contents().bindMemory(to: Float.self, capacity: 16)
    interleavedArray[0] = dots[1].pos.x
    interleavedArray[1] = dots[1].pos.y
    interleavedArray[2] = 0
    interleavedArray[3] = 1

    interleavedArray[4] = dots[0].pos.x
    interleavedArray[5] = dots[0].pos.y
    interleavedArray[6] = 1
    interleavedArray[7] = 1

    interleavedArray[8] = dots[2].pos.x
    interleavedArray[9] = dots[2].pos.y
    interleavedArray[10] = 1
    interleavedArray[11] = 0

    interleavedArray[12] = dots[3].pos.x
    interleavedArray[13] = dots[3].pos.y
    interleavedArray[14] = 0
    interleavedArray[15] = 0
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
      index: 0)
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: indices.count,
      indexType: .uint16,
      indexBuffer: indexBuffer,
      indexBufferOffset: 0
    )
  }
}
