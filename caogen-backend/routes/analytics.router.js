/**
 * 数据分析路由
 */
const express = require('express');
const AnalyticsService = require('./analytics-service');

const router = express.Router();
const analyticsService = new AnalyticsService();

// 追踪事件
router.post('/track', async (req, res) => {
    try {
        const event = req.body;

        if (!event.eventType) {
            return res.status(400).json({
                success: false,
                error: '缺少事件类型'
            });
        }

        await AnalyticsService.track(event);

        res.json({
            success: true,
            eventId: event.eventId
        });

    } catch (error) {
        console.error('事件追踪失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取统计数据
router.get('/stats', async (req, res) => {
    try {
        const options = {
            startDate: req.query.startDate,
            endDate: req.query.endDate,
            userId: req.query.userId,
            eventType: req.query.eventType
        };

        const stats = await AnalyticsService.getStats(options);

        res.json({
            success: true,
            data: stats
        });

    } catch (error) {
        console.error('获取统计数据失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取用户画像
router.get('/profile/:userId', async (req, res) => {
    try {
        const profile = await AnalyticsService.getUserProfile(req.params.userId);

        if (!profile) {
            return res.status(404).json({
                success: false,
                error: '用户不存在'
            });
        }

        res.json({
            success: true,
            data: profile
        });

    } catch (error) {
        console.error('获取用户画像失败:', error);
        res.status(500).json({
                success: false,
                error: error.message
            });
    }
});

// 获取功能使用排名
router.get('/ranking', async (req, res) => {
    try {
        const ranking = await AnalyticsService.getFeatureRanking();

        res.json({
            success: true,
            data: ranking
        });

    } catch (error) {
        console.error('获取排名失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取漏斗分析
router.get('/funnel', async (req, res) => {
    try {
        const defaultFunnel = [
            { name: "启动", eventType: Analytics_EventTypes.SESSION_START },
            { name: "聊天", eventType: Analytics_EventTypes.CHAT_SEND },
            { name: "回复", eventType: Analytics_EventTypes.CHAT_RECEIVE }
        ];

        const funnel = await AnalyticsService.getFunnel(defaultFunnel);

        res.json({
            success: true,
            data: funnel
        });

    } catch (error) {
        console.error('漏斗分析失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取留存率
router.get('/retention', async (req, res) => {
    try {
        const cohortDate = req.query.date || new Date().toISOString().split('T')[0];

        const retention = await AnalyticsService.getRetention(cohortDate);

        res.json({
            success: true,
            data: retention
        });

    } catch (error) {
        console.error('获取留存率失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;