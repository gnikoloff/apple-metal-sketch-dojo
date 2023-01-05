//
//  InfiniteSpace_Shaders.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

#include <metal_stdlib>
#import "../../Shared/Common.h"
using namespace metal;

struct VertexIn {
  float4 position [[attribute(Position)]];
  float3 normal [[attribute(Normal)]];
  float2 uv [[attribute(UV)]];
};

struct VertexOut {
  float4 position [[position]];
  float3 normal;
  float2 uv;
  float3 worldPos;
};


struct FragmentOut {
  float4 color [[color(0)]];
};

// -------- main --------

vertex VertexOut infiniteSpace_vertex(const VertexIn in [[stage_in]],
                                      constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]]) {
  float4 worldPos = in.position;
  VertexOut out {
    .position = cameraUniforms.projectionMatrix * cameraUniforms.viewMatrix * worldPos,
    .normal = in.normal,
    .uv = in.uv,
    .worldPos = worldPos.xyz
  };
  return out;
}

fragment FragmentOut infiniteSpace_fragment(VertexOut in [[stage_in]]) {
  FragmentOut out {
    .color = float4(in.uv, 0.0, 1.0)
  };
  return out;
}
