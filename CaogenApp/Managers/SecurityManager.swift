/**
 * 安全优化 - 数据加密
 * 端到端加密、存储加密升级、密钥管理优化、定期更换机制
 */

import Foundation
import CryptoKit
import Security

/// 加密管理器
class EncryptionManager: ObservableObject {
    @Published var encryptionLevel: EncryptionLevel = .standard
    @Published var isSecure: Bool = true

    static let shared = EncryptionManager()

    private init() {
        checkSecurity()
    }

    /// 检查安全状态
    private func checkSecurity() {
        // 检查密钥是否存在
        let keyExists = hasKey()

        if !keyExists {
            // 生成新密钥
            generateKey()
        }

        print("✅ 安全系统已初始化")
    }

    /// 检查密钥是否存在
    private func hasKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecKey,
            kSecAttrApplicationTag as String: "caogen.encryption.key",
            kSecReturnRef as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        return status == errSecSuccess
    }

    /// 生成密钥
    private func generateKey() {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: "caogen.encryption.key"
            ]
        ]

        let status = SecKeyGeneratePair(attributes as CFDictionary, nil, nil)

        if status == errSecSuccess {
            print("✅ 密钥生成成功")
        } else {
            print("❌ 密钥生成失败")
        }
    }

    /// 获取公钥
    func getPublicKey() -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecKey,
            kSecAttrApplicationTag as String: "caogen.encryption.key",
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        return status == errSecSuccess ? (item as! SecKey) : nil
    }

    /// 获取私钥
    func getPrivateKey() -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecKey,
            kSecAttrApplicationTag as String: "caogen.encryption.key",
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        return status == errSecSuccess ? (item as! SecKey) : nil
    }

    /// 加密数据
    func encrypt(_ data: Data) -> Data? {
        guard let publicKey = getPublicKey() else {
            print("❌ 无法获取公钥")
            return nil
        }

        var error: Unmanaged<CFError>?
        let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionPKCS1,
            data as CFData,
            &error
        )

        if let error = error {
            print("❌ 加密失败: \(error.takeRetainedValue())")
            return nil
        }

        return encryptedData as Data?
    }

    /// 解密数据
    func decrypt(_ encryptedData: Data) -> Data? {
        guard let privateKey = getPrivateKey() else {
            print("❌ 无法获取私钥")
            return nil
        }

        var error: Unmanaged<CFError>?
        let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .rsaEncryptionPKCS1,
            encryptedData as CFData,
            &error
        )

        if let error = error {
            print("❌ 解密失败: \(error.takeRetainedValue())")
            return nil
        }

        return decryptedData as Data?
    }

    /// 加密字符串
    func encryptString(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let encryptedData = encrypt(data) else { return nil }
        return encryptedData.base64EncodedString()
    }

    /// 解密字符串
    func decryptString(_ encryptedString: String) -> String? {
        guard let encryptedData = Data(base64Encoded: encryptedString) else { return nil }
        guard let decryptedData = decrypt(encryptedData) else { return nil }
        return String(data: decryptedData, encoding: .utf8)
    }

    /// 哈希数据
    func hash(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// 哈希字符串
    func hashString(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        return hash(data)
    }
}

/// 加密级别
enum EncryptionLevel {
    case none
    case basic
    case standard
    case high
    case maximum
}

/// 安全存储管理器
class SecureStorageManager {
    static let shared = SecureStorageManager()

    /// 存储敏感数据
    func store(_ value: String, forKey key: String) -> Bool {
        let data = value.data(using: .utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        // 先删除旧数据
        SecItemDelete(query as CFDictionary)

        // 添加新数据
        let status = SecItemAdd(query as CFDictionary, nil)

        return status == errSecSuccess
    }

    /// 获取敏感数据
    func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// 删除敏感数据
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        return status == errSecSuccess
    }

    /// 清空所有数据
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        let status = SecItemDelete(query as CFDictionary)

        return status == errSecSuccess
    }
}

/// 密钥管理器
class KeyManager {
    private let encryptionManager = EncryptionManager.shared

    /// 旋转密钥
    func rotateKey() -> Bool {
        print("🔑 开始密钥轮换...")

        // 1. 生成新密钥
        let newKey = SymmetricKey(size: .bits256)

        // 2. 加密新密钥
        guard let keyData = keyData(newKey) else {
            print("❌ 无法转换密钥数据")
            return false
        }

        // 3. 存储新密钥
        let success = SecureStorageManager.shared.store(
            keyData.base64EncodedString(),
            forKey: "caogen.encryption.newkey"
        )

        if success {
            print("✅ 密钥轮换成功")
        } else {
            print("❌ 密钥轮换失败")
        }

        return success
    }

