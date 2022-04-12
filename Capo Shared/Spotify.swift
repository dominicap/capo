//
//  Spotify.swift
//  Capo Shared
//
//  Created by Dominic Philip on 4/12/22.
//

import Combine
import Foundation
import SpotifyWebAPI
import os.log

final class Spotify: NSObject, ObservableObject {

  let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Spotify")

  private static let clientID = "051fa037942742438df1e85c2793f69b"
  private static let clientSecret = "2c7ef4b2bb144df6abf731e09875b07a"

  static let callbackURLScheme = "capo"
  static let redirectURI = URL(string: "\(callbackURLScheme)://callback")!

  static var codeVerifier = String.randomURLSafe(length: 128)
  static var codeChallenge = String.makeCodeChallenge(codeVerifier: codeVerifier)

  static var state = String.randomURLSafe(length: 128)

  private let keychain = Keychain<AuthorizationCodeFlowPKCEManager>(
    server: SpotifyWebAPI.Endpoints.accountsBase)

  let api = SpotifyAPI(authorizationManager: AuthorizationCodeFlowPKCEManager(clientId: clientID))

  var cancellables: Set<AnyCancellable> = []

  @Published var isAuthorized = false

  override init() {
    super.init()

    self.api.authorizationManagerDidChange
      .receive(on: RunLoop.main)
      .sink(receiveValue: authorizationManagerDidChange)
      .store(in: &cancellables)

    self.api.authorizationManagerDidDeauthorize
      .receive(on: RunLoop.main)
      .sink(receiveValue: authorizationManagerDidDeauthorize)
      .store(in: &cancellables)

    do {
      if let authorizationManager = try keychain.retrieve() {
        self.api.authorizationManager = authorizationManager
        self.isAuthorized = true
        print("foo")
      }
    } catch {
      logger.log("Could not find Spotify Authorization Manager in Keychain.")
    }
  }

  func authorizationManagerDidChange() {
    self.isAuthorized = self.api.authorizationManager.isAuthorized()

    do {
      try keychain.store(self.api.authorizationManager)
    } catch {
      logger.log("Could not store Spotify Authorization Manager into Keychain.")
    }
  }

  func authorizationManagerDidDeauthorize() {
    self.isAuthorized = false

    if !keychain.remove() {
      logger.log("Could not remove Spotify Authorization Manager from Keychain.")
    }
  }

}
