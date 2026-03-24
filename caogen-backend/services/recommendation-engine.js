/**
 * 智能推荐引擎 - Recommendation Engine
 * 基于用户行为、时间、地点、天气、习惯进行智能推荐
 */

const moment = require('moment');

class RecommendationEngine {
    constructor() {
        this.userBehavior = new Map(); // 用户行为数据
        this.preferences = new Map(); // 用户偏好
        this.habits = new Map(); // 用户习惯
        this.context = {}; // 当前上下文
    }

    /**
     * 记录用户行为
     */
    recordBehavior(userId, action, context = {}) {
        const timestamp = Date.now();

        if (!this.userBehavior.has(userId)) {
            this.userBehavior.set(userId, []);
        }

        this.userBehavior.get(userId).push({
            action,
            timestamp,
            context
        });

        // 分析行为模式
        this.analyzeBehavior(userId);

        return { success: true, message: '行为已记录' };
    }

    /**
     * 分析用户行为模式
     */
    analyzeBehavior(userId) {
        const behaviors = this.userBehavior.get(userId) || [];

        // 按时间分组
        const byTime = {};
        behaviors.forEach(b => {
            const hour = new Date(b.timestamp).getHours();
            if (!byTime[hour]) byTime[hour] = [];
            byTime[hour].push(b);
        });

        // 识别习惯模式
        Object.keys(byTime).forEach(hour => {
            const actions = byTime[hour].map(b => b.action);
            const frequency = {};

            actions.forEach(action => {
                frequency[action] = (frequency[action] || 0) + 1;
            });

            // 找出高频行为（> 3次/周）
            const habits = Object.entries(frequency)
                .filter(([_, count]) => count >= 3)
                .map(([action, count]) => ({ action, count }));

            if (habits.length > 0) {
                if (!this.habits.has(userId)) {
                    this.habits.set(userId, []);
                }
                this.habits.get(userId).push({
                    hour: parseInt(hour),
                    habits
                });
            }
        });
    }

    /**
     * 更新当前上下文
     */
    updateContext(context) {
        this.context = {
            ...this.context,
            ...context
        };
    }

    /**
     * 获取智能推荐
     */
    getRecommendations(userId, limit = 5) {
        const recommendations = [];
        const now = moment();
        const hour = now.hour();
        const dayOfWeek = now.day(); // 0-6, 0=Sunday

        // 1. 基于习惯的推荐
        const userHabits = this.habits.get(userId) || [];
        const habitRecommendations = userHabits.filter(h => h.hour === hour);

        habitRecommendations.forEach(habits => {
            habits.habits.forEach(({ action }) => {
                recommendations.push({
                    type: 'habit',
                    title: this.getRecommendationTitle(action),
                    action: action,
                    reason: '根据你的日常习惯',
                    priority: 0.9
                });
            });
        });

        // 2. 基于时间的推荐
        const timeRecommendations = this.getTimeBasedRecommendations(hour, dayOfWeek);
        recommendations.push(...timeRecommendations);

        // 3. 基于地点的推荐
        if (this.context.location) {
            const locationRecommendations = this.getLocationBasedRecommendations(
                this.context.location
            );
            recommendations.push(...locationRecommendations);
        }

        // 4. 基于天气的推荐
        if (this.context.weather) {
            const weatherRecommendations = this.getWeatherBasedRecommendations(
                this.context.weather
            );
            recommendations.push(...weatherRecommendations);
        }

        // 5. 基于日程的推荐
        if (this.context.schedule) {
            const scheduleRecommendations = this.getScheduleBasedRecommendations(
                this.context.schedule
            );
            recommendations.push(...scheduleRecommendations);
        }

        // 6. 基于偏好的推荐
        const userPreferences = this.preferences.get(userId) || {};
        const preferenceRecommendations = this.getPreferenceBasedRecommendations(
            userPreferences
        );
        recommendations.push(...preferenceRecommendations);

        // 7. 随机探索推荐（15%概率）
        if (Math.random() < 0.15) {
            recommendations.push({
                type: 'explore',
                title: '探索新功能',
                action: 'explore',
                reason: '试试新东西',
                priority: 0.3
            });
        }

        // 去重并排序
        const unique = this.deduplicateRecommendations(recommendations);
        const sorted = unique
            .sort((a, b) => b.priority - a.priority)
            .slice(0, limit);

        return sorted;
    }

