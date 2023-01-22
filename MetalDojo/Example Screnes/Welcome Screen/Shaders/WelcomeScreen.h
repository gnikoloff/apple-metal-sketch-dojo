//
//  WelcomeScreen.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 04.01.23.
//

#ifndef WelcomeScreen_h
#define WelcomeScreen_h
#import <simd/simd.h>
#import "../../../Shared/Common.h"

typedef enum {
  ProjectTexture = 1
} WelcomeScreen_Textures;

typedef enum {
  FragmentSettingsBuffer = 13
} WelcomeScreen_BufferIndices;

typedef struct {
  vector_float2 surfaceSize;
} WelcomeScreen_FragmentSettings;

#endif /* WelcomeScreen_h */
