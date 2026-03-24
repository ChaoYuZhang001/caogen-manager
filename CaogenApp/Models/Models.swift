import Foundation

// 聊天消息模型
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let metadata: [String: String]?

    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), metadata: [String: String]? = nil) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// API 响应模型
struct ChatResponse: Codable {
    let success: Bool
    let data: ResponseData?
    let error: String?
    let message: String?

    struct ResponseData: Codable {
        let response: String?
        let timestamp: String?
    }
}

// 认证模型
struct AuthCredentials: Codable {
    let username: String
    let password: String
}

struct AuthToken: Codable {
    let token: String
    let user: UserInfo?
    let expiresAt: Date?

    struct UserInfo: Codable {
        let id: String
        let username: String
        let email: String?
        let fullName: String?
    }
}

// 配置模型
struct AppSettings: Codable {
    var serverURL: String
    var username: String
    var isBiometricEnabled: Bool
    var autoPlayVoice: Bool
    var voiceSpeed: Double

    static let defaultSettings = AppSettings(
        serverURL: "",
        username: "",
        isBiometricEnabled: false,
        autoPlayVoice: true,
        voiceSpeed: 0.5
    )
}

// 统计模型
struct AppStatistics: Codable {
    var totalMessages: Int
    var voiceCalls: Int
    var lastActiveDate: Date

    static let empty = AppStatistics(
        totalMessages: 0,
        voiceCalls: 0,
        lastActiveDate: Date()
    )
}
