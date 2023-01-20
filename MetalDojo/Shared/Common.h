//
//  Common.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>

typedef struct {
  matrix_float4x4 viewMatrix;
  matrix_float4x4 projectionMatrix;
  vector_float3 position;
  float time;
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
  BitangentBuffer = 4,

  LightBuffer = 10,
  UniformsBuffer = 11,
  CameraUniformsBuffer = 12,
} BufferIndices;

typedef enum {
  unused = 0,
  Sun = 1,
  Spot = 2,
  Point = 3,
  Ambient = 4
} LightType;

typedef struct {
  vector_float3 position;
  vector_float3 color;
  vector_float3 specularColor;
  float attenuation;
  LightType type;
  float speed;
  vector_float3 prevPosition;
  vector_float3 velocity;
} Light;

typedef struct {
  float shininess;
  float baseColor;
  float specularColor;
} Material;

#endif /* Common_h */
