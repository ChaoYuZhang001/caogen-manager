import SwiftUI

@main
struct CaogenApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var chatManager = ChatManager()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var quickActionManager = QuickActionManager()
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var accessibilityManager = AccessibilityManager()
    @StateObject private var fontSizeManager = FontSizeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(chatManager)
                .environmentObject(settingsManager)
                .environmentObject(quickActionManager)
                .environmentObject(localizationManager)
                .environmentObject(themeManager)
                .environmentObject(accessibilityManager)
                .environmentObject(fontSizeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .onAppear {
                    setupApp()
                }
        }
    }

    private func setupApp() {
        print("🌾 草根管家 App 启动")

        // 配置应用
        if settingsManager.serverURL.isEmpty {
            settingsManager.serverURL = Bundle.main.object(forInfoDictionaryKey: "SERVER_URL") as? String ?? ""
        }

        // 检查认证状态
        authManager.checkAuthStatus()

        // 初始化快捷指令
        quickActionManager.loadQuickActions()

        // 初始化语言
        localizationManager.loadLanguage()

        // 初始化主题
        themeManager.loadTheme()

        // 初始化无障碍
        accessibilityManager.loadAccessibilitySettings()

        // 初始化字体大小
        fontSizeManager.loadScale()
    }
}
