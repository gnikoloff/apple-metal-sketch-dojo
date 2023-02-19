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
    let fprojectsCount = Float(options.projects.count)

    let idealColWidth = options.drawableSize.x * 0.4
    let colWidth = idealColWidth * 1
    let rowHeight = colWidth * (options.drawableSize.y / options.drawableSize.x)

    let totalWidth = colWidth * 2
    let totalHeight = fprojectsCount * rowHeight

    super.init(
      options: options,
      colWidth: colWidth,
      rowHeight: rowHeight,
      totalWidth: totalWidth,
      totalHeight: totalHeight,
      flipPositions: true //options.isIphone
    )

    makeIphoneLayout(rowsCount: 3, offset: float2(100, 30))
    makePanels()
  }

  func makePanels() {
    let dotsLayoutIphone: [[Dot]] = [
      [dots[0], dots[1], dots[3], dots[4]],
      [dots[1], dots[2], dots[4], dots[5]],
      [dots[3], dots[4], dots[6], dots[7]],
      [dots[4], dots[5], dots[7], dots[8]]
    ]
    for i in 0 ..< options.projects.count {
      let project = options.projects[i]
      let dotLayout = dotsLayoutIphone[i]
      
//      var dotLayout: [Dot]
//      if options.isIphone {
//        dotLayout = dotsLayoutIphone[i]
//      } else {
//        dotLayout = [
//          dots[i * 2 + 0],
//          dots[i * 2 + 1],
//          dots[i * 2 + 3],
//          dots[i * 2 + 2]
//        ]
//      }

      let panel = Panel(
        width: colWidth,
        height: rowHeight,
        dots: dotLayout,
        name: project.name
      )
      panels.append(panel)
    }
    sortedPanels = panels
  }

  func updateVertices(deltaTime: Float) {
    let screenWidth = Float()

    let allowInteractionWithVertices = !options.isProjectTransition && options.isHomescreen

    for i in 0 ..< panels.count {
      let p = panels[i]
      if allowInteractionWithVertices && options.mouseDown {
        var invMouse = options.mouse
        let isIntersect = invMouse.isInside(polygon: p.polygon)
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
    self.options.activeProjectName = WelcomeScreen.SCREEN_NAME

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

    p.zIndex = 1
    sortedPanels = panels.sorted(by: { p0, p1 in
      p0.zIndex < p1.zIndex
    })

    for p in panels {
      p.beforeExpand(
        screenWidth: options.drawableSize.x,
        screenHeight: options.drawableSize.y
      )
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
          screenWidth: self.options.drawableSize.x,
          screenHeight: self.options.drawableSize.y
        )
      },
      onComplete: {
        self.options.isProjectTransition = false
        self.options.activeProjectName = p.name
        for p in self.panels {
          p.afterExpand()
        }
      }
    )
    tween.start()

    options.resetMousePos()
  }
}
