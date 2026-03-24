# 草根管家 iOS App + OpenClaw 完整解决方案

让用户的手机变成像《魔幻手机》里的傻妞一样，随时待命的 AI 助手！

---

## 📱 项目结构

```
/workspace/projects/workspace/
├── CaogenApp/                    # iOS App
│   ├── CaogenApp.swift          # 应用入口
│   ├── Info.plist               # 配置文件
│   ├── Views/                   # 视图
│   │   ├── ContentView.swift
│   │   ├── ChatView.swift
│   │   ├── VoiceAssistantView.swift
│   │   ├── SettingsView.swift
│   │   └── LoginView.swift
│   ├── Models/                  # 数据模型
│   │   └── Models.swift
│   └── Managers/                # 管理器
│       ├── AuthManager.swift
│       ├── ChatManager.swift
│       └── SettingsManager.swift
│
├── caogen-backend/              # 后端服务
│   ├── server.js                # Express 服务器
│   ├── openclaw-adapter.js      # OpenClaw 适配器
│   ├── package.json
│   └── .env
│
└── docs/                        # 文档
    ├── README.md
    ├── DEPLOYMENT.md
    └── API.md
```

---

## 🚀 快速开始

### 第一步：启动后端服务

```bash
cd /workspace/projects/workspace/caogen-backend
npm install
npm start
```

服务启动在：http://localhost:3333

### 第二步：编译 iOS App

```bash
cd CaogenApp
open CaogenApp.xcodeproj
```

在 Xcode 中：
1. 选择你的 iPhone 或模拟器
2. 点击运行按钮
3. 首次启动配置服务器地址

### 第三步：使用 App

1. 打开 App
2. 配置服务器地址（开发环境用 localhost）
3. 开始使用语音助手或聊天功能

---

## 🛠️ 后端服务详解

### 核心功能

#### 1. OpenClaw 深度集成

`openclaw-adapter.js` 提供：

```javascript
// 发送消息到 OpenClaw
async function sendMessageToOpenClaw(message, sessionKey) {
  // 1. 通过 WebSocket 连接 OpenClaw Gateway
  // 2. 发送消息
  // 3. 等待响应
  // 4. 返回结果
}

// 获取会话历史
async function getSessionHistory(sessionKey) {
  // 获取会话历史记录
}

// 创建新会话
async function createSession() {
  // 创建新的 OpenClaw 会话
}
```

#### 2. HTTP API 端点

```
POST /api/chat              # 发送消息
POST /api/chat/batch        # 批量发送
GET  /api/session/history   # 获取历史
POST /api/auth/login        # 用户登录
GET  /health                # 健康检查
```

#### 3. 认证与授权

- JWT Token 认证
- 用户管理
- 会话管理

---

## 📱 iOS App 功能

### 核心功能

#### 1. 聊天界面
- 文字对话
- 消息历史
- 实时响应
- 打字动画

#### 2. 语音助手
- 语音识别（中文）
- 语音合成（TTS）
- 可视化动画
- 快捷操作

#### 3. 设置管理
- 服务器配置
- 生物识别登录
- 语音设置
- 数据管理

#### 4. 用户认证
- 用户名密码登录
- Face ID / Touch ID
- Token 自动刷新

---

## 🔧 配置说明

### 后端环境变量

```bash
# OpenClaw Gateway
OPENCLAW_GATEWAY_URL=ws://127.0.0.1:5000
OPENCLAW_AUTH_TOKEN=your_token_here

# 服务器配置
PORT=3333
NODE_ENV=production

# 数据库（可选）
DATABASE_URL=sqlite://./data.db

# JWT 密钥
JWT_SECRET=your_jwt_secret_key
```

### iOS App 配置

在 `Info.plist` 中：

```xml
<key>SERVER_URL</key>
<string>http://your-server.com:3333</string>
```

或在 App 内设置界面配置。

---

## 🚢 部署指南

### 生产环境部署

#### 1. 后端部署

```bash
# 使用 PM2
pm2 start server.js --name caogen-backend
pm2 save

# 或使用 Docker
docker build -t caogen-backend .
docker run -d -p 3333:3333 caogen-backend
```

