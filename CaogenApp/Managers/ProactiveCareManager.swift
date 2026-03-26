//
//  ProactiveCareManager.swift
//  CaogenApp
//
//  Created by Caogen Team on 2026-03-26.
//  主动关怀系统 - 在用户需要之前就已经准备好了
//

import Foundation
import Combine

// MARK: - Care Type
enum CareType: String, CaseIterable {
    case timeBased     // 基于时间的关怀
    case emotionBased   // 基于情绪的关怀
    case behaviorBased  // 基于行为的关怀
    case scenarioBased // 基于场景的关怀
    case needBased     // 基于需求的关怀
}

// MARK: - Care Action
struct CareAction: Identifiable, Codable {
    let id: UUID
    let type: CareType
    let title: String
    let message: String
    let triggerCondition: String
    let priority: Int // 1-10
    let lastTriggered: Date?
    var isEnabled: Bool
    var triggerCount: Int
    
    init(id: UUID = UUID(), type: CareType, title: String, message: String, triggerCondition: String, priority: Int, isEnabled: Bool = true) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.triggerCondition = triggerCondition
        self.priority = priority
        self.lastTriggered = nil
        self.isEnabled = isEnabled
        self.triggerCount = 0
    }
}

// MARK: - Proactive Care Manager
@MainActor
class ProactiveCareManager: ObservableObject {
    static let shared = ProactiveCareManager()
    
    @Published private(set) var careActions: [CareAction] = []
    @Published private(set) var triggeredActions: [CareAction] = []
    @Published private(set) var isCareEngineRunning = false
    
    private let deepMemory = DeepMemoryManager.shared
    private let emotionAI = EmotionAIManager.shared
    private let predictionAI = PredictionAIManager.shared
    
    private init() {
        setupDefaultCareActions()
        loadCareActions()
        startCareEngine()
    }
    
    // MARK: - Setup Default Actions
    
    private func setupDefaultCareActions() {
        careActions = [
            // 基于时间的关怀
            CareAction(
                type: .timeBased,
                title: "早安问候",
                message: "早上好！今天天气不错，记得吃早饭哦~",
                triggerCondition: "time == 07:00",
                priority: 8
            ),
            CareAction(
                type: .timeBased,
                title: "天气提醒",
                message: "今天会下雨，记得带伞！",
                triggerCondition: "weather == rain",
                priority: 9
            ),
            CareAction(
                type: .timeBased,
                title: "午休提醒",
                message: "中午了，记得按时吃饭哦~",
                triggerCondition: "time == 12:00",
                priority: 7
            ),
            CareAction(
                type: .timeBased,
                title: "下班提醒",
                message: "准备下班了，辛苦了！要不要帮你点外卖？",
                triggerCondition: "time == 18:00",
                priority: 8
            ),
            CareAction(
                type: .timeBased,
                title: "晚安提醒",
                message: "晚上好！早点休息，不要熬夜哦~",
                triggerCondition: "time == 21:00",
                priority: 7
            ),
            
            // 基于情绪的关怀
            CareAction(
                type: .emotionBased,
                title: "情绪低落关怀",
                message: "你今天心情不太好，需要我陪你聊聊天吗？",
                triggerCondition: "emotion == sad",
                priority: 9
            ),
            CareAction(
                type: .emotionBased,
                title: "压力疏导",
                message: "你最近压力很大吧？要不要我帮你放松一下？",
                triggerCondition: "emotion == stress",
                priority: 9
            ),
            CareAction(
                type: .emotionBased,
                title: "疲惫关怀",
                message: "累了吧？该休息了。要不要我给你讲个笑话？",
                triggerCondition: "emotion == tired",
                priority: 8
            ),
            
            // 基于行为的关怀
            CareAction(
                type: .behaviorBased,
                title: "熬夜提醒",
                message: "你昨晚熬夜了，今天注意休息哦~",
                triggerCondition: "behavior == stayed_up_late",
                priority: 8
            ),
            CareAction(
                type: .behaviorBased,
                title: "运动提醒",
                message: "你最近没运动，要不要我提醒你运动一下？",
                triggerCondition: "behavior == no_exercise",
                priority: 6
            ),
            CareAction(
                type: .behaviorBased,
                title: "饮食提醒",
                message: "你最近吃太多了，要注意控制饮食哦~",
                triggerCondition: "behavior == over_eating",
                priority: 6
            ),
            
            // 基于场景的关怀
            CareAction(
                type: .scenarioBased,
                title: "火车站提醒",
                message: "你在火车站吧？要注意安全，看好行李哦~",
                triggerCondition: "location == train_station",
                priority: 8
            ),
            CareAction(
                type: .scenarioBased,
                title: "医院提醒",
                message: "你在医院吧？希望没什么大问题。注意休息~",
                triggerCondition: "location == hospital",
                priority: 9
            ),
            CareAction(
                type: .scenarioBased,
                title: "机场提醒",
                message: "你在机场吧？提前1小时去机场，不要误机哦~",
                triggerCondition: "location == airport",
                priority: 8
            ),
            
            // 基于需求的关怀
            CareAction(
                type: .needBased,
                title: "点餐推荐",
                message: "到点吃饭了，要不要我帮你点个外卖？",
                triggerCondition: "need == food",
                priority: 7
            ),
            CareAction(
                type: .needBased,
                title: "日程提醒",
                message: "你有未完成的日程，需要我提醒你吗？",
                triggerCondition: "need == schedule",
                priority: 8
            ),
            CareAction(
                type: .needBased,
                title: "健康提醒",
                message: "该体检了，需要我帮你预约吗？",
                triggerCondition: "need == health_check",
                priority: 7
            )
        ]
        
        saveCareActions()
    }
    
