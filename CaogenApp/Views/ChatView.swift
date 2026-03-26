import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @StateObject private var emotionAI = EmotionAIManager.shared
    @StateObject private var intentUnderstanding = IntentUnderstandingManager.shared
    @StateObject private var deepMemory = DeepMemoryManager.shared
    @StateObject private var personalization = PersonalizationEngine.shared
    
    @State private var messageText = ""
    @FocusState private var isFocused = false
    @State private var currentEmotion: EmotionType?
    @State private var recognizedIntent: IntentResult?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 情绪状态指示器
                if let emotion = currentEmotion {
                    HStack {
                        Text(emotion.emoji)
                        Text("检测到\(emotion.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(emotion.emoji == "😢" || emotion.emoji == "😠" ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatManager.messages) { message in
                                MessageBubble(
                                    message: message,
                                    emotion: message.isUser ? nil : currentEmotion,
                                    intent: message.isUser ? nil : recognizedIntent
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatManager.messages.count) { _ in
                        if let lastMessage = chatManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // 输入框
                HStack(spacing: 12) {
                    TextField("对草根说...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                        .onSubmit {
                            sendMessage()
                        }

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.isLoading)
                }
                .padding()
            }
            .navigationTitle("💬 草根管家")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Menu {
                        Button(action: {
                            // 初始化用户画像
                            personalization.initializeProfile()
                        }) {
                            Label("初始化画像", systemImage: "person.crop.circle")
                        }
                        
                        Button(action: {
                            // 生成推荐
                            _ = personalization.generateRecommendations()
                        }) {
                            Label("生成推荐", systemImage: "star.fill")
                        }
                        
                        Button(action: {
                            // 查看记忆统计
                            let stats = deepMemory.getStatistics()
                            print("🧠 记忆统计：\(stats)")
                        }) {
                            Label("查看记忆", systemImage: "brain")
                        }
                    } label: {
                        Label("AI能力", systemImage: "brain")
                    }
                }
            }
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""
        isFocused = false

        Task {
            // 1. 识别情绪
            if let emotionResult = emotionAI.recognizeEmotion(from: text) {
                currentEmotion = emotionResult.emotion
                print("❤️ 识别到情绪：\(emotionResult.emotion.rawValue)")
                
                // 记住用户情绪
                deepMemory.store(
                    key: "emotion_\(Date().timeIntervalSince1970)",
                    value: emotionResult.emotion.rawValue,
                    category: .habits,
                    type: .mediumTerm,
                    importance: emotionResult.intensity.rawValue,
                    tags: ["emotion"]
                )
            }
            
            // 2. 识别意图
            let intentResult = intentUnderstanding.recognizeIntent(from: text)
            recognizedIntent = intentResult
            print("🎯 识别到意图：\(intentResult.primaryIntent.rawValue)")
            
            // 3. 学习用户行为
            predictionAI.shared.learnBehavior(action: intentResult.primaryIntent.rawValue, time: Date())
            
            // 4. 更新用户画像
            if intentResult.primaryIntent == .query {
                personalization.updateProfile(
                    key: "query_habit",
                    value: "likes_to_query",
                    category: .habits
                )
            }
            
            // 5. 生成响应
            let enhancedResponse = generateEnhancedResponse(for: text, intent: intentResult, emotion: currentEmotion)
            
            // 6. 发送消息（使用增强响应）
            await chatManager.sendMessage(enhancedResponse ?? text)
        }
    }
    
    // MARK: - Enhanced Response Generation
    
    private func generateEnhancedResponse(for text: String, intent: IntentResult, emotion: EmotionType?) -> String? {
        var response: String?
        
        // 根据情绪生成情感响应
        if let emotion = emotion, let emotionResult = emotionAI.emotionHistory.last {
            if emotionResult.emotion == emotion {
                response = emotionAI.generateEmotionalResponse(for: emotionResult)
            }
        }
        
        // 根据意图生成智能响应
        if response == nil {
            switch intent.primaryIntent {
            case .weather:
                response = "天气查询已收到！正在为你查询..."
                
            case .schedule:
                response = "日程查询已收到！正在为你查询..."
                
            case .expense:
                response = "记账已收到！正在为你记录..."
                
            case .health:
                response = "健康数据已收到！正在为你记录..."
                
            case .habit:
                response = "习惯打卡已收到！正在为你记录..."
                
            case .translate:
                response = "翻译请求已收到！正在为你翻译..."
                
            case .remind:
                response = "提醒已设置！我会准时提醒你~"
                
            case .emotion:
                if let emotion = emotion {
                    switch emotion {
                    case .sad, .disappointed, .lonely:
                        response = "你看起来心情不太好，需要我陪你聊聊天吗？"
                    case .angry, .stress, .anxiety:
                        response = "别太勉强自己，休息一下吧，我会一直陪着你~"
                    case .tired:
                        response = "累了就休息一下，身体最重要~"
                    default:
                        response = "我理解你的心情，需要我帮你做什么吗？"
                    }
                }
                
            default:
                // 使用情感AI的智能响应
                if let emotion = emotion, let emotionResult = emotionAI.emotionHistory.last {
                    if emotionResult.emotion == emotion {
                        response = emotionAI.generateEmotionalResponse(for: emotionResult)
                    }
                }
            }
        }
        
        return response
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let emotion: EmotionType?
    let intent: IntentResult?
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .frame(maxWidth: 250, alignment: .trailing)

                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    // AI 头像和情绪指示
                    HStack(spacing: 8) {
                        ZStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            // 情绪指示
                            if let emotion = emotion {
                                Text(emotion.emoji)
                                    .font(.system(size: 8))
                                    .offset(x: 12, y: -8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("草根")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // 意图指示
                            if let intent = intent {
                                Text(intent.primaryIntent.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .frame(maxWidth: 250, alignment: .leading)

                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(ChatManager())
    }
}
