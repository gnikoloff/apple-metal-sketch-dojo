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


vertex VertexOut cascadedShadows_vertex(const VertexIn in [[stage_in]],
                                        const uint instanceId [[instance_id]],
                                        constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                                        constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]],
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
  VertexOut out {
    .position = cameraUniforms.projectionMatrix *
                cameraUniforms.viewMatrix *
                worldPos,
    .normal = uniforms.normalMatrix * normal.xyz,
    .uv = in.uv,
    .worldPos = worldPos.xyz
  };

  if (renders_to_texture_array) {
    out.layer = instanceId;
  }

  return out;
}

fragment FragmentOut cascadedShadows_fragmentShadow() {
  FragmentOut out {
    .depth = 0.5
  };
  return out;
}

fragment float4 cascadedShadows_fragment(VertexOut in [[stage_in]],
                                         constant Light *lights [[buffer(LightBuffer)]],
                                         constant Material &material [[buffer(MaterialBuffer)]],
                                         constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]],
                                         constant Params &params [[buffer(ParamsBuffer)]]) {
  float3 normal = normalize(in.normal);
  float3 worldPos = in.worldPos;
  float opacity = 1;
  return PBRLighting(lights,
                     params.lightsCount,
                     material,
                     cameraUniforms.position,
                     worldPos,
                     normal,
                     opacity);
}
