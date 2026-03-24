# 定时任务系统

## 1. 系统概述

定时任务系统允许用户设置定时提醒、周期性任务和自动化工作流。

## 2. 任务类型

### 2.1 一次性任务
- 指定时间执行一次
- 例如：明天上午 9 点提醒开会

### 2.2 周期性任务
- 每天重复
- 每周重复
- 每月重复
- 自定义周期

### 2.3 条件任务
- 位置触发
- 时间触发
- 事件触发
- 组合条件

## 3. 任务定义

```typescript
interface ScheduledTask {
  id: string;
  name: string;
  description?: string;
  type: 'once' | 'daily' | 'weekly' | 'monthly' | 'custom' | 'conditional';
  enabled: boolean;

  // 执行配置
  schedule: ScheduleConfig;
  action: TaskAction;

  // 通知配置
  notification?: NotificationConfig;

  // 元数据
  createdAt: Date;
  updatedAt: Date;
  lastExecutedAt?: Date;
  nextExecutionAt?: Date;
}

interface ScheduleConfig {
  // 一次性任务
  executeAt?: Date;

  // 周期性任务
  time?: string;        // "09:00"
  daysOfWeek?: number[]; // [0, 1, 2, 3, 4, 5, 6]
  dayOfMonth?: number;   // 1-31
  interval?: number;     // 间隔秒数

  // 条件任务
  condition?: TaskCondition;
}

interface TaskCondition {
  type: 'location' | 'time' | 'event' | 'composite';
  rules: ConditionRule[];
}

interface ConditionRule {
  type: string;
  operator: 'eq' | 'ne' | 'gt' | 'lt' | 'in';
  value: any;
}

interface TaskAction {
  type: 'message' | 'command' | 'plugin' | 'webhook';
  payload: any;
}

interface NotificationConfig {
  title: string;
  body: string;
  sound?: string;
  badge?: number;
  category?: string;
}
```

## 4. 任务管理器

```typescript
class ScheduledTaskManager {
  private tasks: Map<string, ScheduledTask> = new Map();
  private scheduler: NodeSchedule;

  constructor() {
    this.scheduler = new NodeSchedule();
    this.initialize();
  }

  // 初始化
  private initialize() {
    this.loadTasks();
    this.startScheduler();
  }

  // 添加任务
  async addTask(task: ScheduledTask): Promise<void> {
    // 验证任务
    this.validateTask(task);

    // 计算下次执行时间
    task.nextExecutionAt = this.calculateNextExecution(task);

    // 保存任务
    this.tasks.set(task.id, task);
    await this.saveTasks();

    // 调度任务
    this.scheduleTask(task);
  }

  // 更新任务
  async updateTask(taskId: string, updates: Partial<ScheduledTask>): Promise<void> {
    const task = this.tasks.get(taskId);
    if (!task) throw new Error('Task not found');

    // 更新任务
    Object.assign(task, updates, { updatedAt: new Date() });

    // 重新计算执行时间
    task.nextExecutionAt = this.calculateNextExecution(task);

    // 保存
    this.tasks.set(taskId, task);
    await this.saveTasks();

    // 重新调度
    this.rescheduleTask(task);
  }

  // 删除任务
  async deleteTask(taskId: string): Promise<void> {
    this.tasks.delete(taskId);
    this.scheduler.cancelJob(taskId);
    await this.saveTasks();
  }

  // 执行任务
  private async executeTask(task: ScheduledTask): Promise<void> {
    try {
      // 更新执行时间
      task.lastExecutedAt = new Date();
      task.nextExecutionAt = this.calculateNextExecution(task);

      // 执行动作
      await this.executeAction(task.action);

      // 发送通知
      if (task.notification) {
        await this.sendNotification(task.notification);
      }

      // 保存
      await this.saveTasks();

      // 如果是周期性任务，重新调度
      if (task.type !== 'once') {
        this.scheduleTask(task);
      }

    } catch (error) {
      console.error(`Task execution failed: ${task.id}`, error);
      await this.notifyError(task, error);
    }
  }

  // 计算下次执行时间
  private calculateNextExecution(task: ScheduledTask): Date {
    const now = new Date();
    const schedule = task.schedule;

    switch (task.type) {
      case 'once':
        return schedule.executeAt || now;

      case 'daily':
        return this.getNextDailyExecution(now, schedule.time);

      case 'weekly':
        return this.getNextWeeklyExecution(now, schedule.time, schedule.daysOfWeek);

      case 'monthly':
        return this.getNextMonthlyExecution(now, schedule.time, schedule.dayOfMonth);

      case 'custom':
        return this.getNextCustomExecution(now, schedule.interval);

      default:
        return now;
    }
  }

  // 调度任务
  private scheduleTask(task: ScheduledTask): void {
    if (!task.nextExecutionAt) return;

    const job = this.scheduler.scheduleJob(
      task.nextExecutionAt,
      () => this.executeTask(task)
    );

    task.id = job.id;
  }

  // 重新调度任务
  private rescheduleTask(task: ScheduledTask): void {
    this.scheduler.cancelJob(task.id);
    this.scheduleTask(task);
  }
}
```

