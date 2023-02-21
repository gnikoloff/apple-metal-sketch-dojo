//
//  InfoOverlayView.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 16.02.23.
//

import SwiftUI

struct InfoOverlayView: View {
  @Binding var isInfoOverlayOpen: Bool
  @EnvironmentObject var options: Options

  var body: some View {
    ScrollView {
      VStack {
        HStack {
          Spacer()
          Button(action: {
            withAnimation {
              isInfoOverlayOpen = false
            }
          }) {
            Image(systemName: "xmark")
          }
          .foregroundColor(.black)
          .font(.system(size: 32))
          .padding(.bottom, 28)
        }
        Text(.init("""
        Code and animation developed by [Georgi Nikolov](https://www.georgi-nikolov.com/)

        Source code available on [Github](https://github.com/gnikoloff/metal-dojo)

        References:

        - [Metal By Tutorials](https://www.kodeco.com/books/metal-by-tutorials)
        - [Metal Shading Lang Spec](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
        - [30 days of Metal](https://medium.com/@warrenm/thirty-days-of-metal-day-1-devices-e371729d05ca)
        - [Swift UI Apprentice](https://www.kodeco.com/books/swiftui-apprentice)
        """))
      }
      .frame(maxWidth: 400)
      .padding(.top, 32)
      .padding(.trailing, options.hasTopNotch ? 1 : 24)
      .padding(.bottom, 32)
      .padding(.leading, options.hasTopNotch ? 1 : 24)
    }
    .foregroundColor(.black)
    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    .edgesIgnoringSafeArea(.all)
    .background(.white.opacity(0.95))
    .opacity(isInfoOverlayOpen ? 1 : 0)
  }
}
