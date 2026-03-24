# OpenClaw Gateway 配置
# 允许外部访问的配置

## 方法 1：启动时指定绑定地址（推荐）
```bash
# 停止当前 Gateway
pkill openclaw-gateway

# 重新启动，绑定到 0.0.0.0
openclaw-gateway --bind 0.0.0.0 --port 5000
```

## 方法 2：使用环境变量
```bash
export OPENCLAW_GATEWAY_BIND=0.0.0.0
export OPENCLAW_GATEWAY_PORT=5000
openclaw-gateway
```

## 方法 3：使用 systemd 服务（如果可用）
```ini
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/openclaw-gateway --bind 0.0.0.0 --port 5000
Restart=always

[Install]
WantedBy=multi-user.target
```

## 方法 4：使用 supervisord
```ini
[program:openclaw-gateway]
command=/usr/local/bin/openclaw-gateway --bind 0.0.0.0 --port 5000
autostart=true
autorestart=true
user=root
stdout_logfile=/tmp/logs/openclaw-gateway.log
stderr_logfile=/tmp/logs/openclaw-gateway.log
priority=30
```

## 验证绑定
```bash
# 检查监听地址
netstat -tlnp | grep 5000

# 应该看到：
# tcp  0.0.0.0:5000  ← 允许所有IP访问
```

## 安全建议

### 防火墙配置
```bash
# 只允许特定 IP 访问
iptables -A INPUT -p tcp --dport 5000 -s YOUR_IP -j ACCEPT
iptables -A INPUT -p tcp --dport 5000 -j DROP

# 使用 ufw（Ubuntu）
ufw allow from YOUR_IP to any port 5000
```

### Token 认证
```bash
# 更新后端配置中的 Token
OPENCLAW_AUTH_TOKEN=your_secure_token_here
```

### Nginx 反向代理（生产环境推荐）
```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    location /gateway {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # 添加认证
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
```

## 客户端配置更新

### 草根管家后端 (.env)
```bash
# 本地连接
OPENCLAW_GATEWAY_URL=ws://127.0.0.1:5000

# 外部连接（修改后）
OPENCLAW_GATEWAY_URL=ws://your-server-ip:5000
# 或使用域名
OPENCLAW_GATEWAY_URL=ws://your-domain.com/gateway
```

### iOS App 配置
```swift
// 根据环境选择
let gatewayURL = ProcessInfo.processInfo.environment["OPENCLAW_GATEWAY_URL"] ?? "ws://127.0.0.1:5000"
```

## 测试连接

### 测试 WebSocket 连接
```bash
# 使用 wscat
npm install -g wscat
wscat -c ws://your-server-ip:5000/gateway

# 使用 curl（测试 HTTP）
curl http://your-server-ip:5000/health
```

### 测试认证
```bash
curl -H "Authorization: Bearer ad74331f-6a4f-4b99-aeac-2005ee5ea944" \
     http://your-server-ip:5000/info
```
