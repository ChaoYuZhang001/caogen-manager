import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @EnvironmentObject var quickActionManager: QuickActionManager

    @State private var serverURL: String = ""
    @State private var showAbout = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showDataManagement = false

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
                        Text("1.0.0")
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

    private func logout() {
        authManager.logout()
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
            .environmentObject(AccessibilityManager())
            .environmentObject(QuickActionManager())
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
