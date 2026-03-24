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

// Apple 登录路由
const authRoutes = require('./routes/auth.route');

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

// Apple 登录路由
app.use('/api/auth', authRoutes);

// 草包 AI 路由
const caobaoRoutes = require('./routes/caobao.route');
app.use('/api/caobao', caobaoRoutes);

// 1. 聊天接口