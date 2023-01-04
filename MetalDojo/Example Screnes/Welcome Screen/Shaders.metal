//
//  WelcomeScreen.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

#include <metal_stdlib>
using namespace metal;
#import "../../Shared/Common.h"

struct VertexIn {
  float4 position [[attribute(Position)]];
  float2 uv [[attribute(UV)]];
};

struct VertexOut {
  float4 position [[position]];
  float2 uv;
};

vertex VertexOut vertex_welcomeScreen(const VertexIn in [[stage_in]],
                                      constant CameraUniforms &cameraUniforms [[buffer(UniformsBuffer + 1)]]) {
  float4 pos = in.position;
  VertexOut out {
    .position = cameraUniforms.projectionMatrix *
                cameraUniforms.viewMatrix *
                pos,
    .uv = in.uv
  };
  return out;
}

fragment float4 fragment_welcomeScreen(VertexOut in [[stage_in]]) {
  return float4(in.uv, 0.0, 1.0);
}
