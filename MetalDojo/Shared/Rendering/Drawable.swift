//
//  Mesh.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 02.01.23.
//

import MetalKit

// swiftlint:disable force_unwrapping
// swiftlint:disable force_cast

protocol Drawable: Transformable {
  var vertexBuffers: [MTLBuffer] { get set }
  var submeshes: [Submesh] { get set }
  var cullMode: MTLCullMode { get set }
  var uniforms: Uniforms { get set }
  var instanceCount: Int { get set }
  var baseInstace: Int { get set }
  var primitiveType: MTLPrimitiveType { get set }
  init()
  init(mdlMesh: MDLMesh, mtkMesh: MTKMesh)
  mutating func updateUniforms()
}

extension Drawable {
  init(mdlMesh: MDLMesh, mtkMesh: MTKMesh) {
    self.init()

    var vertexBuffers: [MTLBuffer] = []
    for mtkMeshBuffer in mtkMesh.vertexBuffers {
      vertexBuffers.append(mtkMeshBuffer.buffer)
    }
    self.vertexBuffers = vertexBuffers
    submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map { mesh in
      Submesh(mdlSubmesh: mesh.0 as! MDLSubmesh, mtkSubmesh: mesh.1)
    }
  }
  mutating func updateUniforms() {
    uniforms.modelMatrix = transform.modelMatrix
    uniforms.normalMatrix = float3x3(normalFrom4x4: transform.modelMatrix)
  }
  mutating func draw(renderEncoder: MTLRenderCommandEncoder) {
    updateUniforms()

    var uniforms = uniforms
    renderEncoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index
    )

    for (index, vertexBuffer) in vertexBuffers.enumerated() {
      renderEncoder.setVertexBuffer(
        vertexBuffer,
        offset: 0,
        index: index
      )
    }
    renderEncoder.setCullMode(cullMode)

    for submesh in submeshes {
      renderEncoder.drawIndexedPrimitives(
        type: primitiveType,
        indexCount: submesh.indexCount,
        indexType: submesh.indexType,
        indexBuffer: submesh.indexBuffer,
        indexBufferOffset: submesh.indexBufferOffset,
        instanceCount: instanceCount,
        baseVertex: 0,
        baseInstance: baseInstace
      )
    }
  }
}
