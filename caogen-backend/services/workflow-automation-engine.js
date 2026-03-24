/**
 * 工作流自动化引擎 - Workflow Automation Engine
 * 支持场景触发、事件响应、自动化流程
 */

const cron = require('node-cron');
const moment = require('moment');

class WorkflowAutomationEngine {
    constructor() {
        this.workflows = new Map(); // 工作流定义
        this.instances = new Map(); // 工作流实例
        this.triggers = new Map(); // 触发器
        this.conditions = new Map(); // 条件判断
        this.actions = new Map(); // 动作执行
        this.schedules = new Map(); // 定时任务

        // 初始化内置工作流
        this.initializeBuiltinWorkflows();
    }

    /**
     * 初始化内置工作流
     */
    initializeBuiltinWorkflows() {
        // 下班提醒工作流
        this.registerWorkflow({
            id: 'workday_end_reminder',
            name: '下班提醒',
            description: '下班前 30 分钟提醒准备',
            triggers: [
                {
                    type: 'time',
                    expression: '0 30 17 * * 1-5', // 周一到周五 17:30
                    timezone: 'Asia/Shanghai'
                }
            ],
            conditions: [
                {
                    type: 'weekday',
                    days: [1, 2, 3, 4, 5]
                }
            ],
            actions: [
                {
                    type: 'notification',
                    message: '主人，下班时间快到了，整理一下工作准备下班吧！👋'
                },
                {
                    type: 'add_task',
                    title: '下班准备',
                    category: 'work'
                }
            ]
        });

        // 运动提醒工作流
        this.registerWorkflow({
            id: 'exercise_reminder',
            name: '运动提醒',
            description: '晚上 7 点提醒运动',
            triggers: [
                {
                    type: 'time',
                    expression: '0 0 19 * * *', // 每天 19:00
                    timezone: 'Asia/Shanghai'
                }
            ],
            actions: [
                {
                    type: 'notification',
                    message: '主人，该运动了！今天动了吗？💪'
                },
                {
                    type: 'log_health',
                    action: 'exercise_reminded'
                }
            ]
        });

        // 早安问候工作流
        this.registerWorkflow({
            id: 'morning_greeting',
            name: '早安问候',
            description: '早上 7 点自动发送早安问候',
            triggers: [
                {
                    type: 'time',
                    expression: '0 0 7 * * *', // 每天 7:00
                    timezone: 'Asia/Shanghai'
                }
            ],
            conditions: [
                {
                    type: 'weekday',
                    days: [1, 2, 3, 4, 5]
                }
            ],
            actions: [
                {
                    type: 'notification',
                    message: '早安，主人！新的一天开始了，加油！☀️'
                },
                {
                    type: 'get_weather'
                },
                {
                    type: 'get_schedule'
                }
            ]
        });

        // 下雨提醒工作流
        this.registerWorkflow({
            id: 'rain_reminder',
            name: '下雨提醒',
            description: '当检测到下雨时提醒带伞',
            triggers: [
                {
                    type: 'weather',
                    condition: 'rain',
                    threshold: 1
                }
            ],
            actions: [
                {
                    type: 'notification',
                    message: '主人，今天有雨，出门记得带伞！☔'
                },
                {
                    type: 'log_event',
                    event: 'rain_detected'
                }
            ]
        });

        // 收到快递工作流
        this.registerWorkflow({
            id: 'package_received',
            name: '收到快递',
            description: '收到快递时自动记录',
            triggers: [
                {
                    type: 'event',
                    eventType: 'package_received'
                }
            ],
            actions: [
                {
                    type: 'notification',
                    message: '主人，你收到快递了！📦'
                },
                {
                    type: 'log_task',
                    title: '拆快递',
                    category: 'life'
                }
            ]
        });

        // 会议前提醒工作流
        this.registerWorkflow({
            id: 'meeting_reminder',
            name: '会议前提醒',
            description: '会议开始前 15 分钟提醒',
            triggers: [
                {
                    type: 'schedule',
                    offset: -15, // 15分钟前
                    unit: 'minutes'
                }
            ],
            actions: [
                {
                    type: 'notification',
                    message: '主人，会议还有 15 分钟开始，准备好了吗？📅'
                },
                {
                    type: 'log_task',
                    title: '准备会议',
                    category: 'work'
                }
            ]
        });
    }

