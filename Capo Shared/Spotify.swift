//
//  Spotify.swift
//  Capo Shared
//
//  Created by Dominic Philip on 4/12/22.
//

import Combine
import Foundation
import SpotifyWebAPI
import WatchConnectivity
import os.log

class Spotify: NSObject, ObservableObject {

  let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Spotify")

  let connectivity: WCSession

  private let clientId: String

  static let callbackURLScheme = "capo"
  static let redirectURI = URL(string: "\(callbackURLScheme)://callback")!

  static var state = String.randomURLSafe(length: 128)

  static var codeVerifier = String.randomURLSafe(length: 128)
  static var codeChallenge = String.makeCodeChallenge(codeVerifier: codeVerifier)

  let scopes: Set<Scope>

  let keychain = Keychain<AuthorizationCodeFlowPKCEManager>(
    server: SpotifyWebAPI.Endpoints.accountsBase, accessGroup: "group.run.capo")

  let api: SpotifyAPI<AuthorizationCodeFlowPKCEManager>

  var cancellables: Set<AnyCancellable> = []

  @Published var isAuthorized = false

  init(connectivity: WCSession = .default, clientId: String, scopes: Set<Scope>) {
    self.clientId = clientId
    self.scopes = scopes

    self.api = SpotifyAPI(
      authorizationManager: AuthorizationCodeFlowPKCEManager(clientId: self.clientId))

    self.connectivity = connectivity

    super.init()

    connectivity.delegate = self
    connectivity.activate()

    api.authorizationManagerDidChange
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: authorizationManagerDidChange)
      .store(in: &cancellables)

    api.authorizationManagerDidDeauthorize
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: authorizationManagerDidDeauthorize)
      .store(in: &cancellables)

    do {
      if let authorizationManager = try keychain.retrieve() {
        api.authorizationManager = authorizationManager
      }
    } catch {
      logger.log("Could not find Spotify Authorization Manager in Keychain.")
    }
  }

  private func authorizationManagerDidChange() {
    isAuthorized = api.authorizationManager.isAuthorized()

    do {
      try keychain.store(api.authorizationManager)
    } catch {
      logger.log("Could not store Spotify Authorization Manager into Keychain.")
    }

    #if os(iOS)
      do {
        let data = try JSONEncoder().encode(api.authorizationManager)
        let applicationContext =
          ["AuthorizationManagerDidChange": true, "Data": data] as [String: Any]
        sendApplicationContext(applicationContext)
      } catch {
        logger.log("Could not encode Spotify Authorization Manager.")
      }
    #endif
  }

  private func authorizationManagerDidDeauthorize() {
    isAuthorized = false

    if !keychain.remove() {
      logger.log("Could not remove Spotify Authorization Manager from Keychain.")
    }

    #if os(iOS)
      let applicationContext =
        ["AuthorizationManagerDidDeauthorize": true, "Data": Data()] as [String: Any]
      sendApplicationContext(applicationContext)
    #endif
  }

}

// MARK: - WCSessionDelegate
extension Spotify: WCSessionDelegate {

  func sendApplicationContext(_ applicationContext: [String: Any]) {
    do {
      try connectivity.updateApplicationContext(applicationContext)
    } catch {
      logger.log("Could not update Application Context to counterpart application.")
    }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any])
  {

    print(applicationContext)

    if let status = applicationContext["AuthorizationManagerDidChange"] as? Bool, status == true {
      guard let data = applicationContext["Data"] as? Data else {
        return
      }

      do {
        let authorizationManager = try JSONDecoder().decode(
          AuthorizationCodeFlowPKCEManager.self, from: data)
        api.authorizationManager = authorizationManager
      } catch {
        logger.log("Could not decode Spotify Authorization Manager from data.")
      }
    } else if let status = applicationContext["AuthorizationManagerDidDeauthorize"] as? Bool,
      status == true
    {
      api.authorizationManager.deauthorize()
    }
  }

  func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {}

  #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
      connectivity.activate()
    }
  #endif

}
