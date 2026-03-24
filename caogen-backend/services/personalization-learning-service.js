/**
 * 个性化学习服务 - Personalization Learning Service
 * 学习用户说话方式、记住偏好、适应习惯
 */

class PersonalizationLearningService {
    constructor() {
        this.userProfiles = new Map(); // 用户画像
        this.learningData = new Map(); // 学习数据
        this.patterns = new Map(); // 模式识别
        this.adaptations = new Map(); // 适应性调整
    }

    /**
     * 记录用户行为
     */
    recordBehavior(userId, behavior) {
        const timestamp = Date.now();

        if (!this.learningData.has(userId)) {
            this.learningData.set(userId, []);
        }

        this.learningData.get(userId).push({
            ...behavior,
            timestamp
        });

        // 更新用户画像
        this.updateUserProfile(userId, behavior);

        // 识别模式
        this.detectPatterns(userId);

        return { success: true, message: '行为已记录' };
    }

    /**
     * 更新用户画像
     */
    updateUserProfile(userId, behavior) {
        const profile = this.getUserProfile(userId);

        // 更新说话风格
        if (behavior.type === 'message') {
            this.updateSpeakingStyle(profile, behavior.content);
        }

        // 更新偏好
        if (behavior.preference) {
            profile.preferences = {
                ...profile.preferences,
                ...behavior.preference
            };
        }

        // 更新习惯
        if (behavior.habit) {
            if (!profile.habits.includes(behavior.habit)) {
                profile.habits.push(behavior.habit);
            }
        }

        // 更新活跃时间
        if (behavior.activeTime) {
            if (!profile.activeTimes.includes(behavior.activeTime)) {
                profile.activeTimes.push(behavior.activeTime);
            }
        }

        profile.updatedAt = Date.now();
        this.userProfiles.set(userId, profile);

        return profile;
    }

    /**
     * 更新说话风格
     */
    updateSpeakingStyle(profile, message) {
        // 分析语气
        const tone = this.analyzeTone(message);

        if (tone) {
            profile.speakingStyle.tones[tone] = (profile.speakingStyle.tones[tone] || 0) + 1;
        }

        // 分析常用词
        const words = this.extractCommonWords(message);

        words.forEach(word => {
            profile.speakingStyle.commonWords[word] = (profile.speakingStyle.commonWords[word] || 0) + 1;
        });

        // 分析称呼
        const address = this.extractAddress(message);

        if (address) {
            profile.speakingStyle.preferredAddress = address;
        }
    }

    /**
     * 分析语气
     */
    analyzeTone(message) {
        const tonePatterns = {
            'casual': ['哈哈', '嘿', '哦', '嗯', '好的', '行'],
            'formal': ['请问', '麻烦', '谢谢', '您好'],
            'friendly': ['兄弟', '哥们', '亲爱的', '宝贝'],
            'urgent': ['快点', '急', '马上', '赶紧']
        };

        for (const [tone, patterns] of Object.entries(tonePatterns)) {
            for (const pattern of patterns) {
                if (message.includes(pattern)) {
                    return tone;
                }
            }
        }

        return null;
    }

    /**
     * 提取常用词
     */
    extractCommonWords(message) {
        const stopWords = ['的', '了', '是', '在', '和', '我', '你', '他'];
        const words = message.split(/[\s,.!?，。！？]+/);

        return words.filter(word => word.length > 1 && !stopWords.includes(word));
    }

    /**
     * 提取称呼
     */
    extractAddress(message) {
        const addressPatterns = [
            { pattern: '主人', address: '主人' },
            { pattern: '兄弟', address: '兄弟' },
            { pattern: '哥们', address: '哥们' },
            { pattern: '亲爱的', address: '亲爱的' },
            { pattern: '草根', address: '草根' }
        ];

        for (const { pattern, address } of addressPatterns) {
            if (message.includes(pattern)) {
                return address;
            }
        }

        return null;
    }

