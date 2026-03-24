/**
 * 智能预测引擎 - Intelligent Prediction Engine
 * 天气预测、路线优化、健康预警
 */

const moment = require('moment');

class IntelligentPredictionEngine {
    constructor() {
        this.predictionModels = new Map(); // 预测模型
        this.historicalData = new Map(); // 历史数据
        this.alerts = new Map(); // 预警信息
    }

    /**
     * 预测天气
     */
    async predictWeather(userId, location, hours = 24) {
        const prediction = {
            userId,
            location,
            predictedAt: moment().format('YYYY-MM-DD HH:mm:ss'),
            forecast: [],
            alerts: []
        };

        // 获取历史天气数据
        const historicalWeather = await this.getHistoricalWeather(location);

        // 基于历史数据预测未来天气
        const forecast = this.generateWeatherForecast(historicalWeather, hours);

        prediction.forecast = forecast;

        // 生成预警
        prediction.alerts = this.generateWeatherAlerts(forecast);

        return prediction;
    }

    /**
     * 获取历史天气数据
     */
    async getHistoricalWeather(location) {
        // 实际应用中调用天气 API 获取历史数据
        // 这里返回模拟数据
        return [
            { date: '2026-03-20', temp: 15, condition: '晴', humidity: 40, wind: 3 },
            { date: '2026-03-21', temp: 17, condition: '多云', humidity: 45, wind: 4 },
            { date: '2026-03-22', temp: 18, condition: '阴', humidity: 50, wind: 5 },
            { date: '2026-03-23', temp: 16, condition: '小雨', humidity: 60, wind: 6 }
        ];
    }

    /**
     * 生成天气预报
     */
    generateWeatherForecast(historical, hours) {
        const forecast = [];
        const now = moment();
        const lastRecord = historical[historical.length - 1];

        // 简单趋势预测
        const tempTrend = this.calculateTempTrend(historical);

        for (let i = 1; i <= hours; i += 3) { // 每 3 小时预测一次
            const forecastTime = now.clone().add(i, 'hours');
            const temp = lastRecord.temp + (tempTrend * i / 3);

            // 预测天气状况
            const condition = this.predictCondition(historical, i);

            forecast.push({
                time: forecastTime.format('HH:mm'),
                date: forecastTime.format('YYYY-MM-DD'),
                temp: Math.round(temp * 10) / 10,
                condition,
                humidity: lastRecord.humidity + Math.random() * 10 - 5,
                wind: lastRecord.wind + Math.random() * 2 - 1
            });
        }

        return forecast;
    }

    /**
     * 计算温度趋势
     */
    calculateTempTrend(historical) {
        if (historical.length < 2) return 0;

        const first = historical[0].temp;
        const last = historical[historical.length - 1].temp;

        return (last - first) / historical.length;
    }

    /**
     * 预测天气状况
     */
    predictCondition(historical, hoursAhead) {
        const conditions = ['晴', '多云', '阴', '小雨', '中雨', '大雨'];
        const lastCondition = historical[historical.length - 1].condition;

        // 简单概率模型
        const transitionProb = {
            '晴': { '晴': 0.4, '多云': 0.3, '阴': 0.2, '小雨': 0.1 },
            '多云': { '晴': 0.2, '多云': 0.4, '阴': 0.3, '小雨': 0.1 },
            '阴': { '多云': 0.3, '阴': 0.4, '小雨': 0.2, '中雨': 0.1 },
            '小雨': { '阴': 0.3, '小雨': 0.4, '中雨': 0.2, '多云': 0.1 },
            '中雨': { '小雨': 0.3, '中雨': 0.4, '大雨': 0.2, '阴': 0.1 },
            '大雨': { '中雨': 0.3, '大雨': 0.4, '小雨': 0.2, '阴': 0.1 }
        };

        let currentCondition = lastCondition;
        const probs = transitionProb[currentCondition] || transitionProb['晴'];

        // 随机选择下一个状况
        const rand = Math.random();
        let cumulative = 0;

        for (const [condition, prob] of Object.entries(probs)) {
            cumulative += prob;
            if (rand <= cumulative) {
                return condition;
            }
        }

        return '多云';
    }

    /**
     * 生成天气预警
     */
    generateWeatherAlerts(forecast) {
        const alerts = [];

        forecast.forEach(item => {
            // 降雨预警
            if (['小雨', '中雨', '大雨'].includes(item.condition)) {
                alerts.push({
                    type: 'rain',
                    level: item.condition === '大雨' ? 'high' : 'medium',
                    time: item.time,
                    message: `${item.time} 有${item.condition}，注意带伞 ☔`
                });
            }

            // 高温预警
            if (item.temp > 35) {
                alerts.push({
                    type: 'heat',
                    level: 'high',
                    time: item.time,
                    message: `${item.time} 气温 ${item.temp}°C，注意防暑 ☀️`
                });
            }

            // 大风预警
            if (item.wind > 8) {
                alerts.push({
                    type: 'wind',
                    level: 'medium',
                    time: item.time,
                    message: `${item.time} 风力 ${item.wind}级，注意安全 💨`
                });
            }

            // 低温预警
            if (item.temp < 0) {
                alerts.push({
                    type: 'cold',
                    level: 'medium',
                    time: item.time,
                    message: `${item.time} 气温 ${item.temp}°C，注意保暖 ❄️`
                });
            }
        });

        // 去重
        const uniqueAlerts = [];
        const seen = new Set();

        alerts.forEach(alert => {
            const key = `${alert.type}_${alert.time}`;
            if (!seen.has(key)) {
                seen.add(key);
                uniqueAlerts.push(alert);
            }
        });

        return uniqueAlerts;
    }

