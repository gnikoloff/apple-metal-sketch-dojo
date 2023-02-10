//
//  CascadedShadowsMap.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

#include <metal_stdlib>
#import "../../../Shared/Shader/Vertex.h"
#import "../../../Shared/Shader/LightingHelpers.h"
#import "./CascadedShadowsMap.h"
using namespace metal;

constant bool does_not_render_to_texture_array = !renders_to_texture_array;
constant bool instances_have_unique_positions [[function_constant(10)]];
constant bool uses_debug_camera [[function_constant(11)]];

uint ShadowLayerIdxCalculate(float3 worldPos,
                             constant CameraUniforms &cameraUniforms,
                             constant CascadedShadowsMap_Settings &settings) {
  float4 fragPosViewSpace = cameraUniforms.viewMatrix * float4(worldPos, 1);
  float depthValue = abs(fragPosViewSpace.z);

  int layer = -1;
  for (uint i = 0; i < settings.cascadesCount; ++i) {
    if (depthValue < settings.cascadePlaneDistances[i]) {
      layer = i;
      break;
    }
  }
  if (layer == -1) {
    layer = settings.cascadesCount;
  }
  return layer;
}

float ShadowCalculate(float3 worldPos,
                      float3 normal,
                      constant CameraUniforms &cameraUniforms,
                      constant CascadedShadowsMap_Settings &settings,
                      constant float4x4 *lightMatrices,
                      depth2d_array<float> shadowTextures [[texture(ShadowTextures)]]) {

  uint layer = ShadowLayerIdxCalculate(worldPos, cameraUniforms, settings);

  float4 fragPosLightSpace = lightMatrices[layer] * float4(worldPos, 1);

  // perform perspective divide
  float3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
  // transform to [0,1] range
  projCoords.xy = projCoords.xy * 0.5 + 0.5;
  projCoords.y = 1 - projCoords.y;
  projCoords.xy = saturate(projCoords.xy);
  // get depth of current fragment from light's perspective
  float currentDepth = projCoords.z;

  // keep the shadow at 0.0 when outside the far_plane region of the light's frustum.
  if (currentDepth > 1) {
    return 0;
  }

  // calculate bias (based on depth map resolution and slope)
  float3 lightDir = normalize(float3(10, 10, 10));
  float bias = max(0.01 * (dot(normal, lightDir)), 0.0001);
  float biasModifier = 2;

  if (layer == 0) {
    bias *= 1 / (settings.cascadePlaneDistances[layer] * 3);
  } else if (layer == 1) {
    bias *= 1 / (settings.cascadePlaneDistances[layer] * 0.9);
  } else if (layer == 2) {
    bias *= 1 / (settings.cascadePlaneDistances[layer] * 0.7);
  } else {
    bias *= 1 / (cameraUniforms.far * 0.5);
  }

  constexpr sampler s(filter::linear,
                      coord::normalized,
                      compare_func::less,
                      address::clamp_to_edge);

  // PCF
  float shadow = 0;
  float2 texelSize = 1 / settings.shadowTexSize;
  for(int x = -1; x <= 1; ++x) {
    for(int y = -1; y <= 1; ++y) {
      float2 uv = projCoords.xy + float2(x, y) * texelSize;
      float pcfDepth = shadowTextures.sample(s, uv, layer);
      shadow += (currentDepth - bias) < pcfDepth ? 1 : 0.5;
    }
  }
  shadow /= 9.0;

  return shadow;
}

vertex VertexOut cascadedShadows_vertex(const VertexIn in [[stage_in]],
                                        const uint instanceId [[instance_id]],
                                        constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                                        constant CascadedShadowsMap_Settings &settings [[buffer(SettingsBuffer)]],
                                        constant float4x4 *cubeInstances [[buffer(CubeInstancesBuffer), function_constant(instances_have_unique_positions)]],
                                        constant float4x4 *instanceLightMatrices [[buffer(LightsMatricesBuffer), function_constant(renders_to_texture_array)]],
                                        constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer), function_constant(does_not_render_to_texture_array)]],
                                        constant CameraUniforms &debugCameraUniforms [[buffer(DebugCameraBuffer), function_constant(does_not_render_to_texture_array)]],
                                        constant float4x4 *jointMatrices [[buffer(JointBuffer), function_constant(has_skeleton)]]) {
  float4 position = in.position;
  float4 normal = float4(in.normal, 0);
  if (has_skeleton) {
    float4 weights = in.weights;
    ushort4 joints = in.joints;
    position =
        weights.x * (jointMatrices[joints.x] * position) +
        weights.y * (jointMatrices[joints.y] * position) +
        weights.z * (jointMatrices[joints.z] * position) +
        weights.w * (jointMatrices[joints.w] * position);
    normal =
        weights.x * (jointMatrices[joints.x] * normal) +
        weights.y * (jointMatrices[joints.y] * normal) +
        weights.z * (jointMatrices[joints.z] * normal) +
        weights.w * (jointMatrices[joints.w] * normal);
  }

  float4 worldPos = uniforms.modelMatrix * position;
  if (instances_have_unique_positions) {
    float4x4 instanceMatrix = cubeInstances[instanceId];
    worldPos = uniforms.modelMatrix * instanceMatrix * in.position;
  }

  VertexOut out {
    .normal = uniforms.normalMatrix * normal.xyz,
    .uv = in.uv,
    .worldPos = worldPos.xyz
  };

  uint uid = instanceId;

  if (instances_have_unique_positions) {
    uid /= settings.cubesCount;
  }

  if (renders_to_texture_array) {
    float4x4 lightMatrix = instanceLightMatrices[uid];
    out.position = lightMatrix * worldPos;
  } else {
    if (uses_debug_camera) {
      out.position =  debugCameraUniforms.projectionMatrix *
                      debugCameraUniforms.viewMatrix *
                      worldPos;
    } else {
      out.position =  cameraUniforms.projectionMatrix *
                      cameraUniforms.viewMatrix *
                      worldPos;
    }
  }

  if (renders_to_texture_array) {
    out.layer = uid;
  }

  return out;
}

fragment float4 cascadedShadows_fragment(VertexOut in [[stage_in]],
                                         constant Light *lights [[buffer(LightBuffer)]],
                                         constant Material &material [[buffer(MaterialBuffer)]],
                                         constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]],
                                         constant Params &params [[buffer(ParamsBuffer)]],
                                         constant CascadedShadowsMap_Settings &settings [[buffer(SettingsBuffer)]],
                                         constant float4x4 *instanceLightMatrices [[buffer(LightsMatricesBuffer)]],
                                         depth2d_array<float> shadowTextures [[texture(ShadowTextures)]]) {
  float3 normal = normalize(in.normal);
  float3 worldPos = in.worldPos;
  float opacity = 1;

  float shadow = ShadowCalculate(worldPos,
                                 normal,
                                 cameraUniforms,
                                 settings,
                                 instanceLightMatrices,
                                 shadowTextures);

  float4 color = PBRLighting(lights,
                             params.lightsCount,
                             material,
                             cameraUniforms.position,
                             worldPos,
                             normal,
                             opacity,
                             shadow);

//  constexpr array<float3, 4> colors = {
//    float3(1, 0, 0),
//    float3(0, 1, 0),
//    float3(0, 0, 1),
//    float3(1, 1, 1)
//  };
//  uint layer = ShadowLayerIdxCalculate(worldPos, cameraUniforms, settings);
//  float4 layerColor = float4(colors[layer], 1);
//  color = mix(color, layerColor, 0.1);

  return color;
}
