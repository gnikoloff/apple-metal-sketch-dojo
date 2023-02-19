//
//  VerletGrid.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 14.02.23.
//

// swiftlint:disable identifier_name

import MetalKit

class VerletGrid {
  static let VERLET_ITERATIONS_COUNT = 5

  var dots: [Dot] = []
  var sticks: [Stick] = []

  var panels: [Panel] = []
  var sortedPanels: [Panel] = []
  var touchedPosCount = 0

  var options: Options
  var totalWidth: Float
  var totalHeight: Float
  var colWidth: Float
  var rowHeight: Float
  var surface: Float
  var stechedOutUVs: Bool = false
  var flipPositions: Bool = false

  lazy private var vertexBuffer: MTLBuffer = {
    Renderer.device.makeBuffer(
      length: MemoryLayout<float2>.stride * 200
    )!
  }()

  init(
    options: Options,
    colWidth: Float,
    rowHeight: Float,
    totalWidth: Float,
    totalHeight: Float,
    stechedOutUVs: Bool = false,
    flipPositions: Bool = false
  ) {
    self.options = options
    self.colWidth = colWidth
    self.rowHeight = rowHeight
    self.totalWidth = totalWidth
    self.totalHeight = totalHeight
    self.stechedOutUVs = stechedOutUVs
    self.flipPositions = flipPositions
    self.surface = colWidth * rowHeight
  }

  func draw(encoder: MTLRenderCommandEncoder, cameraUniforms: CameraUniforms) {
    for panel in sortedPanels {
      panel.draw(encoder: encoder, cameraUniforms: cameraUniforms)
    }
  }

  func updateVerlet(deltaTime: Float) {
    let size = options.drawableSize.asCGSize()
    let allowInteractionWithVertices = !options.isProjectTransition && options.isHomescreen

    for d in dots {
      if allowInteractionWithVertices {
        let hasIntersect = d.interactMouse(mousePos: options.mouse)
        if hasIntersect {
          break
        }
      }
    }

    for d in dots {
      d.update(
        size: size,
        dt: deltaTime
      )
    }

    for _ in 0 ..< Self.VERLET_ITERATIONS_COUNT {
      for s in sticks {
        s.update()
      }
      for d in dots {
        d.constrain(size: size)
      }
    }

    for i in 0 ..< panels.count {
      let panel = panels[i]
      let uvStretchHeight = 1 / Float(panels.count)
      let fi = Float(i)

      panel.updateInterleavedArray(
        uvx: 0,
        uvy: stechedOutUVs ? uvStretchHeight * fi : 0,
        uvw: 1,
        uvh: stechedOutUVs ? uvStretchHeight * fi + uvStretchHeight : 1
      )
    }
  }

  func makeIphoneLayout(rowsCount: Int, offset: float2 = float2(0, 0)) {
    for y in 0 ..< rowsCount {
      let realy = Float(y) * rowHeight + offset.y
      dots.append(Dot(pos: float2(offset.x, realy)))
      dots.append(Dot(pos: float2(colWidth + offset.x, realy)))
      dots.append(Dot(pos: float2(colWidth * 2 + offset.x, realy)))

      sticks.append(Stick(
        startPoint: dots[dots.count - 1],
        endPoint: dots[dots.count - 2]
      ))
      sticks.append(Stick(
        startPoint: dots[dots.count - 2],
        endPoint: dots[dots.count - 3]
      ))
      if y > 0 {
        sticks.append(Stick(
          startPoint: dots[dots.count - 1],
          endPoint: dots[dots.count - 4]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 1],
          endPoint: dots[dots.count - 5]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 2],
          endPoint: dots[dots.count - 4]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 2],
          endPoint: dots[dots.count - 5]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 2],
          endPoint: dots[dots.count - 6]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 3],
          endPoint: dots[dots.count - 5]
        ))
        sticks.append(Stick(
          startPoint: dots[dots.count - 3],
          endPoint: dots[dots.count - 6]
        ))
      }
    }
  }

  func makeIpadLayout(rowsCount: Int, offset: float2 = float2(0, 0)) {
    let size = options.drawableSize
    for y in 0 ..< rowsCount {
      let realy = Float(y) * rowHeight - totalHeight / 2 + options.drawableSize.y / 2
      dots.append(Dot(pos: float2(-colWidth / 2 + options.drawableSize.x / 2, realy) + offset))
      dots.append(Dot(pos: float2(colWidth / 2 + options.drawableSize.x / 2, realy) + offset))
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
