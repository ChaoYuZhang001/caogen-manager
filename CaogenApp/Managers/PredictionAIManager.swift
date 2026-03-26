//
//  PredictionAIManager.swift
//  CaogenApp
//
//  Created by Caogen Team on 2026-03-26.
//  预测AI系统 - 预测用户的行为、需求、情绪、场景
//

import Foundation
import Combine
import CoreData

// MARK: - Prediction Type
enum PredictionType: String, CaseIterable {
    case behavior      // 行为预测
    case need         // 需求预测
    case emotion      // 情绪预测
    case scenario     // 场景预测
}

// MARK: - Prediction Result
struct PredictionResult {
    let type: PredictionType
    let prediction: String
    let confidence: Double // 0.0 - 1.0
    let predictedAt: Date
    let expectedTime: Date?
    let context: [String: Any]
    var isTriggered: Bool = false
}

// MARK: - Behavior Pattern
struct BehaviorPattern {
    let id: UUID
    let action: String
    let timeOfDay: String // "morning", "afternoon", "evening", "night"
    let dayOfWeek: String // "monday", "tuesday", ..., "sunday"
    let frequency: Int
    let lastTriggered: Date
    let averageInterval: TimeInterval
}

// MARK: - User Need
struct UserNeed {
    let id: UUID
    let category: String
    let description: String
    let priority: Int
    let lastSatisfied: Date?
    let urgency: Double // 0.0 - 1.0
}

// MARK: - Prediction AI Manager
@MainActor
class PredictionAIManager: ObservableObject {
    static let shared = PredictionAIManager()
    
    @Published private(set) var activePredictions: [PredictionResult] = []
    @Published private(set) var predictionHistory: [PredictionResult] = []
    @Published private(set) var behaviorPatterns: [BehaviorPattern] = []
    @Published private(set) var userNeeds: [UserNeed] = []
    
    private init() {
        loadPredictionData()
        startPredictionEngine()
    }
    
    // MARK: - Behavior Prediction
    
