/**
 * Siri Shortcuts - 深度集成 Siri 快捷指令
 * 语音指令注册、快速操作配置、自动触发设置、数据查询功能
 */

import SwiftUI
import Intents
import IntentsUI

/// Siri Shortcuts 管理器
class SiriShortcutsManager: ObservableObject {
    @Published var shortcuts: [Shortcut] = []
    @Published var isAvailable: Bool = false

    init() {
        checkAvailability()
        loadShortcuts()
    }

    /// 检查 Siri 可用性
    private func checkAvailability() {
        isAvailable = INPreferences.siriAuthorizationStatus() == .authorized
    }

    /// 加载快捷指令
    private func loadShortcuts() {
        shortcuts = [
            Shortcut(
                id: "drink_water",
                title: "喝水时间",
                phrase: "喝水时间",
                icon: "drop.fill",
                category: .health,
                action: { await self.drinkWater() }
            ),
            Shortcut(
                id: "check_weather",
                title: "查询天气",
                phrase: "查询天气",
                icon: "cloud.sun.fill",
                category: .informational,
                action: { await self.checkWeather() }
            ),
            Shortcut(
                id: "check_schedule",
                title: "查看日程",
                phrase: "查看日程",
                icon: "calendar",
                category: .informational,
                action: { await self.checkSchedule() }
            ),
            Shortcut(
                id: "start_exercise",
                title: "开始运动",
                phrase: "开始运动",
                icon: "figure.run",
                category: .health,
                action: { await self.startExercise() }
            ),
            Shortcut(
                id: "log_expense",
                title: "记账",
                phrase: "记账",
                icon: "dollarsign.circle.fill",
                category: .generic,
                action: { await self.logExpense() }
            ),
            Shortcut(
                id: "habit_checkin",
                title: "习惯打卡",
                phrase: "习惯打卡",
                icon: "checkmark.circle.fill",
                category: .productivity,
                action: { await self.habitCheckin() }
            ),
            Shortcut(
                id: "get_summary",
                title: "生活报告",
                phrase: "生活报告",
                icon: "chart.bar.fill",
                category: .informational,
                action: { await self.getSummary() }
            ),
            Shortcut(
                id: "send_message",
                title: "发送消息",
                phrase: "发送消息",
                icon: "message.fill",
                category: .generic,
                action: { await self.sendMessage() }
            )
        ]
    }

    /// 注册快捷指令
    func donateShortcut(_ shortcut: Shortcut) {
        let intent = createIntent(for: shortcut)

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = shortcut.id

        interaction.donate { error in
            if let error = error {
                print("❌ 快捷指令注册失败: \(error)")
            } else {
                print("✅ 快捷指令注册成功: \(shortcut.title)")
            }
        }
    }

    /// 创建 Intent
    private func createIntent(for shortcut: Shortcut) -> INIntent {
        switch shortcut.category {
        case .health:
            return INStartWorkoutIntent()
        case .informational:
            return INSearchForItemsIntent()
        case .productivity:
            return INAddTasksIntent()
        case .generic:
            return INSendMessageIntent()
        default:
            return INIntent()
        }
    }

    /// 提供快捷指令
    func provideShortcut(_ shortcut: Shortcut) -> INVoiceShortcut {
        let intent = createIntent(for: shortcut)
        let phrase = INPhrase spokenPhrase: shortcut.phrase

        return INVoiceShortcut(shortcut: INShortcut(intent: intent), invocationPhrase: phrase)
    }

    /// 快捷指令操作
    func drinkWater() async {
        print("💧 喝水记录已添加")
        // TODO: 实际记录到健康数据
    }

    func checkWeather() async {
        print("🌤️ 查询天气中...")
        // TODO: 实际调用天气 API
    }

    func checkSchedule() async {
        print("📅 查询日程中...")
        // TODO: 实际调用日程 API
    }

    func startExercise() async {
        print("🏃 开始运动")
        // TODO: 实际启动运动记录
    }

    func logExpense() async {
        print("💰 记账中...")
        // TODO: 实际记录消费
    }

    func habitCheckin() async {
        print("✅ 习惯打卡")
        // TODO: 实际打卡记录
    }

    func getSummary() async {
        print("📊 生成生活报告...")
        // TODO: 实际生成报告
    }

    func sendMessage() async {
        print("💬 发送消息...")
        // TODO: 实际发送消息
    }

    /// 请求 Siri 授权
    func requestSiriAuthorization() async -> Bool {
        isAvailable = await INPreferences.requestSiriAuthorization()

        return isAvailable
    }
}

/// 快捷指令
struct Shortcut: Identifiable {
    let id: String
    let title: String
    let phrase: String
    let icon: String
    let category: INIntentCategory
    let action: () async -> Void
}

/// Siri Shortcuts 视图
struct SiriShortcutsView: View {
    @StateObject private var manager = SiriShortcutsManager()

    var body: some View {
        NavigationView {
            List(manager.shortcuts) { shortcut in
                ShortcutRow(shortcut: shortcut, manager: manager)
            }
            .navigationTitle("🎤 Siri 快捷指令")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        // TODO: 添加自定义快捷指令
                    }
                }
            }
        }
    }
}

/// 快捷指令行
struct ShortcutRow: View {
    let shortcut: Shortcut
    @ObservedObject var manager: SiriShortcutsManager

    var body: some View {
        HStack {
            // 图标
            ZStack {
                Circle()
                    .fill(colorForCategory(shortcut.category))
                    .frame(width: 50, height: 50)

                Image(systemName: shortcut.icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(shortcut.title)
                    .font(.headline)

                Text("\"\(shortcut.phrase)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 启用/禁用开关
            Toggle("", isOn: Binding(
                get: { true },
                set: { enabled in
                    if enabled {
                        manager.donateShortcut(shortcut)
                    }
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 8)
    }

    private func colorForCategory(_ category: INIntentCategory) -> Color {
        switch category {
        case .health:
            return .red
        case .informational:
            return .blue
        case .productivity:
            return .green
        case .generic:
            return .orange
        default:
            return .gray
        }
    }
}

/// 快捷指令配置视图
struct ShortcutConfigurationView: View {
    @State private var title: String = ""
    @State private var phrase: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedCategory: INIntentCategory = .generic

    let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "sun.max.fill", "moon.fill", "cloud.fill", "drop.fill"
    ]

    let categories: [INIntentCategory] = [
        .health, .informational, .productivity, .generic
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("标题", text: $title)
                    TextField("语音指令", text: $phrase)
                }

                Section(header: Text("图标")) {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.green : Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: icon)
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("分类")) {
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(categoryName(category))
                                .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("配置快捷指令")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveShortcut()
                    }
                    .disabled(title.isEmpty || phrase.isEmpty)
                }
            }
        }
    }

    private func categoryName(_ category: INIntentCategory) -> String {
        switch category {
        case .health: return "健康"
        case .informational: return "信息"
        case .productivity: return "效率"
        case .generic: return "通用"
        default: return "其他"
        }
    }

    private func saveShortcut() {
        print("💾 保存快捷指令: \(title)")
        // TODO: 保存快捷指令
    }
}

/// 使用示例
struct SiriShortcutsExample: View {
    @StateObject private var manager = SiriShortcutsManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("🎤 Siri 快捷指令")
                .font(.title)

            if !manager.isAvailable {
                Button("授权 Siri") {
                    Task {
                        await manager.requestSiriAuthorization()
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            List(manager.shortcuts) { shortcut in
                Button(shortcut.title) {
                    Task {
                        await shortcut.action()
                    }
                }
            }
        }
        .padding()
    }
}
