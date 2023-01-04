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
  static let VERLET_ITERATIONS_COUNT = 100

  var dots: [Dot] = []
  var sticks: [Stick] = []
  var panels: [Panel] = []
  var options: Options

  var totalHeight: Float

  init(
    projects: [ProjectModel],
    colWidth: Float,
    rowHeight: Float,
    options: Options
  ) {
    let rowsCount = projects.count + 1
    self.totalHeight = Float(rowsCount) * rowHeight
    self.options = options

    for y in 0 ..< rowsCount {
      let realy = Float(y) * rowHeight
      dots.append(
        Dot(
          pos: float2(-colWidth / 2 + 1284 / 2, realy)
        )
      )
      dots.append(
        Dot(
          pos: float2(colWidth / 2 + 1284 / 2, realy)
        )
      )
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
  }

  func updateVertices() {
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
        }
      }
    }

    for _ in 0 ..< ProjectsGrid.VERLET_ITERATIONS_COUNT {
      for d in dots {
        d.constrain(size: options.drawableSize)
      }
      for s in sticks {
        s.update()
      }
    }
    for d in dots {
      if allowInteractionWithVertices {
        d.interactMouse(mousePos: options.mouse)
      }
      d.update(
        size: options.drawableSize,
        dt: options.dt
      )
    }
    for s in sticks {
      s.update()
    }

    for panel in panels {
      var panel = panel
      panel.updateInterleavedArray()
    }
  }

  func dismissSingleProject() {
    let p = panels.first { p in
      p.project.name == options.activeProjectName
    }!
    options.isProjectTransition = true
    let tween = Tween(
      duration: 1,
      delay: 0,
      ease: .sineIn,
      onUpdate: { time in
        let factor = Float(time)
        p.collapse(factor: factor)
        for s in self.sticks {
          s.stiffness += (0.0005 - s.stiffness) * Float(time)
        }
      },
      onComplete: {
        self.options.isProjectTransition = false
      }
    )
    tween.start()
  }

  func onProjectClicked(idx: Int) {
    let p = panels[idx]

    self.options.activeProjectName = p.project.name
    self.options.isProjectTransition = true

    panels.rearrange(from: idx, to: panels.count - 1)
    let screenWidth = Float(options.drawableSize.width)
    let screenHeight = Float(options.drawableSize.height)

    p.beforeExpand()
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
        for s in self.sticks {
          s.stiffness += (0 - s.stiffness) * factor
        }
      },
      onComplete: {
        self.options.isProjectTransition = false
      }
    )
    tween.start()
  }

  func draw(
    encoder: MTLRenderCommandEncoder,
    cameraUniforms: CameraUniforms
  ) {
    for panel in panels {
      panel.draw(
        encoder: encoder,
        cameraUniforms: cameraUniforms
      )
    }
  }
}
