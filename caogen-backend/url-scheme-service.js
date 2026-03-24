import Foundation

// URL Schemes 配置
struct AppURLScheme: Identifiable, Hashable {
    let id: String
    let name: String
    let urlScheme: String
    var icon: String
    var color: String

    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}

// 支持的 App 配置
let supportedApps: [AppURLScheme] = [
    AppURLScheme(
        id: "meituan",
        name: "美团",
        urlScheme: "imeituo://",
        icon: "bag.fill",
        color: "#FF6B00"
    ),
    AppURLScheme(
        id: "eleme",
        name: "饿了么",
        urlScheme: "eleme://",
        icon: "cart.fill",
        color: "#0089FF"
    ),
    AppURLScheme(
        id: "didi",
        name: "滴滴",
        urlScheme: "didi://",
        icon: "car.fill",
        color: "#FFD700"
    ),
    AppURLScheme(
        id: "gaode",
        name: "高德地图",
        urlScheme: "iosamap://",
        icon: "map.fill",
        color: "#00A3FF"
    ),
    AppURLScheme(
        id: "baidu",
        name: "百度地图",
        urlScheme: "baidumap://",
        icon: "mappin.fill",
        color: "#2932FF"
    ),
    AppURLScheme(
        "netease",
        name: "网易云音乐",
        urlScheme: "music.163.com://",
        icon: "music.note",
        color: "#E6202D"
    ),
    AppURLScheme(
        "qqmusic",
        name: "QQ音乐",
        urlScheme: "qqmusic://",
        "icon: "music.note",
        color: "FFC641"
    ),
    ]

// URL Schemes 管理器
class URLSchemesManager: ObservableObject {
    @Published var enabledApps: Set<String> = []

    init() {
        loadEnabledApps()
    }

    func loadEnabledApps() {
        if let data = UserDefaults.standard.data(forKey: "enabled_url_schemes"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            enabledApps = Set(decoded)
        }
    }

    func saveEnabledApps() {
        if let encoded = try? JSONEncoder().encode(Array(enabledApps)) {
            UserDefaults.standard.set(encoded, forKey: "enabled_url_schemes")
        }
    }

    func toggleApp(_ id: String) {
        if enabledApps.contains(id) {
            enabledApps.remove(id)
        } else {
            enabledApps.insert(id)
        }
        saveEnabledApps()
    }

    func getAppById(_ id: String) -> AppURLScheme? {
        supportedApps.first { $0.id == id }
    }
}

// 快捷指令管理器
class QuickActionManager: ObservableObject {
    @Published var quickActions: [QuickAction] = []

    init() {
        loadQuickActions()
    }

    func loadQuickActions() {
        if let data = UserDefaults.standard.data(forKey: "quick_actions"),
           let decoded = try? JSONDecoder().decode([QuickAction].self, from: data) {
            quickActions = decoded
        }
    }

    func saveQuickActions() {
        if let encoded = try? JSONEncoder().encode(quickActions) {
            UserDefaults.standard.set(encoded, forKey: "quick_actions")
        }
    }

    func addQuickAction(_ action: QuickAction) {
        quickActions.append(action)
        saveQuickActions()
    }

    func deleteQuickAction(_ action: QuickAction) {
        quickActions.removeAll { $0.id == action.id }
        saveQuickActions()
    }

    func getActionsByKeyword(keyword: String) -> [QuickAction] {
        return quickActions.filter { $0.keywords.contains(keyword) }
    }
}

// 快捷指令模型
struct QuickAction: Identifiable, Codable {
    let id: UUID
    let name: String
    let keywords: [String]
    let appURL: String
    var urlTemplate: String
    var icon: String

    init(name: String, keywords: [String], appURL: String, urlTemplate: String = "", icon: String = "star.fill") {
        self.id = UUID()
        self.name = name
        self.keywords = keywords
        self.appURL = appURL
        self.urlTemplate = urlTemplate
        self.icon = icon
    }
}

// URL Scheme 服务
class URLSchemeService {
    private let urlSchemes = [
        AppURLScheme(
            id: "meituan",
            name: "美团",
            urlScheme: "imeituo://",
            icon: "bag.fill",
            color: "#FF6B00"
        )
    ]

