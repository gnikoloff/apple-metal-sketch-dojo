//
//  PointShadowmap.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 02.01.23.
//

#include <metal_stdlib>
#import "./PointsShadowmap.h"
using namespace metal;

constant bool is_cubemap_render [[function_constant(0)]];
constant bool is_not_cubemap_render = !is_cubemap_render;
constant bool is_sphere_back_side [[function_constant(1)]];
constant bool is_shaded_and_shadowed [[function_constant(2)]];
constant bool is_cut_off_alpha [[function_constant(3)]];

constant float shadow_camera_depth = 25.0;

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
  uint face [[render_target_array_index, function_constant(is_cubemap_render)]];
};

struct FragmentOut {
  float depth [[depth(any), function_constant(is_cubemap_render)]];
  float4 color [[color(0), function_constant(is_not_cubemap_render)]];
};

// -------- helpers --------

float computeOpacity(vector_float2 uv) {
  return step(sin(uv.y * 30.0), 0.1);
}

float calculateShadow(vector_float3 fragPos,
                      vector_float3 lightPos,
                      texturecube<float> cubeShadowTexture) {

  constexpr sampler s(mip_filter::linear,
                      mag_filter::linear,
                      min_filter::linear);

  float3 fragToLight = fragPos - lightPos;
  float closestDepth = cubeShadowTexture.sample(s, fragToLight).r;
  closestDepth *= shadow_camera_depth;
  float currentDepth = length(fragToLight);
  float bias = 0.05;
  float shadow = currentDepth - bias > closestDepth ? 0.9 : 0.0;
  return shadow;
}

float pow2(float x) {
  return x * x;
}

float pow4(float x) {
  float x2 = x * x;
  return x2 * x2;
}

float getDistanceAttenuation(float lightDistance,
                             float cutoffDistance,
                             float decayExponent) {
  float distanceFalloff = 1.0 / max(pow(lightDistance, decayExponent), 0.01);
  if (cutoffDistance > 0.0) {
    distanceFalloff *= pow2(saturate(1.0 - pow4(lightDistance / cutoffDistance)));
  }
  return distanceFalloff;
}

// -------- main --------

fragment FragmentOut pointsShadowmap_depthFragmentSphere(VertexOut in [[stage_in]],
                                                         constant PointsShadowmap_Light &light [[buffer(ShadowCameraUniformsBuffer)]]) {
  FragmentOut out;
  float a = computeOpacity(in.uv);
  if (a < 0.5) {
    discard_fragment();
  }
  out.depth = length(in.worldPos - light.position);
  out.depth /= shadow_camera_depth;
  return out;
}

fragment FragmentOut pointsShadowmap_fragmentMain(VertexOut in [[stage_in]],
                                                  constant PointsShadowmap_Light *light [[buffer(ShadowCameraUniformsBuffer), function_constant(is_shaded_and_shadowed)]],
                                                  array<texturecube<float>, 2> cubeShadowTextures [[texture(PointsShadowmap_CubeShadowTextures), function_constant(is_shaded_and_shadowed)]]) {

  FragmentOut out;

  if (is_shaded_and_shadowed) {
    float3 normal = normalize(-in.normal);
    float3 ambient = 0.3;

    out.color = float4(0.0);

    for (int i = 0; i < 2; i++) {
      float3 lightPos = light[i].position;
      float3 lightColor = light[i].color;
      float lightCutOffDistance = light[i].cutoffDistance;
      
      // attenuation
      float lightDistance = length(lightPos - in.worldPos);
      float attenuation = getDistanceAttenuation(lightDistance, lightCutOffDistance, 0.001);

      float3 lightDir = normalize(lightPos - in.worldPos);
      float diff = max(dot(lightDir, normal), 0.0);
      float3 diffuse = diff * lightColor;
      diffuse *= attenuation;

      float shadow = calculateShadow(in.worldPos, lightPos, cubeShadowTextures[i]);

      out.color += float4((ambient + (1.0 - shadow)) * diffuse, 1.0);
    }
  } else {
    if (is_cut_off_alpha) {
      float a = computeOpacity(in.uv);
      if (a < 0.5) {
        discard_fragment();
      }
    }

    if (is_sphere_back_side) {
      out.color = float4(float3(1.0), 1.0);
    } else {
      out.color = float4(in.uv, 1.0, 1.0);
    }
  }

  return out;
}

vertex VertexOut pointsShadowmap_vertex(const VertexIn in [[stage_in]],
                                        const uint instanceId [[instance_id]],
                                        constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                                        constant CameraUniforms &perspCameraUniforms [[buffer(CameraUniformsBuffer), function_constant(is_not_cubemap_render)]],
                                        constant PointsShadowmap_View *sideUniforms [[buffer(ShadowCameraUniformsBuffer), function_constant(is_cubemap_render)]]) {
  float4 worldPos = uniforms.modelMatrix * in.position;
  VertexOut out;
  if (is_cubemap_render) {
    out.face = instanceId;
    float4 screenPos = sideUniforms[out.face].viewProjectionMatrix * worldPos;
    out.position = screenPos;
  } else {
    out.position = perspCameraUniforms.projectionMatrix *
      perspCameraUniforms.viewMatrix *
      worldPos;
  }
  out.uv = in.uv;
  out.normal = in.normal;
  out.worldPos = worldPos.xyz;
  return out;
}
