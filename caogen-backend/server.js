const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoose = require('mongoose');
require('dotenv').config();

// OpenClaw 适配器
const openclawAdapter = require('./openclaw-adapter');

// 定时任务管理器
const ScheduledTaskManager = require('./scheduled-task-manager');

// 云同步服务
const CloudSyncService = require('./cloud-sync-service');

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
    windowMs: 15 * 60 * 1000,
    max: 100,
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
    next();
});

// 健康检查
app.get('/health', async (req, res) => {
    let dbStatus = 'disconnected';
    try {
        if (mongoose.connection.readyState === 1) {
            dbStatus = 'connected';
        }
    } catch (e) {}

    res.json({
        status: 'ok',
        service: '草根管家后端服务',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        openclaw: openclawAdapter.isConnected() ? 'connected' : 'disconnected',
        database: dbStatus
    });
});

// ============ API 路由 ============

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
        console.log(`====================\n`);

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

// ============ 定时任务 API ============

// 获取定时任务列表
app.get('/api/tasks', async (req, res) => {
    try {
        const tasks = await ScheduledTaskManager.getTasks();
        res.json({
            success: true,
            data: tasks
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 创建定时任务
app.post('/api/tasks', async (req, res) => {
    try {
        const task = req.body;
        const createdTask = await ScheduledTaskManager.createTask(task);
        res.json({
            success: true,
            data: createdTask
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 更新定时任务
app.put('/api/tasks/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;
        const updatedTask = await ScheduledTaskManager.updateTask(id, updates);
        res.json({
            success: true,
            data: updatedTask
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 删除定时任务
app.delete('/api/tasks/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await ScheduledTaskManager.deleteTask(id);
        res.json({
            success: true,
            message: '任务已删除'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// ============ 云同步 API ============

// 获取同步状态
app.get('/api/sync/status', async (req, res) => {
    try {
        const status = await CloudSyncService.getSyncStatus();
        res.json({
            success: true,
            data: status
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 手动触发同步
app.post('/api/sync/trigger', async (req, res) => {
    try {
        const result = await CloudSyncService.triggerSync();
        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取同步数据
app.get('/api/sync/data', async (req, res) => {
    try {
        const { type, since } = req.query;
        const data = await CloudSyncService.getData(type, since);
        res.json({
            success: true,
            data
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 上传同步数据
app.post('/api/sync/data', async (req, res) => {
    try {
        const { type, data } = req.body;
        await CloudSyncService.uploadData(type, data);
        res.json({
            success: true,
            message: '数据已同步'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// ============ 用户数据 API ============

// 获取会话历史
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

// 认证接口
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return res.status(400).json({
                success: false,
                error: '用户名和密码不能为空',
                code: 'INVALID_CREDENTIALS'
            });
        }

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

// 获取配置
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
                history: true,
                scheduledTasks: true,
                cloudSync: true,
                plugins: true
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

// ============ 启动服务器 ============
app.listen(PORT, async () => {
    console.log('\n========================================');
    console.log('  🌾 草根管家后端服务启动成功');
    console.log('========================================');
    console.log(`  监听端口: ${PORT}`);
    console.log(`  访问地址: http://localhost:${PORT}`);
    console.log(`  API 端点: http://localhost:${PORT}/api/chat`);
    console.log(`  健康检查: http://localhost:${PORT}/health`);
    console.log('========================================\n');

    // 初始化 OpenClaw 连接
    try {
        await openclawAdapter.initialize();
        console.log('✅ OpenClaw 连接已建立\n');
    } catch (error) {
        console.error('❌ OpenClaw 连接失败:', error.message);
        console.log('⚠️  服务将以离线模式运行\n');
    }

    // 初始化数据库
    try {
        if (process.env.MONGODB_URL) {
            await mongoose.connect(process.env.MONGODB_URL);
            console.log('✅ MongoDB 连接成功\n');
        }
    } catch (error) {
        console.error('❌ MongoDB 连接失败:', error.message);
    }

    // 初始化定时任务
    try {
        await ScheduledTaskManager.initialize();
        console.log('✅ 定时任务管理器已启动\n');
    } catch (error) {
        console.error('❌ 定时任务初始化失败:', error.message);
    }

    // 初始化云同步
    try {
        await CloudSyncService.initialize();
        console.log('✅ 云同步服务已启动\n');
    } catch (error) {
        console.error('❌ 云同步初始化失败:', error.message);
    }
});

// 优雅关闭
process.on('SIGTERM', async () => {
    console.log('\n收到 SIGTERM 信号，正在关闭服务器...');
    openclawAdapter.disconnect();
    await mongoose.disconnect();
    await ScheduledTaskManager.stop();
    process.exit(0);
});

process.on('SIGINT', async () => {
    console.log('\n收到 SIGINT 信号，正在关闭服务器...');
    openclawAdapter.disconnect();
    await mongoose.disconnect();
    await ScheduledTaskManager.stop();
    process.exit(0);
});

module.exports = app;
