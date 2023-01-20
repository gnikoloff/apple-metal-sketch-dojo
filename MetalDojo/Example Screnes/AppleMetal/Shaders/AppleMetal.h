//
//  AppleMetal.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 19.01.23.
//

#ifndef AppleMetal_h
#define AppleMetal_h

#import <simd/simd.h>
#import "../../../Shared/Common.h"

typedef struct {
  vector_float3 position;
  vector_float3 position1;
  vector_float3 position2;
  vector_float3 prevPosition;
  vector_float3 velocity;
  vector_float3 rotateAxis;
  float scale;
} AppleMetal_MeshInstance;

typedef struct {
  float mode;
  float wordMode;
} AppleMetal_AnimSettings;

typedef enum {
  InstancesBuffer = 13,
  AnimationSettingsBuffer = 14
} AppleMetal_BufferIndices;

#endif /* AppleMetal_h */