    // MARK: - Care Engine
    
    /// 启动关怀引擎
    private func startCareEngine() {
        isCareEngineRunning = true
        
        // 定时检查关怀触发条件
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                self.checkCareTriggers()
            }
        }
        
        print("💡 主动关怀引擎已启动")
    }
    
    /// 检查关怀触发条件
    private func checkCareTriggers() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        for action in careActions where action.isEnabled {
            var shouldTrigger = false
            
            switch action.type {
            case .timeBased:
                // 检查时间条件
                if action.triggerCondition.contains("time ==") {
                    let timeStr = action.triggerCondition.replacingOccurrences(of: "time == ", with: "")
                    if timeStr.contains(":") {
                        let components = timeStr.split(separator: ":").compactMap { Int($0) }
                        if components.count == 2 {
                            shouldTrigger = (hour == components[0] && minute == components[1])
                        }
                    }
                }
                
                // 检查天气条件
                if action.triggerCondition.contains("weather") {
                    if let weather = deepMemory.retrieve(key: "current_weather", category: .preferences)?.value {
                        shouldTrigger = action.triggerCondition.contains(weather)
                    }
                }
                
            case .emotionBased:
                // 检查情绪条件
                if let currentEmotion = emotionAI.currentEmotion {
                    shouldTrigger = action.triggerCondition.contains(currentEmotion.rawValue)
                }
                
            case .behaviorBased:
                // 检查行为条件
                if action.triggerCondition.contains("stayed_up_late") {
                    if let sleepTime = deepMemory.retrieve(key: "last_sleep_time", category: .habits)?.value {
                        if sleepTime.contains("熬夜") {
                            shouldTrigger = true
                        }
                    }
                }
                
                if action.triggerCondition.contains("no_exercise") {
                    if let lastExercise = deepMemory.retrieve(key: "last_exercise", category: .habits)?.value {
                        if let date = ISO8601DateFormatter().date(from: lastExercise) {
                            let daysSinceExercise = Calendar.current.dateComponents([.day], from: date, to: now).day ?? 0
                            shouldTrigger = daysSinceExercise >= 7
                        }
                    }
                }
                
            case .scenarioBased:
                // 检查场景条件
                if let currentLocation = deepMemory.retrieve(key: "current_location", category: .habits)?.value {
                    shouldTrigger = action.triggerCondition.contains(currentLocation)
                }
                
            case .needBased:
                // 检查需求条件
                let needs = predictionAI.predictNeeds()
                for need in needs where need.urgency >= 0.8 {
                    if action.triggerCondition.contains(need.category) {
                        shouldTrigger = true
                        break
                    }
                }
            }
            
            // 触发关怀
            if shouldTrigger {
                triggerAction(action)
            }
        }
    }
    
    // MARK: - Trigger Action
    
    /// 触发关怀动作
    private func triggerAction(_ action: CareAction) {
        // 检查是否最近已经触发过（避免频繁触发）
        if let lastTriggered = action.lastTriggered {
            let minutesSinceTrigger = Date().timeIntervalSince(lastTriggered) / 60
            if minutesSinceTrigger < 60 { // 1小时内不重复触发
                return
            }
        }
        
        // 更新触发记录
        if let index = careActions.firstIndex(where: { $0.id == action.id }) {
            careActions[index].lastTriggered = Date()
            careActions[index].triggerCount += 1
            
            // 添加到已触发列表
            triggeredActions.append(careActions[index])
            
            // 只保留最近100条触发记录
            if triggeredActions.count > 100 {
                triggeredActions = Array(triggeredActions.suffix(100))
            }
            
            print("💡 触发关怀：\(action.title) - \(action.message)")
            
            // 这里可以发送通知、显示消息等
            // sendCareNotification(action)
            
            saveCareActions()
        }
    }
    
    // MARK: - Custom Care Actions
    
    /// 添加自定义关怀动作
    func addCustomCareAction(type: CareType, title: String, message: String, triggerCondition: String, priority: Int = 5) {
        let action = CareAction(
            type: type,
            title: title,
            message: message,
            triggerCondition: triggerCondition,
            priority: priority
        )
        
        careActions.append(action)
        saveCareActions()
    }
    
    /// 删除关怀动作
    func removeCareAction(id: UUID) {
        careActions.removeAll { $0.id == id }
        saveCareActions()
    }
    
    /// 启用/禁用关怀动作
    func toggleCareAction(id: UUID) {
        if let index = careActions.firstIndex(where: { $0.id == id }) {
            careActions[index].isEnabled.toggle()
            saveCareActions()
        }
    }
    
    // MARK: - Persistence
    
    private func saveCareActions() {
        guard let data = try? JSONEncoder().encode(careActions) else { return }
        UserDefaults.standard.set(data, forKey: "caogen_care_actions")
    }
    
    private func loadCareActions() {
        guard let data = UserDefaults.standard.data(forKey: "caogen_care_actions"),
              let actions = try? JSONDecoder().decode([CareAction].self, from: data) else {
            return
        }
        
        careActions = actions
    }
    
    /// 清除关怀动作
    func clearCareActions() {
        careActions.removeAll()
        triggeredActions.removeAll()
        saveCareActions()
    }
}