## 5. 预设任务模板

### 5.1 早安提醒

```typescript
const morningReminderTask: ScheduledTask = {
  id: 'morning-reminder',
  name: '早安提醒',
  type: 'daily',
  enabled: true,
  schedule: {
    time: '08:00',
    daysOfWeek: [1, 2, 3, 4, 5] // 工作日
  },
  action: {
    type: 'message',
    payload: {
      message: '早上好！今天有什么安排吗？'
    }
  },
  notification: {
    title: '早安提醒',
    body: '早上好！今天有什么安排吗？'
  }
};
```

### 5.2 周报提醒

```typescript
const weeklyReportTask: ScheduledTask = {
  id: 'weekly-report',
  name: '周报提醒',
  type: 'weekly',
  enabled: true,
  schedule: {
    time: '17:00',
    daysOfWeek: [5] // 周五
  },
  action: {
    type: 'command',
    payload: {
      command: 'write-weekly-report'
    }
  },
  notification: {
    title: '周报提醒',
    body: '记得写本周工作总结哦！'
  }
};
```

### 5.3 定期备份

```typescript
const backupTask: ScheduledTask = {
  id: 'daily-backup',
  name: '数据备份',
  type: 'daily',
  enabled: true,
  schedule: {
    time: '02:00'
  },
  action: {
    type: 'command',
    payload: {
      command: 'backup-data'
    }
  }
};
```

## 6. 任务界面

### 6.1 任务列表

```typescript
struct ScheduledTaskListView: View {
    @EnvironmentObject var taskManager: ScheduledTaskManager
    @State private var tasks: [ScheduledTask] = []

    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskRowView(task: task)
                    .onTapGesture {
                        // 编辑任务
                    }
            }
            .onDelete { indexSet in
                // 删除任务
            }
        }
        .navigationTitle("定时任务")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { /* 添加任务 */ }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
```

### 6.2 任务编辑

```typescript
struct TaskEditView: View {
    @State private var task: ScheduledTask
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("任务名称", text: $task.name)
                TextField("描述", text: $task.description)
            }

            Section("执行时间") {
                Picker("任务类型", selection: $task.type) {
                    Text("一次性").tag(ScheduledTaskType.once)
                    Text("每天").tag(ScheduledTaskType.daily)
                    Text("每周").tag(ScheduledTaskType.weekly)
                    Text("每月").tag(ScheduledTaskType.monthly)
                }

                if task.type == .daily || task.type == .weekly {
                    DatePicker("时间", selection: $task.executeAt)
                }

                if task.type == .weekly {
                    DaysOfWeekPicker(daysOfWeek: $task.daysOfWeek)
                }
            }

            Section("执行动作") {
                Picker("动作类型", selection: $task.actionType) {
                    Text("发送消息").tag(ActionType.message)
                    Text("执行命令").tag(ActionType.command)
                }

                TextField("动作内容", text: $task.actionPayload)
            }

            Section("通知") {
                Toggle("启用通知", isOn: $task.notificationEnabled)

                if task.notificationEnabled {
                    TextField("通知标题", text: $task.notificationTitle)
                    TextField("通知内容", text: $task.notificationBody)
                }
            }

            Section {
                Button("保存任务") {
                    // 保存逻辑
                    dismiss()
                }
            }
        }
        .navigationTitle("编辑任务")
    }
}
```

## 7. 后台处理

### iOS 后台任务

```swift
// 注册后台任务
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.caogen.scheduled-tasks",
    using: nil
) { task in
    self.handleBackgroundTask(task)
}

// 处理后台任务
func handleBackgroundTask(_ task: BGTask) {
    // 执行定时任务
    taskManager.executePendingTasks()

    // 标记完成
    task.setTaskCompleted(success: true)
}
```

### Node.js 后台任务

```javascript
// 使用 node-cron
const cron = require('node-cron');

// 每天执行
cron.schedule('0 9 * * *', () => {
    // 执行任务
    executeScheduledTasks();
});
```

## 8. 任务统计

- 执行次数
- 成功率
- 平均执行时间
- 失误记录

---

## 总结

定时任务系统让草根管家能够自动化执行各种任务，提升用户体验。
