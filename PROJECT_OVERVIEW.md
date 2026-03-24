# 🌾 草根管家 - 项目总览

像《魔幻手机》里的傻妞一样，让用户的手机随时待命！

---

## 📋 项目信息

- **项目名称**: 草根管家
- **版本**: 1.0.0
- **技术栈**: iOS (Swift/SwiftUI) + Node.js + OpenClaw
- **开发语言**: Swift, JavaScript, TypeScript
- **部署平台**: iOS, Linux Server

---

## 🎯 核心功能

### 1. 文字对话
- ✅ 实时聊天
- ✅ 消息历史
- ✅ 上下文理解
- ✅ 打字动画

### 2. 语音助手
- ✅ 中文语音识别
- ✅ 语音合成 (TTS)
- ✅ 可视化动画
- ✅ 快捷操作

### 3. 智能调度
- ✅ 识别用户意图
- ✅ 调用对应的子智能体
- ✅ 多模态支持
- ✅ 工作流编排

### 4. 安全认证
- ✅ JWT Token 认证
- ✅ Face ID / Touch ID
- ✅ 自动刷新 Token
- ✅ 安全存储

---

## 📁 项目结构

```
/workspace/projects/workspace/
│
├── CaogenApp/                    # iOS App
│   ├── CaogenApp.swift          # 应用入口
│   ├── Info.plist               # 配置文件
│   ├── Views/                   # 视图组件
│   │   ├── ContentView.swift    # 主视图
│   │   ├── ChatView.swift       # 聊天界面
│   │   ├── VoiceAssistantView.swift  # 语音助手
│   │   ├── SettingsView.swift   # 设置界面
│   │   └── LoginView.swift      # 登录界面
│   ├── Models/                  # 数据模型
│   │   └── Models.swift         # 模型定义
│   └── Managers/                # 业务逻辑
│       ├── AuthManager.swift    # 认证管理
│       ├── ChatManager.swift    # 聊天管理
│       └── SettingsManager.swift # 设置管理
│
├── caogen-backend/              # 后端服务
│   ├── server.js                # Express 服务器
│   ├── openclaw-adapter.js      # OpenClaw 适配器
│   ├── package.json             # 依赖配置
│   └── .env                     # 环境变量
│
├── caogen-siri/                 # Siri Shortcuts (备用)
│   ├── server.js
│   ├── package.json
│   └── README.md
│
├── README.md                    # 项目说明
├── DEPLOYMENT.md                # 部署指南
└── QUICKSTART.md                # 快速开始
```

---

## 🚀 快速开始

### 开发环境

```bash
# 1. 启动后端服务
cd caogen-backend
npm install
npm start

# 2. 编译 iOS App
cd ../CaogenApp
open CaogenApp.xcodeproj

# 3. 在 Xcode 中运行
```

### 生产环境

详见 [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## 📱 iOS App 特性

### 技术栈
- Swift 5.0+
- SwiftUI
- Speech Framework (语音识别)
- AVFoundation (语音合成)
- LocalAuthentication (生物识别)

### 权限配置
- 麦克风权限
- 语音识别权限
- Face ID / Touch ID 权限
- Siri 权限 (可选)

### 最低系统要求
- iOS 17.0+
- iPhone 12 及以上

---

## 🔧 后端服务特性

### 技术栈
- Node.js 16+
- Express.js
- WebSocket (ws)
- JWT (jsonwebtoken)
- 安全防护

### API 端点
- `POST /api/chat` - 发送消息
- `POST /api/chat/batch` - 批量发送
- `GET /api/session/history` - 获取历史
- `POST /api/auth/login` - 用户登录
- `GET /api/config` - 获取配置
- `GET /health` - 健康检查

### OpenClaw 集成
- WebSocket 实时通信
- 自动重连机制
- 心跳保活
- HTTP 回退方案

---

## 🎨 用户体验

### 首次使用流程
1. 下载安装 App
2. 配置服务器地址
3. 注册/登录
4. 开始使用

### 日常使用
- 打开 App → 点击麦克风 → 说话
- 或对着 Siri 说："嘿，草根，..."

### 快捷操作
- 写周报
- 查日程
- 早安报
- (可自定义)

---

## 🔒 安全措施

### 后端安全
- ✅ Helmet 中间件
- ✅ CORS 配置
- ✅ 速率限制
- ✅ JWT 认证
- ✅ HTTPS (生产环境)

### iOS 安全
- ✅ Keychain 存储
- ✅ 生物识别
- ✅ SSL Pinning (可选)
- ✅ 代码混淆

---

## 📊 性能指标

### 后端性能
- 响应时间: < 1s (正常网络)
- 并发支持: 100+ req/min
- 内存占用: < 200MB
- CPU 占用: < 10% (空闲)

### iOS 性能
- 启动时间: < 2s
- 内存占用: < 150MB
- 语音识别: 实时
- 语音合成: < 500ms

---

## 🛠️ 开发指南

### 添加新功能

#### 后端添加 API
```javascript
// server.js
app.post('/api/custom', async (req, res) => {
    // 实现逻辑
});
```

#### iOS 添加页面
```swift
struct CustomView: View {
    var body: some View {
        Text("新功能")
    }
}
```

### 调试技巧

#### 后端调试
```bash
# 查看日志
pm2 logs caogen-backend

# 实时监控
pm2 monit
```

#### iOS 调试
```bash
# 查看日志
xcrun simctl spawn booted log stream
```

---

## 📈 未来规划

### 短期目标
- [ ] Siri Shortcuts 集成
- [ ] 多语言支持
- [ ] 离线模式
- [ ] 消息云同步

### 中期目标
- [ ] 多模态输入（图片、文件）
- [ ] 插件系统
- [ ] 用户画像
- [ ] 个性化推荐

### 长期目标
- [ ] 生态系统开放
- [ ] 企业版功能
- [ ] AI 模型本地化
- [ ] 跨平台支持

---

## 📞 联系方式

- **项目地址**: [GitHub]
- **文档地址**: https://docs.caogen.com
- **技术支持**: support@caogen.com
- **商务合作**: business@caogen.com

---

## 📄 许可证

Copyright © 2025 草根管家. All rights reserved.

---

**让你的手机真正成为 AI 助手！** 🌾
