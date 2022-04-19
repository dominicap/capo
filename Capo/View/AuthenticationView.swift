//
//  AuthenticationView.swift
//  Capo
//
//  Created by Dominic Philip on 3/25/22.
//

import SwiftUI
import WatchConnectivity

struct AuthenticationView: View {

  @EnvironmentObject var spotify: Spotify

  var body: some View {
    ZStack {
      VStack {
        Text("capo")
        Button {
          if !spotify.isAuthorized {
            spotify.authenticate()
          } else {
            spotify.deauthenticate()
          }
        } label: {
          if !spotify.isAuthorized {
            Text("Login to Spotify")
          } else {
            Text("Logout from Spotify")
          }
        }
      }
    }
  }
}

struct AuthenticationView_Previews: PreviewProvider {
  static var previews: some View {
    AuthenticationView()
  }
}
