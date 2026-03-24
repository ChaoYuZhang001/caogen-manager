# 草根管家 - 架构图

## 系统架构图

```mermaid
graph TB
    subgraph 用户层
        iOS[iOS App<br/>SwiftUI]
        Watch[Apple Watch<br/>WatchKit]
        Siri[Siri Shortcuts<br/>Intents]
    end

    subgraph 展示层
        ChatView[聊天界面]
        VoiceView[语音界面]
        WeatherView[天气界面]
        HealthView[健康界面]
        ExpenseView[记账界面]
        HabitView[习惯界面]
    end

    subgraph 业务层
        ChatManager[聊天管理器]
        VoiceManager[语音管理器]
        WeatherManager[天气管理器]
        HealthManager[健康管理器]
        ExpenseManager[记账管理器]
        HabitManager[习惯管理器]
    end

    subgraph 服务层
        AIDialogueEngine[AI对话引擎]
        PredictionEngine[预测引擎]
        RecommendationEngine[推荐引擎]
        WeChatManager[微信集成]
        AlipayManager[支付宝集成]
        DingTalkManager[钉钉集成]
        SecurityManager[安全管理器]
        PermissionManager[权限管理器]
        SiriShortcutsManager[Siri快捷指令]
        WidgetManager[Widget小组件]
        AppleWatchManager[Apple Watch管理]
    end

    subgraph 数据层
        UserDefaults[用户设置]
        Keychain[敏感信息]
        CoreData[本地数据库]
        FileStorage[文件存储]
        CloudStorage[云端存储]
        MemoryCache[内存缓存]
        DiskCache[磁盘缓存]
    end

    subgraph 网络层
        OpenClaw[OpenClaw Gateway<br/>ws://127.0.0.1:5000]
        Caobao[草包助手]
        WeatherAPI[天气API]
        TranslationAPI[翻译API]
        OCRAPI[OCR API]
        Backend[后端服务<br/>Node.js + Express<br/>端口: 3333]
        MongoDB[MongoDB]
    end

    iOS --> ChatView
    iOS --> VoiceView
    iOS --> WeatherView
    iOS --> HealthView
    iOS --> ExpenseView
    iOS --> HabitView

    Watch --> AppleWatchManager
    Siri --> SiriShortcutsManager

    ChatView --> ChatManager
    VoiceView --> VoiceManager
    WeatherView --> WeatherManager
    HealthView --> HealthManager
    ExpenseView --> ExpenseManager
    HabitView --> HabitManager

    ChatManager --> AIDialogueEngine
    WeatherManager --> WeatherAPI
    HealthManager --> RecommendationEngine
    ExpenseManager --> PredictionEngine
    HabitManager --> IntelligentAnalytics

    ChatManager --> WeChatManager
    ExpenseManager --> AlipayManager
    HabitManager --> DingTalkManager

    ChatManager --> SecurityManager
    ChatManager --> PermissionManager
    iOS --> SiriShortcutsManager
    iOS --> WidgetManager

    AIDialogueEngine --> OpenClaw
    OpenClaw --> Caobao
    ChatManager --> Backend
    Backend --> MongoDB
    ChatManager --> CoreData
    ChatManager --> Keychain
    ChatManager --> CloudStorage
    ChatManager --> MemoryCache
    ChatManager --> DiskCache
```

---

## 数据流图

### AI对话流程
```mermaid
sequenceDiagram
    participant U as 用户
    participant V as ChatView
    participant M as ChatManager
    participant O as OpenClaw
    participant C as 草包助手
    participant S as Settings

    U->>V: 输入消息
    V->>M: 发送消息
    M->>S: 获取用户设置
    S-->>M: 返回设置
    M->>O: WebSocket 发送
    O->>C: 转发消息
    C-->>O: 生成回复
    O-->>M: 返回回复
    M->>V: 显示回复
    V-->>U: 显示结果
```

---

## 安全架构图

```mermaid
graph LR
    A[数据] --> B{加密方式}
    B -->|传输| C[HTTPS/TLS]
    B -->|存储| D[AES-256]
    B -->|敏感| E[RSA]
    C --> F[传输层加密]
    D --> G[存储加密]
    E --> H[密钥管理]
    H --> I[Keychain]
    I --> J[密钥轮换<br/>30天]
    F --> K[数据传输]
    G --> L[数据存储]
    J --> M[密钥更新]
```

---

## 权限架构图

