/**
 * AI 对话升级 - 更智能的对话
 * 深度上下文理解、多轮对话、情感分析升级、意图识别优化、主动关怀增强
 */

import SwiftUI
import NaturalLanguage

/// AI 对话引擎
class AIDialogueEngine: ObservableObject {
    @Published var currentContext: DialogueContext?
    @Published var conversationHistory: [DialogueMessage] = []
    @Published var currentSentiment: Sentiment = .neutral
    @Published var currentIntent: Intent?

    private let contextManager = ContextManager()
    private let sentimentAnalyzer = SentimentAnalyzer()
    private let intentRecognizer = IntentRecognizer()
    private let responseGenerator = ResponseGenerator()
    private let careEngine = CareEngine()

    /// 处理用户消息
    func processMessage(_ message: String) async -> DialogueResponse {
        let startTime = Date()

        // 1. 情感分析
        let sentiment = await sentimentAnalyzer.analyze(message)
        self.currentSentiment = sentiment

        // 2. 意图识别
        let intent = await intentRecognizer.recognize(message, context: currentContext)
        self.currentIntent = intent

        // 3. 更新上下文
        await contextManager.update(message, intent: intent, sentiment: sentiment)

        // 4. 生成回复
        let response = await responseGenerator.generate(
            message,
            intent: intent,
            sentiment: sentiment,
            context: contextManager.currentContext
        )

        // 5. 记录对话历史
        recordMessage(message, response: response.text, intent: intent, sentiment: sentiment)

        // 6. 主动关怀检查
        let care = await careEngine.checkCare(conversationHistory, currentContext: contextManager.currentContext)

        let duration = Date().timeIntervalSince(startTime)

        return DialogueResponse(
            text: response.text,
            intent: intent,
            sentiment: sentiment,
            care: care,
            duration: duration,
            suggestions: response.suggestions
        )
    }

    /// 记录消息
    private func recordMessage(_ message: String, response: String, intent: Intent?, sentiment: Sentiment) {
        conversationHistory.append(DialogueMessage(
            role: .user,
            content: message,
            intent: intent,
            sentiment: sentiment,
            timestamp: Date()
        ))

        conversationHistory.append(DialogueMessage(
            role: .assistant,
            content: response,
            intent: intent,
            sentiment: sentiment,
            timestamp: Date()
        ))

        // 保留最近 50 条对话
        if conversationHistory.count > 50 {
            conversationHistory = Array(conversationHistory.suffix(50))
        }
    }

    /// 清除对话历史
    func clearHistory() {
        conversationHistory.removeAll()
        currentContext = nil
        currentSentiment = .neutral
        currentIntent = nil
    }
}

/// 对话上下文
struct DialogueContext {
    var userId: String
    var topic: String?
    var entities: [Entity]
    var lastIntent: Intent?
    var lastTopic: String?
    var conversationFlow: [DialogueStep]
    var userPreferences: UserPreferences
    var emotionState: EmotionState

    init(userId: String) {
        self.userId = userId
        self.topic = nil
        self.entities = []
        self.lastIntent = nil
        self.lastTopic = nil
        self.conversationFlow = []
        self.userPreferences = UserPreferences()
        self.emotionState = EmotionState()
    }
}

/// 对话消息
struct DialogueMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let intent: Intent?
    let sentiment: Sentiment
    let timestamp: Date
}

/// 消息角色
enum MessageRole {
    case user
    case assistant
    case system
}

/// 对话响应
struct DialogueResponse {
    let text: String
    let intent: Intent?
    let sentiment: Sentiment
    let care: CareResponse?
    let duration: TimeInterval
    let suggestions: [String]
}

/// 上下文管理器
class ContextManager {
    @Published private(set) var currentContext: DialogueContext?

    func update(_ message: String, intent: Intent?, sentiment: Sentiment) async {
        if currentContext == nil {
            currentContext = DialogueContext(userId: "default")
        }

        guard var context = currentContext else { return }

        // 更新实体
        let entities = extractEntities(message)
        context.entities = entities

        // 更新主题
        context.topic = detectTopic(message, previousTopic: context.topic)

        // 更新意图
        context.lastIntent = intent

        // 更新对话流程
        if let intent = intent {
            context.conversationFlow.append(DialogueStep(
                step: context.conversationFlow.count + 1,
                message: message,
                intent: intent,
                timestamp: Date()
            ))
        }

        // 更新情感状态
        context.emotionState.update(sentiment)

        currentContext = context
    }

    /// 提取实体
    private func extractEntities(_ text: String) -> [Entity] {
        var entities: [Entity] = []

        // 提取日期
        let datePattern = "\\d{4}-\\d{2}-\\d{2}|\\d{1,2}月\\d{1,2}日|今天|明天|后天"
        if let matches = text.range(of: datePattern, options: .regularExpression) {
            entities.append(Entity(type: .date, value: String(text[matches])))
        }

        // 提取时间
        let timePattern = "\\d{1,2}:\\d{2}|\\d{1,2}点"
        if let matches = text.range(of: timePattern, options: .regularExpression) {
            entities.append(Entity(type: .time, value: String(text[matches])))
        }

        // 提取数字
        let numberPattern = "\\d+"
        if let matches = text.range(of: numberPattern, options: .regularExpression) {
            entities.append(Entity(type: .number, value: String(text[matches])))
        }

        return entities
    }

