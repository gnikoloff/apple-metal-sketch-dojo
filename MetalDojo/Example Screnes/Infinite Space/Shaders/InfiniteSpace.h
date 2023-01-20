//
//  InfiniteSpace.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

#ifndef InfiniteSpace_h
#define InfiniteSpace_h

#import <simd/simd.h>
#import "../../../Shared/Common.h"

typedef struct {
  vector_float3 position;
  vector_float2 moveRadius;
  float zVelocityHead;
  float zVelocityTail;
} InfiniteSpace_ControlPoint;

typedef enum {
  ControlPointsBuffer = 13,
  BoidsSettingsBuffer = 14,
  DeferredSettingsBuffer = 15,
  MaterialsBuffer = 17
} InfiniteSpace_BufferIndices;

typedef enum {
  RenderTargetNormal = 1,
  RenderTargetPosition = 2
} InfiniteSpace_RenderTargets;

typedef enum {
  NormalTexture = 1,
  DepthTexture = 2
} InfiniteSpace_Textures;

typedef struct {
  uint boxSegmentsCount;
  vector_float3 worldSize;
} InfiniteSpace_BoidsSettings;

typedef struct {
  matrix_float4x4 cameraProjectionInverse;
  matrix_float4x4 cameraViewInverse;
  vector_uint2 viewportSize;
} InfiniteSpace_DeferredSettings;

#endif /* InfiniteSpace_h */
