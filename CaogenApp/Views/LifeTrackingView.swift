import SwiftUI

// 生活记录模型
struct LifeRecord: Identifiable, Codable {
    let id: UUID
    var type: LifeType
    var value: Double // 数量/时长等
    var unit: String
    var note: String
    var date: Date

    enum LifeType: String, Codable, CaseIterable {
        case drink = "喝水"
        case eat = "吃饭"
        case poop = "排便"
        case pee = "排尿"
        case sleep = "睡眠"
        case exercise = "运动"
        case walk = "走路"
        case weight = "体重"

        var icon: String {
            switch self {
            case .drink: return "drop.fill"
            case .eat: return "fork.knife"
            case .poop: return "figure.stand"
            case .pee: return "drop.fill"
            case .sleep: return "moon.fill"
            case .exercise: return "figure.run"
            case .walk: return "figure.walk"
            case .weight: return "scalemass.fill"
            }
        }

        var color: Color {
            switch self {
            case .drink: return .blue
            case .eat: return .orange
            case .poop: return .brown
            case .pee: return .yellow
            case .sleep: return .purple
            case .exercise: return .green
            case .walk: return .cyan
            case .weight: return .pink
            }
        }

        var defaultUnit: String {
            switch self {
            case .drink: return "ml"
            case .eat: return "次"
            case .poop: return "次"
            case .pee: return "次"
            case .sleep: return "小时"
            case .exercise: return "分钟"
            case .walk: return "步"
            case .weight: return "kg"
            }
        }
    }

    init(type: LifeType, value: Double, unit: String, note: String = "", date: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.unit = unit
        self.note = note
        self.date = date
    }
}

// 生活记录管理器
class LifeRecordManager: ObservableObject {
    @Published var records: [LifeRecord] = []

    init() {
        loadRecords()
    }

    func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: "life_records"),
           let decoded = try? JSONDecoder().decode([LifeRecord].self, from: data) {
            records = decoded.sorted { $0.date > $1.date }
        }
    }

    func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: "life_records")
        }
    }

    func addRecord(_ record: LifeRecord) {
        records.insert(record, at: 0)
        saveRecords()
    }

    func deleteRecord(_ record: LifeRecord) {
        records.removeAll { $0.id == record.id }
        saveRecords()
    }

    func getTodayRecords() -> [LifeRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        return records.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    func getTodayStats() -> [LifeRecord.LifeType: Double] {
        let todayRecords = getTodayRecords()
        var stats: [LifeRecord.LifeType: Double] = [:]

        for record in todayRecords {
            switch record.type {
            case .drink, .eat, .poop, .pee:
                stats[record.type, default: 0] += 1
            case .sleep, .exercise:
                stats[record.type, default: 0] += record.value
            case .walk:
                stats[record.type, default: 0] += record.value
            case .weight:
                stats[record.type] = record.value
            }
        }

        return stats
    }

    func getWeeklyData(for type: LifeRecord.LifeType) -> [DailyData] {
        var data: [DailyData] = []

        for i in (0..<7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let dayStart = Calendar.current.startOfDay(for: date)
            let dayRecords = records.filter {
                Calendar.current.isDate($0.date, inSameDayAs: dayStart) && $0.type == type
            }

            var value: Double = 0
            switch type {
            case .drink, .eat, .poop, .pee:
                value = Double(dayRecords.count)
            case .sleep, .exercise:
                value = dayRecords.map { $0.value }.reduce(0, +)
            case .walk:
                value = dayRecords.map { $0.value }.reduce(0, +)
            case .weight:
                value = dayRecords.last?.value ?? 0
            }

            data.append(DailyData(date: date, value: value))
        }

        return data
    }
}

struct DailyData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// 吃喝拉撒睡视图
struct LifeTrackingView: View {
    @StateObject private var lifeManager = LifeRecordManager()
    @State private var selectedType: LifeRecord.LifeType = .drink
    @State private var showingAddRecord = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日概览
                    TodayOverviewSection(stats: lifeManager.getTodayStats())

                    // 快速记录
                    QuickRecordSection(
                        selectedType: $selectedType,
                        onRecord: { showingAddRecord = true }
                    )

                    // 趋势图
                    TrendSection(
                        type: selectedType,
                        data: lifeManager.getWeeklyData(for: selectedType)
                    )

