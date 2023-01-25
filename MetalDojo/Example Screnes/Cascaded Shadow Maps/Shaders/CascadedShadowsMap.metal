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
                                        constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                                        constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]]) {
  float4 worldPos = uniforms.modelMatrix * in.position;
  VertexOut out {
    .position = cameraUniforms.projectionMatrix *
                cameraUniforms.viewMatrix *
                worldPos,
    .normal = uniforms.normalMatrix * in.normal,
    .uv = in.uv,
    .worldPos = worldPos.xyz
  };
  return out;
}

fragment float4 cascadedShadows_fragment(VertexOut in [[stage_in]],
                                         constant Light *lights [[buffer(LightBuffer)]],
                                         constant Material &material [[buffer(MaterialBuffer)]],
                                         constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]]) {
  float3 normal = normalize(in.normal);
  float3 worldPos = in.worldPos;
  float opacity = 1;
  return PBRLighting(lights,
                     2,
                     material,
                     cameraUniforms.position,
                     worldPos,
                     normal,
                     opacity);
}
