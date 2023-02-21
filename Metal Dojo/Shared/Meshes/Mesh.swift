//
//  Mesh.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

// swiftlint:disable force_unwrapping
// swiftlint:disable force_cast

import MetalKit

struct Mesh {
  let vertexBuffers: [MTLBuffer]
  let submeshes: [Submesh]
  var transform: TransformComponent?
  let skeleton: Skeleton?
//  var pipelineState: MTLRenderPipelineState
}

extension Mesh {
  init(mdlMesh: MDLMesh, mtkMesh: MTKMesh) {
    let skeleton =
      Skeleton(animationBindComponent:
        (mdlMesh.componentConforming(to: MDLComponent.self)
        as? MDLAnimationBindComponent)
      )
    self.skeleton = skeleton

    var vertexBuffers: [MTLBuffer] = []
    for mtkMeshBuffer in mtkMesh.vertexBuffers {
      vertexBuffers.append(mtkMeshBuffer.buffer)
    }
    self.vertexBuffers = vertexBuffers
    submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map { mesh in
      Submesh(mdlSubmesh: mesh.0 as! MDLSubmesh, mtkSubmesh: mesh.1)
    }
//    let hasSkeleton = skeleton?.jointMatrixPaletteBuffer != nil
//    pipelineState =
//      PipelineStates.createForwardPSO(hasSkeleton: hasSkeleton)
  }

  init(
    mdlMesh: MDLMesh,
    mtkMesh: MTKMesh,
    startTime: TimeInterval,
    endTime: TimeInterval
  ) {
    self.init(mdlMesh: mdlMesh, mtkMesh: mtkMesh)
    if let mdlMeshTransform = mdlMesh.transform {
      transform = TransformComponent(
        transform: mdlMeshTransform,
        object: mdlMesh,
        startTime: startTime,
        endTime: endTime)
    } else {
      transform = nil
    }
  }
}
