//
//  Header.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 17.01.23.
//

#ifndef Header_h
#define Header_h

#import <simd/simd.h>
#import "./Common.h"

struct VertexIn {
  vector_float4 position [[attribute(Position)]];
  vector_float3 normal [[attribute(Normal)]];
  vector_float2 uv [[attribute(UV)]];
};

struct VertexOut {
  vector_float4 position [[position]];
  vector_float3 normal;
  vector_float2 uv;
  vector_float3 worldPos;
  vector_float3 worldTangent;
  vector_float3 worldBitangent;
};

#endif /* Header_h */
