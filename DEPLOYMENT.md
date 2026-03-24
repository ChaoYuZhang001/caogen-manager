# 🌾 草根管家 - 完整部署指南

让用户的手机变成像《魔幻手机》里傻妞一样的 AI 助手！

---

## 📦 快速开始（5分钟）

### 前置要求

- Node.js 16+
- Xcode 15+（仅开发 iOS App 需要）
- 一个可以访问的服务器（公网或内网）
- OpenClaw 已安装并运行

### 第一步：启动后端服务

```bash
# 进入后端目录
cd /workspace/projects/workspace/caogen-backend

# 安装依赖
npm install

# 启动服务
npm start
```

服务将在 http://localhost:3333 启动

### 第二步：测试 API

```bash
# 测试健康检查
curl http://localhost:3333/health

# 测试聊天接口
curl -X POST http://localhost:3333/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "你好，草根！"}'
```

### 第三步：编译 iOS App

```bash
# 进入 iOS 项目目录
cd /workspace/projects/workspace/CaogenApp

# 用 Xcode 打开项目
open CaogenApp.xcodeproj
```

在 Xcode 中：
1. 选择你的 iPhone 或模拟器
2. 点击运行按钮
3. 首次启动时配置服务器地址：`http://localhost:3333`

### 第四步：开始使用

1. 打开"草根管家" App
2. 点击绿色麦克风按钮
3. 说出你的需求
4. 草根回复你！

---

## 🚀 生产环境部署

### 服务器要求

**最小配置**:
- CPU: 2 核心
- 内存: 4GB RAM
- 磁盘: 50GB SSD
- 带宽: 10Mbps

**推荐配置**:
- CPU: 4 核心
- 内存: 8GB RAM
- 磁盘: 100GB SSD
- 带宽: 100Mbps

### 部署步骤

#### 1. 准备服务器

```bash
# 更新系统
sudo apt-get update
sudo apt-get upgrade -y

# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装 PM2
npm install -g pm2

# 安装 Nginx
sudo apt-get install -y nginx

# 安装 Git
sudo apt-get install -y git
```

#### 2. 上传代码

```bash
# 克隆项目（或直接上传文件夹）
git clone <your-repo-url> /opt/caogen
cd /opt/caogen/caogen-backend

# 安装依赖
npm install --production
```

#### 3. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置
nano .env
```

修改以下配置：
```bash
# 修改为你的域名或 IP
OPENCLAW_GATEWAY_URL=ws://your-server.com:5000

# 修改 JWT 密钥（非常重要！）
JWT_SECRET=your_very_secure_random_secret_key

# 修改端口（如果需要）
PORT=3333
```

#### 4. 启动服务

```bash
# 使用 PM2 启动
pm2 start server.js --name caogen-backend

# 保存 PM2 配置
pm2 save

# 设置开机自启
pm2 startup
```

#### 5. 配置 Nginx 反向代理

创建配置文件：
```bash
sudo nano /etc/nginx/sites-available/caogen
```

添加以下内容：
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # 日志
    access_log /var/log/nginx/caogen-access.log;
    error_log /var/log/nginx/caogen-error.log;

    # 上传文件大小限制
    client_max_body_size 10M;

    # API 路由
    location / {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # 超时配置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket 支持
    location /ws {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 健康检查
    location /health {
        proxy_pass http://localhost:3333/health;
        access_log off;
    }
}
```

启用配置：
```bash
# 创建符号链接
sudo ln -s /etc/nginx/sites-available/caogen /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

#### 6. 配置 HTTPS（可选但推荐）

使用 Let's Encrypt 免费证书：

```bash
# 安装 Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo certbot renew --dry-run
```

#### 7. 配置防火墙

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable

# FirewallD (CentOS)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```

---

## 📱 iOS App 打包发布

### 开发者账号

1. 注册 Apple Developer Program（$99/年）
2. 创建 App ID: `com.caogen.app`
3. 创建 Provisioning Profile

### 打包步骤

#### 1. 配置 Xcode 项目

在 Xcode 中：
1. 打开 `CaogenApp.xcodeproj`
2. 选择项目 → 选择 Target
3. 配置 Signing & Capabilities:
   - Bundle Identifier: `com.caogen.app`
   - Team: 选择你的开发者账号
   - Signing Certificate: Automatic

