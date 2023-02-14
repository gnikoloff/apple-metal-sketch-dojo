//
//  InfoGrid.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 14.02.23.
//

// swiftlint:disable identifier_name

import MetalKit

class InfoGrid: VerletGrid {
  init(options: Options) {
    let screenWidth = Float(options.drawableSize.width)
    let screenHeight = Float(options.drawableSize.height)
    let idealColWidth = screenWidth / 3
    let colWidth = idealColWidth * 0.8
    let rowHeight = colWidth * (screenHeight / screenWidth)

    let totalWidth = 3 * colWidth
    let totalHeight = 3 * rowHeight
    super.init(
      options: options,
      colWidth: colWidth,
      rowHeight: rowHeight,
      totalWidth: totalWidth,
      totalHeight: totalHeight
    )

    makeVerticalLayout(rowsCount: 4)
    makePanels()
  }
  func makePanels() {
    for i in 0 ..< 3 {
      let panel = Panel(
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
}
