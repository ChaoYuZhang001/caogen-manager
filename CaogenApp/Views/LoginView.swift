import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var username = ""
    @State private var password = ""
    @State private var showBiometric = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text("草根管家")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("你的 AI 智能助手")
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 登录表单
                VStack(spacing: 20) {
                    TextField("用户名", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("密码", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    if authManager.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else {
                        Button(action: login) {
                            Text("登录")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .disabled(username.isEmpty || password.isEmpty)
                    }

                    // 错误提示
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // 生物识别登录
                if settingsManager.isBiometricEnabled {
                    Button(action: biometricLogin) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("使用 Face ID / Touch ID 登录")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                // 服务器配置链接
                Button(action: { showBiometric = true }) {
                    Text("配置服务器")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("© 2025 草根管家")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showBiometric) {
                ServerConfigView()
                    .environmentObject(settingsManager)
            }
        }
    }

    private func login() {
        Task {
            await authManager.login(username: username, password: password)
        }
    }

    private func biometricLogin() {
        Task {
            let success = await authManager.authenticateWithBiometrics()
            if success {
                // 生物识别成功后自动登录
                await authManager.login(username: settingsManager.username, password: "")
            }
        }
    }
}

// 服务器配置视图
struct ServerConfigView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss

    @State private var serverURL = ""

    var body: some View {
        NavigationView {
            Form {
                Section("服务器") {
                    TextField("服务器地址", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onAppear {
                            serverURL = settingsManager.serverURL
                        }

                    Text("示例: http://your-server.com:3333")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("说明") {
                    Text("配置草根管家后端服务器地址。")
                    Text("如果不确定，请联系管理员。")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationTitle("服务器配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        settingsManager.serverURL = serverURL
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
            .environmentObject(SettingsManager.shared)
    }
}
