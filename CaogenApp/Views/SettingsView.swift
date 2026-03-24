import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var serverURL: String = ""
    @State private var showAbout = false

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

                // 认证设置
                Section("认证") {
                    Toggle("生物识别登录", isOn: $settingsManager.isBiometricEnabled)
                        .onChange(of: settingsManager.isBiometricEnabled) { _ in
                            settingsManager.save()
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
                        Slider(value: $settingsManager.voiceSpeed, in: 0.1...1.0, step: 0.1) {
                            Text("语速")
                        }
                    }
                    .onChange(of: settingsManager.voiceSpeed) { _ in
                        settingsManager.save()
                    }
                }

                // 数据管理
                Section("数据") {
                    Button(action: clearChatHistory) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除聊天记录")
                        }
                        .foregroundColor(.red)
                    }
                }

                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
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
                }

                // 登出
                Section {
                    Button(action: logout) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("退出登录")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("⚙️ 设置")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }

    private func testConnection() {
        Task {
            // TODO: 实现真实的连接测试
            await MainActor.run {
                // 演示：显示成功提示
                print("测试连接: \(serverURL)")
            }
        }
    }

    private func clearChatHistory() {
        // TODO: 实现清除聊天记录
        print("清除聊天记录")
    }

    private func logout() {
        authManager.logout()
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("草根管家")
                    .font(.title)
                    .fontWeight(.bold)

                Text("你的 AI 智能助手")
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    InfoRow(label: "版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    InfoRow(label: "构建", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }

                Spacer()

                Text("© 2025 草根管家")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("确定") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsManager.shared)
            .environmentObject(AuthManager())
    }
}
