import SwiftUI

// 收藏模型
struct Collection: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var type: CollectionType
    var sourceMessageId: UUID?
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CollectionType: String, Codable, CaseIterable {
        case text = "文本"
        case image = "图片"
        case link = "链接"
        case voiceMemo = "语音备忘"
        case file = "文件"
    }

    init(title: String, content: String, type: CollectionType = .text, sourceMessageId: UUID? = nil, tags: [String] = []) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.type = type
        self.sourceMessageId = sourceMessageId
        self.tags = tags
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// 收藏管理器
class CollectionManager: ObservableObject {
    @Published var collections: [Collection] = []
    @Published var notebooks: [Notebook] = []

    init() {
        loadCollections()
        loadNotebooks()
    }

    // 加载收藏
    func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: "collections"),
           let decoded = try? JSONDecoder().decode([Collection].self, from: data) {
            collections = decoded.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    // 保存收藏
    func saveCollections() {
        if let encoded = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(encoded, forKey: "collections")
        }
    }

    // 加载笔记本
    func loadNotebooks() {
        if let data = UserDefaults.standard.data(forKey: "notebooks"),
           let decoded = try? JSONDecoder().decode([Notebook].self, from: data) {
            notebooks = decoded.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    // 保存笔记本
    func saveNotebooks() {
        if let encoded = try? JSONEncoder().encode(notebooks) {
            UserDefaults.standard.set(encoded, forKey: "notebooks")
        }
    }

    // 添加收藏
    func addCollection(_ collection: Collection) {
        collections.insert(collection, at: 0)
        saveCollections()
    }

    // 删除收藏
    func deleteCollection(_ collection: Collection) {
        collections.removeAll { $0.id == collection.id }
        saveCollections()
    }

    // 更新收藏
    func updateCollection(_ collection: Collection, title: String, content: String, tags: [String]) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index].title = title
            collections[index].content = content
            collections[index].tags = tags
            collections[index].updatedAt = Date()
            saveCollections()
        }
    }

    // 切换收藏状态
    func toggleFavorite(_ collection: Collection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index].isFavorite.toggle()
            collections[index].updatedAt = Date()
            saveCollections()
        }
    }

    // 搜索收藏
    func searchCollections(_ query: String) -> [Collection] {
        if query.isEmpty {
            return collections
        }
        return collections.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.content.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    // 获取收藏的收藏
    func getFavorites() -> [Collection] {
        return collections.filter { $0.isFavorite }
    }

    // 创建笔记本
    func createNotebook(name: String, description: String = "") {
        let notebook = Notebook(name: name, description: description)
        notebooks.insert(notebook, at: 0)
        saveNotebooks()
    }

    // 删除笔记本
    func deleteNotebook(_ notebook: Notebook) {
        notebooks.removeAll { $0.id == notebook.id }
        saveNotebooks()
    }

    // 添加到笔记本
    func addToNotebook(_ collection: Collection, notebook: Notebook) {
        if let index = notebooks.firstIndex(where: { $0.id == notebook.id }) {
            notebooks[index].collectionIds.append(collection.id)
            notebooks[index].updatedAt = Date()
            saveNotebooks()
        }
    }

    // 获取笔记本内容
    func getNotebookContent(_ notebook: Notebook) -> [Collection] {
        return collections.filter { notebook.collectionIds.contains($0.id) }
    }
}

// 笔记本模型
struct Notebook: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var collectionIds: [UUID]
    var coverColor: String
    var createdAt: Date
    var updatedAt: Date

    init(name: String, description: String = "", collectionIds: [UUID] = [], coverColor: String = "green") {
        self.id = UUID()
        self.name = name
        self.description = description
        self.collectionIds = collectionIds
        self.coverColor = coverColor
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// 收藏视图
struct CollectionsView: View {
    @StateObject private var collectionManager = CollectionManager()
    @State private var searchText = ""
    @State private var selectedFilter: CollectionFilter = .all
    @State private var showingEditor = false
    @State private var editingCollection: Collection?

    enum CollectionFilter: String, CaseIterable {
        case all = "全部"
        case favorites = "收藏"
        case text = "文本"
        case image = "图片"
        case link = "链接"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CollectionFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))

                // 列表
                if filteredCollections.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("暂无收藏")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredCollections) { collection in
                            CollectionRow(collection: collection) {
                                collectionManager.toggleFavorite(collection)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    collectionManager.deleteCollection(collection)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingCollection = collection
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("⭐ 收藏")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingEditor = true }) {
                            Label("添加文本收藏", systemImage: "doc.text")
                        }
                        Button(action: { collectionManager.createNotebook(name: "新建笔记本") }) {
                            Label("创建笔记本", systemImage: "book.closed")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                CollectionEditorSheet(
                    collection: nil,
                    onSave: { title, content, tags in
                        let collection = Collection(title: title, content: content, tags: tags)
                        collectionManager.addCollection(collection)
                    }
                )
            }
            .sheet(item: $editingCollection) { collection in
                CollectionEditorSheet(
                    collection: collection,
                    onSave: { title, content, tags in
                        collectionManager.updateCollection(collection, title: title, content: content, tags: tags)
                    }
                )
            }
        }
    }

    private var filteredCollections: [Collection] {
        var collections = collectionManager.searchCollections(searchText)

        switch selectedFilter {
        case .all:
            break
        case .favorites:
            collections = collections.filter { $0.isFavorite }
        case .text:
            collections = collections.filter { $0.type == .text }
        case .image:
            collections = collections.filter { $0.type == .image }
        case .link:
            collections = collections.filter { $0.type == .link }
        }

        return collections
    }
}

// 筛选标签
struct FilterChip: View {
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

// 收藏行
struct CollectionRow: View {
    let collection: Collection
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 类型图标
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: iconForType(collection.type))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(collection.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if !collection.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(collection.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()

            Button(action: onToggleFavorite) {
                Image(systemName: collection.isFavorite ? "star.fill" : "star")
                    .foregroundColor(collection.isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func iconForType(_ type: Collection.CollectionType) -> String {
        switch type {
        case .text: return "doc.text"
        case .image: return "photo"
        case .link: return "link"
        case .voiceMemo: return "mic"
        case .file: return "folder"
        }
    }
}

// 收藏编辑弹窗
struct CollectionEditorSheet: View {
    let collection: Collection?
    let onSave: (String, String, [String]) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var content: String
    @State private var tagsText: String

    init(collection: Collection?, onSave: @escaping (String, String, [String]) -> Void) {
        self.collection = collection
        self.onSave = onSave
        _title = State(initialValue: collection?.title ?? "")
        _content = State(initialValue: collection?.content ?? "")
        _tagsText = State(initialValue: collection?.tags.joined(separator: ", ") ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("标题") {
                    TextField("输入标题", text: $title)
                }

                Section("内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }

                Section("标签（用逗号分隔）") {
                    TextField("工作, 重要, 待办", text: $tagsText)
                }
            }
            .navigationTitle(collection == nil ? "添加收藏" : "编辑收藏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let tags = tagsText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                        onSave(title.isEmpty ? "未命名" : title, content, tags)
                        dismiss()
                    }
                    .disabled(title.isEmpty && content.isEmpty)
                }
            }
        }
    }
}

// 预览
struct CollectionsView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionsView()
    }
}
