const express = require('express');
const router = express.Router();
const caobaoService = require('../services/caobao-service');

/**
 * 草包 AI 聊天接口
 * POST /api/caobao/chat
 */
router.post('/chat', async (req, res) => {
    try {
        const { message, sessionId, userId, model, mode } = req.body;

        if (!message) {
            return res.status(400).json({ error: '消息不能为空' });
        }

        const result = await caobaoService.chat(message, {
            sessionId,
            userId,
            model,
            mode
        });

        res.json(result);
    } catch (error) {
        console.error('聊天错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 草包 AI 竞速模式
 * POST /api/caobao/chat/race
 */
router.post('/chat/race', async (req, res) => {
    try {
        const { message, models } = req.body;

        if (!message) {
            return res.status(400).json({ error: '消息不能为空' });
        }

        const result = await caobaoService.chatRace(message, { models });

        res.json(result);
    } catch (error) {
        console.error('竞速模式错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 草包 AI 并行模式
 * POST /api/caobao/chat/parallel
 */
router.post('/chat/parallel', async (req, res) => {
    try {
        const { message, models } = req.body;

        if (!message) {
            return res.status(400).json({ error: '消息不能为空' });
        }

        const result = await caobaoService.chatParallel(message, { models });

        res.json(result);
    } catch (error) {
        console.error('并行模式错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 图片生成
 * POST /api/caobao/image
 */
router.post('/image', async (req, res) => {
    try {
        const { prompt, size, watermark, referenceImage } = req.body;

        if (!prompt) {
            return res.status(400).json({ error: '图片描述不能为空' });
        }

        const result = await caobaoService.generateImage(prompt, {
            size,
            watermark,
            referenceImage
        });

        res.json(result);
    } catch (error) {
        console.error('图片生成错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 图片理解
 * POST /api/caobao/understand
 */
router.post('/understand', async (req, res) => {
    try {
        const { imageUrl, question } = req.body;

        if (!imageUrl) {
            return res.status(400).json({ error: '图片URL不能为空' });
        }

        const result = await caobaoService.understandImage(imageUrl, question);

        res.json(result);
    } catch (error) {
        console.error('图片理解错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * OCR 文字提取
 * POST /api/caobao/ocr
 */
router.post('/ocr', async (req, res) => {
    try {
        const { imageUrl } = req.body;

        if (!imageUrl) {
            return res.status(400).json({ error: '图片URL不能为空' });
        }

        const result = await caobaoService.ocrImage(imageUrl);

        res.json(result);
    } catch (error) {
        console.error('OCR错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 文档解析
 * POST /api/caobao/document/parse
 */
router.post('/document/parse', async (req, res) => {
    try {
        const { fileUrl, extractType } = req.body;

        if (!fileUrl) {
            return res.status(400).json({ error: '文档URL不能为空' });
        }

        const result = await caobaoService.parseDocument(fileUrl, extractType);

        res.json(result);
    } catch (error) {
        console.error('文档解析错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 语音合成 (TTS)
 * POST /api/caobao/tts
 */
router.post('/tts', async (req, res) => {
    try {
        const { text, voice, speed } = req.body;

        if (!text) {
            return res.status(400).json({ error: '文本不能为空' });
        }

        const result = await caobaoService.textToSpeech(text, { voice, speed });

        res.json(result);
    } catch (error) {
        console.error('TTS错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 语音识别 (ASR)
 * POST /api/caobao/asr
 */
router.post('/asr', async (req, res) => {
    try {
        const { audioUrl } = req.body;

        if (!audioUrl) {
            return res.status(400).json({ error: '音频URL不能为空' });
        }

        const result = await caobaoService.speechToText(audioUrl);

        res.json(result);
    } catch (error) {
        console.error('ASR错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 联网搜索
 * POST /api/caobao/search
 */
router.post('/search', async (req, res) => {
    try {
        const { query, maxResults } = req.body;

        if (!query) {
            return res.status(400).json({ error: '搜索关键词不能为空' });
        }

        const result = await caobaoService.webSearch(query, maxResults);

        res.json(result);
    } catch (error) {
        console.error('搜索错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 获取统计信息
 * GET /api/caobao/stats
 */
router.get('/stats', async (req, res) => {
    try {
        const result = await caobaoService.getStats();
        res.json(result);
    } catch (error) {
        console.error('统计信息错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

/**
 * 健康检查
 * GET /api/caobao/health
 */
router.get('/health', async (req, res) => {
    try {
        const result = await caobaoService.healthCheck();
        res.json(result);
    } catch (error) {
        console.error('健康检查错误:', error);
        res.status(500).json({ error: error.message || '服务器错误' });
    }
});

module.exports = router;
