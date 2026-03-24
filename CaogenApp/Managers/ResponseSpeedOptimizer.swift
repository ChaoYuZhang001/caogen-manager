/**
 * 响应速度优化 - Response Speed Optimization
 * 目标：操作响应时间从 500ms 降低到 200ms 以内
 */

import SwiftUI

/// 响应速度优化器
class ResponseSpeedOptimizer: ObservableObject {
    @Published var currentResponseTime: TimeInterval = 0
    @Published var averageResponseTime: TimeInterval = 0

    private var responseTimes: [TimeInterval] = []
    private let maxSamples = 100

    /// 测量操作响应时间
    func measureResponseTime<T>(_ operation: () async throws -> T) async rethrows -> T {
        let start = Date()

        let result = try await operation()

        let responseTime = Date().timeIntervalSince(start)
        currentResponseTime = responseTime

        updateAverageResponseTime(responseTime)

        print("⚡ 响应时间: \(responseTime * 1000)ms")

        return result
    }

    /// 更新平均响应时间
    private func updateAverageResponseTime(_ time: TimeInterval) {
        responseTimes.append(time)

        if responseTimes.count > maxSamples {
            responseTimes.removeFirst()
        }

        averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
    }

    /// 获取性能报告
    func getPerformanceReport() -> String {
        return """
        📊 响应速度报告
        ━━━━━━━━━━━━━━━━━
        ⚡ 当前响应: \(String(format: "%.0f", currentResponseTime * 1000))ms
        📈 平均响应: \(String(format: "%.0f", averageResponseTime * 1000))ms
        🎯 目标: < 200ms
        ━━━━━━━━━━━━━━━━━
        """
    }
}

/// 智能缓存管理器
class SmartCacheManager {
    private let cache = NSCache<NSString, CacheEntry>()

    init() {
        // 设置缓存限制
        cache.countLimit = 100 // 最多 100 个对象
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        print("💾 智能缓存已初始化")
    }

    /// 缓存条目
    private class CacheEntry {
        let value: Any
        let expirationTime: Date
        let accessCount: Int
        let lastAccessTime: Date

        init(value: Any, ttl: TimeInterval = 300) {
            self.value = value
            self.expirationTime = Date().addingTimeInterval(ttl)
            self.accessCount = 1
            self.lastAccessTime = Date()
        }

        func isExpired() -> Bool {
            return Date() > expirationTime
        }

        func access() -> CacheEntry {
            return CacheEntry(
                value: value,
                ttl: expirationTime.timeIntervalSinceNow,
                accessCount: accessCount + 1,
                lastAccessTime: Date()
            )
        }
    }

    /// 存储缓存
    func set<T>(_ value: T, forKey key: String, ttl: TimeInterval = 300) {
        let entry = CacheEntry(value: value, ttl: ttl)
        let cost = calculateCost(value: value)

        cache.setObject(entry, forKey: key as NSString, cost: cost)
    }

    /// 获取缓存
    func get<T>(_ type: T.Type, forKey key: String) -> T? {
        guard let entry = cache.object(forKey: key as NSString) else {
            return nil
        }

        // 检查是否过期
        if entry.isExpired() {
            cache.removeObject(forKey: key as NSString)
            return nil
        }

        // 更新访问信息
        let updatedEntry = entry.access()
        cache.setObject(updatedEntry, forKey: key as NSString)

        return entry.value as? T
    }

    /// 移除缓存
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    /// 清空所有缓存
    func removeAll() {
        cache.removeAllObjects()
    }

    /// 获取缓存统计
    func getCacheStats() -> String {
        return """
        💾 缓存统计
        ━━━━━━━━━━━━━━━━━
        📦 对象数量: \(cache.countLimit)
        💾 总大小: \(cache.totalCostLimit / (1024 * 1024))MB
        ━━━━━━━━━━━━━━━━━
        """
    }

    /// 计算缓存成本
    private func calculateCost<T>(value: T) -> Int {
        // 简化计算，实际应根据类型计算
        return 1
    }
}

/// 预加载管理器
class PreloadManager: ObservableObject {
    private let cacheManager = SmartCacheManager()

    /// 预加载常用数据
    func preloadCommonData() async {
        print("📦 开始预加载数据...")

        // 1. 预加载天气数据
        await preloadWeatherData()

        // 2. 预加载日程数据
        await preloadScheduleData()

        // 3. 预加载习惯数据
        await preloadHabitData()

        print("✅ 预加载完成")
    }

    /// 预加载天气数据
    private func preloadWeatherData() async {
        // TODO: 实际调用天气 API
        print("🌤️ 预加载天气数据...")
    }