    /**
     * 注册工作流
     */
    registerWorkflow(workflow) {
        this.workflows.set(workflow.id, workflow);

        // 注册触发器
        workflow.triggers.forEach(trigger => {
            this.registerTrigger(workflow.id, trigger);
        });

        // 启动工作流
        this.startWorkflow(workflow.id);

        return { success: true, workflowId: workflow.id };
    }

    /**
     * 注册触发器
     */
    registerTrigger(workflowId, trigger) {
        switch (trigger.type) {
        case 'time':
            this.registerTimeTrigger(workflowId, trigger);
            break;

        case 'event':
            this.registerEventTrigger(workflowId, trigger);
            break;

        case 'weather':
            this.registerWeatherTrigger(workflowId, trigger);
            break;

        case 'schedule':
            this.registerScheduleTrigger(workflowId, trigger);
            break;

        default:
            console.warn(`未知的触发器类型: ${trigger.type}`);
        }
    }

    /**
     * 注册时间触发器
     */
    registerTimeTrigger(workflowId, trigger) {
        if (!cron.validate(trigger.expression)) {
            console.error(`无效的 cron 表达式: ${trigger.expression}`);
            return;
        }

        const task = cron.schedule(trigger.expression, () => {
            this.executeWorkflow(workflowId);
        }, {
            timezone: trigger.timezone || 'Asia/Shanghai'
        });

        this.schedules.set(workflowId, task);

        console.log(`已注册时间触发器: ${workflowId} - ${trigger.expression}`);
    }

    /**
     * 注册事件触发器
     */
    registerEventTrigger(workflowId, trigger) {
        if (!this.triggers.has('event')) {
            this.triggers.set('event', new Map());
        }

        const eventTriggers = this.triggers.get('event');

        if (!eventTriggers.has(trigger.eventType)) {
            eventTriggers.set(trigger.eventType, []);
        }

        eventTriggers.get(trigger.eventType).push({
            workflowId,
            trigger
        });
    }

    /**
     * 注册天气触发器
     */
    registerWeatherTrigger(workflowId, trigger) {
        if (!this.triggers.has('weather')) {
            this.triggers.set('weather', []);
        }

        this.triggers.get('weather').push({
            workflowId,
            trigger
        });
    }

    /**
     * 注册日程触发器
     */
    registerScheduleTrigger(workflowId, trigger) {
        if (!this.triggers.has('schedule')) {
            this.triggers.set('schedule', []);
        }

        this.triggers.get('schedule').push({
            workflowId,
            trigger
        });
    }

    /**
     * 启动工作流
     */
    startWorkflow(workflowId) {
        const workflow = this.workflows.get(workflowId);

        if (!workflow) {
            console.error(`工作流不存在: ${workflowId}`);
            return;
        }

        console.log(`已启动工作流: ${workflow.name}`);
    }

    /**
     * 执行工作流
     */
    async executeWorkflow(workflowId, context = {}) {
        const workflow = this.workflows.get(workflowId);

        if (!workflow) {
            console.error(`工作流不存在: ${workflowId}`);
            return;
        }

        console.log(`执行工作流: ${workflow.name}`);

        // 检查条件
        if (!this.checkConditions(workflow.conditions, context)) {
            console.log(`工作流条件不满足: ${workflow.name}`);
            return;
        }

        // 执行动作
        for (const action of workflow.actions) {
            await this.executeAction(action, context);
        }

        console.log(`工作流执行完成: ${workflow.name}`);
    }

    /**
     * 检查条件
     */
    checkConditions(conditions, context) {
        if (!conditions || conditions.length === 0) {
            return true;
        }

        return conditions.every(condition => {
            switch (condition.type) {
            case 'weekday':
                const today = moment().day();
                return condition.days.includes(today);

            case 'time_range':
                const now = moment();
                const start = moment(condition.start, 'HH:mm');
                const end = moment(condition.end, 'HH:mm');
                return now.isBetween(start, end);

            case 'custom':
                // 自定义条件
                if (condition.evaluate && typeof condition.evaluate === 'function') {
                    return condition.evaluate(context);
                }
                return true;

            default:
                return true;
            }
        });
    }

