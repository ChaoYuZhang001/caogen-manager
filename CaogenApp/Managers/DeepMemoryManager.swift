//
//  DeepMemoryManager.swift
//  CaogenApp
//
//  Created by Caogen Team on 2026-03-26.
//  深度记忆系统 - 记住用户的一切：喜好、习惯、关系、目标
//

import Foundation
import SwiftData
import Combine

// MARK: - Memory Type
enum MemoryType {
    case shortTerm    // 短期记忆：7天
    case mediumTerm   // 中期记忆：30天
    case longTerm     // 长期记忆：永久
}

// MARK: - Memory Category
enum MemoryCategory: String, CaseIterable {
    case preferences  // 偏好
    case habits       // 习惯
    case relationships // 关系
    case goals        // 目标
    case painPoints   // 痛点
    case events       // 事件
    case locations    // 地点
}

// MARK: - Memory Item
struct MemoryItem: Identifiable, Codable {
    let id: UUID
    var type: MemoryType
    var category: MemoryCategory
    var key: String
    var value: String
    var timestamp: Date
    var lastAccessed: Date
    var accessCount: Int
    var importance: Double // 0.0 - 1.0, 重要性
    var tags: [String]
    var metadata: [String: String]
    
    var isExpired: Bool {
        switch type {
        case .shortTerm:
            return Date().timeIntervalSince(timestamp) > 7 * 24 * 3600
        case .mediumTerm:
            return Date().timeIntervalSince(timestamp) > 30 * 24 * 3600
        case .longTerm:
            return false
        }
    }
    
    init(id: UUID = UUID(), type: MemoryType, category: MemoryCategory, key: String, value: String, importance: Double = 0.5, tags: [String] = [], metadata: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.category = category
        self.key = key
        self.value = value
        self.timestamp = Date()
        self.lastAccessed = Date()
        self.accessCount = 0
        self.importance = importance
        self.tags = tags
        self.metadata = metadata
    }
}

// MARK: - Deep Memory Manager
@MainActor
class DeepMemoryManager: ObservableObject {
    static let shared = DeepMemoryManager()
    
