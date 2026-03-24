const WebSocket = require('ws');

/**
 * OpenClaw 适配器
 * 负责 OpenClaw Gateway 的 WebSocket 通信
 */
class OpenClawAdapter {
    constructor() {
        this.ws = null;
        this.isConnected = false;
        this.messageQueue = new Map(); // 用于存储等待响应的消息
        this.gatewayUrl = process.env.OPENCLAW_GATEWAY_URL || 'ws://127.0.0.1:5000';
        this.authToken = process.env.OPENCLAW_AUTH_TOKEN || '';
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 5000;
        this.heartbeatInterval = null;
    }

    /**
     * 初始化连接
     */
    async initialize() {
        return new Promise((resolve, reject) => {
            try {
                console.log(`正在连接 OpenClaw Gateway: ${this.gatewayUrl}`);

                this.ws = new WebSocket(`${this.gatewayUrl}/gateway`, {
                    headers: {
                        'Authorization': `Bearer ${this.authToken}`
                    }
                });

                this.ws.on('open', () => {
                    console.log('✅ OpenClaw WebSocket 连接已建立');
                    this.isConnected = true;
                    this.reconnectAttempts = 0;
                    this.startHeartbeat();
                    resolve();
                });

                this.ws.on('message', (data) => {
                    this.handleMessage(data);
                });

                this.ws.on('error', (error) => {
                    console.error('❌ OpenClaw WebSocket 错误:', error.message);
                    if (!this.isConnected) {
                        reject(new Error(`连接失败: ${error.message}`));
                    }
                });

                this.ws.on('close', (code, reason) => {
                    console.log(`OpenClaw WebSocket 连接已关闭: ${code} - ${reason}`);
                    this.isConnected = false;
                    this.stopHeartbeat();

                    if (this.reconnectAttempts < this.maxReconnectAttempts) {
                        this.reconnectAttempts++;
                        console.log(`尝试重新连接 (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);
                        setTimeout(() => this.initialize().catch(console.error), this.reconnectDelay);
                    }
                });

            } catch (error) {
                reject(error);
            }
        });
    }

    /**
     * 断开连接
     */
    disconnect() {
        if (this.ws) {
            this.stopHeartbeat();
            this.ws.close();
            this.ws = null;
            this.isConnected = false;
            console.log('OpenClaw 连接已断开');
        }
    }

    /**
     * 发送消息到 OpenClaw
     */
    sendMessage(message, sessionKey = 'agent:main:main', timeoutSeconds = 30) {
        return new Promise((resolve, reject) => {
            if (!this.isConnected) {
                // 如果未连接，尝试使用 HTTP 回退
                console.log('WebSocket 未连接，尝试 HTTP 回退');
                return this.sendMessageViaHTTP(message, sessionKey, timeoutSeconds)
                    .then(resolve)
                    .catch(reject);
            }

            const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            // 设置超时
            const timeout = setTimeout(() => {
                this.messageQueue.delete(messageId);
                reject(new Error('请求超时'));
            }, timeoutSeconds * 1000);

            // 存储回调
            this.messageQueue.set(messageId, {
                resolve,
                reject,
                timeout
            });

            // 发送消息
            try {
                const payload = {
                    type: 'message',
                    id: messageId,
                    sessionKey,
                    content: message,
                    timestamp: new Date().toISOString()
                };

                this.ws.send(JSON.stringify(payload));
                console.log(`✅ 消息已发送 (${messageId}): ${message}`);

            } catch (error) {
                this.messageQueue.delete(messageId);
                clearTimeout(timeout);
                reject(error);
            }
        });
    }

    /**
     * HTTP 回退方案（如果 WebSocket 不可用）
     */
    async sendMessageViaHTTP(message, sessionKey, timeoutSeconds) {
        // 注意：这需要 OpenClaw Gateway 提供 HTTP API
        // 目前 OpenClaw Gateway 主要是 WebSocket，所以这里是模拟
        // 真实实现需要等待 OpenClaw 提供 HTTP API

        console.log('⚠️  HTTP 回退模式（模拟）');

        // 模拟响应（实际应该调用 OpenClaw HTTP API）
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                resolve({
                    text: `这是对 "${message}" 的模拟回复。需要配置真实的 OpenClaw HTTP API。`,
                    metadata: {
                        mode: 'http_fallback',
                        timestamp: new Date().toISOString()
                    }
                });
            }, 1000);
        });
    }

    /**
     * 获取会话历史
     */
    async getSessionHistory(sessionKey, limit = 20) {
        // TODO: 实现获取会话历史的逻辑
        // 这需要 OpenClaw 提供相应的 API

        console.log(`获取会话历史: ${sessionKey} (限制: ${limit})`);

        return [];
    }

    /**
     * 处理接收到的消息
     */
    handleMessage(data) {
        try {
            const message = JSON.parse(data.toString());
            console.log(`📥 收到消息:`, message);

            // 处理响应
            if (message.id && this.messageQueue.has(message.id)) {
                const pending = this.messageQueue.get(message.id);
                clearTimeout(pending.timeout);
                this.messageQueue.delete(message.id);

                if (message.error) {
                    pending.reject(new Error(message.error));
                } else {
                    pending.resolve(message.data || message);
                }
            }

        } catch (error) {
            console.error('处理消息失败:', error);
        }
    }

    /**
     * 心跳机制
     */
    startHeartbeat() {
        this.heartbeatInterval = setInterval(() => {
            if (this.isConnected && this.ws.readyState === WebSocket.OPEN) {
                this.ws.ping();
            }
        }, 30000); // 每30秒发送一次心跳
    }

    stopHeartbeat() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
            this.heartbeatInterval = null;
        }
    }

    /**
     * 检查连接状态
     */
    isConnectedState() {
        return this.isConnected && this.ws && this.ws.readyState === WebSocket.OPEN;
    }
}

// 单例模式
let instance = null;

function getInstance() {
    if (!instance) {
        instance = new OpenClawAdapter();
    }
    return instance;
}

module.exports = getInstance();
