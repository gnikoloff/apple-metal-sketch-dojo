//
//  WelcomeScreen_PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 28.01.23.
//

// swiftlint:disable type_name

import MetalKit

enum WelcomeScreen_PipelineStates: PipelineStates {
  static func createWelcomeScreenPSO(colorPixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {
    let fnConstants = Self.getFnConstants()
    var hasUv = true
    fnConstants.setConstantValue(&hasUv, type: .bool, index: CustomFnConstant.index)
    
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "vertex_welcomeScreen",
      constantValues: fnConstants
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "fragment_welcomeScreen",
      constantValues: fnConstants
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

    let vertexDescriptor = MTLVertexDescriptor()
    // position
    vertexDescriptor.attributes[Position.index].format = .float2
    vertexDescriptor.attributes[Position.index].bufferIndex = 0
    vertexDescriptor.attributes[Position.index].offset = 0
    // uv
    vertexDescriptor.attributes[UV.index].format = .float2
    vertexDescriptor.attributes[UV.index].bufferIndex = 0
    vertexDescriptor.attributes[UV.index].offset = MemoryLayout<float2>.stride
    // pos and uv are interleaved
    vertexDescriptor.layouts[0].stride = MemoryLayout<float2>.stride * 2

    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    return createPSO(descriptor: pipelineDescriptor)
  }

  static func createDebugAABBBoxes() throws -> MTLRenderPipelineState {
    let fnConstants = Self.getFnConstants(hasUv: false)

    let vertexFunction = try Renderer.library?.makeFunction(
      name: "vertex_welcomeScreen",
      constantValues: fnConstants
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "fragment_welcomeDebugAABB",
      constantValues: fnConstants
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.viewColorFormat

    let vertexDescriptor = MTLVertexDescriptor()

    vertexDescriptor.attributes[Position.index].format = .float2
    vertexDescriptor.attributes[Position.index].bufferIndex = 0
    vertexDescriptor.attributes[Position.index].offset = 0

    vertexDescriptor.layouts[0].stride = MemoryLayout<float2>.stride

    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    return createPSO(descriptor: pipelineDescriptor)
  }

}
