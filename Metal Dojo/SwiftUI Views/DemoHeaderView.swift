//
//  DemoHeaderVIEW.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 15.02.23.
//

import SwiftUI

struct DemoHeaderView: View {
  var activeProjectName: String

  @Binding var isDemoInfoOpen: Bool
  @Binding var gameController: GameController?
  @EnvironmentObject var options: Options

  var body: some View {
    Group {
      ZStack {
        VStack {
          HStack {
            Button(
              action: {
                if let gameController = gameController {
                  gameController.dismissSingleProject()
                }
              },
              label: {
                Text("Back")
                  .padding(24)
              }
            )
            Spacer()
            Button(
              action: {
                withAnimation {
                  isDemoInfoOpen = true
                }
              },
              label: {
                Text("Demo Info")
                  .padding(24)
              }
            )
          }
          .padding()
          Spacer()
        }
      }
      VStack {
        HStack {
          Spacer()
          Text(activeProjectName)
            .padding(24)
            .foregroundColor(.white)
          Spacer()
        }
        .padding()
        Spacer()
      }
    }
      .opacity(isDemoInfoOpen ? 0 : 1)
  }
}
