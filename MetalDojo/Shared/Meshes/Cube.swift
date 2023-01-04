//
//  EnvCube.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 03.01.23.
//

// swiftlint:disable force_try

import MetalKit

struct EnvCube: Drawable {
  var instanceCount: Int = 1
  var baseInstace: Int = 0
  var uniforms = Uniforms()
  var transform = Transform()

  var vertexBuffers: [MTLBuffer] = []
  var submeshes: [Submesh] = []
  var cullMode: MTLCullMode = .none

  init() {
    // ...
  }

  init(size: Float) {
    let cubeMDLMesh = MDLMesh(
      boxWithExtent: float3(size, size, size),
      segments: [1, 1, 1],
      inwardNormals: false,
      geometryType: .triangles,
      allocator: Renderer.meshAllocator
    )
    let cubeMTKMesh = try! MTKMesh(mesh: cubeMDLMesh, device: Renderer.device)
    self.init(mdlMesh: cubeMDLMesh, mtkMesh: cubeMTKMesh)
  }

}
