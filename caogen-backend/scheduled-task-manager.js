/**
 * 定时任务管理器
 * 支持一次性、周期性、条件性任务
 */

const mongoose = require('mongoose');
const nodeCron = require('node-cron');

// 任务模型
const TaskSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    description: String,
    type: {
        type: String,
        enum: ['once', 'daily', 'weekly', 'monthly', 'custom', 'conditional'],
        default: 'once'
    },
    enabled: {
        type: Boolean,
        default: true
    },
    schedule: {
        executeAt: Date,
        time: String,
        daysOfWeek: [Number],
        dayOfMonth: Number,
        interval: Number,
        condition: {
            type: String,
            rules: Array
        }
    },
    action: {
        type: {
            type: String,
            enum: ['message', 'command', 'plugin', 'webhook'],
            default: 'message'
        },
        payload: mongoose.Schema.Types.Mixed
    },
    notification: {
        title: String,
        body: String,
        sound: String,
        badge: Number
    },
    lastExecutedAt: Date,
    nextExecutionAt: Date,
    executionCount: {
        type: Number,
        default: 0
    },
    failedCount: {
        type: Number,
        default: 0
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// 任务执行历史模型
const TaskExecutionSchema = new mongoose.Schema({
    taskId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Task',
        required: true
    },
    status: {
        type: String,
        enum: ['success', 'failed', 'timeout'],
        required: true
    },
    startTime: {
        type: Date,
        required: true
    },
    endTime: Date,
    duration: Number,
    error: String,
    result: mongoose.Schema.Types.Mixed
}, {
    timestamps: true
});

const Task = mongoose.models.Task || mongoose.model('Task', TaskSchema);
const TaskExecution = mongoose.models.TaskExecution || mongoose.model('TaskExecution', TaskExecutionSchema);

class ScheduledTaskManager {
    static tasks = new Map();
    static cronJobs = new Map();
    static isInitialized = false;

    // 初始化
    static async initialize() {
        if (this.isInitialized) return;

        console.log('初始化定时任务管理器...');

        // 加载数据库中的任务
        try {
            const dbTasks = await Task.find({ enabled: true });
            for (const task of dbTasks) {
                await this.scheduleTask(task);
            }
            console.log(`已加载 ${dbTasks.length} 个定时任务`);
        } catch (error) {
            console.log('数据库未连接，使用内存存储');
        }

        this.isInitialized = true;

        // 添加预设任务
        await this.createDefaultTasks();
    }

    // 停止
    static async stop() {
        console.log('停止定时任务管理器...');
        for (const [taskId, cronJob] of this.cronJobs) {
            cronJob.stop();
        }
        this.cronJobs.clear();
        this.tasks.clear();
    }

    // 创建预设任务
    static async createDefaultTasks() {
        const defaultTasks = [
            {
                name: '早安提醒',
                description: '每天早上发送早安问候',
                type: 'daily',
                schedule: { time: '08:00' },
                action: { type: 'message', payload: { message: '早上好！今天有什么安排吗？' } },
                notification: { title: '早安提醒', body: '早上好！新的一天开始了！' }
            },
            {
                name: '周报提醒',
                description: '每周五提醒写周报',
                type: 'weekly',
                schedule: { time: '17:00', daysOfWeek: [5] },
                action: { type: 'command', payload: { command: 'write-weekly-report' } },
                notification: { title: '周报提醒', body: '周末到了，记得写本周工作总结哦！' }
            }
        ];

        for (const taskData of defaultTasks) {
            const existing = await Task.findOne({ name: taskData.name });
            if (!existing) {
                await this.createTask(taskData);
            }
        }
    }

    // 获取所有任务
    static async getTasks() {
        try {
            return await Task.find().sort({ createdAt: -1 });
        } catch (error) {
            return Array.from(this.tasks.values());
        }
    }

    // 创建任务
    static async createTask(taskData) {
        const task = new Task(taskData);
        task.nextExecutionAt = this.calculateNextExecution(task);

        await task.save();
        this.tasks.set(task._id.toString(), task);

        // 调度任务
        await this.scheduleTask(task);

        console.log(`✅ 创建定时任务: ${task.name}`);
        return task;
    }

    // 更新任务
    static async updateTask(taskId, updates) {
        const task = await Task.findByIdAndUpdate(
            taskId,
            { ...updates, updatedAt: new Date() },
            { new: true }
        );

        if (task) {
            // 重新调度
            this.cronJobs.get(taskId)?.stop();
            this.cronJobs.delete(taskId);
            await this.scheduleTask(task);
        }

        return task;
    }

    // 删除任务
    static async deleteTask(taskId) {
        const cronJob = this.cronJobs.get(taskId);
        if (cronJob) {
            cronJob.stop();
            this.cronJobs.delete(taskId);
        }

        await Task.findByIdAndDelete(taskId);
        this.tasks.delete(taskId);

        console.log(`🗑️ 删除定时任务: ${taskId}`);
    }

    // 调度任务
    static async scheduleTask(task) {
        if (!task.enabled) return;

        const cronExpression = this.getCronExpression(task);
        if (!cronExpression) return;

        try {
            const cronJob = nodeCron.schedule(cronExpression, async () => {
                await this.executeTask(task);
            }, {
                scheduled: true,
                timezone: 'Asia/Shanghai'
            });

            this.cronJobs.set(task._id.toString(), cronJob);
            console.log(`⏰ 已调度任务: ${task.name} (${cronExpression})`);
        } catch (error) {
            console.error(`调度任务失败: ${task.name}`, error);
        }
    }

