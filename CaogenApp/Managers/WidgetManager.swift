/**
 * Widget 小组件 - 主屏小组件
 * 天气小组件、记账小组件、习惯小组件、日程小组件
 */

import SwiftUI
import WidgetKit

/// 天气小组件
struct WeatherWidget: View {
    let entry: WeatherEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForWeather(entry.condition))
                    .font(.title2)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(entry.temperature))°C")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(entry.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(entry.condition)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Label("湿度: \(Int(entry.humidity))%", systemImage: "drop.fill")
                    .font(.caption)

                Spacer()

                Text(entry.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private func iconForWeather(_ condition: String) -> String {
        switch condition.lowercased() {
        case "晴天", "sunny":
            return "sun.max.fill"
        case "多云", "cloudy":
            return "cloud.sun.fill"
        case "下雨", "rainy":
            return "cloud.rain.fill"
        case "下雪", "snowy":
            return "snow"
        default:
            return "cloud.fill"
        }
    }
}

/// 天气数据
struct WeatherEntry: TimelineEntry {
    let date: Date
    let location: String
    let temperature: Double
    let condition: String
    let humidity: Double
    let time: String
}

/// 天气小组件提供者
struct WeatherWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(
            date: Date(),
            location: "北京",
            temperature: 20.0,
            condition: "晴天",
            humidity: 50.0,
            time: "12:00"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        let entry = WeatherEntry(
            date: Date(),
            location: "北京",
            temperature: 22.0,
            condition: "多云",
            humidity: 55.0,
            time: getCurrentTime()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let entries: [WeatherEntry] = [
            WeatherEntry(
                date: Date(),
                location: "北京",
                temperature: 22.0,
                condition: "多云",
                humidity: 55.0,
                time: getCurrentTime()
            ),
            WeatherEntry(
                date: Date().addingTimeInterval(3600),
                location: "北京",
                temperature: 23.0,
                condition: "晴天",
                humidity: 50.0,
                time: getCurrentTime()
            ),
            WeatherEntry(
                date: Date().addingTimeInterval(7200),
                location: "北京",
                temperature: 21.0,
                condition: "多云",
                humidity: 60.0,
                time: getCurrentTime()
            )
        ]

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

/// 记账小组件
struct ExpenseWidget: View {
    let entry: ExpenseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("今日消费")
                        .font(.headline)

                    Text("¥\(String(format: "%.2f", entry.todayAmount))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                Spacer()

                Text("\(entry.transactions)笔")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Label("本月: ¥\(String(format: "%.0f", entry.monthAmount))", systemImage: "calendar")
                    .font(.caption)

                Spacer()

                Text(entry.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

/// 记账数据
struct ExpenseEntry: TimelineEntry {
    let date: Date
    let todayAmount: Double
    let monthAmount: Double
    let transactions: Int
    let time: String
}

/// 记账小组件提供者
struct ExpenseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExpenseEntry {
        ExpenseEntry(
            date: Date(),
            todayAmount: 120.50,
            monthAmount: 2500.0,
            transactions: 3,
            time: "12:00"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ExpenseEntry) -> Void) {
        let entry = ExpenseEntry(
            date: Date(),
            todayAmount: 85.00,
            monthAmount: 1800.0,
            transactions: 2,
            time: getCurrentTime()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExpenseEntry>) -> Void) {
        let entries: [ExpenseEntry] = [
            ExpenseEntry(
                date: Date(),
                todayAmount: 85.00,
                monthAmount: 1800.0,
                transactions: 2,
                time: getCurrentTime()
            ),
            ExpenseEntry(
                date: Date().addingTimeInterval(1800),
                todayAmount: 145.00,
                monthAmount: 1860.0,
                transactions: 3,
                time: getCurrentTime()
            ),
            ExpenseEntry(
                date: Date().addingTimeInterval(3600),
                todayAmount: 200.00,
                monthAmount: 1915.0,
                transactions: 4,
                time: getCurrentTime()
            )
        ]

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

/// 习惯小组件
struct HabitWidget: View {
    let entry: HabitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(entry.completed ? .green : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.habitName)
                        .font(.headline)

                    Text("连续 \(entry.streak) 天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if entry.completed {
                    Text("✓")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                } else {
                    Text(entry.progress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack {
                Label("目标: \(entry.target)次/天", systemImage: "target")
                    .font(.caption)

                Spacer()

                Text(entry.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

/// 习惯数据
struct HabitEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let completed: Bool
    let streak: Int
    let progress: String
    let target: Int
    let time: String
}

/// 习惯小组件提供者
struct HabitWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(
            date: Date(),
            habitName: "喝水",
            completed: true,
            streak: 7,
            progress: "8/8",
            target: 8,
            time: "12:00"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        let entry = HabitEntry(
            date: Date(),
            habitName: "运动",
            completed: false,
            streak: 5,
            progress: "1/1",
            target: 1,
            time: getCurrentTime()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let habits = ["喝水", "运动", "阅读", "早睡"]

        let entries = habits.map { habit in
            HabitEntry(
                date: Date(),
                habitName: habit,
                completed: Bool.random(),
                streak: Int.random(in: 1...30),
                progress: "\(Int.random(in: 1...8))/8",
                target: 8,
                time: getCurrentTime()
            )
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

/// 日程小组件
struct ScheduleWidget: View {
    let entry: ScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("今日日程")
                        .font(.headline)

                    Text("\(entry.eventCount) 个安排")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(entry.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            if let nextEvent = entry.nextEvent {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)

                        Text(nextEvent.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(nextEvent.time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("今天没有安排")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

/// 日程数据
struct ScheduleEntry: TimelineEntry {
    let date: Date
    let eventCount: Int
    let nextEvent: Event?
    let time: String
}

/// 事件
struct Event {
    let title: String
    let time: String
}

/// 日程小组件提供者
struct ScheduleWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            eventCount: 3,
            nextEvent: Event(title: "会议", time: "14:00"),
            time: "12:00"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let entry = ScheduleEntry(
            date: Date(),
            eventCount: 2,
            nextEvent: Event(title: "周报", time: "15:00"),
            time: getCurrentTime()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let events = [
            Event(title: "会议", time: "14:00"),
            Event(title: "周报", time: "15:00"),
            Event(title: "运动", time: "18:00"),
            Event(title: "晚餐", time: "19:00")
        ]

        let entries = [
            ScheduleEntry(
                date: Date(),
                eventCount: events.count,
                nextEvent: events.first,
                time: getCurrentTime()
            ),
            ScheduleEntry(
                date: Date().addingTimeInterval(1800),
                eventCount: events.count,
                nextEvent: events[safe: 1],
                time: getCurrentTime()
            ),
            ScheduleEntry(
                date: Date().addingTimeInterval(3600),
                eventCount: events.count,
                nextEvent: events[safe: 2],
                time: getCurrentTime()
            )
        ]

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

/// Array 扩展
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

/// Widget 配置视图
struct WidgetConfigurationView: View {
    var body: some View {
        List {
            Section(header: Text("可用小组件")) {
                NavigationLink(destination: WeatherWidgetDetailView()) {
                    Label("天气小组件", systemImage: "cloud.sun.fill")
                }

                NavigationLink(destination: ExpenseWidgetDetailView()) {
                    Label("记账小组件", systemImage: "dollarsign.circle.fill")
                }

                NavigationLink(destination: HabitWidgetDetailView()) {
                    Label("习惯小组件", systemImage: "checkmark.circle.fill")
                }

                NavigationLink(destination: ScheduleWidgetDetailView()) {
                    Label("日程小组件", systemImage: "calendar")
                }
            }
        }
        .navigationTitle("小组件设置")
    }
}

/// 天气小组件详情
struct WeatherWidgetDetailView: View {
    var body: some View {
        WeatherWidget(entry: WeatherWidgetProvider().placeholder(in: Context()))
            .padding()
            .navigationTitle("天气小组件")
    }
}

/// 记账小组件详情
struct ExpenseWidgetDetailView: View {
    var body: some View {
        ExpenseWidget(entry: ExpenseWidgetProvider().placeholder(in: Context()))
            .padding()
            .navigationTitle("记账小组件")
    }
}

/// 习惯小组件详情
struct HabitWidgetDetailView: View {
    var body: some View {
        HabitWidget(entry: HabitWidgetProvider().placeholder(in: Context()))
            .padding()
            .navigationTitle("习惯小组件")
    }
}

/// 日程小组件详情
struct ScheduleWidgetDetailView: View {
    var body: some View {
        ScheduleWidget(entry: ScheduleWidgetProvider().placeholder(in: Context()))
            .padding()
            .navigationTitle("日程小组件")
    }
}
