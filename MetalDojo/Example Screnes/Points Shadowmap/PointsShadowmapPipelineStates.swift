//
//  PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import Foundation
import Metal

enum PointsShadowmapPipelineStates {
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

  static func createShadowPSO() -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "pointsShadowmap_vertexShadow")
    let fragmentFunction = Renderer.library?.makeFunction(name: "pointsShadowmap_depthFragmentMain")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.inputPrimitiveTopology = .triangle
    pipelineDescriptor.colorAttachments[0].pixelFormat = .invalid
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = createDefaultVertexDescriptor()
    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }

  static func createCubePSO(
    colorPixelFormat: MTLPixelFormat
  ) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "pointsShadowmap_vertexMain")
    let fragmentFunction = Renderer.library?.makeFunction(name: "pointsShadowmap_fragmentCube")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

    pipelineDescriptor.vertexDescriptor = createDefaultVertexDescriptor()
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }

  static func createSpherePSO(
    colorPixelFormat: MTLPixelFormat
  ) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "pointsShadowmap_vertexMain")
    let fragmentFunction = Renderer.library?.makeFunction(name: "pointsShadowmap_fragmentSphere")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    let attachment = pipelineDescriptor.colorAttachments[0]
    attachment?.pixelFormat = colorPixelFormat

    pipelineDescriptor.vertexDescriptor = createDefaultVertexDescriptor()
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }
}
