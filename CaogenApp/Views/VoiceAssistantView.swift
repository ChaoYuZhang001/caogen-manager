import SwiftUI
import Speech
import AVFoundation

struct VoiceAssistantView: View {
    @EnvironmentObject var chatManager: ChatManager
    @State private var isRecording = false
    @State private var recognizedText = ""
    @State private var responseText = ""
    @State private var showSettings = false
    @State private var isSpeaking = false

    // 语音识别
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var speechSynthesizer = SpeechSynthesizer()

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // 语音可视化动画
                if isRecording {
                    VoiceAnimationView(isRecording: $isRecording)
                        .frame(height: 200)
                }

                // 识别的文本
                if !recognizedText.isEmpty {
                    VStack(spacing: 8) {
                        Text("你说了")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(recognizedText)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .transition(.scale)
                }

                // 草根的回复
                if !responseText.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                            Text("草根回复")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(responseText)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .transition(.scale)
                }

                // 状态提示
                if chatManager.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("草根正在思考...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 录音按钮
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.green)
                            .frame(width: 100, height: 100)
                            .scaleEffect(isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isRecording)

                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
                .disabled(chatManager.isLoading)

                // 提示文字
                Text(isRecording ? "点击停止" : "点击开始说话")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 快捷操作
                HStack(spacing: 20) {
                    QuickActionButton(
                        icon: "doc.text.fill",
                        title: "写周报",
                        action: { quickAction("帮我写个工作周报") }
                    )

                    QuickActionButton(
                        icon: "calendar",
                        title: "查日程",
                        action: { quickAction("帮我查一下今天的日程") }
                    )

                    QuickActionButton(
                        icon: "clock",
                        title: "早安报",
                        action: { quickAction("帮我写个早安日报") }
                    )
                }
                .padding()
            }
            .navigationTitle("🎙️ 语音助手")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onReceive(speechRecognizer.$transcript) { transcript in
            recognizedText = transcript
        }
        .onReceive(chatManager.$lastResponse) { response in
            if let response = response {
                responseText = response
                // 自动朗读回复
                Task {
                    await speakResponse(response)
                }
            }
        }
    }

    private func toggleRecording() {
        isRecording.toggle()

        if isRecording {
            // 开始录音
            speechRecognizer.startRecording()
        } else {
            // 停止录音并发送
            speechRecognizer.stopRecording()

            Task {
                if !recognizedText.isEmpty {
                    await chatManager.sendMessage(recognizedText)
                    // 清空识别文本和回复
                    responseText = ""
                }
            }
        }
    }

    private func quickAction(_ text: String) {
        Task {
            recognizedText = text
            await chatManager.sendMessage(text)
        }
    }

    private func speakResponse(_ text: String) async {
        await speechSynthesizer.speak(text)
    }
}

// 语音动画视图
struct VoiceAnimationView: View {
    @Binding var isRecording: Bool

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: CGFloat(80 + index * 40), height: CGFloat(80 + index * 40))
                    .scaleEffect(isRecording ? 1.0 + CGFloat(index) * 0.3 : 1.0)
                    .opacity(isRecording ? 0.6 : 0.3)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isRecording
                    )
            }

            Circle()
                .fill(Color.green)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "waveform")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
        }
    }
}

// 快捷操作按钮
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.green)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct VoiceAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceAssistantView()
            .environmentObject(ChatManager())
    }
}
