import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @EnvironmentObject var quickActionManager: QuickActionManager
    
    // 新增：AI能力管理器
    @StateObject private var deepMemory = DeepMemoryManager.shared
    @StateObject private var emotionAI = EmotionAIManager.shared
    @StateObject private var intentUnderstanding = IntentUnderstandingManager.shared
    @StateObject private var predictionAI = PredictionAIManager.shared
    @StateObject private var personalization = PersonalizationEngine.shared
    @StateObject private var proactiveCare = ProactiveCareManager.shared
    @StateObject private var automation = AutomationManager.shared

    @State private var serverURL: String = ""
    @State private var showAbout = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showDataManagement = false
    @State private var showAIAbilities = false
    @State private var showAutomationTasks = false

    var body: some View {
        NavigationView {
            List {
                // 服务器配置
                Section("服务器配置") {
                    TextField("服务器地址", text: $serverURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onAppear {
                            serverURL = settingsManager.serverURL
                        }
                        .onChange(of: serverURL) { newValue in
                            settingsManager.serverURL = newValue
                        }

                    Button(action: testConnection) {
                        HStack {
                            Image(systemName: "network")
                            Text("测试连接")
                        }
                    }
                    .disabled(serverURL.isEmpty)
                }

                // 外观设置
                Section("外观") {
                    // 主题选择
                    Picker("主题", selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }

                    // 字体大小
                    Picker("字体大小", selection: $fontSizeManager.currentScale) {
                        ForEach(fontSizeManager.availableScales, id: \.scale) { scale in
                            Text(scale.name).tag(scale.scale)
                        }
                    }

                    // 语言选择
                    Picker("语言", selection: $localizationManager.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text("\(language.flagEmoji) \(language.displayName)").tag(language)
                        }
                    }
                    .onChange(of: localizationManager.currentLanguage) { _ in
                        localizationManager.saveLanguage()
                    }
                }

                // 语音设置
                Section("语音") {
                    Toggle("自动朗读回复", isOn: $settingsManager.autoPlayVoice)
                        .onChange(of: settingsManager.autoPlayVoice) { _ in
                            settingsManager.save()
                        }

                    VStack(alignment: .leading) {
                        Text("语速")
                        Slider(value: $settingsManager.voiceSpeed, in: 0.1...1.0, step: 0.1)
                    }
                    .onChange(of: settingsManager.voiceSpeed) { _ in
                        settingsManager.save()
                    }
                }

                // 新增：AI能力
                Section("AI能力") {
                    NavigationLink(destination: AIAbilitiesView()) {
                        HStack {
                            Image(systemName: "brain")
                            Text("AI能力概览")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "brain.fill")
                        Text("深度记忆")
                        Spacer()
                        let stats = deepMemory.getStatistics()
                        Text("\(stats["totalMemories"] ?? 0) 条记忆")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("情感识别")
                        Spacer()
                        Text("\(emotionAI.emotionHistory.count) 次识别")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "sparkles")
                        Text("个性化推荐")
                        Spacer()
                        Text("\(personalization.recommendations.count) 个推荐")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showAutomationTasks = true }) {
                        HStack {
                            Image(systemName: "gearshape.2")
                            Text("自动化任务")
                            Spacer()
                            Text("\(automation.automationTasks.count) 个任务")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 无障碍设置
                Section("无障碍") {
                    Toggle("语音反馈", isOn: Binding(
                        get: { !accessibilityManager.isVoiceOverEnabled },
                        set: { _ in }
                    ))

                    Toggle("减少动画", isOn: $accessibilityManager.isReduceMotionEnabled)
                        .onChange(of: accessibilityManager.isReduceMotionEnabled) { _ in
                            accessibilityManager.saveAccessibilitySettings()
                        }

                    Toggle("粗体文本", isOn: $accessibilityManager.isBoldTextEnabled)
                        .onChange(of: accessibilityManager.isBoldTextEnabled) { _ in
                            accessibilityManager.saveAccessibilitySettings()
                        }

                    NavigationLink(destination: AccessibilitySettingsView()) {
                        Label("高级无障碍设置", systemImage: "figure.walk")
                    }
                }

                // 认证设置
                Section("认证") {
                    Toggle("生物识别登录", isOn: $settingsManager.isBiometricEnabled)
                        .onChange(of: settingsManager.isBiometricEnabled) { _ in
                            settingsManager.save()
                        }

                    NavigationLink(destination: ChangePasswordView()) {
                        Label("修改密码", systemImage: "lock.fill")
                    }
                }

                // 数据管理
                Section("数据管理") {
                    NavigationLink(destination: DataManagementView()) {
                        Label("数据与存储", systemImage: "externaldrive.fill")
                    }

                    Button(action: clearChatHistory) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除聊天记录")
                        }
                        .foregroundColor(.red)
                    }
                    
                    // 新增：AI数据管理
                    Button(action: clearAIData) {
                        HStack {
                            Image(systemName: "trash.circle")
                            Text("清除AI数据")
                        }
                        .foregroundColor(.orange)
                    }
                }

                // 快捷指令
                Section("快捷指令") {
                    NavigationLink(destination: QuickActionManagementView()) {
                        Label("管理快捷指令", systemImage: "bolt.fill")
                    }

                    Text("当前快捷指令: \(quickActionManager.quickActions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 隐私与法律
                Section("隐私与法律") {
                    Button(action: { showPrivacyPolicy = true }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Button(action: { showTermsOfService = true }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("用户服务协议")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("2.0.0 (AI增强版)")
                            .foregroundColor(.secondary)
                    }

                    Button(action: { showAbout = true }) {
                        HStack {
                            Text("关于草根管家")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // 登出
                Section {
                    Button(action: logout) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("退出登录")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("⚙️ 设置")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showAIAbilities) {
                AIAbilitiesView()
            }
            .sheet(isPresented: $showAutomationTasks) {
                AutomationTasksView()
            }
        }
    }

    private func testConnection() {
        // TODO: 实现真实的连接测试
        print("测试连接: \(serverURL)")
    }

    private func clearChatHistory() {
        // TODO: 确认后清除
        print("清除聊天记录")
    }
    
    // 新增：清除AI数据
    private func clearAIData() {
        deepMemory.clearAllMemories()
        emotionAI.clearEmotionHistory()
        intentUnderstanding.clearRecentIntents()
        predictionAI.clearPredictionData()
        personalization.clearRecommendations()
        proactiveCare.clearCareActions()
        automation.clearAutomationTasks()
        print("🧠 AI数据已清除")
    }

    private func logout() {
        authManager.logout()
    }
}

// 新增：AI能力概览视图
struct AIAbilitiesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var deepMemory = DeepMemoryManager.shared
    @StateObject private var emotionAI = EmotionAIManager.shared
    @StateObject private var intentUnderstanding = IntentUnderstandingManager.shared
    @StateObject private var predictionAI = PredictionAIManager.shared
    @StateObject private var personalization = PersonalizationEngine.shared
    @StateObject private var proactiveCare = ProactiveCareManager.shared
    @StateObject private var automation = AutomationManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // 深度记忆
                Section("🧠 深度记忆系统") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("记住你的一切：你的喜好、习惯、关系、目标")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        let stats = deepMemory.getStatistics()
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("总记忆数")
                                Spacer()
                                Text("\(stats["totalMemories"] ?? 0)")
                                    .foregroundColor(.green)
                            }
                            HStack {
                                Text("长期记忆")
                                Spacer()
                                Text("\(stats["longTerm"] ?? 0)")
                                    .foregroundColor(.blue)
                            }
                            HStack {
                                Text("中期记忆")
                                Spacer()
                                Text("\(stats["mediumTerm"] ?? 0)")
                                    .foregroundColor(.orange)
                            }
                        }
                        .font(.caption)
                    }
                    
                    Button(action: {
                        personalization.initializeProfile()
                    }) {
                        Text("初始化用户画像")
                    }
                }
                
                // 情感AI
                Section("❤️ 情感AI系统") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("识别20种情绪，比用户更懂用户的心情")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("最近识别的情绪：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !emotionAI.emotionHistory.isEmpty {
                                let recentEmotions = emotionAI.emotionHistory.suffix(5)
                                ForEach(recentEmotions.reversed()) { result in
                                    HStack {
                                        Text(result.emotion.emoji)
                                        Text(result.emotion.rawValue)
                                        Spacer()
                                        Text("\(result.detectedAt, style: .time)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        // 测试情感识别
                        if let testResult = emotionAI.recognizeEmotion(from: "我今天很开心") {
                            print("测试结果：\(testResult.emotion.rawValue)")
                        }
                    }) {
                        Text("测试情感识别")
                    }
                }
                
                // 智能理解
                Section("🎯 智能理解系统") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("理解用户的每一个指令，即使不说完整")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("支持的能力：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• 复合意图识别")
                                .font(.caption)
                            Text("• 模糊意图理解")
                                .font(.caption)
                            Text("• 上下文推理")
                                .font(.caption)
                            Text("• 场景理解")
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        // 测试意图识别
                        if let testResult = intentUnderstanding.recognizeIntent(from: "查一下天气") {
                            print("测试结果：\(testResult.primaryIntent.rawValue)")
                        }
                    }) {
                        Text("测试意图识别")
                    }
                }
                
                // 预测AI
                Section("🔮 预测AI系统") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("预测用户的行为、需求、情绪、场景")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("支持预测：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                            Text("• 行为预测")
                                .font(.caption)
                            Text("• 需求预测")
                                .font(.caption)
                            Text("• 情绪预测")
                                .font(.caption)
                            Text("• 场景预测")
                                .font(.caption)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("预测统计：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                            Text("行为模式：\(predictionAI.behaviorPatterns.count)")
                                .font(.caption)
                            Text("用户需求：\(predictionAI.userNeeds.count)")
                                .font(.caption)
                        }
                    }
                }
                
                // 个性化推荐
                Section("🎨 个性化推荐") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("基于你的画像，推荐最适合你的")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("推荐类型：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                            Text("• 基于画像推荐")
                                .font(.caption)
                            Text("• 基于上下文推荐")
                                .font(.caption)
                            Text("• 协同过滤推荐")
                                .font(.caption)
                        }
                        
                        Divider()
                        
                        Text("已生成推荐：\(personalization.recommendations.count) 个")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        _ = personalization.generateRecommendations()
                    }) {
                        Text("生成推荐")
                    }
                }
                
                // 主动关怀
                Section("💡 主动关怀") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("在你需要之前就已经准备好了")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("关怀类型：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                            Text("• 基于时间的关怀")
                                .font(.caption)
                            Text("• 基于情绪的关怀")
                                .font(.caption)
                            Text("• 基于行为的关怀")
                                .font(.caption)
                            Text("• 基于场景的关怀")
                                .font(.caption)
                        }
                        
                        Divider()
                        
                        Text("关怀动作：\(proactiveCare.careActions.count) 个")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("已触发：\(proactiveCare.triggeredActions.count) 次")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // 自动化
                Section("🔄 自动化系统") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("学习你的习惯，越用越聪明")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("支持功能：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                            Text("• 自动学习用户习惯")
                                .font(.caption)
                            Text("• 自动执行任务")
                                .font(.caption)
                            Text("• 自动优化建议")
                                .font(.caption)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("统计信息：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                            Text("自动化任务：\(automation.automationTasks.count)")
                                .font(.caption)
                            Text("已执行：\(automation.executionHistory.count) 次")
                                .font(.caption)
                            Text("学习模式：\(automation.learnedPatterns.count)")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("🧠 AI能力概览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// 新增：自动化任务管理视图
struct AutomationTasksView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var automation = AutomationManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("已配置的自动化任务：\(automation.automationTasks.count) 个")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(automation.automationTasks) { task in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.name)
                                .font(.headline)
                            
                            Text(task.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("执行次数：\(task.executionCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if task.isEnabled {
                                Text("已启用")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("已禁用")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(action: {
                            automation.toggleAutomationTask(id: task.id)
                        }) {
                            Label(task.isEnabled ? "禁用" : "启用", systemImage: task.isEnabled ? "pause" : "play")
                        }
                        .tint(task.isEnabled ? .orange : .green)
                        
                        Button(action: {
                            automation.removeAutomationTask(id: task.id)
                        }) {
                            Label("删除", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        // 添加新自动化任务（简化版）
                        automation.addCustomAutomationTask(
                            type: .time,
                            title: "自定义自动化",
                            description: "自定义您的自动化任务",
                            triggerCondition: "time == 12:00",
                            action: .pushNotification,
                            actionData: ["title": "提醒", "message": "这是自定义提醒"]
                        )
                    }) {
                        Label("添加自定义自动化", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("🔄 自动化任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// 辅助视图
struct AccessibilitySettingsView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @EnvironmentObject var fontSizeManager: FontSizeManager

    var body: some View {
        Form {
            Section("显示") {
                Toggle("减少动画", isOn: $accessibilityManager.isReduceMotionEnabled)
                Toggle("粗体文本", isOn: $accessibilityManager.isBoldTextEnabled)

                Picker("字体大小", selection: $fontSizeManager.currentScale) {
                    ForEach(fontSizeManager.availableScales, id: \.scale) { scale in
                        Text(scale.name).tag(scale.scale)
                    }
                }
            }

            Section("语音") {
                Toggle("VoiceOver", isOn: $accessibilityManager.isVoiceOverEnabled)
            }
        }
        .navigationTitle("无障碍设置")
    }
}

struct ChangePasswordView: View {
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        Form {
            SecureField("当前密码", text: $oldPassword)
            SecureField("新密码", text: $newPassword)
            SecureField("确认新密码", text: $confirmPassword)

            Section {
                Button("修改密码") {
                    // 修改密码逻辑
                }
                .disabled(newPassword != confirmPassword || newPassword.isEmpty)
            }
        }
        .navigationTitle("修改密码")
    }
}

struct DataManagementView: View {
    @State private var syncEnabled = false

    var body: some View {
        Form {
            Section("云同步") {
                Toggle("启用云同步", isOn: $syncEnabled)

                Button("立即同步") {
                    // 立即同步
                }
                .disabled(!syncEnabled)
            }

            Section("存储") {
                HStack {
                    Text("本地存储")
                    Spacer()
                    Text("128 MB")
                        .foregroundColor(.secondary)
                }

                Button("清除缓存", role: .destructive) {
                    // 清除缓存
                }
            }
        }
        .navigationTitle("数据管理")
    }
}

struct QuickActionManagementView: View {
    @EnvironmentObject var quickActionManager: QuickActionManager

    var body: some View {
        List {
            ForEach(quickActionManager.quickActions) { action in
                HStack {
                    Image(systemName: action.icon)
                        .foregroundColor(.green)
                    Text(action.name)
                    Spacer()
                    if action.isSystem {
                        Text("系统")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Toggle("", isOn: Binding(
                        get: { quickActionManager.quickActions.first(where: { $0.id == action.id })?.isEnabled ?? false },
                        set: { _ in quickActionManager.toggleQuickAction(action) }
                    ))
                    .labelsHidden()
                }
            }
            .onDelete { indexSet in
                // 删除自定义快捷指令
            }
        }
        .navigationTitle("快捷指令管理")
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("隐私政策")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("我们重视您的隐私。本隐私政策说明我们如何收集、使用、存储和保护您的个人信息。")
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("用户服务协议")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("使用本应用即表示您同意本服务协议。")
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("用户服务协议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// 预览
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsManager.shared)
            .environmentObject(AuthManager())
            .environmentObject(ThemeManager())
            .environmentObject(LocalizationManager())
            .environmentObject(FontSizeManager())
            .EnvironmentObject(AccessibilityManager())
            .environmentObject(QuickActionManager())
    }
}
