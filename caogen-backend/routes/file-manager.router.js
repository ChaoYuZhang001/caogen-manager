/**
 * 文件管理路由
 */
const express = require('express');
const { FileManager } = require('../file-manager');

const router = express.Router();
const fileManager = new FileManager();

// 上传文件
router.post('/upload', upload.single('file'), async (req, res) => {
    try {
        const userId = req.body.userId || 'default';
        const file = req.file;

        if (!file) {
            return res.status(400).json({
                success: false,
                error: '没有上传文件'
            });
        }

        const metadata = await fileManager.uploadFile(file, userId, {
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
});

// 获取文件列表
router.get('/', async (req, res) => {
    try {
        const userId = req.query.userId || 'default';
        const options = {
            folderId: req.query.folderId,
            page: parseInt(req.query.page) || 1,
            limit: parseInt(req.query.limit) || 20,
            sortBy: req.query.sortBy || 'updatedAt',
            sortOrder: req.query.sortOrder || 'desc'
        };

        const result = fileManager.getUserFiles(userId, options);

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
router.get('/:id', async (req, res) => {
    try {
        const file = fileManager.getFile(req.params.id);

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
router.delete('/:id', async (req, res) => {
    try {
        const userId = req.body.userId || 'default';
        await fileManager.deleteFile(req.params.id, userId);

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

// 更新文件信息
router.put('/:id', async (req, res) => {
    try {
        const userId = req.body.userId || 'default';
        const updates = req.body;

        const file = fileManager.updateFile(
            req.params.id,
            userId,
            updates
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

// 生成分享链接
router.post('/:id/share', async (req, res) => {
    try {
        const userId = req.body.userId || 'default';
        const expiresIn = parseInt(req.body.expiresIn) || 7 * 24 * 60 * 1000;

        const shareInfo = fileManager.generateShareLink(req.params.id, userId, expiresIn);

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
router.get('/share/:token', async (req, res) => {
    try {
        const file = fileManager.getFileByShareToken(req.params.token);

        res.download(file.path, file.originalName);

    } catch (error) {
        res.status(404).json({
            success: false,
            error: error.message
        });
    }
});

// 搜索文件
router.get('/search', async (req, res) => {
    try {
        const userId = req.query.userId || 'default';
        const query = req.query.q || '';

        const results = fileManager.searchFiles(userId, query);

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

// 更新文件信息
router.put('/:id/tags', async (req, res) => {
    try {
        const userId = req.body.userId || 'default';
        const file = fileManager.updateFile(
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

module.exports = router;