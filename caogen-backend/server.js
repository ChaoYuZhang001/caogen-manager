const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// OpenClaw 适配器
const openclawAdapter = require('./openclaw-adapter');

const app = express();
const PORT = parseInt(process.env.PORT) || 3333;

// 中间件
app.use(helmet());
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 速率限制
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15分钟
    max: 100, // 最多100次请求
    message: {
        success: false,
        error: '请求过于频繁，请稍后再试',
        code: 'RATE_LIMIT_EXCEEDED'
    }
});
app.use('/api/', limiter);

// 日志中间件
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    if (req.body && Object.keys(req.body).length > 0) {
        console.log('Body:', JSON.stringify(req.body, null, 2));
    }
    next();
});

// 健康检查
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        service: '草根管家后端服务',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        openclaw: openclawAdapter.isConnected() ? 'connected' : 'disconnected'
    });
});

// API 路由

// 1. 聊天接口
app.post('/api/chat', async (req, res) => {
    try {
        const { message, sessionKey = 'agent:main:main', timeoutSeconds = 30 } = req.body;

        if (!message || typeof message !== 'string') {
            return res.status(400).json({
                success: false,
                error: '无效的消息内容',
                code: 'INVALID_MESSAGE'
            });
        }

        console.log(`\n=== 收到聊天请求 ===`);
        console.log(`消息: ${message}`);
        console.log(`会话: ${sessionKey}`);
        console.log(`====================\n`);

        // 调用 OpenClaw
        const response = await openclawAdapter.sendMessage(message, sessionKey, timeoutSeconds);

        res.json({
            success: true,
            data: {
                response: response.text || response,
                timestamp: new Date().toISOString(),
                metadata: response.metadata || {}
            }
        });

    } catch (error) {
        console.error('聊天请求失败:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            code: 'CHAT_ERROR'
        });
    }
});

// 2. 批量消息
app.post('/api/chat/batch', async (req, res) => {
    try {
        const { messages, sessionKey = 'agent:main:main' } = req.body;

        if (!Array.isArray(messages) || messages.length === 0) {
            return res.status(400).json({
                success: false,
                error: '无效的消息列表',
                code: 'INVALID_MESSAGES'
            });
        }

        if (messages.length > 10) {
            return res.status(400).json({
                success: false,
                error: '批量消息最多10条',
                code: 'TOO_MANY_MESSAGES'
            });
        }

        const results = [];

        for (const msg of messages) {
            try {
                const response = await openclawAdapter.sendMessage(msg, sessionKey, 30);
                results.push({
                    message: msg,
                    success: true,
                    response: response
                });

                // 简单的速率限制
                await new Promise(resolve => setTimeout(resolve, 500));

            } catch (error) {
                results.push({
                    message: msg,
                    success: false,
                    error: error.message
                });
            }
        }

        res.json({
            success: true,
            results,
            total: messages.length,
            successful: results.filter(r => r.success).length,
            failed: results.filter(r => !r.success).length
        });

    } catch (error) {
        console.error('批量请求失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 3. 获取会话历史
app.get('/api/session/history', async (req, res) => {
    try {
        const { sessionKey = 'agent:main:main', limit = 20 } = req.query;

        const history = await openclawAdapter.getSessionHistory(sessionKey, parseInt(limit));

        res.json({
            success: true,
            data: {
                sessionKey,
                history: history || [],
                count: history ? history.length : 0
            }
        });

    } catch (error) {
        console.error('获取历史失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 4. 认证接口（简化版）
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        // TODO: 实现真实的认证逻辑
        // 这里简化为：只要有用户名和密码就成功
        if (!username || !password) {
            return res.status(400).json({
                success: false,
                error: '用户名和密码不能为空',
                code: 'INVALID_CREDENTIALS'
            });
        }

        // 生成简单的 JWT Token（生产环境应该使用更安全的方式）
        const jwt = require('jsonwebtoken');
        const token = jwt.sign(
            { username, role: 'user' },
            process.env.JWT_SECRET || 'default_secret_key',
            { expiresIn: '7d' }
        );

        res.json({
            success: true,
            data: {
                token,
                user: {
                    id: `user_${username}`,
                    username,
                    email: `${username}@example.com`,
                    fullName: username
                },
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
            }
        });

    } catch (error) {
        console.error('登录失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 5. 获取配置
app.get('/api/config', (req, res) => {
    res.json({
        success: true,
        data: {
            appName: '草根管家',
            version: '1.0.0',
            features: {
                chat: true,
                voice: true,
                batch: true,
                history: true
            },
            openclaw: {
                gatewayUrl: process.env.OPENCLAW_GATEWAY_URL,
                isConnected: openclawAdapter.isConnected()
            }
        }
    });
});

// 错误处理
app.use((err, req, res, next) => {
    console.error('未捕获的异常:', err);
    res.status(500).json({
        success: false,
        error: '服务器内部错误',
        message: err.message
    });
});

// 404 处理
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: '端点不存在',
        code: 'NOT_FOUND',
        path: req.path
    });
});

// 启动服务器
app.listen(PORT, () => {
    console.log('\n========================================');
    console.log('  🌾 草根管家后端服务启动成功');
    console.log('========================================');
    console.log(`  监听端口: ${PORT}`);
    console.log(`  访问地址: http://localhost:${PORT}`);
    console.log(`  API 端点: http://localhost:${PORT}/api/chat`);
    console.log(`  健康检查: http://localhost:${PORT}/health`);
    console.log('========================================\n');

    // 初始化 OpenClaw 连接
    openclawAdapter.initialize().then(() => {
        console.log('✅ OpenClaw 连接已建立\n');
    }).catch((error) => {
        console.error('❌ OpenClaw 连接失败:', error.message);
        console.log('⚠️  服务将以离线模式运行\n');
    });
});

// 优雅关闭
process.on('SIGTERM', () => {
    console.log('\n收到 SIGTERM 信号，正在关闭服务器...');
    openclawAdapter.disconnect();
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('\n收到 SIGINT 信号，正在关闭服务器...');
    openclawAdapter.disconnect();
    process.exit(0);
});

module.exports = app;