    /// 预测用户的行为
    func predictBehavior(for time: Date, context: [String: Any] = [:]) -> [PredictionResult] {
        var predictions: [PredictionResult] = []
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let weekday = calendar.component(.weekday, from: time)
        
        // 根据时间预测
        if hour >= 7 && hour <= 9 {
            // 早上7-9点：可能查天气、查日程、吃早饭
            predictions.append(PredictionResult(
                type: .behavior,
                prediction: "查看天气",
                confidence: 0.8,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
            
            predictions.append(PredictionResult(
                type: .need,
                prediction: "需要天气提醒",
                confidence: 0.75,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
        }
        
        if hour >= 12 && hour <= 13 {
            // 中午12-13点：可能吃午饭
            predictions.append(PredictionResult(
                type: .behavior,
                prediction: "点外卖",
                confidence: 0.7,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
            
            predictions.append(PredictionResult(
                type: .need,
                prediction: "需要午饭推荐",
                confidence: 0.65,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
        }
        
        if hour >= 18 && hour <= 19 {
            // 晚上18-19点：可能下班、吃晚饭
            predictions.append(PredictionResult(
                type: .behavior,
                prediction: "下班准备",
                confidence: 0.85,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
            
            predictions.append(PredictionResult(
                type: .need,
                prediction: "需要晚餐推荐",
                confidence: 0.7,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
        }
        
        if hour >= 21 && hour <= 22 {
            // 晚上21-22点：可能准备休息
            predictions.append(PredictionResult(
                type: .behavior,
                prediction: "准备休息",
                confidence: 0.75,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
            
            predictions.append(PredictionResult(
                type: .need,
                prediction: "需要早睡提醒",
                confidence: 0.8,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
        }
        
        // 根据星期预测
        if weekday == 1 { // 周一
            predictions.append(PredictionResult(
                type: .scenario,
                prediction: "周一综合症",
                confidence: 0.7,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
        }
        
        if weekday == 5 { // 周五
            predictions.append(PredictionResult(
                type: .behavior,
                prediction: "周末准备",
                confidence: 0.8,
                predictedAt: Date(),
                expectedTime: time,
                context: context
            ))
        }
        
        // 保存预测
        activePredictions.append(contentsOf: predictions)
        savePredictionData()
        
        return predictions
    }
    
    // MARK: - Need Prediction
    
    /// 预测用户的需求
    func predictNeeds(context: [String: Any] = [:]) -> [UserNeed] {
        var needs: [UserNeed] = []
        
        // 检查历史模式
        if let recentBehavior = behaviorPatterns.first {
            if recentBehavior.action.contains("天气") {
                needs.append(UserNeed(
                    id: UUID(),
                    category: "天气",
                    description: "需要天气信息",
                    priority: 3,
                    lastSatisfied: recentBehavior.lastTriggered,
                    urgency: 0.7
                ))
            }
            
            if recentBehavior.action.contains("外卖") {
                needs.append(UserNeed(
                    id: UUID(),
                    category: "外卖",
                    description: "需要外卖推荐",
                    priority: 4,
                    lastSatisfied: recentBehavior.lastTriggered,
                    urgency: 0.8
                ))
            }
        }
        
        // 根据上下文预测
        if let currentWeather = context["weather"] as? String {
            if currentWeather.contains("雨") {
                needs.append(UserNeed(
                    id: UUID(),
                    category: "出行",
                    description: "需要带伞提醒",
                    priority: 5,
                    lastSatisfied: nil,
                    urgency: 0.9
                ))
            }
        }
        
        if let healthData = context["health"] as? [String: Any],
           let sleepHours = healthData["sleepHours"] as? Double,
           sleepHours < 6 {
            needs.append(UserNeed(
                id: UUID(),
                category: "健康",
                description: "需要早睡提醒",
                priority: 4,
                lastSatisfied: nil,
                urgency: 0.85
            ))
        }
        
        // 检查未满足的需求
        for need in userNeeds {
            if let lastSatisfied = need.lastSatisfied {
                let daysSinceSatisfied = Date().timeIntervalSince(lastSatisfied) / (24 * 3600)
                if daysSinceSatisfied > 1 { // 超过1天未满足
                    needs.append(need)
                }
            } else {
                // 从未满足过
                needs.append(need)
            }
        }
        
        // 按优先级排序
        needs.sort { $0.priority > $1.priority }
        
        return needs
    }
    
    // MARK: - Emotion Prediction
    
    /// 预测用户的情绪
    func predictEmotion(for time: Date, context: [String: Any] = [:]) -> PredictionResult? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let weekday = calendar.component(.weekday, from: time)
        
        var emotion = ""
        var confidence = 0.5
        
        // 根据时间预测
        if hour >= 7 && hour <= 9 {
            emotion = "期待/清醒"
            confidence = 0.7
        } else if hour >= 12 && hour <= 13 {
            emotion = "放松/满足"
            confidence = 0.6
        } else if hour >= 15 && hour <= 16 {
            emotion = "疲惫/压力"
            confidence = 0.7
        } else if hour >= 18 && hour <= 19 {
            emotion = "轻松/开心"
            confidence = 0.75
        } else if hour >= 21 && hour <= 22 {
            emotion = "平静/困倦"
            confidence = 0.65
        }
        
        // 根据星期预测
        if weekday == 1 { // 周一
            emotion = "焦虑/疲惫"
            confidence = 0.8
        } else if weekday == 5 { // 周五
            emotion = "兴奋/期待"
            confidence = 0.75
        }
        
        // 根据上下文预测
        if let workLoad = context["workLoad"] as? String {
            if workLoad.contains("多") || workLoad.contains("忙") {
                emotion = "压力/焦虑"
                confidence = 0.85
            }
        }
        
        if let recentEvents = context["recentEvents"] as? [String] {
            if recentEvents.contains("熬夜") {
                emotion = "疲惫"
                confidence = 0.9
            }
        }
        
        let prediction = PredictionResult(
            type: .emotion,
            prediction: emotion,
            confidence: confidence,
            predictedAt: Date(),
            expectedTime: time,
            context: context
        )
        
        return prediction
    }
    
    // MARK: - Scenario Prediction
    
    /// 预测用户的场景
    func predictScenario(from userAction: String, context: [String: Any] = [:]) -> PredictionResult? {
        var scenario = ""
        var confidence = 0.5
        
        // 根据用户行为预测
        if userAction.contains("查") && userAction.contains("天气") {
            scenario = "准备出门"
            confidence = 0.8
        } else if userAction.contains("点") && userAction.contains("外卖") {
            scenario = "准备用餐"
            confidence = 0.85
        } else if userAction.contains("查") && userAction.contains("日程") {
            scenario = "工作准备"
            confidence = 0.75
        } else if userAction.contains("导航") || userAction.contains("去") {
            scenario = "出行"
            confidence = 0.9
        } else if userAction.contains("睡觉") || userAction.contains("休息") {
            scenario = "休息"
            confidence = 0.85
        }
        
        let prediction = PredictionResult(
            type: .scenario,
            prediction: scenario,
            confidence: confidence,
            predictedAt: Date(),
            expectedTime: nil,
            context: context
        )
        
        return prediction
    }
    
    // MARK: - Learning from Behavior
    
    /// 从用户行为中学习模式
    func learnBehavior(action: String, time: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let weekday = calendar.component(.weekday, from: time)
        
        // 确定时间段
        let timeOfDay: String
        if hour >= 5 && hour < 12 {
            timeOfDay = "morning"
        } else if hour >= 12 && hour < 18 {
            timeOfDay = "afternoon"
        } else if hour >= 18 && hour < 22 {
            timeOfDay = "evening"
        } else {
            timeOfDay = "night"
        }
        
        // 确定星期
        let weekdayName: String
        switch weekday {
        case 1: weekdayName = "sunday"
        case 2: weekdayName = "monday"
        case 3: weekdayName = "tuesday"
        case 4: weekdayName = "wednesday"
        case 5: weekdayName = "thursday"
        case 6: weekdayName = "friday"
        case 7: weekdayName = "saturday"
        default: weekdayName = "unknown"
        }
        
        // 检查是否已存在相同模式
        if let index = behaviorPatterns.firstIndex(where: {
            $0.action == action &&
            $0.timeOfDay == timeOfDay &&
            $0.dayOfWeek == weekdayName
        }) {
            // 更新现有模式
            behaviorPatterns[index].frequency += 1
            behaviorPatterns[index].lastTriggered = time
            
            // 更新平均间隔
            let interval = time.timeIntervalSince(behaviorPatterns[index].lastTriggered)
            behaviorPatterns[index].averageInterval = (behaviorPatterns[index].averageInterval + interval) / 2
        } else {
            // 创建新模式
            let pattern = BehaviorPattern(
                id: UUID(),
                action: action,
                timeOfDay: timeOfDay,
                dayOfWeek: weekdayName,
                frequency: 1,
                lastTriggered: time,
                averageInterval: 0
            )
            behaviorPatterns.append(pattern)
        }
        
        savePredictionData()
    }
    
    // MARK: - Prediction Engine
    
    /// 启动预测引擎
    private func startPredictionEngine() {
        // 定时预测用户行为
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in
                let predictions = self.predictBehavior(for: Date())
                print("🔮 预测引擎：预测了 \(predictions.count) 个行为")
            }
        }
    }
    
    /// 触发预测提醒
    func triggerPredictionReminders() {
        for prediction in activePredictions {
            if let expectedTime = prediction.expectedTime {
                let now = Date()
                if now >= expectedTime && !prediction.isTriggered {
                    // 触发提醒
                    prediction.isTriggered = true
                    print("🔮 触发预测：\(prediction.prediction)")
                }
            }
        }
        
        // 清理已触发的预测
        activePredictions.removeAll { $0.isTriggered }
    }
    
    // MARK: - Persistence
    
    private func savePredictionData() {
        guard let patternsData = try? JSONEncoder().encode(behaviorPatterns),
              let needsData = try? JSONEncoder().encode(userNeeds),
              let historyData = try? JSONEncoder().encode(predictionHistory) else { return }
        
        UserDefaults.standard.set(patternsData, forKey: "caogen_behavior_patterns")
        UserDefaults.standard.set(needsData, forKey: "caogen_user_needs")
        UserDefaults.standard.set(historyData, forKey: "caogen_prediction_history")
    }
    
    private func loadPredictionData() {
        if let patternsData = UserDefaults.standard.data(forKey: "caogen_behavior_patterns"),
           let patterns = try? JSONDecoder().decode([BehaviorPattern].self, from: patternsData) {
            behaviorPatterns = patterns
        }
        
        if let needsData = UserDefaults.standard.data(forKey: "caogen_user_needs"),
           let needs = try? JSONDecoder().decode([UserNeed].self, from: needsData) {
            userNeeds = needs
        }
        
        if let historyData = UserDefaults.standard.data(forKey: "caogen_prediction_history"),
           let history = try? JSONDecoder().decode([PredictionResult].self, from: historyData) {
            predictionHistory = history
        }
    }
    
    /// 清除预测数据
    func clearPredictionData() {
        behaviorPatterns.removeAll()
        userNeeds.removeAll()
        predictionHistory.removeAll()
        activePredictions.removeAll()
        savePredictionData()
    }
}
