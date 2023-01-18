//
//  Lighting.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 17.01.23.
//

#ifndef Lighting_h
#define Lighting_h

#import <simd/simd.h>
#import "../../../Shared/Common.h"

float3 phongLighting(float3 normal,
                     float3 position,
                     constant CameraUniforms &cameraUniforms,
                     constant InfiniteSpace_Light *lights,
                     InfiniteSpace_CubeMaterial material);

float3 calculateSun(InfiniteSpace_Light light,
                    float3 normal,
                    float3 cameraPosition,
                    InfiniteSpace_CubeMaterial material);

float3 calculatePoint(InfiniteSpace_Light light,
                      float3 position,
                      float3 normal,
                      InfiniteSpace_CubeMaterial material);

float3 calculateFog(float3 position,
                    float3 color);

//float3 calculateSpot(
//  Light light,
//  float3 position,
//  float3 normal,
//  Material material);
//
//float calculateShadow(
//  float4 shadowPosition,
//  depth2d<float> shadowTexture);

#endif /* Lighting_h */
