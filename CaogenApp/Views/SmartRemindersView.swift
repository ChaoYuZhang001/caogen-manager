import SwiftUI

// 提醒模型
struct Reminder: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var time: Date
    var repeatType: RepeatType
    var isEnabled: Bool
    var triggerConditions: [TriggerCondition]
    var createdAt: Date

    enum RepeatType: String, Codable, CaseIterable {
        case once = "仅一次"
        case daily = "每天"
        case weekdays = "工作日"
        case weekends = "周末"
        case weekly = "每周"
        case monthly = "每月"
    }

    enum TriggerCondition: String, Codable {
        case time = "时间"
        case location = "位置"
        case event = "事件"
    }

    init(title: String, content: String = "", time: Date, repeatType: RepeatType = .once, triggerConditions: [TriggerCondition] = []) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.time = time
        self.repeatType = repeatType
        self.isEnabled = true
        self.triggerConditions = triggerConditions
        self.createdAt = Date()
    }
}

// 智能提醒管理器
class ReminderManager: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var smartSuggestions: [String] = []

    init() {
        loadReminders()
        generateSmartSuggestions()
    }

    func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: "reminders"),
           let decoded = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = decoded.sorted { $0.time < $1.time }
        }
    }

    func saveReminders() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: "reminders")
        }
    }

    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        reminders.sort { $0.time < $1.time }
        saveReminders()
    }

    func deleteReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
    }

    func toggleReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isEnabled.toggle()
            saveReminders()
        }
    }

    // 生成智能建议
    func generateSmartSuggestions() {
        let hour = Calendar.current.component(.hour, from: Date())

        smartSuggestions = []

        // 基于时间的建议
        switch hour {
        case 6...8:
            smartSuggestions = ["起床喝水", "晨间运动", "早餐提醒", "今日计划"]
        case 9...11:
            smartSuggestions = ["工作提醒", "会议提醒", "适当休息", "喝水提醒"]
        case 12...13:
            smartSuggestions = ["午餐提醒", "午休提醒"]
        case 14...17:
            smartSuggestions = ["下午茶", "运动提醒", "工作总结"]
        case 18...20:
            smartSuggestions = ["晚餐提醒", "运动时间", "家人陪伴"]
        case 21...22:
            smartSuggestions = ["睡前阅读", "关闭手机", "明日计划"]
        default:
            smartSuggestions = ["休息时间"]
        }
    }

    func getUpcomingReminders() -> [Reminder] {
        let now = Date()
        return reminders.filter { $0.time > now && $0.isEnabled }.prefix(5).map { $0 }
    }
}

// 智能提醒视图
struct SmartRemindersView: View {
    @StateObject private var reminderManager = ReminderManager()
    @State private var showingAddReminder = false
    @State private var selectedSuggestion: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 智能建议
                if !reminderManager.smartSuggestions.isEmpty {
                    SmartSuggestionsSection(
                        suggestions: reminderManager.smartSuggestions,
                        onSelect: { suggestion in
                            selectedSuggestion = suggestion
                            showingAddReminder = true
                        }
                    )
                }

                // 今日提醒
                UpcomingRemindersSection(
                    reminders: reminderManager.getUpcomingReminders(),
                    onToggle: { reminder in
                        reminderManager.toggleReminder(reminder)
                    },
                    onDelete: { reminder in
                        reminderManager.deleteReminder(reminder)
                    }
                )

                // 所有提醒
                AllRemindersSection(
                    reminders: reminderManager.reminders,
                    onToggle: { reminder in
                        reminderManager.toggleReminder(reminder)
                    },
                    onDelete: { reminder in
                        reminderManager.deleteReminder(reminder)
                    }
                )

                Spacer()
            }
            .padding()
            .navigationTitle("🔔 智能提醒")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddReminder = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderSheet(
                    prefillTitle: selectedSuggestion,
                    onAdd: { reminder in
                        reminderManager.addReminder(reminder)
                        selectedSuggestion = nil
                    }
                )
            }
        }
    }
}

// 智能建议区域
struct SmartSuggestionsSection: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("智能建议")
                    .font(.headline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: { onSelect(suggestion) }) {
                            Text(suggestion)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
}

// 即将到来的提醒
struct UpcomingRemindersSection: View {
    let reminders: [Reminder]
    let onToggle: (Reminder) -> Void
    let onDelete: (Reminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("即将到来")
                .font(.headline)

            if reminders.isEmpty {
                Text("暂无提醒")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(reminders) { reminder in
                    ReminderRow(reminder: reminder, onToggle: onToggle, onDelete: onDelete)
                }
            }
        }
    }
}

// 所有提醒
struct AllRemindersSection: View {
    let reminders: [Reminder]
    let onToggle: (Reminder) -> Void
    let onDelete: (Reminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("所有提醒")
                .font(.headline)

            if reminders.isEmpty {
                Text("点击右上角添加提醒")
                    .foregroundColor(.secondary)
            } else {
                ForEach(reminders) { reminder in
                    ReminderRow(reminder: reminder, onToggle: onToggle, onDelete: onDelete)
                }
            }
        }
    }
}

// 提醒行
struct ReminderRow: View {
    let reminder: Reminder
    let onToggle: (Reminder) -> Void
    let onDelete: (Reminder) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onToggle(reminder) }) {
                Image(systemName: reminder.isEnabled ? "bell.fill" : "bell")
                    .foregroundColor(reminder.isEnabled ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundColor(reminder.isEnabled ? .primary : .secondary)

                HStack(spacing: 4) {
                    Text(reminder.time, style: .time)
                    Text("•")
                    Text(reminder.repeatType.rawValue)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if !reminder.isEnabled {
                Text("已关闭")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: { onDelete(reminder) }) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// 添加提醒弹窗
struct AddReminderSheet: View {
    let prefillTitle: String?
    let onAdd: (Reminder) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var time = Date()
    @State private var repeatType: Reminder.RepeatType = .once

    init(prefillTitle: String?, onAdd: @escaping (Reminder) -> Void) {
        self.prefillTitle = prefillTitle
        self.onAdd = onAdd
        _title = State(initialValue: prefillTitle ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("提醒内容") {
                    TextField("标题", text: $title)
                    TextField("备注（可选）", text: $content)
                }

                Section("时间") {
                    DatePicker("提醒时间", selection: $time, displayedComponents: .hourAndMinute)
                }

                Section("重复") {
                    Picker("重复", selection: $repeatType) {
                        ForEach(Reminder.RepeatType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("添加提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let reminder = Reminder(
                            title: title,
                            content: content,
                            time: time,
                            repeatType: repeatType
                        )
                        onAdd(reminder)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct SmartRemindersView_Previews: PreviewProvider {
    static var previews: some View {
        SmartRemindersView()
    }
}
