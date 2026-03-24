import SwiftUI
import Charts

// 健康记录模型
struct HealthRecord: Identifiable, Codable {
    let id: UUID
    var type: HealthType
    var value: Double
    var secondaryValue: Double? // 如舒张压
    var unit: String
    var notes: String
    var tags: [String]
    var createdAt: Date

    enum HealthType: String, Codable, CaseIterable {
        case bloodPressure = "血压"
        case bloodSugar = "血糖"
        case heartRate = "心率"
        case temperature = "体温"
        case weight = "体重"
        case oxygen = "血氧"

        var unit: String {
            switch self {
            case .bloodPressure: return "mmHg"
            case .bloodSugar: return "mmol/L"
            case .heartRate: return "bpm"
            case .temperature: return "°C"
            case .weight: return "kg"
            case .oxygen: return "%"
            }
        }

        var icon: String {
            switch self {
            case .bloodPressure: return "heart.fill"
            case .bloodSugar: return "drop.fill"
            case .heartRate: return "waveform.path.ecg"
            case .temperature: return "thermometer"
            case .weight: return "scalemass.fill"
            case .oxygen: return "lungs.fill"
            }
        }

        var normalRange: ClosedRange<Double> {
            switch self {
            case .bloodPressure: return 90...140
            case .bloodSugar: return 3.9...6.1
            case .heartRate: return 60...100
            case .temperature: return 36.1...37.2
            case .weight: return 40...120
            case .oxygen: return 95...100
            }
        }
    }

    init(type: HealthType, value: Double, secondaryValue: Double? = nil, notes: String = "", tags: [String] = []) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.secondaryValue = secondaryValue
        self.unit = type.unit
        self.notes = notes
        self.tags = tags
        self.createdAt = Date()
    }

    var isNormal: Bool {
        type.normalRange.contains(value)
    }
}

// 健康管理器
class HealthManager: ObservableObject {
    @Published var records: [HealthRecord] = []
    @State private var isLoading = false

    init() {
        loadRecords()
    }

    // 加载记录
    func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: "health_records"),
           let decoded = try? JSONDecoder().decode([HealthRecord].self, from: data) {
            records = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // 保存记录
    func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: "health_records")
        }
    }

    // 添加记录
    func addRecord(_ record: HealthRecord) {
        records.insert(record, at: 0)
        saveRecords()
    }

    // 删除记录
    func deleteRecord(_ record: HealthRecord) {
        records.removeAll { $0.id == record.id }
        saveRecords()
    }

    // 获取最新记录
    func getLatestRecord(for type: HealthRecord.HealthType) -> HealthRecord? {
        return records.first { $0.type == type }
    }

    // 获取趋势数据
    func getTrendData(for type: HealthRecord.HealthType, days: Int = 7) -> [HealthRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return records
            .filter { $0.type == type && $0.createdAt >= cutoffDate }
            .sorted { $0.createdAt < $1.createdAt }
    }

    // 获取统计数据
    func getStatistics(for type: HealthRecord.HealthType, days: Int = 30) -> HealthStatistics {
        let trendData = getTrendData(for: type, days: days)

        guard !trendData.isEmpty else {
            return HealthStatistics(count: 0, average: 0, min: 0, max: 0, trend: .stable)
        }

        let values = trendData.map { $0.value }
        let average = values.reduce(0, +) / Double(values.count)
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0

        // 计算趋势
        let trend: HealthTrend
        if trendData.count >= 2 {
            let first = values.first!
            let last = values.last!
            let change = ((last - first) / first) * 100

            if change > 5 {
                trend = .up
            } else if change < -5 {
                trend = .down
            } else {
                trend = .stable
            }
        } else {
            trend = .stable
        }

        return HealthStatistics(
            count: values.count,
            average: average,
            min: minVal,
            max: maxVal,
            trend: trend
        )
    }

    // 获取今日记录
    func getTodayRecords() -> [HealthRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        return records.filter { $0.createdAt >= today }
    }
}

struct HealthStatistics {
    let count: Int
    let average: Double
    let min: Double
    let max: Double
    let trend: HealthTrend
}

enum HealthTrend: String {
    case up = "上升"
    case down = "下降"
    case stable = "稳定"
}

// 健康数据视图
struct HealthView: View {
    @StateObject private var healthManager = HealthManager()
    @State private var selectedType: HealthRecord.HealthType = .bloodPressure
    @State private var showingAddRecord = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 快速记录卡片
                    QuickRecordCards(
                        selectedType: $selectedType,
                        onAdd: { showingAddRecord = true }
                    )

                    // 今日数据
                    TodayHealthSection(records: healthManager.getTodayRecords())

                    // 趋势图表
                    TrendChartSection(
                        type: selectedType,
                        records: healthManager.getTrendData(for: selectedType)
                    )

                    // 统计数据
                    StatisticsSection(
                        type: selectedType,
                        stats: healthManager.getStatistics(for: selectedType)
                    )

