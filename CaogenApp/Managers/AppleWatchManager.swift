/**
 * Apple Watch - 手表端支持
 * 通知提醒、运动记录、健康数据同步、语音回复
 */

import SwiftUI
import WatchConnectivity
import HealthKit

/// Apple Watch 管理器
class AppleWatchManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isPaired = false
    @Published var isReachable = false
    @Published var isWatchAppInstalled = false
    @Published var notifications: [WatchNotification] = []
    @Published var exerciseData: ExerciseData?
    @Published var healthData: HealthData?

    private let session = WCSession.default

    override init() {
        super.init()
        setupSession()
    }

    /// 设置会话
    private func setupSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPaired = activationState == .activated
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPaired = false
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPaired = false
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleWatchMessage(message)
    }

    /// 处理手表消息
    private func handleWatchMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "notification":
            if let notification = WatchNotification(from: message) {
                DispatchQueue.main.async {
                    self.notifications.append(notification)
                }
            }

        case "exercise":
            if let exercise = ExerciseData(from: message) {
                DispatchQueue.main.async {
                    self.exerciseData = exercise
                }
            }

        case "health":
            if let health = HealthData(from: message) {
                DispatchQueue.main.async {
                    self.healthData = health
                }
            }

        default:
            break
        }
    }

    /// 发送消息到手表
    func sendMessageToWatch(_ message: [String: Any]) {
        guard session.isReachable else { return }

        session.sendMessage(message, replyHandler: { reply in
            print("✅ 手表响应: \(reply)")
        }) { error in
            print("❌ 发送失败: \(error)")
        }
    }

    /// 发送通知到手表
    func sendNotification(_ title: String, body: String, category: NotificationCategory = .general) {
        let message: [String: Any] = [
            "type": "notification",
            "title": title,
            "body": body,
            "category": category.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]

        sendMessageToWatch(message)
    }

    /// 同步健康数据到手表
    func syncHealthData(_ data: HealthData) {
        let message: [String: Any] = [
            "type": "health",
            "heartRate": data.heartRate,
            "steps": data.steps,
            "calories": data.calories,
            "distance": data.distance,
            "timestamp": Date().timeIntervalSince1970
        ]

        sendMessageToWatch(message)
    }

    /// 同步运动数据到手表
    func syncExerciseData(_ data: ExerciseData) {
        let message: [String: Any] = [
            "type": "exercise",
            "duration": data.duration,
            "type": data.type.rawValue,
            "calories": data.calories,
            "distance": data.distance,
            "timestamp": Date().timeIntervalSince1970
        ]

        sendMessageToWatch(message)
    }

    /// 请求健康数据
    func requestHealthData() {
        let message: [String: Any] = [
            "type": "request_health"
        ]

        sendMessageToWatch(message)
    }

    /// 请求运动数据
    func requestExerciseData() {
        let message: [String: Any] = [
            "type": "request_exercise"
        ]

        sendMessageToWatch(message)
    }
}

/// 手表通知
struct WatchNotification: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let category: NotificationCategory
    let timestamp: Date

    init?(from message: [String: Any]) {
        guard let title = message["title"] as? String,
              let body = message["body"] as? String,
              let categoryRaw = message["category"] as? String,
              let category = NotificationCategory(rawValue: categoryRaw),
              let timestamp = message["timestamp"] as? TimeInterval else {
            return nil
        }

        self.title = title
        self.body = body
        self.category = category
        self.timestamp = Date(timeIntervalSince1970: timestamp)
    }
}

/// 通知分类
enum NotificationCategory: String {
    case general
    case health
    case exercise
    case reminder
    case message
}

/// 运动数据
struct ExerciseData {
    let duration: TimeInterval
    let type: ExerciseType
    let calories: Double
    let distance: Double
    let heartRate: Int?

