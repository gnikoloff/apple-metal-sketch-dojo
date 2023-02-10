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
    } catch {
      fatalError(error.localizedDescription)
    }
  }

  func draw(encoder: MTLRenderCommandEncoder) {
    if (shadowsDepthTexture != nil) {
      encoder.setFragmentTexture(shadowsDepthTexture, index: ShadowTexture.index)
    }
    if (debugCamTexture != nil) {
      encoder.setFragmentTexture(debugCamTexture, index: CamDebugTexture.index)
    }

    encoder.setRenderPipelineState(debugCSMTexturesPipelineState)
    encoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: 6,
      instanceCount: cascadesCount
    )

    encoder.setRenderPipelineState(debugArcballCameraViewPipelineState)
    encoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: 6
    )
  }

}
