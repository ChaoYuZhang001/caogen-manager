// 无障碍功能支持

import SwiftUI
import AVFoundation

// 无障碍管理器
class AccessibilityManager: ObservableObject {
    @Published var isVoiceOverEnabled = false
    @Published var isReduceMotionEnabled = false
    @Published var isBoldTextEnabled = false
    @Published var preferredContentSize: CGSize = .zero

    private let accessibilityKey = "accessibility_preferences"

    init() {
        loadAccessibilitySettings()
        observeAccessibilityChanges()
    }

    // 加载无障碍设置
    private func loadAccessibilitySettings() {
        if let data = UserDefaults.standard.data(forKey: accessibilityKey),
           let decoded = try? JSONDecoder().decode(AccessibilityPreferences.self, from: data) {
            isVoiceOverEnabled = decoded.voiceOverEnabled
            isReduceMotionEnabled = decoded.reduceMotionEnabled
            isBoldTextEnabled = decoded.boldTextEnabled
            preferredContentSize = CGSize(
                width: CGFloat(decoded.contentWidth),
                height: CGFloat(decoded.contentHeight)
            )
        }
    }

    // 保存无障碍设置
    private func saveAccessibilitySettings() {
        let preferences = AccessibilityPreferences(
            voiceOverEnabled: isVoiceOverEnabled,
            reduceMotionEnabled: isReduceMotionEnabled,
            boldTextEnabled: isBoldTextEnabled,
            contentWidth: Int(preferredContentSize.width),
            contentHeight: Int(preferredContentSize.height)
        )

        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: accessibilityKey)
        }
    }

    // 监听无障碍设置变化
    private func observeAccessibilityChanges() {
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { _ in
                self.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
                self.saveAccessibilitySettings()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { _ in
                self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
                self.saveAccessibilitySettings()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIAccessibility.boldTextStatusDidChangeNotification)
            .sink { _ in
                self.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
                self.saveAccessibilitySettings()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}

// 无障碍偏好设置
struct AccessibilityPreferences: Codable {
    var voiceOverEnabled: Bool
    var reduceMotionEnabled: Bool
    var boldTextEnabled: Bool
    var contentWidth: Int
    var contentHeight: Int
}

// 无障碍视图修饰符
struct AccessibilityModifier: ViewModifier {
    @EnvironmentObject var accessibilityManager: AccessibilityManager

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .accessibilityValue(accessibilityValue)
            .accessibilityAddTraits(accessibilityTraits)
            .accessibilityRemoveTraits(accessibilityTraits)
    }

    var accessibilityLabel: Text {
        Text(label)
    }

    var accessibilityHint: Text? {
        hint.isEmpty ? nil : Text(hint)
    }

    var accessibilityValue: Text? {
        value.isEmpty ? nil : Text(value)
    }

    var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = []
        if isButton { traits.insert(.isButton) }
        if isHeader { traits.insert(.isHeader) }
        if isSelected { traits.insert(.isSelected) }
        if isStaticText { traits.insert(.isStaticText) }
        return traits
    }
}

// 使用示例
/*
// 在视图中使用
@EnvironmentObject var accessibilityManager: AccessibilityManager

Button("Send") {
    sendMessage()
}
.modifier(AccessibilityModifier(
    label: "发送消息",
    hint: "双击发送消息",
    value: "",
    isButton: true,
    isHeader: false,
    isSelected: false
))
*/

// 语音反馈管理器
class VoiceFeedbackManager {
    private let synthesizer = AVSpeechSynthesizer()

    // 朗读文本
    func speak(_ text: String, language: String = "zh-CN") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5

        synthesizer.speak(utterance)
    }

    // 停止朗读
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // 暂停朗读
    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
    }

    // 继续朗读
    func resume() {
        synthesizer.continueSpeaking()
    }
}

// 视觉反馈管理器
class VisualFeedbackManager {
    // 震动反馈
    static func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    // 通知反馈
    static func notificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // 选择反馈
    static func selectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// 高对比度颜色
struct HighContrastColors {
    static func foregroundColor(for color: Color) -> Color {
        if UIAccessibility.isInvertColorsEnabled {
            return Color(UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .white
                } else {
                    return .black
                }
            })
        }
        return color
    }

    static func backgroundColor(for color: Color) -> Color {
        if UIAccessibility.isInvertColorsEnabled {
            return Color(UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .black
                } else {
                    return .white
                }
            })
        }
        return color
    }
}

// 使用示例
/*
Text("Hello")
    .foregroundColor(HighContrastColors.foregroundColor(for: .primary))

Button("Submit") {
    submit()
}
.onTapGesture {
    VisualFeedbackManager.hapticFeedback()
}
*/
