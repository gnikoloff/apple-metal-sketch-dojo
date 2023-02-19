//
//  WelcomeScreen.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

#include <metal_stdlib>
#import "../../../Shared/Shader/Common.h"
#import "../../../Shared/Shader/ShaderHelpers.h"
#import "../../../Shared/Shader/Vertex.h"
#import "./WelcomeScreen.h"
using namespace metal;

vertex VertexOut vertex_welcomeScreen(const VertexIn in [[stage_in]],
                                      constant CameraUniforms &cameraUniforms [[buffer(UniformsBuffer + 1)]]) {
  float4 pos = in.position;
  VertexOut out {
    .position = cameraUniforms.projectionMatrix *
                cameraUniforms.viewMatrix *
                pos
  };

  if (has_uv) {
    out.uv = in.uv;
  }

  return out;
}

fragment float4 fragment_welcomeScreen(VertexOut in [[stage_in]],
                                       texture2d<float> texture [[texture(ProjectTexture)]]) {
//  uint texWidth = projectTexture.get_width();
//  uint texHeight = projectTexture.get_height();
//  float2 imageSize = float2(texWidth, texHeight);
//  float2 uv = uvBackgroundSizeCover(in.uv, imageSize, abs(settings.surfaceSize));
  constexpr sampler s(mip_filter::linear,
                      mag_filter::linear,
                      min_filter::linear);
  return texture.sample(s, in.uv);
  return float4(in.uv, 0.0, 1.0);
}

fragment float4 fragment_welcomeDebugAABB(VertexOut in [[stage_in]]) {
  return float4(1.0, 0.0, 0.0, 1.0);
}
