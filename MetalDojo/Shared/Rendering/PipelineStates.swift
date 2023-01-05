//
//  PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import Foundation
import Metal

enum PipelineState {
  static func createPSO(descriptor: MTLRenderPipelineDescriptor)
    -> MTLRenderPipelineState {
    let pipelineState: MTLRenderPipelineState
    do {
      pipelineState =
      try Renderer.device.makeRenderPipelineState(
        descriptor: descriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }

  static func createDefaultVertexDescriptor() -> MTLVertexDescriptor {
    let vertexDescriptor = MTLVertexDescriptor()
    var offset = 0
    // position
    vertexDescriptor.attributes[Position.index].format = .float3
    vertexDescriptor.attributes[Position.index].bufferIndex = 0
    vertexDescriptor.attributes[Position.index].offset = offset

    offset += 12

    // normal
    vertexDescriptor.attributes[Normal.index].format = .float3
    vertexDescriptor.attributes[Normal.index].bufferIndex = 0
    vertexDescriptor.attributes[Normal.index].offset = offset
    offset += 12

    // uv
    vertexDescriptor.attributes[UV.index].format = .float2
    vertexDescriptor.attributes[UV.index].bufferIndex = 0
    vertexDescriptor.attributes[UV.index].offset = offset

    let stride = offset + 8

    vertexDescriptor.layouts[0].stride = stride

    return vertexDescriptor
  }

  static func createWelcomeScreenPSO(colorPixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "vertex_welcomeScreen")
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_welcomeScreen")
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
}

