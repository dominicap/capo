//
//  CapoApp.swift
//  Capo
//
//  Created by Dominic Philip on 3/25/22.
//

import SwiftUI

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

  var body: some Scene {
    WindowGroup {
      AuthenticationView()
        .environmentObject(spotify)
    }
  }
}
