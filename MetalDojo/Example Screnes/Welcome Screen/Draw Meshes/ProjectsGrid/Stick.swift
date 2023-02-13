//
//  Stick.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import Foundation

class Stick {
  var startPoint: Dot
  var endPoint: Dot
  var stiffness: Float
  var length: Float

  init(startPoint: Dot, endPoint: Dot) {
    self.startPoint = startPoint
    self.endPoint = endPoint
    self.stiffness = 0.8
    self.length = startPoint.pos.dist(to: endPoint.pos)
  }
}

extension Stick {
  func update() {
    let dx = endPoint.targetPosPhysics.x - startPoint.targetPosPhysics.x
    let dy = endPoint.targetPosPhysics.y - startPoint.targetPosPhysics.y
    let dist = sqrt(dx * dx + dy * dy)
    let diff = (length - dist) / dist * stiffness

    let offset = float2(
      dx * diff * 0.5,
      dy * diff * 0.5
    )

    var m1 = startPoint.mass + endPoint.mass
    let m2 = startPoint.mass / m1
    m1 = endPoint.mass / m1

    startPoint.targetPosPhysics -= offset * m1
    endPoint.targetPosPhysics += offset * m2
  }
}
