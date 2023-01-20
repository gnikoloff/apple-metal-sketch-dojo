//
//  InfiniteSpace_Shaders.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

#include <metal_stdlib>
#import "./InfiniteSpace.h"

using namespace metal;

kernel void InfiniteSpace_computeBoxes(device InfiniteSpace_ControlPoint *controlPoints [[buffer(ControlPointsBuffer)]],
                                       constant InfiniteSpace_BoidsSettings &boidsSettings [[buffer(BoidsSettingsBuffer)]],
                                       uint id [[thread_position_in_grid]]) {

  uint cubeIdx = id * boidsSettings.boxSegmentsCount;

  device InfiniteSpace_ControlPoint &firstPoint = controlPoints[cubeIdx];

  if (firstPoint.position.z < -5) {
    for (uint i = 0; i < boidsSettings.boxSegmentsCount; i++) {
      uint pointIdx = cubeIdx + i;
      device InfiniteSpace_ControlPoint &point = controlPoints[pointIdx];
      point.position.z = boidsSettings.worldSize.z;
    }
    return;
  }

  for (uint i = 0; i < boidsSettings.boxSegmentsCount; i++) {
    uint pointIdx = cubeIdx + i;
    device InfiniteSpace_ControlPoint &point = controlPoints[pointIdx];
    if (i == 0) {
      point.position.x = cos(point.position.z * 0.1 + pointIdx) * point.moveRadius[0];
      point.position.y = sin(point.position.z * 0.1 + pointIdx) * point.moveRadius[1];
      point.position.x += cos(point.position.z + pointIdx) * 0.1;
      point.position.y += sin(point.position.z + pointIdx) * 0.1;
      point.position.z += -point.zVelocityHead;
    } else {
      device InfiniteSpace_ControlPoint &currPoint = controlPoints[pointIdx];
      device InfiniteSpace_ControlPoint &prevPoint = controlPoints[pointIdx - 1];
      currPoint.position += (prevPoint.position - currPoint.position) * currPoint.zVelocityTail;
    }
  }
}

kernel void InfiniteSpace_computePointLights(device Light *lights [[buffer(LightBuffer)]],
                                             uint id [[thread_position_in_grid]]) {
  device Light &light = lights[id];
  light.position.z += light.speed;
  if (light.position.z > 40) {
    light.position.z = -2;
  }
}