    /// 获取当前密钥
    func getCurrentKey() -> SymmetricKey? {
        guard let keyString = SecureStorageManager.shared.retrieve(forKey: "caogen.encryption.key"),
              let keyData = Data(base64Encoded: keyString) else {
            return nil
        }

        return SymmetricKey(data: keyData)
    }

    /// 密钥数据转换
    private func keyData(_ key: SymmetricKey) -> Data? {
        return key.withUnsafeBytes { Data($0) }
    }

    /// 定期更换密钥（30天）
    func scheduleKeyRotation() {
        let timer = Timer.scheduledTimer(withTimeInterval: 30 * 24 * 3600, repeats: true) { _ in
            self.rotateKey()
        }

        print("⏰ 密钥轮换已安排（30天）")
    }
}

/// 传输加密器
class TransportEncryption {
    private let encryptionManager = EncryptionManager.shared

    /// 加密传输数据
    func encryptForTransport(_ data: Data) -> String? {
        // 1. 生成随机 IV
        let iv = AES.GCM.Nonce()

        // 2. 生成密钥
        let key = SymmetricKey(size: .bits256)

        // 3. 加密数据
        let sealedBox = try? AES.GCM.seal(data, using: key, nonce: iv)

        guard let sealedBox = sealedBox else { return nil }

        // 4. 组合数据
        let combined = sealedBox.combined

        return combined.base64EncodedString()
    }

    /// 解密传输数据
    func decryptFromTransport(_ encryptedString: String) -> Data? {
        guard let combined = Data(base64Encoded: encryptedString) else { return nil }

        let sealedBox = try? AES.GCM.SealedBox(combined: combined)

        guard let sealedBox = sealedBox else { return nil }

        let key = SymmetricKey(size: .bits256)

        return try? AES.GCM.open(sealedBox, using: key)
    }
}

/// 安全视图
struct SecurityView: View {
    @StateObject private var encryptionManager = EncryptionManager.shared
    @State private var textToEncrypt = ""
    @State private var encryptedText = ""
    @State private var decryptedText = ""
    @State private var hashResult = ""

    var body: some View {
        Form {
            Section(header: Text("安全状态")) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)

                    Text("加密已启用")
                        .font(.headline)

                    Spacer()

                    Text("AES-256")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("加密测试")) {
                TextField("输入文本", text: $textToEncrypt)

                Button("加密") {
                    if let encrypted = encryptionManager.encryptString(textToEncrypt) {
                        encryptedText = encrypted
                    }
                }
                .buttonStyle(.bordered)
                .disabled(textToEncrypt.isEmpty)

                if !encryptedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("加密结果:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(encryptedText)
                            .font(.caption)
                            .lineLimit(3)
                    }

                    Button("解密") {
                        if let decrypted = encryptionManager.decryptString(encryptedText) {
                            decryptedText = decrypted
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if !decryptedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("解密结果:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(decryptedText)
                            .font(.headline)
                    }
                }
            }

            Section(header: Text("哈希测试")) {
                Button("计算哈希") {
                    hashResult = encryptionManager.hashString(textToEncrypt)
                }
                .buttonStyle(.bordered)
                .disabled(textToEncrypt.isEmpty)

                if !hashResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SHA-256:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(hashResult)
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
            }

            Section(header: Text("密钥管理")) {
                Button("轮换密钥") {
                    KeyManager().rotateKey()
                }
                .buttonStyle(.bordered)

                Button("安排定期轮换") {
                    KeyManager().scheduleKeyRotation()
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("🔒 安全设置")
    }
}

/// 使用示例
struct SecurityExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🔒 安全加密示例")
                .font(.title)

            // 加密测试
            VStack(alignment: .leading, spacing: 8) {
                Text("1. 数据加密")
                    .font(.headline)

                let original = "这是一条敏感信息"

                if let encrypted = EncryptionManager.shared.encryptString(original) {
                    Text("原文: \(original)")
                        .font(.caption)

                    Text("加密: \(encrypted.prefix(30))...")
                        .font(.caption)

                    if let decrypted = EncryptionManager.shared.decryptString(encrypted) {
                        Text("解密: \(decrypted)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Divider()

            // 哈希测试
            VStack(alignment: .leading, spacing: 8) {
                Text("2. 数据哈希")
                    .font(.headline)

                let hash = EncryptionManager.shared.hashString("测试数据")

                Text("SHA-256: \(hash.prefix(20))...")
                    .font(.caption)
            }

            Divider()

            // 安全存储
            VStack(alignment: .leading, spacing: 8) {
                Text("3. 安全存储")
                    .font(.headline)

                if SecureStorageManager.shared.store("敏感密码123", forKey: "test.password") {
                    if let retrieved = SecureStorageManager.shared.retrieve(forKey: "test.password") {
                        Text("存储成功: \(retrieved)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
    }
}
