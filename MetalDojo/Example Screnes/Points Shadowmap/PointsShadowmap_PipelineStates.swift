//
//  PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import Foundation
import MetalKit

enum PointsShadowmapPipelineStates {
  static func createShadowPSO() throws -> MTLRenderPipelineState {
    let fnConstantValues = MTLFunctionConstantValues()
    var isCubemapRender = true
    fnConstantValues.setConstantValue(
      &isCubemapRender,
      type: .bool,
      index: 0
    )
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "pointsShadowmap_vertex",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "pointsShadowmap_depthFragmentSphere",
      constantValues: fnConstantValues
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.inputPrimitiveTopology = .triangle
    pipelineDescriptor.colorAttachments[0].pixelFormat = .invalid
    pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }

  static func createForwardPSO(
    colorPixelFormat: MTLPixelFormat,
    isSolidColor: Bool = false,
    isShadedAndShadowed: Bool = false,
    isCutOffAlpha: Bool = false
  ) throws -> MTLRenderPipelineState {
    let fnConstantValues = MTLFunctionConstantValues()

    var isCubemapRender = false
    var isSolidColor = isSolidColor
    var isShadedAndShadowed = isShadedAndShadowed
    var isCutOffAlpha = isCutOffAlpha

    fnConstantValues.setConstantValue(
      &isCubemapRender,
      type: .bool,
      index: 0
    )
    fnConstantValues.setConstantValue(
      &isSolidColor,
      type: .bool,
      index: 1
    )
    fnConstantValues.setConstantValue(
      &isShadedAndShadowed,
      type: .bool,
      index: 2
    )
    fnConstantValues.setConstantValue(
      &isCutOffAlpha,
      type: .bool,
      index: 3
    )

    let vertexFunction = try Renderer.library?.makeFunction(
      name: "pointsShadowmap_vertex",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "pointsShadowmap_fragmentMain",
      constantValues: fnConstantValues
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }
}
