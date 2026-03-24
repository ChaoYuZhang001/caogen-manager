/**
 * 性能优化 - 启动速度优化
 * 目标：启动时间从 3 秒降低到 1.5 秒以内
 */

import SwiftUI

/// 性能监控器
class PerformanceMonitor: ObservableObject {
    @Published var startupTime: TimeInterval = 0
    @Published var renderTime: TimeInterval = 0
    @Published var dataLoadTime: TimeInterval = 0

    private var startupStartTime: Date?
    private var renderStartTime: Date?
    private var dataLoadStartTime: Date?

    /// 开始启动计时
    func startStartupTimer() {
        startupStartTime = Date()
    }

    /// 结束启动计时
    func endStartupTimer() {
        if let start = startupStartTime {
            startupTime = Date().timeIntervalSince(start)
            print("📊 启动时间: \(startupTime * 1000)ms")

            // 上报到分析系统
            reportPerformance(metric: "startup_time", value: startupTime)
        }
    }

    /// 开始渲染计时
    func startRenderTimer() {
        renderStartTime = Date()
    }

    /// 结束渲染计时
    func endRenderTimer() {
        if let start = renderStartTime {
            renderTime = Date().timeIntervalSince(start)
            print("📊 渲染时间: \(renderTime * 1000)ms")

            reportPerformance(metric: "render_time", value: renderTime)
        }
    }

    /// 开始数据加载计时
    func startDataLoadTimer() {
        dataLoadStartTime = Date()
    }

    /// 结束数据加载计时
    func endDataLoadTimer() {
        if let start = dataLoadStartTime {
            dataLoadTime = Date().timeIntervalSince(start)
            print("📊 数据加载时间: \(dataLoadTime * 1000)ms")

            reportPerformance(metric: "data_load_time", value: dataLoadTime)
        }
    }

    /// 上报性能数据
    private func reportPerformance(metric: String, value: TimeInterval) {
        // TODO: 上报到分析系统
        print("📈 性能上报: \(metric) = \(value * 1000)ms")
    }

    /// 获取启动性能报告
    func getStartupReport() -> String {
        let total = startupTime + renderTime + dataLoadTime

        return """
        📊 启动性能报告
        ━━━━━━━━━━━━━━━━━
        ⚡ 启动时间: \(String(format: "%.0f", startupTime * 1000))ms
        🖼️ 渲染时间: \(String(format: "%.0f", renderTime * 1000))ms
        📦 数据加载: \(String(format: "%.0f", dataLoadTime * 1000))ms
        ━━━━━━━━━━━━━━━━━
        🏁 总耗时: \(String(format: "%.0f", total * 1000))ms
        """
    }
}

/// 延迟加载管理器
class LazyLoadManager: ObservableObject {
    @Published var isInitialLoadComplete = false
    private var pendingTasks: [() -> Void] = []

    /// 延迟执行任务
    func executeAfterInitialLoad(_ task: @escaping () -> Void) {
        if isInitialLoadComplete {
            task()
        } else {
            pendingTasks.append(task)
        }
    }

    /// 标记初始加载完成
    func markInitialLoadComplete() {
        isInitialLoadComplete = true

        // 执行待处理任务
        for task in pendingTasks {
            task()
        }
        pendingTasks.removeAll()
    }
}

/// Splash Screen 优化
struct OptimizedSplashScreen: View {
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Logo 动画
            VStack(spacing: 20) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(logoScale)
                    .opacity(opacity)
                    .animation(
                        Animation.spring(response: 0.8, dampingFraction: 0.6)
                            .delay(0.2),
                        value: logoScale
                    )

                Text("草根管家")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 0.5).delay(0.5), value: opacity)

                // 加载指示器
                if isAnimating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .onAppear {
            // 启动动画
            withAnimation {
                isAnimating = true
                logoScale = 1.0
                opacity = 1.0
            }

            // 1.5 秒后自动跳转
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // TODO: 跳转到主界面
            }
        }
    }
}

/// 优化后的 App 启动流程
@main
struct CaogenApp: App {
    @StateObject private var performanceMonitor = PerformanceMonitor()
    @StateObject private var lazyLoadManager = LazyLoadManager()
    @StateObject private var showSplash = true

    init() {
        // 1. 开始启动计时
        performanceMonitor.startStartupTimer()

        // 2. 优化启动流程
        optimizeStartup()

        // 3. 预加载关键数据
        preloadCriticalData()
    }

    var body: some Scene {
        WindowGroup {
            if showSplash {
                OptimizedSplashScreen()
                    .onAppear {
                        performanceMonitor.startRenderTimer()
                    }
                    .onDisappear {
                        performanceMonitor.endRenderTimer()
                        performanceMonitor.endStartupTimer()
                    }
            } else {
                ContentView()
                    .environmentObject(performanceMonitor)
                    .environmentObject(lazyLoadManager)
                    .onAppear {
                        performanceMonitor.startDataLoadTimer()
                    }
            }
        }
    }

    /// 优化启动流程
    private func optimizeStartup() {
        // 1. 延迟加载非必要的 View
        // 2. 预加载常用数据
        // 3. 优化数据库查询
        // 4. 减少启动时的网络请求

        print("⚡ 启动流程优化中...")
    }

    /// 预加载关键数据
    private func preloadCriticalData() {
        // 1. 加载用户配置
        // 2. 加载常用数据
        // 3. 建立数据库连接
        // 4. 初始化关键服务

        print("📦 预加载关键数据...")
    }
}

/// 延迟加载 View 修饰器
struct LazyLoadViewModifier: ViewModifier {
    @ObservedObject var lazyLoadManager: LazyLoadManager
    let loadTask: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                lazyLoadManager.executeAfterInitialLoad {
                    loadTask()
                }
            }
    }
}

extension View {
    /// 延迟加载修饰器
    func lazyLoad(
        _ manager: LazyLoadManager,
        perform task: @escaping () -> Void
    ) -> some View {
        self.modifier(LazyLoadViewModifier(lazyLoadManager: manager, loadTask: task))
    }
}

/// 图片缓存优化
struct OptimizedAsyncImage: View {
    let url: URL?
    let placeholder: Image

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url else { return }

        // 使用 ImageIO 优化图片加载
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url) {
                let imageSource = CGImageSourceCreateWithData(data as CFData, nil)
                let options: [NSString: Any] = [
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceShouldAllowFloat: true
                ]

                if let image = CGImageSourceCreateImageAtIndex(imageSource!, 0, options as CFDictionary) {
                    let uiImage = UIImage(cgImage: image)

                    DispatchQueue.main.async {
                        self.image = uiImage
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

/// 内存优化 - 对象池
class ObjectPool<T: AnyObject> {
    private var pool: [T] = []
    private let factory: () -> T
    private let reset: (T) -> Void

    init(factory: @escaping () -> T, reset: @escaping (T) -> Void) {
        self.factory = factory
        self.reset = reset
    }

    func obtain() -> T {
        if pool.isEmpty {
            return factory()
        } else {
            return pool.removeLast()
        }
    }

    func recycle(_ object: T) {
        reset(object)
        pool.append(object)
    }
}

/// 使用示例
let imageViewPool = ObjectPool<UIImageView>(
    factory: { UIImageView() },
    reset: { imageView in
        imageView.image = nil
        imageView.isHidden = true
    }
)
