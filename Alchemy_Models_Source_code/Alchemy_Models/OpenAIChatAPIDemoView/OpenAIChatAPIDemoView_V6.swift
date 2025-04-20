////
////  OpenAIChatAPIDemoView_V6.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIChatVoiceDemoView.swift
////  AIChatVoiceDemo
////
////  Created by Assistant on 2024/06/08.
////  Single-file, ready-to-run SwiftUI OpenAI chatbot with live speech-to-text input.
////
//
//import SwiftUI
//import Speech
//import AVFoundation
//
//// MARK: - MODEL & ENUMS
//
//enum ChatRole: String, Codable, CaseIterable {
//    case system, user, assistant
//}
//struct Message: Identifiable, Codable, Hashable {
//    let id: UUID
//    let role: ChatRole
//    let content: String
//    let timestamp: Date
//    
//    init(role: ChatRole, content: String, timestamp: Date = .now, id: UUID = UUID()) {
//        self.id = id
//        self.role = role
//        self.content = content
//        self.timestamp = timestamp
//    }
//    static func system(_ text: String) -> Message { .init(role: .system, content: text) }
//    static func user(_ text: String) -> Message { .init(role: .user, content: text) }
//    static func assistant(_ text: String) -> Message { .init(role: .assistant, content: text) }
//}
//struct Conversation: Identifiable, Codable, Hashable {
//    let id: UUID
//    var messages: [Message]
//    var title: String
//    var createdAt: Date
//    init(messages: [Message], title: String = "", createdAt: Date = .now, id: UUID = UUID()) {
//        self.id = id
//        self.messages = messages
//        self.title = title.isEmpty
//            ? (messages.first(where: { $0.role == .user })?.content.prefix(32).description ?? "Chat")
//            : title
//        self.createdAt = createdAt
//    }
//}
//
//// MARK: - BACKEND PROTOCOL
//
//protocol ChatBackend {
//    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void)
//}
//
//// MARK: - MOCK BACKEND
//
//struct MockChatBackend: ChatBackend {
//    let replies = [
//        "Absolutely! Here's an example for you.",
//        "That's an intriguing question. Let's break it down.",
//        "I'm your AI assistant -- how can I help further?",
//        "Let me pull up some suggestions.",
//        "Here's what I found!",
//        "Sure thing! Ready when you are."
//    ]
//    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            completion(.success(self.replies.randomElement() ?? "Sorry, can you rephrase that?"))
//        }
//    }
//}
//
//// MARK: - OPENAI API BACKEND (non-streaming for simplicity, add streaming if desired)
//
//final class RealOpenAIBackend: ChatBackend {
//    let apiKey: String
//    let model: String
//    let temperature: Double
//    let maxTokens: Int
//    init(apiKey: String, model: String, temperature: Double, maxTokens: Int) {
//        self.apiKey = apiKey
//        self.model = model
//        self.temperature = temperature
//        self.maxTokens = maxTokens
//    }
//    
//    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void) {
//        var fullMessages = messages
//        if !systemPrompt.isEmpty {
//            fullMessages.insert(.system(systemPrompt), at: 0)
//        }
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            completion(.failure(NSError(domain: "InvalidURL", code: 1)))
//            return
//        }
//        var req = URLRequest(url: url)
//        req.httpMethod = "POST"
//        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        struct ReqPayload: Encodable {
//            let model: String
//            let messages: [[String: String]]
//            let temperature: Double
//            let max_tokens: Int
//        }
//        let payload = ReqPayload(
//            model: model,
//            messages: fullMessages.map { ["role": $0.role.rawValue, "content": $0.content] },
//            temperature: temperature,
//            max_tokens: maxTokens
//        )
//        do { req.httpBody = try JSONEncoder().encode(payload) }
//        catch { completion(.failure(error)); return }
//        
//        URLSession.shared.dataTask(with: req) { data, resp, error in
//            if let error = error { completion(.failure(error)); return }
//            guard let data = data else { completion(.failure(NSError(domain: "NoData", code: 2))); return }
//            do {
//                struct Model: Decodable {
//                    struct Choice: Decodable { let message: MessageContent }
//                    struct MessageContent: Decodable { let role: String; let content: String }
//                    let choices: [Choice]
//                }
//                let obj = try JSONDecoder().decode(Model.self, from: data)
//                let reply = obj.choices.first?.message.content ?? "No response"
//                completion(.success(reply))
//            } catch { completion(.failure(error)) }
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
//    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
//    private var recognitionTask: SFSpeechRecognitionTask?
//    private let audioEngine = AVAudioEngine()
//    
//    func requestAuthorization(completion: @escaping (Bool) -> Void) {
//        SFSpeechRecognizer.requestAuthorization { status in
//            DispatchQueue.main.async {
//                completion(status == .authorized)
//            }
//        }
//    }
//    func startRecording() throws {
//        errorMessage = nil
//        transcript = ""
//        isRecording = true
//        
//        if audioEngine.isRunning {
//            audioEngine.stop(); recognitionTask?.cancel()
//        }
//        let node = audioEngine.inputNode
//        let recordingFormat = node.outputFormat(forBus: 0)
//        node.removeTap(onBus: 0)
//        let request = SFSpeechAudioBufferRecognitionRequest()
//        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
//            guard let self else { return }
//            if let result = result { self.transcript = result.bestTranscription.formattedString }
//            if let error = error {
//                self.errorMessage = error.localizedDescription
//                self.stopRecording()
//            }
//        }
//        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//            request.append(buffer)
//        }
//        audioEngine.prepare()
//        try audioEngine.start()
//    }
//    func stopRecording() {
//        if audioEngine.isRunning {
//            audioEngine.stop()
//            audioEngine.inputNode.removeTap(onBus: 0)
//        }
//        recognitionTask?.cancel()
//        recognitionTask = nil
//        isRecording = false
//    }
//}
//
//// MARK: - VIEWMODEL / STORE
//
//@MainActor
//final class ChatStore: ObservableObject {
//    @Published var conversations: [Conversation] = [
//        Conversation(messages: [.system("You are a helpful assistant!"), .user("Hello!"), .assistant("Hello! How can I help you today?")])
//    ]
//    @Published var currentConversation: Conversation = Conversation(messages: [ .system("You are a helpful assistant. Please answer concisely.") ])
//    @Published var input: String = ""
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//    @Published var systemPrompt: String = "You are a helpful assistant!"
//    @Published var useMock: Bool = true
//    @Published var ttsEnabled: Bool = false
//    
//    let tts = AVSpeechSynthesizer()
//    var backend: ChatBackend = MockChatBackend()
//    
//    func setBackend(_ backend: ChatBackend, useMock: Bool) {
//        self.backend = backend
//        self.useMock = useMock
//    }
//    func resetConversation() {
//        currentConversation = Conversation(messages: [ .system(systemPrompt) ])
//        input = ""
//    }
//    func sendUserMessage(_ msg: String? = nil) {
//        let text = msg ?? input.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !text.isEmpty else { return }
//        let userMsg = Message.user(text)
//        currentConversation.messages.append(userMsg)
//        input = ""
//        isLoading = true
//        backend.streamChat(messages: currentConversation.messages, systemPrompt: systemPrompt) { [weak self] result in
//            DispatchQueue.main.async {
//                guard let self else { return }
//                switch result {
//                case .success(let reply):
//                    let assistantMsg = Message.assistant(reply)
//                    self.currentConversation.messages.append(assistantMsg)
//                    self.isLoading = false
//                    self.saveCurrentToHistory()
//                    if self.ttsEnabled { self.speakText(reply) }
//                case .failure(let error):
//                    self.errorMessage = error.localizedDescription
//                    self.isLoading = false
//                }
//            }
//        }
//    }
//    func deleteConversation(_ id: UUID) {
//        conversations.removeAll { $0.id == id }
//    }
//    func selectConversation(_ convo: Conversation) {
//        currentConversation = convo
//    }
//    func saveCurrentToHistory() {
//        if !conversations.contains(where: { $0.messages == currentConversation.messages }) &&
//            currentConversation.messages.count > 1 {
//            conversations.insert(currentConversation, at: 0)
//        }
//    }
//    func speakText(_ text: String) {
//        let u = AVSpeechUtterance(string: text)
//        u.voice = .init(language: "en-US")
//        tts.speak(u)
//    }
//}
//
//// MARK: - MAIN VIEW
//
//struct OpenAIChatVoiceDemoView: View {
//    @StateObject private var store = ChatStore()
//    @StateObject private var speech = SpeechRecognizer()
//    @AppStorage("openai_api_key") private var apiKey: String = ""
//    @State private var settingsShown = false
//    @State private var profileSheetShown = false
//    @FocusState private var focused: Bool
//    
//    var body: some View {
//        Text("OpenAIChatVoiceDemoView")
//    }
//    
////    var body: some View {
////        NavigationStack {
////            VStack(spacing: 0) {
////                // Conversation title
////                HStack {
////                    Text(store.currentConversation.title)
////                        .font(.title3.bold())
////                        .accessibilityAddTraits(.isHeader)
////                    Spacer()
////                }
////                .padding(.vertical, 4).padding(.horizontal, 16)
////                
////                // Message list
////                ScrollViewReader { scrollProxy in
////                    ScrollView {
////                        VStack(alignment:.leading, spacing: 6) {
////                            ForEach(store.currentConversation.messages) { msg in
////                                MessageBubble(message: msg, own: msg.role == .user)
////                                    .id(msg.id)
////                                    .contextMenu {
////                                        Button("Copy") { UIPasteboard.general.string = msg.content }
////                                        Button("Read Aloud") { store.speakText(msg.content) }
////                                        ShareLink(item: msg.content)
////                                    }
////                                    .onTapGesture { UIPasteboard.general.string = msg.content }
////                            }
////                            if store.isLoading {
////                                ProgressView("Thinking...").padding(.horizontal)
////                            }
////                        }
////                        .padding(.vertical, 8)
////                        .onChange(of: store.currentConversation.messages.count) { _ in
////                            withAnimation { scrollProxy.scrollTo(store.currentConversation.messages.last?.id, anchor: .bottom) }
////                        }
////                    }
////                }
////                // Input bar with voice
////                ChatInputBar(
////                    input: $store.input,
////                    speech: speech,
////                    store: store,
////                    focused: $focused
////                )
////            }
////            .toolbar {
////                ToolbarItem(placement:.navigationBarLeading) {
////                    Button { profileSheetShown = true }
////                        label: { Label("History", systemImage: "clock.arrow.circlepath") }
////                }
////                ToolbarItem(placement:.navigationBarTrailing) {
////                    Button { settingsShown = true }
////                        label: { Label("Settings", systemImage: "gear") }
////                }
////            }
////            .sheet(isPresented: $settingsShown) {
////                SettingsSheet(
////                    useMock: $store.useMock,
////                    apiKey: $apiKey,
////                    backendSetter: { backend, useMock in
////                        store.setBackend(backend, useMock: useMock)
////                    }
////                )
////            }
////            .sheet(isPresented: $profileSheetShown) {
////                ProfileSheet(
////                    conversations: $store.conversations,
////                    onDelete: store.deleteConversation,
////                    onSelect: store.selectConversation
////                )
////            }
////            .alert(isPresented: .constant(store.errorMessage != nil)) {
////                Alert(title: Text("Error"), message: Text(store.errorMessage ?? ""), dismissButton: .default(Text("Dismiss"), action: {
////                    store.errorMessage = nil
////                }))
////            }
////            .overlay(
////                store.isLoading ? Color.black.opacity(0.10).ignoresSafeArea() : nil
////            )
////            .overlay(
////                // Speech errors
////                Group {
////                    if let err = speech.errorMessage {
////                        VStack { Spacer()
////                            Text(err)
////                                .font(.headline)
////                                .foregroundColor(.white)
////                                .padding()
////                                .background(Color.red.opacity(0.9))
////                                .cornerRadius(10)
////                                .padding()
////                        }
////                        .transition(.move(edge: .bottom))
////                        .zIndex(99)
////                    }
////                }
////            )
////        }
////        .onAppear {
////            if !apiKey.isEmpty && !store.useMock {
////                store.setBackend(
////                    RealOpenAIBackend(apiKey: apiKey, model: "gpt-4o", temperature: 0.7, maxTokens: 384),
////                    useMock: false
////                )
////            }
////        }
////    }
//    
//    // MARK: - InputBar wrapper (so Preview is tidy)
//    private struct ChatInputBar: View {
//        @Binding var input: String
//        @ObservedObject var speech: SpeechRecognizer
//        @ObservedObject var store: ChatStore
//        @FocusState var focused: Bool
//        var body: some View {
//            HStack(spacing: 10) {
//                // Editable field: either .input or live transcript if input is empty
//                TextField("Type or use mic…",
//                    text: Binding(
//                        get: { input.isEmpty ? speech.transcript : input },
//                        set: { input = $0 }
//                    ),
//                    axis: .vertical
//                )
//                .focused($focused)
//                .autocorrectionDisabled()
//                .font(.body)
//                .disabled(store.isLoading)
//                .onSubmit {
//                    //submit()
//                }
//                .padding(6)
//                .background(
//                    RoundedRectangle(cornerRadius: 5)
//                        .stroke(Color.gray.opacity(0.2))
//                )
//                // MIC
//                Button(action: {
//                    if speech.isRecording {
//                        speech.stopRecording()
//                        if !speech.transcript.isEmpty {
//                            input = speech.transcript
//                            //submit()
//                            speech.transcript = ""
//                        }
//                    } else {
//                        speech.requestAuthorization { granted in
//                            if granted {
//                                do { try speech.startRecording() }
//                                catch { speech.errorMessage = error.localizedDescription }
//                            } else {
//                                speech.errorMessage = "Speech recognition not authorized."
//                            }
//                        }
//                    }
//                    focused = false
//                }) {
//                    Image(systemName: speech.isRecording ? "mic.fill" : "mic")
//                        .foregroundColor(speech.isRecording ? .red : .primary)
//                        .font(.system(size: 24))
//                        .scaleEffect(speech.isRecording ? 1.15 : 1.0)
//                        .accessibilityLabel(speech.isRecording ? "Stop Recording" : "Start Voice Input")
//                }
//                .padding(.horizontal, 4)
//                // SEND
//                Button {
//                    //submit()
//                } label: {
//                    Image(systemName: "paperplane.fill")
//                        .foregroundColor(
//                            (input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && speech.transcript.isEmpty) || store.isLoading
//                            ? .gray
//                            : .blue
//                        )
//                        .font(.system(size: 22))
//                }
//                .disabled(
//                    (input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && speech.transcript.isEmpty)
//                    || store.isLoading
//                )
//            }
//            .padding(8)
//            .background(.background)
//            .overlay(Divider(), alignment: .top)
//            
////            func submit() {
////                let sendText = input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
////                    ? speech.transcript
////                    : input
////                if !sendText.isEmpty { store.sendUserMessage(sendText) }
////                input = ""; speech.transcript = ""; focused = false
////            }
//        }
//    }
//}
//
//// MARK: - MESSAGE BUBBLE
//
//struct MessageBubble: View {
//    let message: Message
//    let own: Bool
//    var bubbleColor: Color { own ? .blue.opacity(0.16) : .secondary.opacity(0.09) }
//    var textColor: Color { own ? .blue : .primary }
//    var body: some View {
//        HStack(alignment: .bottom) {
//            if own { Spacer(minLength: 16) }
//            VStack(alignment: own ? .trailing : .leading, spacing: 2) {
//                HStack(spacing: 4) {
//                    Text(message.role.rawValue.capitalized)
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                    Text(message.timestamp, style: .time)
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                }
//                Text(message.content)
//                    .font(.body)
//                    .padding(10)
//                    .background(bubbleColor)
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//                    .foregroundColor(textColor)
//            }
//            if !own { Spacer(minLength: 16) }
//        }
//        .padding(.horizontal, own ? 8 : 16)
//        .padding(.vertical, 2)
//    }
//}
//
//// MARK: - SETTINGS SHEET
//
//struct SettingsSheet: View {
//    @Binding var useMock: Bool
//    @Binding var apiKey: String
//    @AppStorage("model_name") private var modelName: String = "gpt-4o"
//    @AppStorage("temperature") private var temperature: Double = 0.7
//    @AppStorage("max_tokens") private var maxTokens: Int = 384
//    var backendSetter: (ChatBackend, Bool) -> Void
//    
//    let models = ["gpt-4o", "gpt-4", "gpt-3.5-turbo"]
//    @Environment(\.dismiss) var dismiss
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("Chat Backend") {
//                    Toggle("Use Mock (offline, for play/testing)", isOn: $useMock)
//                        .onChange(of: useMock) { useMock in
//                            backendSetter(useMock ? MockChatBackend() : RealOpenAIBackend(apiKey: apiKey, model: modelName, temperature: temperature, maxTokens: maxTokens), useMock)
//                        }
//                }
//                Section("OpenAI Configuration") {
//                    Picker("Model", selection: $modelName) {
//                        ForEach(models, id:\.self) { Text($0) }
//                    }
//                    Stepper(value: $temperature, in: 0...1, step: 0.05) {
//                        Text("Temperature: \(temperature, specifier: "%.2f")")
//                    }
//                    Stepper(value: $maxTokens, in: 64...2048, step: 32) {
//                        Text("Max Tokens: \(maxTokens)")
//                    }
//                }
//                if !useMock {
//                    Section("API Key") {
//                        SecureField("OpenAI API Key (sk-...)", text: $apiKey)
//                            .autocapitalization(.none)
//                        if apiKey.isEmpty {
//                            Text("🔑 Enter your OpenAI API key to use Real backend.").font(.footnote)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Settings")
//            .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } }
//            .onChange(of: apiKey) { newKey in
//                if !useMock && !newKey.isEmpty {
//                    backendSetter(RealOpenAIBackend(apiKey: newKey, model: modelName, temperature: temperature, maxTokens: maxTokens), false)
//                }
//            }
//            .onChange(of: modelName) { newModel in
//                if !useMock && !apiKey.isEmpty {
//                    backendSetter(RealOpenAIBackend(apiKey: apiKey, model: newModel, temperature: temperature, maxTokens: maxTokens), false)
//                }
//            }
//            .onChange(of: temperature) { newT in
//                if !useMock && !apiKey.isEmpty {
//                    backendSetter(RealOpenAIBackend(apiKey: apiKey, model: modelName, temperature: newT, maxTokens: maxTokens), false)
//                }
//            }
//            .onChange(of: maxTokens) { newMax in
//                if !useMock && !apiKey.isEmpty {
//                    backendSetter(RealOpenAIBackend(apiKey: apiKey, model: modelName, temperature: temperature, maxTokens: newMax), false)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - PROFILE SHEET (History)
//
//struct ProfileSheet: View {
//    @Binding var conversations: [Conversation]
//    var onDelete: (UUID) -> Void
//    var onSelect: (Conversation) -> Void
//    @Environment(\.dismiss) var dismiss
//    var body: some View {
//        NavigationStack {
//            if conversations.isEmpty {
//                Text("No previous chats.")
//                    .padding(.top, 80)
//            } else {
//                List {
//                    ForEach(conversations) { conv in
//                        Section {
//                            Button {
//                                onSelect(conv)
//                                dismiss()
//                            } label: {
//                                VStack(alignment:.leading, spacing: 2) {
//                                    Text(conv.title)
//                                        .font(.headline)
//                                    Text(conv.createdAt, style:.date)
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
//                                    Text((conv.messages.first{ $0.role == .user }?.content ?? "").prefix(64))
//                                        .font(.body)
//                                        .foregroundColor(.primary)
//                                }
//                                .frame(maxWidth:.infinity, alignment:.leading)
//                                .padding(.vertical, 4)
//                            }
//                        }
//                    }
//                    .onDelete { idx in
//                        idx.map { conversations[$0].id }.forEach(onDelete)
//                    }
//                }
//            }
//        }
//        .presentationDetents([.large])
//    }
//}
//
//// MARK: - PREVIEW
//
//struct OpenAIChatVoiceDemoView_Previews: PreviewProvider {
//    static var previews: some View {
//        OpenAIChatVoiceDemoView()
//    }
//}
