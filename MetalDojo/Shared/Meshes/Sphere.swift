//
//  DottedSphere.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 03.01.23.
//

// swiftlint:disable force_try

import MetalKit

struct Sphere: Drawable {
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
    size: Float,
    inwardNormals: Bool = false
  ) {
    let sphereMDLMesh = MDLMesh(
      sphereWithExtent: float3(size, size, size),
      segments: SIMD2<UInt32>(50, 50),
      inwardNormals: inwardNormals,
      geometryType: .triangles,
      allocator: Renderer.meshAllocator
    )
    let sphereMTKMesh = try! MTKMesh(mesh: sphereMDLMesh, device: Renderer.device)
    self.init(mdlMesh: sphereMDLMesh, mtkMesh: sphereMTKMesh)
  }
  
}
