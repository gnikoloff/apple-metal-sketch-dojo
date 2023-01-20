//
//  AppleMetal_Extensions.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 19.01.23.
//

import Foundation
import MetalKit

enum AppleMetalPipelineStates {
  static func createForwardPSO(
    colorPixelFormat: MTLPixelFormat,
    isLight: Bool = false,
    lightsCount: Int = 1
  ) throws -> MTLRenderPipelineState {
    let fnConstantValues = MTLFunctionConstantValues()
    var isLight = isLight
    var lightsCount = lightsCount
    fnConstantValues.setConstantValue(
      &isLight,
      type: .bool,
      index: 0
    )
    fnConstantValues.setConstantValue(
      &lightsCount,
      type: .uint,
      index: 1
    )
    let vertexFunction = try Renderer.library?.makeFunction(
      name: "appleMetal_vertex",
      constantValues: fnConstantValues
    )
    let fragmentFunction = try Renderer.library?.makeFunction(
      name: "appleMetal_fragment",
      constantValues: fnConstantValues
    )
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = MDLVertexDescriptor.defaultLayout
    return PipelineState.createPSO(descriptor: pipelineDescriptor)
  }

  static func createUpdateComputePSO(
    fnName: String,
    entitiesCount: Int,
    entityRadius: Float,
    gravity: float3 = float3(repeating: 0),
    bounceFactor: float3 = float3(repeating: 1),
    checkEntitiesCollisions: Bool = false
  ) throws -> MTLComputePipelineState {
    let fnConstantValues = MTLFunctionConstantValues()
    var entitiesCount = entitiesCount
    var entityRadius = entityRadius
    var gravity = gravity
    var bounceFactor = bounceFactor
    var checkEntitiesCollisions = checkEntitiesCollisions
    fnConstantValues.setConstantValue(
      &entitiesCount,
      type: .uint,
      index: 0
    )
    fnConstantValues.setConstantValue(
      &entityRadius,
      type: .float,
      index: 1
    )
    fnConstantValues.setConstantValue(
      &gravity,
      type: .float3,
      index: 2
    )
    fnConstantValues.setConstantValue(
      &bounceFactor,
      type: .float3,
      index: 3
    )
    fnConstantValues.setConstantValue(
      &checkEntitiesCollisions,
      type: .bool,
      index: 4
    )
    let computeFunction = try Renderer.library.makeFunction(
      name: fnName,
      constantValues: fnConstantValues
    )
    return try Renderer.device.makeComputePipelineState(function: computeFunction)
  }
}
