/**
 * 智能对话服务 - Intelligent Dialogue Service
 * 支持多轮对话、上下文记忆、情感识别、主动关怀
 */

class IntelligentDialogueService {
    constructor() {
        this.conversations = new Map(); // 对话历史
        this.contexts = new Map(); // 对话上下文
        this.userProfiles = new Map(); // 用户画像
        this.dialogueState = new Map(); // 对话状态
        this.userSentiments = new Map(); // 用户情感状态
    }

    /**
     * 处理用户消息
     */
    async processMessage(userId, message, metadata = {}) {
        // 1. 分析情感
        const sentiment = await this.analyzeSentiment(message);

        // 2. 记录对话历史
        this.recordDialogue(userId, {
            role: 'user',
            content: message,
            timestamp: Date.now(),
            sentiment
        });

        // 3. 更新对话上下文
        this.updateContext(userId, metadata);

        // 4. 检测意图
        const intent = await this.detectIntent(message, userId);

        // 5. 生成回复
        const response = await this.generateResponse(userId, message, intent, sentiment);

        // 6. 记录回复
        this.recordDialogue(userId, {
            role: 'assistant',
            content: response,
            timestamp: Date.now()
        });

        // 7. 更新情感状态
        this.updateSentiment(userId, sentiment);

        // 8. 主动关怀检查
        const careResponse = await this.checkCare(userId);

        return {
            response,
            intent,
            sentiment,
            care: careResponse,
            context: this.contexts.get(userId)
        };
    }

    /**
     * 分析情感
     */
    async analyzeSentiment(message) {
        // 简化版情感分析（实际应用可接入 NLP 服务）
        const positiveKeywords = [
            '开心', '高兴', '快乐', '棒', '好', '赞', '喜欢', '不错',
            'thank', 'thanks', 'happy', 'good', 'great', 'awesome',
            '😊', '👍', '❤️', '✨', '🎉'
        ];

        const negativeKeywords = [
            '难过', '伤心', '生气', '烦恼', '郁闷', '痛苦', '糟糕',
            'sad', 'angry', 'bad', 'worst', 'hate',
            '😢', '😭', '😠', '😡', '💔', '😞'
        ];

        const lowerMessage = message.toLowerCase();

        let positiveCount = 0;
        let negativeCount = 0;

        positiveKeywords.forEach(keyword => {
            if (lowerMessage.includes(keyword)) positiveCount++;
        });

        negativeKeywords.forEach(keyword => {
            if (lowerMessage.includes(keyword)) negativeCount++;
        });

        if (positiveCount > negativeCount) {
            return 'positive';
        } else if (negativeCount > positiveCount) {
            return 'negative';
        } else {
            return 'neutral';
        }
    }

    /**
     * 检测意图
     */
    async detectIntent(message, userId) {
        // 获取对话上下文
        const context = this.contexts.get(userId) || {};
        const dialogueHistory = this.conversations.get(userId) || [];

        // 基于关键词的意图检测
        const intents = {
            'query': ['查询', '查', '看', '多少', '怎么样', '天气', '时间', '日期'],
            'action': ['帮', '做', '打开', '搜索', '导航', '翻译', '设置', '创建'],
            'complaint': ['烦恼', '难过', '生气', '不开心', '郁闷', '糟糕', '伤心'],
            'greeting': ['你好', '早上好', '晚上好', '晚安', '嗨', 'hello', 'hi'],
            'gratitude': ['谢谢', '感谢', 'thank', 'thanks'],
            'question': ['怎么', '为什么', '如何', '?', '吗'],
            'reminder': ['提醒', '记得', '别忘了'],
            'recommendation': ['推荐', '建议', '什么好']
        };

        const lowerMessage = message.toLowerCase();

        // 遍历所有意图
        for (const [intent, keywords] of Object.entries(intents)) {
            for (const keyword of keywords) {
                if (lowerMessage.includes(keyword.toLowerCase())) {
                    return {
                        type: intent,
                        confidence: 0.8,
                        matchedKeyword: keyword
                    };
                }
            }
        }

        // 多轮对话意图检测
        if (dialogueHistory.length > 0) {
            const lastMessage = dialogueHistory[dialogueHistory.length - 1];
            if (lastMessage.role === 'assistant') {
                return {
                    type: 'followup',
                    confidence: 0.7,
                    previousIntent: context.lastIntent
                };
            }
        }

        // 默认意图
        return {
            type: 'chat',
            confidence: 0.5
        };
    }