    /// 检测主题
    private func detectTopic(_ message: String, previousTopic: String?) -> String? {
        let topics = [
            "天气": ["天气", "温度", "下雨", "晴天", "多云"],
            "日程": ["日程", "会议", "安排", "计划"],
            "健康": ["健康", "血压", "血糖", "运动"],
            "工作": ["工作", "任务", "项目", "报告"],
            "生活": ["吃饭", "睡觉", "运动", "购物"],
            "情感": ["开心", "难过", "生气", "烦恼"]
        ]

        for (topic, keywords) in topics {
            for keyword in keywords {
                if message.contains(keyword) {
                    return topic
                }
            }
        }

        return previousTopic
    }
}

/// 情感分析器
class SentimentAnalyzer {
    private let tagger = NLTagger(tagSchemes: [.sentimentScore])

    func analyze(_ text: String) async -> Sentiment {
        tagger.string = text

        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)

        switch sentiment {
        case .positive:
            return .positive
        case .negative:
            return .negative
        default:
            return .neutral
        }
    }
}

/// 情感类型
enum Sentiment: String {
    case positive
    case negative
    case neutral
}

/// 意图识别器
class IntentRecognizer {
    private let intents: [IntentPattern] = [
        IntentPattern(intent: .query, keywords: ["查询", "查", "看", "多少", "怎么样", "天气", "时间", "日期"]),
        IntentPattern(intent: .action, keywords: ["帮", "做", "打开", "搜索", "导航", "翻译", "设置", "创建"]),
        IntentPattern(intent: .complaint, keywords: ["烦恼", "难过", "生气", "不开心", "郁闷", "糟糕", "伤心"]),
        IntentPattern(intent: .greeting, keywords: ["你好", "早上好", "晚上好", "晚安", "嗨", "hello", "hi"]),
        IntentPattern(intent: .gratitude, keywords: ["谢谢", "感谢", "thank", "thanks"]),
        IntentPattern(intent: .question, keywords: ["怎么", "为什么", "如何", "?", "吗"]),
        IntentPattern(intent: .reminder, keywords: ["提醒", "记得", "别忘了"]),
        IntentPattern(intent: .recommendation, keywords: ["推荐", "建议", "什么好"])
    ]

    func recognize(_ text: String, context: DialogueContext?) async -> Intent {
        let lowerText = text.lowercased()

        // 遍历所有意图
        for pattern in intents {
            for keyword in pattern.keywords {
                if lowerText.contains(keyword) {
                    return Intent(type: pattern.intent, confidence: 0.8, matchedKeyword: keyword)
                }
            }
        }

        // 多轮对话意图检测
        if let context = context, !context.conversationFlow.isEmpty {
            let lastStep = context.conversationFlow.last!
            if lastStep.intent.type == .query {
                return Intent(type: .followup, confidence: 0.7, previousIntent: lastStep.intent)
            }
        }

        return Intent(type: .chat, confidence: 0.5)
    }
}

/// 意图
struct Intent {
    let type: IntentType
    let confidence: Double
    let matchedKeyword: String?
    var previousIntent: Intent?

    enum IntentType {
        case query
        case action
        case complaint
        case greeting
        case gratitude
        case question
        case reminder
        case recommendation
        case followup
        case chat
    }
}

/// 意图模式
struct IntentPattern {
    let intent: Intent.IntentType
    let keywords: [String]
}

/// 回复生成器
class ResponseGenerator {
    func generate(
        _ message: String,
        intent: Intent?,
        sentiment: Sentiment,
        context: DialogueContext?
    ) async -> GeneratedResponse {
        switch intent?.type {
        case .query:
            return GeneratedResponse(text: "好的，我来帮你查询：\(message)", suggestions: ["查看详情", "相关推荐"])

        case .action:
            return GeneratedResponse(text: "好的，正在为您执行：\(message)", suggestions: ["查看状态", "撤销"])

        case .complaint:
            return GeneratedResponse(text: generateComfortResponse(sentiment), suggestions: ["寻求帮助", "转移注意力"])

        case .greeting:
            return GeneratedResponse(text: generateGreetingResponse(), suggestions: ["查看日程", "查询天气"])

        case .gratitude:
            return GeneratedResponse(text: generateGratitudeResponse(), suggestions: ["继续", "其他帮助"])

        case .question:
            return GeneratedResponse(text: "让我来回答你的问题", suggestions: ["详细解答", "相关资料"])

        case .reminder:
            return GeneratedResponse(text: "好的，我会记得提醒你这件事的", suggestions: ["设置提醒时间", "添加备注"])

        case .recommendation:
            return GeneratedResponse(text: "根据你的情况，我推荐你试试...", suggestions: ["了解更多", "其他选择"])

        case .followup:
            return GeneratedResponse(text: generateFollowupResponse(context), suggestions: ["继续", "换个话题"])

        default:
            return GeneratedResponse(text: generateChatResponse(message, context), suggestions: ["继续", "换个话题"])
        }
    }