    @Published private(set) var memories: [MemoryItem] = []
    @Published private(set) var isInitialized = false
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        loadMemories()
    }
    
    // MARK: - Core Functions
    
    /// 存储记忆
    func store(key: String, value: String, category: MemoryCategory, type: MemoryType = .shortTerm, importance: Double = 0.5, tags: [String] = []) {
        // 检查是否已存在
        if let existingIndex = memories.firstIndex(where: { $0.key == key && $0.category == category }) {
            // 更新现有记忆
            memories[existingIndex].value = value
            memories[existingIndex].lastAccessed = Date()
            memories[existingIndex].accessCount += 1
            memories[existingIndex].type = type // 更新类型
            memories[existingIndex].importance = importance
            memories[existingIndex].tags = tags
        } else {
            // 创建新记忆
            let newMemory = MemoryItem(type: type, category: category, key: key, value: value, importance: importance, tags: tags)
            memories.append(newMemory)
        }
        
        saveMemories()
        cleanupExpiredMemories()
    }
    
    /// 检索记忆
    func retrieve(key: String, category: MemoryCategory? = nil) -> MemoryItem? {
        let filteredMemories = memories.filter { memory in
            memory.key == key && (category == nil || memory.category == category)
        }
        
        if let memory = filteredMemories.first {
            // 更新访问记录
            if let index = memories.firstIndex(where: { $0.id == memory.id }) {
                memories[index].lastAccessed = Date()
                memories[index].accessCount += 1
                saveMemories()
            }
            return memory
        }
        
        return nil
    }
    
    /// 搜索记忆
    func search(query: String, category: MemoryCategory? = nil, limit: Int = 10) -> [MemoryItem] {
        var results = memories.filter { memory in
            let matchQuery = memory.value.localizedCaseInsensitiveContains(query) ||
                           memory.key.localizedCaseInsensitiveContains(query) ||
                           memory.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            
            let matchCategory = category == nil || memory.category == category
            
            return matchQuery && matchCategory && !memory.isExpired
        }
        
        // 按重要性和访问次数排序
        results.sort { $0.importance > $1.importance || $0.accessCount > $1.accessCount }
        
        return Array(results.prefix(limit))
    }
    
    /// 删除记忆
    func delete(key: String, category: MemoryCategory) {
        memories.removeAll { $0.key == key && $0.category == category }
        saveMemories()
    }
    
    /// 清理过期记忆
    func cleanupExpiredMemories() {
        let before = memories.count
        memories.removeAll { $0.isExpired && $0.type != .longTerm }
        let after = memories.count
        
        if before != after {
            print("🧠 清理了 \(before - after) 条过期记忆")
            saveMemories()
        }
    }
    
    /// 升级记忆类型
    func upgradeToLongTerm(key: String, category: MemoryCategory) {
        if let index = memories.firstIndex(where: { $0.key == key && $0.category == category }) {
            memories[index].type = .longTerm
            saveMemories()
        }
    }
    
    // MARK: - Convenience Functions
    
    /// 记住用户偏好
    func rememberPreference(_ key: String, value: String, importance: Double = 0.7) {
        store(key: key, value: value, category: .preferences, type: .longTerm, importance: importance, tags: ["preference"])
    }
    
    /// 记住用户习惯
    func rememberHabit(_ key: String, value: String, importance: Double = 0.6) {
        store(key: key, value: value, category: .habits, type: .mediumTerm, importance: importance, tags: ["habit"])
    }
    
    /// 记住用户关系
    func rememberRelationship(_ key: String, value: String, importance: Double = 0.8) {
        store(key: key, value: value, category: .relationships, type: .longTerm, importance: importance, tags: ["relationship"])
    }
    
    /// 记住用户目标
    func rememberGoal(_ key: String, value: String, importance: Double = 0.9) {
        store(key: key, value: value, category: .goals, type: .longTerm, importance: importance, tags: ["goal"])
    }
    
    /// 记住用户痛点
    func rememberPainPoint(_ key: String, value: String, importance: Double = 0.7) {
        store(key: key, value: value, category: .painPoints, type: .mediumTerm, importance: importance, tags: ["pain"])
    }
    
    // MARK: - Memory Analysis
    
    /// 获取用户画像
    func getUserProfile() -> [String: Any] {
        var profile: [String: Any] = [:]
        
        // 偏好
        let preferences = memories.filter { $0.category == .preferences }
        profile["preferences"] = preferences.map { ["key": $0.key, "value": $0.value] }
        
        // 习惯
        let habits = memories.filter { $0.category == .habits }
        profile["habits"] = habits.map { ["key": $0.key, "value": $0.value] }
        
        // 关系
        let relationships = memories.filter { $0.category == .relationships }
        profile["relationships"] = relationships.map { ["key": $0.key, "value": $0.value] }
        
        // 目标
        let goals = memories.filter { $0.category == .goals }
        profile["goals"] = goals.map { ["key": $0.key, "value": $0.value] }
        
        // 痛点
        let painPoints = memories.filter { $0.category == .painPoints }
        profile["painPoints"] = painPoints.map { ["key": $0.key, "value": $0.value] }
        
        return profile
    }
    
    /// 获取统计信息
    func getStatistics() -> [String: Int] {
        return [
            "totalMemories": memories.count,
            "shortTerm": memories.filter { $0.type == .shortTerm }.count,
            "mediumTerm": memories.filter { $0.type == .mediumTerm }.count,
            "longTerm": memories.filter { $0.type == .longTerm }.count,
            "preferences": memories.filter { $0.category == .preferences }.count,
            "habits": memories.filter { $0.category == .habits }.count,
            "relationships": memories.filter { $0.category == .relationships }.count,
            "goals": memories.filter { $0.category == .goals }.count,
            "painPoints": memories.filter { $0.category == .painPoints }.count
        ]
    }
    
    // MARK: - Persistence
    
    private func saveMemories() {
        do {
            let data = try encoder.encode(memories)
            UserDefaults.standard.set(data, forKey: "caogen_deep_memories")
        } catch {
            print("❌ 保存记忆失败: \(error)")
        }
    }
    
    private func loadMemories() {
        guard let data = UserDefaults.standard.data(forKey: "caogen_deep_memories") else {
            isInitialized = true
            return
        }
        
        do {
            memories = try decoder.decode([MemoryItem].self, from: data)
            cleanupExpiredMemories()
            isInitialized = true
            print("🧠 加载了 \(memories.count) 条记忆")
        } catch {
            print("❌ 加载记忆失败: \(error)")
            memories = []
            isInitialized = true
        }
    }
    
    /// 清除所有记忆
    func clearAllMemories() {
        memories.removeAll()
        saveMemories()
    }
}
