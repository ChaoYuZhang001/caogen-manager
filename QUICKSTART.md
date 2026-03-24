# 🚀 草根管家 - 快速开始

5 分钟内让用户的手机变成 AI 助手！

---

## 📱 快速开始（iOS App 用户）

### 第一步：下载 App

从 App Store 搜索"草根管家"并下载安装。

### 第二步：配置服务器

1. 打开 App
2. 点击"设置" → "服务器配置"
3. 输入服务器地址（由管理员提供）
4. 点击"测试连接"
5. 确认连接成功

### 第三步：登录

1. 输入用户名和密码
2. 点击"登录"
3. 或使用 Face ID / Touch ID 快速登录

### 第四步：开始使用

#### 文字对话
1. 点击"聊天"标签
2. 在输入框输入消息
3. 点击发送按钮

#### 语音对话
1. 点击"语音助手"标签
2. 点击绿色麦克风按钮
3. 对着手机说话
4. 等待草根回复

---

## 💻 快速开始（开发者）

### 环境要求

- Node.js 16+
- Xcode 15+
- 一个可用的 OpenClaw 实例

### 第一步：克隆项目

```bash
git clone <your-repo-url>
cd <project-name>
```

### 第二步：启动后端

```bash
cd caogen-backend
npm install
npm start
```

服务启动在：http://localhost:3333

### 第三步：编译 iOS App

```bash
cd ../CaogenApp
open CaogenApp.xcodeproj
```

在 Xcode 中：
1. 选择模拟器或真机
2. 点击运行按钮
3. 首次启动配置服务器：`http://localhost:3333`

### 第四步：测试功能

1. **测试文字对话**
   - 在输入框输入："你好"
   - 点击发送
   - 等待回复

2. **测试语音助手**
   - 点击绿色麦克风按钮
   - 说出："帮我写个周报"
   - 等待回复

3. **测试设置**
   - 点击"设置"标签
   - 修改服务器地址
   - 启用/关闭语音播放

---

## 🧪 测试 API

### 使用 curl

```bash
# 健康检查
curl http://localhost:3333/health

# 发送消息
curl -X POST http://localhost:3333/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "你好，草根！"}'

# 批量消息
curl -X POST http://localhost:3333/api/chat/batch \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      "你好",
      "介绍一下自己"
    ]
  }'

# 获取历史
curl "http://localhost:3333/api/session/history?sessionKey=agent:main:main&limit=10"

# 用户登录
curl -X POST http://localhost:3333/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "password"
  }'
```

### 使用 Postman

导入以下配置：

**Base URL**: `http://localhost:3333`

**端点**:
- `GET /health`
- `POST /api/chat`
- `POST /api/chat/batch`
- `GET /api/session/history`
- `POST /api/auth/login`

---

## 🎯 常用命令

### 后端

```bash
# 安装依赖
npm install

# 启动开发服务器（自动重启）
npm run dev

# 启动生产服务器
npm start

# 查看日志
pm2 logs caogen-backend

# 重启服务
pm2 restart caogen-backend

# 停止服务
pm2 stop caogen-backend

# 删除服务
pm2 delete caogen-backend
```

### iOS App

```bash
# 打开 Xcode 项目
open CaogenApp.xcodeproj

# 命令行编译
xcodebuild -scheme CaogenApp -sdk iphonesimulator

# 清理构建
xcodebuild clean
```

---

## 🔧 配置说明

### 后端环境变量

编辑 `caogen-backend/.env`:

```bash
# OpenClaw Gateway 地址
OPENCLAW_GATEWAY_URL=ws://127.0.0.1:5000

# OpenClaw 认证 Token
OPENCLAW_AUTH_TOKEN=your_token_here

# 服务端口
PORT=3333

# JWT 密钥
JWT_SECRET=your_jwt_secret_key

# 运行环境
NODE_ENV=development
```

### iOS 配置

编辑 `CaogenApp/Info.plist`:

```xml
<key>SERVER_URL</key>
<string>http://localhost:3333</string>
```

或在 App 内的设置界面配置。

---

## 🐛 常见问题

### Q: 服务无法启动？

A: 检查以下几点：
1. 端口 3333 是否被占用
2. Node.js 版本是否 >= 16
3. 依赖是否完整安装（`npm install`）

### Q: iOS App 无法连接服务器？

A: 检查以下几点：
1. 服务器地址是否正确
2. 服务器是否正在运行
3. 网络连接是否正常
4. 防火墙是否阻止连接

### Q: 语音识别不工作？

A: 检查以下几点：
1. 是否授予了麦克风权限
2. 是否授予了语音识别权限
3. 网络连接是否正常（语音识别需要网络）

### Q: OpenClaw 连接失败？

A: 检查以下几点：
1. OpenClaw Gateway 是否正在运行
2. Gateway 地址是否正确
3. 认证 Token 是否正确
4. 网络连接是否正常

---

## 📚 下一步

- 查看 [DEPLOYMENT.md](./DEPLOYMENT.md) 了解生产环境部署
- 查看 [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) 了解项目架构
- 查看 iOS 代码了解具体实现

---

## 💡 提示

1. **开发模式**: 使用 `npm run dev` 启动，支持自动重启
2. **生产模式**: 使用 PM2 管理，支持进程守护
3. **调试模式**: 查看 PM2 日志：`pm2 logs`
4. **测试模式**: 使用模拟器快速测试

---

**开始使用草根管家，让你的手机变得智能！** 🌾
