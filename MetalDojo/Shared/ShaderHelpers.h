//
//  ShaderHelpers.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 19.01.23.
//

#ifndef ShaderHelpers_h
#define ShaderHelpers_h
#import <simd/simd.h>

float2 encodeNormals(float3 n);

float3 decodeNormals(float2 n);

matrix_float4x4 rotation3d(float3 axis, float angle);

#endif /* ShaderHelpers_h */
