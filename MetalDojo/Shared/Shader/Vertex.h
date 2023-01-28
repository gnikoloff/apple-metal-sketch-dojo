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

constant bool renders_to_texture_array [[function_constant(RendersToTargetArray)]];
constant bool has_skeleton [[function_constant(IsSkeletonAnimation)]];
constant bool renders_depth [[function_constant(RendersDepth)]];

struct VertexIn {
  vector_float4 position [[attribute(Position)]];
  vector_float3 normal [[attribute(Normal)]];
  vector_float2 uv [[attribute(UV)]];
  ushort4 joints [[attribute(Joints), function_constant(has_skeleton)]];
  float4 weights [[attribute(Weights), function_constant(has_skeleton)]];
};

struct VertexOut {
  vector_float4 position [[position]];
  vector_float3 normal;
  vector_float2 uv;
  vector_float3 worldPos;
  vector_float3 worldTangent;
  vector_float3 worldBitangent;
  uint layer [[render_target_array_index, function_constant(renders_to_texture_array)]];
};

struct FragmentOut {
  float depth [[depth(any), function_constant(renders_depth)]];
};

#endif /* Header_h */
