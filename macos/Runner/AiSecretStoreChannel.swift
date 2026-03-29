import Cocoa
import FlutterMacOS
import Security

final class AiSecretStoreChannel {
  static let channelName = "kongo/ai_secrets"

  private let service = "kongo.ai"
  private let account = "default"

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadApiKey":
      loadApiKey(result: result)
    case "saveApiKey":
      guard
        let arguments = call.arguments as? [String: Any],
        let value = arguments["value"] as? String
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Missing api key payload",
            details: nil
          )
        )
        return
      }
      saveApiKey(value, result: result)
    case "clearApiKey":
      clearApiKey(result: result)
    case "isSupported":
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func loadApiKey(result: @escaping FlutterResult) {
    var item: CFTypeRef?
    let status = SecItemCopyMatching(readQuery as CFDictionary, &item)
    if status == errSecItemNotFound {
      result(nil)
      return
    }

    guard status == errSecSuccess else {
      result(
        FlutterError(
          code: "keychain_read_failed",
          message: "Unable to read API key from Keychain",
          details: status
        )
      )
      return
    }

    guard
      let data = item as? Data,
      let value = String(data: data, encoding: .utf8)
    else {
      result(
        FlutterError(
          code: "keychain_decode_failed",
          message: "Unable to decode API key",
          details: nil
        )
      )
      return
    }

    result(value)
  }

  private func saveApiKey(_ value: String, result: @escaping FlutterResult) {
    let data = Data(value.utf8)
    let updateStatus = SecItemUpdate(
      identityQuery as CFDictionary,
      [kSecValueData as String: data] as CFDictionary
    )

    if updateStatus == errSecSuccess {
      result(nil)
      return
    }

    if updateStatus != errSecItemNotFound {
      result(
        FlutterError(
          code: "keychain_write_failed",
          message: "Unable to update API key in Keychain",
          details: updateStatus
        )
      )
      return
    }

    var addQuery = identityQuery
    addQuery[kSecValueData as String] = data
    let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      result(
        FlutterError(
          code: "keychain_write_failed",
          message: "Unable to save API key to Keychain",
          details: addStatus
        )
      )
      return
    }

    result(nil)
  }

  private func clearApiKey(result: @escaping FlutterResult) {
    let status = SecItemDelete(identityQuery as CFDictionary)
    if status == errSecSuccess || status == errSecItemNotFound {
      result(nil)
      return
    }

    result(
      FlutterError(
        code: "keychain_delete_failed",
        message: "Unable to remove API key from Keychain",
        details: status
      )
    )
  }

  private var identityQuery: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }

  private var readQuery: [String: Any] {
    var query = identityQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    return query
  }
}