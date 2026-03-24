const axios = require('axios');

/**
 * 草包 API 服务
 * 调用草包 AI API 提供的能力
 */
class CaobaoService {
    constructor() {
        this.baseURL = process.env.CAOBAO_API_URL || 'http://49.235.213.222';
        this.apiKey = process.env.CAOBAO_API_KEY || 'caobao-1774353104-t1Uz38Jm4FXeTZP9';
        this.client = axios.create({
            baseURL: this.baseURL,
            timeout: 60000,
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.apiKey}`
            }
        });
    }

    /**
     * 智能聊天（默认模式）
     */
    async chat(message, options = {}) {
        try {
            const response = await this.client.post('/v1/chat', {
                message,
                session_id: options.sessionId || null,
                user_id: options.userId || null,
                model: options.model || null,
                stream: options.stream || false,
                mode: options.mode || 'smart',
                models: options.models || null
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 聊天失败:', error.message);
            throw error;
        }
    }

    /**
     * 竞速模式 - 多模型并发，返回最快结果
     */
    async chatRace(message, options = {}) {
        try {
            const response = await this.client.post('/v1/chat/race', {
                message,
                session_id: options.sessionId || null,
                user_id: options.userId || null,
                model: options.model || null,
                stream: options.stream || false,
                models: options.models || ['deepseek-chat', 'qwen-turbo']
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 竞速模式失败:', error.message);
            throw error;
        }
    }

    /**
     * 并行模式 - 返回所有模型结果
     */
    async chatParallel(message, options = {}) {
        try {
            const response = await this.client.post('/v1/chat/parallel', {
                message,
                session_id: options.sessionId || null,
                user_id: options.userId || null,
                model: options.model || null,
                stream: options.stream || false,
                models: options.models || ['deepseek-chat', 'qwen-turbo', 'kimi']
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 并行模式失败:', error.message);
            throw error;
        }
    }

    /**
     * 图片生成
     */
    async generateImage(prompt, options = {}) {
        try {
            const response = await this.client.post('/v1/images/generations', {
                prompt,
                size: options.size || '2K',
                watermark: options.watermark || false,
                reference_image: options.referenceImage || null
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 图片生成失败:', error.message);
            throw error;
        }
    }

    /**
     * 图片理解
     */
    async understandImage(imageUrl, question = '请描述这张图片的内容') {
        try {
            const response = await this.client.post('/v1/images/understand', {
                image_url: imageUrl,
                question
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 图片理解失败:', error.message);
            throw error;
        }
    }

    /**
     * OCR 文字提取
     */
    async ocrImage(imageUrl) {
        try {
            const response = await this.client.post('/v1/images/ocr', {
                image_url: imageUrl
            });
            return response.data;
        } catch (error) {
            console.error('草包 API OCR 失败:', error.message);
            throw error;
        }
    }

    /**
     * 文档解析
     */
    async parseDocument(fileUrl, extractType = 'text') {
        try {
            const response = await this.client.post('/v1/documents/parse', {
                file_url: fileUrl,
                extract_type: extractType
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 文档解析失败:', error.message);
            throw error;
        }
    }

    /**
     * 创建 PPT
     */
    async createPPT(title, slides, template = 'default') {
        try {
            const response = await this.client.post('/v1/documents/ppt', {
                title,
                slides,
                template
            });
            return response.data;
        } catch (error) {
            console.error('草包 API PPT 创建失败:', error.message);
            throw error;
        }
    }

    /**
     * 创建 Word 文档
     */
    async createWord(title, content, template = 'default') {
        try {
            const response = await this.client.post('/v1/documents/word', {
                title,
                content,
                template
            });
            return response.data;
        } catch (error) {
            console.error('草包 API Word 创建失败:', error.message);
            throw error;
        }
    }

    /**
     * 创建 Excel
     */
    async createExcel(options = {}) {
        try {
            const response = await this.client.post('/v1/documents/excel', {
                sheet_name: options.sheetName || 'Sheet1',
                headers: options.headers || [],
                data: options.data || []
            });
            return response.data;
        } catch (error) {
            console.error('草包 API Excel 创建失败:', error.message);
            throw error;
        }
    }

    /**
     * 数据分析
     */
    async analyzeData(data, analysisType = 'summary') {
        try {
            const response = await this.client.post('/v1/data/analyze', {
                file_url: data.fileUrl || null,
                data: data.data || null,
                analysis_type: analysisType
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 数据分析失败:', error.message);
            throw error;
        }
    }

    /**
     * 语音合成 (TTS)
     */
    async textToSpeech(text, options = {}) {
        try {
            const response = await this.client.post('/v1/speech/tts', {
                text,
                voice: options.voice || 'zh_female',
                speed: options.speed || 1.0
            });
            return response.data;
        } catch (error) {
            console.error('草包 API TTS 失败:', error.message);
            throw error;
        }
    }

    /**
     * 语音识别 (ASR)
     */
    async speechToText(audioUrl) {
        try {
            const response = await this.client.post('/v1/speech/asr', {
                audio_url: audioUrl
            });
            return response.data;
        } catch (error) {
            console.error('草包 API ASR 失败:', error.message);
            throw error;
        }
    }

    /**
     * 联网搜索
     */
    async webSearch(query, maxResults = 5) {
        try {
            const response = await this.client.post('/v1/search/web', {
                query,
                max_results: maxResults
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 联网搜索失败:', error.message);
            throw error;
        }
    }

    /**
     * 音乐搜索
     */
    async musicSearch(keyword, searchType = 'song') {
        try {
            const response = await this.client.post('/v1/search/music', {
                keyword,
                search_type: searchType
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 音乐搜索失败:', error.message);
            throw error;
        }
    }

    /**
     * 知识库添加
     */
    async addKnowledge(content, title = null, tags = null) {
        try {
            const response = await this.client.post('/v1/knowledge/add', {
                content,
                title,
                tags
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 知识库添加失败:', error.message);
            throw error;
        }
    }

    /**
     * 知识库搜索
     */
    async searchKnowledge(query, topK = 5) {
        try {
            const response = await this.client.post('/v1/knowledge/search', {
                query,
                top_k: topK
            });
            return response.data;
        } catch (error) {
            console.error('草包 API 知识库搜索失败:', error.message);
            throw error;
        }
    }

    /**
     * 获取统计信息
     */
    async getStats() {
        try {
            const response = await this.client.get('/v1/stats');
            return response.data;
        } catch (error) {
            console.error('草包 API 统计信息失败:', error.message);
            throw error;
        }
    }

    /**
     * 健康检查
     */
    async healthCheck() {
        try {
            const response = await this.client.get('/health');
            return response.data;
        } catch (error) {
            console.error('草包 API 健康检查失败:', error.message);
            throw error;
        }
    }
}

module.exports = new CaobaoService();
