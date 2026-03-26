//
//  AutomationManager.swift
//  CaogenApp
//
//  Created by Caogen Team on 2026-03-26.
//  自动化系统 - 学习用户习惯，自动执行任务
//

import Foundation
import Combine

// MARK: - Automation Trigger
enum AutomationTrigger: String, CaseIterable {
    case time         // 时间触发
    case location     // 位置触发
    case event        // 事件触发
    case condition    // 条件触发
    case manual       // 手动触发
}

// MARK: - Automation Action
enum AutomationAction: String, CaseIterable {
    case pushNotification   // 推送通知
    case showMessage         // 显示消息
    case executeCommand     // 执行命令
    case openApp            // 打开应用
    case sendRequest        // 发送请求
    case updateData         // 更新数据
    case recordAction       // 记录动作
}

// MARK: - Automation Task
struct AutomationTask: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let trigger: AutomationTrigger
    let triggerCondition: String
    let action: AutomationAction
    let actionData: [String: String]
    var isEnabled: Bool
    var executionCount: Int
    let lastExecuted: Date?
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, description: String, trigger: AutomationTrigger, triggerCondition: String, action: AutomationAction, actionData: [String: String] = [:], isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.trigger = trigger
        self.triggerCondition = triggerCondition
        self.action = action
        self.actionData = actionData
        self.isEnabled = isEnabled
        self.executionCount = 0
        self.lastExecuted = nil
        self.createdAt = Date()
    }
}

// MARK: - Automation Manager
@MainActor
class AutomationManager: ObservableObject {
    static let shared = AutomationManager()
    
    @Published private(set) var automationTasks: [AutomationTask] = []
    @Published private(set) var executionHistory: [AutomationTask] = []
    @Published private(set) var isAutomationEngineRunning = false
    @Published private(set) var learnedPatterns: [String: Int] = [:]
    
    private let deepMemory = DeepMemoryManager.shared
    private let predictionAI = PredictionAIManager.shared
    
    private init() {
        setupDefaultAutomations()
        loadAutomationTasks()
        startAutomationEngine()
    }
    
    // MARK: - Setup Default Automations
    
    private func setupDefaultAutomations() {
        automationTasks = [
            // 天气查询自动化
            AutomationTask(
                name: "自动天气查询",
                description: "每天早上7点自动查询天气",
                trigger: .time,
                triggerCondition: "time == 07:00",
                action: .executeCommand,
                actionData: ["command": "query_weather"],
                isEnabled: false
            ),
            
            // 日程查询自动化
            AutomationTask(
                name: "自动日程查询",
                description: "每天早上8点自动查询日程",
                trigger: .time,
                triggerCondition: "time == 08:00",
                action: .executeCommand,
                actionData: ["command": "query_schedule"],
                isEnabled: false
            ),
            
            // 早睡提醒自动化
            AutomationTask(
                name: "自动早睡提醒",
                description: "每天晚上9点自动提醒早睡",
                trigger: .time,
                triggerCondition: "time == 21:00",
                action: .pushNotification,
                actionData: ["title": "该休息了", "message": "晚上好！早点休息，不要熬夜哦~"],
                isEnabled: false
            ),
            
            // 运动提醒自动化
            AutomationTask(
                name: "自动运动提醒",
                description: "每天下午5点自动提醒运动",
                trigger: .time,
                triggerCondition: "time == 17:00",
                action: .pushNotification,
                actionData: ["title": "运动时间", "message": "该运动了！每天运动保持健康~"],
                isEnabled: false
            ),
            
            // 外卖推荐自动化
            AutomationTask(
                name: "自动外卖推荐",
                description: "每周五晚上自动推荐外卖",
                trigger: .time,
                triggerCondition: "time == 18:00 && weekday == friday",
                action: .sendMessage,
                actionData: ["message": "周末要出去玩吗？我帮你推荐一些好吃的吧~"],
                isEnabled: false
            ),
            
            // 音乐推荐自动化
            AutomationTask(
                name: "自动音乐推荐",
                description: "每天晚上9点自动推荐音乐",
                trigger: .time,
                triggerCondition: "time == 21:00",
                action: .sendMessage,
                actionData: ["message": "准备休息了！推荐一些放松的音乐吧~"],
                isEnabled: false
            ),
            
            // 带伞提醒自动化
            AutomationTask(
                name: "自动带伞提醒",
                description: "预测下雨时自动提醒带伞",
                trigger: .condition,
                triggerCondition: "weather == rain",
                action: .pushNotification,
                actionData: ["title": "下雨提醒", "message": "今天会下雨，记得带伞！"],
                isEnabled: false
            )
        ]
        
        saveAutomationTasks()
    }
    
