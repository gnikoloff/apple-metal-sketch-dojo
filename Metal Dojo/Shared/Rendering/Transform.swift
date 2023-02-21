//
//  Transform.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import Foundation
import simd

struct Transform {
  var position: float3 = [0, 0, 0]
  var rotation: float3 = [0, 0, 0]
  var scale: Float = 1
}

extension Transform {
  var modelMatrix: matrix_float4x4 {
    let translation = float4x4(translation: position)
    let rotation = float4x4(rotation: rotation)
    let scale = float4x4(scaling: scale)
    return translation * rotation * scale
  }
}

protocol Transformable {
  var transform: Transform { get set }
}

extension Transformable {
  var position: float3 {
    get { transform.position }
    set { transform.position = newValue }
  }
  var rotation: float3 {
    get { transform.rotation }
    set { transform.rotation = newValue }
  }
  var scale: Float {
    get { transform.scale }
    set { transform.scale = newValue }
  }
}
