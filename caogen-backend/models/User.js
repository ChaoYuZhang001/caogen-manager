/**
 * 用户模型
 * 支持多个平台（草包 iOS/macOS/iPadOS + 草根管家 iOS）
 */

const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    // 基本信息
    userIdentifier: {
        type: String,
        required: true,
        unique: true,
        index: true
    },

    email: {
        type: String,
        index: true,
        sparse: true
    },

    emailVerified: {
        type: Boolean,
        default: false
    },

    fullName: {
        type: String,
        default: ''
    },

    // 提供商信息
    provider: {
        type: String,
        enum: ['apple', 'guest', 'phone', 'wechat'],
        default: 'guest'
    },

    platform: {
        type: String,
        enum: ['ios', 'ipados', 'macos', 'web', 'android'],
        default: 'web'
    },

    // 平台关联（用于账号互通）
    caobaoUserIdentifier: {
        type: String,
        sparse: true,
        index: true
    },

    hasCaobaoLinked: {
        type: Boolean,
        default: false
    },

    caogenUserIdentifier: {
        type: String,
        sparse: true,
        index: true
    },

    hasCaogenLinked: {
        type: Boolean,
        default: false
    },

    // 设置
    settings: {
        type: Object,
        default: {}
    },

    // 时间戳
    createdAt: {
        type: Date,
        default: Date.now
    },

    updatedAt: {
        type: Date,
        default: Date.now
    },

    expiresAt: {
        type: Date
    }
});

// 索引
userSchema.index({ createdAt: -1 });
userSchema.index({ updatedAt: -1 });

// 中间件
userSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

module.exports = mongoose.model('User', userSchema);
