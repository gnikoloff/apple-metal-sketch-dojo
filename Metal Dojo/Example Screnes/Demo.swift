//
//  Example.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 31.12.22.
//

// swiftlint:disable identifier_name

import MetalKit

protocol Demo: PipelineStates {
  static var SCREEN_NAME: String { get }
  var options: Options { get set }
  var outputTexture: MTLTexture! { get set }
  var outputDepthTexture: MTLTexture! { get set }
  var outputPassDescriptor: MTLRenderPassDescriptor { get set }
  func isActive() -> Bool
  func resize(view: MTKView)
  func update(elapsedTime: Float, deltaTime: Float)
  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer)
}

extension Demo {
  func isActive() -> Bool {
    return Self.SCREEN_NAME == options.activeProjectName
  }

  static func createParamsBuffer(lightsCount: UInt32 = 1, worldSize: float3 = [1, 1, 1]) -> MTLBuffer {
    var params = Params(lightsCount: lightsCount, worldSize: worldSize)
    return Renderer.device.makeBuffer(bytes: &params, length: MemoryLayout<Params>.stride)!
  }

  static func createOutputTexture(size: CGSize, label: String) -> MTLTexture {
    return TextureController.makeTexture(
      size: size,
      pixelFormat: Renderer.colorPixelFormat,
      label: label,
      storageMode: .private
    )!
  }
  static func createDepthOutputTexture(size: CGSize) -> MTLTexture {
    return TextureController.makeTexture(
      size: size,
      pixelFormat: .depth16Unorm,
      label: "Output depth texture"
    )!
  }

  static func buildDefaultLight() -> Light {
    var light = Light()
    light.position = [0, 0, 0]
    light.color = float3(repeating: 1.0)
    light.specularColor = float3(repeating: 0.6)
    light.attenuation = [1, 0, 0]
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