    /**
     * 识别模式
     */
    detectPatterns(userId) {
        const data = this.learningData.get(userId) || [];

        if (!this.patterns.has(userId)) {
            this.patterns.set(userId, {});
        }

        const patterns = this.patterns.get(userId);

        // 时间模式
        patterns.timePatterns = this.detectTimePatterns(data);

        // 行为模式
        patterns.behaviorPatterns = this.detectBehaviorPatterns(data);

        // 偏好模式
        patterns.preferencePatterns = this.detectPreferencePatterns(data);

        return patterns;
    }

    /**
     * 检测时间模式
     */
    detectTimePatterns(data) {
        const byHour = {};

        data.forEach(item => {
            const hour = new Date(item.timestamp).getHours();

            if (!byHour[hour]) {
                byHour[hour] = [];
            }

            byHour[hour].push(item);
        });

        const patterns = [];

        Object.keys(byHour).forEach(hour => {
            const items = byHour[hour];

            if (items.length >= 5) { // 至少5次
                const actions = items.map(i => i.type);

                patterns.push({
                    hour: parseInt(hour),
                    frequency: items.length,
                    commonActions: this.getMostFrequent(actions)
                });
            }
        });

        return patterns;
    }

    /**
     * 检测行为模式
     */
    detectBehaviorPatterns(data) {
        const sequences = [];

        for (let i = 1; i < data.length; i++) {
            const prev = data[i - 1];
            const curr = data[i];

            if (curr.timestamp - prev.timestamp < 5 * 60 * 1000) { // 5分钟内
                sequences.push({
                    from: prev.type,
                    to: curr.type,
                    count: 1
                });
            }
        }

        // 合并相同序列
        const merged = {};

        sequences.forEach(seq => {
            const key = `${seq.from}->${seq.to}`;
            merged[key] = (merged[key] || 0) + seq.count;
        });

        return Object.entries(merged)
            .map(([key, count]) => ({
                sequence: key,
                count,
                probability: count / data.length
            }))
            .filter(p => p.probability > 0.1);
    }

    /**
     * 检测偏好模式
     */
    detectPreferencePatterns(data) {
        const preferences = {};

        data.forEach(item => {
            if (item.preference) {
                Object.entries(item.preference).forEach(([key, value]) => {
                    if (!preferences[key]) {
                        preferences[key] = {};
                    }

                    preferences[key][value] = (preferences[key][value] || 0) + 1;
                });
            }
        });

        return Object.entries(preferences).map(([key, values]) => ({
            key,
            mostFrequent: this.getMostFrequentValue(values)
        }));
    }

    /**
     * 获取最频繁的值
     */
    getMostFrequentValue(values) {
        return Object.entries(values)
            .sort((a, b) => b[1] - a[1])[0][0];
    }