    /**
     * 生成回复
     */
    async generateResponse(userId, message, intent, sentiment) {
        // 获取用户画像
        const userProfile = this.getUserProfile(userId);

        // 根据意图生成不同回复
        switch (intent.type) {
        case 'query':
            return this.generateQueryResponse(message, userProfile);

        case 'action':
            return this.generateActionResponse(message, userProfile);

        case 'complaint':
            return this.generateComfortResponse(message, sentiment, userProfile);

        case 'greeting':
            return this.generateGreetingResponse(userProfile);

        case 'gratitude':
            return this.generateGratitudeResponse(userProfile);

        case 'question':
            return this.generateAnswerResponse(message, userProfile);

        case 'reminder':
            return this.generateReminderResponse(message, userProfile);

        case 'recommendation':
            return this.generateRecommendationResponse(userProfile);

        case 'followup':
            return this.generateFollowupResponse(userId, message, userProfile);

        default:
            return this.generateChatResponse(message, userProfile);
        }
    }

    /**
     * 生成查询回复
     */
    generateQueryResponse(message, userProfile) {
        // 调用 OpenClaw API 处理查询
        return `好的，我来帮你查询：${message}`;
    }

    /**
     * 生成行动回复
     */
    generateActionResponse(message, userProfile) {
        // 执行相应操作
        return `好的，正在为您执行：${message}`;
    }

    /**
     * 生成安慰回复
     */
    generateComfortResponse(message, sentiment, userProfile) {
        const comforts = [
            '别难过，我在你身边，可以和我说说。',
            '没关系，一切都会好起来的。💪',
            '我理解你的感受，慢慢来，不着急。',
            '主人，有什么心事可以告诉我，我帮你分担。❤️'
        ];

        const name = userProfile.nickname || '主人';
        const comfort = comforts[Math.floor(Math.random() * comforts.length)];

        return `${name}，${comfort}`;
    }

    /**
     * 生成问候回复
     */
    generateGreetingResponse(userProfile) {
        const hour = new Date().getHours();
        const name = userProfile.nickname || '主人';

        if (hour >= 5 && hour < 12) {
            return `早上好，${name}！今天有什么计划吗？☀️`;
        } else if (hour >= 12 && hour < 18) {
            return `下午好，${name}！工作辛苦了，需要我帮你做什么吗？☕`;
        } else if (hour >= 18 && hour < 22) {
            return `晚上好，${name}！今天过得怎么样？🌙`;
        } else {
            return `夜深了，${name}！早点休息，晚安~ 💤`;
        }
    }

    /**
     * 生成感谢回复
     */
    generateGratitudeResponse(userProfile) {
        const thanks = [
            '不客气，这是我应该做的！😊',
            '随时为您服务，主人！👍',
            '能帮到你就好！✨',
            '主人客气了，有需要随时叫我！🌾'
        ];

        return thanks[Math.floor(Math.random() * thanks.length)];
    }

    /**
     * 生成问答回复
     */
    generateAnswerResponse(message, userProfile) {
        // 调用 OpenClaw API 生成答案
        return `让我来回答你的问题：${message}`;
    }

    /**
     * 生成提醒回复
     */
    generateReminderResponse(message, userProfile) {
        return `好的，我会记得提醒你这件事的。🔔`;
    }

    /**
     * 生成推荐回复
     */
    generateRecommendationResponse(userProfile) {
        // 调用推荐引擎
        return `根据你的情况，我推荐你试试...`;
    }