                    // 历史记录
                    HistorySection(
                        records: healthManager.records.filter { $0.type == selectedType },
                        onDelete: { healthManager.deleteRecord($0) }
                    )
                }
                .padding()
            }
            .navigationTitle("💊 健康数据")
            .sheet(isPresented: $showingAddRecord) {
                AddHealthRecordSheet(
                    type: selectedType,
                    onSave: { record in
                        healthManager.addRecord(record)
                    }
                )
            }
        }
    }
}

// 快速记录卡片
struct QuickRecordCards: View {
    @Binding var selectedType: HealthRecord.HealthType
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速记录")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HealthRecord.HealthType.allCases, id: \.self) { type in
                        QuickRecordCard(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
}

struct QuickRecordCard: View {
    let type: HealthRecord.HealthType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .green)

                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding()
            .frame(width: 80)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// 今日数据
struct TodayHealthSection: View {
    let records: [HealthRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日数据")
                .font(.headline)

            if records.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("暂无记录")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(records.prefix(4)) { record in
                        HealthValueCard(record: record)
                    }
                }
            }
        }
    }
}

struct HealthValueCard: View {
    let record: HealthRecord

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: record.type.icon)
                    .foregroundColor(.green)
                Text(record.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let secondary = record.secondaryValue {
                Text("\(Int(record.value))/\(Int(secondary))")
                    .font(.title2)
                    .fontWeight(.bold)
            } else {
                Text(String(format: "%.1f", record.value))
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text(record.type.unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(record.isNormal ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// 趋势图表
struct TrendChartSection: View {
    let type: HealthRecord.HealthType
    let records: [HealthRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("趋势")
                .font(.headline)

            if records.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                // 简化图表（实际使用 Charts 框架）
                ChartView(records: records)
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
}

// 简化图表视图
struct ChartView: View {
    let records: [HealthRecord]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            if records.count > 1 {
                let maxValue = records.map { $0.value }.max() ?? 100
                let minValue = records.map { $0.value }.min() ?? 0
                let range = maxValue - minValue

                Path { path in
                    for (index, record) in records.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(records.count - 1)
                        let y = height - (height * CGFloat((record.value - minValue) / range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.green, lineWidth: 2)
            }
        }
    }
}

// 统计数据
struct StatisticsSection: View {
    let type: HealthRecord.HealthType
    let stats: HealthStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("统计")
                .font(.headline)

            HStack(spacing: 12) {
                StatCard(title: "平均", value: String(format: "%.1f", stats.average), unit: type.unit)
                StatCard(title: "最低", value: String(format: "%.1f", stats.min), unit: type.unit)
                StatCard(title: "最高", value: String(format: "%.1f", stats.max), unit: type.unit)
                StatCard(title: "趋势", value: stats.trend.rawValue, unit: "", isTrend: true)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    var isTrend: Bool = false

    var trendColor: Color {
        switch value {
        case "上升": return .red
        case "下降": return .blue
        default: return .green
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .foregroundColor(isTrend ? trendColor : .primary)

            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 历史记录
struct HistorySection: View {
    let records: [HealthRecord]
    let onDelete: (HealthRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史记录")
                .font(.headline)

            if records.isEmpty {
                Text("暂无记录")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(records.prefix(10)) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.createdAt, style: .date)
                                .font(.subheadline)
                            if let secondary = record.secondaryValue {
                                Text("\(Int(record.value))/\(Int(secondary)) \(record.unit)")
                                    .font(.caption)
                            } else {
                                Text("\(String(format: "%.1f", record.value)) \(record.unit)")
                                    .font(.caption)
                            }
                        }

                        Spacer()

                        Image(systemName: record.isNormal ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(record.isNormal ? .green : .red)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// 添加健康记录弹窗
struct AddHealthRecordSheet: View {
    let type: HealthRecord.HealthType
    let onSave: (HealthRecord) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var value: String = ""
    @State private var secondaryValue: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("数值") {
                    if type == .bloodPressure {
                        HStack {
                            TextField("收缩压", text: $value)
                            Text("mmHg")
                                .foregroundColor(.secondary)
                        }
                        TextField("舒张压（可选）", text: $secondaryValue)
                    } else {
                        HStack {
                            TextField("数值", text: $value)
                            Text(type.unit)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("备注") {
                    TextField("添加备注（可选）", text: $notes)
                }

                Section("正常范围") {
                    Text("\(Int(type.normalRange.lowerBound)) - \(Int(type.normalRange.upperBound)) \(type.unit)")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("记录\(type.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let mainValue = Double(value) else { return }
                        let secondary = Double(secondaryValue)
                        let record = HealthRecord(
                            type: type,
                            value: mainValue,
                            secondaryValue: secondary,
                            notes: notes
                        )
                        onSave(record)
                        dismiss()
                    }
                    .disabled(value.isEmpty)
                }
            }
        }
    }
}

// 预览
struct HealthView_Previews: PreviewProvider {
    static var previews: some View {
        HealthView()
    }
}
