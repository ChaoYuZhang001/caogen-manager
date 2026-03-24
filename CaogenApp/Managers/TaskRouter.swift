import Foundation
import Network
import Combine

/// 网络状态监控器
/// 负责检测网络状态，智能选择本地或云端处理
class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    enum ConnectionType {
        case wifi
        case cellular
        case none
        case other
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.status == .satisfied {
                    self?.connectionType = .other
                } else {
                    self?.connectionType = .none
                }

                print("网络状态: \(self?.isConnected == true ? "在线" : "离线")")
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}

/// 任务类型
enum TaskType {
    case voiceMemo
    case expenseRecord
    case habit
    case lifeRecord
    case collection
    case chatMessage
    case weatherQuery
    case translation
    case ocr
    case documentParsing
}

/// 任务优先级
enum TaskPriority {
    case high    // 高优先级，必须云端处理
    case medium  // 中等优先级，优先本地
    case low     // 低优先级，可以本地处理
}

/// 智能任务路由器
/// 负责智能选择本地或云端处理任务
class TaskRouter: ObservableObject {

    static let shared = TaskRouter()

    @Published var currentMode: ProcessingMode = .online
    @Published var pendingTasks: [PendingTask] = []

    private var networkMonitor = NetworkMonitor.shared

    enum ProcessingMode {
        case online    // 在线模式：使用云端
        case offline   // 离线模式：使用本地
        case hybrid    // 混合模式：智能选择
    }