    private func generateComfortResponse(_ sentiment: Sentiment) -> String {
        let comforts = [
            "别难过，我在你身边，可以和我说说。",
            "没关系，一切都会好起来的。💪",
            "我理解你的感受，慢慢来，不着急。",
            "主人，有什么心事可以告诉我，我帮你分担。❤️"
        ]

        return comforts.randomElement()!
    }

    private func generateGreetingResponse() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour >= 5 && hour < 12 {
            return "早上好，主人！今天有什么计划吗？☀️"
        } else if hour >= 12 && hour < 18 {
            return "下午好，主人！工作辛苦了，需要我帮你做什么吗？☕"
        } else if hour >= 18 && hour < 22 {
            return "晚上好，主人！今天过得怎么样？🌙"
        } else {
            return "夜深了，主人！早点休息，晚安~ 💤"
        }
    }

    private func generateGratitudeResponse() -> String {
        let thanks = [
            "不客气，这是我应该做的！😊",
            "随时为您服务，主人！👍",
            "能帮到你就好！✨",
            "主人客气了，有需要随时叫我！🌾"
        ]

        return thanks.randomElement()!
    }

    private func generateFollowupResponse(_ context: DialogueContext?) -> String {
        guard let context = context, !context.conversationFlow.isEmpty else {
            return "还有其他需要帮助的吗？"
        }

        let lastIntent = context.conversationFlow.last?.intent?.type

        switch lastIntent {
        case .query:
            return "关于这个查询，还有其他想了解的吗？"
        case .action:
            return "操作已执行，还有其他需要吗？"
        default:
            return "还有其他需要帮助的吗？"
        }
    }

    private func generateChatResponse(_ message: String, _ context: DialogueContext?) -> String {
        let chatResponses = [
            "我理解了，继续说吧。",
            "嗯嗯，我在听。",
            "主人说得对！👍",
            "好的，我明白了。"
        ]

        return chatResponses.randomElement()!
    }
}

/// 生成的回复
struct GeneratedResponse {
    let text: String
    let suggestions: [String]
}

/// 主动关怀引擎
class CareEngine {
    func checkCare(_ history: [DialogueMessage], currentContext: DialogueContext?) async -> CareResponse? {
        // 检测持续负面情感
        let negativeCount = history.suffix(5).filter { $0.sentiment == .negative }.count

        if negativeCount >= 3 {
            return CareResponse(
                type: .emotional,
                message: "主人，最近感觉不太开心？有什么可以帮你的吗？❤️",
                priority: .high
            )
        }

        // 检测长时间未对话（> 24小时）
        if let lastMessage = history.last {
            let hoursSinceLast = Date().timeIntervalSince(lastMessage.timestamp) / 3600

            if hoursSinceLast > 24 {
                return CareResponse(
                    type: .longTerm,
                    message: "好久不见，主人！今天过得怎么样？☀️",
                    priority: .medium
                )
            }
        }

        // 检测异常情绪状态
        if let context = currentContext {
            if context.emotionState.stressLevel > 0.8 {
                return CareResponse(
                    type: .stress,
                    message: "主人，你看起来压力很大，需要我帮忙分担吗？😊",
                    priority: .high
                )
            }
        }

        return nil
    }
}

/// 主动关怀响应
struct CareResponse {
    let type: CareType
    let message: String
    let priority: Priority

    enum CareType {
        case emotional
        case longTerm
        case stress
        case health
    }

    enum Priority {
        case high
        case medium
        case low
    }
}

/// 用户偏好
struct UserPreferences {
    var preferredTone: String = "friendly"
    var preferredStyle: String = "casual"
    var interests: [String] = []
}

/// 情感状态
struct EmotionState {
    var currentEmotion: Sentiment = .neutral
    var stressLevel: Double = 0.0
    var moodHistory: [Sentiment] = []

    mutating func update(_ sentiment: Sentiment) {
        currentEmotion = sentiment
        moodHistory.append(sentiment)

        // 计算压力水平（基于负面情感频率）
        if moodHistory.count > 0 {
            let negativeCount = moodHistory.filter { $0 == .negative }.count
            stressLevel = Double(negativeCount) / Double(moodHistory.count)
        }

        // 保留最近 20 条记录
        if moodHistory.count > 20 {
            moodHistory = Array(moodHistory.suffix(20))
        }
    }
}

/// 实体
struct Entity {
    let type: EntityType
    let value: String

    enum EntityType {
        case date
        case time
        case number
        case person
        case location
    }
}

/// 对话步骤
struct DialogueStep {
    let step: Int
    let message: String
    let intent: Intent
    let timestamp: Date
}