    /**
     * 基于时间的推荐
     */
    getTimeBasedRecommendations(hour, dayOfWeek) {
        const recommendations = [];

        // 早晨 (6-9点)
        if (hour >= 6 && hour < 9) {
            recommendations.push({
                type: 'time',
                title: '早安！喝水时间',
                action: 'drink_water',
                reason: '早上喝水有益健康',
                priority: 0.8
            });
            recommendations.push({
                type: 'time',
                title: '查看今日日程',
                action: 'check_schedule',
                reason: '新的一天，规划一下',
                priority: 0.7
            });
        }

        // 上班时间 (9-12点)
        if (hour >= 9 && hour < 12) {
            recommendations.push({
                type: 'time',
                title: '工作提醒',
                action: 'work_focus',
                reason: '工作时间，保持专注',
                priority: 0.6
            });
        }

        // 午餐时间 (12-13点)
        if (hour >= 12 && hour < 13) {
            recommendations.push({
                type: 'time',
                title: '午餐时间到了',
                action: 'lunch',
                reason: '该吃饭了',
                priority: 0.9
            });
        }

        // 下午 (14-18点)
        if (hour >= 14 && hour < 18) {
            if (hour === 15) {
                recommendations.push({
                    type: 'time',
                    title: '下午休息一下',
                    action: 'break',
                    reason: '工作累了，休息5分钟',
                    priority: 0.7
                });
            }
        }

        // 晚餐 (18-20点)
        if (hour >= 18 && hour < 20) {
            recommendations.push({
                type: 'time',
                title: '晚餐时间',
                action: 'dinner',
                reason: '该吃晚饭了',
                priority: 0.9
            });
        }

        // 晚上 (20-22点)
        if (hour >= 20 && hour < 22) {
            recommendations.push({
                type: 'time',
                title: '放松时间',
                action: 'relax',
                reason: '听听音乐或看部电影',
                priority: 0.7
            });
        }

        // 周末
        if (dayOfWeek === 0 || dayOfWeek === 6) {
            recommendations.push({
                type: 'time',
                title: '周末愉快！',
                action: 'weekend',
                reason: '周末了，好好休息',
                priority: 0.8
            });
        }

        return recommendations;
    }

    /**
     * 基于地点的推荐
     */
    getLocationBasedRecommendations(location) {
        const recommendations = [];

        if (location.includes('公司') || location.includes('work')) {
            recommendations.push({
                type: 'location',
                title: '附近午餐推荐',
                action: 'nearby_lunch',
                reason: '工作时间，查查附近的餐厅',
                priority: 0.8
            });
        }

        if (location.includes('家') || location.includes('home')) {
            recommendations.push({
                type: 'location',
                title: '放松一下',
                action: 'relax_home',
                reason: '到家了，好好休息',
                priority: 0.7
            });
        }

        if (location.includes('商场') || location.includes('mall')) {
            recommendations.push({
                type: 'location',
                title: '购物提醒',
                action: 'shopping',
                reason: '在商场，有需要买的吗？',
                priority: 0.6
            });
        }

        if (location.includes('医院') || location.includes('hospital')) {
            recommendations.push({
                type: 'location',
                title: '健康记录',
                action: 'health_record',
                reason: '医院就诊后，记得记录健康数据',
                priority: 0.9
            });
        }

        return recommendations;
    }