    /**
     * 生成多轮对话回复
     */
    generateFollowupResponse(userId, message, userProfile) {
        const context = this.contexts.get(userId) || {};

        if (context.lastIntent === 'query') {
            return `关于这个查询，还有其他想了解的吗？`;
        } else if (context.lastIntent === 'action') {
            return `操作已执行，还有其他需要吗？`;
        } else {
            return `还有其他需要帮助的吗？`;
        }
    }

    /**
     * 生成聊天回复
     */
    generateChatResponse(message, userProfile) {
        // 默认聊天回复
        const chatResponses = [
            `我理解了，"${message}"。还有什么想说的吗？`,
            `好的，我记住了。继续说吧。`,
            `嗯嗯，我在听。`,
            `主人说得对！👍`
        ];

        return chatResponses[Math.floor(Math.random() * chatResponses.length)];
    }

    /**
     * 记录对话
     */
    recordDialogue(userId, message) {
        if (!this.conversations.has(userId)) {
            this.conversations.set(userId, []);
        }

        const history = this.conversations.get(userId);

        // 保留最近 50 条对话
        if (history.length >= 50) {
            history.shift();
        }

        history.push(message);
        this.conversations.set(userId, history);
    }

    /**
     * 更新上下文
     */
    updateContext(userId, metadata) {
        const context = this.contexts.get(userId) || {};

        this.contexts.set(userId, {
            ...context,
            ...metadata,
            lastUpdateTime: Date.now()
        });
    }

    /**
     * 更新情感状态
     */
    updateSentiment(userId, sentiment) {
        if (!this.userSentiments.has(userId)) {
            this.userSentiments.set(userId, []);
        }

        const sentiments = this.userSentiments.get(userId);

        // 保留最近 20 条情感记录
        if (sentiments.length >= 20) {
            sentiments.shift();
        }

        sentiments.push({
            sentiment,
            timestamp: Date.now()
        });

        this.userSentiments.set(userId, sentiments);
    }

    /**
     * 检测主动关怀
     */
    async checkCare(userId) {
        const userProfile = this.getUserProfile(userId);
        const sentiments = this.userSentiments.get(userId) || [];

        // 检测持续负面情感
        if (sentiments.length >= 3) {
            const recentSentiments = sentiments.slice(-3);
            const negativeCount = recentSentiments.filter(s => s.sentiment === 'negative').length;

            if (negativeCount >= 2) {
                return {
                    type: 'emotional_care',
                    message: '主人，最近感觉不太开心？有什么可以帮你的吗？❤️',
                    priority: 'high'
                };
            }
        }

        // 检测长时间未对话（> 24小时）
        const dialogueHistory = this.conversations.get(userId) || [];
        if (dialogueHistory.length > 0) {
            const lastMessage = dialogueHistory[dialogueHistory.length - 1];
            const hoursSinceLast = (Date.now() - lastMessage.timestamp) / (1000 * 60 * 60);

            if (hoursSinceLast > 24) {
                return {
                    type: 'long_term_care',
                    message: `好久不见，主人！今天过得怎么样？☀️`,
                    priority: 'medium'
                };
            }
        }

        return null;
    }

    /**
     * 获取用户画像
     */
    getUserProfile(userId) {
        return this.userProfiles.get(userId) || {
            nickname: '主人',
            preferences: {},
            habits: [],
            createdAt: Date.now()
        };
    }

    /**
     * 更新用户画像
     */
    updateUserProfile(userId, updates) {
        const existing = this.getUserProfile(userId);

        this.userProfiles.set(userId, {
            ...existing,
            ...updates,
            updatedAt: Date.now()
        });

        return this.getUserProfile(userId);
    }

    /**
     * 获取对话历史
     */
    getDialogueHistory(userId, limit = 10) {
        const history = this.conversations.get(userId) || [];

        return history.slice(-limit);
    }

    /**
     * 清除对话历史
     */
    clearDialogueHistory(userId) {
        this.conversations.set(userId, []);

        return { success: true, message: '对话历史已清除' };
    }
}

module.exports = IntelligentDialogueService;