    /// 预加载日程数据
    private func preloadScheduleData() async {
        // TODO: 实际调用日程 API
        print("📅 预加载日程数据...")
    }

    /// 预加载习惯数据
    private func preloadHabitData() async {
        // TODO: 实际调用习惯 API
        print("🎯 预加载习惯数据...")
    }
}

/// 网络请求优化
class OptimizedNetworkManager {
    private let session: URLSession
    private let cacheManager = SmartCacheManager()

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .returnCacheDataElseLoad

        self.session = URLSession(configuration: configuration)
    }

    /// 优化后的 GET 请求
    func get<T: Decodable>(
        _ url: URL,
        type: T.Type,
        useCache: Bool = true
    ) async throws -> T {
        // 检查缓存
        if useCache {
            let cacheKey = url.absoluteString
            if let cached: T = cacheManager.get(T.self, forKey: cacheKey) {
                print("💾 命中缓存: \(url)")
                return cached
            }
        }

        // 发起网络请求
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        // 解析数据
        let decoded = try JSONDecoder().decode(T.self, from: data)

        // 缓存结果
        if useCache {
            let cacheKey = url.absoluteString
            cacheManager.set(decoded, forKey: cacheKey, ttl: 300)
        }

        return decoded
    }

    /// 优化后的 POST 请求
    func post<T: Decodable>(
        _ url: URL,
        body: Encodable,
        type: T.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try? JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    enum NetworkError: Error {
        case invalidResponse
        case networkError(Error)
    }
}

/// 列表性能优化
struct OptimizedListView: View {
    let items: [String]
    @State private var visibleItems: Set<Int> = []

    var body: some View {
        List(items.indices, id: \.self) { index in
            OptimizedListItem(
                item: items[index],
                isVisible: visibleItems.contains(index)
            )
            .onAppear {
                visibleItems.insert(index)
            }
            .onDisappear {
                visibleItems.remove(index)
            }
        }
        .listStyle(.plain)
    }
}

/// 优化的列表项
struct OptimizedListItem: View {
    let item: String
    let isVisible: Bool

    @State private var isLoaded = false

    var body: some View {
        HStack {
            Text(item)
                .font(.body)

            if isVisible && isLoaded {
                // 只有可见时才加载额外内容
                Text("详情")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if isVisible {
                // 延迟加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isLoaded = true
                }
            }
        }
    }
}

/// 动画性能优化
struct OptimizedAnimationView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 100, height: 100)
            .scaleEffect(scale)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: scale)
            .onTapGesture {
                withAnimation {
                    scale = isAnimating ? 1.0 : 1.5
                    isAnimating.toggle()
                }
            }
    }
}

/// 图片懒加载
struct LazyImageLoader: View {
    let url: URL?
    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }

        isLoading = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                if let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoading = false
                    }
                }
            } catch {
                print("❌ 图片加载失败: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

/// 使用示例
struct PerformanceOptimizationDemo: View {
    @StateObject private var optimizer = ResponseSpeedOptimizer()
    @StateObject private var preloadManager = PreloadManager()
    @State private var responseTime: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // 性能测试按钮
            Button("测试响应速度") {
                Task {
                    await testPerformance()
                }
            }
            .buttonStyle(.borderedProminent)

            // 显示响应时间
            Text(responseTime)
                .font(.headline)

            // 性能报告
            Text(optimizer.getPerformanceReport())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            // 预加载数据
            Task {
                await preloadManager.preloadCommonData()
            }
        }
    }

    private func testPerformance() async {
        do {
            let result = try await optimizer.measureResponseTime {
                // 模拟耗时操作
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                return "操作完成"
            }

            await MainActor.run {
                responseTime = result
            }
        } catch {
            print("❌ 性能测试失败: \(error)")
        }
    }
}

/// 优化后的数据模型
struct OptimizedDataModel: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let imageURL: URL?

    // 使用 CodingKeys 优化 JSON 解析
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle
        case imageURL = "image_url"
    }
}

/// 数据库查询优化
class OptimizedDatabaseManager {
    private let database: SQLiteDatabase // 假设的数据库

    /// 优化查询 - 使用索引
    func queryWithIndex(_ query: String) async throws -> [OptimizedDataModel] {
        // TODO: 实际实现
        // 1. 使用索引加速查询
        // 2. 限制返回数量
        // 3. 只查询必要的字段
        return []
    }

    /// 批量查询优化
    func batchQuery(_ queries: [String]) async throws -> [[OptimizedDataModel]] {
        // TODO: 实际实现
        // 1. 批量执行查询
        // 2. 使用事务
        // 3. 减少网络往返
        return []
    }
}

/// 数据库（模拟）
class SQLiteDatabase {
    // 实际实现应使用 CoreData 或 SQLite
}
