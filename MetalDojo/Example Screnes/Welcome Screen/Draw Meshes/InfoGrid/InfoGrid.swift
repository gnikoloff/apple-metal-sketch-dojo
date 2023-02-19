//
//  InfoGrid.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 14.02.23.
//

// swiftlint:disable identifier_name

import MetalKit

class InfoGrid: VerletGrid {

  let texture = try? TextureController.loadTexture(filename: "poster")

  init(options: Options) {
    let colWidth = options.drawableSize.x * 0.24
    let rowHeight = colWidth * (options.drawableSize.y / options.drawableSize.x) * 1.3

    let totalWidth = colWidth
    let totalHeight = 3 * rowHeight
    
    super.init(
      options: options,
      colWidth: colWidth,
      rowHeight: rowHeight,
      totalWidth: totalWidth,
      totalHeight: totalHeight,
      stechedOutUVs: true,
      flipPositions: false
    )

    makeIpadLayout(rowsCount: 4)
    makePanels()

  }

  func makePanels() {
    for i in 0 ..< 3 {
      let panel = Panel(
        width: colWidth,
        height: rowHeight,
        dots: [
          dots[i * 2 + 0],
          dots[i * 2 + 1],
          dots[i * 2 + 3],
          dots[i * 2 + 2]
        ],
        name: "Panel \(i)"
      )
      panels.append(panel)
    }
    sortedPanels = panels
  }

  override func draw(encoder: MTLRenderCommandEncoder, cameraUniforms: CameraUniforms) {
//    print("render")
    for panel in sortedPanels {
      panel.texture = texture
      panel.draw(encoder: encoder, cameraUniforms: cameraUniforms)
    }
  }

}
