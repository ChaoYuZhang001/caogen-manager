/**
 * 智能数据分析服务 - Intelligent Analytics Service
 * 生活报告、消费分析、习惯统计、趋势预测
 */

const moment = require('moment');

class IntelligentAnalyticsService {
    constructor() {
        this.userData = new Map(); // 用户数据
        this.analyticsCache = new Map(); // 分析结果缓存
        this.models = new Map(); // 预测模型
    }

    /**
     * 记录用户数据
     */
    recordData(userId, type, data) {
        const timestamp = Date.now();

        if (!this.userData.has(userId)) {
            this.userData.set(userId, {});
        }

        const user = this.userData.get(userId);

        if (!user[type]) {
            user[type] = [];
        }

        user[type].push({
            ...data,
            timestamp
        });

        // 清除缓存
        this.clearCache(userId);

        return { success: true, message: '数据已记录' };
    }

    /**
     * 生成生活报告
     */
    async generateLifeReport(userId, period = 'week') {
        const user = this.userData.get(userId);

        if (!user) {
            return { error: '用户数据不存在' };
        }

        const report = {
            userId,
            period,
            generatedAt: moment().format('YYYY-MM-DD HH:mm:ss'),
            summary: {},
            details: {},
            insights: [],
            recommendations: []
        };

        // 获取时间范围
        const { startDate, endDate } = this.getDateRange(period);

        // 1. 喝水分析
        const waterData = this.filterByDateRange(user.drink_water || [], startDate, endDate);
        const waterAnalysis = this.analyzeWater(waterData);
        report.details.water = waterAnalysis;

        // 2. 睡眠分析
        const sleepData = this.filterByDateRange(user.sleep || [], startDate, endDate);
        const sleepAnalysis = this.analyzeSleep(sleepData);
        report.details.sleep = sleepAnalysis;

        // 3. 运动分析
        const exerciseData = this.filterByDateRange(user.exercise || [], startDate, endDate);
        const exerciseAnalysis = this.analyzeExercise(exerciseData);
        report.details.exercise = exerciseAnalysis;

        // 4. 体重分析
        const weightData = this.filterByDateRange(user.weight || [], startDate, endDate);
        const weightAnalysis = this.analyzeWeight(weightData);
        report.details.weight = weightAnalysis;

        // 5. 消费分析
        const expenseData = this.filterByDateRange(user.expense || [], startDate, endDate);
        const expenseAnalysis = this.analyzeExpenses(expenseData);
        report.details.expense = expenseAnalysis;

        // 生成汇总
        report.summary = this.generateSummary(report.details);

        // 生成洞察
        report.insights = this.generateInsights(report.details);

        // 生成建议
        report.recommendations = this.generateRecommendations(report.details);

        return report;
    }

    /**
     * 分析喝水数据
     */
    analyzeWater(data) {
        if (data.length === 0) {
            return {
                total: 0,
                average: 0,
                rating: 'N/A',
                message: '暂无数据'
            };
        }

        const total = data.reduce((sum, d) => sum + (d.amount || 0), 0);
        const average = total / data.length;

        let rating = '一般';
        if (average >= 2000) rating = '优秀';
        else if (average >= 1500) rating = '良好';
        else if (average >= 1000) rating = '一般';
        else rating = '需改进';

        return {
            total: Math.round(total),
            average: Math.round(average),
            rating,
            days: data.length,
            message: `${period === 'week' ? '本周' : '本月'}平均每天喝 ${Math.round(average)}ml 水，${rating}`
        };
    }

    /**
     * 分析睡眠数据
     */
    analyzeSleep(data) {
        if (data.length === 0) {
            return {
                averageDuration: 0,
                averageBedtime: 'N/A',
                rating: 'N/A',
                message: '暂无数据'
            };
        }

        const durations = data.map(d => d.duration || 0);
        const totalDuration = durations.reduce((sum, d) => sum + d, 0);
        const averageDuration = totalDuration / durations.length;

        const bedtimes = data.map(d => d.bedtime || 0);
        const totalBedtime = bedtimes.reduce((sum, b) => sum + b, 0);
        const averageBedtime = totalBedtime / bedtimes.length;

        // 评分
        let rating = '一般';
        if (averageDuration >= 7.5 && averageDuration <= 9) rating = '优秀';
        else if (averageDuration >= 6.5) rating = '良好';
        else if (averageDuration >= 6) rating = '一般';
        else rating = '需改进';

        return {
            averageDuration: Math.round(averageDuration * 10) / 10,
            averageBedtime: `${Math.floor(averageBedtime)}:${Math.round((averageBedtime % 1) * 60).toString().padStart(2, '0')}`,
            rating,
            days: data.length,
            message: `平均睡眠 ${Math.round(averageDuration * 10) / 10} 小时，${rating}`
        };
    }

