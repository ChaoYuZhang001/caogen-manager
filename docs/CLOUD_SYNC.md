# 云同步系统

## 1. 系统概述

云同步系统允许用户在多个设备间同步数据，包括：
- 聊天记录
- 用户设置
- 快捷指令
- 定时任务
- 插件配置

## 2. 同步策略

### 2.1 实时同步
- 即时同步用户操作
- 适合聊天记录、在线状态

### 2.2 定期同步
- 按时间间隔同步
- 适合设置、插件配置

### 2.3 按需同步
- 用户主动触发
- 适合数据恢复

## 3. 数据模型

```typescript
interface SyncData {
  version: number;
  timestamp: Date;
  deviceId: string;
  data: {
    messages?: ChatMessage[];
    settings?: UserSettings;
    quickActions?: QuickAction[];
    scheduledTasks?: ScheduledTask[];
    plugins?: PluginConfig[];
  };
}

interface SyncConfig {
  enabled: boolean;
  syncInterval: number;        // 同步间隔（秒）
  syncOnWiFi: boolean;        // 仅 WiFi 同步
  syncOnCharging: boolean;    // 仅充电时同步
  compressData: boolean;      // 压缩数据
  encryption: boolean;        // 加密数据
}
```

## 4. 同步管理器

```typescript
class SyncManager {
  private config: SyncConfig;
  private syncQueue: SyncData[] = [];
  private isSyncing = false;

  constructor(config: SyncConfig) {
    this.config = config;
    this.initialize();
  }

  // 初始化
  private initialize() {
    // 注册设备
    this.registerDevice();

    // 启动定期同步
    this.startPeriodicSync();

    // 监听网络变化
    this.observeNetworkChanges();
  }

  // 注册设备
  private async registerDevice(): Promise<void> {
    const deviceInfo = {
      id: await this.getDeviceId(),
      name: await this.getDeviceName(),
      type: await this.getDeviceType(),
      osVersion: await this.getOSVersion(),
      lastSeen: new Date()
    };

    await this.api.registerDevice(deviceInfo);
  }

  // 上传数据
  async upload(data: Partial<SyncData>): Promise<void> {
    const syncData: SyncData = {
      version: await this.getCurrentVersion(),
      timestamp: new Date(),
      deviceId: await this.getDeviceId(),
      data
    };

    // 压缩数据
    if (this.config.compressData) {
      syncData.data = await this.compressData(syncData.data);
    }

    // 加密数据
    if (this.config.encryption) {
      syncData.data = await this.encryptData(syncData.data);
    }

    // 添加到队列
    this.syncQueue.push(syncData);

    // 尝试同步
    this.sync();
  }

  // 下载数据
  async download(): Promise<SyncData> {
    const deviceId = await this.getDeviceId();

    // 从服务器获取最新数据
    let serverData = await this.api.getLatestData(deviceId);

    // 解密数据
    if (this.config.encryption) {
      serverData.data = await this.decryptData(serverData.data);
    }

    // 解压数据
    if (this.config.compressData) {
      serverData.data = await this.decompressData(serverData.data);
    }

    return serverData;
  }

  // 同步
  async sync(): Promise<void> {
    if (this.isSyncing) return;

    try {
      this.isSyncing = true;

      // 检查条件
      if (!await this.canSync()) {
        return;
      }

      // 上传本地数据
      while (this.syncQueue.length > 0) {
        const data = this.syncQueue.shift()!;
        await this.api.uploadData(data);
      }

      // 下载远程数据
      const remoteData = await this.download();

      // 合并数据
      await this.mergeData(remoteData);

      // 更新版本
      await this.updateVersion(remoteData.version);

    } catch (error) {
      console.error('Sync failed:', error);
    } finally {
      this.isSyncing = false;
    }
  }

  // 合并数据
  private async mergeData(remoteData: SyncData): Promise<void> {
    const localData = await this.getLocalData();
    const localVersion = localData.version;
    const remoteVersion = remoteData.version;

    // 版本比较
    if (remoteVersion > localVersion) {
      // 远程数据更新，合并到本地
      await this.applyRemoteData(remoteData.data);
    } else if (localVersion > remoteVersion) {
      // 本地数据更新，上传到远程
      await this.upload(localData);
    } else {
      // 版本相同，不处理
    }
  }

  // 检查是否可以同步
  private async canSync(): Promise<boolean> {
    if (!this.config.enabled) return false;

    // 检查网络
    if (this.config.syncOnWiFi && !await this.isOnWiFi()) {
      return false;
    }

    // 检查充电状态
    if (this.config.syncOnCharging && !await this.isCharging()) {
      return false;
    }

    return true;
  }

  // 启动定期同步
  private startPeriodicSync(): void {
    setInterval(() => {
      this.sync();
    }, this.config.syncInterval * 1000);
  }
}
```

