//
//  Common.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>
#import "../Example Screnes/Welcome Screen/WelcomeScreen.h"
#import "../Example Screnes/Points Shadowmap/PointsShadowmap.h"

typedef struct {
  matrix_float4x4 viewMatrix;
  matrix_float4x4 projectionMatrix;
  vector_float3 position;
} CameraUniforms;

typedef struct {
  matrix_float4x4 modelMatrix;
} Uniforms;

typedef enum {
  Position = 0,
  UV = 1,
  Normal = 2,
  Color = 3,
  Tangent = 4,
  Bitangent = 5
} Attributes;

typedef enum {
  VertexBuffer = 0,
  UVBuffer = 1,
  ColorBuffer = 2,
  TangentBuffer = 3,
  BitangentBuffer = 4
} BufferIndices;

#endif /* Common_h */
