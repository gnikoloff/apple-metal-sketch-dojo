//
//  Grid.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

// swiftlint:disable identifier_name

import MetalKit

class ProjectsGrid: VerletGrid {
  lazy private var ctrlPointsBuffer: MTLBuffer = {
    Renderer.device.makeBuffer(length: MemoryLayout<float2>.stride * 9)!
  }()

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
    let allowInteractionWithVertices = !options.isProjectTransition && options.isHomescreen

    for i in 0 ..< panels.count {
      let p = panels[i]
      if allowInteractionWithVertices && options.mouseDown {
        let isIntersect = options.mouse.isInside(polygon: p.polygon)
        if isIntersect {
          onProjectClicked(idx: i)
          break
        }
      }
    }

    super.updateVerlet(deltaTime: deltaTime)

    let ctrlPointsBufferPtr = ctrlPointsBuffer
      .contents()
      .bindMemory(to: float2.self, capacity: 9)

    ctrlPointsBufferPtr[0] = dots[0].pos
    ctrlPointsBufferPtr[1] = dots[1].pos
    ctrlPointsBufferPtr[2] = dots[2].pos
    ctrlPointsBufferPtr[3] = dots[3].pos
    ctrlPointsBufferPtr[4] = dots[4].pos
    ctrlPointsBufferPtr[5] = dots[5].pos
    ctrlPointsBufferPtr[6] = dots[6].pos
    ctrlPointsBufferPtr[7] = dots[7].pos
    ctrlPointsBufferPtr[8] = dots[8].pos
//    ctrlPointsBufferPtr[1] = dots[1].pos

//    ctrlPointsBufferPtr[1].x = dots[1].pos.x
//    ctrlPointsBufferPtr[1].y = dots[1].pos.y
//
//    ctrlPointsBufferPtr[2].x = dots[2].pos.x
//    ctrlPointsBufferPtr[2].y = dots[3].pos.y

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

    options.activeProjectName = p.name
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
        for p in self.panels {
          p.afterExpand()
        }
      }
    )
    tween.start()

    options.resetMousePos()
  }

  func drawCtrlPoints(encoder: MTLRenderCommandEncoder, camUniforms: CameraUniforms) {
    var camUniforms = camUniforms
    encoder.setVertexBytes(
      &camUniforms,
      length: MemoryLayout<CameraUniforms>.stride,
      index: UniformsBuffer.index + 1
    )
    encoder.setVertexBuffer(
      ctrlPointsBuffer,
      offset: 0,
      index: UniformsBuffer.index + 2
    )
    encoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: 6,
      instanceCount: 9
    )
  }
}
