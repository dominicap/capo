//
//  CapoApp.swift
//  Capo Watch Extension
//
//  Created by Dominic Philip on 3/25/22.
//

import SwiftUI

@main
struct CapoApp: App {
  @SceneBuilder var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }

    WKNotificationScene(controller: NotificationController.self, category: "myCategory")
  }
}
