/**
 * 钉钉集成 - DingTalk Integration
 * 企业应用集成、日程同步、消息推送
 */

import Foundation
import Combine

/// 钉钉管理器
class DingTalkManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var schedules: [DingSchedule] = []
    @Published var messages: [DingMessage] = []
    @Published var contacts: [DingContact] = []

    private let apiURL = "https://oapi.dingtalk.com"
    private let accessToken = "" // 需要从钉钉开放平台获取
    private let corpId = "" // 企业ID

    /// 登录
    func login() async -> Bool {
        print("🔐 钉钉登录中...")

        // 模拟登录
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        isLoggedIn = true

        print("✅ 钉钉登录成功")

        return true
    }

    /// 同步日程
    func syncSchedules(startDate: Date, endDate: Date) async -> SyncResult {
        guard isLoggedIn else {
            return SyncResult(success: false, message: "未登录")
        }

        print("📅 同步日程...")

        // 模拟同步
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // 生成模拟日程
        let schedules = generateMockSchedules(startDate: startDate, endDate: endDate)

        self.schedules = schedules

        return SyncResult(
            success: true,
            message: "同步成功，共 \(schedules.count) 个日程",
            scheduleCount: schedules.count
        )
    }

    /// 生成模拟日程
    private func generateMockSchedules(startDate: Date, endDate: Date) -> [DingSchedule] {
        let titles = ["会议", "培训", "面试", "周报", "项目评审"]
        let locations = ["会议室A", "会议室B", "线上", "办公室", "客户现场"]
        let types: [ScheduleType] = [.meeting, .training, .interview, .report, .review]

        return (0..<10).map { i in
            let title = titles.randomElement()!
            let location = locations.randomElement()!
            let type = types.randomElement()!
            let timestamp = startDate.addingTimeInterval(Double(i) * 86400)
            let duration = TimeInterval.random(in: 1800...7200)

            return DingSchedule(
                id: UUID().uuidString,
                title: title,
                location: location,
                type: type,
                startTime: timestamp,
                duration: duration,
                attendees: generateMockAttendees()
            )
        }
    }

    /// 生成模拟参会人
    private func generateMockAttendees() -> [String] {
        let names = ["张三", "李四", "王五", "赵六"]
        let count = Int.random(in: 2...5)
        return Array(names.shuffled().prefix(count))
    }

    /// 获取今日日程
    func getTodaySchedules() -> [DingSchedule] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        return schedules.filter { schedule in
            schedule.startTime >= today && schedule.startTime < tomorrow
        }.sorted { $0.startTime < $1.startTime }
    }

    /// 获取即将到来的日程
    func getUpcomingSchedules(within hours: Int = 2) -> [DingSchedule] {
        let now = Date()
        let future = Date().addingTimeInterval(Double(hours) * 3600)

        return schedules.filter { schedule in
            schedule.startTime >= now && schedule.startTime <= future
        }.sorted { $0.startTime < $1.startTime }
    }

    /// 发送消息
    func sendMessage(_ content: String, to userId: String) async -> Bool {
        guard isLoggedIn else {
            print("❌ 未登录")
            return false
        }

        print("💬 发送消息: \(content)")

        // 模拟发送
        try? await Task.sleep(nanoseconds: 500_000_000)

        return true
    }

    /// 获取联系人
    func getContacts() async -> [DingContact] {
        print("👥 获取联系人...")

        // 模拟数据
        let contacts = [
            DingContact(id: "user1", name: "张三", department: "技术部", avatar: ""),
            DingContact(id: "user2", name: "李四", department: "产品部", avatar: ""),
            DingContact(id: "user3", name: "王五", department: "设计部", avatar: "")
        ]

        return contacts
    }

    /// 创建日程
    func createSchedule(
        title: String,
        location: String,
        startTime: Date,
        duration: TimeInterval,
        attendees: [String]
    ) -> Bool {
        guard isLoggedIn else {
            print("❌ 未登录")
            return false
        }

        let schedule = DingSchedule(
            id: UUID().uuidString,
            title: title,
            location: location,
            type: .meeting,
            startTime: startTime,
            duration: duration,
            attendees: attendees
        )

        schedules.append(schedule)

        print("✅ 日程创建成功: \(title)")

        return true
    }

    /// 删除日程
    func deleteSchedule(_ id: String) -> Bool {
        guard isLoggedIn else {
            print("❌ 未登录")
            return false
        }

        schedules.removeAll { $0.id == id }

        print("✅ 日程删除成功")

        return true
    }

    /// 获取消息
    func getMessages() async -> [DingMessage] {
        print("💬 获取消息...")

        // 模拟数据
        let messages = [
            DingMessage(
                id: UUID().uuidString,
                sender: "张三",
                content: "明天下午3点开会",
                timestamp: Date().addingTimeInterval(-3600),
                type: .text
            ),
            DingMessage(
                id: UUID().uuidString,
                sender: "李四",
                content: "项目进度如何？",
                timestamp: Date().addingTimeInterval(-7200),
                type: .text
            )
        ]

        return messages
    }
}

/// 钉钉日程
struct DingSchedule: Identifiable, Codable {
    let id: String
    let title: String
    let location: String
    let type: ScheduleType
    let startTime: Date
    let duration: TimeInterval
    let attendees: [String]