    // MARK: - Automation Engine
    
    /// 启动自动化引擎
    private func startAutomationEngine() {
        isAutomationEngineRunning = true
        
        // 定时检查自动化触发条件
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                self.checkAutomationTriggers()
            }
        }
        
        // 学习用户习惯
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in
                self.learnUserPatterns()
            }
        }
        
        print("🔄 自动化引擎已启动")
    }
    
    /// 检查自动化触发条件
    private func checkAutomationTriggers() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        for task in automationTasks where task.isEnabled {
            var shouldExecute = false
            
            switch task.trigger {
            case .time:
                // 检查时间条件
                if task.triggerCondition.contains("time ==") {
                    let timeStr = task.triggerCondition.replacingOccurrences(of: "time == ", with: "")
                    if timeStr.contains(":") {
                        let components = timeStr.split(separator: ":").compactMap { Int($0) }
                        if components.count == 2 {
                            shouldExecute = (hour == components[0] && minute == components[1])
                        }
                    }
                }
                
                // 检查星期条件
                if task.triggerCondition.contains("weekday") {
                    if weekday == 5 && task.triggerCondition.contains("friday") {
                        shouldExecute = true
                    }
                }
                
            case .condition:
                // 检查条件
                if task.triggerCondition.contains("weather") {
                    if let weather = deepMemory.retrieve(key: "current_weather", category: .preferences)?.value {
                        shouldExecute = task.triggerCondition.contains(weather)
                    }
                }
                
                // 检查其他条件
                if task.triggerCondition.contains("stayed_up_late") {
                    if let sleepTime = deepMemory.retrieve(key: "last_sleep_time", category: .habits)?.value {
                        shouldExecute = sleepTime.contains("熬夜")
                    }
                }
                
            case .event:
                // 检查事件
                if task.triggerCondition.contains("meeting") {
                    if let upcomingMeeting = deepMemory.retrieve(key: "upcoming_meeting", category: .events)?.value {
                        shouldExecute = !upcomingMeeting.isEmpty
                    }
                }
                
            default:
                break
            }
            
            // 执行任务
            if shouldExecute {
                executeTask(task)
            }
        }
    }
    
    // MARK: - Execute Task
    
    /// 执行自动化任务
    private func executeTask(_ task: AutomationTask) {
        // 检查是否最近已经执行过（避免频繁执行）
        if let lastExecuted = task.lastExecuted {
            let minutesSinceExecution = Date().timeIntervalSince(lastExecuted) / 60
            if minutesSinceExecution < 60 { // 1小时内不重复执行
                return
            }
        }
        
        // 更新执行记录
        if let index = automationTasks.firstIndex(where: { $0.id == task.id }) {
            automationTasks[index].executionCount += 1
            
            // 添加到执行历史
            executionHistory.append(automationTasks[index])
            
            // 只保留最近100条执行记录
            if executionHistory.count > 100 {
                executionHistory = Array(executionHistory.suffix(100))
            }
            
            print("🔄 执行自动化：\(task.name)")
            
            // 执行动作
            switch task.action {
            case .pushNotification:
                sendPushNotification(title: task.actionData["title"] ?? "", message: task.actionData["message"] ?? "")
                
            case .showMessage:
                showNotification(title: task.actionData["title"] ?? "", message: task.actionData["message"] ?? "")
                
            case .executeCommand:
                executeCommand(command: task.actionData["command"] ?? "")
                
            case .sendMessage:
                sendMessage(message: task.actionData["message"] ?? "")
                
            case .openApp:
                openApp(appName: task.actionData["appName"] ?? "")
                
            case .updateData:
                updateData(key: task.actionData["key"] ?? "", value: task.actionData["value"] ?? "")
                
            case .recordAction:
                recordAction(action: task.actionData["action"] ?? "")
            }
            
            saveAutomationTasks()
        }
    }
    
    // MARK: - Action Implementations
    
    private func sendPushNotification(title: String, message: String) {
        // 这里实现推送通知
        print("📱 推送通知：\(title) - \(message)")
    }
    
    private func showNotification(title: String, message: String) {
        // 这里实现显示通知
        print("💬 显示通知：\(title) - \(message)")
    }
    
    private func executeCommand(command: String) {
        // 这里实现命令执行
        print("⚡ 执行命令：\(command)")
    }
    
    private func sendMessage(message: String) {
        // 这里实现发送消息
        print("💬 发送消息：\(message)")
    }
    
    private func openApp(appName: String) {
        // 这里实现打开应用
        print("📱 打开应用：\(appName)")
    }
    
    private func updateData(key: String, value: String) {
        // 这里实现更新数据
        print("📊 更新数据：\(key) = \(value)")
    }
    
    private func recordAction(action: String) {
        // 这里实现记录动作
        print("📝 记录动作：\(action)")
    }
    
    // MARK: - Learn User Patterns
    
    /// 学习用户模式
    private func learnUserPatterns() {
        // 学习用户查询天气的习惯
        let weatherQueries = deepMemory.search(query: "天气", category: .habits)
        if weatherQueries.count >= 3 {
            learnedPatterns["weather_query"] = weatherQueries.count
            
            // 自动创建天气查询自动化
            if learnedPatterns["weather_query"] == 3 {
                createAutomationFromPattern("天气查询", "weather", "query_weather", .pushNotification)
            }
        }
        
        // 学习用户查询日程的习惯
        let scheduleQueries = deepMemory.search(query: "日程", category: .habits)
        if scheduleQueries.count >= 3 {
            learnedPatterns["schedule_query"] = scheduleQueries.count
            
            if learnedPatterns["schedule_query"] == 3 {
                createAutomationFromPattern("日程查询", "schedule", "query_schedule", .pushNotification)
            }
        }
        
        // 学习用户点外卖的习惯
        let foodOrders = deepMemory.search(query: "外卖", category: .habits)
        if foodOrders.count >= 3 {
            learnedPatterns["food_order"] = foodOrders.count
        }
        
        // 学习用户听音乐的习惯
        let musicListens = deepMemory.search(query: "音乐", category: .habits)
        if musicListens.count >= 3 {
            learnedPatterns["music_listen"] = musicListens.count
        }
        
        print("🧠 学习用户模式：\(learnedPatterns)")
    }
    
    /// 从模式创建自动化
    private func createAutomationFromPattern(name: String, triggerType: String, actionCommand: String, action: AutomationAction) {
        let task = AutomationTask(
            name: "自动\(name)",
            description: "根据你的习惯，自动\(name)",
            trigger: .time,
            triggerCondition: "time == auto",
            action: action,
            actionData: ["command": actionCommand],
            isEnabled: false
        )
        
        automationTasks.append(task)
        saveAutomationTasks()
        
        print("🎯 自动创建自动化：\(name)")
    }
    
    // MARK: - Custom Automation
    
    /// 添加自定义自动化任务
    func addCustomAutomationTask(name: String, description: String, trigger: AutomationTrigger, triggerCondition: String, action: AutomationAction, actionData: [String: String] = [:]) {
        let task = AutomationTask(
            name: name,
            description: description,
            trigger: trigger,
            triggerCondition: triggerCondition,
            action: action,
            actionData: actionData
        )
        
        automationTasks.append(task)
        saveAutomationTasks()
    }
    
    /// 删除自动化任务
    func removeAutomationTask(id: UUID) {
        automationTasks.removeAll { $0.id == id }
        saveAutomationTasks()
    }
    
    /// 启用/禁用自动化任务
    func toggleAutomationTask(id: UUID) {
        if let index = automationTasks.firstIndex(where: { $0.id == id }) {
            automationTasks[index].isEnabled.toggle()
            saveAutomationTasks()
        }
    }
    
    // MARK: - Persistence
    
    private func saveAutomationTasks() {
        guard let data = try? JSONEncoder().encode(automationTasks) else { return }
        UserDefaults.standard.set(data, forKey: "caogen_automation_tasks")
    }
    
    private func loadAutomationTasks() {
        guard let data = UserDefaults.standard.data(forKey: "caogen_automation_tasks"),
              let tasks = try? JSONDecoder().decode([AutomationTask].self, from: data) else {
            return
        }
        
        automationTasks = tasks
    }
    
    /// 清除自动化任务
    func clearAutomationTasks() {
        automationTasks.removeAll()
        executionHistory.removeAll()
        learnedPatterns.removeAll()
        saveAutomationTasks()
    }
}
