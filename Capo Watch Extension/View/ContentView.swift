//
//  ContentView.swift
//  Capo Watch Extension
//
//  Created by Dominic Philip on 4/19/22.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var spotify: Spotify

  var body: some View {
    if spotify.isAuthorized {
      StartView()
    } else {
      AuthenticationView()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