    enum ScheduleType: String, Codable {
        case meeting
        case training
        case interview
        case report
        case review
    }
}

/// 钉钉消息
struct DingMessage: Identifiable, Codable {
    let id: String
    let sender: String
    let content: String
    let timestamp: Date
    let type: MessageType

    enum MessageType: String, Codable {
        case text
        case image
        case file
        case link
    }
}

/// 钉钉联系人
struct DingContact: Identifiable, Codable {
    let id: String
    let name: String
    let department: String
    let avatar: String
}

/// 同步结果
struct SyncResult {
    let success: Bool
    let message: String
    let scheduleCount: Int?
}

/// 钉钉视图
struct DingTalkView: View {
    @StateObject private var manager = DingTalkManager()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("账户状态")) {
                    HStack {
                        Image(systemName: manager.isLoggedIn ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(manager.isLoggedIn ? .green : .red)

                        Text(manager.isLoggedIn ? "已登录" : "未登录")
                            .font(.headline)

                        Spacer()

                        if !manager.isLoggedIn {
                            Button("登录") {
                                Task {
                                    await manager.login()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                if manager.isLoggedIn {
                    Section(header: Text("日程同步")) {
                        Button("同步本周日程") {
                            Task {
                                let now = Date()
                                let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

                                await manager.syncSchedules(startDate: startOfWeek, endDate: now)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Section(header: Text("今日日程")) {
                        let todaySchedules = manager.getTodaySchedules()

                        if todaySchedules.isEmpty {
                            Text("今天没有日程")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(todaySchedules) { schedule in
                                ScheduleRow(schedule: schedule)
                            }
                        }
                    }

                    Section(header: Text("即将到来")) {
                        let upcomingSchedules = manager.getUpcomingSchedules(within: 24)

                        if upcomingSchedules.isEmpty {
                            Text("24小时内没有日程")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(upcomingSchedules) { schedule in
                                ScheduleRow(schedule: schedule)
                            }
                        }
                    }

                    Section(header: Text("工具")) {
                        NavigationLink(destination: CreateScheduleView(manager: manager)) {
                            Label("创建日程", systemImage: "calendar.badge.plus")
                        }

                        NavigationLink(destination: ContactsView(manager: manager)) {
                            Label("联系人", systemImage: "person.2.fill")
                        }

                        NavigationLink(destination: MessagesView(manager: manager)) {
                            Label("消息", systemImage: "message.fill")
                        }
                    }
                }
            }
            .navigationTitle("💼 钉钉")
        }
    }
}

/// 日程行
struct ScheduleRow: View {
    let schedule: DingSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(schedule.title)
                    .font(.headline)

                Spacer()

                Text(scheduleTypeIcon(schedule.type))
                    .font(.caption)
            }

            HStack {
                Label(formatTime(schedule.startTime), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("\(Int(schedule.duration / 60))分钟", systemImage: "timer")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label(schedule.location, systemImage: "location")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(schedule.attendees.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func scheduleTypeIcon(_ type: DingSchedule.ScheduleType) -> String {
        switch type {
        case .meeting: return "📋"
        case .training: return "📚"
        case .interview: return "🎤"
        case .report: return "📊"
        case .review: return "🔍"
        }
    }
}

/// 创建日程视图
struct CreateScheduleView: View {
    @ObservedObject var manager: DingTalkManager
    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var location: String = ""
    @State private var startTime: Date = Date()
    @State private var duration: Double = 3600
    @State private var attendees: String = ""

    var body: some View {
        Form {
            Section(header: Text("日程信息")) {
                TextField("标题", text: $title)

                TextField("地点", text: $location)

                DatePicker("开始时间", selection: $startTime)

                Picker("时长", selection: $duration) {
                    Text("30分钟").tag(1800.0)
                    Text("1小时").tag(3600.0)
                    Text("1.5小时").tag(5400.0)
                    Text("2小时").tag(7200.0)
                }

                TextField("参会人（逗号分隔）", text: $attendees)
            }

            Section {
                Button("创建") {
                    let attendeeList = attendees.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    let success = manager.createSchedule(
                        title: title,
                        location: location,
                        startTime: startTime,
                        duration: duration,
                        attendees: attendeeList
                    )

                    if success {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || location.isEmpty)
            }
        }
        .navigationTitle("创建日程")
    }
}

/// 联系人视图
struct ContactsView: View {
    @ObservedObject var manager: DingTalkManager
    @State private var contacts: [DingContact] = []

    var body: some View {
        List {
            ForEach(contacts) { contact in
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(contact.name)
                            .font(.headline)

                        Text(contact.department)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("发送消息") {
                        Task {
                            await manager.sendMessage("你好", to: contact.id)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("联系人")
        .task {
            contacts = await manager.getContacts()
        }
    }
}

/// 消息视图
struct MessagesView: View {
    @ObservedObject var manager: DingTalkManager
    @State private var messages: [DingMessage] = []

    var body: some View {
        List {
            ForEach(messages) { message in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(message.sender)
                            .font(.headline)

                        Spacer()

                        Text(formatTime(message.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(message.content)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("消息")
        .task {
            messages = await manager.getMessages()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
