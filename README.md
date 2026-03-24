# 🌾 草根管家 (Caogen Manager)

<div align="center">

像《魔幻手机》里的傻妞一样，让用户的手机随时待命的 AI 助手！

[![iOS Version](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://www.apple.com/ios/)
[![Node.js Version](https://img.shields.io/badge/node-16%2B-green.svg)](https://nodejs.org/)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)
[![CI/CD](https://github.com/ChaoYuZhang001/caogen-manager/actions/workflows/ci-cd.yml/badge.svg)](.github/workflows/ci-cd.yml)

[Features](#-功能特性) •
[Quick Start](#-快速开始) •
[Deployment](#-部署指南) •
[Contributing](#-贡献指南)

</div>

---

## 📋 项目简介

草根管家是一个完整的 AI 智能助手解决方案，包含 iOS App、后端服务和 OpenClaw 深度集成。用户可以通过文字或语音与助手交互，实现类似《魔幻手机》中"傻妞"的体验。

### ✨ 核心特性

- 📱 **完整的 iOS App**：Swift + SwiftUI，支持 iOS 17.0+
- 🎙️ **语音交互**：中文语音识别 + TTS 语音合成
- 🤖 **AI 能力**：深度集成 OpenClaw，支持多模态交互
- 🔐 **安全认证**：JWT + Face ID/Touch ID
- 🚀 **生产就绪**：完整的 CI/CD 流程和部署方案

---

## 🏗️ 项目架构

```
caogen-manager/
├── 📱 CaogenApp/                  # iOS App (Swift/SwiftUI)
│   ├── Views/                     # 视图组件
│   │   ├── ContentView.swift      # 主界面
│   │   ├── ChatView.swift         # 聊天界面
│   │   ├── VoiceAssistantView.swift  # 语音助手
│   │   ├── SettingsView.swift     # 设置界面
│   │   └── LoginView.swift        # 登录界面
│   ├── Models/                    # 数据模型
│   └── Managers/                  # 业务逻辑
│
├── ⚙️  caogen-backend/             # 后端服务 (Node.js + Express)
│   ├── server.js                  # Express 服务器
│   ├── openclaw-adapter.js        # OpenClaw 适配器
│   └── package.json
│
├── 📚 docs/                       # 文档
│   ├── DEPLOYMENT.md              # 部署指南
│   ├── QUICKSTART.md              # 快速开始
│   └── PROJECT_OVERVIEW.md        # 项目架构
│
└── 🔧 .github/                    # GitHub 配置
    └── workflows/
        └── ci-cd.yml              # CI/CD 流程
```

---

## 🚀 快速开始

### 前置要求

- **开发环境**：
  - Node.js 16+
  - Xcode 15+
  - 一个可用的 OpenClaw 实例

- **生产环境**：
  - Linux 服务器（Ubuntu 20.04+ 推荐）
  - Node.js 16+
  - Nginx（可选）
  - 域名和 SSL 证书（可选）

### 第一步：启动后端服务

```bash
# 克隆项目
git clone https://github.com/ChaoYuZhang001/caogen-manager.git
cd caogen-manager/caogen-backend

# 安装依赖
npm install

# 配置环境变量
cp .env.example .env
nano .env

# 启动服务
npm start
```

服务启动在：http://localhost:3333

### 第二步：编译 iOS App

```bash
# 在 Xcode 中打开项目
open CaogenApp/CaogenApp.xcodeproj
```

在 Xcode 中：
1. 选择你的 iPhone 或模拟器
2. 点击运行按钮
3. 首次启动配置服务器地址：`http://localhost:3333`

### 第三步：开始使用

1. 打开 App
2. 配置服务器地址
3. 开始使用语音助手或聊天功能

---

## 💡 功能特性

### iOS App 功能

#### 📝 文字对话
- ✅ 实时聊天
- ✅ 消息历史
- ✅ 上下文理解
- ✅ 打字动画

#### 🎙️ 语音助手
- ✅ 中文语音识别
- ✅ 语音合成 (TTS)
- ✅ 可视化动画
- ✅ 快捷操作

#### 🔐 用户认证
- ✅ JWT Token 认证
- ✅ Face ID / Touch ID
- ✅ 自动刷新 Token
- ✅ 安全存储

#### ⚙️ 设置管理
- ✅ 服务器配置
- ✅ 语音设置
- ✅ 数据管理
- ✅ 生物识别开关

### 后端服务功能

#### 🤖 OpenClaw 集成
- ✅ WebSocket 实时通信
- ✅ 自动重连机制
- ✅ 心跳保活
- ✅ HTTP 回退方案

#### 🔌 HTTP API
```
POST /api/chat              # 发送消息
POST /api/chat/batch        # 批量发送
GET  /api/session/history   # 获取历史
POST /api/auth/login        # 用户登录
GET  /health                # 健康检查
```

#### 🛡️ 安全特性
- ✅ JWT 认证
- ✅ 速率限制
- ✅ CORS 配置
- ✅ HTTPS 支持

---

## 📱 使用示例

### 文字对话

```swift
// 发送消息
await chatManager.sendMessage("你好，草根！")

// 接收回复
@Published var messages: [ChatMessage]
```

### 语音交互

```swift
// 开始录音
speechRecognizer.startRecording()

// 停止录音并发送
speechRecognizer.stopRecording()
await chatManager.sendMessage(recognizedText)

// 朗读回复
await speechSynthesizer.speak(response)
```

---

## 🚢 部署指南

详细的部署说明请查看 [DEPLOYMENT.md](./DEPLOYMENT.md)

### 快速部署

```bash
# 1. 服务器准备
sudo apt-get update
sudo apt-get install -y nodejs npm nginx

# 2. 上传代码
git clone https://github.com/ChaoYuZhang001/caogen-manager.git
cd caogen-manager/caogen-backend

# 3. 安装依赖
npm install --production

# 4. 配置环境
cp .env.example .env
nano .env

# 5. 启动服务
pm2 start server.js --name caogen-backend
pm2 save
```

### Nginx 配置

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

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

# JWT 密钥
JWT_SECRET=your_jwt_secret_key

# CORS
CORS_ORIGIN=*
```

### iOS App 配置

在 `Info.plist` 中配置服务器地址：

```xml
<key>SERVER_URL</key>
<string>http://your-server.com:3333</string>
```

或在 App 内设置界面配置。

---

## 📊 技术栈

| 组件 | 技术栈 |
|------|--------|
| **iOS App** | Swift 5.0+, SwiftUI, Speech Framework, AVFoundation |
| **后端服务** | Node.js, Express, WebSocket, JWT |
| **集成框架** | OpenClaw AI Platform |
| **部署工具** | PM2, Nginx, Docker (可选) |
| **CI/CD** | GitHub Actions |

---

## 🐛 故障排查

### 常见问题

<details>
<summary><b>服务无法启动？</b></summary>

```bash
# 检查端口占用
sudo netstat -tlnp | grep 3333

# 查看日志
pm2 logs caogen-backend
```
</details>

<details>
<summary><b>iOS App 无法连接？</b></summary>

- 检查服务器地址是否正确
- 检查网络连接
- 查看设备日志（Xcode）
- 检查防火墙规则
</details>

<details>
<summary><b>语音识别不工作？</b></summary>

- 检查麦克风权限
- 检查语音识别权限
- 确保网络连接正常
</details>

---

## 📈 路线图

- [ ] Siri Shortcuts 深度集成
- [ ] 多语言支持（英文、日文）
- [ ] 离线模式
- [ ] 消息云同步
- [ ] 插件系统
- [ ] 用户画像
- [ ] 个性化推荐

---

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

---

## 📞 联系方式

- **GitHub Issues**: [提交问题](https://github.com/ChaoYuZhang001/caogen-manager/issues)
- **Email**: support@caogen.com
- **文档**: [在线文档](https://docs.caogen.com)

---

<div align="center">

**让你的手机变成真正的 AI 助手！** 🌾

Made with ❤️ by [ChaoYuZhang001](https://github.com/ChaoYuZhang001)

</div>
