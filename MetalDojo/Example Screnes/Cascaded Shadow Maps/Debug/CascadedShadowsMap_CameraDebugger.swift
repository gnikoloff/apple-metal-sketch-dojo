//
//  CascadedShadowsMap_CameraDebugger.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 10.02.23.
//

// swiftlint:disable type_name identifier_name

import MetalKit

final class CascadedShadowsMap_CameraDebugger {
  private static let POINTS_IN_FRUSTUM_COUNT = 8

  private var cascadesCount: Int

  private let frustumPartitionsVertexBuffer: MTLBuffer
  private let debugCSMCameraFrustumPipelineState: MTLRenderPipelineState

  init(cascadesCount: Int) {
    self.cascadesCount = cascadesCount
    frustumPartitionsVertexBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<float3>.stride * Self.POINTS_IN_FRUSTUM_COUNT * cascadesCount
    )!
    do {
      try debugCSMCameraFrustumPipelineState = CascadedShadowsMap_PipelineStates.makeCSMVertexlessPipelineState()
    } catch {
      fatalError(error.localizedDescription)
    }
  }

  func draw(camera: Camera, renderEncoder: MTLRenderCommandEncoder) {
    let frustumWorldSpaceCorners = camera.getFrustumCornersWorldSpace()
    let frustumVertexBufferPtr = frustumPartitionsVertexBuffer
      .contents()
      .bindMemory(
        to: float3.self,
        capacity: cascadesCount * Self.POINTS_IN_FRUSTUM_COUNT
      )

    for i in 0 ..< cascadesCount {
      for n in 0 ..< Self.POINTS_IN_FRUSTUM_COUNT {
        frustumVertexBufferPtr[i * Self.POINTS_IN_FRUSTUM_COUNT + n] = frustumWorldSpaceCorners[n].xyz
      }
    }

    renderEncoder.setRenderPipelineState(debugCSMCameraFrustumPipelineState)
    renderEncoder.setVertexBuffer(
      frustumPartitionsVertexBuffer,
      offset: 0,
      index: VertexBuffer.index
    )
    renderEncoder.drawPrimitives(
      type: .line,
      vertexStart: 0,
      vertexCount: 8,
      instanceCount: cascadesCount
    )
  }
}
