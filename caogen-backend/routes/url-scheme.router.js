/**
 * URL Scheme 路由
 */
const express = require('express');
const { URLSchemeService } = require('./url-scheme-service');

const router = express.Router();
const urlSchemeService = new URLSchemeService();

// 生成深度链接
router.post('/api/url-schemes/deep-link', async (req, res) => {
    try {
        const { appId, location, query, action } = req.body;

        if (!appId || !action) {
            return res.status(400).json({
                success: false,
                error: '缺少必要参数: appId 和 action'
            });
        }

        let deepLink = "";

        switch (action) {
        case "search":
            deepLink = urlSchemeService.generateDeepLink(
                urlSchemeService.getAppById(appId)!, // 这里应该传入 app 对象
                location,
                query
            );
            break;

        case "navigate":
            deepLink = urlSchemeService.generateDeepLink(
                urlSchemeService.getAppById(appId)!,
                location
            );
            break;

        case "restaurant":
            deepLink = urlSchemeService.generateDeepLink(
                urlSchemeService.getAppById(appId)!,
                location
            );
            break;

        case "map":
        case "route":
        case "navigate":
            deepLink = urlSchemeService.generateDeepLink(
                urlSchemeService.getAppById(appId)!,
                location
            );
            break;

        default:
            return res.status(400).json({
                success: false,
                error: '不支持的 action: ' + action
            });
        }

        res.json({
            success: true,
            data: {
                appName: urlSchemeService.getAppById(appId)?.name ?? "未知",
                deepLink,
                action,
                openType: "open"
            }
        });

    } catch (error) {
        console.error('深度链接生成失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取支持的 App 列表
router.get('/api/url-schemes', (req, res) => {
    try {
        const apps = URLSchemeService.getApps();

        // 构造每个 App 的完整信息
        const appList = apps.map(app => ({
            id: app.id,
            name: app.name,
            icon: app.icon,
            color: app.color,
            urlScheme: app.urlScheme,
            enabled: false, // 默认都不启用
            examples: []
        }));

        // 添加示例
        if appList.count > 0 {
            appList[0].examples = [
                {
                    title: "搜索北京美食",
                    description: "搜索北京地区的美食",
                    url: "imeituo://?keyword=美食"
                },
                {
                    title: "导航到天安门",
                    description: "打开高德地图并导航到天安门",
                    url: "iosamap://route/plan?sid=BG0C7192&x=116.403824&y=39.9&termname=天安门"
                }
            ]
        }

        res.json({
            success: true,
            data: appList
        });

    } catch (error) {
        console.error('获取 URL Schemes 失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 启用/禁用 App
app.post('/api/url-schemes/toggle/:id', (req, res) => {
    try {
        const { id } = req.params;

        urlSchemeService.toggleApp(id);

        res.json({
            success: true,
            message: urlSchemeService.getAppsById(id)?.name ?? "未知"
        });

    } catch (error) {
        console.error('切换 URL Scheme 失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取启用的 App 列表
router.get('/api/url-schemes/enabled', (req, res) => {
    try {
        const enabledApps = Array.from(urlSchemeService.enabledApps);

        res.json({
            success: true,
            data: {
                enabled: enabledApps
            }
        });

    } catch (error) {
        console.error('获取启用列表失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;