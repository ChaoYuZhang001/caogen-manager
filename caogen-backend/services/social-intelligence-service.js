/**
 * 社交智能服务 - Social Intelligence Service
 * 智能回复、生日提醒、活动推荐
 */

const moment = require('moment');

class SocialIntelligenceService {
    constructor() {
        this.contacts = new Map(); // 联系人
        this.socialEvents = new Map(); // 社交事件
        this.replySuggestions = new Map(); // 回复建议
        this.birthdays = new Map(); // 生日信息
    }

    /**
     * 添加联系人
     */
    addContact(userId, contact) {
        if (!this.contacts.has(userId)) {
            this.contacts.set(userId, new Map());
        }

        const contacts = this.contacts.get(userId);

        contacts.set(contact.id, {
            ...contact,
            createdAt: Date.now(),
            lastInteraction: Date.now()
        });

        return { success: true, message: '联系人已添加' };
    }

    /**
     * 获取联系人
     */
    getContact(userId, contactId) {
        const contacts = this.contacts.get(userId);

        if (!contacts) {
            return null;
        }

        return contacts.get(contactId);
    }

    /**
     * 获取所有联系人
     */
    getContacts(userId) {
        const contacts = this.contacts.get(userId);

        if (!contacts) {
            return [];
        }

        return Array.from(contacts.values());
    }

    /**
     * 生成智能回复
     */
    async generateSmartReply(userId, message, senderId) {
        const sender = this.getContact(userId, senderId);

        if (!sender) {
            return null;
        }

        // 分析消息
        const analysis = await this.analyzeMessage(message);

        // 生成回复建议
        const suggestions = [];

        // 基于消息类型生成回复
        if (analysis.type === 'question') {
            suggestions.push(await this.generateQuestionReply(message, sender));
        } else if (analysis.type === 'invitation') {
            suggestions.push(await this.generateInvitationReply(message, sender));
        } else if (analysis.type === 'complaint') {
            suggestions.push(await this.generateComfortReply(message, sender));
        } else if (analysis.type === 'greeting') {
            suggestions.push(await this.generateGreetingReply(message, sender));
        } else if (analysis.type === 'request') {
            suggestions.push(await this.generateRequestReply(message, sender));
        }

        // 基于关系生成个性化回复
        const personalized = this.generatePersonalizedReply(message, sender);
        suggestions.push(personalized);

        // 去重
        const uniqueSuggestions = [];
        const seen = new Set();

        suggestions.forEach(suggestion => {
            if (suggestion && !seen.has(suggestion.text)) {
                seen.add(suggestion.text);
                uniqueSuggestions.push(suggestion);
            }
        });

        return uniqueSuggestions.slice(0, 5);
    }

    /**
     * 分析消息
     */
    async analyzeMessage(message) {
        const analysis = {
            original: message,
            type: 'chat',
            sentiment: 'neutral',
            keywords: [],
            urgency: 'normal'
        };

        // 检测消息类型
        const questionPatterns = ['?', '吗', '吗', '什么', '怎么', '为什么', '如何'];
        if (questionPatterns.some(p => message.includes(p))) {
            analysis.type = 'question';
        }

        const invitationPatterns = ['周末', '聚餐', '聚会', '出去玩', '电影'];
        if (invitationPatterns.some(p => message.includes(p))) {
            analysis.type = 'invitation';
        }

        const complaintPatterns = ['烦', '难受', '不开心', '生气', '郁闷'];
        if (complaintPatterns.some(p => message.includes(p))) {
            analysis.type = 'complaint';
        }

        const greetingPatterns = ['你好', '早', '晚安', '嗨', 'hello', 'hi'];
        if (greetingPatterns.some(p => message.includes(p))) {
            analysis.type = 'greeting';
        }

        const requestPatterns = ['帮我', '麻烦', '请', '能不能'];
        if (requestPatterns.some(p => message.includes(p))) {
            analysis.type = 'request';
        }

        // 检测情感
        if (analysis.type === 'complaint') {
            analysis.sentiment = 'negative';
        } else if (analysis.type === 'greeting') {
            analysis.sentiment = 'positive';
        }

        // 检测紧急程度
        const urgentPatterns = ['急', '快', '马上', '赶紧', '紧急'];
        if (urgentPatterns.some(p => message.includes(p))) {
            analysis.urgency = 'high';
        }

        return analysis;
    }

    /**
     * 生成问答回复
     */
    async generateQuestionReply(message, sender) {
        return {
            type: 'answer',
            text: `好的，让我想想...`,
            confidence: 0.7
        };
    }

