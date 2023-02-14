//
//  VerletGrid.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 14.02.23.
//

// swiftlint:disable identifier_name

import MetalKit

class VerletGrid {
  private static let VERLET_ITERATIONS_COUNT = 5

  var dots: [Dot] = []
  var sticks: [Stick] = []

  var panels: [Panel] = []
  var sortedPanels: [Panel] = []

  var options: Options
  var totalWidth: Float
  var totalHeight: Float
  var colWidth: Float
  var rowHeight: Float

  init(options: Options, colWidth: Float, rowHeight: Float, totalWidth: Float, totalHeight: Float) {
    self.options = options
    self.colWidth = colWidth
    self.rowHeight = rowHeight
    self.totalWidth = totalWidth
    self.totalHeight = totalHeight
  }

  func draw(
    encoder: MTLRenderCommandEncoder,
    cameraUniforms: CameraUniforms
  ) {
    for panel in sortedPanels {
      panel.draw(
        encoder: encoder,
        cameraUniforms: cameraUniforms
      )
    }
  }

  func updateVerlet(deltaTime: Float) {
    let allowInteractionWithVertices = !options.isProjectTransition && options.activeProjectName == nil

    for d in dots {
      if allowInteractionWithVertices {
        d.interactMouse(mousePos: options.mouse)
      }
      d.update(
        size: options.drawableSize,
        dt: deltaTime
      )
    }

    for _ in 0 ..< Self.VERLET_ITERATIONS_COUNT {
      for s in sticks {
        s.update()
      }
      for d in dots {
        d.constrain(size: options.drawableSize)
      }
    }

    for panel in panels {
      panel.updateInterleavedArray()
    }
  }

  func makeHorizontalLayout(colsCount: Int) {
    let size = options.drawableSize
    let screenWidth = Float(size.width)
    let screenHeight = Float(size.height)
    let rotMatrix = float4x4(rotationZ: .pi / 4)
    for x in 0 ..< colsCount {
      let fx = Float(x)
      let realx = fx * colWidth - totalWidth / 2 + screenWidth / 2
      let pos0 = rotMatrix * float4(
        x: realx,
        y: -rowHeight / 2 + screenHeight / 2,
        z: 0,
        w: 1
      )
      let pos1 = rotMatrix * float4(
        x: realx,
        y: rowHeight / 2 + screenHeight / 2,
        z: 0,
        w: 1
      )
      dots.append(Dot(pos: float2(x: pos0.x, y: pos0.y)))
      dots.append(Dot(pos: float2(x: pos1.x, y: pos1.y)))
      sticks.append(Stick(
        startPoint: dots[dots.count - 1],
        endPoint: dots[dots.count - 2]
      ))
      if x > 0 {
        sticks.append(Stick(
          startPoint: dots[dots.count - 3],
          endPoint: dots[dots.count - 2]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 4],
          endPoint: dots[dots.count - 1]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 1],
          endPoint: dots[dots.count - 3]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 2],
          endPoint: dots[dots.count - 4]
        ))
      }
    }
  }

  func makeVerticalLayout(rowsCount: Int, offset: float2 = float2(0, 0)) {
    let size = options.drawableSize
    let screenWidth = Float(size.width)
    let screenHeight = Float(size.height)
    for y in 0 ..< rowsCount {
      let realy = Float(y) * rowHeight - totalHeight / 2 + screenHeight / 2
      dots.append(Dot(pos: float2(-colWidth / 2 + screenWidth / 2, realy) + offset))
      dots.append(Dot(pos: float2(colWidth / 2 + screenWidth / 2, realy) + offset))
      sticks.append(Stick(
        startPoint: dots[dots.count - 1],
        endPoint: dots[dots.count - 2]
      ))
      if y > 0 {
        sticks.append(Stick(
          startPoint: dots[dots.count - 3],
          endPoint: dots[dots.count - 2]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 4],
          endPoint: dots[dots.count - 1]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 1],
          endPoint: dots[dots.count - 3]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 2],
          endPoint: dots[dots.count - 4]
        ))
      }
    }
  }
}