    /**
     * 基于天气的推荐
     */
    getWeatherBasedRecommendations(weather) {
        const recommendations = [];

        if (weather.main && weather.main.temp < 5) {
            // 冷天气
            recommendations.push({
                type: 'weather',
                title: '天冷了，注意保暖',
                action: 'warm_up',
                reason: '气温较低，注意保暖',
                priority: 0.8
            });
        }

        if (weather.weather && weather.weather[0].main === 'Rain') {
            // 下雨
            recommendations.push({
                type: 'weather',
                title: '记得带伞',
                action: 'umbrella',
                reason: '今天有雨，出门带把伞',
                priority: 0.9
            });
        }

        if (weather.weather && weather.weather[0].main === 'Clear') {
            // 晴天
            recommendations.push({
                type: 'weather',
                title: '天气不错，出去走走',
                action: 'walk',
                reason: '天气晴朗，适合户外运动',
                priority: 0.7
            });
        }

        if (weather.main && weather.main.temp > 30) {
            // 高温
            recommendations.push({
                type: 'weather',
                title: '天气炎热，注意防暑',
                action: 'heat_protection',
                reason: '气温较高，多喝水，避免暴晒',
                priority: 0.8
            });
        }

        return recommendations;
    }

    /**
     * 基于日程的推荐
     */
    getScheduleBasedRecommendations(schedule) {
        const recommendations = [];
        const now = moment();
        const oneHourLater = moment().add(1, 'hour');

        // 查找 1 小时内的日程
        const upcomingEvents = schedule.filter(event => {
            const eventTime = moment(event.start);
            return eventTime.isBetween(now, oneHourLater);
        });

        upcomingEvents.forEach(event => {
            recommendations.push({
                type: 'schedule',
                title: `准备：${event.title}`,
                action: 'prepare_event',
                reason: `${event.title} ${moment(event.start).format('HH:mm')} 开始`,
                priority: 0.9,
                eventData: event
            });
        });

        return recommendations;
    }

    /**
     * 基于偏好的推荐
     */
    getPreferenceBasedRecommendations(preferences) {
        const recommendations = [];

        if (preferences.coffee && preferences.coffee.type) {
            recommendations.push({
                type: 'preference',
                title: `${preferences.coffee.type} 时间`,
                action: 'coffee_break',
                reason: `你喜欢 ${preferences.coffee.type}，休息一下`,
                priority: 0.6
            });
        }

        if (preferences.music && preferences.music.genre) {
            recommendations.push({
                type: 'preference',
                title: `${preferences.music.genre} 音乐`,
                action: 'listen_music',
                reason: `听听 ${preferences.music.genre} 放松一下`,
                priority: 0.5
            });
        }

        if (preferences.health && preferences.health.exercise) {
            recommendations.push({
                type: 'preference',
                title: '运动提醒',
                action: 'exercise',
                reason: '该运动了',
                priority: 0.7
            });
        }

        return recommendations;
    }

    /**
     * 获取推荐标题
     */
    getRecommendationTitle(action) {
        const titles = {
            'drink_water': '喝水时间',
            'check_schedule': '查看日程',
            'work_focus': '专注工作',
            'lunch': '午餐时间',
            'dinner': '晚餐时间',
            'break': '休息一下',
            'relax': '放松时间',
            'weekend': '周末愉快'
        };

        return titles[action] || action;
    }

    /**
     * 去重推荐
     */
    deduplicateRecommendations(recommendations) {
        const seen = new Set();
        const unique = [];

        recommendations.forEach(rec => {
            const key = `${rec.type}_${rec.action}`;
            if (!seen.has(key)) {
                seen.add(key);
                unique.push(rec);
            }
        });

        return unique;
    }

    /**
     * 更新用户偏好
     */
    updateUserPreferences(userId, preferences) {
        this.preferences.set(userId, {
            ...this.preferences.get(userId),
            ...preferences
        });

        return { success: true, message: '偏好已更新' };
    }

    /**
     * 获取用户偏好
     */
    getUserPreferences(userId) {
        return this.preferences.get(userId) || {};
    }
}

module.exports = RecommendationEngine;
