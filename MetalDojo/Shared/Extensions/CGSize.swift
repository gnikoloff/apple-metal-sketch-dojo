//
//  CGSize.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 23.01.23.
//

import Foundation

extension CGSize {
  static func *= (lhs: CGSize, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
  }
  static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
  }
}
