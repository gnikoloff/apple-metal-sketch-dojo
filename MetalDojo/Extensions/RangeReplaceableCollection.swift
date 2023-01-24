//
//  RangeReplaceableCollection.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 29.12.22.
//

// swiftlint:disable identifier_name

import Foundation

extension RangeReplaceableCollection where Indices: Equatable {
  mutating func rearrange(from: Index, to: Index) {
    insert(remove(at: from), at: to)
  }
}
