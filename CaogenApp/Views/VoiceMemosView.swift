import SwiftUI
import AVFoundation

// 语音备忘模型
struct VoiceMemo: Identifiable, Codable {
    let id: UUID
    var title: String
    var audioURL: URL?
    var duration: TimeInterval
    var transcript: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "", audioURL: URL? = nil, duration: TimeInterval = 0, transcript: String? = nil, tags: [String] = []) {
        self.id = UUID()
        self.title = title
        self.audioURL = audioURL
        self.duration = duration
        self.transcript = transcript
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// 语音备忘管理器
class VoiceMemoManager: ObservableObject {
    @Published var memos: [VoiceMemo] = []
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var isPlaying = false
    @Published var playingMemoId: UUID?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?

    init() {
        loadMemos()
    }

    // 加载备忘
    func loadMemos() {
        if let data = UserDefaults.standard.data(forKey: "voice_memos"),
           let decoded = try? JSONDecoder().decode([VoiceMemo].self, from: data) {
            memos = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // 保存备忘
    func saveMemos() {
        if let encoded = try? JSONEncoder().encode(memos) {
            UserDefaults.standard.set(encoded, forKey: "voice_memos")
        }
    }

    // 开始录音
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()

            isRecording = true
            recordingDuration = 0

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.recordingDuration += 1
            }

        } catch {
            print("录音失败: \(error)")
        }
    }

    // 停止录音
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil

        let url = audioRecorder?.url
        audioRecorder = nil
        isRecording = false

        return url
    }

    // 保存新备忘
    func saveMemo(title: String, audioURL: URL, duration: TimeInterval, transcript: String? = nil) {
        let memo = VoiceMemo(
            title: title,
            audioURL: audioURL,
            duration: duration,
            transcript: transcript,
            tags: []
        )

        memos.insert(memo, at: 0)
        saveMemos()
    }

    // 播放语音
    func playMemo(_ memo: VoiceMemo) {
        guard let url = memo.audioURL else { return }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()

            isPlaying = true
            playingMemoId = memo.id

            playbackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if !(self.audioPlayer?.isPlaying ?? false) {
                    self.stopPlaying()
                }
            }

        } catch {
            print("播放失败: \(error)")
        }
    }

    // 停止播放
    func stopPlaying() {
        audioPlayer?.stop()
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
        playingMemoId = nil
    }

    // 删除备忘
    func deleteMemo(_ memo: VoiceMemo) {
        // 删除音频文件
        if let url = memo.audioURL {
            try? FileManager.default.removeItem(at: url)
        }

        memos.removeAll { $0.id == memo.id }
        saveMemos()
    }

    // 更新备忘
    func updateMemo(_ memo: VoiceMemo, title: String, tags: [String]) {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index].title = title
            memos[index].tags = tags
            memos[index].updatedAt = Date()
            saveMemos()
        }
    }

    // 搜索备忘
    func searchMemos(_ query: String) -> [VoiceMemo] {
        if query.isEmpty {
            return memos
        }
        return memos.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            ($0.transcript?.localizedCaseInsensitiveContains(query) ?? false) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

// 语音备忘视图
struct VoiceMemosView: View {
    @StateObject private var memoManager = VoiceMemoManager()
    @State private var searchText = ""
    @State private var showingRecorder = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 录音按钮
                RecordButton(
                    isRecording: memoManager.isRecording,
                    duration: memoManager.recordingDuration,
                    onStart: { memoManager.startRecording() },
                    onStop: {
                        if let url = memoManager.stopRecording() {
                            showingRecorder = true
                        }
                    }
                )
                .padding(.vertical, 20)

                // 搜索
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索语音备忘", text: $searchText)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                // 备忘列表
                if filteredMemos.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("暂无语音备忘")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("点击上方按钮开始录音")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredMemos) { memo in
                            VoiceMemoRow(
                                memo: memo,
                                isPlaying: memoManager.playingMemoId == memo.id,
                                onPlay: { memoManager.playMemo(memo) },
                                onStop: { memoManager.stopPlaying() }
                            )
                        }
                        .onDelete(perform: deleteMemos)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("🎙️ 语音备忘")
            .sheet(isPresented: $showingRecorder) {
                SaveMemoSheet(
                    audioURL: memoManager.audioRecorder?.url,
                    duration: memoManager.recordingDuration,
                    onSave: { title, tags in
                        if let url = memoManager.audioRecorder?.url {
                            memoManager.saveMemo(
                                title: title,
                                audioURL: url,
                                duration: memoManager.recordingDuration
                            )
                        }
                    }
                )
            }
        }
    }

    private var filteredMemos: [VoiceMemo] {
        memoManager.searchMemos(searchText)
    }

    private func deleteMemos(at offsets: IndexSet) {
        for index in offsets {
            memoManager.deleteMemo(filteredMemos[index])
        }
    }
}

// 录音按钮
struct RecordButton: View {
    let isRecording: Bool
    let duration: TimeInterval
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        Button(action: {
            if isRecording {
                onStop()
            } else {
                onStart()
            }
        }) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.green)
                    .frame(width: 80, height: 80)
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isRecording)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
        }

        if isRecording {
            Text(formatDuration(duration))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .padding(.top, 10)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// 语音备忘行
struct VoiceMemoRow: View {
    let memo: VoiceMemo
    let isPlaying: Bool
    let onPlay: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 播放按钮
            Button(action: {
                if isPlaying {
                    onStop()
                } else {
                    onPlay()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title.isEmpty ? "未命名备忘" : memo.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(formatDuration(memo.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let transcript = memo.transcript, !transcript.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(transcript.prefix(30) + (transcript.count > 30 ? "..." : ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !memo.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(memo.tags.prefix(3), id: \.self) { tag in
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

            Text(memo.createdAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// 保存备忘弹窗
struct SaveMemoSheet: View {
    let audioURL: URL?
    let duration: TimeInterval
    let onSave: (String, [String]) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var tagsText = ""

    var body: some View {
        NavigationView {
            Form {
                Section("标题") {
                    TextField("输入备忘标题", text: $title)
                }

                Section("标签（用逗号分隔）") {
                    TextField("工作, 重要, 待办", text: $tagsText)
                }

                Section("时长") {
                    Text(formatDuration(duration))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("保存语音备忘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let tags = tagsText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                        onSave(title.isEmpty ? "语音备忘" : title, tags)
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// 预览
struct VoiceMemosView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceMemosView()
    }
}
