//
//  CascadedShadowsMap_PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

import MetalKit

// swiftlint:disable type_name

enum CascadedShadowsMap_PipelineStates: PipelineStates {
  static func createShadowPSO(instancesHaveUniquePositions: Bool = false) throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants(
      rendersToTargetArray: true,
      rendersDepth: true
    )
    var instancesHaveUniquePositions = instancesHaveUniquePositions
    var usesDebugCamera = false
    fnConstantValues.setConstantValue(
      &instancesHaveUniquePositions,
      type: .bool,
      index: 10
    )
    fnConstantValues.setConstantValue(
      &usesDebugCamera,
      type: .bool,
      index: 11
    )
    let vertexFunction = try Renderer.library.makeFunction(
      name: "cascadedShadows_vertex",
      constantValues: fnConstantValues
    )
//    let fragmentFunction = try Renderer.library.makeFunction(
//      name: "cascadedShadows_fragmentShadow",
//      constantValues: fnConstantValues
//    )
    pipelineDescriptor.vertexFunction = vertexFunction
//    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
//    pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    pipelineDescriptor.inputPrimitiveTopology = .triangle

    return Self.createPSO(descriptor: pipelineDescriptor)
  }

  static func createMeshPSO(
    instancesHaveUniquePositions: Bool = false,
    usesDebugCamera: Bool = false
  ) throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants()
    var instancesHaveUniquePositions = instancesHaveUniquePositions
    var usesDebugCamera = usesDebugCamera
    fnConstantValues.setConstantValue(
      &instancesHaveUniquePositions,
      type: .bool,
      index: 10
    )
    fnConstantValues.setConstantValue(
      &usesDebugCamera,
      type: .bool,
      index: 11
    )

    print("createMeshPSO")
    print(fnConstantValues)
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
    var instancesHaveUniquePositions = false
    var usesDebugCamera = false
    fnConstantValues.setConstantValue(
      &instancesHaveUniquePositions,
      type: .bool,
      index: 10
    )
    fnConstantValues.setConstantValue(
      &usesDebugCamera,
      type: .bool,
      index: 11
    )
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

  static func makeCSMFrustumDebuggerPipelineState() throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants()
    var isTextureDebug = false
    var isCsmTextureDebug = false
    var isCamTextureDebug = false
    fnConstantValues.setConstantValue(
      &isTextureDebug,
      type: .bool,
      index: 10
    )
    fnConstantValues.setConstantValue(
      &isCsmTextureDebug,
      type: .bool,
      index: 11
    )
    fnConstantValues.setConstantValue(
      &isCamTextureDebug,
      type: .bool,
      index: 12
    )
    let vertexFunction = try Renderer.library.makeFunction(
      name: "CSMFrustumDebugger_vertex",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library.makeFunction(
      name: "CascadedShadowsMap_fragmentDebug",
      constantValues: fnConstantValues
    )
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.viewColorFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    return Self.createPSO(descriptor: pipelineDescriptor)
  }

  static func makeCSMVertexlessPipelineState(
    isTextureDebug: Bool = false,
    isCsmTextureDebug: Bool = false,
    isCamTextureDebug: Bool = false,
    isLightSpaceFrustumVerticesDebug: Bool = false
  ) throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants()
    var isTextureDebug = isTextureDebug
    var isCsmTextureDebug = isCsmTextureDebug
    var isCamTextureDebug = isCamTextureDebug
    var isLightSpaceFrustumVerticesDebug = isLightSpaceFrustumVerticesDebug
    fnConstantValues.setConstantValue(
      &isTextureDebug,
      type: .bool,
      index: 10
    )
    fnConstantValues.setConstantValue(
      &isCsmTextureDebug,
      type: .bool,
      index: 11
    )
    fnConstantValues.setConstantValue(
      &isCamTextureDebug,
      type: .bool,
      index: 12
    )
    fnConstantValues.setConstantValue(
      &isLightSpaceFrustumVerticesDebug,
      type: .bool,
      index: 13
    )
    let vertexFunction = try Renderer.library.makeFunction(
      name: "CascadedShadowsMap_vertexDebug",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library.makeFunction(
      name: "CascadedShadowsMap_fragmentDebug",
      constantValues: fnConstantValues
    )
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.viewColorFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    return Self.createPSO(descriptor: pipelineDescriptor)
  }
}
