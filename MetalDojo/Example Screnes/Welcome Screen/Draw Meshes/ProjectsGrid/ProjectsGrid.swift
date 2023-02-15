//
//  Grid.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import MetalKit

class ProjectsGrid: VerletGrid {
  init(options: Options) {
    let screenWidth = Float(options.drawableSize.width)
    let screenHeight = Float(options.drawableSize.height)

    let fprojectsCount = Float(options.projects.count)

    let idealColWidth = screenWidth / fprojectsCount
    let colWidth = idealColWidth * 1
    let rowHeight = colWidth * (screenHeight / screenWidth)

    let totalWidth = fprojectsCount * colWidth
    let totalHeight = fprojectsCount * rowHeight

    super.init(
      options: options,
      colWidth: colWidth,
      rowHeight: rowHeight,
      totalWidth: totalWidth,
      totalHeight: totalHeight
    )

//    makeHorizontalLayout(colsCount: projects.count + 1)
    makeVerticalLayout(rowsCount: options.projects.count + 1, offset: float2(screenWidth / 2.8, 0))
    makePanels()
  }

  func makePanels() {
    for i in 0 ..< options.projects.count {
      let project = options.projects[i]
      let panel = Panel(
        width: colWidth,
        height: rowHeight,
        dots: [
          dots[i * 2 + 0],
          dots[i * 2 + 1],
          dots[i * 2 + 3],
          dots[i * 2 + 2]
        ],
        name: project.name
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

    super.updateVerlet(deltaTime: deltaTime)
  }

  func dismissSingleProject() {
    let p = panels.first { p in
      p.name == options.activeProjectName
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
    options.resetMousePos()

    let p = panels[idx]

    self.options.activeProjectName = p.name

    p.zIndex = 1
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
        self.options.isProjectTransition = false
        for p in self.panels {
          p.afterExpand()
        }
      }
    )
    tween.start()
  }
}
