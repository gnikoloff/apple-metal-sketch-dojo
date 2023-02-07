//
//  CascadedShadowsMap.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

#ifndef CascadedShadowsMap_h
#define CascadedShadowsMap_h

#import <simd/simd.h>
#import "../../../Shared/Shader/Common.h"

typedef enum {
  CubeInstancesBuffer = 14,
  SettingsBuffer = 15,
  LightsMatricesBuffer = 16,
  DebugCameraBuffer = 17
} CascadedShadowsMap_BufferIndices;

typedef enum {
  ShadowTextures = 0,
  CamDebugTexture = 1
} CascadedShadowsMap_TextureIndices;

typedef struct {
  uint cubesCount;
  uint cascadesCount;
  float cascadePlaneDistances[4];
  vector_float2 shadowTexSize;
} CascadedShadowsMap_Settings;

#endif /* CascadedShadowsMap_h */
