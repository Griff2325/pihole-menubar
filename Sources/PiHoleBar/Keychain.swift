import Foundation
import Security

enum Keychain {
    private static let service = "PiHoleBar"
    private static let account = "admin-password"

    static func load() -> String {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: service,
                                kSecAttrAccount as String: account,
                                kSecReturnData as String: true]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let d = out as? Data else { return "" }
        return String(data: d, encoding: .utf8) ?? ""
    }

    static func save(_ password: String) {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: account]
        guard !password.isEmpty else { SecItemDelete(base as CFDictionary); return }
        let data = [kSecValueData as String: Data(password.utf8)]
        if SecItemUpdate(base as CFDictionary, data as CFDictionary) == errSecItemNotFound {
            SecItemAdd(base.merging(data) { $1 } as CFDictionary, nil)
        }
    }
}
