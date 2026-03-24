import Foundation

// 聊天管理器
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var lastResponse: String?
    @Published var errorMessage: String?

    private var settingsManager: SettingsManager {
        SettingsManager.shared
    }

    init() {
        loadMessages()
    }

    // 发送消息
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // 添加用户消息
        let userMessage = ChatMessage(
            content: text,
            isUser: true,
            timestamp: Date()
        )
        await MainActor.run {
            messages.append(userMessage)
        }

        isLoading = true
        errorMessage = nil

        do {
            // 调用后端 API
            let response = try await sendToBackend(text)

            // 添加草根回复
            let botMessage = ChatMessage(
                content: response,
                isUser: false,
                timestamp: Date()
            )

            await MainActor.run {
                messages.append(botMessage)
                lastResponse = response
                isLoading = false
            }

            // 保存消息
            saveMessages()

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            print("发送消息失败: \(error)")
        }
    }

    // 发送到后端
    private func sendToBackend(_ text: String) async throws -> String {
        let serverURL = settingsManager.serverURL
        guard !serverURL.isEmpty else {
            throw ChatError.serverNotConfigured
        }

        let url = URL(string: "\(serverURL)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 如果有认证 Token，添加到请求头
        if let token = AuthManager().getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "message": text,
            "sessionKey": "agent:main:main",
            "timeoutSeconds": 30
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ChatError.serverError(statusCode: httpResponse.statusCode)
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

        guard chatResponse.success,
              let responseData = chatResponse.data,
              let responseText = responseData.response else {
            throw ChatError.noData
        }

        return responseText
    }

    // 批量发送消息
    func sendBatchMessages(_ texts: [String]) async {
        for text in texts {
            await sendMessage(text)
            // 避免请求过快
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        }
    }

    // 清除历史
    func clearHistory() {
        messages.removeAll()
        lastResponse = nil
        saveMessages()
    }

    // 保存/加载消息
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: "chat_messages")
        }
    }

    private func loadMessages() {
        if let data = UserDefaults.standard.data(forKey: "chat_messages"),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = decoded
        }
    }

    enum ChatError: LocalizedError {
        case serverNotConfigured
        case invalidResponse
        case serverError(statusCode: Int)
        case noData
        case networkError

        var errorDescription: String? {
            switch self {
            case .serverNotConfigured:
                return "服务器未配置，请在设置中添加服务器地址"
            case .invalidResponse:
                return "服务器响应无效"
            case .serverError(let statusCode):
                return "服务器错误 (状态码: \(statusCode))"
            case .noData:
                return "未收到数据"
            case .networkError:
                return "网络连接失败"
            }
        }
    }

    // 获取认证 Token（临时方法）
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.caogen.app.keychain",
            kSecAttrAccount as String: "auth_token",
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
}
