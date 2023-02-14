//
//  Options.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import Foundation

class Options: ObservableObject {
  @Published var activeProjectName: String?
  @Published var projects = [
    ProjectModel(name: "Georgi"),
    ProjectModel(name: "Nikolov"),
    ProjectModel(name: "Whatever")
  ]
  var drawableSize: CGSize = .zero

  var isProjectTransition = false
  var mouse: CGPoint = CGPoint(x: -2000, y: -2000)
  var pinchFactor: CGFloat = CGFloat(1)

  var mouseDown: Bool = false

}
