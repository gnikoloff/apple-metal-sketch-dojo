//
//  CGPointExtension.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 28.12.22.
//

// swiftlint:disable identifier_name

import Foundation

extension CGPoint {
  func isInsidePolygon(vertices: [CGPoint]) -> Bool {
    guard !vertices.isEmpty else {
      return false      
    }
    var j = vertices.last!
    var c = false
    for i in vertices {
      let a = (i.y > y) != (j.y > y)
      let b = (x < (j.x - i.x) * (y - i.y) / (j.y - i.y) + i.x)
      if a && b {
        c = true
      }
      j = i
    }
    return c
  }
  static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }
  static func += (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }
}
