//
//  CascadedShadowsMap_PipelineStates.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

import MetalKit

// swiftlint:disable type_name

enum CascadedShadowsMap_PipelineStates: PipelineStates {
  static func createShadowPSO(
    instancesHaveUniquePositions: Bool = false,
    useDefaultMTKVertexLayout: Bool = false,
    isSkeletonAnimation: Bool = false
  ) throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants(
      hasSkeleton: isSkeletonAnimation,
      rendersToTargetArray: true,
      rendersDepth: true
    )
    var instancesHaveUniquePositions = instancesHaveUniquePositions
    var usesDebugCamera = false
    fnConstantValues.setConstantValue(
      &instancesHaveUniquePositions,
      type: .bool,
      index: CustomFnConstant.index
    )
    fnConstantValues.setConstantValue(
      &usesDebugCamera,
      type: .bool,
      index: CustomFnConstant.index + 1
    )
    let vertexFunction = try Renderer.library.makeFunction(
      name: "cascadedShadows_vertex",
      constantValues: fnConstantValues
    )
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = useDefaultMTKVertexLayout
      ? MTLVertexDescriptor.defaultMTKLayout
      : MTLVertexDescriptor.defaultLayout
    pipelineDescriptor.inputPrimitiveTopology = .triangle
    return Self.createPSO(descriptor: pipelineDescriptor)
  }

  static func createMeshPSO(
    instancesHaveUniquePositions: Bool = false,
    usesDebugCamera: Bool = false,
    isSkeletonAnimation: Bool = false
  ) throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants(hasSkeleton: isSkeletonAnimation)
    var instancesHaveUniquePositions = instancesHaveUniquePositions
    var usesDebugCamera = usesDebugCamera
    fnConstantValues.setConstantValue(
      &instancesHaveUniquePositions,
      type: .bool,
      index: CustomFnConstant.index
    )
    fnConstantValues.setConstantValue(
      &usesDebugCamera,
      type: .bool,
      index: CustomFnConstant.index + 1
    )
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
    pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
    return Self.createPSO(descriptor: pipelineDescriptor)
  }

  static func createPBRPSO(
    instancesHaveUniquePositions: Bool = false,
    usesDebugCamera: Bool = false,
    isSkeletonAnimation: Bool = false
  ) throws -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    let fnConstantValues = Self.getFnConstants(hasSkeleton: isSkeletonAnimation)
    var instancesHaveUniquePositions = instancesHaveUniquePositions
    var usesDebugCamera = usesDebugCamera
    fnConstantValues.setConstantValue(
      &instancesHaveUniquePositions,
      type: .bool,
      index: CustomFnConstant.index
    )
    fnConstantValues.setConstantValue(
      &usesDebugCamera,
      type: .bool,
      index: CustomFnConstant.index + 1
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
    pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm
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
      index: CustomFnConstant.index
    )
    fnConstantValues.setConstantValue(
      &isCsmTextureDebug,
      type: .bool,
      index: CustomFnConstant.index + 1
    )
    fnConstantValues.setConstantValue(
      &isCamTextureDebug,
      type: .bool,
      index: CustomFnConstant.index + 2
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
    pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm
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
      index: CustomFnConstant.index
    )
    fnConstantValues.setConstantValue(
      &isCsmTextureDebug,
      type: .bool,
      index: CustomFnConstant.index + 1
    )
    fnConstantValues.setConstantValue(
      &isCamTextureDebug,
      type: .bool,
      index: CustomFnConstant.index + 2
    )
    fnConstantValues.setConstantValue(
      &isLightSpaceFrustumVerticesDebug,
      type: .bool,
      index: CustomFnConstant.index + 3
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
    pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm
    return Self.createPSO(descriptor: pipelineDescriptor)
  }
}
