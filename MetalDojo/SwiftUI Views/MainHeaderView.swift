//
//  MainHeaderView.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 16.02.23.
//

import SwiftUI

struct MainHeaderView: View {
  @Binding var isInfoOverlayOpen: Bool
  @EnvironmentObject var options: Options

  var body: some View {
    VStack {
      HStack {
        VStack {
          Text("Metal Sketch Dojo")
            .padding(.bottom, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(options.isIphone ? .title3 : .title )
          Text("Collection of demos using the Apple Metal API written in Swift and C++")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 1)
            .font(options.isIphone ? .subheadline : .body)
//          Text(.init("Made by [Georgi Nikolov](https://www.georgi-nikolov.com)"))
//            .contentShape(Rectangle())
//            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
//            .font(options.isIphone ? .subheadline : .body)
        }
        Spacer()
        Button(action: {
          withAnimation {
            isInfoOverlayOpen = true
          }
        }, label: {
          Text("Info")
        })
      }
      .foregroundColor(.black)
      .background(.white.opacity(0.01))
      .ignoresSafeArea(.all)
      .padding(.top, 24)
      .padding(.trailing, options.hasTopNotch ? 1 : 24)
      .padding(.bottom, 24)
      .padding(.leading, options.hasTopNotch ? 1 : 24)
      Spacer()
    }
    .opacity(options.activeProjectName == WelcomeScreen.SCREEN_NAME ? 1 : 0)
  }
}
