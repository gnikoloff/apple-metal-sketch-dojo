//
//  ExampleScene.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 02.01.23.
//

import MetalKit

protocol ExampleScene {
  var options: Options { get set }
  mutating func update(size: CGSize)
  mutating func update(deltaTime: Float)
}

extension ExampleScene {}
