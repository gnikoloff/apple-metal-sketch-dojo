//
//  DemoInfoView.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 15.02.23.
//

import SwiftUI

struct DemoInfoView: View {
  var activeProjectName: String

  @Binding var isDemoInfoOpen: Bool
  @EnvironmentObject var options: Options

  var body: some View {
    ZStack {
      VStack {
        Text(activeProjectName)
          .font(.title)
          .padding(.bottom)
        Text(.init(demosDescriptions[activeProjectName]!))
          .frame(maxWidth: 400)
      }
      VStack {
        HStack {
          Spacer()
          Button(action: {
            isDemoInfoOpen = false
          }) {
            Image(systemName: "xmark")
          }
          .foregroundColor(.white)
          .font(.system(size: 40))
          .padding(50)
        }
        Spacer()
      }
    }
    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    .edgesIgnoringSafeArea(.all)
    .background(.black.opacity(0.75))
  }
}