    /**
     * 生成邀请回复
     */
    async generateInvitationReply(message, sender) {
        const suggestions = [
            '好啊！什么时候？',
            '没问题，来吧！',
            '看看时间安排',
            '这个周末有点忙，下次吧'
        ];

        const text = suggestions[Math.floor(Math.random() * suggestions.length)];

        return {
            type: 'acceptance',
            text,
            confidence: 0.8
        };
    }

    /**
     * 生成安慰回复
     */
    async generateComfortReply(message, sender) {
        const suggestions = [
            '别难过，我在呢。',
            '怎么了？和我说说。',
            '没事的，一切都会好的。',
            '别生气，慢慢来。'
        ];

        const text = suggestions[Math.floor(Math.random() * suggestions.length)];

        return {
            type: 'comfort',
            text,
            confidence: 0.9
        };
    }

    /**
     * 生成问候回复
     */
    async generateGreetingReply(message, sender) {
        const hour = new Date().getHours();
        let greeting = '你好！';

        if (hour >= 5 && hour < 12) {
            greeting = '早上好！';
        } else if (hour >= 12 && hour < 18) {
            greeting = '下午好！';
        } else {
            greeting = '晚上好！';
        }

        return {
            type: 'greeting',
            text: `${greeting}${sender.name || '朋友'}！`,
            confidence: 0.9
        };
    }

    /**
     * 生成请求回复
     */
    async generateRequestReply(message, sender) {
        return {
            type: 'response',
            text: '好的，我来帮你处理。',
            confidence: 0.8
        };
    }

    /**
     * 生成个性化回复
     */
    generatePersonalizedReply(message, sender) {
        const personalizedReplies = [];

        // 基于关系类型
        if (sender.relationship === 'close_friend') {
            personalizedReplies.push({
                type: 'casual',
                text: '嗯嗯，我知道了！',
                confidence: 0.9
            });
        } else if (sender.relationship === 'colleague') {
            personalizedReplies.push({
                type: 'formal',
                text: '好的，收到。',
                confidence: 0.9
            });
        } else if (sender.relationship === 'family') {
            personalizedReplies.push({
                type: 'warm',
                text: '好的，亲爱的！',
                confidence: 0.9
            });
        }

        // 基于昵称
        if (sender.nickname) {
            personalizedReplies.push({
                type: 'personal',
                text: `${sender.nickname}，好的！`,
                confidence: 0.9
            });
        }

        return personalizedReplies[0] || null;
    }

    /**
     * 添加生日
     */
    addBirthday(userId, contactId, birthday) {
        if (!this.birthdays.has(userId)) {
            this.birthdays.set(userId, new Map());
        }

        const birthdays = this.birthdays.get(userId);

        birthdays.set(contactId, {
            contactId,
            birthday: moment(birthday).format('MM-DD'),
            year: moment(birthday).format('YYYY'),
            createdAt: Date.now()
        });

        return { success: true, message: '生日已记录' };
    }

    /**
     * 获取即将到来的生日
     */
    getUpcomingBirthdays(userId, days = 7) {
        const birthdays = this.birthdays.get(userId);

        if (!birthdays) {
            return [];
        }

        const upcoming = [];
        const today = moment();

        birthdays.forEach((birthday, contactId) => {
            const thisYearBirthday = moment(`${today.year()}-${birthday.birthday}`, 'YYYY-MM-DD');
            let daysUntil = thisYearBirthday.diff(today, 'days');

            // 如果今年生日已过，计算明年
            if (daysUntil < 0) {
                const nextYearBirthday = moment(`${today.year() + 1}-${birthday.birthday}`, 'YYYY-MM-DD');
                daysUntil = nextYearBirthday.diff(today, 'days');
            }

            if (daysUntil >= 0 && daysUntil <= days) {
                const contact = this.getContact(userId, contactId);

                upcoming.push({
                    contactId,
                    contactName: contact?.name || '未知',
                    birthday: birthday.birthday,
                    age: today.year() - parseInt(birthday.year),
                    daysUntil,
                    isToday: daysUntil === 0
                });
            }
        });

        return upcoming.sort((a, b) => a.daysUntil - b.daysUntil);
    }

    /**
     * 生成生日提醒
     */
    generateBirthdayReminder(userId) {
        const upcoming = this.getUpcomingBirthdays(userId, 7);

        if (upcoming.length === 0) {
            return null;
        }

        const reminders = [];

        upcoming.forEach(birthday => {
            let message = '';

            if (birthday.isToday) {
                message = `今天是 ${birthday.contactName} 的 ${birthday.age} 岁生日，记得送上祝福！🎂`;
            } else if (birthday.daysUntil === 1) {
                message = `明天是 ${birthday.contactName} 的生日，准备一下礼物吧！🎁`;
            } else {
                message = `${birthday.contactName} 还有 ${birthday.daysUntil} 天生日，可以开始准备了。`;
            }

            reminders.push({
                contactId: birthday.contactId,
                contactName: birthday.contactName,
                birthday: birthday.birthday,
                daysUntil: birthday.daysUntil,
                message
            });
        });

        return reminders;
    }

