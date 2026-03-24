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
                    Label("语音", systemImage: "mic.fill")
                }
                .tag(1)

            VoiceMemosView()
                .tabItem {
                    Label("备忘", systemImage: "waveform")
                }
                .tag(2)

            WeatherView()
                .tabItem {
                    Label("天气", systemImage: "cloud.sun.fill")
                }
                .tag(3)

            TranslationView()
                .tabItem {
                    Label("翻译", systemImage: "globe")
                }
                .tag(4)

            OCRView()
                .tabItem {
                    Label("OCR", systemImage: "doc.text.viewfinder")
                }
                .tag(5)

            HabitTrackerView()
                .tabItem {
                    Label("习惯", systemImage: "checkmark.circle.fill")
                }
                .tag(6)

            QuickActionsView()
                .tabItem {
                    Label("快捷", systemImage: "bolt.fill")
                }
                .tag(7)

            CollectionsView()
                .tabItem {
                    Label("收藏", systemImage: "star.fill")
                }
                .tag(8)

            HealthView()
                .tabItem {
                    Label("健康", systemImage: "heart.fill")
                }
                .tag(9)

            PluginStoreView()
                .tabItem {
                    Label("插件", systemImage: "square.grid.2x2.fill")
                }
                .tag(10)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(11)
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
