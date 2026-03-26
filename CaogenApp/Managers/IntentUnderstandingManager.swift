//
//  IntentUnderstandingManager.swift
//  CaogenApp
//
//  Created by Caogen Team on 2026-03-26.
//  智能理解系统 - 理解用户的每一个指令，即使不说完整
//

import Foundation
import Combine
import NaturalLanguage

// MARK: - Intent Type
enum IntentType: String, CaseIterable {
    case query         // 查询
    case remind        // 提醒
    case record        // 记录
    case translate     // 翻译
    case search        // 搜索
    case calculate     // 计算
    case create        // 创建
    case delete        // 删除
    case update        // 更新
    case navigate      // 导航
    case call          // 打电话
    case message       // 发消息
    case order         // 订购
    case book          // 预订
    case weather       // 天气
    case schedule      // 日程
    case expense       // 记账
    case health        // 健康
    case habit         // 习惯
    case chat          // 聊天
    case emotion       // 情绪表达
    case request       // 请求
    case command       // 命令
    case unknown       // 未知
}

// MARK: - Intent Entity
struct IntentEntity {
    let type: String
    let value: String
    let confidence: Double
}

// MARK: - Intent Result
struct IntentResult {
    let primaryIntent: IntentType
    let secondaryIntents: [IntentType]
    let entities: [IntentEntity]
    let confidence: Double
    let rawText: String
    let detectedAt: Date
    let context: [String: Any]
}

// MARK: - Intent Understanding Manager
@MainActor
class IntentUnderstandingManager: ObservableObject {
    static let shared = IntentUnderstandingManager()
    
    @Published private(set) var recentIntents: [IntentResult] = []
    
    private let intentKeywords: [IntentType: [String]] = [
        .query: ["查", "查询", "看", "显示", "告诉我", "什么", "怎么样"],
        .remind: ["提醒", "记得", "别忘了", "别忘了", "别忘了"],
        .record: ["记录", "记下来", "保存", "备忘", "写下来"],
        .translate: ["翻译", "翻译成", "英文", "中文", "翻译成英文"],
        .search: ["搜索", "找", "查找", "寻找", "搜"],
        .calculate: ["计算", "算", "多少", "多少钱", "多少个"],
        .create: ["创建", "新建", "建立", "生成", "创建一个"],
        .delete: ["删除", "移除", "去掉", "清除", "删除"],
        .update: ["更新", "修改", "改", "更改", "更新"],
        .navigate: ["导航", "去", "去往", "前往", "到"],
        .call: ["打", "打电话", "给...打电话", "给...打"],
        .message: ["发", "发消息", "给...发", "给...发消息"],
        .order: ["点", "点外卖", "买", "购买", "订购"],
        .book: ["预订", "订", "预约", "预订"],
        .weather: ["天气", "气温", "温度", "下雨", "晴天"],
        .schedule: ["日程", "安排", "计划", "会议", "会议"],
        .expense: ["记账", "花了", "消费", "支出", "花了多少钱"],
        .health: ["健康", "血压", "血糖", "心率", "运动"],
        .habit: ["习惯", "打卡", "坚持", "养成"],
        .chat: ["聊", "聊天", "说话", "对话", "聊天"],
        .emotion: ["难过", "开心", "生气", "焦虑", "压力大"],
        .request: ["帮", "帮我", "帮忙", "请求", "要求"],
        .command: ["执行", "运行", "启动", "开始", "执行"]
    ]
    
    private init() {
        loadRecentIntents()
    }
    
    // MARK: - Intent Recognition
    
    /// 识别用户意图
    func recognizeIntent(from text: String, context: [String: Any] = [:]) -> IntentResult {
        var bestMatch: IntentType?
        var bestScore: Double = 0
        var secondaryIntents: [IntentType] = []
        var entities: [IntentEntity] = []
        
        // 识别主要意图
        for (intent, keywords) in intentKeywords {
            var score: Double = 0
            for keyword in keywords {
                if text.localizedCaseInsensitiveContains(keyword) {
                    score += 1
                }
            }
            
            if score > bestScore {
                bestScore = score
                if bestMatch != nil {
                    secondaryIntents.append(bestMatch!)
                }
                bestMatch = intent
            } else if score > 0 {
                secondaryIntents.append(intent)
            }
        }
        
        // 如果没有匹配到，根据上下文推理
        if bestMatch == nil {
            bestMatch = inferIntentFromContext(text, context: context)
        }
        
        // 提取实体
        entities = extractEntities(from: text, intent: bestMatch ?? .unknown)
        
        // 计算置信度
        let confidence = min(bestScore / 3.0, 1.0)
        
        let result = IntentResult(
            primaryIntent: bestMatch ?? .unknown,
            secondaryIntents: secondaryIntents,
            entities: entities,
            confidence: confidence,
            rawText: text,
            detectedAt: Date(),
            context: context
        )
        
        // 保存到历史
        recentIntents.append(result)
        saveRecentIntents()
        
        // 只保留最近50条记录
        if recentIntents.count > 50 {
            recentIntents = Array(recentIntents.suffix(50))
        }
        
        return result
    }
    
    // MARK: - Context Inference
    
