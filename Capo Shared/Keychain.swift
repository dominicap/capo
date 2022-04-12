//
//  Keychain.swift
//  Capo Shared
//
//  Created by Dominic Philip on 4/12/22.
//

import Foundation
import Security

struct Keychain<T: Codable> {

  var server: String

  @discardableResult
  func create(_ item: T) throws -> Bool {
    let attributes: [String: Any] = [
      kSecClass as String: kSecClassInternetPassword,
      kSecAttrSynchronizable as String: true,
      kSecAttrServer as String: self.server,
      kSecValueData as String: try JSONEncoder().encode(item),
    ]

    let status = SecItemAdd(attributes as CFDictionary, nil)

    guard status == errSecSuccess else {
      return false
    }

    return true
  }

  @discardableResult
  func store(_ item: T) throws -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassInternetPassword,
      kSecAttrSynchronizable as String: true,
      kSecAttrServer as String: self.server,
    ]

    let data = try JSONEncoder().encode(item)
    let attributes: [String: Any] = [kSecValueData as String: data]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

    guard status != errSecItemNotFound else {
      return try create(item)
    }

    guard status == errSecSuccess else {
      return false
    }

    return true
  }

  @discardableResult
  func retrieve() throws -> T? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassInternetPassword,
      kSecAttrSynchronizable as String: true,
      kSecAttrServer as String: self.server,
      kSecReturnAttributes as String: false,
      kSecReturnData as String: true,
    ]

    var data: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &data)

    guard status != errSecItemNotFound else {
      return nil
    }

    guard status == errSecSuccess else {
      return nil
    }

    guard let data = data as? Data else {
      return nil
    }

    return try JSONDecoder().decode(T.self, from: data)
  }

  @discardableResult
  func remove() -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassInternetPassword,
      kSecAttrSynchronizable as String: true,
      kSecAttrServer as String: self.server,
    ]

    let status = SecItemDelete(query as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      return false
    }

    return true
  }

}
