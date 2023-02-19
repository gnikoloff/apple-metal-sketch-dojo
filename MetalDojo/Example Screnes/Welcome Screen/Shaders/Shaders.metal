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

  VertexOut out;

  float4 pos = in.position;
  out.position = cameraUniforms.projectionMatrix * cameraUniforms.viewMatrix * pos;
  out.uv = in.uv;


  return out;
}

vertex VertexOut vertex_welcomeScreenCtrlPoints(const uint vertexId [[vertex_id]],
                                                const uint instanceId [[instance_id]],
                                                constant CameraUniforms &cameraUniforms [[buffer(UniformsBuffer + 1)]],
                                                constant float2 *ctrlPoints [[buffer(UniformsBuffer + 2)]]) {

  float3 ndcPos = TRIANGLE_VERTICES_NDC[vertexId] * 10;
  float2 ctrlPointPos = ctrlPoints[instanceId];
  float4 pos = float4(ndcPos.xy + ctrlPointPos, 0, 1);

  VertexOut out;
  out.instanceId = instanceId;
  out.position = cameraUniforms.projectionMatrix * cameraUniforms.viewMatrix * pos;
  out.uv = TRIANGLE_UVS[vertexId];
  return out;
}

fragment FragmentOut fragment_welcomeScreen(VertexOut in [[stage_in]],
                                       texture2d<float> texture [[texture(ProjectTexture)]]) {
  constexpr sampler s(filter::linear);
  FragmentOut out {
    .color = texture.sample(s, in.uv)
  };
  return out;
}

fragment FragmentOut fragment_welcomeScreenCtrlPoints(VertexOut in [[stage_in]]) {
  float dist = distance(in.uv, float2(0.5));
  if (dist > 0.5) {
    discard_fragment();
  }
  FragmentOut out {
    .color = float4(1, 0, 0, 1)
  };
  return out;
}
