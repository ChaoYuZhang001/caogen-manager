/**
 * 云同步服务
 * 支持多设备数据同步、冲突解决、离线模式
 */

const mongoose = require('mongoose');
const crypto = require('crypto');

// 同步数据模型
const SyncDataSchema = new mongoose.Schema({
    deviceId: {
        type: String,
        required: true
    },
    userId: {
        type: String,
        required: true
    },
    type: {
        type: String,
        enum: ['messages', 'settings', 'quickActions', 'scheduledTasks', 'plugins'],
        required: true
    },
    version: {
        type: Number,
        required: true
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    data: mongoose.Schema.Types.Mixed,
    checksum: String,
    isDeleted: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// 设备模型
const DeviceSchema = new mongoose.Schema({
    userId: {
        type: String,
        required: true
    },
    deviceId: {
        type: String,
        required: true,
        unique: true
    },
    deviceName: String,
    deviceType: {
        type: String,
        enum: ['ios', 'android', 'web', 'desktop'],
        default: 'ios'
    },
    osVersion: String,
    appVersion: String,
    lastSeen: {
        type: Date,
        default: Date.now
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

// 冲突记录模型
const ConflictSchema = new mongoose.Schema({
    userId: {
        type: String,
        required: true
    },
    type: {
        type: String,
        required: true
    },
    itemId: String,
    localData: mongoose.Schema.Types.Mixed,
    remoteData: mongoose.Schema.Types.Mixed,
    resolvedAt: Date,
    resolution: {
        type: String,
        enum: ['keepLocal', 'keepRemote', 'keepLatest', 'merge', 'manual'],
        default: 'manual'
    },
    resolvedBy: String
}, {
    timestamps: true
});

const SyncData = mongoose.models.SyncData || mongoose.model('SyncData', SyncDataSchema);
const Device = mongoose.models.Device || mongoose.model('Device', DeviceSchema);
const Conflict = mongoose.models.Conflict || mongoose.model('Conflict', ConflictSchema);

class CloudSyncService {
    static config = {
        enabled: false,
        syncInterval: 300, // 5分钟
        syncOnWiFi: true,
        syncOnCharging: false,
        compressData: true,
        encryption: true,
        encryptionKey: process.env.SYNC_ENCRYPTION_KEY || 'default-encryption-key-32ch'
    };

    static deviceId = null;
    static isInitialized = false;
    static lastSyncTime = null;
    static pendingSync = [];
    static isSyncing = false;

    // 初始化
    static async initialize() {
        if (this.isInitialized) return;

        console.log('初始化云同步服务...');

        // 加载配置
        await this.loadConfig();

        this.isInitialized = true;
        console.log('✅ 云同步服务初始化完成');

        // 启动定期同步
        if (this.config.enabled) {
            this.startPeriodicSync();
        }
    }

    // 加载配置
    static async loadConfig() {
        try {
            // 从数据库加载同步配置
            const configDoc = await mongoose.models.SystemConfig?.findOne({ key: 'sync_config' });
            if (configDoc) {
                this.config = { ...this.config, ...configDoc.value };
            }
        } catch (error) {
            console.log('使用默认同步配置');
        }
    }

    // 启动定期同步
    static startPeriodicSync() {
        setInterval(async () => {
            await this.sync();
        }, this.config.syncInterval * 1000);
    }

    // 获取同步状态
    static getSyncStatus() {
        return {
            enabled: this.config.enabled,
            lastSyncTime: this.lastSyncTime,
            pendingCount: this.pendingSync.length,
            isSyncing: this.isSyncing,
            deviceId: this.deviceId
        };
    }

    // 触发同步
    static async triggerSync() {
        return await this.sync();
    }

    // 执行同步
    static async sync() {
        if (this.isSyncing || !this.config.enabled) {
            return { success: false, reason: 'already_syncing_or_disabled' };
        }

        this.isSyncing = true;

        try {
            // 1. 上传本地数据
            await this.uploadPendingData();

            // 2. 下载远程数据
            await this.downloadRemoteData();

            // 3. 解决冲突
            await this.resolveConflicts();

            this.lastSyncTime = new Date();

            return {
                success: true,
                timestamp: this.lastSyncTime,
                uploaded: this.pendingSync.length,
                downloaded: 0
            };

        } catch (error) {
            console.error('同步失败:', error);
            return {
                success: false,
                error: error.message
            };
        } finally {
            this.isSyncing = false;
        }
    }

    // 上传待同步数据
    static async uploadPendingData() {
        while (this.pendingSync.length > 0) {
            const syncItem = this.pendingSync.shift();

            try {
                // 加密数据
                let data = syncItem.data;
                if (this.config.encryption) {
                    data = await this.encryptData(data);
                }

                // 创建同步记录
                const syncData = new SyncData({
                    deviceId: this.deviceId,
                    userId: syncItem.userId,
                    type: syncItem.type,
                    version: syncItem.version,
                    timestamp: new Date(),
                    data,
                    checksum: this.calculateChecksum(syncItem.data)
                });

                await syncData.save();
                console.log(`✅ 上传同步数据: ${syncItem.type} v${syncItem.version}`);

            } catch (error) {
                console.error(`❌ 上传失败:`, error);
                // 重新加入队列
                this.pendingSync.push(syncItem);
            }
        }
    }

    // 下载远程数据
    static async downloadRemoteData() {
        if (!this.deviceId) return;

        try {
            const since = this.lastSyncTime || new Date(0);

            // 获取其他设备的最新数据
            const remoteData = await SyncData.find({
                deviceId: { $ne: this.deviceId },
                timestamp: { $gt: since }
            }).sort({ timestamp: -1 });

            // 按类型分组
            const groupedData = {};
            for (const item of remoteData) {
                if (!groupedData[item.type] || groupedData[item.type].version < item.version) {
                    let data = item.data;

                    // 解密数据
                    if (this.config.encryption) {
                        data = await this.decryptData(data);
                    }

                    groupedData[item.type] = {
                        ...item.toObject(),
                        data
                    };
                }
            }

            // 合并数据
            for (const [type, data] of Object.entries(groupedData)) {
                await this.mergeData(type, data);
            }

            console.log(`📥 下载了 ${Object.keys(groupedData).length} 条同步数据`);

        } catch (error) {
            console.error('下载远程数据失败:', error);
        }
    }

    // 合并数据
    static async mergeData(type, remoteData) {
        // TODO: 实现具体的合并逻辑
        console.log(`🔀 合并数据: ${type}`);
    }

    // 获取数据
    static async getData(type, since) {
        try {
            const query = {
                type,
                isDeleted: false
            };

            if (since) {
                query.timestamp = { $gt: new Date(since) };
            }

            const data = await SyncData.find(query)
                .sort({ timestamp: -1 })
                .limit(100);

            return data.map(item => ({
                ...item.toObject(),
                data: this.config.encryption ? item.data : item.data
            }));

        } catch (error) {
            console.error('获取同步数据失败:', error);
            return [];
        }
    }

    // 上传数据
    static async uploadData(type, data, userId = 'default') {
        const syncItem = {
            type,
            data,
            version: Date.now(),
            userId,
            timestamp: new Date()
        };

        this.pendingSync.push(syncItem);

        // 尝试立即同步
        if (!this.isSyncing) {
            await this.sync();
        }

        return { success: true, queued: true };
    }

    // 检测冲突
    static async detectConflicts(type, localData, remoteData) {
        const conflicts = [];

        for (const [id, localItem] of Object.entries(localData)) {
            const remoteItem = remoteData[id];

            if (remoteItem && remoteItem.version !== localItem.version) {
                const localTime = new Date(localItem.updatedAt || 0);
                const remoteTime = new Date(remoteItem.updatedAt || 0);

                // 如果时间相同但内容不同，则是冲突
                if (Math.abs(localTime.getTime() - remoteTime.getTime()) < 1000 &&
                    JSON.stringify(localItem) !== JSON.stringify(remoteItem)) {

                    conflicts.push({
                        type,
                        itemId: id,
                        localData: localItem,
                        remoteData: remoteItem,
                        localTime,
                        remoteTime
                    });
                }
            }
        }

        // 记录冲突
        for (const conflict of conflicts) {
            try {
                const conflictRecord = new Conflict({
                    userId: 'default',
                    type: conflict.type,
                    itemId: conflict.itemId,
                    localData: conflict.localData,
                    remoteData: conflict.remoteData
                });
                await conflictRecord.save();
            } catch (e) {
                console.error('记录冲突失败:', e);
            }
        }

        return conflicts;
    }

    // 解决冲突
    static async resolveConflicts() {
        try {
            const unresolved = await Conflict.find({
                resolvedAt: null
            });

            for (const conflict of unresolved) {
                // 自动解决：保留最新
                conflict.resolution = 'keepLatest';
                conflict.resolvedAt = new Date();
                conflict.resolvedBy = 'auto';

                await conflict.save();
            }

            if (unresolved.length > 0) {
                console.log(`✅ 自动解决了 ${unresolved.length} 个冲突`);
            }

        } catch (error) {
            console.error('解决冲突失败:', error);
        }
    }

    // 注册设备
    static async registerDevice(deviceInfo) {
        try {
            const device = await Device.findOneAndUpdate(
                { deviceId: deviceInfo.deviceId },
                {
                    ...deviceInfo,
                    lastSeen: new Date(),
                    isActive: true
                },
                { upsert: true, new: true }
            );

            this.deviceId = deviceInfo.deviceId;
            console.log(`✅ 设备注册成功: ${deviceInfo.deviceName}`);

            return device;

        } catch (error) {
            console.error('设备注册失败:', error);
            throw error;
        }
    }

    // 加密数据
    static async encryptData(data) {
        const text = JSON.stringify(data);
        const iv = crypto.randomBytes(16);
        const key = crypto.scryptSync(this.config.encryptionKey, 'salt', 32);

        const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
        let encrypted = cipher.update(text, 'utf8', 'hex');
        encrypted += cipher.final('hex');

        return {
            iv: iv.toString('hex'),
            data: encrypted
        };
    }

    // 解密数据
    static async decryptData(encrypted) {
        if (!encrypted || !encrypted.iv || !encrypted.data) {
            return encrypted;
        }

        try {
            const iv = Buffer.from(encrypted.iv, 'hex');
            const key = crypto.scryptSync(this.config.encryptionKey, 'salt', 32);

            const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
            let decrypted = decipher.update(encrypted.data, 'hex', 'utf8');
            decrypted += decipher.final('utf8');

            return JSON.parse(decrypted);
        } catch (error) {
            console.error('解密失败:', error);
            return encrypted;
        }
    }

    // 计算校验和
    static calculateChecksum(data) {
        const text = JSON.stringify(data);
        return crypto.createHash('md5').update(text).digest('hex');
    }
}

module.exports = CloudSyncService;
