// 多语言支持

import Foundation

// 支持的语言
enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-CN"
    case traditionalChinese = "zh-HK"
    case english = "en-US"
    case japanese = "ja-JP"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }

    var flagEmoji: String {
        switch self {
        case .simplifiedChinese: return "🇨🇳"
        case .traditionalChinese: return "🇭🇰"
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        }
    }
}

// 本地化管理器
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: AppLanguage = .simplifiedChinese

    private let languageKey = "app_language"

    init() {
        loadLanguage()
    }

    // 加载语言设置
    func loadLanguage() {
        if let languageCode = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: languageCode) {
            currentLanguage = language
        }
    }

    // 保存语言设置
    func saveLanguage() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }

    // 切换语言
    func switchLanguage(_ language: AppLanguage) {
        currentLanguage = language
        saveLanguage()

        // 重新加载应用语言
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // 提示用户重启应用
        // 这里可以显示一个对话框提示用户
    }

    // 获取本地化字符串
    func localizedString(_ key: String) -> String {
        let tableName = "Localizable"
        let bundle = Bundle.main

        return NSLocalizedString(
            key,
            tableName: tableName,
            bundle: bundle,
            value: key,
            comment: ""
        )
    }
}

// 本地化字符串
extension String {
    var localized: String {
        let manager = LocalizationManager()
        return manager.localizedString(self)
    }
}

// 使用示例
/*
// 在代码中使用
Text("welcome_message".localized)

// 或使用 manager
let manager = LocalizationManager()
Text(manager.localizedString("welcome_message"))
*/
