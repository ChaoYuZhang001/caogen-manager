const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = parseInt(process.env.PORT) || 3001;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// OpenClaw Gateway 配置
const OPENCLAW_GATEWAY = process.env.OPENCLAW_GATEWAY || 'http://127.0.0.1:5000';
const AUTH_TOKEN = process.env.OPENCLAW_AUTH_TOKEN || 'ad74331f-6a4f-4b99-aeac-2005ee5ea944';
const HOOKS_TOKEN = process.env.OPENCLAW_HOOKS_TOKEN || 'aa11e103-262a-4bb9-97ec-7b47e12704f3';

// 日志中间件
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  console.log('Body:', req.body);
  next();
});

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: '草根管家 Siri 集成服务',
    timestamp: new Date().toISOString()
  });
});

// API 端点：接收消息并转发到 OpenClaw
app.post('/api/chat', async (req, res) => {
  try {
    const { message, sessionKey = 'agent:main:main', timeoutSeconds = 30 } = req.body;

    if (!message) {
      return res.status(400).json({
        error: '缺少必填参数: message',
        code: 'MISSING_MESSAGE'
      });
    }

    console.log(`\n=== 草根管家请求 ===`);
    console.log(`消息: ${message}`);
    console.log(`会话: ${sessionKey}`);
    console.log(`===================\n`);

    // 方法1：通过 OpenClaw Sessions API 发送消息
    // 注意：这需要 OpenClaw Gateway 提供 HTTP API 支持
    // 如果没有，我们可以使用 hooks 或者直接调用

    // 临时方案：模拟返回（实际应该调用 OpenClaw）
    // 这里我们需要实现真正的 OpenClaw 调用

    // 检查 OpenClaw 是否可用
    try {
      // 尝试调用 OpenClaw Gateway
      const response = await axios.post(
        `${OPENCLAW_GATEWAY}/api/v1/sessions/send`,
        {
          sessionKey,
          message,
          timeoutSeconds
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${AUTH_TOKEN}`
          },
          timeout: timeoutSeconds * 1000
        }
      );

      console.log('OpenClaw 响应:', response.data);

      return res.json({
        success: true,
        data: response.data,
        timestamp: new Date().toISOString()
      });

    } catch (gatewayError) {
      console.error('Gateway 错误:', gatewayError.message);

      // 如果 Gateway 不可用，返回友好的错误信息
      return res.status(503).json({
        success: false,
        error: 'OpenClaw Gateway 暂时不可用',
        message: gatewayError.message,
        suggestion: '请检查 OpenClaw Gateway 是否正常运行',
        code: 'GATEWAY_UNAVAILABLE'
      });
    }

  } catch (error) {
    console.error('处理请求失败:', error);
    res.status(500).json({
      success: false,
      error: '服务器内部错误',
      message: error.message,
      code: 'INTERNAL_ERROR'
    });
  }
});

// 批量消息端点
app.post('/api/chat/batch', async (req, res) => {
  try {
    const { messages, sessionKey = 'agent:main:main' } = req.body;

    if (!Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({
        error: 'messages 必须是非空数组',
        code: 'INVALID_MESSAGES'
      });
    }

    const results = [];

    for (const msg of messages) {
      try {
        const response = await axios.post(
          `${OPENCLAW_GATEWAY}/api/v1/sessions/send`,
          {
            sessionKey,
            message: msg,
            timeoutSeconds: 30
          },
          {
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${AUTH_TOKEN}`
            },
            timeout: 30000
          }
        );

        results.push({
          message: msg,
          success: true,
          response: response.data
        });

        // 简单的速率限制
        await new Promise(resolve => setTimeout(resolve, 500));

      } catch (error) {
        results.push({
          message: msg,
          success: false,
          error: error.message
        });
      }
    }

    res.json({
      success: true,
      results,
      total: messages.length,
      successful: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length
    });

  } catch (error) {
    console.error('批量请求失败:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 快捷指令配置端点（返回可导入的快捷指令配置）
app.get('/api/shortcut-config', (req, res) => {
  const config = {
    name: '草根管家',
    description: '通过 Siri 调用草根管家 AI 助手',
    apiUrl: `${req.protocol}://${req.get('host')}/api/chat`,
    voicePhrase: '嘿，草根',
    examples: [
      '帮我写个周报',
      '查询明天的天气',
      '创建一个飞书文档',
      '分析这个数据表格',
      '生成一张赛博朋克风格的图片'
    ],
    version: '1.0.0'
  };

  res.json(config);
});

// 错误处理
app.use((err, req, res, next) => {
  console.error('未捕获的异常:', err);
  res.status(500).json({
    success: false,
    error: '服务器错误',
    message: err.message
  });
});

// 404 处理
app.use((req, res) => {
  res.status(404).json({
    error: '端点不存在',
    code: 'NOT_FOUND',
    path: req.path
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log('\n========================================');
  console.log('  🌾 草根管家 Siri 集成服务启动成功');
  console.log('========================================');
  console.log(`  监听端口: ${PORT}`);
  console.log(`  访问地址: http://localhost:${PORT}`);
  console.log(`  API 端点: http://localhost:${PORT}/api/chat`);
  console.log(`  健康检查: http://localhost:${PORT}/health`);
  console.log('========================================\n');
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('\n收到 SIGTERM 信号，正在关闭服务器...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('\n收到 SIGINT 信号，正在关闭服务器...');
  process.exit(0);
});
