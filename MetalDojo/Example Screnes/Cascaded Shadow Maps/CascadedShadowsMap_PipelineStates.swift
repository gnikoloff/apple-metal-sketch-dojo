//
//  CascadedShadowsMap_PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

import MetalKit

// swiftlint:disable type_name

enum CascadedShadowsMap_PipelineStates: PipelineStates {
  static func createShadowPSO() throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants(rendersToTargetArray: true)
    let vertexFunction = try Renderer.library.makeFunction(
      name: "cascadedShadows_vertex",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library.makeFunction(
      name: "cascadedShadows_fragmentShadow",
      constantValues: fnConstantValues
    )
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.viewColorFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    pipelineDescriptor.inputPrimitiveTopology = .triangle

    return Self.createPSO(descriptor: pipelineDescriptor)
  }

  static func createFloorPSO() throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants()
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "cascadedShadows_vertex",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "cascadedShadows_fragment",
      constantValues: fnConstantValues
    )
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.viewColorFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    return Self.createPSO(descriptor: pipelineDescriptor)
  }

  static func createPBRPSO() throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants()
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "cascadedShadows_vertex",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "fragment_pbr",
      constantValues: fnConstantValues
    )
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.viewColorFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultMTKLayout
    return Self.createPSO(descriptor: pipelineDescriptor)
  }
}
