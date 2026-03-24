import SwiftUI

// 支持的语言
struct Language: Identifiable, Hashable {
    let id: String
    let name: String
    let flag: String

    static let supportedLanguages: [Language] = [
        Language(id: "zh", name: "中文", flag: "🇨🇳"),
        Language(id: "en", name: "英语", flag: "🇺🇸"),
        Language(id: "ja", name: "日语", flag: "🇯🇵"),
        Language(id: "ko", name: "韩语", flag: "🇰🇷"),
        Language(id: "fr", name: "法语", flag: "🇫🇷"),
        Language(id: "de", name: "德语", flag: "🇩🇪"),
        Language(id: "es", name: "西班牙语", flag: "🇪🇸"),
        Language(id: "it", name: "意大利语", flag: "🇮🇹"),
        Language(id: "pt", name: "葡萄牙语", flag: "🇵🇹"),
        Language(id: "ru", name: "俄语", flag: "🇷🇺"),
        Language(id: "ar", name: "阿拉伯语", flag: "🇸🇦"),
        Language(id: "hi", name: "印地语", flag: "🇮🇳")
    ]
}

// 翻译记录
struct TranslationRecord: Identifiable, Codable {
    let id: UUID
    var sourceText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var createdAt: Date

    init(sourceText: String, translatedText: String, sourceLanguage: String, targetLanguage: String) {
        self.id = UUID()
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.createdAt = Date()
    }
}

// 翻译管理器
class TranslationManager: ObservableObject {
    @Published var records: [TranslationRecord] = []

    init() {
        loadRecords()
    }

    func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: "translation_records"),
           let decoded = try? JSONDecoder().decode([TranslationRecord].self, from: data) {
            records = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: "translation_records")
        }
    }

    func addRecord(_ record: TranslationRecord) {
        records.insert(record, at: 0)
        saveRecords()
    }

    func deleteRecord(_ record: TranslationRecord) {
        records.removeAll { $0.id == record.id }
        saveRecords()
    }

    // 模拟翻译（实际需要调用翻译 API）
    func translate(text: String, from: String, to: String) async -> String {
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 返回模拟翻译结果
        return "[\(to.uppercased())] \(text)"
    }
}

// 翻译视图
struct TranslationView: View {
    @StateObject private var translationManager = TranslationManager()

    @State private var sourceText = ""
    @State private var translatedText = ""
    @State private var sourceLanguage = Language.supportedLanguages[0] // 中文
    @State private var targetLanguage = Language.supportedLanguages[1] // 英语
    @State private var isTranslating = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 翻译区域
                VStack(spacing: 16) {
                    // 源语言
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            LanguagePicker(language: $sourceLanguage)
                            Spacer()
                            Button(action: swapLanguages) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            LanguagePicker(language: $targetLanguage)
                        }

                        TextEditor(text: $sourceText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // 翻译按钮
                    Button(action: performTranslation) {
                        HStack {
                            if isTranslating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            Text(isTranslating ? "翻译中..." : "翻译")
                        }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(sourceText.isEmpty ? Color.gray : Color.green)
                            .cornerRadius(12)
                    }
                    .disabled(sourceText.isEmpty || isTranslating)

                    // 翻译结果
                    if !translatedText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("翻译结果")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: copyTranslation) {
                                    Label("复制", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                            }

                            ScrollView {
                                Text(translatedText)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(minHeight: 100)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()

                Divider()

                // 翻译历史
                if !translationManager.records.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("翻译历史")
                                .font(.headline)
                            Spacer()
                            Button("清空") {
                                translationManager.records.removeAll()
                                translationManager.saveRecords()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal)

                        List {
                            ForEach(translationManager.records.prefix(10)) { record in
                                TranslationRecordRow(record: record)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            translationManager.deleteRecord(record)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("🌐 翻译")
        }
    }

    private func performTranslation() {
        guard !sourceText.isEmpty else { return }

        isTranslating = true
        translatedText = ""

        Task {
            let result = await translationManager.translate(
                text: sourceText,
                from: sourceLanguage.id,
                to: targetLanguage.id
            )

            await MainActor.run {
                translatedText = result
                isTranslating = false

                // 保存记录
                let record = TranslationRecord(
                    sourceText: sourceText,
                    translatedText: result,
                    sourceLanguage: sourceLanguage.name,
                    targetLanguage: targetLanguage.name
                )
                translationManager.addRecord(record)
            }
        }
    }

    private func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        // 交换文本
        if !translatedText.isEmpty {
            sourceText = translatedText
            translatedText = ""
        }
    }

    private func copyTranslation() {
        UIPasteboard.general.string = translatedText
    }
}

// 语言选择器
struct LanguagePicker: View {
    @Binding var language: Language

    var body: some View {
        Menu {
            ForEach(Language.supportedLanguages) { lang in
                Button(action: { language = lang }) {
                    HStack {
                        Text(lang.flag)
                        Text(lang.name)
                        if language.id == lang.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(language.flag)
                Text(language.name)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// 翻译记录行
struct TranslationRecordRow: View {
    let record: TranslationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.sourceText)
                .font(.subheadline)
                .lineLimit(1)

            Text(record.translatedText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack {
                Text("\(record.sourceLanguage) → \(record.targetLanguage)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text(record.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// 预览
struct TranslationView_Previews: PreviewProvider {
    static var previews: some View {
        TranslationView()
    }
}
