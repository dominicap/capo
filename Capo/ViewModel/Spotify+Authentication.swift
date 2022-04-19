//
//  Spotify+Authentication.swift
//  Capo
//
//  Created by Dominic Philip on 4/12/22.
//

import AuthenticationServices
import Foundation

extension Spotify: ASWebAuthenticationPresentationContextProviding {

  func authenticate() {
    let authorizationURL = self.api.authorizationManager.makeAuthorizationURL(
      redirectURI: Spotify.redirectURI, codeChallenge: Spotify.codeChallenge, state: Spotify.state,
      scopes: self.scopes)

    guard let authorizationURL = authorizationURL else {
      return
    }

    let authenticationSession = ASWebAuthenticationSession(
      url: authorizationURL, callbackURLScheme: Spotify.callbackURLScheme
    ) { callbackURL, error in
      guard error == nil, let callbackURL = callbackURL else {
        return
      }

      self.api.authorizationManager.requestAccessAndRefreshTokens(
        redirectURIWithQuery: callbackURL, codeVerifier: Spotify.codeVerifier, state: Spotify.state
      )
      .sink { completion in
        switch completion {
        case .finished:
          self.logger.log("User successfully authenticated through Spotify.")
        case .failure:
          self.logger.log("Could not authenticate user through Spotify successfully.")
        }
      }
      .store(in: &self.cancellables)
    }

    authenticationSession.presentationContextProvider = self
    authenticationSession.prefersEphemeralWebBrowserSession = true

    if authenticationSession.canStart {
      authenticationSession.start()
    } else {
      self.logger.log("Authentication session could not start successfully.")
    }
  }

  func deauthenticate() {
    self.api.authorizationManager.deauthorize()
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }

}
