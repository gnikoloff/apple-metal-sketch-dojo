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

enum InfiniteSpacePipelineStates: PipelineStates {
  static func buildLightingDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.isDepthWriteEnabled = false
    return Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }

  static func createGBufferPSO() throws -> MTLRenderPipelineState {
    let fnConstantValues = Self.getFnConstants()
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "infiniteSpace_vertexCube",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "infiniteSpace_fragmentCube",
      constantValues: fnConstantValues
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.setColorAttachmentPixelFormatsForInfiniteSpace(Renderer.colorPixelFormat)
    pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    return Self.createPSO(descriptor: pipelineDescriptor)
  }

  static func createPointLightPSO() throws -> MTLRenderPipelineState {
    let fnConstantValues = Self.getFnConstants()
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "InfiniteSpace_vertexPointLight",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "InfiniteSpace_fragmentPointLight",
      constantValues: fnConstantValues
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.setColorAttachmentPixelFormatsForInfiniteSpace(Renderer.colorPixelFormat)
    pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm
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
    return Self.createPSO(descriptor: pipelineDescriptor)
  }

  static func createSunLightPSO() throws -> MTLRenderPipelineState {
    let fnConstantValues = Self.getFnConstants()
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "infiniteSpace_vertexQuad",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "InfiniteSpace_fragmentDeferredSun",
      constantValues: fnConstantValues
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.setColorAttachmentPixelFormatsForInfiniteSpace(Renderer.colorPixelFormat)
    pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm
    return Self.createPSO(descriptor: pipelineDescriptor)
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