    /**
     * 分析运动数据
     */
    analyzeExercise(data) {
        if (data.length === 0) {
            return {
                totalDays: 0,
                totalMinutes: 0,
                average: 0,
                rating: 'N/A',
                message: '暂无数据'
            };
        }

        const totalDays = data.length;
        const totalMinutes = data.reduce((sum, d) => sum + (d.duration || 0), 0);
        const average = totalMinutes / totalDays;

        let rating = '一般';
        if (average >= 45) rating = '优秀';
        else if (average >= 30) rating = '良好';
        else if (average >= 15) rating = '一般';
        else rating = '需改进';

        return {
            totalDays,
            totalMinutes,
            average: Math.round(average),
            rating,
            message: `${period === 'week' ? '本周' : '本月'}运动 ${totalDays} 天，平均每天 ${Math.round(average)} 分钟，${rating}`
        };
    }

    /**
     * 分析体重数据
     */
    analyzeWeight(data) {
        if (data.length === 0) {
            return {
                current: 'N/A',
                change: 'N/A',
                trend: 'N/A',
                message: '暂无数据'
            };
        }

        const weights = data.map(d => d.weight || 0);
        const current = weights[weights.length - 1];
        const previous = weights[0];
        const change = current - previous;

        let trend = '稳定';
        if (change > 0.5) trend = '上升';
        else if (change < -0.5) trend = '下降';

        return {
            current: Math.round(current * 10) / 10,
            change: Math.round(change * 10) / 10,
            trend,
            message: `当前体重 ${Math.round(current * 10) / 10}kg，较${period === 'week' ? '上周' : '上月'}${trend}`
        };
    }

    /**
     * 分析消费数据
     */
    analyzeExpenses(data) {
        if (data.length === 0) {
            return {
                total: 0,
                average: 0,
                topCategory: 'N/A',
                breakdown: {},
                message: '暂无数据'
            };
        }

        const total = data.reduce((sum, d) => sum + (d.amount || 0), 0);
        const average = total / data.length;

        // 按分类统计
        const categoryTotal = {};
        data.forEach(d => {
            const category = d.category || '其他';
            categoryTotal[category] = (categoryTotal[category] || 0) + (d.amount || 0);
        });

        // 找出最高消费分类
        let topCategory = 'N/A';
        let maxAmount = 0;
        Object.entries(categoryTotal).forEach(([category, amount]) => {
            if (amount > maxAmount) {
                maxAmount = amount;
                topCategory = category;
            }
        });

        return {
            total: Math.round(total),
            average: Math.round(average),
            topCategory,
            breakdown: categoryTotal,
            message: `${period === 'week' ? '本周' : '本月'}消费 ¥${Math.round(total)}，主要消费：${topCategory}`
        };
    }

    /**
     * 生成汇总
     */
    generateSummary(details) {
        const summary = {
            overall: '良好',
            score: 75,
            highlights: []
        };

        let totalScore = 0;
        let count = 0;

        // 喝水评分
        if (details.water && details.water.rating !== 'N/A') {
            const scores = { '优秀': 100, '良好': 80, '一般': 60, '需改进': 40 };
            totalScore += scores[details.water.rating] || 0;
            count++;
            summary.highlights.push(`喝水：${details.water.rating}`);
        }

        // 睡眠评分
        if (details.sleep && details.sleep.rating !== 'N/A') {
            const scores = { '优秀': 100, '良好': 80, '一般': 60, '需改进': 40 };
            totalScore += scores[details.sleep.rating] || 0;
            count++;
            summary.highlights.push(`睡眠：${details.sleep.rating}`);
        }

        // 运动评分
        if (details.exercise && details.exercise.rating !== 'N/A') {
            const scores = { '优秀': 100, '良好': 80, '一般': 60, '需改进': 40 };
            totalScore += scores[details.exercise.rating] || 0;
            count++;
            summary.highlights.push(`运动：${details.exercise.rating}`);
        }

        // 计算总分
        if (count > 0) {
            summary.score = Math.round(totalScore / count);

            if (summary.score >= 90) summary.overall = '优秀';
            else if (summary.score >= 75) summary.overall = '良好';
            else if (summary.score >= 60) summary.overall = '一般';
            else summary.overall = '需改进';
        }

        return summary;
    }

