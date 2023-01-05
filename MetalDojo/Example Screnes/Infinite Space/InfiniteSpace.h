//
//  InfiniteSpace.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

#ifndef InfiniteSpace_h
#define InfiniteSpace_h

#import <simd/simd.h>
#import "../../Shared/Common.h"

typedef struct {
  vector_float3 position;
} InfiniteSpace_ControlPoint;

typedef enum {
  ControlPointsBuffer = 13
} InfiniteSpace_BufferIndices;

#endif /* InfiniteSpace_h */
