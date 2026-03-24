import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var chatManager: ChatManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

// 主标签页视图
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("聊天", systemImage: "message.fill")
                }
                .tag(0)

            VoiceAssistantView()
                .tabItem {
                    Label("语音助手", systemImage: "mic.fill")
                }
                .tag(1)

            QuickActionsView()
                .tabItem {
                    Label("快捷指令", systemImage: "bolt.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.green)
    }
}

// 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager())
            .environmentObject(ChatManager())
            .environmentObject(SettingsManager.shared)
            .environmentObject(QuickActionManager())
            .environmentObject(ThemeManager())
            .environmentObject(AccessibilityManager())
            .environmentObject(FontSizeManager())
    }
}
