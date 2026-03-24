import SwiftUI

// 插件模型
struct Plugin: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let author: String
    let version: String
    let icon: String
    let category: PluginCategory
    let price: Double // 0 = 免费
    let rating: Double
    let downloadCount: Int
    let isInstalled: Bool
    let isEnabled: Bool

    enum PluginCategory: String, Codable, CaseIterable {
        case productivity = "效率工具"
        case entertainment = "娱乐"
        case social = "社交"
        case utility = "实用工具"
        case education = "教育"
        case lifestyle = "生活"
    }
}

// 插件市场视图
struct PluginStoreView: View {
    @StateObject private var pluginManager = PluginStoreManager()
    @State private var selectedCategory: Plugin.PluginCategory?
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding()

                // 分类筛选
                CategoryFilter(
                    selectedCategory: $selectedCategory,
                    categories: Plugin.PluginCategory.allCases
                )
                .padding(.horizontal)

                // 插件列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredPlugins) { plugin in
                            PluginCard(plugin: plugin) {
                                pluginManager.installPlugin(plugin)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("🔌 插件市场")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { pluginManager.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    private var filteredPlugins: [Plugin] {
        var plugins = pluginManager.plugins

        // 分类筛选
        if let category = selectedCategory {
            plugins = plugins.filter { $0.category == category }
        }

        // 搜索筛选
        if !searchText.isEmpty {
            plugins = plugins.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return plugins
    }
}

// 搜索栏
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("搜索插件", text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// 分类筛选
struct CategoryFilter: View {
    @Binding var selectedCategory: Plugin.PluginCategory?
    let categories: [Plugin.PluginCategory]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 全部
                CategoryChip(
                    title: "全部",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
}

// 分类标签
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

// 插件卡片
struct PluginCard: View {
    let plugin: Plugin
    let onInstall: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // 插件图标
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: plugin.icon)
                        .font(.title)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(plugin.name)
                        .font(.headline)

                    Text("v\(plugin.version) • \(plugin.author)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", plugin.rating))
                            .font(.caption)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(formatNumber(plugin.downloadCount)) 次下载")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 安装按钮
                if plugin.isInstalled {
                    Button(action: {}) {
                        Text(plugin.isEnabled ? "已启用" : "已安装")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                } else {
                    Button(action: onInstall) {
                        Text(plugin.price > 0 ? "¥\(Int(plugin.price))" : "免费")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
            }

            // 描述
            Text(plugin.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // 分类标签
            HStack {
                Text(plugin.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)

                Spacer()

                if plugin.isInstalled {
                    Toggle("", isOn: .constant(plugin.isEnabled))
                        .labelsHidden()
                        .tint(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000000 {
            return String(format: "%.1fM", Double(num) / 1000000)
        } else if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}

// 插件商店管理器
class PluginStoreManager: ObservableObject {
    @Published var plugins: [Plugin] = []
    @Published var isLoading = false

    init() {
        loadPlugins()
    }

    func loadPlugins() {
        // 模拟插件数据
        plugins = [
            Plugin(
                id: "1",
                name: "天气助手",
                description: "查询实时天气、预报空气质量，支持多种城市",
                author: "草根团队",
                version: "1.2.0",
                icon: "cloud.sun.fill",
                category: .utility,
                price: 0,
                rating: 4.8,
                downloadCount: 12500,
                isInstalled: true,
                isEnabled: true
            ),
            Plugin(
                id: "2",
                name: "翻译官",
                description: "支持 100+ 语言实时翻译，离线也能用",
                author: "草根团队",
                version: "2.0.0",
                icon: "globe",
                category: .utility,
                price: 0,
                rating: 4.9,
                downloadCount: 25000,
                isInstalled: false,
                isEnabled: false
            ),
            Plugin(
                id: "3",
                name: "日历同步",
                description: "同步系统日历、Outlook、Google Calendar",
                author: "第三方开发者",
                version: "1.5.0",
                icon: "calendar",
                category: .productivity,
                price: 12,
                rating: 4.5,
                downloadCount: 5800,
                isInstalled: false,
                isEnabled: false
            ),
            Plugin(
                id: "4",
                name: "语音备忘",
                description: "快速创建语音备忘，支持语音转文字",
                author: "草根团队",
                version: "1.0.0",
                icon: "mic.fill",
                category: .productivity,
                price: 0,
                rating: 4.7,
                downloadCount: 8900,
                isInstalled: true,
                isEnabled: true
            ),
            Plugin(
                id: "5",
                name: "新闻摘要",
                description: "每日自动汇总科技、财经要闻",
                author: "第三方开发者",
                version: "1.8.0",
                icon: "newspaper.fill",
                category: .lifestyle,
                price: 6,
                rating: 4.3,
                downloadCount: 3200,
                isInstalled: false,
                isEnabled: false
            ),
            Plugin(
                id: "6",
                name: "记账助手",
                description: "语音快速记账，生成消费分析报表",
                author: "草根团队",
                version: "1.3.0",
                icon: "dollarsign.circle.fill",
                category: .lifestyle,
                price: 0,
                rating: 4.6,
                downloadCount: 15600,
                isInstalled: false,
                isEnabled: false
            )
        ]
    }

    func refresh() {
        isLoading = true
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadPlugins()
            self.isLoading = false
        }
    }

    func installPlugin(_ plugin: Plugin) {
        // 模拟安装
        if let index = plugins.firstIndex(where: { $0.id == plugin.id }) {
            plugins[index] = Plugin(
                id: plugin.id,
                name: plugin.name,
                description: plugin.description,
                author: plugin.author,
                version: plugin.version,
                icon: plugin.icon,
                category: plugin.category,
                price: plugin.price,
                rating: plugin.rating,
                downloadCount: plugin.downloadCount + 1,
                isInstalled: true,
                isEnabled: false
            )
        }
    }

    func uninstallPlugin(_ plugin: Plugin) {
        if let index = plugins.firstIndex(where: { $0.id == plugin.id }) {
            plugins[index] = Plugin(
                id: plugin.id,
                name: plugin.name,
                description: plugin.description,
                author: plugin.author,
                version: plugin.version,
                icon: plugin.icon,
                category: plugin.category,
                price: plugin.price,
                rating: plugin.rating,
                downloadCount: plugin.downloadCount,
                isInstalled: false,
                isEnabled: false
            )
        }
    }
}

// 预览
struct PluginStoreView_Previews: PreviewProvider {
    static var previews: some View {
        PluginStoreView()
    }
}
