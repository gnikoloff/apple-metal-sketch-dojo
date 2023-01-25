//
//  InfiniteSpace_PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

import Foundation
import Metal
import ModelIO



extension MTLRenderPipelineDescriptor {
  func setColorAttachmentPixelFormatsForInfiniteSpace(_ colorPixelFormat: MTLPixelFormat) {
    colorAttachments[0].pixelFormat = colorPixelFormat
    colorAttachments[RenderTargetNormal.index].pixelFormat = .rgba16Float
    colorAttachments[RenderTargetPosition.index].pixelFormat = .rgba16Float
  }
}

enum InfiniteSpacePipelineStates {

  static func buildLightingDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.isDepthWriteEnabled = false
    return Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }

  static func createGBufferPSO(colorPixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "infiniteSpace_vertexCube")
    let fragmentFunction = Renderer.library?.makeFunction(name: "infiniteSpace_fragmentCube")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.setColorAttachmentPixelFormatsForInfiniteSpace(colorPixelFormat)
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }

  static func createPointLightPSO(
    colorPixelFormat: MTLPixelFormat
  ) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "InfiniteSpace_vertexPointLight")
    let fragmentFunction = Renderer.library?.makeFunction(name: "InfiniteSpace_fragmentPointLight")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.setColorAttachmentPixelFormatsForInfiniteSpace(colorPixelFormat)
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    let attachment = pipelineDescriptor.colorAttachments[0]
    attachment?.isBlendingEnabled = true
    attachment?.rgbBlendOperation = .add
    attachment?.alphaBlendOperation = .add
    attachment?.sourceRGBBlendFactor = .one
    attachment?.sourceAlphaBlendFactor = .one
    attachment?.destinationRGBBlendFactor = .one
    attachment?.destinationAlphaBlendFactor = .zero
    attachment?.sourceRGBBlendFactor = .one
    attachment?.sourceAlphaBlendFactor = .one
    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }

  static func createSunLightPSO(
    colorPixelFormat: MTLPixelFormat
  ) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "infiniteSpace_vertexQuad")
    let fragmentFunction = Renderer.library?.makeFunction(name: "InfiniteSpace_fragmentDeferredSun")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.setColorAttachmentPixelFormatsForInfiniteSpace(colorPixelFormat)
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }

  static func createBoxesComputePSO() throws -> MTLComputePipelineState {
    guard let computeFunction = Renderer.library.makeFunction(name: "InfiniteSpace_computeBoxes") else {
      throw EngineError.invalidComputeFunction
    }
    return try Renderer.device.makeComputePipelineState(function: computeFunction)
  }

  static func createPointLightsComputePSO() throws -> MTLComputePipelineState {
    guard let computeFunction = Renderer.library.makeFunction(name: "InfiniteSpace_computePointLights") else {
      throw EngineError.invalidComputeFunction
    }
    return try Renderer.device.makeComputePipelineState(function: computeFunction)
  }
}
