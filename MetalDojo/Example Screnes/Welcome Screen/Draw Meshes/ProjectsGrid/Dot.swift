//
//  Dot.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import Foundation

class Dot {
  var pos: float2
  var oldPos: float2
  var mainScreenOldPos: float2
  var targetPos: float2

  var gravity = float2(0, 0)
  var friction = float2(0.2, 0.2)
  var groundFriction = Float(0.7)
  var mass = Float(1)

  init(pos: float2, vel: float2 = float2(x: 0, y: 0)) {
    self.pos = pos
    oldPos = pos + vel
    mainScreenOldPos = pos
    targetPos = pos
  }
}

extension Dot {
  func cacheMainScreenPos() {
    mainScreenOldPos = pos
    oldPos = pos
  }
  func update(size: CGSize, dt: Float) {
    let h = Float(size.height)
    var vel = (pos - oldPos) * friction
    let magSq = pos.magSq()
    if pos.y >= h && magSq > 0.000001 {
      let m = sqrtf(pos.x * pos.x + pos.y * pos.y)
      vel.x /= m
      vel.y /= m
      vel *= (m * friction)
    }
    oldPos = pos
    pos += vel
    pos += gravity
    pos += (targetPos - pos) * dt * 10
  }

  func interactMouse(mousePos: CGPoint) {
    var delta = pos - float2(Float(mousePos.x), Float(mousePos.y))
    let dist = delta.magSq()
    let magr: Float = 1000 * 1000
    if dist < magr {
      let f = delta.normalizeTo(length: 1 - (dist / magr)) * 50
      pos += f
    }
  }

  func constrain(size: CGSize) {
    let w = Float(size.width)
    let h = Float(size.height)
    if w == 0 || h == 0 {
      return
    }
    if pos.x > w - 20 {
      pos.x = w - 20
    }
    if pos.x < 20 {
      pos.x = 20
    }
  }
}
