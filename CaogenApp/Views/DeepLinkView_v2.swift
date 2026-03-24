import SwiftUI

// URL Schemes（简化版）
struct AppURLScheme {
    let id: String
    let name: String
    let urlScheme: String
    var icon: String
    var color: String
}

// 简化版 URL Schemes 配置
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
        icon: "map.fill",
        color: "#2932FF"
    )
]

// 简化的 URL Scheme 管理器
class URLSchemesManager_v2 {
    @Published var enabledApps: Set<String> = []

    func init() {
        loadEnabledApps()
    }

    func loadEnabledApps() {
        if let data = UserDefaults.standard.data(forKey: "enabled_url_schemes_v2"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            enabledApps = Set(decoded)
        }
    }

    func saveEnabledApps() {
        if let encoded = try? JSONEncoder().encode(Array(enabledApps)) {
            UserDefaults.standard.set(encoded, forKey: "enabled_url_schemes_v2")
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
}

// 简化的深度链接生成
class DeepLinkGenerator {
    static func generateLink(app: AppURLScheme, location: String, query: String = "") -> String {
        var urlString = ""

        switch app.id {
        case "meituan":
            // 美团
            if !location.isEmpty {
                if location.contains("北京") {
                    urlString = "imeituo://restaurant?id=125919&location_id=125919&from=m_index_0"
                } else if location.contains("上海") {
                    urlString = "imeituo://restaurant?id=125920&location_id=125920&from=m_index_0"
                } else if location.contains("广州") {
                    urlString = "imeituo://restaurant?id=125921&location_id=125921&from=m_index_0"
                } else {
                    urlString = "imeituo://restaurant?id=125922&from=m_index_0"
                }
            } else {
                if location.contains("附近") {
                    urlString = "imeituo://restaurant?id=125919&location_id=125919&from=m_index_0"
                } else {
                    urlString = "imeituo://restaurant?from=m_index_0"
                }
            }
            break

        case "eleme":
            // 饿了么
            if !location.isEmpty {
                if location.contains("北京") {
                    urlString = "eleme://restaurant?id=1041&location_id=1041&from=m_index_0"
                } else if location.contains("上海") {
                    urlString = "eleme://restaurant?id=1042&location_id=1042&from=m_index_0"
                } else if location.contains("广州") {
                    urlString = "eleme://restaurant?id=1043&location_id=1043&from=m_index_0"
                } else {
                    urlString = "eleme://restaurant?id=1044&from=m_index_0"
                }
            } else {
                urlString = "eleme://restaurant?id=1044&from=m_index_0"
            }
            break

        case "didi":
            // 滴滴
            if !location.isEmpty {
                if location.contains("天安门") {
                    urlString = "didi://destinations?destId=1&destType=2&destLat=39.9&destLng=116.403824&destName=%E5%A4%87%E6%95%B4%E5%95%8F"
                } else if location.contains("机场") {
                    urlString = "didi://destinations?destId=1&destType=2&destLat=39.903824&destName=%E5%A4%87%E6%95%B4%E5%95%8F"
                } else {
                    urlString = "didi://destinations?destId=1&destType=2&destLat=39.903824&destName=%E5%A4%87%E6%95%B4%E5%95%8F&destName=地点名称"
                }
            }
            break

        case "gaode":
            // 高德地图
            if !location.isEmpty {
                if location.contains("天安门") {
                    urlString = "iosamap://route/plan?sid=BG0C7192&x=116.403824&y=39.9&termname=天安门广场"
                } else if location.contains("故宫") {
                    urlString = "iosamap://route/plan?sid=BG0C7192&x=116.397803&y=39.9&termname=故宫"
                } else {
                    urlString = "iosamap://search?keyword=\(keyword)&source=webapp&source=routeplan&resultType=search&map_action=&coordinate_systems=727&search_type=webapp&version=5&resultType=webapp"
                }
            }
            break

        case "baidu":
            // 百度地图
            if !location.isEmpty {
                if location.contains("天安门") {
                    urlString = "https://map.baidu.com/@api/map/gen/?x=116.403824&y=39.903824&title=天安门"
                } else if location.contains("故宫") {
                    urlString = "https:// map.baidu.com/@api/map/gen/?x=116.397803&y=39.903824&title=故宫"
                } else {
                    urlString = "https://map.baidu.com/@api/map/gen/?keyword=\(keyword)&z=3&source=webapp&resultType=webapp"
                }
            }
            break

        case "netease":
            // 网易云音乐
            if !query.isEmpty {
                urlString = "music.163.com/s?name=\(query)"
            } else {
                urlString = "music.163.com/s"
            }
            break

        case "qqmusic":
            // QQ 音乐
            urlString = "y.qq.com/#/"

        default:
            urlString = ""
        }

        // URL 编码中文部分
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

// 简化版深度链接视图
struct DeepLinkView_v2: View {
    @StateObject private var urlSchemesManager = URLSchemes_v2()
    @State private var searchText = ""
    @State private var selectedApp: AppURLScheme?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索应用或地点", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }

                // App 列表
                if !urlSchemesManager.enabledApps.isEmpty {
                    AppGrid(apps: urlSchemesManager.enabledApps, selectedApp: $selectedApp)
                        .padding(.horizontal)
                }

                // 示例区域
                if let app = selectedApp {
                    ExampleCards(app: app, location: searchText)
                }

                // 使用示例卡片
                if urlSchemesManager.enabledApps.isEmpty && searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("💡 使用说明")
                            .font(.headline)

                        Text("1. 点击顶部 + 号添加应用")
                        Text("2. 搜索\"北京必胜客\"打开美团")
                        Text("3. 搜索\"故宫\"打开高德地图")
                        Text("4. 搜索\"音乐\"打开网易云")
                    }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("🔗 深度链接")
    }
}

// 应用网格
struct AppGrid_v2: View {
    let apps: [AppURLScheme]
    @Binding var selectedApp: AppURLScheme?

    var columns: [GridItem] = [
        GridItem(.adaptive(minimum: 100), spacing: 12),
        GridItem(.adaptive(minimum: 100), spacing: 12),
        GridItem(.adaptive(minimum: 100), spacing: 12),
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(apps, id: \. self) { app in
                AppGridCard_v2(app, selectedApp: $selectedApp)
            }
        }
    }
}

// 应用卡片（简化版）
struct AppGridCard_v2: View {
    let app: AppURLScheme
    @Binding var selectedApp: AppURLScheme?

    var isSelected: Bool {
        if let selected = selectedApp {
            return app.id == selected.id
        }
        return false
    }

    var body: some View {
        Button(action: { selectedApp = app }) {
            ZStack {
                Circle()
                    .fill(isSelected ? app.color : app.color.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: app.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : app.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// 示例卡片
struct ExampleCards: View {
    let app: AppURLScheme
    let location: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(app.name)
                    .font(.headline)
                Text(app.urlScheme)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !location.isEmpty {
                Text("示例: \(location)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

// 预览
struct DeepLinkView_v2_Previews: PreviewProvider {
    static var previews: some View {
        DeepLinkView_v2()
    }
}
