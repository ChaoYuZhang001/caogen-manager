/**
 * 内存优化 - Memory Optimization
 * 目标：减少内存占用 30%，避免内存泄漏
 */

import SwiftUI
import Combine

/// 内存监控器
class MemoryMonitor: ObservableObject {
    @Published var currentMemoryUsage: UInt64 = 0
    @Published var peakMemoryUsage: UInt64 = 0
    @Published var memoryWarningCount: Int = 0

    private var timer: Timer?

    init() {
        startMonitoring()
    }

    /// 开始内存监控
    private func startMonitoring() {
        // 每 5 秒更新一次内存使用情况
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.updateMemoryUsage()
        }

        // 监听内存警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    /// 更新内存使用情况
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMemory = info.resident_size
            currentMemoryUsage = usedMemory

            if usedMemory > peakMemoryUsage {
                peakMemoryUsage = usedMemory
            }

            print("💾 内存使用: \(formatMemory(usedMemory))")
        }
    }

    /// 处理内存警告
    @objc private func handleMemoryWarning() {
        memoryWarningCount += 1

        print("⚠️ 收到内存警告 (第 \(memoryWarningCount) 次)")

        // 触发内存清理
        MemoryOptimizer.shared.clearCache()
        ImageCache.shared.clearCache()
    }

    /// 格式化内存大小
    private func formatMemory(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / 1024 / 1024
        return String(format: "%.2f MB", mb)
    }

    /// 获取内存报告
    func getMemoryReport() -> String {
        return """
        💾 内存报告
        ━━━━━━━━━━━━━━━━━
        📊 当前使用: \(formatMemory(currentMemoryUsage))
        📈 峰值使用: \(formatMemory(peakMemoryUsage))
        ⚠️ 内存警告: \(memoryWarningCount) 次
        ━━━━━━━━━━━━━━━━━
        """
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

/// 内存优化器
class MemoryOptimizer {
    static let shared = MemoryOptimizer()

    private init() {}

    /// 清理缓存
    func clearCache() {
        print("🧹 清理缓存...")

        // 清理图片缓存
        ImageCache.shared.clearCache()

        // 清理数据缓存
        DataCache.shared.clearCache()

        // 清理网络缓存
        URLCache.shared.removeAllCachedResponses()

        print("✅ 缓存清理完成")
    }

    /// 优化图片内存
    func optimizeImage(_ image: UIImage, maxSize: CGSize) -> UIImage? {
        // 调整图片大小
        UIGraphicsBeginImageContextWithOptions(maxSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: maxSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    /// 压缩图片
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
}

/// 图片缓存优化
class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private var cacheURL: URL?

    private init() {
        // 配置内存缓存
        cache.countLimit = 100 // 最多 100 张图片
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        // 配置磁盘缓存
        setupDiskCache()

        print("💾 图片缓存已初始化")
    }

    /// 设置磁盘缓存
    private func setupDiskCache() {
        let cacheDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!

        cacheURL = cacheDirectory.appendingPathComponent("ImageCache")

        // 创建缓存目录
        try? FileManager.default.createDirectory(
            at: cacheURL!,
            withIntermediateDirectories: true
        )
    }

    /// 缓存图片
    func set(_ image: UIImage, forKey key: String) {
        // 存储到内存
        let cost = estimateImageCost(image)
        cache.setObject(image, forKey: key as NSString, cost: cost)

        // 存储到磁盘
        if let data = image.pngData(),
           let url = cacheURL?.appendingPathComponent(key) {
            try? data.write(to: url)
        }
    }

    /// 获取图片
    func get(forKey key: String) -> UIImage? {
        // 先从内存获取
        if let image = cache.object(forKey: key as NSString) {
            return image
        }

        // 再从磁盘获取
        if let url = cacheURL?.appendingPathComponent(key),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            // 重新缓存到内存
            cache.setObject(image, forKey: key as NSString)
            return image
        }

        return nil
    }

    /// 清理缓存
    func clearCache() {
        // 清理内存缓存
        cache.removeAllObjects()

        // 清理磁盘缓存
        if let cacheURL = cacheURL {
            try? FileManager.default.removeItem(at: cacheURL)
            try? FileManager.default.createDirectory(
                at: cacheURL,
                withIntermediateDirectories: true
            )
        }
    }

    /// 估算图片成本
    private func estimateImageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 1 }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let totalBytes = cgImage.width * cgImage.height * bytesPerPixel

        return totalBytes / 1024 // KB
    }
}

/// 数据缓存优化
class DataCache {
    static let shared = DataCache()

    private let cache = NSCache<NSString, CacheEntry>()

    init() {
        cache.countLimit = 50 // 最多 50 个对象
        cache.totalCostLimit = 20 * 1024 * 1024 // 20MB
    }

    class CacheEntry {
        let data: Data
        let expirationTime: Date

        init(data: Data, ttl: TimeInterval = 300) {
            self.data = data
            self.expirationTime = Date().addingTimeInterval(ttl)
        }

