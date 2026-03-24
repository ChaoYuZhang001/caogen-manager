/**
 * 消息推送路由
 */
const express = require('express');
const { PushNotificationService } = require('../push-notification-service');

const router = express.Router();
const pushService = new PushNotificationService();

// 注册设备
router.post('/register', async (req, res) => {
    try {
        const { deviceToken, deviceType, userId } = req.body;

        if (!deviceToken || !deviceType) {
            return res.status(400).json({
                success: false,
                error: '缺少必要参数'
            });
        }

        pushService.registerDevice(deviceToken, deviceType, userId);

        res.json({
            success: true,
            message: '设备注册成功'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 取消注册设备
router.post('/unregister', async (req, res) => {
    try {
        const { deviceToken } = req.body;

        if (!deviceToken) {
            return res.status(400). json({
                success: false,
                error: '缺少设备 Token'
            });
        }

        pushService.unregisterDevice(deviceToken);

        res.json({
            success: true,
            message: '设备取消注册'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Web Push 订阅
router.post('/subscribe', async (req, res) => {
    try {
        const { userId, subscription } = req.body;

        if (!userId || !subscription) {
            return res.status(400).json({
                success: false,
                error: '缺少必要参数'
            });
        }

        pushService.subscribeWebPush(userId, subscription);

        res.json({
            success: true,
            message: '订阅成功'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 发送测试推送
router.post('/test', async (req, res) => {
    try {
        const { userId, title, body } = req.body;

        const result = await pushService.sendSystemNotification(
            userId,
            title || "测试通知",
            body || "这是一条测试推送消息"
        );

        res.json({
            success: true,
            result
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 发送消息推送
router.post('/message', async (req, res) => {
    try {
        const { userId, title, body, data, url } = req.body;

        if (!userId) {
            return res.status(400).json({
                success: false,
                error: '缺少用户 ID'
            });
        }

        await pushService.sendPushNotification(userId, {
            title: title || "新消息",
            body: body || "",
            data: data || {},
            notification: {
                badge: 1
            }
        });

        res.json({
            success: true,
            message: '推送成功'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;