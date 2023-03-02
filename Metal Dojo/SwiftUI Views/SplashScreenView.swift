//
//  SplashScreenView.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 19.02.23.
//

import SwiftUI

struct SplashScreenView: View {
  var body: some View {
    ZStack {
      Color.white
        .ignoresSafeArea()
      VStack {
        Image("metalsketch-splash")
          .resizable()
          .scaledToFit()
          .frame(width: 250, height: 250)
        VStack {
          Text("Metal Sketch Dojo")
            .font(.title)
            .foregroundColor(.black)
        }
      }
    }
  }
}
