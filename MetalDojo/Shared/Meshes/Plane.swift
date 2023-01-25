//
//  Plane.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

// swiftlint:disable force_try

import MetalKit

struct Plane: Drawable {
  var instanceCount: Int = 1
  var baseInstace: Int = 0
  var uniforms = Uniforms()
  var transform = Transform()

  var vertexBuffers: [MTLBuffer] = []
  var submeshes: [Submesh] = []
  var cullMode: MTLCullMode = .back

  init() {
    // ...
  }

  init(
    size: float3 = [1, 1, 1],
    segments: vector_uint2 = [1, 1]
  ) {
    let mdlMesh = MDLMesh(
      planeWithExtent: size,
      segments: segments,
      geometryType: .triangles,
      allocator: Renderer.meshAllocator
    )

    let mtkMesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
    self.init(mdlMesh: mdlMesh, mtkMesh: mtkMesh)
  }

}

