import SwiftUI
import Vision
import UIKit

// OCR 识别结果
struct OCRResult: Identifiable, Codable {
    let id: UUID
    var text: String
    var confidence: Float
    var boundingBox: CGRect?
    var imageURL: URL?
    var createdAt: Date
}

// OCR 管理器
class OCRManager: ObservableObject {
    @Published var results: [OCRResult] = []
    @Published var isProcessing = false

    init() {
        loadResults()
    }

    func loadResults() {
        if let data = UserDefaults.standard.data(forKey: "ocr_results"),
           let decoded = try? JSONDecoder().decode([OCRResult].self, from: data) {
            results = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func saveResults() {
        if let encoded = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(encoded, forKey: "ocr_results")
        }
    }

    func recognizeText(from image: UIImage) async -> [OCRResult] {
        await MainActor.run { isProcessing = true }

        guard let cgImage = image.cgImage else {
            await MainActor.run { isProcessing = false }
            return []
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let ocrResults = observations.compactMap { observation -> OCRResult? in
                    guard let candidate = observation.topCandidates(1).first else {
                        return nil
                    }

                    return OCRResult(
                        id: UUID(),
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox,
                        createdAt: Date()
                    )
                }

                continuation.resume(returning: ocrResults)
            }

            // 配置识别选项
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                print("OCR 识别失败: \(error)")
                continuation.resume(returning: [])
            }
        }
    }

    func addResult(_ result: OCRResult) {
        results.insert(result, at: 0)
        saveResults()
    }

    func deleteResult(_ result: OCRResult) {
        results.removeAll { $0.id == result.id }
        saveResults()
    }
}

// OCR 视图
struct OCRView: View {
    @StateObject private var ocrManager = OCRManager()
    @State private var recognizedText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingCamera = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 图片区域
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(16)
                } else {
                    // 占位图
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("选择图片开始识别")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }

                // 识别按钮
                HStack(spacing: 16) {
                    Button(action: { showingImagePicker = true }) {
                        Label("相册", systemImage: "photo.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button(action: { showingCamera = true }) {
                        Label("拍照", systemImage: "camera.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }

                // 识别结果
                if !recognizedText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("识别结果")
                                .font(.headline)

                            Spacer()

                            Button(action: copyText) {
                                Label("复制", systemImage: "doc.on.doc")
                            }
                        }

                        ScrollView {
                            Text(recognizedText)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        Button(action: saveResult) {
                            Label("保存到收藏", systemImage: "star.fill")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }

                // 历史记录
                if !ocrManager.results.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("识别历史")
                            .font(.headline)

                        List {
                            ForEach(ocrManager.results.prefix(5)) { result in
                                Button(action: { recognizedText = result.text }) {
                                    VStack(alignment: .leading) {
                                        Text(result.text)
                                            .font(.subheadline)
                                            .lineLimit(2)

                                        HStack {
                                            Text(String(format: "%.0f%%", result.confidence * 100))
                                                .font(.caption)
                                                .foregroundColor(.secondary)

                                            Text(result.createdAt, style: .relative)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    ocrManager.deleteResult(ocrManager.results[index])
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("📷 OCR 文字识别")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                    .onDisappear {
                        if selectedImage != nil {
                            processImage()
                        }
                    }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
                    .onDisappear {
                        if selectedImage != nil {
                            processImage()
                        }
                    }
            }
        }
    }

    private func processImage() {
        guard let image = selectedImage else { return }

        Task {
            let results = await ocrManager.recognizeText(from: image)

            await MainActor.run {
                let fullText = results.map { $0.text }.joined(separator: "\n")
                recognizedText = fullText
                ocrManager.isProcessing = false

                // 添加到历史
                if let first = results.first {
                    ocrManager.addResult(first)
                }
            }
        }
    }

    private func copyText() {
        UIPasteboard.general.string = recognizedText
    }

    private func saveResult() {
        // 保存到收藏
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// 预览
struct OCRView_Previews: PreviewProvider {
    static var previews: some View {
        OCRView()
    }
}