#### 2. 修改服务器地址

编辑 `CaogenApp/Info.plist`:
```xml
<key>SERVER_URL</key>
<string>https://your-domain.com</string>
```

#### 3. 打包 Archive

```bash
# 在 Xcode 中:
# Product → Archive

# 或命令行:
xcodebuild -scheme CaogenApp -archivePath ./build/CaogenApp.xcarchive archive
```

#### 4. 导出 IPA

```bash
# 在 Xcode Organizer 中:
# 点击 Distribute App → 选择 TestFlight 或 App Store

# 或命令行:
xcodebuild -exportArchive \
  -archivePath ./build/CaogenApp.xcarchive \
  -exportPath ./build/export \
  -exportOptionsPlist exportOptions.plist
```

#### 5. 上传到 TestFlight

```bash
# 使用 Transporter 或 Xcode Organizer 上传
```

#### 6. 提交审核

在 App Store Connect 中：
1. 创建新 App
2. 上传构建
3. 填写 App 信息（名称、描述、截图等）
4. 提交审核

---

## 🔧 高级配置

### 数据持久化

#### SQLite

```bash
# 安装依赖
npm install sqlite3

# 修改代码
const Database = require('sqlite3').verbose();
const db = new Database('./data/caogen.db');
```

#### PostgreSQL

```bash
# 安装 PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib

# 创建数据库
sudo -u postgres psql
CREATE DATABASE caogen;
CREATE USER caogen WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE caogen TO caogen;
```

### 监控配置

#### PM2 监控

```bash
# 查看日志
pm2 logs caogen-backend

# 查看状态
pm2 status

# 实时监控
pm2 monit

# 查看详细信息
pm2 show caogen-backend
```

#### 日志轮转

```bash
# 安装 logrotate
sudo apt-get install -y logrotate

# 创建配置文件
sudo nano /etc/logrotate.d/caogen
```

内容：
```
/opt/caogen/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    copytruncate
}
```

### 自动备份

```bash
# 创建备份脚本
nano /opt/caogen/scripts/backup.sh
```

内容：
```bash
#!/bin/bash
BACKUP_DIR="/opt/caogen/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据库
# pg_dump -U caogen caogen > $BACKUP_DIR/caogen_$DATE.sql

# 备份配置文件
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /opt/caogen/.env

# 删除7天前的备份
find $BACKUP_DIR -type f -mtime +7 -delete
```

添加定时任务：
```bash
crontab -e

# 每天凌晨 2 点备份
0 2 * * * /opt/caogen/scripts/backup.sh
```

---

## 🔒 安全加固

### 1. 修改默认配置

```bash
# 修改 JWT 密钥
JWT_SECRET=$(openssl rand -base64 64)

# 修改 OpenClaw Token
OPENCLAW_AUTH_TOKEN=$(openssl rand -base64 32)
```

### 2. 配置防火墙

只开放必要的端口：
- 80 (HTTP)
- 443 (HTTPS)
- 22 (SSH)

### 3. 启用 Fail2Ban

```bash
# 安装
sudo apt-get install -y fail2ban

# 配置
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

### 4. 定期更新

```bash
# 系统更新
sudo apt-get update && sudo apt-get upgrade -y

# 依赖更新
cd /opt/caogen/caogen-backend
npm update
```

---

## 🐛 故障排查

### 常见问题

#### 1. 服务无法启动

```bash
# 查看日志
pm2 logs caogen-backend

# 检查端口
sudo netstat -tlnp | grep 3333

# 检查权限
ls -la /opt/caogen
```

#### 2. OpenClaw 连接失败

```bash
# 检查 OpenClaw Gateway
curl http://localhost:5000/health

# 检查 WebSocket 连接
wscat -c ws://localhost:5000/gateway
```

#### 3. iOS App 无法连接

- 检查服务器地址是否正确
- 检查网络连接
- 查看设备日志（Xcode）
- 检查防火墙规则

---

## 📞 技术支持

- GitHub Issues: [项目地址]
- Email: support@caogen.com
- 文档: https://docs.caogen.com

---

**部署完成！用户现在可以下载 App 开始使用了！** 🌾
