//
//  CascadedShadowsMap_Debug.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.02.23.
//

#include <metal_stdlib>
#import "../../../Shared/Shader/Vertex.h"
#import "./CascadedShadowsMap.h"
using namespace metal;

constant bool is_texture_visualize_debug [[function_constant(10)]];
constant bool is_csm_texture_visualize_debug [[function_constant(11)]];
constant bool is_cam_texture_visualize_debug [[function_constant(12)]];
constant bool is_light_space_frustum_vertices_debug [[function_constant(13)]];

constant float DEBUG_CSM_TEX_SCALE = 0.13;
constant float DEBUG_CAM_TEX_SCALE = 0.3;
constant float DEBUG_TEX_SCALE_BORDER_PADDING = 0.01;

vertex VertexOut CSMFrustumDebugger_vertex(VertexIn in [[stage_in]],
                                              const uint vertexId [[vertex_id]],
                                              const uint instanceId [[instance_id]],
                                              constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                                              constant float4x4 *instanceLightMatrices [[buffer(LightsMatricesBuffer)]]) {
  VertexOut out;
  float4x4 lightMatrix = instanceLightMatrices[instanceId];
  out.position = lightMatrix * uniforms.modelMatrix * in.position;
  return out;
}

vertex VertexOut CascadedShadowsMap_vertexDebug(const uint vertexId [[vertex_id]],
                                                const uint instanceId [[instance_id]],
                                                constant float3 *vertices [[buffer(VertexBuffer)]]) {

  VertexOut out;
  if (is_texture_visualize_debug) {
    float4 pos = float4(TRIANGLE_VERTICES_NDC[vertexId], 1);

    if (is_csm_texture_visualize_debug) {
      pos.xy *= DEBUG_CSM_TEX_SCALE;
      pos.x -= 1 - DEBUG_CSM_TEX_SCALE - DEBUG_TEX_SCALE_BORDER_PADDING;
      pos.y -= 1 - DEBUG_CSM_TEX_SCALE - DEBUG_TEX_SCALE_BORDER_PADDING - DEBUG_CSM_TEX_SCALE * 2 * instanceId - DEBUG_TEX_SCALE_BORDER_PADDING * instanceId;
    } else if (is_cam_texture_visualize_debug) {
      pos.xy *= DEBUG_CAM_TEX_SCALE;
      pos.x += 1 - DEBUG_CAM_TEX_SCALE - DEBUG_TEX_SCALE_BORDER_PADDING;
      pos.y -= 1 - DEBUG_CAM_TEX_SCALE - DEBUG_TEX_SCALE_BORDER_PADDING;
    }

    out.position = pos;
    out.uv = TRIANGLE_UVS[vertexId];
    out.worldPos = float3(instanceId, 0, 0);
  }

  return out;
}

fragment float4 CascadedShadowsMap_fragmentDebug(VertexOut in [[stage_in]],
                                                 texture2d_array<float> shadowTextures [[texture(ShadowTextures), function_constant(is_csm_texture_visualize_debug)]],
                                                 texture2d<float> camDebugTexture [[texture(CamDebugTexture), function_constant(is_cam_texture_visualize_debug)]]) {

  if (is_texture_visualize_debug) {
    constexpr sampler s(mip_filter::linear,
                        mag_filter::linear,
                        min_filter::linear,
                        address::repeat);


    if (is_csm_texture_visualize_debug) {
      uint arrayIdx = uint(in.worldPos.x);
      float4 texColor = shadowTextures.sample(s, in.uv, arrayIdx);
//      constexpr array<float3, 3> colors = {
//        float3(1, 0, 0),
//        float3(0, 1, 0),
//        float3(0, 0, 1)
//      };
//      float4 layerColor = float4(colors[arrayIdx], 1);
//      texColor = mix(texColor, layerColor, 0.1);
      return texColor;
    } else if (is_cam_texture_visualize_debug) {
      return camDebugTexture.sample(s, in.uv);
    }
  } else {
    return float4(1, 1, 1, 1);
  }
}
