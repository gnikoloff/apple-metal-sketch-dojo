//
//  PointsShadowmap.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 03.01.23.
//

#ifndef PointsShadowmap_h
#define PointsShadowmap_h

#import <simd/simd.h>
#import "../../../Shared/Shader/Common.h"

typedef enum {
  PointsShadowmap_CubeShadowTextures = 0
} PointsShadowmap_TextureIndices;

typedef struct {
  vector_float3 position;
  vector_float3 color;
  float cutoffDistance;
} PointsShadowmap_Light;

typedef struct {
  matrix_float4x4 viewProjectionMatrix;
} PointsShadowmap_View;

typedef enum {
  ShadowCameraUniformsBuffer = 14
} PointsShadowmap_BufferIndices;

#endif /* PointsShadowmap_h */
