import Foundation

// 设置管理器
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var settings: AppSettings

    private let settingsKey = "app_settings"

    private init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings.defaultSettings
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    func reset() {
        settings = AppSettings.defaultSettings
        save()
    }

    // 便捷属性
    var serverURL: String {
        get { settings.serverURL }
        set {
            settings.serverURL = newValue
            save()
        }
    }

    var username: String {
        get { settings.username }
        set {
            settings.username = newValue
            save()
        }
    }

    var isBiometricEnabled: Bool {
        get { settings.isBiometricEnabled }
        set {
            settings.isBiometricEnabled = newValue
            save()
        }
    }

    var autoPlayVoice: Bool {
        get { settings.autoPlayVoice }
        set {
            settings.autoPlayVoice = newValue
            save()
        }
    }

    var voiceSpeed: Double {
        get { settings.voiceSpeed }
        set {
            settings.voiceSpeed = newValue
            save()
        }
    }
}

// 语音识别器
import Speech

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var isAvailable = false
    @Published var errorMessage: String?

    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    init(locale: Locale = Locale(identifier: "zh-CN")) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        isAvailable = speechRecognizer?.isAvailable ?? false

        if !isAvailable {
            errorMessage = "语音识别不可用"
        }
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startRecording() {
        guard isAvailable else {
            errorMessage = "语音识别不可用"
            return
        }

        // 停止之前的录音
        stopRecording()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "无法创建识别请求"
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.transcript = result.bestTranscription.formattedString
            }

            if let error = error {
                self.errorMessage = error.localizedDescription
                self.stopRecording()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer in
            self.recognitionRequest?.append(buffer)
        }

        do {
            try audioEngine.start()
            isRecording = true
            transcript = ""
        } catch {
            errorMessage = "无法启动音频引擎"
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false
    }
}

// 语音合成器
import AVFoundation

@MainActor
class SpeechSynthesizer: ObservableObject {
    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    init() {
        synthesizer.delegate = self
    }

    func speak(_ text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}
