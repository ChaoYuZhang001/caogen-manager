// 快捷指令系统

import Foundation

// 快捷指令模型
struct QuickAction: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let prompt: String
    let isSystem: Bool
    let isEnabled: Bool
    let executionCount: Int
}

// 快捷指令管理器
class QuickActionManager: ObservableObject {
    @Published var quickActions: [QuickAction] = []

    // 系统预设快捷指令
    let systemActions: [QuickAction] = [
        QuickAction(
            id: UUID(),
            name: "写周报",
            icon: "doc.text.fill",
            prompt: "帮我写个工作周报",
            isSystem: true,
            isEnabled: true,
            executionCount: 0
        ),
        QuickAction(
            id: UUID(),
            name: "查日程",
            icon: "calendar",
            prompt: "帮我查一下今天的日程",
            isSystem: true,
            isEnabled: true,
            executionCount: 0
        ),
        QuickAction(
            id: UUID(),
            name: "早安报",
            icon: "sun.max.fill",
            prompt: "帮我写个早安日报",
            isSystem: true,
            isEnabled: true,
            executionCount: 0
        ),
        QuickAction(
            id: UUID(),
            name: "生成图片",
            icon: "photo.fill",
            prompt: "生成一张",
            isSystem: true,
            isEnabled: true,
            executionCount: 0
        ),
        QuickAction(
            id: UUID(),
            name: "翻译文本",
            icon: "textformat.abc",
            prompt: "翻译这段文本：",
            isSystem: true,
            isEnabled: true,
            executionCount: 0
        )
    ]

    init() {
        loadQuickActions()
    }

    // 加载快捷指令
    func loadQuickActions() {
        if let data = UserDefaults.standard.data(forKey: "quick_actions"),
           let decoded = try? JSONDecoder().decode([QuickAction].self, from: data) {
            quickActions = decoded
        } else {
            quickActions = systemActions
        }
    }

    // 保存快捷指令
    func saveQuickActions() {
        if let encoded = try? JSONEncoder().encode(quickActions) {
            UserDefaults.standard.set(encoded, forKey: "quick_actions")
        }
    }

    // 执行快捷指令
    func executeQuickAction(_ action: QuickAction, chatManager: ChatManager) async {
        // 增加执行次数
        if let index = quickActions.firstIndex(where: { $0.id == action.id }) {
            quickActions[index].executionCount += 1
            saveQuickActions()
        }

        // 发送消息
        await chatManager.sendMessage(action.prompt)
    }

    // 添加自定义快捷指令
    func addCustomQuickAction(name: String, icon: String, prompt: String) {
        let newAction = QuickAction(
            id: UUID(),
            name: name,
            icon: icon,
            prompt: prompt,
            isSystem: false,
            isEnabled: true,
            executionCount: 0
        )
        quickActions.append(newAction)
        saveQuickActions()
    }

    // 删除快捷指令
    func deleteQuickAction(_ action: QuickAction) {
        quickActions.removeAll { $0.id == action.id }
        saveQuickActions()
    }

    // 切换快捷指令状态
    func toggleQuickAction(_ action: QuickAction) {
        if let index = quickActions.firstIndex(where: { $0.id == action.id }) {
            quickActions[index].isEnabled.toggle()
            saveQuickActions()
        }
    }
}

// 快捷指令编辑视图
struct QuickActionEditorView: View {
    @EnvironmentObject var quickActionManager: QuickActionManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var prompt = ""

    let availableIcons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "sun.fill", "moon.fill", "cloud.fill",
        "doc.text.fill", "calendar", "clock.fill", "bell.fill",
        "photo.fill", "video.fill", "music.note", "mic.fill"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $name)
                    Picker("图标", selection: $icon) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Label(icon, systemImage: icon)
                        }
                    }
                }

                Section("指令内容") {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 100)
                    Text("提示：可以输入类似 '帮我写个周报' 这样的指令")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button("创建快捷指令") {
                        quickActionManager.addCustomQuickAction(
                            name: name,
                            icon: icon,
                            prompt: prompt
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty || prompt.isEmpty)
                }
            }
            .navigationTitle("创建快捷指令")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