```mermaid
graph TB
    A[用户] --> B{角色}
    B -->|访客| C[读权限]
    B -->|用户| D[读+写权限]
    B -->|管理员| E[读+写+删除权限]
    B -->|超级管理员| F[全部权限]

    C --> G[审计日志]
    D --> G
    E --> G
    F --> G

    G --> H[权限申请]
    H --> I{审批}
    I -->|通过| J[授予权限]
    I -->|拒绝| K[拒绝通知]
```

---

## 缓存架构图

```mermaid
graph TB
    A[数据请求] --> B{缓存检查}
    B -->|命中| C[返回缓存]
    B -->|未命中| D[网络请求]
    D --> E[数据响应]
    E --> F[存储缓存]
    F --> G[Memory Cache]
    F --> H[Disk Cache]
    F --> I[Network Cache]
    G --> J[LRU淘汰]
    H --> K[定期清理]
    I --> L[自动过期]
    J --> M[更新缓存]
    K --> M
    L --> M
    M --> C
```

---

## 第三方集成架构

```mermaid
graph TB
    subgraph 草根管家
        iOS[iOS App]
        Backend[后端服务]
    end

    subgraph 微信
        WeChatAPI[微信API]
        WeChatMini[小程序]
    end

    subgraph 支付宝
        AlipayAPI[支付宝API]
        AlipayBill[账单]
    end

    subgraph 钉钉
        DingTalkAPI[钉钉API]
        DingTalkSchedule[日程]
    end

    iOS --> WeChatAPI
    iOS --> AlipayAPI
    iOS --> DingTalkAPI

    WeChatAPI --> WeChatMini
    AlipayAPI --> AlipayBill
    DingTalkAPI --> DingTalkSchedule

    Backend --> WeChatAPI
    Backend --> AlipayAPI
    Backend --> DingTalkAPI
```

---

## 性能优化架构

```mermaid
graph TB
    subgraph 优化前
        A1[启动 3s]
        A2[响应 500ms]
        A3[内存 100MB]
    end

    subgraph 优化后
        B1[启动 1.5s]
        B2[响应 200ms]
        B3[内存 70MB]
    end

    A1 -->|延迟加载| B1
    A2 -->|智能缓存| B2
    A3 -->|内存优化| B3

    B1 --> C[Splash优化<br/>预加载<br/>延迟渲染]
    B2 --> D[预加载管理器<br/>网络优化<br/>列表优化]
    B3 --> E[对象池<br/>弱引用<br/>缓存清理]
```

---

## App生命周期

```mermaid
stateDiagram-v2
    [*] --> 未安装
    未安装 --> 已安装: 下载安装
    已安装 --> 首次启动: 打开App
    首次启动 --> 登录: 用户登录
    登录 --> 主界面: 加载数据
    主界面 --> 后台: 按Home键
    主界面 --> 锁屏: 锁屏
    后台 --> 主界面: 打开App
    锁屏 --> 主界面: 解锁
    主界面 --> 已终止: 杀进程
    已终止 --> [*]
```

---

## 模块依赖关系

```mermaid
graph TB
    A[ChatView] --> B[ChatManager]
    A --> C[VoiceManager]
    A --> D[NotificationManager]

    B --> E[OpenClawAdapter]
    B --> F[SecurityManager]
    B --> G[PermissionManager]

    E --> H[WebSocket]
    H --> I[OpenClaw Gateway]
    I --> J[草包助手]

    D --> K[PushNotificationService]
    K --> L[APNs]

    F --> M[AES-256]
    F --> N[RSA]
    F --> O[Keychain]

    G --> P[Role System]
    G --> Q[Audit Log]
```

---

## 系统部署架构

```mermaid
graph TB
    subgraph 客户端
        A[iOS App]
        B[Apple Watch]
    end

    subgraph 边缘层
        C[CDN]
        D[API Gateway]
    end

    subgraph 应用层
        E[Node.js Backend<br/>端口: 3333]
        F[OpenClaw Gateway<br/>端口: 5000]
    end

    subgraph 数据层
        G[MongoDB]
        H[Redis Cache]
    end

    subgraph AI层
        I[草包助手]
        J[AI Models]
    end

    A --> C
    B --> C
    C --> D
    D --> E
    D --> F
    E --> G
    E --> H
    F --> I
    I --> J
```

---

**主人，这就是草根管家的完整架构图！** 🏗️✨
