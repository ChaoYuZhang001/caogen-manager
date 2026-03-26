//
//  EmotionAIManager.swift
//  CaogenApp
//
//  Created by Caogen Team on 2026-03-26.
//  情感AI系统 - 识别20种情绪，比用户更懂用户的心情
//

import Foundation
import Combine
import NaturalLanguage

// MARK: - Emotion Type
enum EmotionType: String, CaseIterable {
    // 基础情绪（6种）
    case happy          // 开心
    case sad            // 难过
    case angry          // 生气
    case surprised      // 惊讶
    case fear           // 恐惧
    case disgust        // 厌恶
    
    // 复杂情绪（14种）
    case anxiety        // 焦虑
    case stress         // 压力
    case tired          // 疲惫
    case excited        // 兴奋
    case disappointed   // 失落
    case guilty         // 愧疚
    case ashamed        // 羞愧
    case confused       // 困惑
    case lonely         // 孤独
    case hopeful        // 充满希望
    case grateful       // 感激
    case proud          // 自豪
    case jealous        // 嫉妒
    case embarrassed    // 尴尬
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .angry: return "😠"
        case .surprised: return "😲"
        case .fear: return "😨"
        case .disgust: return "🤢"
        case .anxiety: return "😰"
        case .stress: return "😫"
        case .tired: return "😴"
        case .excited: return "🤩"
        case .disappointed: return "😞"
        case .guilty: return "😔"
        case .ashamed: return "😳"
        case .confused: return "😕"
        case .lonely: return "😔"
        case .hopeful: return "🌟"
        case .grateful: return "🙏"
        case .proud: return "😤"
        case .jealous: return "😒"
        case .embarrassed: return "😅"
        }
    }
    
    var description: String {
        switch self {
        case .happy: return "开心"
        case .sad: return "难过"
        case .angry: return "生气"
        case .surprised: return "惊讶"
        case .fear: return "恐惧"
        case .disgust: return "厌恶"
        case .anxiety: return "焦虑"
        case .stress: return "压力大"
        case .tired: return "疲惫"
        case .excited: return "兴奋"
        case .disappointed: return "失落"
        case .guilty: return "愧疚"
        case .ashamed: return "羞愧"
        case .confused: return "困惑"
        case .lonely: return "孤独"
        case .hopeful: return "充满希望"
        case .grateful: return "感激"
        case .proud: return "自豪"
        case .jealous: return "嫉妒"
        case .embarrassed: return "尴尬"
        }
    }
}

// MARK: - Emotion Intensity
enum EmotionIntensity: Double {
    case low = 0.3
    case medium = 0.5
    case high = 0.7
    case veryHigh = 0.9
}

// MARK: - Emotion Analysis Result
struct EmotionAnalysisResult {
    let emotion: EmotionType
    let intensity: EmotionIntensity
    let confidence: Double // 0.0 - 1.0
    let detectedAt: Date
    let context: String
    let triggers: [String]
}

// MARK: - Emotion Response Strategy
enum EmotionResponseStrategy {
    case accompany     // 陪伴
    case comfort       // 安慰
    case guide         // 疏导
    case encourage     // 鼓励
    case humor         // 幽默
    case professional  // 专业建议
    case urgent        // 紧急介入
}

// MARK: - Emotion AI Manager
@MainActor
class EmotionAIManager: ObservableObject {
    static let shared = EmotionAIManager()
    
    @Published private(set) var currentEmotion: EmotionType?
    @Published private(set) var emotionHistory: [EmotionAnalysisResult] = []
    @Published private(set) var emotionTrends: [String: [EmotionAnalysisResult]] = [:]
    
