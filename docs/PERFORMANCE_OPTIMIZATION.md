# 性能优化方案

## 1. iOS 性能优化

### 1.1 启动优化

```swift
// 延迟初始化
@LazyInject var authService: AuthService
@LazyInject var chatManager: ChatManager

// 预加载关键数据
func preloadCriticalData() async {
    async let userSettings = loadUserSettings()
    async let recentMessages = loadRecentMessages()
    async let quickActions = loadQuickActions()

    await (userSettings, recentMessages, quickActions)
}

// 减少启动时的网络请求
func minimizeNetworkRequests() {
    // 使用缓存数据
    // 合并多个请求
    // 延迟非关键请求
}
```

### 1.2 内存优化

```swift
// 自动释放池
func processLargeData() {
    autoreleasepool {
        // 处理大数据
        let data = loadLargeDataSet()
        process(data)
    } // 数据立即释放
}

// 图片优化
func optimizedImage(named: String) -> UIImage? {
    guard let image = UIImage(named: named) else { return nil }

    // 压缩图片
    let maxSize = CGSize(width: 1024, height: 1024)
    let scaledImage = image.scale(to: maxSize)

    // 释放原图
    return scaledImage
}

// 懒加载视图
struct LazyLoadedView: View {
    var body: some View {
        LazyVStack {
            ForEach(items) { item in
                ItemView(item: item)
            }
        }
    }
}
```

### 1.3 网络优化

```swift
// 请求合并
class RequestBatcher {
    private var batch: [URLRequest] = []
    private let timer: Timer?

    func addRequest(_ request: URLRequest) {
        batch.append(request)

        // 延迟发送
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sendBatch()
        }
    }

    private func sendBatch() {
        let requests = batch
        batch.removeAll()

        // 合并请求
        let batchRequest = createBatchRequest(requests)
        send(batchRequest)
    }
}

// 响应缓存
class ResponseCache {
    private let cache = NSCache<NSString, CacheEntry>()

    func get(url: String) -> Data? {
        return cache.object(forKey: url as NSString)?.data
    }

    func set(url: String, data: Data, ttl: TimeInterval = 3600) {
        let entry = CacheEntry(data: data, expiry: Date().addingTimeInterval(ttl))
        cache.setObject(entry, forKey: url as NSString)
    }
}

// 压缩传输
func compressData(_ data: Data) -> Data {
    return (data as NSData).compressed(using: .zlib) as Data
}
```

### 1.4 渲染优化

```swift
// 视图层级优化
struct OptimizedView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 减少层级
            HeaderView()
                .frame(height: 44)

            ScrollView {
                LazyVStack {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
            }

            InputView()
                .frame(height: 50)
        }
    }
}

// 避免 SwiftUI 重绘
struct MemoizedView: View {
    let expensiveValue: Int

    var body: some View {
        let optimized = useMemo(of: expensiveValue) { value in
            // 昂贵计算
            return performExpensiveCalculation(value)
        }

        Text("\(optimized)")
    }
}

// 使用 SwiftUI 性能工具
struct PerformanceView: View {
    @State private var frame = CGRect.zero

    var body: some View {
        Text("Hello")
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(key: FramePreferenceKey.self,
                                        value: geometry.frame(in: .global))
                }
            )
            .onPreferenceChange(FramePreferenceKey.self) { frame in
                self.frame = frame
            }
    }
}
```

## 2. 后端性能优化

### 2.1 数据库优化

```javascript
// 添加索引
await queryInterface(`
    CREATE INDEX idx_messages_created_at ON messages(created_at);
    CREATE INDEX idx_messages_user_id ON messages(user_id);
`);

// 查询优化
async function getMessages(userId, limit = 20) {
    // 使用索引
    const messages = await db.query(`
        SELECT * FROM messages
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT $2
    `, [userId, limit]);

    return messages;
}

// 连接池
const pool = new Pool({
    host: 'localhost',
    database: 'caogen',
    max: 20,           // 最大连接数
    min: 5,            // 最小连接数
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000
});
```

### 2.2 缓存策略

