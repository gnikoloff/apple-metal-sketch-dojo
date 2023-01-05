//
//  InfiniteSpace_Shaders.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

#include <metal_stdlib>
#import "./InfiniteSpace.h"
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
                                      const device InfiniteSpace_ControlPoint *controlPoints [[buffer(ControlPointsBuffer)]],
                                      constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]]) {


  uint idx = round((in.position.z + 0.5) * 10);
  float4 pos = in.position;
  float3 controlPoint = controlPoints[idx].position;
  pos.xy += controlPoint.xy;
  pos.z = controlPoint.z;
  float4 worldPos = pos;
//  worldPos.y += sin(idx) * 0.1;
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

kernel void InfiniteSpace_compute(device InfiniteSpace_ControlPoint *controlPoints [[buffer(ControlPointsBuffer)]],
                                  uint id [[thread_position_in_grid]]) {

  device InfiniteSpace_ControlPoint &point = controlPoints[id];

  if (id == 0) {
    point.position.y += sin(point.position.z) * 0.01;
    point.position.z += 0.02;
    if (point.position.z > 2) {
      for (uint i = 0; i < 11; i++) {
        device InfiniteSpace_ControlPoint &p = controlPoints[i];
        p.position.z = -2;
      }
    }
  } else {
    device InfiniteSpace_ControlPoint &prevPoint = controlPoints[id - 1];
    point.position += (prevPoint.position - point.position) * 0.1;
  }
  
//  particle.
}
