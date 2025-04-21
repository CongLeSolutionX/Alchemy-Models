////
////  OpenAIChatAPIDemoView_V6.swift
////  Alchemy_Models
////  AIChatVoiceDemo
////  Created by Cong Le on 4/20/25.
////
////  Single-file, ready-to-run SwiftUI OpenAI chatbot with live speech-to-text input.
////  Enhanced with Real-time Voice Reply from AI Assistant.
////
//
//import SwiftUI
//import Speech
//import AVFoundation // <-- Import AVFoundation for speech synthesis
//
//// MARK: - MODEL & ENUMS
//// ... (Keep existing Message, Conversation, ChatRole enums) ...
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
//        ? (messages.first(where: { $0.role == .user })?.content.prefix(32).description ?? "Chat")
//        : title
//        self.createdAt = createdAt
//    }
//}
//
//// MARK: - BACKEND PROTOCOL
//protocol ChatBackend {
//    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void)
//}
//
//// MARK: - MOCK BACKEND
//// ... (Keep existing MockChatBackend) ...
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
//// MARK: - OPENAI API BACKEND
//// ... (Keep existing RealOpenAIBackend) ...
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
//// ... (Keep existing SpeechRecognizer class) ...
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
//    
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
//// MARK: - VIEWMODEL / STORE (MODIFICATIONS HERE)
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
//    @Published var ttsEnabled: Bool = false // <-- State for TTS toggle
//
//    let tts = AVSpeechSynthesizer() // <-- TTS Engine instance
//    var backend: ChatBackend = MockChatBackend()
//
//    func setBackend(_ backend: ChatBackend, useMock: Bool) {
//        self.backend = backend
//        self.useMock = useMock
//    }
//    func resetConversation() {
//        tts.stopSpeaking(at: .immediate) // Stop any ongoing speech
//        currentConversation = Conversation(messages: [ .system(systemPrompt) ])
//        input = ""
//    }
//    func sendUserMessage(_ msg: String? = nil) {
//        tts.stopSpeaking(at: .word) // Stop previous utterance if user sends new message
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
//                    // --- TTS Integration ---
//                    if self.ttsEnabled { // <-- Check if TTS is enabled
//                        self.speakText(reply)
//                    }
//                    // ---------------------
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
//        tts.stopSpeaking(at: .immediate) // Stop speech when changing conversation
//        currentConversation = convo
//    }
//    func saveCurrentToHistory() {
//        // Prevent duplicate saves if the only change was adding the assistant message
//         if let existingIndex = conversations.firstIndex(where: { $0.id == currentConversation.id }) {
//             // Update existing conversation if it's already in history
//             conversations[existingIndex] = currentConversation
//         } else if currentConversation.messages.count > 1 { // More than just system prompt
//             // Insert new conversation only if it has user interaction
//             conversations.insert(currentConversation, at: 0)
//         }
//    }
//
//    // --- NEW TTS FUNCTION ---
//    func speakText(_ text: String) {
//        // Ensure audio session is active and configured (optional but good practice for reliability)
//         do {
//             try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers]) // Duck other audio
//             try AVAudioSession.sharedInstance().setActive(true)
//         } catch {
//             print("⚠️ Failed to set up audio session: \(error.localizedDescription)")
//             // Handle error appropriately, maybe disable TTS or show a warning
//         }
//
//        // Create and configure utterance
//        let utterance = AVSpeechUtterance(string: text)
//        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // Or dynamically choose based on locale/settings
//        utterance.rate = AVSpeechUtteranceDefaultSpeechRate // Adjust rate if needed
//        utterance.pitchMultiplier = 1.0 // Adjust pitch if needed
//        utterance.volume = 1.0 // Full volume
//
//        // Speak
//        if tts.isSpeaking {
//             tts.stopSpeaking(at: .word) // Stop current utterance smoothly before starting new one
//        }
//        tts.speak(utterance)
//    }
//    // ------------------------
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
//    @FocusState private var isInputBarFocused: Bool
//
//    var body: some View {
//        NavigationStack {
//            mainContentView
//                .navigationTitle("")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar { toolbarContent }
//                .sheet(isPresented: $settingsShown) {
//                    // Pass the ttsEnabled binding to SettingsSheet
//                    SettingsSheet(
//                        useMock: $store.useMock,
//                        apiKey: $apiKey,
//                        ttsEnabled: $store.ttsEnabled, // <-- Pass binding here
//                        backendSetter: store.setBackend
//                    )
//                }
//                .sheet(isPresented: $profileSheetShown) { profileSheetView }
//                .alert("Error", isPresented: .constant(store.errorMessage != nil), actions: {
//                    Button("Dismiss") { store.errorMessage = nil }
//                }, message: {
//                    Text(store.errorMessage ?? "An unknown error occurred.")
//                })
//                .overlay(loadingOverlay)
//                .overlay(alignment: .bottom) { speechErrorOverlay }
//                .onAppear(perform: setupBackendOnAppear)
//        }
//    }
//
//    // --- Other SUB-VIEWS / VIEW BUILDERS ---
//
//    @ViewBuilder
//    private var mainContentView: some View {
//        VStack(spacing: 0) {
//            conversationTitleView
//            messageListView
//            OpenAIChatVoiceDemoView.ChatInputBar( // Ensure you reference the nested struct correctly
//                 input: $store.input,
//                 speech: speech,
//                 store: store,
//                 focused: _isInputBarFocused // Pass FocusState binding correctly
//             )
//        }
//    }
//
//    @ViewBuilder
//    private var conversationTitleView: some View {
//        HStack {
//            Text(store.currentConversation.title)
//                .font(.headline)
//                .lineLimit(1)
//                .accessibilityAddTraits(.isHeader)
//            Spacer()
//            // Optional: Indicate TTS status? e.g., an icon if enabled
//            if store.ttsEnabled {
//                Image(systemName: "speaker.wave.2.fill")
//                    .foregroundColor(.secondary)
//                    .imageScale(.small)
//                    .transition(.opacity.combined(with: .scale))
//            }
//        }
//        .padding(.vertical, 8)
//        .padding(.horizontal)
//        .background(.thinMaterial)
//        .animation(.easeInOut, value: store.ttsEnabled) // Animate the icon appearance
//    }
//
//    @ViewBuilder
//    private var messageListView: some View {
//        ScrollViewReader { scrollProxy in
//            ScrollView {
//                LazyVStack(alignment: .leading, spacing: 8) {
//                    ForEach(store.currentConversation.messages.filter { $0.role != .system }) { msg in // Filter out system messages from view
//                        MessageBubble(message: msg, own: msg.role == .user)
//                            .id(msg.id)
//                            .contextMenu { messageContextMenu(for: msg) }
//                            .onTapGesture { UIPasteboard.general.string = msg.content }
//                    }
//                    if store.isLoading {
//                        ProgressView("Thinking...")
//                            .padding(.top, 10)
//                            .frame(maxWidth: .infinity)
//                    }
//                }
//                .padding(.vertical, 8)
//                .padding(.horizontal, 8)
//            }
//             .onChange(of: store.currentConversation.messages.last?.id) { _, newLastId in // Use new signature
//                 // Scroll when the ID of the *last* message changes
//                 if let idToScroll = newLastId {
//                     // Only scroll if the last message isn't a system message (prevent scrolling on initial load)
//                     if store.currentConversation.messages.last?.role != .system {
//                         withAnimation(.spring()) {
//                             scrollProxy.scrollTo(idToScroll, anchor: .bottom)
//                         }
//                     }
//                 }
//             }
//        }
//        .background(Color(.systemGroupedBackground))
//    }
//
//    @ViewBuilder
//    private func messageContextMenu(for message: Message) -> some View {
//        Button { UIPasteboard.general.string = message.content } label: {
//            Label("Copy", systemImage: "doc.on.doc")
//        }
//        // Always offer read aloud, even if auto-TTS is off
//        Button { store.speakText(message.content) } label: {
//            Label("Read Aloud", systemImage: "speaker.wave.2.fill")
//        }
//        ShareLink(item: message.content) {
//            Label("Share", systemImage: "square.and.arrow.up")
//        }
//    }
//
//    @ToolbarContentBuilder
//    private var toolbarContent: some ToolbarContent {
//        ToolbarItem(placement: .navigationBarLeading) {
//            Button { profileSheetShown = true } label: {
//                Label("History", systemImage: "clock.arrow.circlepath")
//            }
//        }
//        ToolbarItem(placement: .navigationBarTrailing) {
//            Button { settingsShown = true } label: {
//                Label("Settings", systemImage: "gear")
//            }
//        }
//        ToolbarItem(placement: .navigationBarTrailing) {
//            Button { store.resetConversation() } label: {
//                Label("New Chat", systemImage: "plus.circle")
//            }
//            .disabled(store.isLoading)
//        }
//    }
//
//    // SettingsSheet view is now passed ttsEnabled binding
//    @ViewBuilder
//    private var profileSheetView: some View {
//        ProfileSheet(
//            conversations: $store.conversations,
//            onDelete: store.deleteConversation,
//            onSelect: { conversation in
//                store.selectConversation(conversation)
//                // Dismissal is handled within ProfileSheet or automatically
//            }
//        )
//    }
//
//    @ViewBuilder
//    private var loadingOverlay: some View {
//         if store.isLoading {
//             // More subtle loading indication
//             HStack {
//                 Spacer() // Push to center
//                 ProgressView()
//                     .padding(10)
//                     .background(.regularMaterial, in: Circle()) // Use material background
//                     .shadow(radius: 3)
//                 Spacer()
//             }
//             .padding(.top, 40) // Position it down a bit
//             .transition(.opacity)
//             .ignoresSafeArea(.container, edges: .bottom) // Allow interaction below
//             .zIndex(1) // Ensure it's visible
//         }
//     }
//
//    @ViewBuilder
//    private var speechErrorOverlay: some View {
//        if let err = speech.errorMessage {
//            Text(err)
//                .font(.caption)
//                .foregroundColor(.white)
//                .padding(8)
//                .background(Color.red.opacity(0.85))
//                .clipShape(Capsule())
//                .padding(.bottom, 50) // Adjust padding as needed above input bar
//                .transition(.move(edge: .bottom).combined(with: .opacity))
//                .zIndex(1)
//                .onAppear {
//                     DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                         if speech.errorMessage == err { speech.errorMessage = nil }
//                     }
//                 }
//        }
//    }
//
//    private func setupBackendOnAppear() {
//          // Access defaults via AppStorage directly or temporary instance
//          @AppStorage("model_name") var defaultModelName: String = "gpt-4o"
//          @AppStorage("temperature") var defaultTemperature: Double = 0.7
//          @AppStorage("max_tokens") var defaultMaxTokens: Int = 384
//
//          if !apiKey.isEmpty && !store.useMock {
//              store.setBackend(
//                  RealOpenAIBackend(
//                      apiKey: apiKey,
//                      model: defaultModelName,
//                      temperature: defaultTemperature,
//                      maxTokens: defaultMaxTokens
//                  ),
//                  useMock: false
//              )
//          } else {
//              store.setBackend(MockChatBackend(), useMock: true)
//          }
//        
//          speech.requestAuthorization { granted in
//              if !granted { print("Speech recognition permission denied.") }
//          }
//      }
//
//    // --- CHAT INPUT BAR ---
//    struct ChatInputBar: View {
//        @Binding var input: String
//        @ObservedObject var speech: SpeechRecognizer
//        @ObservedObject var store: ChatStore
//        @FocusState var focused: Bool
//
//        private var textFieldBinding: Binding<String> {
//              Binding(
//                  get: { input.isEmpty ? speech.transcript : input },
//                  set: {
//                      input = $0
//                      if !speech.transcript.isEmpty && !$0.isEmpty {
//                          speech.transcript = ""
//                      }
//                  }
//              )
//        }
//        var body: some View {
//             HStack(spacing: 8) {
//                  TextField("Type or use mic…", text: textFieldBinding, axis: .vertical)
//                      .focused($focused)
//                      .lineLimit(1...5)
//                      .padding(10)
//                      .background(Color(.secondarySystemBackground))
//                      .clipShape(RoundedRectangle(cornerRadius: 18))
//                      .overlay(
//                          RoundedRectangle(cornerRadius: 18)
//                              .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                      )
//                      .onSubmit(submit)
//                      .disabled(store.isLoading)
//
//                  micButton
//                  sendButton
//              }
//              .padding(.horizontal, 12)
//              .padding(.vertical, 8)
//              .background(.thinMaterial)
//              .animation(.easeInOut(duration: 0.2), value: speech.isRecording)
//        }
//        private var micButton: some View {
//             Button(action: toggleRecording) {
//                 Image(systemName: speech.isRecording ? "stop.circle.fill" : "mic.circle.fill")
//                     .resizable()
//                     .scaledToFit()
//                     .frame(width: 28, height: 28)
//                     .foregroundStyle(speech.isRecording ? Color.red : Color.blue)
//                     .padding(.vertical, 4)
//                     .contentTransition(.symbolEffect(.replace))
//                     .accessibilityLabel(speech.isRecording ? "Stop Recording" : "Start Voice Input")
//             }
//             .disabled(store.isLoading)
//        }
//        private var sendButton: some View {
//             Button(action: submit) {
//                 Image(systemName: "arrow.up.circle.fill")
//                     .resizable()
//                     .scaledToFit()
//                     .frame(width: 28, height: 28)
//                     .foregroundStyle(canSubmit ? Color.blue : Color.gray.opacity(0.5))
//             }
//             .disabled(!canSubmit || store.isLoading)
//             .keyboardShortcut(.return, modifiers: .command)
//        }
//        private var canSubmit: Bool {
//             !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
//             !speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//        }
//        private func toggleRecording() {
//             focused = false
//              if speech.isRecording {
//                  speech.stopRecording()
//                  if !speech.transcript.isEmpty {
//                      input = speech.transcript
//                      // Optional: Auto-submit after stop
//                       submit()
//                  }
//              } else {
//                  input = ""
//                  speech.requestAuthorization { granted in
//                      if granted {
//                          do { try speech.startRecording() }
//                          catch { speech.errorMessage = "Failed to start recording: \(error.localizedDescription)" }
//                      } else {
//                          speech.errorMessage = "Speech recognition permission needed."
//                      }
//                  }
//              }
//        }
//        private func submit() {
//             let textToSend = input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//              ? speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
//              : input.trimmingCharacters(in: .whitespacesAndNewlines)
//
//              if !textToSend.isEmpty {
//                  store.sendUserMessage(textToSend)
//              }
//              input = ""
//              speech.transcript = ""
//              if speech.isRecording { speech.stopRecording() }
//              focused = false
//        }
//    }
//}
//
//// MARK: - MESSAGE BUBBLE
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
//// MARK: - SETTINGS SHEET (MODIFICATIONS HERE)
//
//struct SettingsSheet: View {
//    // Receive bindings from the parent view
//    @Binding var useMock: Bool
//    @Binding var apiKey: String
//    @Binding var ttsEnabled: Bool // <-- Receive TTS toggle binding
//
//    // Keep internal @AppStorage for local persistence of these settings
//    @AppStorage("model_name") private var modelName: String = "gpt-4o"
//    @AppStorage("temperature") private var temperature: Double = 0.7
//    @AppStorage("max_tokens") private var maxTokens: Int = 384
//
//    var backendSetter: (ChatBackend, Bool) -> Void
//
//    let models = ["gpt-4o", "gpt-4", "gpt-3.5-turbo"]
//    @Environment(\.dismiss) var dismiss
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("Features") { // New section for features
//                    Toggle("Enable Voice Reply (TTS)", isOn: $ttsEnabled) // <-- Toggle for TTS
//                }
//
//                Section("Chat Backend") {
//                    Toggle("Use Mock (offline, for play/testing)", isOn: $useMock)
//                        .onChange(of: useMock) { _, newValue in // Use new signature
//                            updateBackend(useMock: newValue)
//                        }
//                }
//                Section("OpenAI Configuration") {
//                    Picker("Model", selection: $modelName) {
//                        ForEach(models, id:\.self) { Text($0) }
//                    }
//                    .onChange(of: modelName) { _, _ in updateBackend() } // Update on change
//
//                    Stepper(value: $temperature, in: 0...1, step: 0.05) {
//                        Text("Temperature: \(temperature, specifier: "%.2f")")
//                    }
//                    .onChange(of: temperature) { _, _ in updateBackend() } // Update on change
//
//                    Stepper(value: $maxTokens, in: 64...2048, step: 32) {
//                        Text("Max Tokens: \(maxTokens)")
//                    }
//                     .onChange(of: maxTokens) { _, _ in updateBackend() } // Update on change
//                }
//                if !useMock {
//                    Section("API Key") {
//                        SecureField("OpenAI API Key (sk-...)", text: $apiKey)
//                            .autocapitalization(.none)
//                            .onChange(of: apiKey) { _, _ in updateBackend() } // Update on change
//
//                        if apiKey.isEmpty {
//                            Text("🔑 Enter your OpenAI API key to use Real backend.").font(.footnote)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Settings")
//            .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } }
//             // Removed individual .onChange handlers, combined into updateBackend
//        }
//    }
//
//    // Helper function to update backend based on current settings
//    private func updateBackend(useMock: Bool? = nil) {
//         let shouldUseMock = useMock ?? self.useMock // Use passed value or current state
//         // Only update Real backend if not using mock and API key is present
//         if !shouldUseMock && !apiKey.isEmpty {
//             backendSetter(RealOpenAIBackend(
//                 apiKey: apiKey,
//                 model: modelName,
//                 temperature: temperature,
//                 maxTokens: maxTokens
//             ), false)
//         } else if shouldUseMock {
//             // Ensure mock is set correctly if toggled or if API key is missing
//             backendSetter(MockChatBackend(), true)
//         }
//         // Note: If useMock is false but apiKey is empty, backendSetter won't be called here.
//         // This implicitly keeps the existing backend (which might be Mock). Consider explicitly
//         // setting to Mock if apiKey becomes empty while useMock is false if desired.
//     }
//}
//
//// MARK: - PROFILE SHEET (History)
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
//                                    Text((conv.messages.last{ $0.role == .assistant }?.content ?? // Show last assistant message
//                                          conv.messages.first{ $0.role == .user }?.content ?? "").prefix(64))
//                                        .font(.body)
//                                        .foregroundColor(.primary)
//                                        .lineLimit(2) // Allow two lines for preview
//                                }
//                                .frame(maxWidth:.infinity, alignment:.leading)
//                                .padding(.vertical, 4)
//                            }
//                             .buttonStyle(.plain) // Use plain style for better tap handling in List
//                        }
//                    }
//                     .onDelete { idx in
//                         idx.map { conversations[$0].id }.forEach(onDelete)
//                     }
//                }
//                 .listStyle(.grouped) // Use grouped style for sections
//            }
//            //.navigationTitle("Chat History") // Added title
////            .toolbar {
////                 ToolbarItem(placement: .navigationBarLeading) { EditButton() } // Add standard Edit button
////                 ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
////             }
//        }
//        .presentationDetents([.medium, .large]) // Allow medium and large detents
//    }
//}
//
//// MARK: - PREVIEW
//struct OpenAIChatVoiceDemoView_Previews: PreviewProvider {
//    static var previews: some View {
//        OpenAIChatVoiceDemoView()
//            .preferredColorScheme(.dark)
//        OpenAIChatVoiceDemoView()
//            .preferredColorScheme(.light)
//    }
//}