```javascript
// Redis 缓存
class CacheService {
    constructor(redis) {
        this.redis = redis;
    }

    async get(key) {
        const cached = await this.redis.get(key);
        return cached ? JSON.parse(cached) : null;
    }

    async set(key, value, ttl = 3600) {
        await this.redis.setex(
            key,
            ttl,
            JSON.stringify(value)
        );
    }

    async invalidate(pattern) {
        const keys = await this.redis.keys(pattern);
        if (keys.length > 0) {
            await this.redis.del(...keys);
        }
    }
}

// 使用缓存
async function getUser(userId) {
    const cache = new CacheService(redis);

    // 尝试从缓存获取
    let user = await cache.get(`user:${userId}`);

    if (!user) {
        // 缓存未命中，从数据库获取
        user = await db.getUser(userId);

        // 写入缓存
        await cache.set(`user:${userId}`, user, 3600);
    }

    return user;
}
```

### 2.3 请求优化

```javascript
// 请求批处理
async function batchRequest(items, batchSize = 10) {
    const results = [];

    for (let i = 0; i < items.length; i += batchSize) {
        const batch = items.slice(i, i + batchSize);
        const batchResults = await Promise.all(
            batch.map(item => processItem(item))
        );
        results.push(...batchResults);
    }

    return results;
}

// 流式响应
async function streamResponse(ctx, data) {
    ctx.set('Content-Type', 'text/event-stream');
    ctx.set('Cache-Control', 'no-cache');

    for (const item of data) {
        ctx.write(`data: ${JSON.stringify(item)}\n\n`);
        await new Promise(resolve => setTimeout(resolve, 100));
    }

    ctx.write('data: [DONE]\n\n');
}
```

## 3. 网络优化

### 3.1 HTTP/2

```nginx
server {
    listen 443 ssl http2;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # 启用 HTTP/2 推送
    http2_push_preload on;
}
```

### 3.2 CDN 加速

```javascript
// 静态资源 CDN
const staticFiles = express.static('public', {
    maxAge: '1y',
    setHeaders: (res, path) => {
        // 添加 CDN 头
        res.setHeader('Cache-Control', 'public, max-age=31536000');
    }
});

app.use(express.static('public'));
```

### 3.3 负载均衡

```nginx
upstream backend {
    least_conn;
    server backend1:3333;
    server backend2:3333;
    server backend3:3333;
}

server {
    location /api {
        proxy_pass http://backend;
    }
}
```

## 4. 监控与分析

### 4.1 性能监控

```javascript
// 性能指标收集
class PerformanceMonitor {
    constructor() {
        this.metrics = {
            requests: [],
            databaseQueries: [],
            cacheHits: 0,
            cacheMisses: 0
        };
    }

    recordRequest(req, res, duration) {
        this.metrics.requests.push({
            method: req.method,
            path: req.path,
            status: res.statusCode,
            duration,
            timestamp: Date.now()
        });
    }

    getAverageResponseTime() {
        const times = this.metrics.requests.map(r => r.duration);
        return times.reduce((a, b) => a + b, 0) / times.length;
    }
}
```

### 4.2 内存监控

```javascript
// 内存使用监控
setInterval(() => {
    const used = process.memoryUsage();
    console.log({
        rss: `${Math.round(used.rss / 1024 / 1024)} MB`,
        heapTotal: `${Math.round(used.heapTotal / 1024 / 1024)} MB`,
        heapUsed: `${Math.round(used.heapUsed / 1024 / 1024)} MB`,
        external: `${Math.round(used.external / 1024 / 1024)} MB`
    });
}, 60000);
```

## 5. 电池优化（iOS）

```swift
// 降低 CPU 使用
func reduceCPUUsage() {
    // 降低刷新率
    preferredFramesPerSecond = 30

    // 禁用不必要的动画
    withAnimation(.none) {
        // 更新 UI
    }
}

// 后台任务优化
func performBackgroundTask() {
    var bgTask: UIBackgroundTaskIdentifier = .invalid

    bgTask = UIApplication.shared.beginBackgroundTask {
        self.cleanupTask(bgTask)
    }

    // 执行任务
    DispatchQueue.global(qos: .background).async {
        // 低优先级执行
        self.doHeavyWork()

        DispatchQueue.main.async {
            self.finishBackgroundTask(bgTask)
        }
    }
}
```

## 6. 优化清单

- [ ] 减少启动时间（目标：< 2 秒）
- [ ] 优化内存使用（目标：< 200MB）
- [ ] 提升响应速度（目标：< 500ms）
- [ ] 减少电池消耗
- [ ] 优化网络请求
- [ ] 实现缓存机制
- [ ] 使用 CDN 加速
- [ ] 配置负载均衡
- [ ] 监控性能指标
- [ ] 定期性能测试

---

## 总结

通过以上优化措施，可以显著提升应用的性能和用户体验。
