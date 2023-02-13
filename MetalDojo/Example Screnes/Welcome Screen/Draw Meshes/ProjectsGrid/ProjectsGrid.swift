//
//  Grid.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import Foundation
import simd
import MetalKit

class ProjectsGrid {
  static let VERLET_ITERATIONS_COUNT = 5

  var dots: [Dot] = []
  var sticks: [Stick] = []
  var panels: [Panel] = []
  var sortedPanels: [Panel] = []
  var options: Options

  var totalHeight: Float

  init(
    projects: [ProjectModel],
    colWidth: Float,
    rowHeight: Float,
    options: Options
  ) {
    let rowsCount = projects.count + 1
    self.totalHeight = Float(projects.count) * rowHeight
    self.options = options

    let screenWidth = Float(options.drawableSize.width)
    let screenHeight = Float(options.drawableSize.height)

    let size = options.drawableSize
    let floatWidth = Float(size.width)

    var i = 0

    for y in 0 ..< rowsCount {
      let realy = Float(y) * rowHeight - totalHeight / 2 + Float(options.drawableSize.height) / 2
      dots.append(Dot(pos: float2(-colWidth / 2 + floatWidth / 2, realy)))
      dots.append(Dot(pos: float2(colWidth / 2 + floatWidth / 2, realy)))
      i += 1
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

    for i in 0 ..< projects.count {
      let project = projects[i]
      let panel = Panel(
        size: float2(colWidth, rowHeight),
        dots: [
          dots[i * 2 + 0],
          dots[i * 2 + 1],
          dots[i * 2 + 3],
          dots[i * 2 + 2]
        ],
        project: project
      )
      panels.append(panel)
    }

    sortedPanels = panels
  }

  func updateVertices(deltaTime: Float) {
    let allowInteractionWithVertices = !options.isProjectTransition && options.activeProjectName == nil

    for i in 0 ..< panels.count {
      let p = panels[i]
      let vertices: [CGPoint] = p.dots.map { d in
        return CGPoint(x: CGFloat(d.pos.x), y: CGFloat(d.pos.y))
      }

      if allowInteractionWithVertices && options.mouseDown {
        let isIntersect = options.mouse.isInsidePolygon(vertices: vertices)
        if isIntersect {
          onProjectClicked(idx: i)
          return
        }
      }
    }

    for d in dots {
      if allowInteractionWithVertices {
        d.interactMouse(mousePos: options.mouse)
      }
      d.update(
        size: options.drawableSize,
        dt: deltaTime
      )
    }

    for _ in 0 ..< ProjectsGrid.VERLET_ITERATIONS_COUNT {
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

  func dismissSingleProject() {
    let p = panels.first { p in
      p.project.name == options.activeProjectName
    }!
    options.isProjectTransition = true

    for p in self.panels {
      p.beforeClose()
    }

    let tween = Tween(
      duration: 1,
      delay: 0,
      ease: .sineIn,
      onUpdate: { time in
        let factor = Float(time)
        p.collapse(factor: factor)
      },
      onComplete: {
        self.options.isProjectTransition = false
        self.options.activeProjectName = nil
        for p in self.panels {
          p.afterClose()
          p.zIndex = 0
        }
      }
    )
    tween.start()
  }

  func onProjectClicked(idx: Int) {
    let p = panels[idx]

    self.options.activeProjectName = p.project.name

//    panels.rearrange(from: idx, to: panels.count - 1)
    p.zIndex = 999
    sortedPanels = panels.sorted(by: { p0, p1 in
      p0.zIndex < p1.zIndex
    })

    let screenWidth = Float(options.drawableSize.width)
    let screenHeight = Float(options.drawableSize.height)

    for p in panels {
      p.beforeExpand()
    }

    options.isProjectTransition = true
    let tween = Tween(
      duration: 1,
      delay: 0,
      ease: .sineIn,
      onUpdate: { time in
        let factor = Float(time)
        p.expand(
          factor: factor,
          screenWidth: screenWidth,
          screenHeight: screenHeight
        )
      },
      onComplete: {
        self.options.isProjectTransition = true
        for p in self.panels {
          p.afterExpand()
        }
      }
    )
    tween.start()
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
}
