//
//  Example.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 31.12.22.
//

import MetalKit

protocol ExampleScreen {
  mutating func resize(view: MTKView, size: CGSize)
  mutating func update(elapsedTime: Float, deltaTime: Float)
  mutating func draw(in view: MTKView, commandBuffer: MTLCommandBuffer)
}

extension ExampleScreen {
  static func buildDefaultLight() -> Light {
    var light = Light()
    light.position = [0, 0, 0]
    light.color = float3(repeating: 1.0)
    light.specularColor = float3(repeating: 0.6)
    light.attenuation = 1
    light.type = Sun
    return light
  }

  static func createLightBuffer(lights: [Light]) -> MTLBuffer {
    var lights = lights
    return Renderer.device.makeBuffer(
      bytes: &lights,
      length: MemoryLayout<Light>.stride * lights.count,
      options: []
    )!
  }
}