    /**
     * 优化路线
     */
    async optimizeRoute(userId, from, to, options = {}) {
        const optimization = {
            userId,
            from,
            to,
            options,
            routes: [],
            recommended: null
        };

        // 获取多条路线方案
        const routes = await this.getRouteOptions(from, to, options);
        optimization.routes = routes;

        // 评估每条路线
        const evaluatedRoutes = routes.map(route => ({
            ...route,
            score: this.evaluateRoute(route, options)
        }));

        // 推荐最优路线
        optimization.recommended = evaluatedRoutes.reduce((best, current) =>
            current.score > best.score ? current : best
        );

        return optimization;
    }

    /**
     * 获取路线方案
     */
    async getRouteOptions(from, to, options) {
        // 实际应用中调用地图 API 获取路线
        // 这里返回模拟数据
        return [
            {
                id: 1,
                name: '最快路线',
                duration: 30,
                distance: 12,
                traffic: '畅通',
                cost: 0,
                type: 'highway'
            },
            {
                id: 2,
                name: '最短路线',
                duration: 35,
                distance: 10,
                traffic: '一般',
                cost: 0,
                type: 'urban'
            },
            {
                id: 3,
                name: '避开拥堵',
                duration: 40,
                distance: 15,
                traffic: '畅通',
                cost: 0,
                type: 'alternative'
            }
        ];
    }

    /**
     * 评估路线
     */
    evaluateRoute(route, options) {
        let score = 100;

        // 考虑时间
        if (options.prioritizeTime) {
            score -= route.duration * 0.5;
        }

        // 考虑距离
        if (options.prioritizeDistance) {
            score -= route.distance * 0.3;
        }

        // 考虑交通状况
        if (route.traffic === '拥堵') {
            score -= 20;
        } else if (route.traffic === '一般') {
            score -= 10;
        }

        // 考虑费用
        score -= route.cost * 0.1;

        return Math.max(0, score);
    }

    /**
     * 健康预警
     */
    async healthCheck(userId, healthData) {
        const alerts = [];
        const recommendations = [];

        // 血压预警
        if (healthData.bloodPressure) {
            const bpAlerts = this.checkBloodPressure(healthData.bloodPressure);
            alerts.push(...bpAlerts);
        }

        // 血糖预警
        if (healthData.bloodSugar) {
            const bsAlerts = this.checkBloodSugar(healthData.bloodSugar);
            alerts.push(...bsAlerts);
        }

        // 心率预警
        if (healthData.heartRate) {
            const hrAlerts = this.checkHeartRate(healthData.heartRate);
            alerts.push(...hrAlerts);
        }

        // 体重预警
        if (healthData.weight) {
            const weightAlerts = this.checkWeight(healthData.weight, healthData.height);
            alerts.push(...weightAlerts);
        }

        // 睡眠预警
        if (healthData.sleep) {
            const sleepAlerts = this.checkSleep(healthData.sleep);
            alerts.push(...sleepAlerts);
        }

        // 生成建议
        recommendations.push(...this.generateHealthRecommendations(alerts));

        return {
            userId,
            checkedAt: moment().format('YYYY-MM-DD HH:mm:ss'),
            alerts,
            recommendations,
            overallHealth: this.calculateOverallHealth(alerts)
        };
    }

    /**
     * 检查血压
     */
    checkBloodPressure(bloodPressure) {
        const alerts = [];
        const { systolic, diastolic } = bloodPressure;

        if (systolic > 140 || diastolic > 90) {
            alerts.push({
                type: 'blood_pressure',
                level: 'high',
                message: '血压偏高，建议减少盐分摄入，增加运动',
                value: `${systolic}/${diastolic} mmHg`
            });
        } else if (systolic < 90 || diastolic < 60) {
            alerts.push({
                type: 'blood_pressure',
                level: 'medium',
                message: '血压偏低，注意补充营养，适当休息',
                value: `${systolic}/${diastolic} mmHg`
            });
        }

        return alerts;
    }