    /**
     * 生成洞察
     */
    generateInsights(details) {
        const insights = [];

        // 喝水洞察
        if (details.water && details.water.average < 1500) {
            insights.push({
                type: 'water',
                level: 'warning',
                message: '饮水量偏低，建议每天至少喝 1500ml 水'
            });
        }

        // 睡眠洞察
        if (details.sleep && (details.sleep.averageDuration < 6 || details.sleep.averageDuration > 9)) {
            insights.push({
                type: 'sleep',
                level: 'warning',
                message: '睡眠时间不理想，建议每天保持 7-8 小时睡眠'
            });
        }

        // 运动洞察
        if (details.exercise && details.exercise.average < 30) {
            insights.push({
                type: 'exercise',
                level: 'info',
                message: '运动量不足，建议每天至少运动 30 分钟'
            });
        }

        // 消费洞察
        if (details.expense && details.expense.topCategory === '餐饮') {
            insights.push({
                type: 'expense',
                level: 'info',
                message: '餐饮消费占比较高，可以适当控制外卖支出'
            });
        }

        return insights;
    }

    /**
     * 生成建议
     */
    generateRecommendations(details) {
        const recommendations = [];

        // 喝水建议
        if (details.water && details.water.average < 1500) {
            recommendations.push({
                type: 'water',
                priority: 'high',
                action: 'drink_water',
                message: '设置喝水提醒，每天至少 8 杯水'
            });
        }

        // 睡眠建议
        if (details.sleep) {
            if (details.sleep.averageBedtime > 24) {
                recommendations.push({
                    type: 'sleep',
                    priority: 'medium',
                    action: 'set_bedtime_reminder',
                    message: '建议提前 30 分钟睡觉'
                });
            }
        }

        // 运动建议
        if (details.exercise && details.exercise.average < 30) {
            recommendations.push({
                type: 'exercise',
                priority: 'medium',
                action: 'set_exercise_goal',
                message: '设定每日 30 分钟运动目标'
            });
        }

        // 消费建议
        if (details.expense && details.expense.total > 3000) {
            recommendations.push({
                type: 'expense',
                priority: 'low',
                action: 'review_expenses',
                message: '本月消费较高，建议回顾支出并制定预算'
            });
        }

        return recommendations;
    }

    /**
     * 趋势预测
     */
    predictTrend(userId, type, days = 7) {
        const user = this.userData.get(userId);

        if (!user || !user[type]) {
            return { error: '数据不足' };
        }

        const data = user[type];

        if (data.length < 5) {
            return { error: '数据不足，至少需要 5 条记录' };
        }

        // 简单线性回归预测
        const values = data.map(d => d.value || d.amount || d.weight || d.duration);
        const timestamps = data.map(d => d.timestamp);

        const trend = this.calculateLinearRegression(timestamps, values);

        // 预测未来数据
        const prediction = trend.slope * (Date.now() + days * 24 * 60 * 60 * 1000) + trend.intercept;

        return {
            trend: trend.slope > 0 ? '上升' : '下降',
            prediction: Math.round(prediction * 100) / 100,
            confidence: 0.7,
            message: `根据当前趋势，${days} 天后预计为 ${Math.round(prediction * 100) / 100}`
        };
    }

    /**
     * 线性回归计算
     */
    calculateLinearRegression(x, y) {
        const n = x.length;
        let sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

        for (let i = 0; i < n; i++) {
            sumX += x[i];
            sumY += y[i];
            sumXY += x[i] * y[i];
            sumXX += x[i] * x[i];
        }

        const slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
        const intercept = (sumY - slope * sumX) / n;

        return { slope, intercept };
    }

    /**
     * 获取时间范围
     */
    getDateRange(period) {
        const now = moment();

        switch (period) {
        case 'day':
            return {
                startDate: now.clone().startOf('day').toDate(),
                endDate: now.clone().endOf('day').toDate()
            };

        case 'week':
            return {
                startDate: now.clone().startOf('week').toDate(),
                endDate: now.clone().endOf('week').toDate()
            };

        case 'month':
            return {
                startDate: now.clone().startOf('month').toDate(),
                endDate: now.clone().endOf('month').toDate()
            };

        default:
            return {
                startDate: now.clone().subtract(7, 'days').toDate(),
                endDate: now.toDate()
            };
        }
    }

    /**
     * 按日期范围筛选数据
     */
    filterByDateRange(data, startDate, endDate) {
        return data.filter(d => {
            const timestamp = d.timestamp;
            return timestamp >= startDate.getTime() && timestamp <= endDate.getTime();
        });
    }

    /**
     * 清除缓存
     */
    clearCache(userId) {
        this.analyticsCache.delete(userId);
    }

    /**
     * 获取用户数据
     */
    getUserData(userId) {
        return this.userData.get(userId) || {};
    }
}

module.exports = IntelligentAnalyticsService;
