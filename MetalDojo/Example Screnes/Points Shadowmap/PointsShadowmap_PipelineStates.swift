//
//  PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import Foundation
import MetalKit

enum PointsShadowmapPipelineStates: PipelineStates {
  static func createShadowPSO() throws -> MTLRenderPipelineState {
    let fnConstants = Self.getFnConstants(rendersToTargetArray: true)
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "pointsShadowmap_vertex",
      constantValues: fnConstants
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "pointsShadowmap_depthFragmentSphere",
      constantValues: fnConstants
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.inputPrimitiveTopology = .triangle
    pipelineDescriptor.colorAttachments[0].pixelFormat = .invalid
    pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    return createPSO(descriptor: pipelineDescriptor)
  }

  static func createForwardPSO(
    colorPixelFormat: MTLPixelFormat,
    isSolidColor: Bool = false,
    isShadedAndShadowed: Bool = false,
    isCutOffAlpha: Bool = false
  ) throws -> MTLRenderPipelineState {
    let fnConstants = Self.getFnConstants()

    var isSolidColor = isSolidColor
    var isShadedAndShadowed = isShadedAndShadowed
    var isCutOffAlpha = isCutOffAlpha

    fnConstants.setConstantValue(
      &isSolidColor,
      type: .bool,
      index: CustomFnConstant.index
    )
    fnConstants.setConstantValue(
      &isShadedAndShadowed,
      type: .bool,
      index: CustomFnConstant.index + 1
    )
    fnConstants.setConstantValue(
      &isCutOffAlpha,
      type: .bool,
      index: CustomFnConstant.index + 2
    )

    let vertexFunction = try Renderer.library?.makeFunction(
      name: "pointsShadowmap_vertex",
      constantValues: fnConstants
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "pointsShadowmap_fragmentMain",
      constantValues: fnConstants
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

    return createPSO(descriptor: pipelineDescriptor)
  }
}
