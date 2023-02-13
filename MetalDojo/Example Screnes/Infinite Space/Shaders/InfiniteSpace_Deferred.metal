//
//  InfiniteSpace_Deferred.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 17.01.23.
//

#include <metal_stdlib>
#import "./InfiniteSpace.h"
#import "../../../Shared/Shader/Vertex.h"
#import "../../../Shared/Shader/ShaderHelpers.h"
#import "../../../Shared/Shader/LightingHelpers.h"

using namespace metal;

struct GBufferOut {
  float4 normal [[color(RenderTargetNormal)]];
  float4 position [[color(RenderTargetPosition)]];
};

struct GBufferVertexOut {
  float4 position [[position]];
  float3 normal;
  vector_float3 worldPos;
  float shininess;
  float baseColor;
  float specularColor;
};

// Mark: Deferred pass

vertex GBufferVertexOut infiniteSpace_vertexCube(const VertexIn in [[stage_in]],
                                             uint iid [[instance_id]],
                                             const device InfiniteSpace_ControlPoint *controlPoints [[buffer(ControlPointsBuffer)]],
                                             const device Material *cubeMaterials [[buffer(MaterialsBuffer)]],
                                             constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]],
                                             constant Uniforms &uniforms [[buffer(UniformsBuffer)]]) {
  uint idx = round((in.position.z + 0.5) * 9);
  float3 controlPoint = controlPoints[iid * 10 + idx].position;

  matrix_float4x4 rotMatrix = rotation3d(float3(0, 0, 1), controlPoint.z);
  float4 pos = rotMatrix * in.position;
  pos.xy += controlPoint.xy;
  pos.z = controlPoint.z;
  float4 worldPos = pos;
  Material material = cubeMaterials[iid];
  GBufferVertexOut out {
    .position = cameraUniforms.projectionMatrix * cameraUniforms.viewMatrix * worldPos,
    .normal = (rotMatrix * float4(uniforms.normalMatrix * in.normal, 1.0)).xyz,
    .worldPos = worldPos.xyz,
    .shininess = material.shininess,
    .baseColor = material.baseColor.r,
    .specularColor = material.specularColor.r
  };
  return out;
}

fragment GBufferOut infiniteSpace_fragmentCube(GBufferVertexOut in [[stage_in]]) {
  float3 normal = normalize(in.normal);
  GBufferOut out {
    .normal = float4(encodeNormals(normal), in.shininess, in.baseColor),
    .position = float4(in.worldPos, in.specularColor)
  };
  return out;
}

// Mark: Point Light pass

vertex VertexOut InfiniteSpace_vertexPointLight(VertexIn in [[stage_in]],
                                                constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]],
                                                constant Light *lights [[buffer(LightBuffer)]],
                                                uint instanceId [[instance_id]]) {
  float4 lightPosition = float4(lights[instanceId].position, 0);
  float4 instancePosition = in.position + lightPosition;
  float4 position = cameraUniforms.projectionMatrix *
                    cameraUniforms.viewMatrix *
                    instancePosition;
  VertexOut out {
    .position = position,
    .instanceId = instanceId
  };
  return out;
}

fragment float4 InfiniteSpace_fragmentPointLight(VertexOut in [[stage_in]],
                                                 constant Light *lights [[buffer(LightBuffer)]],
                                                 GBufferOut gBuffer) {
  Light light = lights[in.instanceId];
//  return float4(light.color, 1);
  float3 normal = decodeNormals(gBuffer.normal.xy);
  float3 position = gBuffer.position.xyz;

  Material material {
    .baseColor = 1
  };
  float3 lighting = calculatePoint(light, position, normal, material);
  lighting *= 0.5;
  lighting = calculateFog(position, lighting);
  return float4(lighting, 1);
}

// Mark: Sun Light pass

constant float3 TRIANGLE_VERTICES[6] = {
  float3(-1,  1,  0),    // triangle 1
  float3( 1, -1,  0),
  float3(-1, -1,  0),
  float3(-1,  1,  0),    // triangle 2
  float3( 1,  1,  0),
  float3( 1, -1,  0)
};

vertex VertexOut infiniteSpace_vertexQuad(uint vertexID [[vertex_id]]) {
  VertexOut out {
    .position = float4(TRIANGLE_VERTICES[vertexID], 1)
  };
  return out;
}

fragment float4 InfiniteSpace_fragmentDeferredSun(VertexOut in [[stage_in]],
                                                  GBufferOut gBuffer,
                                                  constant InfiniteSpace_DeferredSettings &settings [[buffer(DeferredSettingsBuffer)]],
                                                  constant Light *lights [[buffer(LightBuffer)]],
                                                  constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]]) {
  float3 position = gBuffer.position.xyz;
  float3 normal = decodeNormals(gBuffer.normal.xy);
  Material cubeMaterial = {
    .shininess = gBuffer.normal.z,
    .baseColor = gBuffer.normal.w,
    .specularColor = gBuffer.position.w
  };
  float3 color = phongLighting(normal,
                               position.xyz,
                               cameraUniforms.position,
                               2,
                               lights,
                               cubeMaterial);


  color = calculateFog(position, color);

  return float4(color, 1.0);
}
