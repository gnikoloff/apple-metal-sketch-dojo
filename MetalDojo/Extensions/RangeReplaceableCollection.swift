//
//  RangeReplaceableCollection.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 29.12.22.
//

import Foundation

extension RangeReplaceableCollection where Indices: Equatable {
  mutating func rearrange(from: Index, to: Index) {
//    precondition(from != to && indices.contains(from) && indices.contains(to), "invalid indices")
    insert(remove(at: from), at: to)
  }
}
