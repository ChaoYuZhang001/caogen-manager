//
//  PersonalizationEngine.swift
//  CaogenApp
//
//  Created by Caogen Team on 2026-03-26.
//  个性化推荐引擎 - 基于用户画像，推荐最适合用户的内容
//

import Foundation
import Combine
import SwiftData

// MARK: - User Profile
struct UserProfile: Codable {
    var id: UUID
    var age: Int?
    var gender: String?
    var occupation: String?
    var location: String?
    var interests: [String]
    var preferences: [String: String]
    var habits: [String]
    var goals: [String]
    var painPoints: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID()) {
        self.id = id
        self.interests = []
        self.preferences = [:]
        self.habits = []
        self.goals = []
        self.painPoints = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Recommendation Item
struct RecommendationItem: Identifiable, Codable {
    let id: UUID
    let category: String
    let title: String
    let description: String
    let relevanceScore: Double // 0.0 - 1.0
    let source: String // "profile", "context", "collaborative", "content"
    let createdAt: Date
    var isClicked: Bool = false
    var isLiked: Bool = false
}

// MARK: - Personalization Engine
@MainActor
class PersonalizationEngine: ObservableObject {
    static let shared = PersonalizationEngine()
    
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var recommendations: [RecommendationItem] = []
    @Published private(set) var isProfileInitialized = false
    
    private let deepMemory = DeepMemoryManager.shared
    
    private init() {
        loadUserProfile()
    }
    
    // MARK: - Profile Management
    
    /// 初始化用户画像
    func initializeProfile() {
        var profile = UserProfile()
        
        // 从深度记忆加载基本信息
        if let age = deepMemory.retrieve(key: "age", category: .preferences)?.value {
            profile.age = Int(age)
        }
        
        if let gender = deepMemory.retrieve(key: "gender", category: .preferences)?.value {
            profile.gender = gender
        }
        
        if let occupation = deepMemory.retrieve(key: "occupation", category: .preferences)?.value {
            profile.occupation = occupation
        }
        
        // 加载兴趣
        profile.interests = deepMemory.search(query: "", category: .habits).map { $0.key }
        
        // 加载偏好
        let preferences = deepMemory.search(query: "", category: .preferences)
        for pref in preferences {
            profile.preferences[pref.key] = pref.value
        }
        
        // 加载习惯
        profile.habits = deepMemory.search(query: "", category: .habits).map { $0.key }
        
        // 加载目标
        profile.goals = deepMemory.search(query: "", category: .goals).map { $0.key }
        
        // 加载痛点
        profile.painPoints = deepMemory.search(query: "", category: .painPoints).map { $0.key }
        
        userProfile = profile
        isProfileInitialized = true
        saveUserProfile()
        
        print("🎨 用户画像已初始化")
    }
    
    /// 更新用户画像
    func updateProfile(key: String, value: String, category: MemoryCategory) {
        var profile = userProfile ?? UserProfile()
        
        switch category {
        case .preferences:
            profile.preferences[key] = value
            
        case .habits:
            if !profile.habits.contains(key) {
                profile.habits.append(key)
            }
            
        case .goals:
            if !profile.goals.contains(key) {
                profile.goals.append(key)
            }
            
        case .painPoints:
            if !profile.painPoints.contains(key) {
                profile.painPoints.append(key)
            }
            
        default:
            break
        }
        
        profile.updatedAt = Date()
        userProfile = profile
        saveUserProfile()
    }
    
    // MARK: - Recommendation Generation
    
    /// 生成推荐
    func generateRecommendations(context: [String: Any] = [:]) -> [RecommendationItem] {
        guard let profile = userProfile else {
            initializeProfile()
            return []
        }
        
        var items: [RecommendationItem] = []
        
        // 基于画像推荐
        let profileRecommendations = generateProfileBasedRecommendations(profile: profile, context: context)
        items.append(contentsOf: profileRecommendations)
        
        // 基于上下文推荐
        let contextRecommendations = generateContextBasedRecommendations(profile: profile, context: context)
        items.append(contentsOf: contextRecommendations)
        
        // 基于协同过滤推荐
        let collaborativeRecommendations = generateCollaborativeRecommendations(profile: profile)
        items.append(contentsOf: collaborativeRecommendations)
        
        // 按相关性排序
        items.sort { $0.relevanceScore > $1.relevanceScore }
        
        // 只保留前20个
        recommendations = Array(items.prefix(20))
        saveRecommendations()
        
        return recommendations
    }
    
    // MARK: - Profile-Based Recommendations
    
    private func generateProfileBasedRecommendations(profile: UserProfile, context: [String: Any]) -> [RecommendationItem] {
        var recommendations: [RecommendationItem] = []
        
        // 基于兴趣推荐
        for interest in profile.interests {
            if interest.contains("音乐") {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "娱乐",
                    title: "推荐音乐：\(interest)",
                    description: "根据你的兴趣，推荐\(interest)相关的音乐",
                    relevanceScore: 0.8,
                    source: "profile",
                    createdAt: Date()
                ))
            }
            
            if interest.contains("运动") {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "健康",
                    title: "运动建议：\(interest)",
                    description: "根据你的运动习惯，推荐\(interest)",
                    relevanceScore: 0.85,
                    source: "profile",
                    createdAt: Date()
                ))
            }
            
            if interest.contains("美食") || interest.contains("食物") {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "美食",
                    title: "美食推荐：\(interest)",
                    description: "根据你的喜好，推荐\(interest)",
                    relevanceScore: 0.9,
                    source: "profile",
                    createdAt: Date()
                ))
            }
        }
        
        // 基于偏好推荐
        if let foodPreference = profile.preferences["food"] {
            recommendations.append(RecommendationItem(
                id: UUID(),
                category: "美食",
                title: "美食偏好推荐",
                description: "根据你的喜好，推荐\(foodPreference)的食物",
                relevanceScore: 0.95,
                source: "profile",
                createdAt: Date()
            ))
        }
        
        if let musicPreference = profile.preferences["music"] {
            recommendations.append(RecommendationItem(
                id: UUID(),
                category: "娱乐",
                title: "音乐偏好推荐",
                description: "根据你的喜好，推荐\(musicPreference)的音乐",
                relevanceScore: 0.9,
                source: "profile",
                createdAt: Date()
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Context-Based Recommendations
    
    private func generateContextBasedRecommendations(profile: UserProfile, context: [String: Any]) -> [RecommendationItem] {
        var recommendations: [RecommendationItem] = []
        
        // 根据时间推荐
        if let time = context["time"] as? Date {
            let hour = Calendar.current.component(.hour, from: time)
            
            if hour >= 7 && hour <= 9 {
                // 早上
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "生活",
                    title: "早安推荐",
                    description: "早上好！推荐一些适合早晨的内容",
                    relevanceScore: 0.8,
                    source: "context",
                    createdAt: Date()
                ))
            } else if hour >= 12 && hour <= 13 {
                // 中午
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "美食",
                    title: "午餐推荐",
                    description: "午餐时间到了！推荐一些美食",
                    relevanceScore: 0.85,
                    source: "context",
                    createdAt: Date()
                ))
            } else if hour >= 18 && hour <= 19 {
                // 晚上
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "生活",
                    title: "晚餐推荐",
                    description: "晚餐时间到了！推荐一些美食",
                    relevanceScore: 0.85,
                    source: "context",
                    createdAt: Date()
                ))
            } else if hour >= 21 && hour <= 22 {
                // 深夜
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "娱乐",
                    title: "放松推荐",
                    description: "准备休息了！推荐一些放松的内容",
                    relevanceScore: 0.8,
                    source: "context",
                    createdAt: Date()
                ))
            }
        }
        
        // 根据天气推荐
        if let weather = context["weather"] as? String {
            if weather.contains("雨") {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "出行",
                    title: "雨天提醒",
                    description: "下雨天，记得带伞！推荐室内活动",
                    relevanceScore: 0.9,
                    source: "context",
                    createdAt: Date()
                ))
            } else if weather.contains("晴") {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "出行",
                    title: "晴天推荐",
                    description: "天气不错！推荐户外活动",
                    relevanceScore: 0.85,
                    source: "context",
                    createdAt: Date()
                ))
            }
        }
        
        // 根据情绪推荐
        if let emotion = context["emotion"] as? String {
            if emotion.contains("难过") || emotion.contains("伤心") {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "情绪",
                    title: "情绪安抚",
                    description: "你看起来心情不太好，推荐一些放松的内容",
                    relevanceScore: 0.9,
                    source: "context",
                    createdAt: Date()
                ))
            } else if emotion.contains("开心") || emotion.contains("高兴") {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "情绪",
                    title: "心情分享",
                    description: "你看起来很开心！分享你的快乐吧",
                    relevanceScore: 0.85,
                    source: "context",
                    createdAt: Date()
                ))
            }
        }
        
        return recommendations
    }
    
    // MARK: - Collaborative Recommendations
    
    private func generateCollaborativeRecommendations(profile: UserProfile) -> [RecommendationItem] {
        // 简化版协同过滤
        // 在实际应用中，应该基于用户相似度计算
        var recommendations: [RecommendationItem] = []
        
        // 基于年龄推荐
        if let age = profile.age {
            if age >= 18 && age <= 25 {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "娱乐",
                    title: "年轻人推荐",
                    description: "根据你的年龄，推荐一些年轻人喜欢的内容",
                    relevanceScore: 0.7,
                    source: "collaborative",
                    createdAt: Date()
                ))
            } else if age >= 26 && age <= 35 {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "生活",
                    title: "青年推荐",
                    description: "根据你的年龄，推荐一些适合青年生活内容",
                    relevanceScore: 0.7,
                    source: "collaborative",
                    createdAt: Date()
                ))
            } else if age >= 36 && age <= 50 {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "生活",
                    title: "中年推荐",
                    description: "根据你的年龄，推荐一些适合中年生活内容",
                    relevanceScore: 0.7,
                    source: "collaborative",
                    createdAt: Date()
                ))
            }
        }
        
        // 基于职业推荐
        if let occupation = profile.occupation {
            if occupation.contains("学生") || occupation.contains("学习") {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "学习",
                    title: "学生推荐",
                    description: "根据你的职业，推荐一些学习内容",
                    relevanceScore: 0.75,
                    source: "collaborative",
                    createdAt: Date()
                ))
            } else if occupation.contains("工作") || occupation.contains("上班") {
                recommendations.append(RecommendationItem(
                    id: UUID(),
                    category: "工作",
                    title: "上班族推荐",
                    description: "根据你的职业，推荐一些工作相关内容",
                    relevanceScore: 0.75,
                    source: "collaborative",
                    createdAt: Date()
                ))
            }
        }
        
        return recommendations
    }
    
    // MARK: - Feedback Handling
    
    /// 用户点击推荐
    func recordRecommendationClick(id: UUID) {
        if let index = recommendations.firstIndex(where: { $0.id == id }) {
            recommendations[index].isClicked = true
            
            // 更新深度记忆
            let item = recommendations[index]
            deepMemory.store(
                key: "clicked_\(item.category)_\(item.title)",
                value: "1",
                category: .habits,
                type: .mediumTerm,
                importance: 0.6
            )
            
            saveRecommendations()
        }
    }
    
    /// 用户喜欢推荐
    func recordRecommendationLike(id: UUID) {
        if let index = recommendations.firstIndex(where: { $0.id == id }) {
            recommendations[index].isLiked = true
            
            // 更新深度记忆
            let item = recommendations[index]
            deepMemory.store(
                key: "liked_\(item.category)_\(item.title)",
                value: "1",
                category: .preferences,
                type: .longTerm,
                importance: 0.8
            )
            
            saveRecommendations()
        }
    }
    
    // MARK: - Persistence
    
    private func saveUserProfile() {
        guard let profile = userProfile else { return }
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: "caogen_user_profile")
    }
    
    private func loadUserProfile() {
        guard let data = UserDefaults.standard.data(forKey: "caogen_user_profile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return
        }
        
        userProfile = profile
        isProfileInitialized = true
    }
    
    private func saveRecommendations() {
        guard let data = try? JSONEncoder().encode(recommendations) else { return }
        UserDefaults.standard.set(data, forKey: "caogen_recommendations")
    }
    
    /// 清除推荐数据
    func clearRecommendations() {
        recommendations.removeAll()
        saveRecommendations()
    }
}