    /**
     * 检查血糖
     */
    checkBloodSugar(bloodSugar) {
        const alerts = [];

        if (bloodSugar.fasting > 7.0) {
            alerts.push({
                type: 'blood_sugar',
                level: 'high',
                message: '空腹血糖偏高，建议控制饮食，减少糖分摄入',
                value: `${bloodSugar.fasting} mmol/L`
            });
        } else if (bloodSugar.fasting < 3.9) {
            alerts.push({
                type: 'blood_sugar',
                level: 'high',
                message: '空腹血糖偏低，可能存在低血糖风险',
                value: `${bloodSugar.fasting} mmol/L`
            });
        }

        if (bloodSugar.postprandial > 11.1) {
            alerts.push({
                type: 'blood_sugar',
                level: 'high',
                message: '餐后血糖偏高，建议饭后适当运动',
                value: `${bloodSugar.postprandial} mmol/L`
            });
        }

        return alerts;
    }

    /**
     * 检查心率
     */
    checkHeartRate(heartRate) {
        const alerts = [];

        if (heartRate.resting > 100) {
            alerts.push({
                type: 'heart_rate',
                level: 'medium',
                message: '静息心率偏高，建议检查心脏健康',
                value: `${heartRate.resting} bpm`
            });
        } else if (heartRate.resting < 60) {
            alerts.push({
                type: 'heart_rate',
                level: 'low',
                message: '静息心率偏低，可能是运动员或心脏问题',
                value: `${heartRate.resting} bpm`
            });
        }

        if (heartRate.max > 220 - age) {
            alerts.push({
                type: 'heart_rate',
                level: 'high',
                message: '运动心率过高，注意安全',
                value: `${heartRate.max} bpm`
            });
        }

        return alerts;
    }

    /**
     * 检查体重
     */
    checkWeight(weight, height) {
        const alerts = [];

        if (!height) return alerts;

        const heightInMeters = height / 100;
        const bmi = weight / (heightInMeters * heightInMeters);

        if (bmi > 28) {
            alerts.push({
                type: 'weight',
                level: 'medium',
                message: `BMI ${bmi.toFixed(1)}，超重，建议控制饮食，增加运动`,
                value: `${weight}kg`
            });
        } else if (bmi < 18.5) {
            alerts.push({
                type: 'weight',
                level: 'medium',
                message: `BMI ${bmi.toFixed(1)}，偏瘦，建议增加营养摄入`,
                value: `${weight}kg`
            });
        }

        return alerts;
    }

    /**
     * 检查睡眠
     */
    checkSleep(sleep) {
        const alerts = [];

        if (sleep.duration < 6) {
            alerts.push({
                type: 'sleep',
                level: 'medium',
                message: '睡眠时间不足，建议保证 7-8 小时睡眠',
                value: `${sleep.duration} 小时`
            });
        } else if (sleep.duration > 10) {
            alerts.push({
                type: 'sleep',
                level: 'low',
                message: '睡眠时间过长，可能影响精神状态',
                value: `${sleep.duration} 小时`
            });
        }

        if (sleep.bedtime > 24) {
            alerts.push({
                type: 'sleep',
                level: 'low',
                message: '入睡时间较晚，建议提前入睡时间',
                value: `${Math.floor(sleep.bedtime - 24)}:${Math.round((sleep.bedtime % 1) * 60)}`
            });
        }

        return alerts;
    }

    /**
     * 生成健康建议
     */
    generateHealthRecommendations(alerts) {
        const recommendations = [];

        if (alerts.some(a => a.type === 'blood_pressure')) {
            recommendations.push({
                type: 'diet',
                priority: 'high',
                action: 'reduce_salt',
                message: '减少盐分摄入，每天不超过 6g'
            });
        }

        if (alerts.some(a => a.type === 'blood_sugar')) {
            recommendations.push({
                type: 'diet',
                priority: 'high',
                action: 'control_sugar',
                message: '控制糖分摄入，选择低 GI 食物'
            });
        }

        if (alerts.some(a => a.type === 'heart_rate')) {
            recommendations.push({
                type: 'exercise',
                priority: 'medium',
                action: 'cardio',
                message: '增加有氧运动，每周 150 分钟'
            });
        }

        if (alerts.some(a => a.type === 'weight')) {
            recommendations.push({
                type: 'exercise',
                priority: 'high',
                action: 'weight_management',
                message: '制定体重管理计划，每周减重 0.5kg'
            });
        }

        if (alerts.some(a => a.type === 'sleep')) {
            recommendations.push({
                type: 'sleep',
                priority: 'medium',
                action: 'sleep_schedule',
                message: '建立规律的睡眠习惯，固定作息时间'
            });
        }

        return recommendations;
    }

    /**
     * 计算整体健康状况
     */
    calculateOverallHealth(alerts) {
        const highAlerts = alerts.filter(a => a.level === 'high').length;
        const mediumAlerts = alerts.filter(a => a.level === 'medium').length;

        if (highAlerts > 0) {
            return '需要注意';
        } else if (mediumAlerts > 2) {
            return '一般';
        } else {
            return '良好';
        }
    }

    /**
     * 获取预警信息
     */
    getAlerts(userId) {
        return this.alerts.get(userId) || [];
    }

    /**
     * 清除预警
     */
    clearAlerts(userId) {
        this.alerts.delete(userId);
        return { success: true, message: '预警已清除' };
    }
}

module.exports = IntelligentPredictionEngine;
