//
//  CascadedShadowsMap_ArgumentBuffers.h
//  MetalDojo
//
//  Created by Georgi Nikoloff on 10.02.23.
//

#ifndef CascadedShadowsMap_ArgumentBuffers_h
#define CascadedShadowsMap_ArgumentBuffers_h

struct CascadedShadowMap_DrawArgBuffer {
  Uniforms uniforms [[id(0)]];
  CameraUniforms camera [[id(1)]];
  CameraUniforms debugCamera [[id(2)]];
  float4x4 lightMatrices[4] [[id(3)]];
  float4x4 cubeInstances[60] [[id(4)]];
  CascadedShadowsMap_Settings settings [[id(5)]];
  Material material [[id(6)]];
  Light lights[2] [[id(7)]];
  depth2d_array<float> shadowDepthTexture;
  texture2d<float> camDebugTexture;
};

#endif /* CascadedShadowsMap_ArgumentBuffers_h */
