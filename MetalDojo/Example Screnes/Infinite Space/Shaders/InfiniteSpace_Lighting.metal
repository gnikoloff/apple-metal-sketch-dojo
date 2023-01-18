//
//  InfiniteSpace_Lighting.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 17.01.23.
//

#include <metal_stdlib>
#import "./InfiniteSpace.h"

using namespace metal;

float3 calculateSun(InfiniteSpace_Light light,
                    float3 normal,
                    float3 cameraPosition,
                    InfiniteSpace_CubeMaterial material) {
  float3 diffuseColor = 0;
  float3 specularColor = 0;
  float3 lightDirection = normalize(-light.position);

  float diffuseIntensity =
    saturate(-dot(lightDirection, normal));

  diffuseColor += light.color * material.baseColor * diffuseIntensity;

  if (diffuseIntensity > 0) {
    float3 reflection =
        reflect(lightDirection, normal);
    float3 viewDirection =
        normalize(cameraPosition);
    float specularIntensity =
        pow(saturate(dot(reflection, viewDirection)),
            material.shininess);
    specularColor +=
        light.specularColor * material.specularColor
* specularIntensity;
  }
  return diffuseColor + specularColor;
}

float3 calculatePoint(InfiniteSpace_Light light,
                      float3 position,
                      float3 normal,
                      InfiniteSpace_CubeMaterial material) {
  float d = distance(light.position, position);
  float3 lightDirection = normalize(light.position - position);
//  float attenuation = 1.0 / (light.attenuation.x +
//      light.attenuation.y * d + light.attenuation.z * d * d);
  float attenuation = d / (1 - d) * d;
  attenuation = attenuation + 1;
  attenuation = 1 / (attenuation * attenuation);
//  float attenuation = dist / (1.0 - (dist / lightR) * (dist / lightR));
//      attenuation = attenuation / lightR + 1.0;
//      attenuation = 1.0 / (attenuation * attenuation);
  float diffuseIntensity =
      saturate(dot(lightDirection, normal));
  float3 color = light.color * diffuseIntensity * attenuation;
  return color;
}

float3 phongLighting(float3 normal,
                     float3 position,
                     constant CameraUniforms &cameraUniforms,
                     constant InfiniteSpace_Light *lights,
                     InfiniteSpace_CubeMaterial material) {

  float3 ambientColor = 0;
  float3 accumulatedLighting = 0;

  for (uint i = 0; i < 2; i++) {
    InfiniteSpace_Light light = lights[i];
    switch (light.type) {
      case Sun: {
        accumulatedLighting += calculateSun(light,
                                            normal,
                                            cameraUniforms.position,
                                            material);
        break;
      }
      case Point: {
        accumulatedLighting += calculatePoint(light, position, normal, material);
        break;
      }
      case Spot: {
        accumulatedLighting += 0;
        break;
      }
      case Ambient: {
        accumulatedLighting += 0;
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