    private let emotionKeywords: [EmotionType: [String]] = [
        // 基础情绪关键词
        .happy: ["开心", "高兴", "快乐", "幸福", "棒", "好", "赞", "太好了", "不错", "优秀", "成功"],
        .sad: ["难过", "悲伤", "伤心", "痛苦", "哭", "难受", "失望", "绝望", "不想", "痛苦"],
        .angry: ["生气", "愤怒", "火大", "烦", "讨厌", "恨", "气死", "可恶", "想打人", "讨厌"],
        .surprised: ["惊讶", "意外", "震惊", "没想到", "天哪", "什么", "怎么会", "不敢相信"],
        .fear: ["害怕", "恐惧", "担心", "怕", "紧张", "焦虑", "不安", "吓死", "害怕"],
        .disgust: ["恶心", "讨厌", "反感", "受不了", "脏", "恶心", "想吐", "恶心"],
        
        // 复杂情绪关键词
        .anxiety: ["焦虑", "担心", "紧张", "不安", "怕", "害怕", "忧虑", "焦躁", "担心"],
        .stress: ["压力大", "累", "辛苦", "疲惫", "压力大", "忙", "忙不过来", "压力", "累死"],
        .tired: ["累", "疲惫", "困", "想睡觉", "没精力", "体力不支", "累趴", "累得不行"],
        .excited: ["兴奋", "激动", "期待", "开心", "高兴", "太棒了", "超级开心", "激动"],
        .disappointed: ["失望", "失落", "灰心", "丧", "没心情", "心情不好", "失望", "难过"],
        .guilty: ["愧疚", "内疚", "对不起", "抱歉", "不好意思", "对不起", "抱歉"],
        .ashamed: ["羞愧", "羞耻", "不好意思", "羞耻", "丢人", "尴尬"],
        .confused: ["困惑", "迷茫", "不明白", "不懂", "不知道", "怎么回事", "困惑"],
        .lonely: ["孤独", "寂寞", "一个人", "没人", "孤单", "寂寞", "孤独"],
        .hopeful: ["充满希望", "期待", "希望", "有信心", "相信", "相信", "期待"],
        .grateful: ["感激", "谢谢", "感谢", "谢谢", "感激", "谢谢", "感谢"],
        .proud: ["自豪", "骄傲", "骄傲", "自豪", "很棒", "优秀", "厉害"],
        .jealous: ["嫉妒", "羡慕", "嫉妒", "羡慕", "嫉妒", "酸", "羡慕"],
        .embarrassed: ["尴尬", "不好意思", "羞", "尴尬", "难为情", "不好意思"]
    ]
    
    private init() {
        loadEmotionHistory()
    }
    
    // MARK: - Emotion Recognition
    
    /// 识别情绪（文本）
    func recognizeEmotion(from text: String) -> EmotionAnalysisResult? {
        var bestMatch: EmotionType?
        var bestScore: Double = 0
        var triggers: [String] = []
        
        for (emotion, keywords) in emotionKeywords {
            var score: Double = 0
            var emotionTriggers: [String] = []
            
            for keyword in keywords {
                if text.localizedCaseInsensitiveContains(keyword) {
                    score += 1
                    emotionTriggers.append(keyword)
                }
            }
            
            if score > bestScore {
                bestScore = score
                bestMatch = emotion
                triggers = emotionTriggers
            }
        }
        
        guard let emotion = bestMatch, bestScore > 0 else {
            return nil
        }
        
        // 计算强度
        let intensity: EmotionIntensity
        if bestScore >= 3 {
            intensity = .high
        } else if bestScore == 2 {
            intensity = .medium
        } else {
            intensity = .low
        }
        
        // 计算置信度
        let confidence = min(bestScore / 3.0, 1.0)
        
        let result = EmotionAnalysisResult(
            emotion: emotion,
            intensity: intensity,
            confidence: confidence,
            detectedAt: Date(),
            context: text,
            triggers: triggers
        )
        
        // 保存到历史
        currentEmotion = emotion
        emotionHistory.append(result)
        saveEmotionHistory()
        
        // 更新趋势
        updateEmotionTrends(result)
        
        return result
    }
    
    // MARK: - Emotion Response
    
    /// 根据情绪生成响应策略
    func getResponseStrategy(for emotion: EmotionType, intensity: EmotionIntensity) -> EmotionResponseStrategy {
        switch emotion {
        case .happy, .excited, .grateful, .proud, .hopeful:
            return .accompany
            
        case .sad, .disappointed, .guilty, .ashamed, .lonely:
            if intensity == .veryHigh {
                return .urgent
            } else {
                return .comfort
            }
            
        case .angry, .fear, .anxiety:
            if intensity == .veryHigh {
                return .urgent
            } else if intensity == .high {
                return .guide
            } else {
                return .encourage
            }
            
        case .stress, .tired:
            return .guide
            
        case .surprised, .confused:
            return .professional
            
        case .disgust, .jealous, .embarrassed:
            return .humor
        }
    }
    
    /// 生成情感响应文本
    func generateEmotionalResponse(for result: EmotionAnalysisResult) -> String {
        let strategy = getResponseStrategy(for: result.emotion, intensity: result.intensity)
        
        switch strategy {
        case .accompany:
            return generateAccompanyResponse(for: result.emotion)
            
        case .comfort:
            return generateComfortResponse(for: result.emotion)
            
        case .guide:
            return generateGuideResponse(for: result.emotion)
            
        case .encourage:
            return generateEncourageResponse(for: result.emotion)
            
        case .humor:
            return generateHumorResponse(for: result.emotion)
            
        case .professional:
            return generateProfessionalResponse(for: result.emotion)
            
        case .urgent:
            return generateUrgentResponse(for: result.emotion)
        }
    }
    
    // MARK: - Response Generators
    
    private func generateAccompanyResponse(for emotion: EmotionType) -> String {
        let responses = [
            "太好了！看来你今天心情不错呀~分享一下吧~",
            "很高兴看到你这么开心！我也跟着开心~",
            "哇，今天看起来很棒！继续保持好心情~",
            "看来你今天遇到好事了？快告诉我吧~"
        ]
        return responses.randomElement() ?? "很高兴看到你这么开心！"
    }
    
