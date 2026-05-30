import Foundation
import Security

/// P-256 Secure Enclave signing for ProofLock device signatures.
enum EnclaveSigner {
  private static let keyTag = "com.factlockcam.device_signing"

  static func signHash(hex: String) throws -> String {
    let digest = try digestFromHex(hex)
    let privateKey = try loadOrCreatePrivateKey()
    var error: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(
      privateKey,
      .ecdsaSignatureMessageX962SHA256,
      digest as CFData,
      &error,
    ) else {
      let message = (error?.takeRetainedValue() as Error?)?.localizedDescription
        ?? "Secure Enclave signing failed."
      throw NSError(
        domain: "EnclaveSigner",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: message],
      )
    }
    return (signature as Data).base64EncodedString()
  }

  private static func digestFromHex(_ hex: String) throws -> Data {
    let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !trimmed.isEmpty, trimmed.count % 2 == 0 else {
      throw NSError(
        domain: "EnclaveSigner",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "hash must be non-empty hex"],
      )
    }
    var data = Data(capacity: trimmed.count / 2)
    var index = trimmed.startIndex
    while index < trimmed.endIndex {
      let next = trimmed.index(index, offsetBy: 2)
      guard let byte = UInt8(trimmed[index..<next], radix: 16) else {
        throw NSError(
          domain: "EnclaveSigner",
          code: 3,
          userInfo: [NSLocalizedDescriptionKey: "invalid hex in hash"],
        )
      }
      data.append(byte)
      index = next
    }
    return data
  }

  private static func loadOrCreatePrivateKey() throws -> SecKey {
    if let existing = try tryCopyPrivateKey() {
      return existing
    }
    return try generatePrivateKey()
  }

  private static func tryCopyPrivateKey() throws -> SecKey? {
    let tag = keyTag.data(using: .utf8)!
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: tag,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecReturnRef as String: true,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess, let ref = item {
      return (ref as! SecKey)
    }
    if status == errSecItemNotFound {
      return nil
    }
    throw NSError(
      domain: "EnclaveSigner",
      code: 4,
      userInfo: [NSLocalizedDescriptionKey: "Keychain lookup failed (\(status))"],
    )
  }

  private static func generatePrivateKey() throws -> SecKey {
    let tag = keyTag.data(using: .utf8)!
    let access = SecAccessControlCreateWithFlags(
      nil,
      kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      [],
      nil,
    )!
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: tag,
        kSecAttrAccessControl as String: access,
      ],
    ]
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      let message = (error?.takeRetainedValue() as Error?)?.localizedDescription
        ?? "Could not create Secure Enclave key."
      throw NSError(
        domain: "EnclaveSigner",
        code: 5,
        userInfo: [NSLocalizedDescriptionKey: message],
      )
    }
    return privateKey
  }
}
