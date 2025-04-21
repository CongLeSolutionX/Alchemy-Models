////
////  OpenAIChatAPIDemoView_Vietnamize_Version_Part2.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIChatAPIDemoView_V7.swift
////  Alchemy_Models
////  AIChatVoiceDemo
////  Created by Cong Le on 4/20/25.
////  Updated with Vietnamese speech recognition settings on 6/3/24.
////
////  Single-file SwiftUI chat + speech recognition + TTS + voice commands.
////
//
//import SwiftUI
//import Speech
//import AVFoundation
//
//// MARK: - MODELS
//
//enum ChatRole: String, Codable {
//    case system, user, assistant
//}
//
//struct Message: Identifiable, Codable, Hashable {
//    let id: UUID
//    let role: ChatRole
//    let content: String
//    let timestamp: Date
//
//    init(role: ChatRole, content: String, timestamp: Date = .now, id: UUID = UUID()) {
//        self.id = id; self.role = role; self.content = content; self.timestamp = timestamp
//    }
//
//    static func system(_ text: String)    -> Message { .init(role: .system, content: text) }
//    static func user(_ text: String)      -> Message { .init(role: .user, content: text) }
//    static func assistant(_ text: String) -> Message { .init(role: .assistant, content: text) }
//}
//
//struct Conversation: Identifiable, Codable, Hashable {
//    let id: UUID
//    var messages: [Message]
//    var title: String
//    var createdAt: Date
//
//    init(messages: [Message], title: String = "", createdAt: Date = .now, id: UUID = UUID()) {
//        self.id = id
//        self.messages = messages
//        self.createdAt = createdAt
//        if title.isEmpty {
//            let first = messages.first { $0.role == .user }?.content
//            self.title = first.map { String($0.prefix(32)) } ?? "Chat"
//        } else {
//            self.title = title
//        }
//    }
//}
//
//// MARK: - BACKEND PROTOCOLS
//
//protocol ChatBackend {
//    func streamChat(
//        messages: [Message],
//        systemPrompt: String,
//        completion: @escaping (Result<String, Error>) -> Void
//    )
//}
//
//struct MockChatBackend: ChatBackend {
//    let replies = [
//        "Chắc chắn rồi!",
//        "Hãy cùng xem xét.",
//        "Bạn có thể làm rõ hơn không?",
//        "Đây là gợi ý của tôi.",
//        "OK!",
//        "Tôi đang suy nghĩ..."
//    ]
//    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            completion(.success(replies.randomElement() ?? "Bạn có thể diễn đạt lại không?"))
//        }
//    }
//}
//
//final class RealOpenAIBackend: ChatBackend {
//    let apiKey: String, model: String, temperature: Double, maxTokens: Int
//    init(apiKey: String, model: String, temperature: Double, maxTokens: Int) {
//        self.apiKey = apiKey; self.model = model
//        self.temperature = temperature; self.maxTokens = maxTokens
//    }
//    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void) {
//        var full = messages
//        if !systemPrompt.isEmpty {
//            full.insert(.system(systemPrompt), at: 0)
//        }
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            completion(.failure(NSError(domain: "InvalidURL", code: 1)))
//            return
//        }
//        var req = URLRequest(url: url)
//        req.httpMethod = "POST"
//        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        struct Payload: Encodable {
//            let model: String
//            let messages: [[String:String]]
//            let temperature: Double
//            let max_tokens: Int
//        }
//        let body = Payload(
//            model: model,
//            messages: full.map { ["role": $0.role.rawValue, "content": $0.content] },
//            temperature: temperature,
//            max_tokens: maxTokens
//        )
//        do { req.httpBody = try JSONEncoder().encode(body) }
//        catch { completion(.failure(error)); return }
//
//        URLSession.shared.dataTask(with: req) { data, _, error in
//            if let err = error { return completion(.failure(err)) }
//            guard let d = data else {
//                return completion(.failure(NSError(domain: "NoData", code: 2)))
//            }
//            do {
//                struct Resp: Decodable {
//                    struct Choice: Decodable {
//                        struct Msg: Decodable { let role: String; let content: String }
//                        let message: Msg
//                    }
//                    let choices: [Choice]
//                }
//                let obj = try JSONDecoder().decode(Resp.self, from: d)
//                let text = obj.choices.first?.message.content ?? "No response"
//                DispatchQueue.main.async { completion(.success(text)) }
//            } catch {
//                DispatchQueue.main.async { completion(.failure(error)) }
//            }
//        }.resume()
//    }
//}
//
//// MARK: - SPEECH RECOGNIZER
//
//final class SpeechRecognizer: NSObject, ObservableObject {
//    @Published var transcript: String = ""
//    @Published var isRecording: Bool = false
//    @Published var errorMessage: String?
//
//    /// Called on final transcription (either recognized final or silence timeout).
//    var onFinalTranscription: ((String) -> Void)?
//
//    /// Explicitly Vietnamese recognizer
//    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi‑VN"))
//    private let audioEngine = AVAudioEngine()
//    private var request: SFSpeechAudioBufferRecognitionRequest?
//    private var task: SFSpeechRecognitionTask?
//
//    /// Tune timeout for Vietnamese
//    private let silenceTimeout: TimeInterval = 2.0
//    private var silenceWorkItem: DispatchWorkItem?
//
//    func requestAuthorization(completion: @escaping (Bool)->Void) {
//        SFSpeechRecognizer.requestAuthorization { status in
//            DispatchQueue.main.async {
//                let granted = (status == .authorized)
//                if !granted {
//                    // Vietnamese fallback message
//                    self.errorMessage = "Cần quyền truy cập micro."
//                }
//                completion(granted)
//            }
//        }
//    }
//
//    func startRecording() throws {
//        errorMessage = nil
//        transcript = ""
//        isRecording = true
//
//        // Cancel prior sessions
//        task?.cancel(); task = nil
//        request?.endAudio(); request = nil
//        silenceWorkItem?.cancel(); silenceWorkItem = nil
//
//        // Configure audio session (duck others)
//        let session = AVAudioSession.sharedInstance()
//        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
//        try session.setActive(true, options: .notifyOthersOnDeactivation)
//
//        // Create recognition request
//        let req = SFSpeechAudioBufferRecognitionRequest()
//        req.shouldReportPartialResults = true
//        req.taskHint = .dictation
//        self.request = req
//
//        // Start recognition task
//        task = recognizer?.recognitionTask(with: req) { [weak self] result, error in
//            guard let self = self else { return }
//            if let res = result {
//                DispatchQueue.main.async {
//                    self.transcript = res.bestTranscription.formattedString
//                }
//                if res.isFinal {
//                    self.handleFinal(self.transcript)
//                } else {
//                    self.scheduleSilenceTimeout()
//                }
//            }
//            if let err = error {
//                DispatchQueue.main.async {
//                    self.errorMessage = err.localizedDescription
//                    self.stopRecording()
//                }
//            }
//        }
//
//        // Install tap on input node
//        let input = audioEngine.inputNode
//        let fmt = input.outputFormat(forBus: 0)
//        input.removeTap(onBus: 0)
//        input.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buffer, _ in
//            req.append(buffer)
//        }
//
//        audioEngine.prepare()
//        try audioEngine.start()
//    }
//
//    private func scheduleSilenceTimeout() {
//        silenceWorkItem?.cancel()
//        let wi = DispatchWorkItem { [weak self] in
//            guard let self = self, self.isRecording else { return }
//            self.handleFinal(self.transcript)
//        }
//        silenceWorkItem = wi
//        DispatchQueue.main.asyncAfter(deadline: .now() + silenceTimeout, execute: wi)
//    }
//
//    private func handleFinal(_ text: String) {
//        onFinalTranscription?(text)
//        stopRecording()
//    }
//
//    func stopRecording() {
//        if audioEngine.isRunning {
//            audioEngine.inputNode.removeTap(onBus: 0)
//            audioEngine.stop()
//        }
//        request?.endAudio()
//        task?.cancel()
//        isRecording = false
//
//        silenceWorkItem?.cancel(); silenceWorkItem = nil
//        request = nil; task = nil
//
//        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
//    }
//}
//
//// MARK: - VIEW MODEL
//
//@MainActor
//final class ChatStore: ObservableObject {
//    @Published var conversations: [Conversation] = [
//        Conversation(messages: [
//            .system("Bạn là trợ lý hữu ích."),
//            .user("Xin chào!"),
//            .assistant("Chào bạn! Tôi có thể giúp gì?")
//        ])
//    ]
//    @Published var currentConversation: Conversation =
//        Conversation(messages: [.system("Bạn là trợ lý hữu ích. Trả lời ngắn gọn.")])
//
//    @Published var input: String = ""
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//    @Published var systemPrompt: String = "Bạn là trợ lý hữu ích!"
//    @Published var useMock = true
//    @Published var ttsEnabled = false
//
//    private(set) var backend: ChatBackend = MockChatBackend()
//    private let tts = AVSpeechSynthesizer()
//    @AppStorage("openai_api_key") private var apiKey = ""
//
//    func setBackend(_ backend: ChatBackend, useMock: Bool) {
//        self.backend = backend
//        self.useMock = useMock
//    }
//
//    func resetConversation() {
//        tts.stopSpeaking(at: .immediate)
//        currentConversation = Conversation(messages: [.system(systemPrompt)])
//        input = ""
//    }
//
//    func sendUserMessage(_ text: String) {
//        tts.stopSpeaking(at: .word)
//        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//
//        let userMsg = Message.user(trimmed)
//        currentConversation.messages.append(userMsg)
//        input = ""
//        isLoading = true
//
//        backend.streamChat(messages: currentConversation.messages, systemPrompt: systemPrompt) { [weak self] result in
//            guard let self = self else { return }
//            DispatchQueue.main.async {
//                self.isLoading = false
//                switch result {
//                case .success(let reply):
//                    let msg = Message.assistant(reply)
//                    self.currentConversation.messages.append(msg)
//                    self.saveHistory()
//                    if self.ttsEnabled {
//                        self.speak(reply)
//                    }
//                case .failure(let err):
//                    self.errorMessage = err.localizedDescription
//                }
//            }
//        }
//    }
//
//    func speak(_ text: String) {
//        do {
//            let session = AVAudioSession.sharedInstance()
//            try session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
//            try session.setActive(true)
//        } catch {
//            print("AudioSession error: \(error)")
//        }
//        let u = AVSpeechUtterance(string: text)
//        u.voice = AVSpeechSynthesisVoice(language: "vi-VN")
//        u.rate = AVSpeechUtteranceDefaultSpeechRate
//        if tts.isSpeaking {
//            tts.stopSpeaking(at: .word)
//        }
//        tts.speak(u)
//    }
//
//    func deleteConversation(id: UUID) {
//        conversations.removeAll { $0.id == id }
//    }
//
//    func selectConversation(_ convo: Conversation) {
//        tts.stopSpeaking(at: .immediate)
//        currentConversation = convo
//    }
//
//    private func saveHistory() {
//        if let idx = conversations.firstIndex(where: { $0.id == currentConversation.id }) {
//            conversations[idx] = currentConversation
//        } else if currentConversation.messages.count > 1 {
//            conversations.insert(currentConversation, at: 0)
//        }
//    }
//
//    func attachRecognizer(_ sr: SpeechRecognizer) {
//        sr.onFinalTranscription = { [weak self] text in
//            self?.handleVoiceCommand(text)
//        }
//    }
//
//    private func handleVoiceCommand(_ spoken: String) {
//        let cmd = spoken.lowercased()
//        switch true {
//        case cmd.contains("chat mới"), cmd.contains("bắt đầu mới"):
//            resetConversation()
//        case cmd.contains("bật phản hồi âm thanh"), cmd.contains("tts on"):
//            ttsEnabled = true
//        case cmd.contains("tắt phản hồi âm thanh"), cmd.contains("tts off"):
//            ttsEnabled = false
//        case cmd.contains("dùng mock"), cmd.contains("offline"):
//            setBackend(MockChatBackend(), useMock: true)
//        case cmd.contains("dùng real"), cmd.contains("online"):
//            if !apiKey.isEmpty {
//                let real = RealOpenAIBackend(
//                    apiKey: apiKey,
//                    model: systemPrompt, temperature: 0.7, maxTokens: 384
//                )
//                setBackend(real, useMock: false)
//            }
//        default:
//            sendUserMessage(spoken)
//        }
//    }
//}
//
//// MARK: - MAIN VIEW
//
//struct OpenAIChatVoiceDemoEnhanced: View {
//    @StateObject private var store = ChatStore()
//    @StateObject private var speech = SpeechRecognizer()
//    @AppStorage("openai_api_key") private var apiKey = ""
//    @State private var showSettings = false
//    @State private var showHistory  = false
//    @FocusState private var inputFocused: Bool
//
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                header
//                chatScrollView
//                ChatInputBar(
//                    input: $store.input,
//                    speech: speech,
//                    store: store,
//                    focused: _inputFocused
//                )
//            }
//            .navigationTitle("")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { toolbar }
//            .sheet(isPresented: $showSettings) {
//                SettingsSheet(
//                    useMock: $store.useMock,
//                    apiKey: $apiKey,
//                    ttsEnabled: $store.ttsEnabled,
//                    backendSetter: store.setBackend
//                )
//            }
//            .sheet(isPresented: $showHistory) {
//                ProfileSheet(
//                    conversations: $store.conversations,
//                    onDelete: store.deleteConversation(id:),
//                    onSelect: { convo in
//                        store.selectConversation(convo)
//                        showHistory = false
//                    }
//                )
//            }
//            .alert("Lỗi", isPresented: .constant(store.errorMessage != nil)) {
//                Button("OK") { store.errorMessage = nil }
//            } message: {
//                Text(store.errorMessage ?? "")
//            }
//            .onAppear {
//                // Setup backend
//                if !apiKey.isEmpty && !store.useMock {
//                    let real = RealOpenAIBackend(
//                        apiKey: apiKey,
//                        model: store.systemPrompt,
//                        temperature: 0.7,
//                        maxTokens: 384
//                    )
//                    store.setBackend(real, useMock: false)
//                }
//                // Request Vietnamese speech auth
//                speech.requestAuthorization { granted in
//                    if !granted {
//                        print("Cần quyền truy cập micro.")
//                    }
//                }
//                store.attachRecognizer(speech)
//            }
//        }
//    }
//
//    private var header: some View {
//        HStack {
//            Text(store.currentConversation.title)
//                .font(.headline)
//                .lineLimit(1)
//            Spacer()
//            if store.ttsEnabled {
//                Image(systemName: "speaker.wave.2.fill")
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding()
//        .background(.thinMaterial)
//    }
//
//    private var chatScrollView: some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                LazyVStack(spacing: 8) {
//                    ForEach(store.currentConversation.messages.filter { $0.role != .system }) { msg in
//                        MessageBubble(message: msg, own: msg.role == .user)
//                            .id(msg.id)
//                            .contextMenu {
//                                Button("Copy") { UIPasteboard.general.string = msg.content }
//                                Button("Đọc to") { store.speak(msg.content) }
//                                ShareLink(item: msg.content) {
//                                    Label("Chia sẻ", systemImage: "square.and.arrow.up")
//                                }
//                            }
//                    }
//                    if store.isLoading {
//                        ProgressView("Đang xử lý…")
//                            .padding(.top, 10)
//                    }
//                }
//                .padding()
//            }
//            .background(Color(.systemGroupedBackground))
//            .onChange(of: store.currentConversation.messages.last?.id) { _, newId in
//                guard let id = newId else { return }
//                withAnimation {
//                    proxy.scrollTo(id, anchor: .bottom)
//                }
//            }
//        }
//    }
//
//    @ToolbarContentBuilder
//    private var toolbar: some ToolbarContent {
//        ToolbarItem(placement: .navigationBarLeading) {
//            Button { showHistory = true }
//            label: { Label("Lịch sử", systemImage: "clock.arrow.circlepath") }
//        }
//        ToolbarItem(placement: .navigationBarTrailing) {
//            Button { showSettings = true }
//            label: { Label("Cài đặt", systemImage: "gear") }
//        }
//        ToolbarItem(placement: .navigationBarTrailing) {
//            Button { store.resetConversation() }
//            label: { Label("Chat mới", systemImage: "plus.circle") }
//        }
//    }
//}
//
//// MARK: - CHAT INPUT BAR
//
//struct ChatInputBar: View {
//    @Binding var input: String
//    @ObservedObject var speech: SpeechRecognizer
//    @ObservedObject var store: ChatStore
//    @FocusState var focused: Bool
//
//    @GestureState private var isPressing = false
//
//    var body: some View {
//        HStack(spacing: 8) {
//            TextField("Gõ hoặc giữ để nói…", text: $input, axis: .vertical)
//                .focused($focused)
//                .lineLimit(1...5)
//                .padding(10)
//                .background(Color(.secondarySystemBackground))
//                .clipShape(RoundedRectangle(cornerRadius: 18))
//                .overlay(RoundedRectangle(cornerRadius: 18)
//                    .stroke(Color.gray.opacity(0.3), lineWidth: 1))
//                .disabled(store.isLoading)
//
//            micButton
//            sendButton
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//        .background(.thinMaterial)
//        .animation(.easeInOut(duration: 0.2), value: isPressing)
//    }
//
//    private var micButton: some View {
//        let longPress = LongPressGesture(minimumDuration: 0.2)
//            .updating($isPressing) { curr, state, _ in state = curr }
//            .onEnded { _ in
//                speech.stopRecording()
//                if !speech.transcript.isEmpty {
//                    store.sendUserMessage(speech.transcript)
//                }
//            }
//
//        return Image(systemName: speech.isRecording ? "mic.fill" : "mic.circle")
//            .resizable()
//            .frame(width: 28, height: 28)
//            .foregroundColor(speech.isRecording ? .red : .blue)
//            .gesture(
//                longPress.onChanged { _ in
//                    guard !speech.isRecording else { return }
//                    focused = false
//                    speech.requestAuthorization { granted in
//                        if granted {
//                            try? speech.startRecording()
//                        } else {
//                            // Vietnamese fallback
//                            speech.errorMessage = "Cần quyền truy cập micro."
//                        }
//                    }
//                }
//            )
//            .accessibilityLabel(speech.isRecording ? "Thả để gửi" : "Giữ để nói")
//    }
//
//    private var sendButton: some View {
//        Button(action: {
//            let txt = input.trimmingCharacters(in: .whitespacesAndNewlines)
//            if txt.isEmpty { return }
//            store.sendUserMessage(txt)
//            input = ""
//        }) {
//            Image(systemName: "arrow.up.circle.fill")
//                .resizable().frame(width: 28, height: 28)
//                .foregroundColor(input.isEmpty ? .gray.opacity(0.5) : .blue)
//        }
//        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading)
//    }
//}
//
//// MARK: - MESSAGE BUBBLE
//
//struct MessageBubble: View {
//    let message: Message
//    let own: Bool
//
//    var bubbleColor: Color { own ? .blue.opacity(0.2) : .secondary.opacity(0.1) }
//    var textColor: Color   { own ? .blue : .primary }
//
//    var body: some View {
//        HStack {
//            if own { Spacer(minLength: 16) }
//            VStack(alignment: own ? .trailing : .leading, spacing: 4) {
//                HStack(spacing: 4) {
//                    Text(message.role.rawValue.capitalized)
//                        .font(.caption2).foregroundColor(.secondary)
//                    Text(message.timestamp, style: .time)
//                        .font(.caption2).foregroundColor(.secondary)
//                }
//                Text(message.content)
//                    .padding(10)
//                    .background(bubbleColor)
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//                    .foregroundColor(textColor)
//            }
//            if !own { Spacer(minLength: 16) }
//        }
//        .padding(.horizontal, own ? 8 : 16)
//    }
//}
//
//// MARK: - SETTINGS SHEET
//
//struct SettingsSheet: View {
//    @Binding var useMock: Bool
//    @Binding var apiKey: String
//    @Binding var ttsEnabled: Bool
//    @AppStorage("model_name") private var modelName: String = "gpt-4o"
//    @AppStorage("temperature") private var temperature: Double = 0.7
//    @AppStorage("max_tokens") private var maxTokens: Int = 384
//
//    var backendSetter: (ChatBackend, Bool) -> Void
//    let models = ["gpt-4o", "gpt-4", "gpt-3.5-turbo"]
//    @Environment(\.dismiss) var dismiss
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("Tính năng") {
//                    Toggle("Bật phản hồi âm thanh (TTS)", isOn: $ttsEnabled)
//                }
//                Section("Chat Backend") {
//                    Toggle("Dùng Mock (offline)", isOn: $useMock)
//                        .onChange(of: useMock) { _, newValue in updateBackend(useMock: newValue) }
//                }
//                Section("Cấu hình OpenAI") {
//                    Picker("Model", selection: $modelName) {
//                        ForEach(models, id:\.self) { Text($0) }
//                    }.onChange(of: modelName) { _, _ in updateBackend() }
//                    Stepper(value: $temperature, in: 0...1, step: 0.05) {
//                        Text("Nhiệt độ: \(temperature, specifier: "%.2f")")
//                    }.onChange(of: temperature) { _, _ in updateBackend() }
//                    Stepper(value: $maxTokens, in: 64...2048, step: 32) {
//                        Text("Max Tokens: \(maxTokens)")
//                    }.onChange(of: maxTokens) { _, _ in updateBackend() }
//                }
//                if !useMock {
//                    Section("API Key") {
//                        SecureField("OpenAI API Key (sk-...)", text: $apiKey)
//                            .autocapitalization(.none)
//                            .onChange(of: apiKey) { _, _ in updateBackend() }
//                        if apiKey.isEmpty {
//                            Text("🔑 Nhập API key để dùng backend thật.").font(.footnote)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Cài đặt")
//            .toolbar { ToolbarItem(placement:.confirmationAction) {
//                Button("Xong") { dismiss() }
//            } }
//        }
//    }
//
//    private func updateBackend(useMock: Bool? = nil) {
//        let shouldMock = useMock ?? self.useMock
//        if !shouldMock && !apiKey.isEmpty {
//            backendSetter(RealOpenAIBackend(
//                apiKey: apiKey,
//                model: modelName,
//                temperature: temperature,
//                maxTokens: maxTokens
//            ), false)
//        } else {
//            backendSetter(MockChatBackend(), true)
//        }
//    }
//}
//
//// MARK: - HISTORY SHEET
//
//struct ProfileSheet: View {
//    @Binding var conversations: [Conversation]
//    var onDelete: (UUID) -> Void
//    var onSelect: (Conversation) -> Void
//    @Environment(\.dismiss) private var dismiss
//
//    var body: some View {
//        NavigationStack {
//            if conversations.isEmpty {
//                Text("Chưa có chat nào.").padding()
//            } else {
//                List {
//                    ForEach(conversations) { convo in
//                        Button {
//                            onSelect(convo)
//                        } label: {
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(convo.title).font(.headline)
//                                Text(convo.createdAt, style: .date)
//                                    .font(.caption).foregroundColor(.secondary)
//                                Text(convo.messages.last { $0.role == .assistant }?.content ?? "")
//                                    .lineLimit(2).font(.body)
//                            }.padding(.vertical, 4)
//                        }
//                        .buttonStyle(.plain)
//                    }
//                    .onDelete { idx in
//                        idx.map { conversations[$0].id }.forEach(onDelete)
//                    }
//                }
//                .listStyle(.grouped)
//            }
//        }
//        .presentationDetents([.medium, .large])
//        .toolbar {
//            ToolbarItem(placement: .confirmationAction) {
//                Button("Đóng") { dismiss() }
//            }
//        }
//    }
//}
//
//// MARK: - PREVIEW
//
//struct OpenAIChatVoiceDemoEnhanced_Previews: PreviewProvider {
//    static var previews: some View {
//        OpenAIChatVoiceDemoEnhanced()
//            .preferredColorScheme(.light)
//        OpenAIChatVoiceDemoEnhanced()
//            .preferredColorScheme(.dark)
//    }
//}
