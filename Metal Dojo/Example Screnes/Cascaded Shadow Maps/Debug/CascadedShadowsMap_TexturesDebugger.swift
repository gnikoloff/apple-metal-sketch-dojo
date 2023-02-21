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

  private var cascadesCount: Int

  weak var shadowsDepthTexture: MTLTexture?

  init(cascadesCount: Int) {
    self.cascadesCount = cascadesCount
    do {
      try debugCSMTexturesPipelineState = CascadedShadowsMap_PipelineStates.makeCSMVertexlessPipelineState(
        isTextureDebug: true,
        isCsmTextureDebug: true
      )
    } catch {
      fatalError(error.localizedDescription)
    }
  }

  func draw(renderEncoder: MTLRenderCommandEncoder) {
    if shadowsDepthTexture != nil {
      renderEncoder.setFragmentTexture(shadowsDepthTexture, index: ShadowTexture.index)
    }

    renderEncoder.setRenderPipelineState(debugCSMTexturesPipelineState)
    renderEncoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: 6,
      instanceCount: cascadesCount
    )
  }

}
