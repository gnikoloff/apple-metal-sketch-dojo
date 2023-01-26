//
//  CascadedShadowsMap_PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

import MetalKit

// swiftlint:disable type_name

enum CascadedShadowsMap_PipelineStates {
  static func createFloorPSO() -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let vertexFunction = Renderer.library?.makeFunction(name: "cascadedShadows_vertex")
    let fragmentFunction = Renderer.library?.makeFunction(name: "cascadedShadows_fragment")
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.viewColorFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }
  static func createPBRPSO() -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let vertexFunction = Renderer.library?.makeFunction(name: "cascadedShadows_vertex")
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_pbr")
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.viewColorFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultMTKLayout
    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }
}
