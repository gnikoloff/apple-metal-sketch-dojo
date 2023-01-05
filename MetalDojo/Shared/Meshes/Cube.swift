//
//  Cube.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 03.01.23.
//

// swiftlint:disable force_try

import MetalKit

struct Cube: Drawable {
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

  init(size: float3 = [1, 1, 1], segments: vector_uint3 = [1, 1, 1]) {
    let cubeMDLMesh = MDLMesh(
      boxWithExtent: size,
      segments: segments,
      inwardNormals: false,
      geometryType: .lines,
      allocator: Renderer.meshAllocator
    )
    let cubeMTKMesh = try! MTKMesh(mesh: cubeMDLMesh, device: Renderer.device)
    self.init(mdlMesh: cubeMDLMesh, mtkMesh: cubeMTKMesh)
  }

}
