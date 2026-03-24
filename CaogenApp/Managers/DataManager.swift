import CoreData
import Foundation

/// CoreData 数据管理器
/// 负责本地数据的增删改查
class DataManager: ObservableObject {

    static let shared = DataManager()

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CaogenApp")

        // 自动迁移
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // 合并策略
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil

        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Save Context

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("CoreData 保存失败: \(error)")
            }
        }
    }

    // MARK: - VoiceMemo

    /// 创建语音备忘录
    func createVoiceMemo(title: String, content: String, audioURL: String? = nil, duration: Double = 0.0) -> VoiceMemo {
        let memo = VoiceMemo(context: context)
        memo.id = UUID()
        memo.title = title
        memo.content = content
        memo.audioURL = audioURL
        memo.duration = duration
        memo.createdAt = Date()
        memo.updatedAt = Date()
        memo.isSynced = false

        save()
        return memo
    }

    /// 获取所有语音备忘录
    func fetchVoiceMemos() -> [VoiceMemo] {
        let request: NSFetchRequest<VoiceMemo> = VoiceMemo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取语音备忘录失败: \(error)")
            return []
        }
    }

    /// 删除语音备忘录
    func deleteVoiceMemo(_ memo: VoiceMemo) {
        context.delete(memo)
        save()
    }

    // MARK: - ExpenseRecord

    /// 创建消费记录
    func createExpenseRecord(amount: Double, category: String, description: String? = nil, paymentMethod: String? = nil) -> ExpenseRecord {
        let record = ExpenseRecord(context: context)
        record.id = UUID()
        record.amount = amount
        record.category = category
        record.description_ = description
        record.paymentMethod = paymentMethod
        record.date = Date()
        record.createdAt = Date()
        record.updatedAt = Date()
        record.isSynced = false

        save()
        return record
    }

    /// 获取所有消费记录
    func fetchExpenseRecords() -> [ExpenseRecord] {
        let request: NSFetchRequest<ExpenseRecord> = ExpenseRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取消费记录失败: \(error)")
            return []
        }
    }

    /// 按月份获取消费记录
    func fetchExpenseRecords(month: Int, year: Int) -> [ExpenseRecord] {
        let request: NSFetchRequest<ExpenseRecord> = ExpenseRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, endOfMonth as NSDate)

        do {
            return try context.fetch(request)
        } catch {
            print("获取消费记录失败: \(error)")
            return []
        }
    }

    /// 删除消费记录
    func deleteExpenseRecord(_ record: ExpenseRecord) {
        context.delete(record)
        save()
    }

    // MARK: - Habit

    /// 创建习惯
    func createHabit(title: String, description: String? = nil, frequency: String = "daily", targetDays: Int = 30) -> Habit {
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.title = title
        habit.description_ = description
        habit.frequency = frequency
        habit.targetDays = Int32(targetDays)
        habit.completedDays = 0
        habit.createdAt = Date()
        habit.updatedAt = Date()
        habit.isSynced = false

        save()
        return habit
    }

    /// 获取所有习惯
    func fetchHabits() -> [Habit] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取习惯失败: \(error)")
            return []
        }
    }

    /// 更新习惯完成天数
    func updateHabitCompletion(_ habit: Habit, increment: Bool = true) {
        if increment {
            habit.completedDays += 1
        }
        habit.updatedAt = Date()
        habit.isSynced = false
        save()
    }

    /// 删除习惯
    func deleteHabit(_ habit: Habit) {
        context.delete(habit)
        save()
    }

    // MARK: - LifeRecord

    /// 创建生活记录
    func createLifeRecord(type: String, content: String, mood: String? = nil, location: String? = nil) -> LifeRecord {
        let record = LifeRecord(context: context)
        record.id = UUID()
        record.type = type
        record.content = content
        record.mood = mood
        record.location = location
        record.date = Date()
        record.createdAt = Date()
        record.updatedAt = Date()
        record.isSynced = false

        save()
        return record
    }

    /// 获取所有生活记录
    func fetchLifeRecords() -> [LifeRecord] {
        let request: NSFetchRequest<LifeRecord> = LifeRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取生活记录失败: \(error)")
            return []
        }
    }

    /// 删除生活记录
    func deleteLifeRecord(_ record: LifeRecord) {
        context.delete(record)
        save()
    }

    // MARK: - CollectionItem

    /// 创建收藏项
    func createCollectionItem(title: String, content: String, category: String, tags: String? = nil, sourceURL: String? = nil) -> CollectionItem {
        let item = CollectionItem(context: context)
        item.id = UUID()
        item.title = title
        item.content = content
        item.category = category
        item.tags = tags
        item.sourceURL = sourceURL
        item.createdAt = Date()
        item.updatedAt = Date()
        item.isSynced = false

        save()
        return item
    }

    /// 获取所有收藏项
    func fetchCollectionItems() -> [CollectionItem] {
        let request: NSFetchRequest<CollectionItem> = CollectionItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取收藏项失败: \(error)")
            return []
        }
    }

    /// 按分类获取收藏项
    func fetchCollectionItems(category: String) -> [CollectionItem] {
        let request: NSFetchRequest<CollectionItem> = CollectionItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.predicate = NSPredicate(format: "category == %@", category)

        do {
            return try context.fetch(request)
        } catch {
            print("获取收藏项失败: \(error)")
            return []
        }
    }

    /// 删除收藏项
    func deleteCollectionItem(_ item: CollectionItem) {
        context.delete(item)
        save()
    }

    // MARK: - ChatMessageLocal

    /// 创建本地聊天消息
    func createChatMessage(content: String, isUser: Bool, metadata: String? = nil) -> ChatMessageLocal {
        let message = ChatMessageLocal(context: context)
        message.id = UUID()
        message.content = content
        message.isUser = isUser
        message.timestamp = Date()
        message.metadata = metadata
        message.isSynced = false

        save()
        return message
    }

    /// 获取所有本地聊天消息
    func fetchChatMessages() -> [ChatMessageLocal] {
        let request: NSFetchRequest<ChatMessageLocal> = ChatMessageLocal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取聊天消息失败: \(error)")
            return []
        }
    }

    /// 删除聊天消息
    func deleteChatMessage(_ message: ChatMessageLocal) {
        context.delete(message)
        save()
    }

    /// 清空所有聊天消息
    func clearChatMessages() {
        let request: NSFetchRequest<NSFetchRequestResult> = ChatMessageLocal.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            save()
        } catch {
            print("清空聊天消息失败: \(error)")
        }
    }

    // MARK: - Cloud Sync

    /// 获取需要同步的未同步数据
    func fetchUnsyncedData() -> [Any] {
        var unsyncedData: [Any] = []

        // 获取未同步的语音备忘录
        let voiceMemosRequest: NSFetchRequest<VoiceMemo> = VoiceMemo.fetchRequest()
        voiceMemosRequest.predicate = NSPredicate(format: "isSynced == NO")
        unsyncedData.append(contentsOf: try! context.fetch(voiceMemosRequest))

        // 获取未同步的消费记录
        let expensesRequest: NSFetchRequest<ExpenseRecord> = ExpenseRecord.fetchRequest()
        expensesRequest.predicate = NSPredicate(format: "isSynced == NO")
        unsyncedData.append(contentsOf: try! context.fetch(expensesRequest))

        // 获取未同步的习惯
        let habitsRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        habitsRequest.predicate = NSPredicate(format: "isSynced == NO")
        unsyncedData.append(contentsOf: try! context.fetch(habitsRequest))

        // 获取未同步的生活记录
        let lifeRecordsRequest: NSFetchRequest<LifeRecord> = LifeRecord.fetchRequest()
        lifeRecordsRequest.predicate = NSPredicate(format: "isSynced == NO")
        unsyncedData.append(contentsOf: try! context.fetch(lifeRecordsRequest))

        // 获取未同步的收藏项
        let collectionsRequest: NSFetchRequest<CollectionItem> = CollectionItem.fetchRequest()
        collectionsRequest.predicate = NSPredicate(format: "isSynced == NO")
        unsyncedData.append(contentsOf: try! context.fetch(collectionsRequest))

        return unsyncedData
    }

    /// 标记数据为已同步
    func markAsSynced<T: NSManagedObject>(_ items: [T]) {
        for item in items {
            if let syncableItem = item as? any Syncable {
                syncableItem.isSynced = true
            }
        }
        save()
    }
}

/// 可同步协议
protocol Syncable {
    var isSynced: Bool { get set }
}

// 为所有 CoreData 实体扩展 Syncable 协议
extension VoiceMemo: Syncable {}
extension ExpenseRecord: Syncable {}
extension Habit: Syncable {}
extension LifeRecord: Syncable {}
extension CollectionItem: Syncable {}
extension ChatMessageLocal: Syncable {}
