/**
 * 文件管理服务
 * 支持上传、下载、预览、分享文件
 */

const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const { promisify } = require('util');

// 配置上传目录
const UPLOAD_DIR = process.env.UPLOAD_DIR || './uploads';
const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE) || 100 * 1024 * 1024; // 100MB

// 确保上传目录存在
if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

// 文件存储配置
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const userId = req.body.userId || 'default';
        const userDir = path.join(UPLOAD_DIR, userId);

        if (!fs.existsSync(userDir)) {
            fs.mkdirSync(userDir, { recursive: true });
        }

        cb(null, userDir);
    },
    filename: (req, file, cb) => {
        // 生成唯一文件名
        const uniqueSuffix = Date.now() + '-' + crypto.randomBytes(6).toString('hex');
        const ext = path.extname(file.originalname);
        cb(null, uniqueSuffix + ext);
    }
});

// 文件过滤器
const fileFilter = (req, file, cb) => {
    // 允许的文件类型
    const allowedTypes = [
        // 图片
        'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml',
        // 文档
        'application/pdf', 'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        // 音频
        'audio/mpeg', 'audio/wav', 'audio/ogg',
        // 视频
        'video/mp4', 'video/webm',
        // 文本
        'text/plain', 'text/csv', 'text/json',
        // 压缩文件
        'application/zip', 'application/x-rar-compressed', 'application/x-7z-compressed'
    ];

    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error(`不支持的文件类型: ${file.mimetype}`), false);
    }
};

const upload = multer({
    storage,
    limits: {
        fileSize: MAX_FILE_SIZE
    },
    fileFilter
});

// 文件元数据模型
class FileMetadata {
    constructor(data) {
        this.id = data.id || crypto.randomUUID();
        this.filename = data.filename;
        this.originalName = data.originalName;
        this.mimetype = data.mimetype;
        this.size = data.size;
        this.userId = data.userId;
        this.path = data.path;
        this.url = data.url;
        this.thumbnailUrl = data.thumbnailUrl || null;
        this.folderId = data.folderId || null;
        this.tags = data.tags || [];
        this.description = data.description || '';
        this.isPublic = data.isPublic || false;
        this.shareToken = data.shareToken || null;
        this.downloadCount = data.downloadCount || 0;
        this.createdAt = data.createdAt || new Date();
        this.updatedAt = data.updatedAt || new Date();
    }

    toJSON() {
        return {
            id: this.id,
            filename: this.filename,
            originalName: this.originalName,
            mimetype: this.mimetype,
            size: this.size,
            userId: this.userId,
            url: this.url,
            thumbnailUrl: this.thumbnailUrl,
            folderId: this.folderId,
            tags: this.tags,
            description: this.description,
            isPublic: this.isPublic,
            downloadCount: this.downloadCount,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt
        };
    }
}

// 文件管理器
class FileManager {
    static files = new Map(); // id -> FileMetadata

    // 上传文件
    static async uploadFile(file, userId, options = {}) {
        const metadata = new FileMetadata({
            filename: file.filename,
            originalName: file.originalname,
            mimetype: file.mimetype,
            size: file.size,
            userId,
            path: file.path,
            url: `/api/files/download/${file.filename}`,
            folderId: options.folderId,
            tags: options.tags,
            description: options.description,
            isPublic: options.isPublic || false
        });

        // 生成缩略图（图片）
        if (file.mimetype.startsWith('image/')) {
            metadata.thumbnailUrl = `/api/files/thumbnail/${file.filename}`;
        }

        // 保存到存储
        this.files.set(metadata.id, metadata);

        // 如果有数据库，保存到数据库
        // await FileModel.create(metadata.toJSON());

        console.log(`📁 文件上传: ${metadata.originalName} (${metadata.size} bytes)`);

        return metadata;
    }

    // 获取文件
    static getFile(fileId) {
        return this.files.get(fileId);
    }

    // 获取用户文件列表
    static getUserFiles(userId, options = {}) {
        const files = Array.from(this.files.values())
            .filter(f => f.userId === userId);

        // 文件夹过滤
        if (options.folderId !== undefined) {
            files.filter(f => f.folderId === options.folderId);
        }

        // 排序
        if (options.sortBy) {
            files.sort((a, b) => {
                if (options.sortOrder === 'desc') {
                    return b[options.sortBy] - a[options.sortBy];
                }
                return a[options.sortBy] - b[options.sortBy];
            });
        }

        // 分页
        const page = options.page || 1;
        const limit = options.limit || 20;
        const start = (page - 1) * limit;
        const end = start + limit;

        return {
            files: files.slice(start, end),
            total: files.length,
            page,
            limit,
            totalPages: Math.ceil(files.length / limit)
        };
    }

    // 删除文件
    static async deleteFile(fileId, userId) {
        const file = this.files.get(fileId);

        if (!file) {
            throw new Error('文件不存在');
        }

        if (file.userId !== userId) {
            throw new Error('无权删除此文件');
        }

        // 删除物理文件
        try {
            fs.unlinkSync(file.path);
        } catch (e) {
            console.error('删除物理文件失败:', e);
        }

        // 删除元数据
        this.files.delete(fileId);

        console.log(`🗑️ 文件删除: ${file.originalName}`);

        return { success: true };
    }

