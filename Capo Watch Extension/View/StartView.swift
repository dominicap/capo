//
//  StartView.swift
//  Capo Watch Extension
//
//  Created by Dominic Philip on 4/20/22.
//

import SwiftUI

struct StartView: View {
  @EnvironmentObject var workoutManager: WorkoutManager

  var body: some View {
    VStack {
      Text("Cadence (SPM): \(workoutManager.cadence)")
      Spacer()
      ScrollView {
        Button("Start") {
          workoutManager.start()
        }
        Button("Pause") {
          workoutManager.pause()
        }
        Button("Resume") {
          workoutManager.resume()
        }
        Button("Stop") {
          workoutManager.stop()
        }
      }
    }
  }
}

struct StartView_Previews: PreviewProvider {
  static var previews: some View {
    StartView()
  }
}
