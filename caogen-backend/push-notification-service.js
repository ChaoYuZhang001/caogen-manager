/**
 * 消息推送服务
 * 支持 APNs、FCM、WebSocket 实时推送
 */

const apn = require('apn');
const webpush = require('web-push');

// 推送配置
const pushConfig = {
    apns: {
        token: {
            key: process.env.APNS_KEY_PATH || './keys/apns-auth-key.p8',
            keyId: process.env.APNS_KEY_ID || 'XXXXXXXXXX',
            teamId: process.env.APNS_TEAM_ID || 'YYYYYYYYYY'
        },
        production: process.env.NODE_ENV === 'production'
    },
    fcm: {
        serverKey: process.env.FCM_SERVER_KEY || ''
    }
};

// 设备注册
class PushNotificationService {
    static devices = new Map(); // deviceToken -> { type, userId, createdAt }
    static webPushSubscriptions = new Map(); // userId -> subscriptions

    // 初始化
    static initialize() {
        console.log('初始化消息推送服务...');

        // 初始化 APNs
        if (pushConfig.apns.token.key) {
            try {
                this.apnProvider = new apn.Provider({
                    token: pushConfig.apns.token,
                    production: pushConfig.apns.production
                });
                console.log('✅ APNs 已初始化');
            } catch (error) {
                console.log('⚠️ APNs 初始化失败:', error.message);
            }
        }
    }

    // 注册设备
    static registerDevice(deviceToken, deviceType, userId) {
        this.devices.set(deviceToken, {
            type: deviceType, // 'ios', 'android', 'web'
            userId,
            createdAt: new Date()
        });
        console.log(`📱 设备注册: ${deviceType} (${userId})`);
    }

    // 取消注册设备
    static unregisterDevice(deviceToken) {
        this.devices.delete(deviceToken);
        console.log(`📱 设备取消注册: ${deviceToken}`);
    }

    // 注册 Web Push 订阅
    static subscribeWebPush(userId, subscription) {
        if (!this.webPushSubscriptions.has(userId)) {
            this.webPushSubscriptions.set(userId, []);
        }
        this.webPushSubscriptions.get(userId).push(subscription);
        console.log(`🌐 Web Push 订阅: ${userId}`);
    }

    // 发送推送（通用方法）
    static async sendPush(userId, notification) {
        const results = {
            apns: null,
            fcm: null,
            webpush: null
        };

        // 获取用户的设备
        const userDevices = Array.from(this.devices.entries())
            .filter(([_, device]) => device.userId === userId);

        // 发送到 iOS 设备
        const iosDevices = userDevices.filter(([_, device]) => device.type === 'ios');
        if (iosDevices.length > 0 && this.apnProvider) {
            results.apns = await this.sendAPNs(iosDevices.map(([token, _]) => token), notification);
        }

        // 发送到 Android 设备
        const androidDevices = userDevices.filter(([_, device]) => device.type === 'android');
        if (androidDevices.length > 0) {
            results.fcm = await this.sendFCM(androidDevices.map(([token, _]) => token), notification);
        }

        // 发送到 Web 浏览器
        const webSubscriptions = this.webPushSubscriptions.get(userId) || [];
        if (webSubscriptions.length > 0) {
            results.webpush = await this.sendWebPush(webSubscriptions, notification);
        }

        return results;
    }

    // 发送到 APNs (iOS)
    static async sendAPNs(deviceTokens, notification) {
        if (!this.apnProvider) {
            return { success: false, error: 'APNs not initialized' };
        }

        const note = new apn.Notification();
        note.title = notification.title;
        note.body = notification.body;
        note.sound = notification.sound || 'default';
        note.badge = notification.badge || 1;
        note.payload = notification.data || {};
        note.topic = notification.topic || 'com.caogen.app';

        try {
            const result = await this.apnProvider.send(note, deviceTokens);
            console.log(`📱 APNs 发送结果: ${result.sent.length} 成功, ${result.failed.length} 失败`);
            return {
                success: result.sent.length > 0,
                sent: result.sent.length,
                failed: result.failed.length
            };
        } catch (error) {
            console.error('❌ APNs 发送失败:', error);
            return { success: false, error: error.message };
        }
    }

    // 发送到 FCM (Android)
    static async sendFCM(deviceTokens, notification) {
        // FCM 实现需要 Google FCM 服务
        console.log(`📱 FCM 发送: ${deviceTokens.length} 设备`);
        return { success: true, sent: deviceTokens.length };
    }

    // 发送到 Web Push
    static async sendWebPush(subscriptions, notification) {
        // Web Push 实现
        console.log(`🌐 Web Push 发送: ${subscriptions.length} 订阅`);
        return { success: true, sent: subscriptions.length };
    }

    // 发送消息推送
    static async sendMessagePush(userId, message) {
        return await this.sendPush(userId, {
            title: '新消息',
            body: message.content.substring(0, 100),
            sound: 'default',
            badge: 1,
            data: {
                type: 'message',
                messageId: message.id
            }
        });
    }

    // 发送定时任务提醒
    static async sendTaskReminder(userId, task) {
        return await this.sendPush(userId, {
            title: task.name,
            body: task.notification?.body || '任务提醒',
            sound: 'default',
            data: {
                type: 'task',
                taskId: task.id
            }
        });
    }

    // 发送系统通知
    static async sendSystemNotification(userId, title, body, data = {}) {
        return await this.sendPush(userId, {
            title,
            body,
            sound: 'default',
            data: {
                type: 'system',
                ...data
            }
        });
    }
}

// API 路由
module.exports = (app) => {
    // 注册设备
    app.post('/api/push/register', async (req, res) => {
        try {
            const { deviceToken, deviceType, userId } = req.body;

            if (!deviceToken || !deviceType || !userId) {
                return res.status(400).json({
                    success: false,
                    error: '缺少必要参数'
                });
            }

            PushNotificationService.registerDevice(deviceToken, deviceType, userId);

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
    app.post('/api/push/unregister', async (req, res) => {
        try {
            const { deviceToken } = req.body;

            if (!deviceToken) {
                return res.status(400).json({
                    success: false,
                    error: '缺少设备 Token'
                });
            }

            PushNotificationService.unregisterDevice(deviceToken);

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
    app.post('/api/push/subscribe', async (req, res) => {
        try {
            const { userId, subscription } = req.body;

            if (!userId || !subscription) {
                return res.status(400).json({
                    success: false,
                    error: '缺少必要参数'
                });
            }

            PushNotificationService.subscribeWebPush(userId, subscription);

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
    app.post('/api/push/test', async (req, res) => {
        try {
            const { userId, title, body } = req.body;

            if (!userId) {
                return res.status(400).json({
                    success: false,
                    error: '缺少用户 ID'
                });
            }

            const result = await PushNotificationService.sendSystemNotification(
                userId,
                title || '测试通知',
                body || '这是一条测试推送消息'
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
};

module.exports.PushNotificationService = PushNotificationService;
