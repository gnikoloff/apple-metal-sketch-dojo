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

  lazy private var vertexBuffer: MTLBuffer = {
    Renderer.device.makeBuffer(
      length: MemoryLayout<float2>.stride * 200
    )!
  }()

  init(options: Options, colWidth: Float, rowHeight: Float, totalWidth: Float, totalHeight: Float) {
    self.options = options
    self.colWidth = colWidth
    self.rowHeight = rowHeight
    self.totalWidth = totalWidth
    self.totalHeight = totalHeight
    self.surface = colWidth * rowHeight
  }

  func drawDebug(encoder: MTLRenderCommandEncoder, cameraUniforms: CameraUniforms) {
    for panel in panels {
      panel.drawDebugAABB(encoder: encoder, cameraUniforms: cameraUniforms)
    }
    encoder.setVertexBuffer(
      vertexBuffer,
      offset: 0,
      index: 0
    )
    encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: touchedPosCount)
    touchedPosCount = 0
  }

  func draw(encoder: MTLRenderCommandEncoder, cameraUniforms: CameraUniforms) {
    for panel in sortedPanels {
      panel.draw(encoder: encoder, cameraUniforms: cameraUniforms
      )
    }
  }

  func testCollisionWith(grid: VerletGrid) {
//    let buffPtr = vertexBuffer.contents().bindMemory(to: float2.self, capacity: 2)
//    for d in dots {
//      for p in grid.panels {
//        if d.isInside(polygon: p.dots) {
//          let nearestDotIdx0 = p.dots.firstIndex { dd in
//            dd.pos.dist(to: d.pos) < surface / 2
//          }!
//
//          let nextIdx = nearestDotIdx0 == p.dots.endIndex - 1 ? 0 : nearestDotIdx0 + 1
//          let prevIdx = nearestDotIdx0 == 0 ? p.dots.endIndex - 1 : nearestDotIdx0 - 1
//          let nextDist = p.dots[nextIdx].pos.dist(to: d.pos)
//          let prevDist = p.dots[prevIdx].pos.dist(to: d.pos)
//          let nearestDotIdx1 = nextDist < prevDist ? nextIdx : prevIdx
//
//          let nearestDot0 = p.dots[nearestDotIdx0]
//          let nearestDot1 = p.dots[nearestDotIdx1]
//
////          nearestDot1.pos = d.pos
////          nearestDot0.pos = d.pos
//
////          let dx = nearestDot0.pos.x - d.pos.x
////          let dy = nearestDot0.pos.y - d.pos.y
////
////          d.pos.x += dx / 2
////          d.pos.y += dy / 2
////
////          nearestDot0.pos.x -= dx / 2
////          nearestDot0.pos.y -= dy / 2
//
//          buffPtr[touchedPosCount * 2 + 0] = nearestDot0.pos
//          buffPtr[touchedPosCount * 2 + 1] = nearestDot1.pos
//          touchedPosCount += 1
//
//          break
//        }
//      }
//    }
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
