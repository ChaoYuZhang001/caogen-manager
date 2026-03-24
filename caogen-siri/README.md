# 草根管家 Siri 集成

让 Siri 成为你的「草根管家」，就像《魔幻手机》里的傻妞一样，随时待命！🌾

---

## 🚀 快速开始

### 1. 安装依赖

```bash
cd caogen-siri
npm install
```

### 2. 启动服务

```bash
# 开发模式
npm run dev

# 生产模式
npm start
```

服务启动后，访问：http://localhost:3001/health

### 3. 配置 Siri Shortcuts

见下方「Siri 配置指南」

---

## 📱 Siri 配置指南

### 方案一：快捷指令（推荐，5分钟搞定）

#### 步骤 1：创建快捷指令

1. 打开 iOS「快捷指令」App
2. 点击右上角「+」创建新快捷指令
3. 命名为「草根管家」或「嘿草根」

#### 步骤 2：添加操作

按顺序添加以下操作：

1. **听写** → 获取语音输入
   - 设置变量名为「userMessage」

2. **获取 URL 的内容**
   - URL: `http://YOUR_SERVER_IP:3001/api/chat`
   - 方法: POST
   - 请求头:
     - Content-Type: application/json
   - 请求体:
     ```json
     {
       "message": "{{userMessage}}"
     }
     ```

3. **词典** → 解析响应
   - 从上一步获取的数据
   - 获取键值: data.response

4. **朗读文本**
   - 朗读内容: 上一步的响应文本

#### 步骤 3：配置语音触发

1. 点击快捷指令右上角「...」
2. 找到「添加到 Siri」
3. 录制自定义短语：「嘿，草根」
4. 完成！

### 方案二：快捷指令文件导入

在服务器根目录下运行：

```bash
node generate-shortcut.js
```

将生成的 `.shortcut` 文件发送到 iPhone，双击导入即可。

---

## 🎯 使用示例

对着 Siri 说：

```
"嘿，草根，帮我写个周报"
"嘿，草根，查询明天的天气"
"嘿，草根，创建一个飞书文档"
"嘿，草根，分析这个数据表格"
"嘿，草根，生成一张赛博朋克风格的图片"
"嘿，草根，给团队发个消息"
"嘿，草根，检查今天的日程"
```

---

## 🔧 API 文档

### POST /api/chat

发送消息到草根管家

**请求**:
```json
{
  "message": "帮我写个周报",
  "sessionKey": "agent:main:main",
  "timeoutSeconds": 30
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "response": "好的，这是你的周报...",
    "timestamp": "2025-03-24T10:00:00Z"
  }
}
```

### GET /health

健康检查

**响应**:
```json
{
  "status": "ok",
  "service": "草根管家 Siri 集成服务",
  "timestamp": "2025-03-24T10:00:00Z"
}
```

---

## 🔐 生产部署

### 使用 PM2 守护进程

```bash
npm install -g pm2
pm2 start server.js --name caogen-siri
pm2 save
pm2 startup
```

### 使用 systemd 服务

创建 `/etc/systemd/system/caogen-siri.service`:

```ini
[Unit]
Description=草根管家 Siri 集成服务
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/caogen-siri
ExecStart=/usr/bin/node /path/to/caogen-siri/server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable caogen-siri
sudo systemctl start caogen-siri
```

### 反向代理配置（Nginx）

```nginx
server {
    listen 80;
    server_name caogen.yourdomain.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## 🛠️ 配置说明

### 环境变量

编辑 `.env` 文件：

```bash
# OpenClaw Gateway 地址
OPENCLAW_GATEWAY=http://127.0.0.1:5000

# OpenClaw 认证 Token
OPENCLAW_AUTH_TOKEN=your_auth_token_here

# 服务端口
PORT=3001

# 运行环境
NODE_ENV=production
```

### 端口配置

默认端口：3001

如果端口被占用，修改 `.env` 文件中的 `PORT` 值。

---

## 🐛 故障排查

### 问题 1: 服务启动失败

```bash
# 检查端口占用
lsof -i :3001

# 查看错误日志
npm start
```

### 问题 2: OpenClaw 连接失败

```bash
# 检查 OpenClaw Gateway 状态
curl http://127.0.0.1:5000/health

# 检查 Gateway 日志
openclaw logs --follow
```

### 问题 3: Siri 响应慢

- 增加 `timeoutSeconds` 参数
- 检查网络连接
- 优化 OpenClaw 响应速度

---

## 📊 监控与日志

### 查看实时日志

```bash
# PM2
pm2 logs caogen-siri

# 直接运行
npm start
```

### 性能监控

```bash
# PM2 监控
pm2 monit

# 查看资源使用
pm2 show caogen-siri
```

---

## 🔒 安全建议

1. **修改默认 Token**: 生产环境必须修改 `OPENCLAW_AUTH_TOKEN`
2. **启用 HTTPS**: 使用 Nginx + Let's Encrypt
3. **限制访问**: 配置防火墙，只允许信任的 IP
4. **启用认证**: 为 API 端点添加额外的认证层

---

## 🎨 进阶功能

### 1. 多语言支持

修改 `server.js`，添加语言检测和翻译。

### 2. 上下文记忆

使用 Redis 存储对话历史。

### 3. 语音合成

集成其他 TTS 服务，提供更好的语音体验。

### 4. 多媒体支持

支持图片、文件上传等。

---

## 📞 技术支持

- GitHub Issues: [项目地址]
- Email: support@caogen.com

---

**祝您使用愉快！就像拥有傻妞一样！🌾**

© 2025 草根管家