#### 2. 反向代理（Nginx）

```nginx
server {
    listen 80;
    server_name caogen.yourdomain.com;

    location / {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # WebSocket 支持
    location /ws {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### 3. iOS App 打包发布

1. **配置证书**
   - 在 Apple Developer 申请证书
   - 配置 Bundle Identifier
   - 配置签名

2. **TestFlight 测试**
   ```bash
   xcodebuild -archivePath CaogenApp.xcarchive archive
   xcodebuild -exportArchive -archivePath CaogenApp.xcarchive -exportPath ./export
   ```

3. **App Store 发布**
   - 上传到 App Store Connect
   - 提交审核
   - 等待审核通过

---

## 🎯 用户使用流程

### 第一次使用

1. **下载安装**
   - 从 App Store 下载"草根管家"

2. **配置服务器**
   - 打开 App
   - 输入服务器地址
   - 测试连接

3. **注册/登录**
   - 创建账号
   - 登录系统

4. **开始使用**
   - 文字聊天
   - 语音对话
   - 快捷操作

### 日常使用

#### 对着 Siri 说（需要 Siri Shortcuts）

```
"嘿，草根，帮我写个周报"
"嘿，草根，查询明天的天气"
"嘿，草根，创建一个飞书文档"
```

#### 或直接打开 App

1. 打开"草根管家" App
2. 点击绿色麦克风按钮
3. 说出你的需求
4. 等待草根回复

---

## 🔒 安全最佳实践

### 1. 后端安全

- ✅ 使用 HTTPS（生产环境强制）
- ✅ JWT Token 认证
- ✅ 速率限制
- ✅ 输入验证
- ✅ CORS 配置

### 2. iOS App 安全

- ✅ Keychain 存储敏感信息
- ✅ Face ID / Touch ID
- ✅ SSL Pinning（可选）
- ✅ 代码混淆（Release）

### 3. 传输加密

- ✅ 所有通信使用 TLS 1.2+
- ✅ 证书验证
- ✅ 防止中间人攻击

---

## 📊 监控与日志

### 后端监控

```bash
# 查看 PM2 日志
pm2 logs caogen-backend

# 查看状态
pm2 status

# 监控
pm2 monit
```

### iOS 日志

在 Xcode 中：
```bash
# 查看设备日志
xcrun simctl spawn booted log stream --predicate 'process == "CaogenApp"'

# 查看崩溃日志
xcrun simctl spawn booted log show --predicate 'process == "CaogenApp" AND eventMessage contains "error"'
```

---

## 🐛 故障排查

### 常见问题

#### 1. 无法连接服务器

- 检查服务器地址是否正确
- 检查网络连接
- 检查防火墙设置
- 查看后端日志

#### 2. 语音识别不工作

- 检查麦克风权限
- 检查 Speech Recognition 权限
- 检查网络连接（语音识别需要网络）

#### 3. 生物识别失败

- 检查设备是否支持
- 检查权限配置
- 重新注册 Face ID / Touch ID

---

## 📈 性能优化

### 后端优化

1. **缓存**：使用 Redis 缓存常用响应
2. **负载均衡**：使用 Nginx 负载均衡
3. **数据库优化**：添加索引，优化查询
4. **CDN**：静态资源使用 CDN

### iOS 优化

1. **图片缓存**：使用 SDWebImage
2. **数据压缩**：gzip 压缩
3. **懒加载**：延迟加载内容
4. **内存管理**：及时释放资源

---

## 🎨 自定义开发

### 添加新功能

#### 后端添加新 API

```javascript
// server.js
app.post('/api/custom', async (req, res) => {
    // 处理逻辑
    res.json({ success: true });
});
```

#### iOS 添加新页面

```swift
struct CustomView: View {
    var body: some View {
        Text("自定义功能")
    }
}
```

---

## 📞 技术支持

- GitHub Issues: [项目地址]
- Email: support@caogen.com
- 文档: https://docs.caogen.com

---

## 📄 许可证

Copyright © 2025 草根管家. All rights reserved.

---

**让你的手机变成真正的 AI 助手！** 🌾