    /**
     * 获取最频繁的项目
     */
    getMostFrequent(items) {
        const counts = {};

        items.forEach(item => {
            counts[item] = (counts[item] || 0) + 1;
        });

        return Object.entries(counts)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 3)
            .map(([item, count]) => ({ item, count }));
    }

    /**
     * 生成个性化回复
     */
    generatePersonalizedResponse(userId, context) {
        const profile = this.getUserProfile(userId);
        const patterns = this.patterns.get(userId) || {};

        let response = '';

        // 使用用户喜欢的称呼
        const address = profile.speakingStyle.preferredAddress || '主人';
        response += address + '，';

        // 根据语气选择回复风格
        const dominantTone = this.getDominantTone(profile.speakingStyle.tones);

        if (dominantTone === 'casual') {
            response += '好的，没问题！';
        } else if (dominantTone === 'formal') {
            response += '好的，为您服务。';
        } else if (dominantTone === 'friendly') {
            response += '没问题，兄弟！';
        } else {
            response += '好的，我明白了。';
        }

        // 根据偏好添加个性化内容
        if (profile.preferences.coffee && profile.preferences.coffee.type) {
            response += ` 需要来杯${profile.preferences.coffee.type}吗？`;
        }

        if (profile.preferences.music && profile.preferences.music.genre) {
            response += ` 或者听听${profile.preferences.music.genre}？`;
        }

        return response;
    }

    /**
     * 获取主要语气
     */
    getDominantTone(tones) {
        const entries = Object.entries(tones);

        if (entries.length === 0) {
            return 'neutral';
        }

        return entries.sort((a, b) => b[1] - a[1])[0][0];
    }

    /**
     * 个性化推荐
     */
    getPersonalizedRecommendations(userId) {
        const profile = this.getUserProfile(userId);
        const patterns = this.patterns.get(userId) || {};

        const recommendations = [];

        // 基于偏好的推荐
        if (profile.preferences.coffee) {
            recommendations.push({
                type: 'preference',
                category: 'coffee',
                title: `${profile.preferences.coffee.type} 时间`,
                reason: `你喜欢 ${profile.preferences.coffee.type}，休息一下`
            });
        }

        if (profile.preferences.music) {
            recommendations.push({
                type: 'preference',
                category: 'music',
                title: `${profile.preferences.music.genre} 音乐`,
                reason: `听听 ${profile.preferences.music.genre} 放松一下`
            });
        }

        // 基于时间模式的推荐
        if (patterns.timePatterns) {
            patterns.timePatterns.forEach(pattern => {
                const currentHour = new Date().getHours();

                if (pattern.hour === currentHour) {
                    pattern.commonActions.forEach(action => {
                        recommendations.push({
                            type: 'habit',
                            category: action.item,
                            title: `${action.item} 时间`,
                            reason: `你经常在这个时间${action.item}`
                        });
                    });
                }
            });
        }

        return recommendations;
    }

    /**
     * 适应学习
     */
    adaptToUser(userId, feedback) {
        if (!this.adaptations.has(userId)) {
            this.adaptations.set(userId, []);
        }

        const adaptations = this.adaptations.get(userId);

        adaptations.push({
            type: 'adaptation',
            feedback,
            timestamp: Date.now()
        });

        // 根据反馈调整策略
        this.adjustStrategy(userId, feedback);

        return { success: true, message: '已适应用户反馈' };
    }

    /**
     * 调整策略
     */
    adjustStrategy(userId, feedback) {
        const profile = this.getUserProfile(userId);

        if (feedback.type === 'preference_change') {
            profile.preferences = {
                ...profile.preferences,
                ...feedback.changes
            };
        } else if (feedback.type === 'speaking_style_change') {
            profile.speakingStyle = {
                ...profile.speakingStyle,
                ...feedback.changes
            };
        } else if (feedback.type === 'tone_change') {
            profile.speakingStyle.tones[feedback.tone] =
                (profile.speakingStyle.tones[feedback.tone] || 0) + 1;
        }

        profile.updatedAt = Date.now();
        this.userProfiles.set(userId, profile);
    }

    /**
     * 获取用户画像
     */
    getUserProfile(userId) {
        if (!this.userProfiles.has(userId)) {
            this.userProfiles.set(userId, {
                id: userId,
                nickname: '主人',
                speakingStyle: {
                    tones: {},
                    commonWords: {},
                    preferredAddress: '主人'
                },
                preferences: {},
                habits: [],
                activeTimes: [],
                createdAt: Date.now(),
                updatedAt: Date.now()
            });
        }

        return this.userProfiles.get(userId);
    }

    /**
     * 导出学习数据
     */
    exportLearningData(userId) {
        return {
            userId,
            profile: this.getUserProfile(userId),
            patterns: this.patterns.get(userId) || {},
            adaptations: this.adaptations.get(userId) || []
        };
    }

    /**
     * 导入学习数据
     */
    importLearningData(data) {
        this.userProfiles.set(data.userId, data.profile);
        this.patterns.set(data.userId, data.patterns);
        this.adaptations.set(data.userId, data.adaptations);

        return { success: true, message: '学习数据已导入' };
    }

    /**
     * 清除学习数据
     */
    clearLearningData(userId) {
        this.userProfiles.delete(userId);
        this.learningData.delete(userId);
        this.patterns.delete(userId);
        this.adaptations.delete(userId);

        return { success: true, message: '学习数据已清除' };
    }
}

module.exports = PersonalizationLearningService;
