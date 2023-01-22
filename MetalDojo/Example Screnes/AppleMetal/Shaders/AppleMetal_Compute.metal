//
//  AppleMetal_Compute.metal
//  MetalDojo
//
//  Created by Georgi Nikoloff on 19.01.23.
//

#include <metal_stdlib>
#import "./AppleMetal.h"
using namespace metal;

constant uint COMPUTE_UPDATE_ENTITIES_COUNT [[function_constant(0)]];
constant float ENTITY_RADIUS [[function_constant(1)]];
constant float3 GRAVITY [[function_constant(2)]];
constant float3 BOUNCE_FACTOR [[function_constant(3)]];
constant bool CHECK_ENTITIES_COLLISIONS [[function_constant(4)]];

constant float DAMPING = 1;

template <class T>
void checkCollision(device T &entity0, device T &entity1, bool ip) {
  float dx = entity0.position.x - entity1.position.x;
  float dy = entity0.position.y - entity1.position.y;
  float dz = entity0.position.z - entity1.position.z;
  float length = dx * dx + dy * dy + dz * dz;
  float dist = distance(entity0.position, entity1.position);
  float realDist = dist - ENTITY_RADIUS * 2;
  if (realDist < 0) {
    float velx1 = entity0.position.x - entity0.prevPosition.x;
    float vely1 = entity0.position.y - entity0.prevPosition.y;
    float velz1 = entity0.position.z - entity0.prevPosition.z;

    float velx2 = entity1.position.x - entity1.prevPosition.x;
    float vely2 = entity1.position.y - entity1.prevPosition.y;
    float velz2 = entity1.position.z - entity1.prevPosition.z;

    float depthX = dx * (realDist / dist);
    float depthY = dy * (realDist / dist);
    float depthZ = dz * (realDist / dist);

    entity0.position.x -= depthX * 0.5;
    entity0.position.y -= depthY * 0.5;
    entity0.position.z -= depthZ * 0.5;

    entity1.position.x += depthX * 0.5;
    entity1.position.y += depthY * 0.5;
    entity1.position.z += depthZ * 0.5;

    if (ip) {
      float pr1 = DAMPING * (dx * velx1 + dy * vely1 + dz * velz1) / length;
      float pr2 = DAMPING * (dx * velx2 + dy * vely2 + dz * velz2) / length;

      velx1 += pr2 * dx - pr1 * dx;
      velx2 += pr1 * dx - pr2 * dx;

      vely1 += pr2 * dy - pr1 * dy;
      vely2 += pr1 * dy - pr2 * dy;

      velz1 += pr2 * dz - pr1 * dz;
      velz2 += pr1 * dz - pr2 * dz;

      entity0.prevPosition.x = entity0.position.x - velx1;
      entity0.prevPosition.y = entity0.position.y - vely1;
      entity0.prevPosition.z = entity0.position.z - velz1;

      entity1.prevPosition.x = entity1.position.x - velx2;
      entity1.prevPosition.y = entity1.position.y - vely2;
      entity1.prevPosition.z = entity1.position.z - velz2;
    }
  }
}

template <class T>
void verlet(device T &entity) {
  float nx = (entity.position.x * 2) - entity.prevPosition.x;
  float ny = (entity.position.y * 2) - entity.prevPosition.y;
  float nz = (entity.position.z * 2) - entity.prevPosition.z;
  entity.prevPosition = entity.position;
  entity.position.x = nx;
  entity.position.y = ny;
  entity.position.z = nz;
}

template <class T>
void applyForce(device T &entity, float delta) {
  delta *= delta;
  entity.velocity += GRAVITY;
  entity.position += entity.velocity * delta;
}

template <class T>
void checkWall(device T &entity) {
  if (entity.position.x > 0.5) {
    float velX = entity.prevPosition.x - entity.position.x;
    entity.position.x = 0.5;
    entity.prevPosition.x = entity.position.x - velX * BOUNCE_FACTOR.x;
  }
  if (entity.position.x < -0.5) {
    float velX = entity.prevPosition.x - entity.position.x;
    entity.position.x = -0.5;
    entity.prevPosition.x = entity.position.x - velX * BOUNCE_FACTOR.x;
  }
  if (entity.position.y > 0.5) {
    float velY = entity.prevPosition.y - entity.position.y;
    entity.position.y = 0.5;
    entity.prevPosition.y = entity.position.y - velY * BOUNCE_FACTOR.y;
  }
  if (entity.position.y < -0.5) {
    float velY = entity.prevPosition.y - entity.position.y;
    entity.position.y = -0.5;
    entity.prevPosition.y = entity.position.y - velY * BOUNCE_FACTOR.y;
  }
  if (entity.position.z > 0.5) {
    float velZ = entity.prevPosition.z - entity.position.z;
    entity.position.z = 0.5;
    entity.prevPosition.z = entity.position.z - velZ * BOUNCE_FACTOR.z;
  }
  if (entity.position.z < -0.5) {
    float velZ = entity.prevPosition.z - entity.position.z;
    entity.position.z = -0.5;
    entity.prevPosition.z = entity.position.z - velZ * BOUNCE_FACTOR.z;
  }
}

kernel void appleMetal_updateLights(device Light *lights[[buffer(LightBuffer)]],
                                    uint id [[thread_position_in_grid]]) {
  device Light &light = lights[id];

  uint iterations = 6;
  float fixedDelta = 0.01 / float(iterations);

  while (iterations--) {
    applyForce(light, fixedDelta);
    verlet(light);
    checkWall(light);
    for (uint i = id + 1; i < COMPUTE_UPDATE_ENTITIES_COUNT; i++) {
      device Light &nextLight = lights[i];
      checkCollision(light, nextLight, false);
    }
    verlet(light);
    for (uint i = id + 1; i < COMPUTE_UPDATE_ENTITIES_COUNT; i++) {
      device Light &nextLight = lights[i];
      checkCollision(light, nextLight, true);
    }
  }
}

kernel void appleMetal_updatePoints(device AppleMetal_MeshInstance *instances[[buffer(InstancesBuffer)]],
                                    uint id [[thread_position_in_grid]]) {
  device AppleMetal_MeshInstance &instance = instances[id];


  float fixedDelta = 0.1 / 6;
  applyForce(instance, fixedDelta);
  verlet(instance);
  checkWall(instance);

//  if (CHECK_ENTITIES_COLLISIONS) {
//    uint iterations = 6;
//    float fixedDelta = 0.01 / float(iterations);
//    while (iterations--) {
//      applyForce(instance, fixedDelta);
//      verlet(instance);
//      checkWall(instance);
//      for (uint i = id + 1; i < COMPUTE_UPDATE_ENTITIES_COUNT; i++) {
//        device AppleMetal_MeshInstance &nextInstance = instances[i];
//        checkCollision(instance, nextInstance, false);
//      }
//    }
//  } else {
//    float fixedDelta = 0.1 / 6;
//    applyForce(instance, fixedDelta);
//    verlet(instance);
//    checkWall(instance);
//  }
}


