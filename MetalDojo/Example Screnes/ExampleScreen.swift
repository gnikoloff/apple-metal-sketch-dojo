//
//  Example.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 31.12.22.
//

import MetalKit

protocol ExampleScreen {
  mutating func resize(view: MTKView, size: CGSize)
  mutating func updateUniforms()
  mutating func update(deltaTime: Float)
  mutating func draw(in view: MTKView, commandBuffer: MTLCommandBuffer)
}

extension ExampleScreen {}
