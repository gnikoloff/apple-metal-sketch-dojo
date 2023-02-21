//
//  Icosahedron.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 17.01.23.
//

// swiftlint:disable force_try

import MetalKit

struct Icosahedron: Drawable {
  var instanceCount: Int = 1
  var baseInstace: Int = 0
  var uniforms = Uniforms()
  var transform = Transform()
  var primitiveType: MTLPrimitiveType = .triangle

  var vertexBuffers: [MTLBuffer] = []
  var submeshes: [Submesh] = []
  var cullMode: MTLCullMode = .back

  init() {
    // ...
  }

  init(
    size: float3 = [1, 1, 1],
    inwardNormals: Bool = false
  ) {
    let mdlMesh = MDLMesh(
      icosahedronWithExtent: size,
      inwardNormals: inwardNormals,
      geometryType: .triangles,
      allocator: Renderer.meshAllocator
    )

    let mtkMesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
    self.init(mdlMesh: mdlMesh, mtkMesh: mtkMesh)
  }

}