    // 生成分享链接
    static generateShareLink(fileId, userId, expiresIn = 7 * 24 * 60 * 60 * 1000) {
        const file = this.files.get(fileId);

        if (!file) {
            throw new Error('文件不存在');
        }

        if (file.userId !== userId) {
            throw new Error('无权分享此文件');
        }

        // 生成分享 Token
        const shareToken = crypto.randomBytes(32).toString('hex');
        const expiresAt = new Date(Date.now() + expiresIn);

        file.shareToken = shareToken;
        file.isPublic = true;

        this.files.set(fileId, file);

        return {
            shareToken,
            url: `/api/files/share/${shareToken}`,
            expiresAt
        };
    }

    // 通过分享链接获取文件
    static getFileByShareToken(shareToken) {
        const file = Array.from(this.files.values())
            .find(f => f.shareToken === shareToken);

        if (!file) {
            throw new Error('分享链接无效');
        }

        // 检查是否过期
        // if (file.expiresAt && file.expiresAt < new Date()) {
        //     throw new Error('分享链接已过期');
        // }

        // 增加下载计数
        file.downloadCount++;
        this.files.set(file.id, file);

        return file;
    }

    // 更新文件信息
    static updateFile(fileId, userId, updates) {
        const file = this.files.get(fileId);

        if (!file) {
            throw new Error('文件不存在');
        }

        if (file.userId !== userId) {
            throw new Error('无权修改此文件');
        }

        // 更新字段
        if (updates.tags) file.tags = updates.tags;
        if (updates.description !== undefined) file.description = updates.description;
        if (updates.folderId !== undefined) file.folderId = updates.folderId;
        file.updatedAt = new Date();

        this.files.set(fileId, file);

        return file;
    }

    // 搜索文件
    static searchFiles(userId, query) {
        const files = Array.from(this.files.values())
            .filter(f => f.userId === userId);

        const searchResults = files.filter(f =>
            f.originalName.toLowerCase().includes(query.toLowerCase()) ||
            f.description.toLowerCase().includes(query.toLowerCase()) ||
            f.tags.some(tag => tag.toLowerCase().includes(query.toLowerCase()))
        );

        return searchResults;
    }
}

// API 路由
module.exports = (app) => {
    // 上传文件
    app.post('/api/files/upload',
        upload.single('file'),
        async (req, res) => {
            try {
                if (!req.file) {
                    return res.status(400).json({
                        success: false,
                        error: '没有上传文件'
                    });
                }

                const userId = req.body.userId || 'default';
                const metadata = await FileManager.uploadFile(req.file, userId, {
                    folderId: req.body.folderId,
                    tags: req.body.tags ? JSON.parse(req.body.tags) : [],
                    description: req.body.description,
                    isPublic: req.body.isPublic === 'true'
                });

                res.json({
                    success: true,
                    data: metadata.toJSON()
                });
            } catch (error) {
                res.status(500).json({
                    success: false,
                    error: error.message
                });
            }
        }
    );

    // 获取文件列表
    app.get('/api/files', async (req, res) => {
        try {
            const userId = req.query.userId || 'default';
            const result = FileManager.getUserFiles(userId, {
                folderId: req.query.folderId,
                page: parseInt(req.query.page) || 1,
                limit: parseInt(req.query.limit) || 20,
                sortBy: req.query.sortBy || 'createdAt',
                sortOrder: req.query.sortOrder || 'desc'
            });

            res.json({
                success: true,
                data: result
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 获取文件详情
    app.get('/api/files/:id', async (req, res) => {
        try {
            const file = FileManager.getFile(req.params.id);

            if (!file) {
                return res.status(404).json({
                    success: false,
                    error: '文件不存在'
                });
            }

            res.json({
                success: true,
                data: file.toJSON()
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 删除文件
    app.delete('/api/files/:id', async (req, res) => {
        try {
            const userId = req.body.userId || 'default';
            await FileManager.deleteFile(req.params.id, userId);

            res.json({
                success: true,
                message: '文件删除成功'
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 生成分享链接
    app.post('/api/files/:id/share', async (req, res) => {
        try {
            const userId = req.body.userId || 'default';
            const expiresIn = parseInt(req.body.expiresIn) || 7 * 24 * 60 * 60 * 1000;

            const shareInfo = FileManager.generateShareLink(
                req.params.id,
                userId,
                expiresIn
            );

            res.json({
                success: true,
                data: shareInfo
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 通过分享链接下载
    app.get('/api/files/share/:token', async (req, res) => {
        try {
            const file = FileManager.getFileByShareToken(req.params.token);

            res.download(file.path, file.originalName);
        } catch (error) {
            res.status(404).json({
                success: false,
                error: error.message
            });
        }
    });

    // 更新文件信息
    app.put('/api/files/:id', async (req, res) => {
        try {
            const userId = req.body.userId || 'default';
            const file = FileManager.updateFile(
                req.params.id,
                userId,
                req.body
            );

            res.json({
                success: true,
                data: file.toJSON()
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 搜索文件
    app.get('/api/files/search', async (req, res) => {
        try {
            const userId = req.query.userId || 'default';
            const query = req.query.q;

            if (!query) {
                return res.status(400).json({
                    success: false,
                    error: '缺少搜索关键词'
                });
            }

            const results = FileManager.searchFiles(userId, query);

            res.json({
                success: true,
                data: results.map(f => f.toJSON())
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });
};

module.exports.FileManager = FileManager;
module.exports.upload = upload;
