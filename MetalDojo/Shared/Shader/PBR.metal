//
//  PBR.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

#include <metal_stdlib>
#import "./Common.h"
#import "./Vertex.h"
using namespace metal;

constant float pi = 3.1415926535897932384626433832795;

// functions
float3 computeSpecular(
  float3 normal,
  float3 viewDirection,
  float3 lightDirection,
  float roughness,
  float3 F0);

float3 computeDiffuse(
  Material material,
  float3 normal,
  float3 lightDirection);

float4 PBRLighting(constant Light *lights,
                   uint lightsCount,
                   Material material,
                   float3 cameraPosition,
                   float3 worldPos,
                   float3 normal,
                   float opacity,
                   float shadow);

fragment float4 fragment_pbr(VertexOut in [[stage_in]],
                             constant Light *lights [[buffer(LightBuffer)]],
                             constant Material &_material [[buffer(MaterialBuffer)]],
                             constant CameraUniforms &cameraUniforms [[buffer(CameraUniformsBuffer)]],
                             constant Params &params [[buffer(ParamsBuffer)]],
                             texture2d<float> baseColorTexture [[texture(BaseColor)]],
                             texture2d<float> normalTexture [[texture(NormalTexture)]],
                             texture2d<float> roughnessTexture [[texture(RoughnessTexture)]],
                             texture2d<float> metallicTexture [[texture(MetallicTexture)]],
                             texture2d<float> aoTexture [[texture(AOTexture)]],
                             texture2d<float> opacityTexture [[texture(OpacityTexture)]]) {
  constexpr sampler textureSampler(
    filter::linear,
    address::repeat,
    mip_filter::linear);

  Material material = _material;
  if (!is_null_texture(baseColorTexture)) {
    float4 color = baseColorTexture.sample(textureSampler,in.uv);
    material.baseColor = color.rgb;
  }

  float opacity = 1;
//  float opacity = material.opacity;
//  if (params.alphaBlending) {
//    if (!is_null_texture(opacityTexture)) {
//      opacity = opacityTexture.sample(textureSampler, in.uv).r;
//    }
//  }
  // extract metallic
  if (!is_null_texture(metallicTexture)) {
    material.metallic = metallicTexture.sample(textureSampler, in.uv).r;
  }
  // extract roughness
  if (!is_null_texture(roughnessTexture)) {
    material.roughness = roughnessTexture.sample(textureSampler, in.uv).r;
  }
  // extract ambient occlusion
  if (!is_null_texture(aoTexture)) {
    material.ambientOcclusion = aoTexture.sample(textureSampler, in.uv).r;
  }
  // normal map
  float3 normal;
  if (is_null_texture(normalTexture)) {
    normal = in.normal;
  } else {
    float3 normalValue = normalTexture.sample(textureSampler, in.uv).xyz * 2.0 - 1.0;
    normal = float3x3(
      in.worldTangent,
      in.worldBitangent,
      in.normal) * normalValue;
  }
  normal = normalize(normal);
//  float opacity = 1;
  float shadow = 0;
  return PBRLighting(lights,
                     params.lightsCount,
                     material,
                     cameraUniforms.position,
                     in.worldPos,
                     normal,
                     opacity,
                     shadow);
}

float4 PBRLighting(constant Light *lights,
                   uint lightsCount,
                   Material material,
                   float3 cameraPosition,
                   float3 worldPos,
                   float3 normal,
                   float opacity,
                   float shadow) {
  float3 viewDirection = normalize(cameraPosition - worldPos);
  float3 specularColor = 0;
  float3 diffuseColor = 0;
  for (uint i = 0; i < lightsCount; i++) {
    Light light = lights[i];
    if (light.type == Ambient) {
      diffuseColor += material.baseColor * light.color;
      continue;
    }
    float3 lightDirection = normalize(light.position);
    float3 F0 = mix(0.04, material.baseColor, material.metallic);

    specularColor +=
      saturate(computeSpecular(
        normal,
        viewDirection,
        lightDirection,
        material.roughness,
        F0));

    diffuseColor +=
      saturate(computeDiffuse(
        material,
        normal,
        lightDirection) * light.color);
  }
// shadow calculation
  diffuseColor *= shadow;
  float4 color = float4(diffuseColor * opacity + specularColor, opacity);
  return color;
}

float G1V(float nDotV, float k)
{
  return 1.0f / (nDotV * (1.0f - k) + k);
}

// specular optimized-ggx
// AUTHOR John Hable. Released into the public domain
float3 computeSpecular(float3 normal, float3 viewDirection, float3 lightDirection, float roughness, float3 F0) {
  float alpha = roughness * roughness;
  float3 halfVector = normalize(viewDirection + lightDirection);
  float nDotL = saturate(dot(normal, lightDirection));
  float nDotV = saturate(dot(normal, viewDirection));
  float nDotH = saturate(dot(normal, halfVector));
  float lDotH = saturate(dot(lightDirection, halfVector));

  float3 F;
  float D, vis;

  // Distribution
  float alphaSqr = alpha * alpha;
  float pi = 3.14159f;
  float denom = nDotH * nDotH * (alphaSqr - 1.0) + 1.0f;
  D = alphaSqr / (pi * denom * denom);

  // Fresnel
  float lDotH5 = pow(1.0 - lDotH, 5);
  F = F0 + (1.0 - F0) * lDotH5;

  // V
  float k = alpha / 2.0f;
  vis = G1V(nDotL, k) * G1V(nDotV, k);

  float3 specular = nDotL * D * F * vis;
  return specular;
}

// diffuse
float3 computeDiffuse(Material material, float3 normal, float3 lightDirection) {
  float nDotL = saturate(dot(normal, lightDirection));
  float3 diffuse = float3(((1.0/pi) * material.baseColor) * (1.0 - material.metallic));
  diffuse = float3(material.baseColor) * (1.0 - material.metallic);
  return diffuse * nDotL * material.ambientOcclusion;
}
