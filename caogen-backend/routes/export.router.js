/**
 * 数据导出路由
 */
const express = require('express');
const { DataExportService } = require('../data-export-service');

const router = express.Router();
const exportService = new DataExportService();

// 导出用户数据
router.post('/export', async (req, res) => {
    try {
        const { userId, types, format, startDate, endDate } = req.body;

        if (!userId) {
            return res.status(400).json({
                success: false,
                error: '缺少用户 ID'
            });
        }

        const result = await exportService.exportUserData(userId, {
            types,
            format,
            startDate,
            endDate
        });

        res.json({
            success: true,
            data: result
        });

    } catch (error) {
        console.error('导出失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取导出历史
router.get('/history', async (req, res) => {
    try {
        const userId = req.query.userId || 'default';

        const files = exportService.getExportList(userId);

        res.json({
            success: true,
            data: files
        });

    } catch (error) {
        console.error('获取导出历史失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 下载导出文件
router.get('/download/:filename', async (req, res) => {
    try {
        const filePath = require('path').join(
            process.env.EXPORT_DIR || './exports',
            req.params.filename
        ));

        if (!require('fs').existsSync(filePath)) {
            return res.status(404).json({
                success: false,
                error: '文件不存在'
            });
        }

        res.download(filePath);

    } catch (error) {
        console.error('下载失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 删除导出文件
router.delete('/:filename', async (req, res) => {
    try {
        const filePath = require('path').join(
            process.env.EXPORT_DIR || './exports',
            req.params.filename
        ));

        if (!require('fs').existsSync(filePath)) {
            return res.status(404).json({
                success: false,
                error: '文件不存在'
            });
        }

        if (exportService.deleteExportFile(req.params.filename)) {
            res.json({
                success: true,
                message: '文件已删除'
            });
        } else {
            res.status(404).json({
                success: false,
                error: '删除失败'
            });
        }

    } catch (error) {
        console.error('删除失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取支持的格式和数据类型
router.get('/formats', (req, res) => {
    try {
        res.json({
            success: true,
            data: {
                formats: ["json", "csv", "xml", "zip"],
                types: ["messages", "settings", "quickActions", "scheduledTasks", "collections", "health", "voice_memos", "files"]
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;