/**
 * 数据导出服务
 * 支持导出用户数据为多种格式
 */

const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

// 支持的导出格式
const EXPORT_FORMATS = {
    JSON: 'json',
    CSV: 'csv',
    XML: 'xml',
    PDF: 'pdf',
    ZIP: 'zip'
};

// 数据类型
const DATA_TYPES = {
    MESSAGES: 'messages',
    CONTACTS: 'contacts',
    FILES: 'files',
    SETTINGS: 'settings',
    HEALTH: 'health',
    VOICE_MEMOS: 'voice_memos',
    COLLECTIONS: 'collections',
    TASKS: 'tasks',
    ANALYTICS: 'analytics'
};

class DataExportService {
    constructor() {
        this.exportDir = process.env.EXPORT_DIR || './exports';
        this.ensureExportDir();
    }

    // 确保导出目录存在
    ensureExportDir() {
        if (!fs.existsSync(this.exportDir)) {
            fs.mkdirSync(this.exportDir, { recursive: true });
        }
    }

    // 导出用户数据
    async exportUserData(userId, options = {}) {
        const {
            types = Object.values(DATA_TYPES),
            format = EXPORT_FORMATS.JSON,
            startDate,
            endDate
        } = options;

        const exportData = {
            metadata: {
                userId,
                exportDate: new Date().toISOString(),
                version: '1.0',
                format,
                dataTypes: types
            },
            data: {}
        };

        // 收集各类数据
        for (const type of types) {
            exportData.data[type] = await this.getDataByType(type, userId, startDate, endDate);
        }

        // 根据格式导出
        let exportContent;
        let filename;

        switch (format) {
            case EXPORT_FORMATS.JSON:
                exportContent = JSON.stringify(exportData, null, 2);
                filename = `caogen_export_${userId}_${Date.now()}.json`;
                break;

            case EXPORT_FORMATS.CSV:
                exportContent = this.convertToCSV(exportData);
                filename = `caogen_export_${userId}_${Date.now()}.csv`;
                break;

            case EXPORT_FORMATS.XML:
                exportContent = this.convertToXML(exportData);
                filename = `caogen_export_${userId}_${Date.now()}.xml`;
                break;

            case EXPORT_FORMATS.ZIP:
                return await this.createZipExport(exportData, userId);

            default:
                throw new Error(`不支持的导出格式: ${format}`);
        }

        // 保存文件
        const filePath = path.join(this.exportDir, filename);
        fs.writeFileSync(filePath, exportContent, 'utf8');

        return {
            success: true,
            filename,
            filePath,
            size: exportContent.length,
            format,
            downloadUrl: `/api/exports/download/${filename}`
        };
    }

    // 按类型获取数据
    async getDataByType(type, userId, startDate, endDate) {
        // 模拟数据获取（实际需要从数据库查询）
        switch (type) {
            case DATA_TYPES.MESSAGES:
                return this.getMockMessages(userId, startDate, endDate);

            case DATA_TYPES.SETTINGS:
                return this.getMockSettings(userId);

            case DATA_TYPES.HEALTH:
                return this.getMockHealthData(userId, startDate, endDate);

            case DATA_TYPES.COLLECTIONS:
                return this.getMockCollections(userId);

            case DATA_TYPES.FILES:
                return this.getMockFiles(userId);

            case DATA_TYPES.VOICE_MEMOS:
                return this.getMockVoiceMemos(userId);

            case DATA_TYPES.TASKS:
                return this.getMockTasks(userId);

            default:
                return [];
        }
    }

    // 转换为 CSV
    convertToCSV(data) {
        let csv = '';

        for (const [type, records] of Object.entries(data.data)) {
            if (!records || records.length === 0) continue;

            csv += `# ${type}\n`;

            // 获取表头
            if (records.length > 0) {
                const headers = Object.keys(records[0]);
                csv += headers.join(',') + '\n';

                // 添加数据行
                for (const record of records) {
                    const values = headers.map(h => {
                        let value = record[h];
                        if (typeof value === 'object') {
                            value = JSON.stringify(value);
                        }
                        // 处理逗号和换行
                        if (typeof value === 'string') {
                            value = `"${value.replace(/"/g, '""')}"`;
                        }
                        return value || '';
                    });
                    csv += values.join(',') + '\n';
                }
            }

            csv += '\n';
        }

        return csv;
    }