        func isExpired() -> Bool {
            return Date() > expirationTime
        }
    }

    /// 存储数据
    func set(_ data: Data, forKey key: String, ttl: TimeInterval = 300) {
        let entry = CacheEntry(data: data, ttl: ttl)
        cache.setObject(entry, forKey: key as NSString, cost: data.count)
    }

    /// 获取数据
    func get(forKey key: String) -> Data? {
        guard let entry = cache.object(forKey: key as NSString) else {
            return nil
        }

        if entry.isExpired() {
            cache.removeObject(forKey: key as NSString)
            return nil
        }

        return entry.data
    }

    /// 清理缓存
    func clearCache() {
        cache.removeAllObjects()
    }
}

/// 对象池（复用对象，减少内存分配）
class ObjectPool<T: AnyObject> {
    private var pool: [T] = []
    private let maxSize: Int
    private let factory: () -> T
    private let reset: (T) -> Void

    init(maxSize: Int = 10, factory: @escaping () -> T, reset: @escaping (T) -> Void) {
        self.maxSize = maxSize
        self.factory = factory
        self.reset = reset
    }

    /// 获取对象
    func obtain() -> T {
        if let object = pool.popLast() {
            return object
        } else {
            return factory()
        }
    }

    /// 回收对象
    func recycle(_ object: T) {
        if pool.count < maxSize {
            reset(object)
            pool.append(object)
        }
    }

    /// 清空对象池
    func clear() {
        pool.removeAll()
    }
}

/// 使用示例：UIImageView 对象池
let imageViewPool = ObjectPool<UIImageView>(
    maxSize: 10,
    factory: { UIImageView() },
    reset: { imageView in
        imageView.image = nil
        imageView.isHidden = true
        imageView.alpha = 1.0
    }
)

/// 弱引用包装器
class WeakBox<T: AnyObject> {
    weak var value: T?

    init(_ value: T) {
        self.value = value
    }
}

/// 防止循环引用
class ViewModel: ObservableObject {
    // 使用 weak 避免循环引用
    weak var delegate: ViewModelDelegate?

    // 使用 Combine 处理异步
    @Published var data: String = ""

    private var cancellables = Set<AnyCancellable>()

    func fetchData() {
        // 使用 Combine 避免内存泄漏
        Future<String, Error> { promise in
            // 模拟异步操作
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                promise(.success("数据加载完成"))
            }
        }
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ 加载失败: \(error)")
                }
            },
            receiveValue: { [weak self] value in
                self?.data = value
            }
        )
        .store(in: &cancellables)
    }
}

protocol ViewModelDelegate: AnyObject {
    func viewModelDidUpdate(_ viewModel: ViewModel)
}

/// 内存泄漏检测工具
class LeakDetector {
    static func detectLeaks(_ object: AnyObject, after delay: TimeInterval = 2.0) {
        let weakObject = WeakBox(object)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if weakObject.value == nil {
                print("✅ 对象已正确释放")
            } else {
                print("⚠️ 可能存在内存泄漏")
            }
        }
    }
}

/// 大数据处理优化
class LargeDataHandler {
    /// 流式处理大数据
    func processLargeData<T>(
        data: [T],
        chunkSize: Int = 100,
        process: ([T]) -> Void
    ) {
        // 分批处理，避免一次性加载所有数据
        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = Array(data[i..<end])

            process(chunk)

            // 释放内存
            autoreleasepool {
                // 在这里处理数据
            }
        }
    }
}

/// 使用示例
class ExampleUsage {
    let memoryMonitor = MemoryMonitor()

    func testMemoryOptimization() {
        // 1. 测试图片缓存
        if let image = UIImage(named: "test") {
            ImageCache.shared.set(image, forKey: "test_image")

            if let cachedImage = ImageCache.shared.get(forKey: "test_image") {
                print("✅ 图片缓存成功")
            }
        }

        // 2. 测试对象池
        let imageView = imageViewPool.obtain()
        imageViewPool.recycle(imageView)

        // 3. 测试大数据处理
        let largeData = Array(0..<10000)
        LargeDataHandler().processLargeData(data: largeData, chunkSize: 100) { chunk in
            print("处理批次: \(chunk.count) 条数据")
        }

        // 4. 显示内存报告
        print(memoryMonitor.getMemoryReport())
    }
}

/// 后台任务优化
class BackgroundTaskManager {
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    /// 开始后台任务
    func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            print("⚠️ 后台任务即将结束")
        }

        print("🔄 后台任务已启动")
    }

    /// 结束后台任务
    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid

        print("✅ 后台任务已结束")
    }

    /// 执行后台任务
    func executeBackgroundTask(_ task: @escaping () -> Void) {
        startBackgroundTask()

        DispatchQueue.global(qos: .background).async {
            task()

            DispatchQueue.main.async {
                self.endBackgroundTask()
            }
        }
    }
}
