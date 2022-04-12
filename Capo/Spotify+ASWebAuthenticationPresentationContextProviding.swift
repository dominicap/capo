//
//  Spotify+ASWebAuthenticationPresentationContextProviding.swift
//  Capo
//
//  Created by Dominic Philip on 4/12/22.
//

import AuthenticationServices
import Foundation

extension Spotify: ASWebAuthenticationPresentationContextProviding {

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }

  func authorize() {
    let authorizationURL = self.api.authorizationManager.makeAuthorizationURL(
      redirectURI: Spotify.redirectURI, codeChallenge: Spotify.codeChallenge,
      state: Spotify.state,
      scopes: [
        .userReadPlaybackState, .userModifyPlaybackState, .userReadCurrentlyPlaying, .userTopRead,
        .playlistModifyPublic, .playlistModifyPrivate,
      ])!

    let authenticationSession = ASWebAuthenticationSession(
      url: authorizationURL, callbackURLScheme: Spotify.callbackURLScheme,
      completionHandler: { callbackURL, error in
        guard error == nil, let callbackURL = callbackURL else {
          return
        }

        self.api.authorizationManager.requestAccessAndRefreshTokens(
          redirectURIWithQuery: callbackURL, codeVerifier: Spotify.codeVerifier,
          state: Spotify.state
        )
        .sink(receiveCompletion: { completion in
          switch completion {
          case .finished:
            self.logger.log("User has successfully authorized their account.")
          case .failure:
            self.logger.log("User has denied authorization for their account.")
            return
          }
        })
        .store(in: &self.cancellables)
      })

    authenticationSession.presentationContextProvider = self
    authenticationSession.prefersEphemeralWebBrowserSession = true

    if authenticationSession.canStart {
      authenticationSession.start()
    }
  }

}