    // 转换为 XML
    convertToXML(data) {
        let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
        xml += '<export>\n';
        xml += '  <metadata>\n';
        xml += `    <userId>${data.metadata.userId}</userId>\n`;
        xml += `    <exportDate>${data.metadata.exportDate}</exportDate>\n`;
        xml += `    <version>${data.metadata.version}</version>\n`;
        xml += '  </metadata>\n';

        for (const [type, records] of Object.entries(data.data)) {
            if (!records || records.length === 0) continue;

            xml += `  <${type}>\n`;
            for (const record of records) {
                xml += '    <record>\n';
                for (const [key, value] of Object.entries(record)) {
                    xml += `      <${key}>${this.escapeXML(value)}</${key}>\n`;
                }
                xml += '    </record>\n';
            }
            xml += `  </${type}>\n`;
        }

        xml += '</export>';
        return xml;
    }

    // XML 转义
    escapeXML(value) {
        if (value === null || value === undefined) return '';
        if (typeof value === 'object') {
            value = JSON.stringify(value);
        }
        return String(value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&apos;');
    }

    // 创建 ZIP 导出
    async createZipExport(data, userId) {
        // 简化实现，实际需要使用 archiver 或 adm-zip
        const jsonData = JSON.stringify(data, null, 2);
        const filename = `caogen_export_${userId}_${Date.now()}.zip`;
        const filePath = path.join(this.exportDir, filename);

        // 实际应该创建 ZIP 文件
        // 这里简化处理，直接保存 JSON
        fs.writeFileSync(filePath.replace('.zip', '.json'), jsonData, 'utf8');

        return {
            success: true,
            filename,
            filePath,
            size: jsonData.length,
            format: 'zip',
            downloadUrl: `/api/exports/download/${filename.replace('.json', '.zip')}`
        };
    }

    // 获取导出文件列表
    getExportList(userId) {
        const files = fs.readdirSync(this.exportDir)
            .filter(f => f.includes(userId))
            .map(f => {
                const filePath = path.join(this.exportDir, f);
                const stats = fs.statSync(filePath);
                return {
                    filename: f,
                    size: stats.size,
                    createdAt: stats.birthtime,
                    downloadUrl: `/api/exports/download/${f}`
                };
            })
            .sort((a, b) => b.createdAt - a.createdAt);

        return files;
    }

    // 删除导出文件
    deleteExportFile(filename) {
        const filePath = path.join(this.exportDir, filename);
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
            return true;
        }
        return false;
    }

    // 模拟数据方法（实际应该从数据库获取）
    getMockMessages(userId, startDate, endDate) {
        return [
            {
                id: 'msg_1',
                content: '你好，草根！',
                isUser: true,
                createdAt: new Date().toISOString()
            },
            {
                id: 'msg_2',
                content: '你好！有什么可以帮你的？',
                isUser: false,
                createdAt: new Date().toISOString()
            }
        ];
    }

    getMockSettings(userId) {
        return {
            theme: 'auto',
            language: 'zh-CN',
            voiceSpeed: 0.5,
            pushEnabled: true
        };
    }

    getMockHealthData(userId, startDate, endDate) {
        return [
            {
                type: 'bloodPressure',
                value: 120,
                secondaryValue: 80,
                unit: 'mmHg',
                createdAt: new Date().toISOString()
            }
        ];
    }

    getMockCollections(userId) {
        return [];
    }

    getMockFiles(userId) {
        return [];
    }

    getMockVoiceMemos(userId) {
        return [];
    }

    getMockTasks(userId) {
        return [];
    }
}

// API 路由
module.exports = (app) => {
    const exportService = new DataExportService();

    // 导出用户数据
    app.post('/api/export', async (req, res) => {
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
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 获取导出历史
    app.get('/api/export/history', async (req, res) => {
        try {
            const { userId } = req.query;

            if (!userId) {
                return res.status(400).json({
                    success: false,
                    error: '缺少用户 ID'
                });
            }

            const files = exportService.getExportList(userId);

            res.json({
                success: true,
                data: files
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 下载导出文件
    app.get('/api/export/download/:filename', async (req, res) => {
        try {
            const { filename } = req.params;
            const filePath = path.join(exportService.exportDir, filename);

            if (!fs.existsSync(filePath)) {
                return res.status(404).json({
                    success: false,
                    error: '文件不存在'
                });
            }

            res.download(filePath, filename);
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 删除导出文件
    app.delete('/api/export/:filename', async (req, res) => {
        try {
            const { filename } = req.params;
            const success = exportService.deleteExportFile(filename);

            if (success) {
                res.json({
                    success: true,
                    message: '文件已删除'
                });
            } else {
                res.status(404).json({
                    success: false,
                    error: '文件不存在'
                });
            }
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 获取支持的导出格式
    app.get('/api/export/formats', (req, res) => {
        res.json({
            success: true,
            data: {
                formats: Object.values(EXPORT_FORMATS),
                types: Object.values(DATA_TYPES)
            }
        });
    });
};

module.exports.DataExportService = DataExportService;
module.exports.EXPORT_FORMATS = EXPORT_FORMATS;
module.exports.DATA_TYPES = DATA_TYPES;
