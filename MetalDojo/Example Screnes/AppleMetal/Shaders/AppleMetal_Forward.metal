//
//  AppleMetal_Shaders.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 19.01.23.
//

#include <metal_stdlib>
#import "./AppleMetal.h"
#import "../../../Shared/ShaderHelpers.h"
#import "../../../Shared/LightingHelpers.h"
using namespace metal;

constant bool IS_LIGHT [[function_constant(0)]];
constant uint LIGHTS_COUNT [[function_constant(1)]];

struct VertexIn {
  vector_float4 position [[attribute(Position)]];
  vector_float3 normal [[attribute(Normal)]];
  vector_float3 color [[attribute(Color)]];
};

struct VertexOut {
  vector_float4 position [[position]];
  vector_float3 normal;
  vector_float3 worldPos;
  vector_float3 color;
};


struct FragmentOut {
  float4 color [[color(0)]];
};

vertex VertexOut appleMetal_vertex(const VertexIn in [[stage_in]],
                                        const uint iid [[instance_id]],
                                        constant Light *lights [[buffer(LightBuffer)]],
                                        constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                                        constant CameraUniforms &perspCameraUniforms [[buffer(CameraUniformsBuffer)]],
                                        constant AppleMetal_MeshInstance *instances [[buffer(InstancesBuffer)]],
                                        constant AppleMetal_AnimSettings &animSettings [[buffer(AnimationSettingsBuffer)]]) {

  constant AppleMetal_MeshInstance &instance = instances[iid];
  matrix_float4x4 rotMatrix = rotation3d(instance.position, perspCameraUniforms.time);
  float4 worldPos = 0.0;
  if (IS_LIGHT) {
    constant Light &light = lights[iid];
    worldPos = in.position;
    worldPos.xyz += light.position;
  } else {
    worldPos = rotMatrix * in.position;
    worldPos += mix(float4(mix(instance.position1, instance.position2, animSettings.wordMode), 0),
                    float4(instance.position, 0),
                    saturate(animSettings.mode - float(iid) / 1090 * 0.5));
  }
  VertexOut out {
    .position = perspCameraUniforms.projectionMatrix *
                perspCameraUniforms.viewMatrix *
                worldPos,
    .normal = (rotMatrix * float4(uniforms.normalMatrix * in.normal, 0)).xyz,
    .worldPos = worldPos.xyz
  };
  if (IS_LIGHT) {
    constant Light &light = lights[iid];
    out.color = light.color;
  }
  return out;
}

fragment FragmentOut appleMetal_fragment(VertexOut in [[stage_in]],
                                         constant Light *lights [[buffer(LightBuffer)]],
                                         constant CameraUniforms &perspCameraUniforms [[buffer(CameraUniformsBuffer)]]) {

  Material material {
    .shininess = 1,
    .baseColor = 0.2,
    .specularColor = 0.8
  };

  float3 color = 0.0;

  if (IS_LIGHT) {
    color += in.color;
  } else {
    color += phongLighting(in.normal,
                           in.worldPos.xyz,
                           perspCameraUniforms.position,
                           LIGHTS_COUNT,
                           lights,
                           material);
  }



  FragmentOut out {
    .color = float4(color, 1.0)
  };
  return out;
}