## 5. 冲突解决

### 5.1 冲突检测

```typescript
async function detectConflicts(
  localData: any,
  remoteData: any
): Promise<Conflict[]> {
  const conflicts: Conflict[] = [];

  // 检测聊天记录冲突
  for (const localMessage of localData.messages || []) {
    const remoteMessage = remoteData.messages?.find(
      m => m.id === localMessage.id
    );

    if (remoteMessage && remoteMessage.timestamp !== localMessage.timestamp) {
      conflicts.push({
        type: 'message',
        itemId: localMessage.id,
        local: localMessage,
        remote: remoteMessage
      });
    }
  }

  return conflicts;
}
```

### 5.2 冲突解决策略

```typescript
enum ConflictResolution {
  KeepLocal,        // 保留本地
  KeepRemote,       // 保留远程
  KeepLatest,       // 保留最新的
  Manual,           // 手动选择
  Merge             // 合并
}

async function resolveConflict(
  conflict: Conflict,
  strategy: ConflictResolution
): Promise<void> {
  switch (strategy) {
    case ConflictResolution.KeepLocal:
      // 不做操作，保留本地数据
      break;

    case ConflictResolution.KeepRemote:
      // 使用远程数据
      await applyRemoteData(conflict.remote);
      break;

    case ConflictResolution.KeepLatest:
      // 使用最新的数据
      const latest = conflict.local.timestamp > conflict.remote.timestamp
        ? conflict.local
        : conflict.remote;
      await applyData(latest);
      break;

    case ConflictResolution.Manual:
      // 提示用户选择
      await promptUserToResolve(conflict);
      break;

    case ConflictResolution.Merge:
      // 合并数据
      await mergeData(conflict.local, conflict.remote);
      break;
  }
}
```

## 6. iOS 云同步

```swift
import CloudKit

class CloudKitSyncManager {
    private let container = CKContainer(identifier: "iCloud.com.caogen.app")
    private let database: CKDatabase

    init() {
        database = container.privateCloudDatabase
    }

    // 上传数据
    func upload<T: CKRecord>(_ record: T) async throws {
        try await database.save(record)
    }

    // 下载数据
    func download(recordType: String) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        return try await database.records(matching: query).allResults()
    }

    // 同步消息
    func syncMessages() async throws {
        let records = try await download(recordType: "Message")

        for record in records {
            let message = Message(
                id: record.recordID.recordName,
                content: record["content"] as! String,
                isUser: record["isUser"] as! Bool,
                timestamp: record["timestamp"] as! Date
            )

            // 保存到本地
            await MessageStore.shared.save(message)
        }
    }
}
```

## 7. 数据加密

```typescript
// AES-256 加密
async function encryptData(data: any, key: string): Promise<string> {
  const text = JSON.stringify(data);
  const encrypted = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: await crypto.getRandomValues(new Uint8Array(12))
    },
    await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(key),
      { name: 'AES-GCM' },
      false,
      ['encrypt']
    ),
    new TextEncoder().encode(text)
  );

  return btoa(String.fromCharCode(...new Uint8Array(encrypted)));
}

// 数据解密
async function decryptData(encrypted: string, key: string): Promise<any> {
  const data = Uint8Array.from(atob(encrypted), c => c.charCodeAt(0));

  const decrypted = await crypto.subtle.decrypt(
    {
      name: 'AES-GCM',
      iv: data.slice(0, 12)
    },
    await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(key),
      { name: 'AES-GCM' },
      false,
      ['decrypt']
    ),
    data.slice(12)
  );

  return JSON.parse(new TextDecoder().decode(decrypted));
}
```

## 8. 离线模式

```typescript
class OfflineManager {
  private offlineQueue: Operation[] = [];
  private isOnline = true;

  // 添加离线操作
  addOfflineOperation(operation: Operation): void {
    this.offlineQueue.push(operation);
  }

  // 检测网络状态
  observeNetworkStatus(): void {
    window.addEventListener('online', () => {
      this.isOnline = true;
      this.syncOfflineOperations();
    });

    window.addEventListener('offline', () => {
      this.isOnline = false;
    });
  }

  // 同步离线操作
  async syncOfflineOperations(): Promise<void> {
    while (this.offlineQueue.length > 0) {
      const operation = this.offlineQueue.shift()!;

      try {
        await operation.execute();
      } catch (error) {
        console.error('Failed to sync offline operation:', error);
        // 重新加入队列
        this.offlineQueue.push(operation);
      }
    }
  }
}
```

## 9. 同步统计

- 同步频率
- 数据量
- 冲突次数
- 同步成功率
- 平均同步时间

---

## 总结

云同步系统确保用户数据在多设备间保持一致，提供流畅的跨设备体验。
