/**
 * JVS Claw 风格首页
 * 突出"AI 助手"核心，"秒回不墨迹"
 */

import SwiftUI

/// JVS Claw 风格首页
struct JVSHomePage: View {
    @State private var userInput = ""
    @State private var responseText = ""
    @State private var isResponding = false
    @State private var responseTimer: Timer?

    let toxicColors = [
        "#FFD700", // 毒舌
        "#FF6B00", // 适中
        "#A0A3FF", // 温和
        "#E60000", // 严重
        "#2196F3", // 建议
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 标题区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)

                        Text("JVS Claw 风格")
                            .font(.system(size: 28, weight: .bold))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Text("毒舌但有用")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("默认接地气")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("真实不虚伪")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .background(Color(.ultraThinMaterial))

                Divider()

                // 输入区域
                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .leading) {
                        Image(systemName: "text.bubble.left")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)

                        TextField("让草根帮你点什么？",
                                text: $userInput)
                            .textFieldStyle(RoundedBorder())
                            .disabled(isResponding)
                            .autocapitalization(.disableAutocorrect)
                    }

                    Spacer()

                    // 按钮
                    HStack(spacing: 8) {
                        Button(action: {
                            sendMessage()
                        }) {
                            Text("发送")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || isResponding)

                        Button(action: {
                            withAnimation {
                                Animation.spring(response: 1.5, dampingFraction: 0.6)
                            }
                        }) {
                            Text("清除")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .disabled(userInput.isEmpty)
                    }
                }
                .padding(.horizontal, 16)
                .background(Color(.ultraThinMaterial))

                // 响应区域
                if !responseText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "text.bubble.right.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)

                            Text("草根回复:")
                                .font(.subheadline)
                        }

                        Text(responseText)
                            .font(.body)

                        Text(Date(), style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .navigationTitle("🌾 草根")
    }

    /// 发送消息
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isResponding = true
        let input = userInput
        userInput = ""

        // 模拟 AI 响应延迟
        responseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            responseText = "这是草根的回复：\(input)"
            isResponding = false
        }
    }
}

/// 聊天聊气泡
struct ChatBubble: Identifiable {
    let id = UUID()
    let user: String
    let text: String
    let timestamp: Date
    let isAI: Bool

    init(user: String, text: String, timestamp: Date, isAI: Bool = false) {
        self.user = user
        self.text = text
        self.timestamp = timestamp
        self.isAI = isAI
    }
}

/// 毒舌程度颜色
func toxicColor(level: Int) -> String {
    switch level {
    case 1:
        return "#A0A3FF" // 轻度
    case 2:
        return "#FFD700" // 温和
    case 3:
        return "#FFD700" // 适中
    case 4:
        return "#FF6B00" // 毒舌
    case 5:
        return "#E60000" // 严重
    default:
        return "#A0A3FF"
    }
}

/// 毒舌等级定义
enum ToxicityLevel: Int, Hashable, CustomStringConvertible {
    case light = 1
    case moderate = 2
    case normal = 3
    case severe = 4
    case extreme = 5

    var description: String {
        switch self {
        case .light:
            return "轻"
        case .moderate:
            return "中度"
        case .normal:
            return "适中"
        case .severe:
            return "严重"
        case .extreme:
            return "严重"
        }
    }
}

/// 用户画像
struct UserProfile {
    let nickname: String
    let fullName: String
    let avatar: String
    let bio: String
    let toxicityLevel: Int // 1-5
    let style: String // 轻度 | 温和 | 适中 | 严重 | 建议
}
