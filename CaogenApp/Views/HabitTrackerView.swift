import SwiftUI
import Charts

// 习惯模型
struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var targetDays: [Int] // 0=周日, 1=周一, ...
    var reminderTime: Date?
    var createdAt: Date
    var completions: [Date]

    init(name: String, icon: String, color: String, targetDays: [Int], reminderTime: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.targetDays = targetDays
        self.reminderTime = reminderTime
        self.createdAt = Date()
        self.completions = []
    }

    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return completions.contains { Calendar.current.isDate($0, inSameDayAs: today) }
    }

    var currentStreak: Int {
        var streak = 0
        var date = Date()

        for i in 0..<365 {
            let checkDate = Calendar.current.date(byAdding: .day, value: -i, to: date)!
            let dayOfWeek = Calendar.current.component(.weekday, from: checkDate) - 1

            if targetDays.contains(dayOfWeek) {
                let dayStart = Calendar.current.startOfDay(for: checkDate)
                if completions.contains(where: { Calendar.current.isDate($0, inSameDayAs: dayStart) }) {
                    streak += 1
                } else {
                    break
                }
            }
        }

        return streak
    }

    var completionRate: Double {
        let daysSinceCreated = max(1, Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day!)
        let expectedCompletions = targetDays.count * (daysSinceCreated / 7) * 7
        return Double(completions.count) / Double(max(1, expectedCompletions)) * 100
    }
}

// 习惯管理器
class HabitManager: ObservableObject {
    @Published var habits: [Habit] = []

    init() {
        loadHabits()
    }

    func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: "habits"),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }

    func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: "habits")
        }
    }

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabits()
    }

    func toggleCompletion(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: Date())

        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            if habits[index].isCompletedToday {
                habits[index].completions.removeAll { Calendar.current.isDate($0, inSameDayAs: today) }
            } else {
                habits[index].completions.append(today)
            }
            saveHabits()
        }
    }

    func getTodayHabits() -> [Habit] {
        let today = Calendar.current.component(.weekday, from: Date()) - 1
        return habits.filter { $0.targetDays.contains(today) }
    }

    func getCompletionData(for habit: Habit, days: Int = 7) -> [CompletionData] {
        var data: [CompletionData] = []

        for i in (0..<days).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let dayStart = Calendar.current.startOfDay(for: date)
            let completed = habit.completions.contains { Calendar.current.isDate($0, inSameDayAs: dayStart) }

            data.append(CompletionData(
                date: date,
                completed: completed
            ))
        }

        return data
    }
}

struct CompletionData: Identifiable {
    let id = UUID()
    let date: Date
    let completed: Bool
}

// 习惯追踪视图
struct HabitTrackerView: View {
    @StateObject private var habitManager = HabitManager()
    @State private var showingAddHabit = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 今日进度
                TodayProgressCard(habits: habitManager.getTodayHabits())

                // 习惯列表
                if habitManager.habits.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("暂无习惯")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("点击右上角添加第一个习惯")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(habitManager.habits) { habit in
                                HabitCard(
                                    habit: habit,
                                    onToggle: { habitManager.toggleCompletion(habit) },
                                    onDelete: { habitManager.deleteHabit(habit) }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("🎯 习惯追踪")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitSheet(onAdd: { habit in
                    habitManager.addHabit(habit)
                })
            }
        }
    }
}

// 今日进度卡片
struct TodayProgressCard: View {
    let habits: [Habit]

    var completedCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }

    var progress: Double {
        guard !habits.isEmpty else { return 0 }
        return Double(completedCount) / Double(habits.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("今日进度")
                .font(.headline)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(completedCount)/\(habits.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// 习惯卡片
struct HabitCard: View {
    let habit: Habit
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(habit.isCompletedToday ? Color.green : Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: habit.icon)
                        .font(.title3)
                        .foregroundColor(habit.isCompletedToday ? .white : .gray)
                }
            }

            // 名称和进度
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    // 连续天数
                    Label("\(habit.currentStreak) 天", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    // 完成率
                    Text(String(format: "%.0f%%", habit.completionRate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 进度环
            CompletionRing(progress: habit.completionRate / 100)
                .frame(width: 40, height: 40)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// 完成进度环
struct CompletionRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if progress >= 1 {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

// 添加习惯弹窗
struct AddHabitSheet: View {
    let onAdd: (Habit) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var color = "green"
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5] // 工作日
    @State private var hasReminder = false
    @State private var reminderTime = Date()

    let icons = ["star.fill", "flame.fill", "heart.fill", "book.fill", "figure.run",
                 "dumbbell.fill", "drop.fill", "brain.head.profile", "leaf.fill",
                 "moon.fill", "sun.max.fill", "cup.and.saucer.fill"]

    let colors = ["green", "blue", "red", "orange", "purple", "pink", "yellow"]

    let dayNames = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        NavigationView {
            Form {
                Section("习惯名称") {
                    TextField("例如：每天运动", text: $name)
                }

                Section("选择图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { iconName in
                            Button(action: { icon = iconName }) {
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundColor(icon == iconName ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(icon == iconName ? Color.green : Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                Section("选择颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(colors, id: \.self) { colorName in
                            Button(action: { color = colorName }) {
                                Circle()
                                    .fill(Color(colorName))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: color == colorName ? 3 : 0)
                                    )
                            }
                        }
                    }
                }

                Section("选择周期") {
                    HStack(spacing: 8) {
                        ForEach(0..<7) { index in
                            Button(action: {
                                if selectedDays.contains(index) {
                                    selectedDays.remove(index)
                                } else {
                                    selectedDays.insert(index)
                                }
                            }) {
                                Text(dayNames[index])
                                    .font(.caption)
                                    .fontWeight(selectedDays.contains(index) ? .bold : .regular)
                                    .foregroundColor(selectedDays.contains(index) ? .white : .primary)
                                    .frame(width: 36, height: 36)
                                    .background(selectedDays.contains(index) ? Color.green : Color.gray.opacity(0.1))
                                    .cornerRadius(18)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Section("提醒") {
                    Toggle("开启提醒", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("添加习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let habit = Habit(
                            name: name,
                            icon: icon,
                            color: color,
                            targetDays: Array(selectedDays).sorted(),
                            reminderTime: hasReminder ? reminderTime : nil
                        )
                        onAdd(habit)
                        dismiss()
                    }
                    .disabled(name.isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }
}

// 预览
struct HabitTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        HabitTrackerView()
    }
}