    // 执行任务
    static async executeTask(task) {
        const startTime = new Date();
        console.log(`\n▶️ 执行任务: ${task.name}`);

        try {
            // 执行动作
            await this.executeAction(task.action);

            // 发送通知
            if (task.notification) {
                await this.sendNotification(task.notification);
            }

            // 更新任务状态
            task.lastExecutedAt = new Date();
            task.executionCount += 1;
            task.nextExecutionAt = this.calculateNextExecution(task);
            await task.save();

            // 记录执行历史
            await this.recordExecution(task, 'success', startTime);

            console.log(`✅ 任务执行成功: ${task.name}`);

        } catch (error) {
            console.error(`❌ 任务执行失败: ${task.name}`, error);

            task.failedCount += 1;
            task.lastExecutedAt = new Date();
            task.nextExecutionAt = this.calculateNextExecution(task);
            await task.save();

            await this.recordExecution(task, 'failed', startTime, error);
        }
    }

    // 执行动作
    static async executeAction(action) {
        switch (action.type) {
            case 'message':
                // 发送消息
                const openclawAdapter = require('./openclaw-adapter');
                await openclawAdapter.sendMessage(action.payload.message);
                break;

            case 'command':
                // 执行命令
                console.log(`执行命令: ${action.payload.command}`);
                break;

            case 'webhook':
                // 调用 Webhook
                const response = await fetch(action.payload.url, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(action.payload.data)
                });
                return await response.json();

            case 'plugin':
                // 调用插件
                console.log(`调用插件: ${action.payload.plugin}`);
                break;

            default:
                console.log(`未知动作类型: ${action.type}`);
        }
    }

    // 发送通知
    static async sendNotification(notification) {
        // TODO: 实现推送通知
        console.log(`📢 发送通知: ${notification.title} - ${notification.body}`);
    }

    // 记录执行历史
    static async recordExecution(task, status, startTime, error = null) {
        try {
            const execution = new TaskExecution({
                taskId: task._id,
                status,
                startTime,
                endTime: new Date(),
                duration: Date.now() - startTime.getTime(),
                error: error?.message,
                result: null
            });
            await execution.save();
        } catch (e) {
            console.error('记录执行历史失败:', e);
        }
    }

    // 计算 Cron 表达式
    static getCronExpression(task) {
        const { schedule, type } = task;

        switch (type) {
            case 'once':
                if (!schedule.executeAt) return null;
                const date = new Date(schedule.executeAt);
                return `${date.getMinutes()} ${date.getHours()} ${date.getDate()} ${date.getMonth() + 1} *`;

            case 'daily':
                if (!schedule.time) return null;
                const [hours, minutes] = schedule.time.split(':');
                return `${minutes} ${hours} * * *`;

            case 'weekly':
                if (!schedule.time || !schedule.daysOfWeek) return null;
                const [h, m] = schedule.time.split(':');
                return `${m} ${h} * * ${schedule.daysOfWeek.join(',')}`;

            case 'monthly':
                if (!schedule.time || !schedule.dayOfMonth) return null;
                const [hh, mm] = schedule.time.split(':');
                return `${mm} ${hh} ${schedule.dayOfMonth} * *`;

            case 'custom':
                if (!schedule.interval) return null;
                // 自定义间隔任务不使用 cron，手动处理
                return null;

            default:
                return null;
        }
    }

    // 计算下次执行时间
    static calculateNextExecution(task) {
        const now = new Date();
        const { schedule, type } = task;

        switch (type) {
            case 'once':
                return schedule.executeAt > now ? schedule.executeAt : null;

            case 'daily':
                if (!schedule.time) return null;
                const [hours, minutes] = schedule.time.split(':').map(Number);
                const next = new Date(now);
                next.setHours(hours, minutes, 0, 0);
                if (next <= now) {
                    next.setDate(next.getDate() + 1);
                }
                return next;

            case 'weekly':
                if (!schedule.time || !schedule.daysOfWeek) return null;
                const [h, m] = schedule.time.split(':').map(Number);
                const nextWeekly = new Date(now);
                nextWeekly.setHours(h, m, 0, 0);

                const currentDay = nextWeekly.getDay();
                const targetDays = schedule.daysOfWeek;

                let daysToAdd = 0;
                for (let i = 0; i < 7; i++) {
                    const checkDay = (currentDay + i) % 7;
                    if (targetDays.includes(checkDay)) {
                        daysToAdd = i;
                        break;
                    }
                }

                if (daysToAdd === 0 && nextWeekly <= now) {
                    for (let i = 1; i <= 7; i++) {
                        const checkDay = (currentDay + i) % 7;
                        if (targetDays.includes(checkDay)) {
                            daysToAdd = i;
                            break;
                        }
                    }
                }

                nextWeekly.setDate(nextWeekly.getDate() + daysToAdd);
                return nextWeekly;

            case 'monthly':
                if (!schedule.time || !schedule.dayOfMonth) return null;
                const [hh, mm] = schedule.time.split(':').map(Number);
                const nextMonthly = new Date(now);
                nextMonthly.setDate(schedule.dayOfMonth);
                nextMonthly.setHours(hh, mm, 0, 0);
                if (nextMonthly <= now) {
                    nextMonthly.setMonth(nextMonthly.getMonth() + 1);
                }
                return nextMonthly;

            default:
                return null;
        }
    }
}

module.exports = ScheduledTaskManager;
