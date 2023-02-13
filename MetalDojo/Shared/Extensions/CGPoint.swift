//
//  CGPointExtension.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 28.12.22.
//

// swiftlint:disable identifier_name

import Foundation
import UIKit

extension CGPoint {
  func isInsidePolygon(vertices: [CGPoint]) -> Bool {
    guard !vertices.isEmpty else {
      return false
    }
    let p = UIBezierPath()
    p.move(to: vertices[0])
    for vert in vertices {
      p.addLine(to: vert)
    }
    p.close()
    return p.contains(self)
  }
  static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }
  static func += (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }
}
