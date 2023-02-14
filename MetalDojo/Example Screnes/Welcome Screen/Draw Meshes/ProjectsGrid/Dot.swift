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
  var targetPosPhysics: float2
  var oldPos: float2
  var expandPos: float2 = .zero

  var gravity = float2(0, 4)
  var friction = float2(repeating: 0.999)
  var groundFriction = Float(0.7)
  var mass = Float(1)

  var physicsMixFactor: Float = 1

  init(pos: float2, vel: float2 = float2(x: 0, y: 0)) {
    self.pos = pos
    targetPosPhysics = pos
    oldPos = pos + vel
  }
}

extension Dot {
  func update(size: CGSize, dt: Float) {
    let h = Float(size.height)
    var vel = (targetPosPhysics - oldPos) * friction
    oldPos = targetPosPhysics
    let magSq = targetPosPhysics.magSq()
    //    if pos.y >= h && magSq > 0.000001 {
    //      let m = sqrtf(pos.x * pos.x + pos.y * pos.y)
    //      vel.x /= m
    //      vel.y /= m
    //      vel *= (m * friction)
    //    }
    targetPosPhysics += vel
    targetPosPhysics += gravity

    pos += mix(float2.zero, (targetPosPhysics - pos) * 0.2, t: physicsMixFactor)
    pos += mix(float2.zero, (expandPos - pos) * 0.2, t: 1 - physicsMixFactor)
  }

  func interactMouse(mousePos: CGPoint) {
    let mousePos = mousePos * (1 + (1 - WelcomeScreen.cameraZoom))
    let delta = targetPosPhysics - mousePos
    let dist = delta.magSq()
    let magr: Float = 200 * 200 * (1 + (1 - WelcomeScreen.cameraZoom))
    if dist < magr {
      targetPosPhysics += (float2(Float(mousePos.x), Float(mousePos.y)) - targetPosPhysics) * 0.6
//      let f = delta.normalizeTo(length: 1 - (dist / magr)) * 100 * (1 + (1 - WelcomeScreen.cameraZoom))
//      targetPosPhysics += f
    }
  }

  func constrain(size: CGSize) {
    let fwidth = Float(size.width)
    let fheight = Float(size.height)
    let w = fwidth * (1 + (1 - WelcomeScreen.cameraZoom))
    let h = fheight * (1 + (1 - WelcomeScreen.cameraZoom))
    let l: Float = 0 // -fwidth * (1 - WelcomeScreen.cameraZoom)
    let t: Float = 0 // -fheight * (1 - WelcomeScreen.cameraZoom)

    if w == 0 || h == 0 {
      return
    }
    let bounce: Float = 0.9
//
    if targetPosPhysics.x > w {
      let velX = (targetPosPhysics.x - oldPos.x) * bounce
      targetPosPhysics.x = w
      oldPos.x = targetPosPhysics.x + velX
    }
    if targetPosPhysics.x < l {
      let velX = (targetPosPhysics.x - oldPos.x) * bounce
      targetPosPhysics.x = l
      oldPos.x = targetPosPhysics.x + velX
    }

    if targetPosPhysics.y > h {
      let velY = (targetPosPhysics.y - oldPos.y) * bounce
      targetPosPhysics.y = h
      oldPos.y = targetPosPhysics.y + velY
    }
    if targetPosPhysics.y < t {
      let velY = (targetPosPhysics.y - oldPos.y) * bounce
      targetPosPhysics.y = t
      oldPos.y = targetPosPhysics.y + velY
    }
  }
}
