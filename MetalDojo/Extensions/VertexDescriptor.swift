//
//  VertexDescriptor.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import MetalKit

extension MDLVertexDescriptor {
  static var defaultLayout: MTLVertexDescriptor? {
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
}
