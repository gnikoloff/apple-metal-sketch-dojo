//
//  Lighting.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 19.01.23.
//

#include <metal_stdlib>
#import "./Common.h"
using namespace metal;

float calculateAttenuation(float3 attenuation, float d) {
  return 1.0 / (attenuation.x + attenuation.y * d + attenuation.z * d * d);
}

float3 calculateSun(Light light,
                    float3 normal,
                    float3 cameraPosition,
                    Material material) {
  float3 diffuseColor = 0;
  float3 specularColor = 0;
  float3 lightDirection = normalize(-light.position);

  float diffuseIntensity = saturate(-dot(lightDirection, normal));

  diffuseColor += light.color * material.baseColor * diffuseIntensity;

  if (diffuseIntensity > 0) {
    float3 reflection = reflect(lightDirection, normal);
    float3 viewDirection = normalize(cameraPosition);
    float specularIntensity = pow(saturate(dot(reflection, viewDirection)), material.shininess);
    specularColor += light.specularColor * material.specularColor * specularIntensity;
  }
  return diffuseColor + specularColor;
}

float3 calculatePoint(Light light, float3 position, float3 normal, Material material) {
  float d = distance(light.position, position);
  float3 lightDirection = normalize(light.position - position);
  float attenuation = calculateAttenuation(light.attenuation, d);

  float diffuseIntensity =
      saturate(dot(lightDirection, normal));
  float3 color = light.color * material.baseColor * diffuseIntensity;
  color *= attenuation;
  return color;
}

float3 calculateSpot(Light light, float3 position, float3 normal, Material material) {
  float d = distance(light.position, position);
  float3 lightDirection = normalize(light.position - position);
  float3 coneDirection = normalize(light.coneDirection);
  float spotResult = dot(lightDirection, -coneDirection);
  float3 color =  0;
  if (spotResult > cos(light.coneAngle)) {
    float attenuation = calculateAttenuation(light.position, d);
    attenuation *= pow(spotResult, light.coneAttenuation);
    float diffuseIntensity =
             saturate(dot(lightDirection, normal));
    color = light.color * material.baseColor * diffuseIntensity;
    color *= attenuation;
  }
  return color;
}

float3 phongLighting(float3 normal,
                     float3 position,
                     float3 cameraPosition,
                     uint lightsCount,
                     constant Light *lights,
                     Material material) {

  float3 ambientColor = 0;
  float3 accumulatedLighting = 0;

  for (uint i = 0; i < lightsCount; i++) {
    Light light = lights[i];
    switch (light.type) {
      case Sun: {
        accumulatedLighting += calculateSun(light,
                                            normal,
                                            cameraPosition,
                                            material);
        break;
      }
      case Point: {
        accumulatedLighting += calculatePoint(light, position, normal, material);
        break;
      }
      case Spot: {
        accumulatedLighting += calculateSpot(light, position, normal, material);
        break;
      }
      case Ambient: {
        ambientColor += light.color;
        break;
      }
      case unused: {
        break;
      }
    }
  }
  float3 color = accumulatedLighting + ambientColor;
  return color;
}

float3 calculateFog(float3 position, float3 color) {
  float fogDensity = 0.125;
  float3 fogColor = 0.0;
  float fogDistance = length(position.xyz);
  float fogAmount = 1.0 - exp2(-fogDensity * fogDensity * fogDistance * fogDistance * M_LOG2E_F);
  fogAmount = saturate(fogAmount);
  return mix(color, fogColor, fogAmount);
}
