import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var chatManager: ChatManager
    @StateObject private var predictionAI = PredictionAIManager.shared
    @StateObject private var proactiveCare = ProactiveCareManager.shared
    @State private var showCareNotification = false
    @State private var currentCareMessage = ""

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .onAppear {
                        // 应用启动时初始化预测和关怀
                        initializePredictionsAndCare()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CareNotification"))) { notification in
                        if let message = notification.object as? String {
                            currentCareMessage = message
                            showCareNotification = true
                        }
                    }
            } else {
                LoginView()
            }
        }
        .alert("主动关怀", isPresented: $showCareNotification) {
            Button("知道了") {
                showCareNotification = false
            }
        } message: {
            Text(currentCareMessage)
        }
    }
    
    // MARK: - Initialization
    
    private func initializePredictionsAndCare() {
        // 生成行为预测
        let predictions = predictionAI.predictBehavior(for: Date())
        print("🔮 启动预测：\(predictions.count) 个预测")
        
        // 检查关怀触发
        proactiveCare.triggerPredictionReminders()
    }
}

// 主标签页视图
struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var predictionAI = PredictionAIManager.shared
    @StateObject private var proactiveCare = ProactiveCareManager.shared
    @StateObject private var personalization = PersonalizationEngine.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: AI 助手（JVS Claw 风格）⭐
            JVSHomePage()
                .tabItem { Label("AI 助手", systemImage: "sparkles") }
                .tag(0)

            VoiceAssistantView()
                .tabItem { Label("语音", systemImage: "mic.fill") }
                .tag(1)

            VoiceMemosView()
                .tabItem { Label("备忘", systemImage: "waveform") }
                .tag(2)

            // 生活工具
            WeatherView()
                .tabItem { Label("天气", systemImage: "cloud.sun.fill") }
                .tag(3)

            TranslationView()
                .tabItem { Label("翻译", systemImage: "globe") }
                .tag(4)

            OCRView()
                .tabItem { Label("OCR", systemImage: "doc.text.viewfinder") }
                .tag(5)

            // 健康
            HabitTrackerView()
                .tabItem { Label("习惯", systemImage: "checkmark.circle.fill") }
                .tag(6)

            HealthView()
                .tabItem { Label("健康", systemImage: "heart.fill") }
                .tag(7)

            LifeTrackingView()
                .tabItem { Label("生活", systemImage: "house.fill") }
                .tag(8)

            ExpenseTrackerView()
                .tabItem { Label("记账", systemImage: "dollarsign.circle.fill") }
                .tag(9)

            SmartRemindersView()
                .tabItem { Label("提醒", systemImage: "bell.fill") }
                .tag(10)

            // 数据
            QuickActionsView()
                .tabItem { Label("快捷", systemImage: "bolt.fill") }
                .tag(11)

            CollectionsView()
                .tabItem { Label("收藏", systemImage: "star.fill") }
                .tag(12)

            // 扩展
            PluginStoreView()
                .tabItem { Label("插件", systemImage: "square.grid.2x2.fill") }
                .tag(13)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(14)
        }
        .accentColor(.green)
        .onChange(of: selectedTab) { newTab in
            // 切换标签时记录用户行为
            trackTabChange(newTab)
        }
    }
    
    // MARK: - Tab Change Tracking
    
    private func trackTabChange(_ tab: Int) {
        let tabNames = [
            "AI助手", "语音", "备忘", "天气", "翻译", "OCR",
            "习惯", "健康", "生活", "记账", "提醒", "快捷", "收藏", "插件", "设置"
        ]
        
        if tab < tabNames.count {
            let tabName = tabNames[tab]
            
            // 记录用户行为
            predictionAI.learnBehavior(action: "tab_\(tabName)", time: Date())
            
            // 生成推荐
            let context: [String: Any] = [
                "action": "tab_change",
                "tab": tabName
            ]
            _ = personalization.generateRecommendations(context: context)
        }
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