    init?(from message: [String: Any]) {
        guard let duration = message["duration"] as? TimeInterval,
              let typeRaw = message["type"] as? String,
              let type = ExerciseType(rawValue: typeRaw),
              let calories = message["calories"] as? Double,
              let distance = message["distance"] as? Double else {
            return nil
        }

        self.duration = duration
        self.type = type
        self.calories = calories
        self.distance = distance
        self.heartRate = message["heartRate"] as? Int
    }
}

/// 运动类型
enum ExerciseType: String {
    case running
    case walking
    case cycling
    case swimming
    case yoga
    case strength
}

/// 健康数据
struct HealthData {
    let heartRate: Int
    let steps: Int
    let calories: Double
    let distance: Double

    init?(from message: [String: Any]) {
        guard let heartRate = message["heartRate"] as? Int,
              let steps = message["steps"] as? Int,
              let calories = message["calories"] as? Double,
              let distance = message["distance"] as? Double else {
            return nil
        }

        self.heartRate = heartRate
        self.steps = steps
        self.calories = calories
        self.distance = distance
    }
}

/// Apple Watch 视图
struct AppleWatchView: View {
    @StateObject private var manager = AppleWatchManager()

    var body: some View {
        List {
            Section(header: Text("连接状态")) {
                HStack {
                    Image(systemName: manager.isPaired ? "applewatch" : "applewatch.slash")
                        .foregroundColor(manager.isPaired ? .green : .gray)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(manager.isPaired ? "已连接" : "未连接")
                            .font(.headline)

                        Text(manager.isReachable ? "可响应" : "不可响应")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("健康数据")) {
                if let healthData = manager.healthData {
                    HStack {
                        Label("\(healthData.heartRate) bpm", systemImage: "heart.fill")
                            .foregroundColor(.red)
                    }

                    HStack {
                        Label("\(healthData.steps) 步", systemImage: "figure.walk")
                    }

                    HStack {
                        Label("\(Int(healthData.calories)) 卡", systemImage: "flame.fill")
                    }

                    HStack {
                        Label("\(String(format: "%.1f", healthData.distance)) km", systemImage: "location.fill")
                    }
                } else {
                    Button("获取健康数据") {
                        manager.requestHealthData()
                    }
                }
            }

            Section(header: Text("运动数据")) {
                if let exerciseData = manager.exerciseData {
                    HStack {
                        Label("\(exerciseData.duration / 60) 分钟", systemImage: "clock.fill")
                    }

                    HStack {
                        Label(exerciseTypeName(exerciseData.type), systemImage: "figure.run")
                    }

                    HStack {
                        Label("\(Int(exerciseData.calories)) 卡", systemImage: "flame.fill")
                    }
                } else {
                    Button("获取运动数据") {
                        manager.requestExerciseData()
                    }
                }
            }

            Section(header: Text("通知")) {
                if manager.notifications.isEmpty {
                    Text("暂无通知")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(manager.notifications) { notification in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(notification.title)
                                    .font(.headline)

                                Spacer()

                                Text(notification.category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }

                            Text(notification.body)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("⌚️ Apple Watch")
    }

    private func exerciseTypeName(_ type: ExerciseType) -> String {
        switch type {
        case .running: return "跑步"
        case .walking: return "步行"
        case .cycling: return "骑行"
        case .swimming: return "游泳"
        case .yoga: return "瑜伽"
        case .strength: return "力量训练"
        }
    }
}

/// 测试视图
struct AppleWatchTestView: View {
    @StateObject private var manager = AppleWatchManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("⌚️ Apple Watch 测试")
                .font(.title)

            if manager.isPaired {
                VStack(spacing: 16) {
                    Button("发送测试通知") {
                        manager.sendNotification("测试通知", "这是一条测试通知")
                    }

                    Button("发送健康提醒") {
                        manager.sendNotification("健康提醒", "该运动了！", category: .health)
                    }

                    Button("发送运动提醒") {
                        manager.sendNotification("运动提醒", "今日运动目标完成 50%", category: .exercise)
                    }

                    Button("获取健康数据") {
                        manager.requestHealthData()
                    }
                }
            } else {
                Text("等待连接手表...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
