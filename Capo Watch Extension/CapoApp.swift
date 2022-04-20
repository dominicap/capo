//
//  CapoApp.swift
//  Capo Watch Extension
//
//  Created by Dominic Philip on 3/25/22.
//

import SwiftUI
import WatchKit

@main
struct CapoApp: App {
  @StateObject var spotify = Spotify(
    clientId: "051fa037942742438df1e85c2793f69b",
    scopes: [
      .userReadPlaybackState,
      .userModifyPlaybackState,
      .userReadCurrentlyPlaying,
      .userTopRead,
      .playlistModifyPublic,
      .playlistModifyPrivate,
    ])

  @StateObject var workoutManager = WorkoutManager()

  @SceneBuilder var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
      .environmentObject(spotify)
      .environmentObject(workoutManager)
    }

    WKNotificationScene(controller: NotificationController.self, category: "myCategory")
  }
}