                    // 今日记录
                    TodayRecordsSection(
                        records: lifeManager.getTodayRecords(),
                        onDelete: { lifeManager.deleteRecord($0) }
                    )
                }
                .padding()
            }
            .navigationTitle("🏠 生活")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddRecord = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRecord) {
                AddLifeRecordSheet(
                    defaultType: selectedType,
                    onAdd: { lifeManager.addRecord($0) }
                )
            }
        }
    }
}

// 今日概览
struct TodayOverviewSection: View {
    let stats: [LifeRecord.LifeType: Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日概览")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(LifeRecord.LifeType.allCases, id: \.self) { type in
                    let value = stats[type] ?? 0
                    OverviewCard(type: type, value: value)
                }
            }
        }
    }
}

struct OverviewCard: View {
    let type: LifeRecord.LifeType
    let value: Double

    var displayValue: String {
        switch type {
        case .drink: return "\(Int(value))杯"
        case .eat: return "\(Int(value))餐"
        case .poop, .pee: return "\(Int(value))次"
        case .sleep: return String(format: "%.1f时", value)
        case .exercise: return "\(Int(value))分"
        case .walk: return "\(Int(value))步"
        case .weight: return value > 0 ? String(format: "%.1fkg", value) : "--"
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(type.color)

            Text(displayValue)
                .font(.caption)
                .fontWeight(.semibold)

            Text(type.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(type.color.opacity(0.1))
        .cornerRadius(12)
    }
}

// 快速记录
struct QuickRecordSection: View {
    @Binding var selectedType: LifeRecord.LifeType
    let onRecord: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速记录")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LifeRecord.LifeType.allCases, id: \.self) { type in
                        QuickRecordButton(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                            onRecord()
                        }
                    }
                }
            }
        }
    }
}

struct QuickRecordButton: View {
    let type: LifeRecord.LifeType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)

                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 70, height: 70)
            .background(isSelected ? type.color : type.color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// 趋势
struct TrendSection: View {
    let type: LifeRecord.LifeType
    let data: [DailyData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(type.rawValue)趋势（7天）")
                .font(.headline)

            if data.isEmpty || data.allSatisfy({ $0.value == 0 }) {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                // 简化趋势条
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data) { item in
                        let maxValue = data.map { $0.value }.max() ?? 1
                        let height = maxValue > 0 ? (item.value / maxValue) * 60 : 0

                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(type.color)
                                .frame(width: 30, height: max(4, height))

                            Text(item.date, format: .dateTime.weekday(.narrow))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

// 今日记录
struct TodayRecordsSection: View {
    let records: [LifeRecord]
    let onDelete: (LifeRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日记录")
                .font(.headline)

            if records.isEmpty {
                Text("暂无记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(records.prefix(10)) { record in
                    LifeRecordRow(record: record)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onDelete(record)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

struct LifeRecordRow: View {
    let record: LifeRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.type.icon)
                .font(.title3)
                .foregroundColor(record.type.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.type.rawValue)
                    .font(.headline)

                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(record.value)) \(record.unit)")
                    .font(.headline)

                Text(record.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 添加记录
struct AddLifeRecordSheet: View {
    let defaultType: LifeRecord.LifeType
    let onAdd: (LifeRecord) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var type: LifeRecord.LifeType
    @State private var value: String = ""
    @State private var note = ""

    init(defaultType: LifeRecord.LifeType, onAdd: @escaping (LifeRecord) -> Void) {
        self.defaultType = defaultType
        self.onAdd = onAdd
        _type = State(initialValue: defaultType)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("类型") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(LifeRecord.LifeType.allCases, id: \.self) { t in
                            Button(action: { type = t; value = "" }) {
                                VStack(spacing: 4) {
                                    Image(systemName: t.icon)
                                        .font(.title3)
                                    Text(t.rawValue)
                                        .font(.caption2)
                                }
                                .foregroundColor(type == t ? .white : t.color)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(type == t ? t.color : t.color.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                Section("数值") {
                    HStack {
                        TextField("0", text: $value)
                            .keyboardType(.decimalPad)
                            .font(.title2)

                        Text(type.defaultUnit)
                            .foregroundColor(.secondary)
                    }
                }

                Section("备注") {
                    TextField("添加备注（可选）", text: $note)
                }
            }
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let valueNum = Double(value) else { return }
                        let record = LifeRecord(
                            type: type,
                            value: valueNum,
                            unit: type.defaultUnit,
                            note: note
                        )
                        onAdd(record)
                        dismiss()
                    }
                    .disabled(value.isEmpty)
                }
            }
        }
    }
}

struct LifeTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        LifeTrackingView()
    }
}
