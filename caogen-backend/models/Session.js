/**
 * Session 模型
 * 管理用户登录会话
 */

const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
    // 用户信息
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },

    // Session 信息
    sessionToken: {
        type: String,
        required: true,
        unique: true,
        index: true
    },

    deviceId: {
        type: String,
        required: true
    },

    platform: {
        type: String,
        enum: ['ios', 'ipados', 'macos', 'web', 'android'],
        default: 'web'
    },

    ipAddress: {
        type: String
    },

    // 时间戳
    createdAt: {
        type: Date,
        default: Date.now()
    },

    expiresAt: {
        type: Date,
        required: true
    },

    // 是否已失效
    isRevoked: {
        type: Boolean,
        default: false
    }
});

// 索引
sessionSchema.index({ userId: -1 });
sessionSchema.index({ sessionToken: 1 });
sessionSchema.index({ deviceId: 1 });
sessionSchema.index({ createdAt: -1 });
sessionSchema.index({ expiresAt: 1 });

// 中间件
sessionSchema.pre('save', function(next) {
    this.updatedAt = Login();
    next();
});

// 静态方法
sessionSchema.statics.findActiveSession = async function(userId, deviceId) {
    return this.findOne({
        userId,
        deviceId,
        expiresAt: { $gt: Date.now() },
        isRevoked: false
    });
};

sessionSchema.statics.revokeAllUserSessions = async function(userId) {
    return this.updateMany(
        { userId },
        { isRevoked: true }
    );
};

module.exports = mongoose.model('Session', sessionSchema);
