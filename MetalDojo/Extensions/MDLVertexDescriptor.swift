//
//  MDLVertexDescriptor.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

import MetalKit

extension MDLVertexDescriptor {
  static var defaultLayout: MDLVertexDescriptor = {
    let vertexDescriptor = MDLVertexDescriptor()

    // Position and Normal
    var offset = 0
    vertexDescriptor.attributes[Position.index]
      = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float3,
        offset: 0,
        bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float3>.stride
    vertexDescriptor.attributes[Normal.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: offset,
        bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float3>.stride

    // joints and weights attributes
    vertexDescriptor.attributes[Joints.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeJointIndices,
        format: .uShort4,
        offset: offset,
        bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<ushort>.stride * 4

    vertexDescriptor.attributes[Weights.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeJointWeights,
        format: .float4,
        offset: offset,
        bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float4>.stride

    vertexDescriptor.layouts[VertexBuffer.index]
      = MDLVertexBufferLayout(stride: offset)

    // UVs
    vertexDescriptor.attributes[UV.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeTextureCoordinate,
        format: .float2,
        offset: 0,
        bufferIndex: UVBuffer.index)
    vertexDescriptor.layouts[UVBuffer.index]
      = MDLVertexBufferLayout(stride: MemoryLayout<float2>.stride)

    // Vertex Color
    vertexDescriptor.attributes[Color.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeColor,
        format: .float3,
        offset: 0,
        bufferIndex: ColorBuffer.index)
    vertexDescriptor.layouts[ColorBuffer.index]
      = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)

    vertexDescriptor.attributes[Tangent.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeTangent,
        format: .float3,
        offset: 0,
        bufferIndex: TangentBuffer.index)
    vertexDescriptor.layouts[TangentBuffer.index]
      = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    vertexDescriptor.attributes[Bitangent.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeBitangent,
        format: .float3,
        offset: 0,
        bufferIndex: BitangentBuffer.index)
    vertexDescriptor.layouts[BitangentBuffer.index]
      = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    return vertexDescriptor
  }()
}
