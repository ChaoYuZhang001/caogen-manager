import Foundation
import LocalAuthentication

// 认证管理器
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let keychainService = "com.caogen.app.keychain"
    private let tokenKey = "auth_token"
    private let credentialsKey = "user_credentials"

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 这里调用后端 API 进行认证
            // 临时实现：演示用
            if username.isEmpty || password.isEmpty {
                throw AuthError.invalidCredentials
            }

            // 模拟 API 调用
            let token = try await authenticateWithBackend(username: username, password: password)

            // 保存 Token
            saveToken(token)

            isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            print("登录失败: \(error)")
        }

        isLoading = false
    }

    func logout() {
        deleteToken()
        isAuthenticated = false
    }

    func checkAuthStatus() {
        isAuthenticated = (getToken() != nil)
    }

    // 生物识别认证
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "使用 Face ID 或 Touch ID 登录草根管家"
            )
            return success
        } catch {
            print("生物识别认证失败: \(error)")
            return false
        }
    }

    // 保存/获取 Token
    private func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    // 后端认证（需要实现）
    private func authenticateWithBackend(username: String, password: String) async throws -> String {
        // TODO: 调用真实的后端 API
        // 示例代码：
        /*
        let url = URL(string: "\(serverURL)/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AuthCredentials(username: username, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthToken.self, from: data)
        return response.token
        */

        // 演示：返回模拟 Token
        return "demo_token_\(username)_\(Date().timeIntervalSince1970)"
    }

    enum AuthError: LocalizedError {
        case invalidCredentials
        case networkError
        case serverError

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "用户名或密码错误"
            case .networkError:
                return "网络连接失败"
            case .serverError:
                return "服务器错误"
            }
        }
    }
}
