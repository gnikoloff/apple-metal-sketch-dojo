//
//  InfiniteSpace_PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

import Foundation
import Metal

enum InfiniteSpacePipelineStates {

  static func createForwardPSO(
    colorPixelFormat: MTLPixelFormat
  ) throws -> MTLRenderPipelineState {
    let fnConstantValues = MTLFunctionConstantValues()
//    var isCubemapRender = false
//    fnConstantValues.setConstantValue(
//      &isCubemapRender,
//      type: .bool,
//      index: 0
//    )
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "infiniteSpace_vertex",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "infiniteSpace_fragment",
      constantValues: fnConstantValues
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

    pipelineDescriptor.vertexDescriptor = PipelineState.createDefaultVertexDescriptor()
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }
}