    private func generateComfortResponse(for emotion: EmotionType) -> String {
        let responses = [
            "怎么了？需要我陪你聊聊天吗？或者推荐一些轻松的音乐？",
            "别难过，一切都会好起来的。我一直在你身边~",
            "想哭就哭吧，发泄出来会好受一些。我会陪着你~",
            "不开心的时候，我会一直陪着你的。慢慢来~"
        ]
        return responses.randomElement() ?? "别难过，我会陪着你的~"
    }
    
    private func generateGuideResponse(for emotion: EmotionType) -> String {
        let responses = [
            "别生气啦，气坏了身体自己受罪。要不要发泄一下？",
            "你最近是不是压力很大？要不要我帮你放松一下？",
            "累了就休息一下吧，身体最重要~",
            "深呼吸，放松一下，慢慢来，别着急~"
        ]
        return responses.randomElement() ?? "别太勉强自己，休息一下吧~"
    }
    
    private func generateEncourageResponse(for emotion: EmotionType) -> String {
        let responses = [
            "别担心，我会帮你的。我们一起想想办法吧~",
            "我相信你能行！加油！",
            "你可以的！不要放弃~",
            "坚持一下，很快就会过去的~"
        ]
        return responses.randomElement() ?? "你能行的，加油！"
    }
    
    private func generateHumorResponse(for emotion: EmotionType) -> String {
        let responses = [
            "哈哈，别这样嘛，开心点~",
            "哎呀，别生气了，我给你讲个笑话吧~",
            "没事的，小问题~",
            "别太在意这些小事啦~"
        ]
        return responses.randomElement() ?? "哈哈，别太在意啦~"
    }
    
    private func generateProfessionalResponse(for emotion: EmotionType) -> String {
        let responses = [
            "我明白你的意思，需要我帮你解决什么问题？",
            "你的情况我了解了，需要我提供什么帮助？",
            "我明白了，有什么我可以帮你的吗？",
            "好的，我理解了，接下来需要做什么？"
        ]
        return responses.randomElement() ?? "我明白了，需要我帮你解决什么问题？"
    }
    
    private func generateUrgentResponse(for emotion: EmotionType) -> String {
        let responses = [
            "你现在情绪很糟糕，我建议你找人聊聊，或者寻求专业帮助。",
            "我注意到你的情绪很不稳定，建议你休息一下，或者找人聊聊。",
            "你的情绪需要关注，建议你寻求专业帮助，或者找个朋友聊聊。",
            "我担心你的状态，建议你休息一下，或者寻求专业帮助。"
        ]
        return responses.randomElement() ?? "你的情绪需要关注，建议你寻求专业帮助。"
    }
    
    // MARK: - Emotion Trends
    
    private func updateEmotionTrends(_ result: EmotionAnalysisResult) {
        let key = result.emotion.rawValue
        if emotionTrends[key] == nil {
            emotionTrends[key] = []
        }
        emotionTrends[key]?.append(result)
        
        // 只保留最近30条记录
        if let trends = emotionTrends[key], trends.count > 30 {
            emotionTrends[key] = Array(trends.suffix(30))
        }
    }
    
    /// 获取情绪趋势
    func getEmotionTrends(for emotion: EmotionType, limit: Int = 7) -> [EmotionAnalysisResult] {
        guard let trends = emotionTrends[emotion.rawValue] else {
            return []
        }
        return Array(trends.suffix(limit))
    }
    
    /// 获取最近的负面情绪
    func getRecentNegativeEmotions(limit: Int = 5) -> [EmotionAnalysisResult] {
        let negativeEmotions: [EmotionType] = [
            .sad, .angry, .fear, .anxiety, .stress, .tired, 
            .disappointed, .guilty, .ashamed, .lonely, .jealous
        ]
        
        return emotionHistory.filter { negativeEmotions.contains($0.emotion) }
            .suffix(limit)
    }
    
    // MARK: - Persistence
    
    private func saveEmotionHistory() {
        guard let data = try? JSONEncoder().encode(emotionHistory) else { return }
        UserDefaults.standard.set(data, forKey: "caogen_emotion_history")
    }
    
    private func loadEmotionHistory() {
        guard let data = UserDefaults.standard.data(forKey: "caogen_emotion_history"),
              let history = try? JSONDecoder().decode([EmotionAnalysisResult].self, from: data) else {
            return
        }
        
        emotionHistory = history
        
        // 重建趋势数据
        for result in emotionHistory {
            updateEmotionTrends(result)
        }
    }
    
    /// 清除情绪历史
    func clearEmotionHistory() {
        emotionHistory.removeAll()
        emotionTrends.removeAll()
        saveEmotionHistory()
    }
}