    /**
     * 执行动作
     */
    async executeAction(action, context) {
        console.log(`执行动作: ${action.type}`);

        switch (action.type) {
        case 'notification':
            await this.sendNotification(action.message, context);
            break;

        case 'log_event':
            await this.logEvent(action.event, context);
            break;

        case 'log_task':
            await this.logTask(action.title, action.category, context);
            break;

        case 'get_weather':
            await this.getWeather(context);
            break;

        case 'get_schedule':
            await this.getSchedule(context);
            break;

        case 'add_task':
            await this.addTask(action.title, action.category, context);
            break;

        case 'log_health':
            await this.logHealth(action.action, context);
            break;

        case 'send_message':
            await this.sendMessage(action.message, action.target, context);
            break;

        default:
            console.warn(`未知的动作类型: ${action.type}`);
        }
    }

    /**
     * 发送通知
     */
    async sendNotification(message, context) {
        console.log(`📢 发送通知: ${message}`);
        // 实际实现需要集成消息推送服务
    }

    /**
     * 记录事件
     */
    async logEvent(event, context) {
        console.log(`📝 记录事件: ${event}`);
    }

    /**
     * 记录任务
     */
    async logTask(title, category, context) {
        console.log(`📋 记录任务: ${title} (${category})`);
    }

    /**
     * 获取天气
     */
    async getWeather(context) {
        console.log('🌤️ 获取天气信息');
    }

    /**
     * 获取日程
     */
    async getSchedule(context) {
        console.log('📅 获取日程信息');
    }

    /**
     * 添加任务
     */
    async addTask(title, category, context) {
        console.log(`➕ 添加任务: ${title}`);
    }

    /**
     * 记录健康数据
     */
    async logHealth(action, context) {
        console.log(`💊 记录健康数据: ${action}`);
    }

    /**
     * 发送消息
     */
    async sendMessage(message, target, context) {
        console.log(`💬 发送消息到 ${target}: ${message}`);
    }

    /**
     * 触发事件
     */
    async triggerEvent(eventType, data = {}) {
        const eventTriggers = this.triggers.get('event');

        if (!eventTriggers) {
            return;
        }

        const triggers = eventTriggers.get(eventType) || [];

        for (const { workflowId } of triggers) {
            await this.executeWorkflow(workflowId, data);
        }
    }

    /**
     * 触发天气事件
     */
    async triggerWeather(weatherData) {
        const weatherTriggers = this.triggers.get('weather');

        if (!weatherTriggers) {
            return;
        }

        for (const { workflowId, trigger } of weatherTriggers) {
            const shouldTrigger = this.evaluateWeatherTrigger(trigger, weatherData);

            if (shouldTrigger) {
                await this.executeWorkflow(workflowId, weatherData);
            }
        }
    }

    /**
     * 评估天气触发器
     */
    evaluateWeatherTrigger(trigger, weatherData) {
        if (trigger.condition === 'rain') {
            return weatherData.weather &&
                   weatherData.weather[0] &&
                   weatherData.weather[0].main === 'Rain';
        }

        return false;
    }

    /**
     * 触发日程事件
     */
    async triggerSchedule(scheduleData) {
        const scheduleTriggers = this.triggers.get('schedule');

        if (!scheduleTriggers) {
            return;
        }

        for (const { workflowId, trigger } of scheduleTriggers) {
            const shouldTrigger = this.evaluateScheduleTrigger(trigger, scheduleData);

            if (shouldTrigger) {
                await this.executeWorkflow(workflowId, scheduleData);
            }
        }
    }

    /**
     * 评估日程触发器
     */
    evaluateScheduleTrigger(trigger, scheduleData) {
        if (trigger.offset) {
            const now = moment();
            const eventTime = moment(scheduleData.start);
            const diff = eventTime.diff(now, trigger.unit || 'minutes');

            return Math.abs(diff) <= Math.abs(trigger.offset);
        }

        return false;
    }

    /**
     * 停止工作流
     */
    stopWorkflow(workflowId) {
        const schedule = this.schedules.get(workflowId);

        if (schedule) {
            schedule.stop();
            this.schedules.delete(workflowId);
        }

        console.log(`已停止工作流: ${workflowId}`);
    }

    /**
     * 获取工作流列表
     */
    getWorkflows() {
        return Array.from(this.workflows.values());
    }

    /**
     * 获取工作流详情
     */
    getWorkflow(workflowId) {
        return this.workflows.get(workflowId);
    }
}

module.exports = WorkflowAutomationEngine;
