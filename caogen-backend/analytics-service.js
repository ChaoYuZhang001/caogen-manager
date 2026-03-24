/**
 * 用户行为分析服务
 * 收集和分析用户行为数据，提供洞察和报表
 */

const mongoose = require('mongoose');
const crypto = require('crypto');

// 事件模型
const EventSchema = new mongoose.Schema({
    eventId: {
        type: String,
        required: true,
        index: true
    },
    eventType: {
        type: String,
        required: true,
        index: true
    },
    userId: {
        type: String,
        index: true
    },
    sessionId: String,
    deviceId: String,
    deviceType: String,
    appVersion: String,
    platform: String,
    properties: mongoose.Schema.Types.Mixed,
    timestamp: {
        type: Date,
        default: Date.now,
        index: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// 用户模型
const UserProfileSchema = new mongoose.Schema({
    userId: {
        type: String,
        required: true,
        unique: true,
        index: true
    },
    firstSeen: {
        type: Date,
        default: Date.now
    },
    lastSeen: {
        type: Date,
        default: Date.now
    },
    totalSessions: {
        type: Number,
        default: 0
    },
    totalEvents: {
        type: Number,
        default: 0
    },
    activeDays: {
        type: Number,
        default: 0
    },
    // 功能使用统计
    featureUsage: {
        chat: { type: Number, default: 0 },
        voice: { type: Number, default: 0 },
        quickActions: { type: Number, default: 0 },
        scheduledTasks: { type: Number, default: 0 },
        files: { type: Number, default: 0 },
        settings: { type: Number, default: 0 }
    },
    // 设备信息
    devices: [{
        deviceId: String,
        deviceType: String,
        appVersion: String,
        firstSeen: Date,
        lastSeen: Date
    }],
    // 用户属性
    properties: {
        language: String,
        timezone: String,
        pushEnabled: Boolean,
        biometricEnabled: Boolean
    }
}, {
    timestamps: true
});

// 事件类型定义
const EVENT_TYPES = {
    // 会话事件
    SESSION_START: 'session_start',
    SESSION_END: 'session_end',

    // 功能使用
    CHAT_SEND: 'chat_send',
    CHAT_RECEIVE: 'chat_receive',
    VOICE_START: 'voice_start',
    VOICE_END: 'voice_end',
    QUICK_ACTION: 'quick_action',
    TASK_CREATE: 'task_create',
    TASK_COMPLETE: 'task_complete',

    // 导航
    SCREEN_VIEW: 'screen_view',
    TAB_SWITCH: 'tab_switch',

    // 设置
    SETTINGS_CHANGE: 'settings_change',
    THEME_CHANGE: 'theme_change',
    LANGUAGE_CHANGE: 'language_change',

    // 错误
    ERROR: 'error',
    CRASH: 'crash',

    // 业务
    FILE_UPLOAD: 'file_upload',
    FILE_DOWNLOAD: 'file_download',
    SHARE: 'share',
    LOGIN: 'login',
    LOGOUT: 'logout'
};

// 分析服务类
class AnalyticsService {
    static Event = null;
    static UserProfile = null;
    static isInitialized = false;

    // 初始化
    static async initialize() {
        if (this.isInitialized) return;

        console.log('初始化用户行为分析服务...');

        try {
            this.Event = mongoose.models.AnalyticsEvent || mongoose.model('AnalyticsEvent', EventSchema);
            this.UserProfile = mongoose.models.AnalyticsUserProfile || mongoose.model('AnalyticsUserProfile', UserProfileSchema);
            this.isInitialized = true;
            console.log('✅ 用户行为分析服务初始化完成');
        } catch (error) {
            console.log('⚠️ MongoDB 未连接，使用内存存储');
            this.events = [];
        }
    }

    // 追踪事件
    static async track(event) {
        const eventData = {
            eventId: crypto.randomUUID(),
            eventType: event.eventType,
            userId: event.userId,
            sessionId: event.sessionId,
            deviceId: event.deviceId,
            deviceType: event.deviceType,
            appVersion: event.appVersion,
            platform: event.platform,
            properties: event.properties || {},
            timestamp: event.timestamp || new Date()
        };

        // 保存到数据库
        if (this.Event) {
            try {
                await this.Event.create(eventData);
            } catch (error) {
                console.error('保存事件失败:', error);
            }
        } else {
            this.events.push(eventData);
        }

        // 更新用户画像
        if (eventData.userId) {
            await this.updateUserProfile(eventData);
        }

        console.log(`📊 事件追踪: ${eventData.eventType}`);

        return eventData;
    }

    // 更新用户画像
    static async updateUserProfile(event) {
        if (!this.UserProfile) return;

        try {
            const update = {
                $inc: {
                    totalEvents: 1
                },
                $set: {
                    lastSeen: new Date()
                }
            };

            // 根据事件类型更新统计
            switch (event.eventType) {
                case EVENT_TYPES.SESSION_START:
                    update.$inc.totalSessions = 1;
                    update.$set['devices'] = {
                        deviceId: event.deviceId,
                        deviceType: event.deviceType,
                        appVersion: event.appVersion,
                        lastSeen: new Date()
                    };
                    break;

                case EVENT_TYPES.CHAT_SEND:
                case EVENT_TYPES.CHAT_RECEIVE:
                    update.$inc['featureUsage.chat'] = 1;
                    break;

                case EVENT_TYPES.VOICE_START:
                case EVENT_TYPES.VOICE_END:
                    update.$inc['featureUsage.voice'] = 1;
                    break;

                case EVENT_TYPES.QUICK_ACTION:
                    update.$inc['featureUsage.quickActions'] = 1;
                    break;

                case EVENT_TYPES.TASK_CREATE:
                case EVENT_TYPES.TASK_COMPLETE:
                    update.$inc['featureUsage.scheduledTasks'] = 1;
                    break;

                case EVENT_TYPES.FILE_UPLOAD:
                case EVENT_TYPES.FILE_DOWNLOAD:
                    update.$inc['featureUsage.files'] = 1;
                    break;

                case EVENT_TYPES.SETTINGS_CHANGE:
                    update.$inc['featureUsage.settings'] = 1;
                    break;

                case EVENT_TYPES.THEME_CHANGE:
                    if (event.properties?.theme) {
                        update.$set['properties.language'] = event.properties.theme;
                    }
                    break;

                case EVENT_TYPES.LANGUAGE_CHANGE:
                    if (event.properties?.language) {
                        update.$set['properties.language'] = event.properties.language;
                    }
                    break;
            }

            await this.UserProfile.findOneAndUpdate(
                { userId: event.userId },
                update,
                { upsert: true, new: true }
            );

        } catch (error) {
            console.error('更新用户画像失败:', error);
        }
    }

    // 获取用户画像
    static async getUserProfile(userId) {
        if (!this.UserProfile) {
            return null;
        }

        try {
            return await this.UserProfile.findOne({ userId });
        } catch (error) {
            console.error('获取用户画像失败:', error);
            return null;
        }
    }

    // 获取统计数据
    static async getStats(options = {}) {
        const { startDate, endDate, userId, eventType } = options;

        const query = {};

        if (startDate || endDate) {
            query.timestamp = {};
            if (startDate) query.timestamp.$gte = new Date(startDate);
            if (endDate) query.timestamp.$lte = new Date(endDate);
        }

        if (userId) query.userId = userId;
        if (eventType) query.eventType = eventType;

        try {
            const total = await this.Event.countDocuments(query);
            const events = await this.Event.find(query)
                .sort({ timestamp: -1 })
                .limit(100);

            // 按事件类型分组统计
            const typeStats = await this.Event.aggregate([
                { $match: query },
                { $group: { _id: '$eventType', count: { $sum: 1 } } },
                { $sort: { count: -1 } }
            ]);

            // 按日期分组统计
            const dateStats = await this.Event.aggregate([
                { $match: query },
                {
                    $group: {
                        _id: {
                            $dateToString: { format: '%Y-%m-%d', date: '$timestamp' }
                        },
                        count: { $sum: 1 }
                    }
                },
                { $sort: { _id: -1 } },
                { $limit: 30 }
            ]);

            // 唯一用户数
            const uniqueUsers = await this.Event.distinct('userId', query);

            return {
                total,
                uniqueUsers: uniqueUsers.length,
                typeStats: typeStats.reduce((acc, t) => {
                    acc[t._id] = t.count;
                    return acc;
                }, {}),
                dateStats,
                recentEvents: events.slice(0, 10)
            };

        } catch (error) {
            console.error('获取统计数据失败:', error);
            return null;
        }
    }

    // 获取漏斗分析
    static async getFunnel(funnelSteps, options = {}) {
        const { startDate, endDate, userId } = options;

        const results = [];

        for (const step of funnelSteps) {
            const query = { eventType: step.eventType };

            if (startDate || endDate) {
                query.timestamp = {};
                if (startDate) query.timestamp.$gte = new Date(startDate);
                if (endDate) query.timestamp.$lte = new Date(endDate);
            }

            if (userId) query.userId = userId;

            try {
                const count = await this.Event.countDocuments(query);
                results.push({
                    step: step.name,
                    eventType: step.eventType,
                    count,
                    rate: results.length > 0 ?
                        ((count / results[0].count) * 100).toFixed(2) + '%' : '100%'
                });
            } catch (error) {
                console.error('获取漏斗数据失败:', error);
            }
        }

        return results;
    }

    // 获取留存率
    static async getRetention(cohortDate) {
        if (!this.UserProfile) {
            return null;
        }

        try {
            const cohorts = await this.UserProfile.aggregate([
                {
                    $match: {
                        firstSeen: {
                            $gte: new Date(cohortDate),
                            $lt: new Date(new Date(cohortDate).getTime() + 24 * 60 * 60 * 1000)
                        }
                    }
                },
                {
                    $group: {
                        _id: null,
                        totalUsers: { $sum: 1 },
                        activeUsers: {
                            $sum: { $cond: [{ $gte: ['$lastSeen', new Date()] }, 1, 0] }
                        }
                    }
                }
            ]);

            if (cohorts.length === 0) {
                return { totalUsers: 0, retentionRate: 0 };
            }

            const { totalUsers, activeUsers } = cohorts[0];

            return {
                totalUsers,
                activeUsers,
                retentionRate: ((activeUsers / totalUsers) * 100).toFixed(2) + '%',
                cohortDate
            };

        } catch (error) {
            console.error('获取留存率失败:', error);
            return null;
        }
    }

    // 获取功能使用排名
    static async getFeatureRanking() {
        if (!this.UserProfile) {
            return null;
        }

        try {
            const profiles = await this.UserProfile.find();

            const ranking = {
                chat: 0,
                voice: 0,
                quickActions: 0,
                scheduledTasks: 0,
                files: 0,
                settings: 0
            };

            for (const profile of profiles) {
                if (profile.featureUsage) {
                    for (const [feature, count] of Object.entries(profile.featureUsage)) {
                        ranking[feature] = (ranking[feature] || 0) + count;
                    }
                }
            }

            return Object.entries(ranking)
                .sort((a, b) => b[1] - a[1])
                .map(([feature, count]) => ({ feature, count }));

        } catch (error) {
            console.error('获取功能排名失败:', error);
            return null;
        }
    }
}

// API 路由
module.exports = (app) => {
    // 追踪事件
    app.post('/api/analytics/track', async (req, res) => {
        try {
            const event = req.body;

            if (!event.eventType) {
                return res.status(400).json({
                    success: false,
                    error: '缺少事件类型'
                });
            }

            const eventData = await AnalyticsService.track(event);

            res.json({
                success: true,
                eventId: eventData.eventId
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 获取统计数据
    app.get('/api/analytics/stats', async (req, res) => {
        try {
            const stats = await AnalyticsService.getStats({
                startDate: req.query.startDate,
                endDate: req.query.endDate,
                userId: req.query.userId,
                eventType: req.query.eventType
            });

            res.json({
                success: true,
                data: stats
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 获取用户画像
    app.get('/api/analytics/profile/:userId', async (req, res) => {
        try {
            const profile = await AnalyticsService.getUserProfile(req.params.userId);

            res.json({
                success: true,
                data: profile
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 获取漏斗分析
    app.get('/api/analytics/funnel', async (req, res) => {
        try {
            const defaultFunnel = [
                { name: '启动', eventType: 'session_start' },
                { name: '发送消息', eventType: 'chat_send' },
                { name: '收到回复', eventType: 'chat_receive' }
            ];

            const funnel = await AnalyticsService.getFunnel(defaultFunnel, {
                startDate: req.query.startDate,
                endDate: req.query.endDate
            });

            res.json({
                success: true,
                data: funnel
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 获取功能排名
    app.get('/api/analytics/ranking', async (req, res) => {
        try {
            const ranking = await AnalyticsService.getFeatureRanking();

            res.json({
                success: true,
                data: ranking
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 获取留存率
    app.get('/api/analytics/retention', async (req, res) => {
        try {
            const cohortDate = req.query.date || new Date().toISOString().split('T')[0];
            const retention = await AnalyticsService.getRetention(cohortDate);

            res.json({
                success: true,
                data: retention
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });
};

module.exports.EVENT_TYPES = EVENT_TYPES;
module.exports.AnalyticsService = AnalyticsService;
