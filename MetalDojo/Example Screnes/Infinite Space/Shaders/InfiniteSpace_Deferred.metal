//
//  InfiniteSpace_Deferred.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 17.01.23.
//

#include <metal_stdlib>
#import "./InfiniteSpace.h"
#import "./Lighting.h"
#import "../../../Shared/Vertex.h"

using namespace metal;

struct GBufferOut {
//  float4 albedo [[color(RenderTargetAlbedo)]];
  float4 normal [[color(RenderTargetNormal)]];
  float4 position [[color(RenderTargetPosition)]];
};

struct PointLightIn {
  float4 position [[attribute(Position)]];
};

struct PointLightOut {
  float4 position [[position]];
  uint instanceId [[flat]];
};

struct GBufferVertexOut {
  float4 position [[position]];
  float3 normal;
  vector_float3 worldPos;
  float shininess;
  float baseColor;
  float specularColor;
};

// Mark: Helpers

float2 encodeNormals(float3 n) {
  float p = sqrt(n.z * 8.0 + 8.0);
  return float2(n.xy / p + 0.5);
}

float3 decodeNormals(float2 enc) {
  float2 fenc = enc * 4.0 - 2.0;
  float f = dot(fenc, fenc);
  float g = sqrt(1.0 - f / 4.0);
  return float3(fenc * g, 1.0 - f / 2.0);
}

matrix_float4x4 rotation3d(float3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return matrix_float4x4(
                         oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
    0.0,                                0.0,                                0.0,                                1.0
  );
}

// Mark: Deferred pass

vertex GBufferVertexOut infiniteSpace_vertexCube(const VertexIn in [[stage_in]],
                                             uint iid [[instance_id]],
                                             const device InfiniteSpace_ControlPoint *controlPoints [[buffer(ControlPointsBuffer)]],
                                             const device InfiniteSpace_CubeMaterial *cubeMaterials [[buffer(MaterialsBuffer)]],
                                             constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]]) {
  uint idx = round((in.position.z + 0.5) * 9);
  float3 controlPoint = controlPoints[iid * 10 + idx].position;

  matrix_float4x4 rotMatrix = rotation3d(float3(0, 0, 1), controlPoint.z);
  float4 pos = rotMatrix * in.position;
  pos.xy += controlPoint.xy;
  pos.z = controlPoint.z;
  float4 worldPos = pos;
  InfiniteSpace_CubeMaterial material = cubeMaterials[iid];
  GBufferVertexOut out {
    .position = cameraUniforms.projectionMatrix * cameraUniforms.viewMatrix * worldPos,
    .normal = (rotMatrix * float4(in.normal, 1.0)).xyz,
    .worldPos = worldPos.xyz,
    .shininess = material.shininess,
    .baseColor = material.baseColor,
    .specularColor = material.specularColor
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

vertex PointLightOut InfiniteSpace_vertexPointLight(PointLightIn in [[stage_in]],
                                       constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]],
                                       constant InfiniteSpace_Light *lights [[buffer(LightBuffer)]],
                                       uint instanceId [[instance_id]]) {
  float4 lightPosition = float4(lights[instanceId].position, 0);
  float4 instancePosition = in.position + lightPosition;
  float4 position = cameraUniforms.projectionMatrix *
                    cameraUniforms.viewMatrix *
                    instancePosition;
  PointLightOut out {
    .position = position,
    .instanceId = instanceId
  };
  return out;
}

fragment float4 InfiniteSpace_fragmentPointLight(PointLightOut in [[stage_in]],
                                                 constant InfiniteSpace_Light *lights [[buffer(LightBuffer)]],
                                                 GBufferOut gBuffer) {
  InfiniteSpace_Light light = lights[in.instanceId];
//  return float4(light.color, 1);
  float3 normal = decodeNormals(gBuffer.normal.xy);
  float3 position = gBuffer.position.xyz;

  InfiniteSpace_CubeMaterial material {
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
                                                  constant InfiniteSpace_Light *lights [[buffer(LightBuffer)]],
                                                  constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]]) {
  float3 position = gBuffer.position.xyz;
  float3 normal = decodeNormals(gBuffer.normal.xy);
  InfiniteSpace_CubeMaterial cubeMaterial = {
    .shininess = gBuffer.normal.z,
    .baseColor = gBuffer.normal.w,
    .specularColor = gBuffer.position.w
  };
  float3 color = phongLighting(normal,
                               position.xyz,
                               cameraUniforms,
                               lights,
                               cubeMaterial);


  color = calculateFog(position, color);

  return float4(color, 1.0);
}