    // 生成深度链接
    func generateDeepLink(app: AppURLScheme, location: String, query: String = "") -> String {
        var urlString = ""

        switch appURL.id {
        case "meituan":
            // 美团
            if location.contains("北京") {
                urlString = "imeituo://restaurant?id=125919&location_id=125919&from=m_index_0"
            } else if location.contains("上海") {
                urlString = "imeituo://restaurant?id=125920&location_id=125920&from=m_index_0"
            } else if location.contains("广州") {
                urlString = "imeituo://restaurant?id=125921&location_id=125921&from=m_index_0"
            }

        case "eleme":
            // 饿了么
            if location.contains("北京") {
                urlString = "eleme://restaurant?id=1041&location_id=1041&from=m_index_0"
            } else if location.contains("上海") {
                urlString = "eleme://restaurant?id=1042&location_id=1042&from=m_index_0"
            } else if location.contains("广州") {
                urlString = "eleme://restaurant?id=1043&location_id=1043&from=m_index_0"
            }

        case "didi":
            // 滴滴
            if location.contains("天安门") {
                urlString = "didi://destinations?destId=1&destType=2&destLat=39.9&destLng=116.403824&destName=%E5%A4%87%E6%95%B4%E5%95%8F"
            } else if location.contains("机场") {
                urlString = "didi://destinations?destId=1&destType=2&destLat=39.903824&destName=%E5%A4%87%E6%95%B4%E5%95%8F"
            } else {
                urlString = "didi://destinations?destId=1&destType=2&destName=%E5%A4%87%E6%95%B4%E5%95%8F&destName=地点名称"
            }

        case "gaode":
            // 高德地图
            if location.contains("天安门") {
                urlString = "iosamap://route/plan?sid=BG0C7192&x=116.403824&y=39.9&termname=天安门广场"
            } else if location.contains("故宫") {
                urlString = "iosamap://route/plan?sid=BG0C7192&x=116.397803&y=39.9&termname=故宫"
            } else {
                urlString = "iosamap://search?keyword=\(keyword)&source=webapp&source=routeplan&resultType=search&map_action=&coordinate_systems=727&search_type=webapp&source=webapp&version=5&resultType=webapp"
            }

        case "baidu":
            // 百度地图
            if location.contains("天安门") {
                // 百度地图 Web App 的调用
                urlString = "https://map.baidu.com/@api/map/gen/?x=116.403824&y=39.903824&title=天安门"
            } else if location.contains("故宫") {
                urlString = "https://map.baidu.com/@api/map/gen/?x=116.397803&y=39.903824&title=故宫"
            } else {
                urlString = "https://map.baidu.com/@api/map/gen/?keyword=\(keyword)&z=3&source=webapp&resultType=webapp"
            }

        case "netease":
            // 网易云音乐
            // 网易云音乐 Web 调用
            urlString = "music.163.com/s?name=我的电台&rid=xxx"

        case "qqmusic":
            // QQ 音乐
            // QQ 音乐 Web 调用
            urlString = "y.qq.com/#/"
        }

        // URL 编码（中文编码）
        if !query.isEmpty {
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed, encoding: .utf8)
            if let urlComponents = URLComponents(string: urlString, resolvingAllowed: .utf8),
               urlComponents.queryItems == nil {
                urlString += "?\(encodedQuery)"
            }
        }

        return urlString
    }
}

// API 路由
module.exports = (app) => {
    const urlSchemesService = new URLSchemeService();

    // 获取支持的 App 列表
    app.get('/api/url-schemes', (req, res) => {
        try {
            res.json({
                success: true,
                data: URLSchemesManager.supportedApps.map(\.0.toJSON())
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    // 生成深度链接
    app.post('/api/url-schemes/deep-link', (req, res) => {
        try {
            const { appId, location, query, action } = req.body;

            if (!appId || !action) {
                return res.status(400).json({
                    success: false,
                    error: '缺少必要参数'
                });
            }

            const app = URLSchemesManager.getAppById(appId);
            let deepLink = "";

            switch (action) {
            case "search":
                // 搜索
                deepLink = urlSchemesService.generateDeepLink(app!, location, query);
                break;

            case "navigate":
                // 导航
                deepLink = urlSchemesService.generateDeepLink(app!, location);
                break;

            case "restaurant":
                // 外卖搜索
                deepLink = urlSchemesService.generateDeepLink(app!, location);
                break;

            default:
                return res.status(400).json({
                    success: false,
                    error: '不支持的 action'
                });
            }

            res.json({
                success: true,
                data: {
                    appName: app?.name ?? "未知",
                    deepLink,
                    openType: "open"
                }
            });

        } catch (error) {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });
};

module.exports.URLSchemeService = URLSchemeService;
module.exports.URLSchemesManager = URLSchemesManager;