    /**
     * 推荐活动
     */
    async recommendActivities(userId, preferences = {}) {
        const recommendations = [];

        // 获取用户偏好
        const userPreferences = preferences || {
            interests: ['music', 'sports', 'movies'],
            location: '北京',
            budget: 'medium'
        };

        // 音乐活动
        if (userPreferences.interests.includes('music')) {
            recommendations.push({
                type: 'music',
                title: '周末音乐会',
                description: '本周末有精彩的音乐会演出',
                time: '本周六 19:00',
                location: '音乐厅',
                price: '¥100-300',
                recommended: true
            });
        }

        // 体育活动
        if (userPreferences.interests.includes('sports')) {
            recommendations.push({
                type: 'sports',
                title: '周末跑步活动',
                description: '和跑友一起晨跑',
                time: '本周日 7:00',
                location: '奥林匹克公园',
                price: '免费',
                recommended: true
            });
        }

        // 电影活动
        if (userPreferences.interests.includes('movies')) {
            recommendations.push({
                type: 'movies',
                title: '新电影上映',
                description: '最新电影即将上映',
                time: '本周五 20:00',
                location: '电影院',
                price: '¥40-80',
                recommended: false
            });
        }

        // 艺术展览
        if (userPreferences.interests.includes('art')) {
            recommendations.push({
                type: 'art',
                title: '艺术展览',
                description: '当代艺术展',
                time: '本周末',
                location: '美术馆',
                price: '¥50-100',
                recommended: false
            });
        }

        // 根据预算筛选
        const filtered = recommendations.filter(rec => {
            if (userPreferences.budget === 'low') {
                return rec.price === '免费' || rec.price.includes('¥40-');
            } else if (userPreferences.budget === 'medium') {
                return rec.price.includes('¥');
            } else {
                return true;
            }
        });

        return filtered.slice(0, 5);
    }

    /**
     * 记录社交事件
     */
    recordSocialEvent(userId, event) {
        if (!this.socialEvents.has(userId)) {
            this.socialEvents.set(userId, []);
        }

        this.socialEvents.get(userId).push({
            ...event,
            createdAt: Date.now()
        });

        return { success: true, message: '事件已记录' };
    }

    /**
     * 获取社交事件
     */
    getSocialEvents(userId, limit = 10) {
        const events = this.socialEvents.get(userId) || [];

        return events.slice(-limit).reverse();
    }

    /**
     * 社交智能分析
     */
    analyzeSocialActivity(userId) {
        const events = this.socialEvents.get(userId) || [];
        const contacts = this.getContacts(userId);

        const analysis = {
            totalEvents: events.length,
            totalContacts: contacts.length,
            mostActiveContact: null,
            activityTrend: 'stable',
            recommendations: []
        };

        // 找出最活跃的联系人
        const contactActivity = {};

        events.forEach(event => {
            if (event.contactId) {
                contactActivity[event.contactId] = (contactActivity[event.contactId] || 0) + 1;
            }
        });

        let maxActivity = 0;
        Object.entries(contactActivity).forEach(([contactId, count]) => {
            if (count > maxActivity) {
                maxActivity = count;
                analysis.mostActiveContact = this.getContact(userId, contactId);
            }
        });

        // 分析活动趋势
        if (events.length > 0) {
            const lastWeek = events.filter(e =>
                moment(e.createdAt).isAfter(moment().subtract(7, 'days'))
            ).length;

            const weekBefore = events.filter(e =>
                moment(e.createdAt).isBetween(
                    moment().subtract(14, 'days'),
                    moment().subtract(7, 'days')
                )
            ).length;

            if (lastWeek > weekBefore * 1.5) {
                analysis.activityTrend = 'increasing';
            } else if (lastWeek < weekBefore * 0.5) {
                analysis.activityTrend = 'decreasing';
            }
        }

        // 生成建议
        if (analysis.activityTrend === 'decreasing') {
            analysis.recommendations.push({
                type: 'social',
                message: '最近社交活动减少了，约朋友聚聚吧！'
            });
        }

        if (contacts.length < 5) {
            analysis.recommendations.push({
                type: 'social',
                message: '联系人较少，可以多认识一些新朋友！'
            });
        }

        if (analysis.mostActiveContact) {
            analysis.recommendations.push({
                type: 'social',
                message: `和 ${analysis.mostActiveContact.name} 经常互动，关系不错！`
            });
        }

        return analysis;
    }
}

module.exports = SocialIntelligenceService;