    private func inferIntentFromContext(_ text: String, context: [String: Any]) -> IntentType {
        // 从上下文中推理意图
        if let time = context["time"] as? String {
            if time.contains("早上") || time.contains("上午") {
                return .schedule
            } else if time.contains("晚上") || time.contains("下午") {
                return .query
            }
        }
        
        if let location = context["location"] as? String {
            if location.contains("公司") || location.contains("办公室") {
                return .schedule
            } else if location.contains("家") || location.contains("家里") {
                return .query
            } else if location.contains("超市") || location.contains("商场") {
                return .order
            }
        }
        
        if let weather = context["weather"] as? String {
            if weather.contains("雨") || weather.contains("阴") {
                return .remind
            }
        }
        
        // 默认查询意图
        return .query
    }
    
    // MARK: - Entity Extraction
    
    private func extractEntities(from text: String, intent: IntentType) -> [IntentEntity] {
        var entities: [IntentEntity] = []
        
        // 使用NLTagger提取实体
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag, tags.contains(tag) {
                let value = String(text[range])
                let entity = IntentEntity(type: tag.rawValue, value: value, confidence: 0.8)
                entities.append(entity)
            }
            return true
        }
        
        // 提取特定于意图的实体
        switch intent {
        case .remind:
            // 提取时间实体
            if let time = extractTimeEntity(from: text) {
                entities.append(time)
            }
            
        case .order:
            // 提取商品实体
            if let item = extractItemEntity(from: text) {
                entities.append(item)
            }
            
        case .navigate:
            // 提取地点实体
            if let location = extractLocationEntity(from: text) {
                entities.append(location)
            }
            
        case .translate:
            // 提取语言实体
            if let language = extractLanguageEntity(from: text) {
                entities.append(language)
            }
            
        default:
            break
        }
        
        return entities
    }
    
    // MARK: - Entity Extractors
    
    private func extractTimeEntity(from text: String) -> IntentEntity? {
        let timePatterns = [
            "\\d{1,2}点", "\\d{1,2}:\\d{2}", "明天", "后天", "下周", "下个月",
            "早上", "上午", "下午", "晚上", "凌晨"
        ]
        
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                let value = (text as NSString).substring(with: match.range)
                return IntentEntity(type: "time", value: value, confidence: 0.9)
            }
        }
        
        return nil
    }
    
    private func extractItemEntity(from text: String) -> IntentEntity? {
        // 简化版：提取最后一个名词
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var lastNoun: String?
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            if tag == .noun {
                lastNoun = String(text[range])
            }
            return true
        }
        
        if let item = lastNoun {
            return IntentEntity(type: "item", value: item, confidence: 0.7)
        }
        
        return nil
    }
    
    private func extractLocationEntity(from text: String) -> IntentEntity? {
        let locationKeywords = ["北京", "上海", "广州", "深圳", "公司", "家", "超市", "商场", "医院", "学校"]
        
        for location in locationKeywords {
            if text.localizedCaseInsensitiveContains(location) {
                return IntentEntity(type: "location", value: location, confidence: 0.9)
            }
        }
        
        return nil
    }
    
    private func extractLanguageEntity(from text: String) -> IntentEntity? {
        let languages = ["英语", "英文", "中文", "日语", "韩语", "法语", "德语"]
        
        for language in languages {
            if text.localizedCaseInsensitiveContains(language) {
                return IntentEntity(type: "language", value: language, confidence: 0.95)
            }
        }
        
        return nil
    }
    
    // MARK: - Compound Intent Detection
    
    /// 检测复合意图
    func detectCompoundIntents(from text: String) -> [IntentType] {
        var compoundIntents: [IntentType] = []
        
        let result = recognizeIntent(from: text)
        compoundIntents.append(result.primaryIntent)
        compoundIntents.append(contentsOf: result.secondaryIntents)
        
        // 检测特殊组合
        if text.contains("如果") && text.contains("提醒") {
            if !compoundIntents.contains(.query) {
                compoundIntents.append(.query)
            }
        }
        
        if text.contains("和") || text.contains("以及") {
            if compoundIntents.count > 1 {
                // 确认是复合意图
            }
        }
        
        return compoundIntents
    }
    
    // MARK: - Ambiguity Resolution
    
    /// 解决模糊意图
    func resolveAmbiguity(from text: String, candidates: [IntentType]) -> IntentType {
        // 如果只有一个候选，直接返回
        if candidates.count == 1 {
            return candidates.first ?? .unknown
        }
        
        // 如果有多个候选，使用上下文决策
        let recentIntents = Array(recentIntents.suffix(5))
        let recentIntentTypes = recentIntents.map { $0.primaryIntent }
        
        // 优先选择最近使用过的意图
        for recent in recentIntentTypes {
            if candidates.contains(recent) {
                return recent
            }
        }
        
        // 否则选择置信度最高的
        let results = candidates.map { recognizeIntent(from: text, context: ["candidates": candidates]) }
        let bestResult = results.max { $0.confidence < $1.confidence }
        
        return bestResult?.primaryIntent ?? candidates.first ?? .unknown
    }
    
    // MARK: - Persistence
    
    private func saveRecentIntents() {
        guard let data = try? JSONEncoder().encode(recentIntents) else { return }
        UserDefaults.standard.set(data, forKey: "caogen_recent_intents")
    }
    
    private func loadRecentIntents() {
        guard let data = UserDefaults.standard.data(forKey: "caogen_recent_intents"),
              let intents = try? JSONDecoder().decode([IntentResult].self, from: data) else {
            return
        }
        
        recentIntents = intents
    }
    
    /// 清除意图历史
    func clearRecentIntents() {
        recentIntents.removeAll()
        saveRecentIntents()
    }
}
