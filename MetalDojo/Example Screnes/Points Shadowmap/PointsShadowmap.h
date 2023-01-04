//
//  PointsShadowmap.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 03.01.23.
//

#ifndef PointsShadowmap_h
#define PointsShadowmap_h

#import <simd/simd.h>

//typedef struct {
//
//}

typedef enum {
  PointsShadowmap_CubeShadowTexture = 0
} PointsShadowmap_TextureIndices;

typedef struct {
  vector_float3 position;
} PointsShadowmap_Light;

typedef struct {
  matrix_float4x4 viewProjectionMatrix;
} PointsShadowmap_View;

#endif /* PointsShadowmap_h */
