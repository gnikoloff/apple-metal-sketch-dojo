//
//  Stick.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import Foundation

class Stick {
  var startPoint: Dot
  var endPoint: Dot
  var stiffness: Float
  var length: Float
  init(startPoint: Dot, endPoint: Dot) {
    self.startPoint = startPoint
    self.endPoint = endPoint
    self.stiffness = 0.0005
    self.length = startPoint.pos.dist(to: endPoint.pos)
  }
}

extension Stick {
  func update() {
    let dx = endPoint.pos.x - startPoint.pos.x
    let dy = endPoint.pos.y - startPoint.pos.y
    let dist = sqrt(dx * dx + dy * dy)
    let diff = (length - dist) / dist * stiffness
    
    var offset = float2(
      dx * diff * 0.5,
      dy * diff * 0.5
    )
    
    var m1 = startPoint.mass + endPoint.mass
    var m2 = startPoint.mass / m1
    m1 = endPoint.mass / m1
    
    startPoint.pos -= offset * m1
    endPoint.pos += offset * m2
    
    
//    this.startPoint.pos.x -= offsetx * m1;
//      this.startPoint.pos.y -= offsety * m1;
  }
}