    private init() {
        // 监听网络状态变化
        networkMonitor.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] isConnected in
                self?.updateProcessingMode(isConnected: isConnected)
            }
            .store(in: &cancellables)

        // 当恢复在线时，处理待处理任务
        networkMonitor.$isConnected
            .dropFirst()
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.processPendingTasks()
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - 模式切换

    private func updateProcessingMode(isConnected: Bool) {
        currentMode = isConnected ? .online : .offline
        print("当前处理模式: \(currentMode)")
    }

    // MARK: - 任务路由

    /// 路由任务到合适的处理器
    func routeTask(
        taskType: TaskType,
        data: Any,
        completion: @escaping (Result<Any, Error>) -> Void
    ) {
        let priority = getTaskPriority(for: taskType)
        let shouldUseCloud = shouldUseCloud(taskType: taskType, priority: priority)

        if shouldUseCloud && networkMonitor.isConnected {
            // 云端处理
            processOnCloud(taskType: taskType, data: data, completion: completion)
        } else {
            // 本地处理
            processLocally(taskType: taskType, data: data, completion: completion)
        }
    }

    /// 判断是否应该使用云端处理
    private func shouldUseCloud(taskType: TaskType, priority: TaskPriority) -> Bool {
        switch priority {
        case .high:
            return true  // 高优先级任务必须云端处理
        case .medium:
            return networkMonitor.isConnected && networkMonitor.connectionType == .wifi
        case .low:
            return false  // 低优先级任务优先本地处理
        }
    }

    /// 获取任务优先级
    private func getTaskPriority(for taskType: TaskType) -> TaskPriority {
        switch taskType {
        case .weatherQuery,
             .translation,
             .ocr,
             .documentParsing:
            return .high  // 需要 AI 能力，必须云端

        case .chatMessage:
            return .medium  // 可以本地，但云端更好

        case .voiceMemo,
             .expenseRecord,
             .habit,
             .lifeRecord,
             .collection:
            return .low  // 完全可以本地处理
        }
    }

    // MARK: - 本地处理

    private func processLocally(
        taskType: TaskType,
        data: Any,
        completion: @escaping (Result<Any, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try self.handleLocalTask(taskType: taskType, data: data)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func handleLocalTask(taskType: TaskType, data: Any) throws -> Any {
        let dataManager = DataManager.shared

        switch taskType {
        case .voiceMemo:
            guard let params = data as? [String: Any],
                  let title = params["title"] as? String,
                  let content = params["content"] as? String else {
                throw TaskError.invalidData
            }
            let memo = dataManager.createVoiceMemo(
                title: title,
                content: content,
                audioURL: params["audioURL"] as? String,
                duration: params["duration"] as? Double ?? 0.0
            )
            return memo

        case .expenseRecord:
            guard let params = data as? [String: Any],
                  let amount = params["amount"] as? Double,
                  let category = params["category"] as? String else {
                throw TaskError.invalidData
            }
            let record = dataManager.createExpenseRecord(
                amount: amount,
                category: category,
                description: params["description"] as? String,
                paymentMethod: params["paymentMethod"] as? String
            )
            return record

        case .habit:
            guard let params = data as? [String: Any],
                  let title = params["title"] as? String else {
                throw TaskError.invalidData
            }
            let habit = dataManager.createHabit(
                title: title,
                description: params["description"] as? String,
                frequency: params["frequency"] as? String ?? "daily",
                targetDays: params["targetDays"] as? Int ?? 30
            )
            return habit

        case .lifeRecord:
            guard let params = data as? [String: Any],
                  let type = params["type"] as? String,
                  let content = params["content"] as? String else {
                throw TaskError.invalidData
            }
            let record = dataManager.createLifeRecord(
                type: type,
                content: content,
                mood: params["mood"] as? String,
                location: params["location"] as? String
            )
            return record

        case .collection:
            guard let params = data as? [String: Any],
                  let title = params["title"] as? String,
                  let content = params["content"] as? String,
                  let category = params["category"] as? String else {
                throw TaskError.invalidData
            }
            let item = dataManager.createCollectionItem(
                title: title,
                content: content,
                category: category,
                tags: params["tags"] as? String,
                sourceURL: params["sourceURL"] as? String
            )
            return item

        case .chatMessage:
            guard let params = data as? [String: Any],
                  let content = params["content"] as? String else {
                throw TaskError.invalidData
            }
            let message = dataManager.createChatMessage(
                content: content,
                isUser: params["isUser"] as? Bool ?? true,
                metadata: params["metadata"] as? String
            )
            return message

        case .weatherQuery,
             .translation,
             .ocr,
             .documentParsing:
            // 这些任务需要云端处理，但当前在离线模式下
            throw TaskError.cloudRequired

        }
    }

    // MARK: - 云端处理

    private func processOnCloud(
        taskType: TaskType,
        data: Any,
        completion: @escaping (Result<Any, Error>) -> Void
    ) {
        // TODO: 实现云端处理
        // 这里会调用后端 API 或 OpenClaw Gateway

        print("云端处理任务: \(taskType)")

        // 模拟云端处理延迟
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
            DispatchQueue.main.async {
                completion(.success("云端处理完成"))
            }
        }
    }

    // MARK: - 待处理任务队列

    /// 添加待处理任务
    func addPendingTask(_ task: PendingTask) {
        pendingTasks.append(task)
        print("添加待处理任务: \(task.taskType)，总数: \(pendingTasks.count)")
    }

    /// 处理所有待处理任务
    private func processPendingTasks() {
        guard !pendingTasks.isEmpty else { return }

        print("开始处理待处理任务，数量: \(pendingTasks.count)")

        for task in pendingTasks {
            routeTask(taskType: task.taskType, data: task.data) { result in
                switch result {
                case .success(let result):
                    print("待处理任务处理成功: \(task.taskType)")
                case .failure(let error):
                    print("待处理任务处理失败: \(task.taskType), 错误: \(error)")
                }
            }
        }

        pendingTasks.removeAll()
    }

    /// 清空待处理任务
    func clearPendingTasks() {
        pendingTasks.removeAll()
    }
}

// MARK: - 待处理任务

struct PendingTask {
    let id = UUID()
    let taskType: TaskType
    let data: Any
    let createdAt = Date()
}

// MARK: - 错误

enum TaskError: Error {
    case invalidData
    case cloudRequired
    case networkUnavailable
    case processingFailed
}
