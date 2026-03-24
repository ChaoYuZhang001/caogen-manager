import SwiftUI

@main
struct CaogenApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var chatManager = ChatManager()
    @StateObject private var settingsManager = SettingsManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(chatManager)
                .environmentObject(settingsManager)
                .onAppear {
                    setupApp()
                }
        }
    }

    private func setupApp() {
        // 配置应用
        print("🌾 草根管家 App 启动")

        // 检查配置
        if settingsManager.serverURL.isEmpty {
            settingsManager.serverURL = Bundle.main.object(forInfoDictionaryKey: "SERVER_URL") as? String ?? ""
        }

        // 检查认证状态
        authManager.checkAuthStatus()
    }
}
