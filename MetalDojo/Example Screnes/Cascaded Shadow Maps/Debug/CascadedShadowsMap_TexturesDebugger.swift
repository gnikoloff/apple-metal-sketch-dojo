//
//  CascadedShadowsMap_DepthTexturesDebugger.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 09.02.23.
//

// swiftlint:disable type_name

import MetalKit

final class CascadedShadowsMap_TexturesDebugger {
  private let debugCSMTexturesPipelineState: MTLRenderPipelineState
  private let debugArcballCameraViewPipelineState: MTLRenderPipelineState

  private var cascadesCount: Int

  weak var shadowsDepthTexture: MTLTexture?
  weak var debugCamTexture: MTLTexture?

  var floorPipelineDebugState: MTLRenderPipelineState
  var cubesPipelineDebugState: MTLRenderPipelineState
  var modelPipelineDebugState: MTLRenderPipelineState

  init(cascadesCount: Int) {
    self.cascadesCount = cascadesCount
    do {
      try debugCSMTexturesPipelineState = CascadedShadowsMap_PipelineStates.makeCSMVertexlessPipelineState(
        isTextureDebug: true,
        isCsmTextureDebug: true
      )
      try debugArcballCameraViewPipelineState = CascadedShadowsMap_PipelineStates.makeCSMVertexlessPipelineState(
        isTextureDebug: true,
        isCamTextureDebug: true
      )
      try floorPipelineDebugState = CascadedShadowsMap_PipelineStates.createMeshPSO(
        usesDebugCamera: true
      )
      try cubesPipelineDebugState = CascadedShadowsMap_PipelineStates.createMeshPSO(
        instancesHaveUniquePositions: true,
        usesDebugCamera: true
      )
      try modelPipelineDebugState = CascadedShadowsMap_PipelineStates.createPBRPSO(
        usesDebugCamera: true,
        isSkeletonAnimation: true
      )
    } catch {
      fatalError(error.localizedDescription)
    }
  }

  func draw(renderEncoder: MTLRenderCommandEncoder) {
    if shadowsDepthTexture != nil {
      renderEncoder.setFragmentTexture(shadowsDepthTexture, index: ShadowTexture.index)
    }
    if debugCamTexture != nil {
      renderEncoder.setFragmentTexture(debugCamTexture, index: CamDebugTexture.index)
    }

    renderEncoder.setRenderPipelineState(debugCSMTexturesPipelineState)
    renderEncoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: 6,
      instanceCount: cascadesCount
    )

    renderEncoder.setRenderPipelineState(debugArcballCameraViewPipelineState)
    renderEncoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: 6
    )
  }

}
