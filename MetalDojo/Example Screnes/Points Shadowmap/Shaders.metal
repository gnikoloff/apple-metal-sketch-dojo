//
//  PointShadowmap.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 02.01.23.
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

struct ShadowFragment {
  float depth [[depth(any)]];
};

struct CubeVertexOut {
  float4 position [[position]];
  float2 uv;
  float3 worldPos;
  uint face [[render_target_array_index]];
};

float computeOpacity(vector_float2 uv) {
  return step(sin(uv.y * 70.0), 0.1);
}

vertex VertexOut pointsShadowmap_vertexMain(const VertexIn in [[stage_in]],
                                      constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                                      constant CameraUniforms &perspCameraUniforms [[buffer(UniformsBuffer + 1)]]) {
  float4 worldPos = uniforms.modelMatrix * in.position;
  VertexOut out {
    .position = perspCameraUniforms.projectionMatrix *
                perspCameraUniforms.viewMatrix *
                worldPos,
    .normal = in.normal,
    .uv = in.uv,
    .worldPos = worldPos.xyz
  };
  return out;
}

fragment ShadowFragment pointsShadowmap_depthFragmentMain(VertexOut in [[stage_in]],
                                                          constant PointsShadowmap_Light &light [[buffer(UniformsBuffer + 2)]]) {
  ShadowFragment out;
  float a = computeOpacity(in.uv);
  if (a < 0.5) {
    discard_fragment();
  }
  out.depth = length(in.worldPos - light.position);
  out.depth /= 25.0;
  return out;
}

float calculateShadow(vector_float3 fragPos,
                      vector_float3 lightPos,
                      texturecube<float> cubeShadowTexture) {

  constexpr sampler s(mip_filter::linear,
                      mag_filter::linear,
                      min_filter::linear);

  float3 fragToLight = fragPos - lightPos;
  float closestDepth = cubeShadowTexture.sample(s, fragToLight).r;
  closestDepth *= 25.0;
  float currentDepth = length(fragToLight);
  float bias = 0.05;
  float shadow = currentDepth - bias > closestDepth ? 0.9 : 0.0;
  return shadow;
}

fragment float4 pointsShadowmap_fragmentCube(VertexOut in [[stage_in]],
                                             constant PointsShadowmap_Light &light [[buffer(UniformsBuffer + 2)]],
                                             texturecube<float> cubeShadowTexture [[texture(PointsShadowmap_CubeShadowTexture)]]) {

  float shadow = calculateShadow(in.worldPos, light.position, cubeShadowTexture);

//  vector_float4 ambient = vector_float4(0.2, 0.5, 1.0, 1.0);
  vector_float4 ambient = vector_float4(0.3, 0.3, 0.3, 1.0);

  return (ambient + (1.0 - shadow)) * float4(in.uv, 0.0, 1.0);
}

fragment float4 pointsShadowmap_fragmentSphere(VertexOut in [[stage_in]]) {
  float a = computeOpacity(in.uv);
  if (a < 0.5) {
    discard_fragment();
  }
  return float4(in.uv, 1.0, 1.0);
}

vertex CubeVertexOut pointsShadowmap_vertexShadow(const VertexIn in [[stage_in]],
                                         const uint instanceId [[instance_id]],
                                         constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                                         constant PointsShadowmap_View *sideUniforms [[buffer(UniformsBuffer + 1)]]) {
  CubeVertexOut out;
  out.face = instanceId;
  float4 worldPos = uniforms.modelMatrix * in.position;
  float4 screenPos = sideUniforms[out.face].viewProjectionMatrix * worldPos;
  out.position = screenPos;
  out.uv = in.uv;
  out.worldPos = worldPos.xyz;
  return out;
}
