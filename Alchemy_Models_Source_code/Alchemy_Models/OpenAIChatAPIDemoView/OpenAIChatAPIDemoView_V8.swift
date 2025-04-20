//
//  OpenAIChatAPIDemoView_V6.swift
//  Alchemy_Models
//  AIChatVoiceDemo
//  Created by Cong Le on 4/20/25.
//

//  AIChatVoiceDemo
//
//  Single-file, ready-to-run SwiftUI OpenAI chatbot with live speech-to-text input.
//

import SwiftUI
import Speech
import AVFoundation

// MARK: - MODEL & ENUMS

enum ChatRole: String, Codable, CaseIterable {
    case system, user, assistant
}
struct Message: Identifiable, Codable, Hashable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date
    
    init(role: ChatRole, content: String, timestamp: Date = .now, id: UUID = UUID()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
    static func system(_ text: String) -> Message { .init(role: .system, content: text) }
    static func user(_ text: String) -> Message { .init(role: .user, content: text) }
    static func assistant(_ text: String) -> Message { .init(role: .assistant, content: text) }
}
struct Conversation: Identifiable, Codable, Hashable {
    let id: UUID
    var messages: [Message]
    var title: String
    var createdAt: Date
    init(messages: [Message], title: String = "", createdAt: Date = .now, id: UUID = UUID()) {
        self.id = id
        self.messages = messages
        self.title = title.isEmpty
        ? (messages.first(where: { $0.role == .user })?.content.prefix(32).description ?? "Chat")
        : title
        self.createdAt = createdAt
    }
}

// MARK: - BACKEND PROTOCOL

protocol ChatBackend {
    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void)
}

// MARK: - MOCK BACKEND

struct MockChatBackend: ChatBackend {
    let replies = [
        "Absolutely! Here's an example for you.",
        "That's an intriguing question. Let's break it down.",
        "I'm your AI assistant -- how can I help further?",
        "Let me pull up some suggestions.",
        "Here's what I found!",
        "Sure thing! Ready when you are."
    ]
    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(.success(self.replies.randomElement() ?? "Sorry, can you rephrase that?"))
        }
    }
}

// MARK: - OPENAI API BACKEND (non-streaming for simplicity, add streaming if desired)

final class RealOpenAIBackend: ChatBackend {
    let apiKey: String
    let model: String
    let temperature: Double
    let maxTokens: Int
    init(apiKey: String, model: String, temperature: Double, maxTokens: Int) {
        self.apiKey = apiKey
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
    
    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        var fullMessages = messages
        if !systemPrompt.isEmpty {
            fullMessages.insert(.system(systemPrompt), at: 0)
        }
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "InvalidURL", code: 1)))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        struct ReqPayload: Encodable {
            let model: String
            let messages: [[String: String]]
            let temperature: Double
            let max_tokens: Int
        }
        let payload = ReqPayload(
            model: model,
            messages: fullMessages.map { ["role": $0.role.rawValue, "content": $0.content] },
            temperature: temperature,
            max_tokens: maxTokens
        )
        do { req.httpBody = try JSONEncoder().encode(payload) }
        catch { completion(.failure(error)); return }
        
        URLSession.shared.dataTask(with: req) { data, resp, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "NoData", code: 2))); return }
            do {
                struct Model: Decodable {
                    struct Choice: Decodable { let message: MessageContent }
                    struct MessageContent: Decodable { let role: String; let content: String }
                    let choices: [Choice]
                }
                let obj = try JSONDecoder().decode(Model.self, from: data)
                let reply = obj.choices.first?.message.content ?? "No response"
                completion(.success(reply))
            } catch { completion(.failure(error)) }
        }.resume()
    }
}

// MARK: - SPEECH RECOGNIZER

final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    func startRecording() throws {
        errorMessage = nil
        transcript = ""
        isRecording = true
        
        if audioEngine.isRunning {
            audioEngine.stop(); recognitionTask?.cancel()
        }
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.removeTap(onBus: 0)
        let request = SFSpeechAudioBufferRecognitionRequest()
        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result = result { self.transcript = result.bestTranscription.formattedString }
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.stopRecording()
            }
        }
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }
}

// MARK: - VIEWMODEL / STORE

@MainActor
final class ChatStore: ObservableObject {
    @Published var conversations: [Conversation] = [
        Conversation(messages: [.system("You are a helpful assistant!"), .user("Hello!"), .assistant("Hello! How can I help you today?")])
    ]
    @Published var currentConversation: Conversation = Conversation(messages: [ .system("You are a helpful assistant. Please answer concisely.") ])
    @Published var input: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var systemPrompt: String = "You are a helpful assistant!"
    @Published var useMock: Bool = true
    @Published var ttsEnabled: Bool = false
    
    let tts = AVSpeechSynthesizer()
    var backend: ChatBackend = MockChatBackend()
    
    func setBackend(_ backend: ChatBackend, useMock: Bool) {
        self.backend = backend
        self.useMock = useMock
    }
    func resetConversation() {
        currentConversation = Conversation(messages: [ .system(systemPrompt) ])
        input = ""
    }
    func sendUserMessage(_ msg: String? = nil) {
        let text = msg ?? input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let userMsg = Message.user(text)
        currentConversation.messages.append(userMsg)
        input = ""
        isLoading = true
        backend.streamChat(messages: currentConversation.messages, systemPrompt: systemPrompt) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let reply):
                    let assistantMsg = Message.assistant(reply)
                    self.currentConversation.messages.append(assistantMsg)
                    self.isLoading = false
                    self.saveCurrentToHistory()
                    if self.ttsEnabled { self.speakText(reply) }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
    }
    func selectConversation(_ convo: Conversation) {
        currentConversation = convo
    }
    func saveCurrentToHistory() {
        if !conversations.contains(where: { $0.messages == currentConversation.messages }) &&
            currentConversation.messages.count > 1 {
            conversations.insert(currentConversation, at: 0)
        }
    }
    func speakText(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.voice = .init(language: "en-US")
        tts.speak(u)
    }
}

// MARK: - MAIN VIEW

struct OpenAIChatVoiceDemoView: View {
    @StateObject private var store = ChatStore()
    @StateObject private var speech = SpeechRecognizer()
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @State private var settingsShown = false
    @State private var profileSheetShown = false
    @FocusState private var isInputBarFocused: Bool // Renamed for clarity
    
    // --- BODY ---
    var body: some View {
        NavigationStack {
            mainContentView
                .navigationTitle("") // Title is handled inside mainContentView or a subview
                .navigationBarTitleDisplayMode(.inline) // Often preferred with custom title views
                .toolbar { toolbarContent } // Use @ToolbarContentBuilder
                .sheet(isPresented: $settingsShown) { settingsSheetView }
                .sheet(isPresented: $profileSheetShown) { profileSheetView }
                .alert("Error", isPresented: .constant(store.errorMessage != nil), actions: {
                    Button("Dismiss") { store.errorMessage = nil }
                }, message: {
                    Text(store.errorMessage ?? "An unknown error occurred.")
                })
                .overlay(loadingOverlay)
                .overlay(alignment: .bottom) { speechErrorOverlay } // Align speech error to bottom
                .onAppear(perform: setupBackendOnAppear)
        }
    }
    
    // --- SUB-VIEWS / VIEW BUILDERS ---
    
    /// The main vertical stack containing title, messages, and input bar.
    @ViewBuilder
    private var mainContentView: some View {
        VStack(spacing: 0) {
            conversationTitleView
            messageListView
            ChatInputBar(
                input: $store.input,
                speech: speech,
                store: store
                //focused: $isInputBarFocused // Pass the FocusState binding
            )
        }
    }
    
    /// Displays the current conversation's title.
    @ViewBuilder
    private var conversationTitleView: some View {
        HStack {
            Text(store.currentConversation.title)
                .font(.headline) // Adjusted font slightly for common practice
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            // Optional: Add an Edit button for the title if needed
            // Button { /* Edit title action */ } label: { Image(systemName: "pencil") }
        }
        .padding(.vertical, 8) // Adjusted padding
        .padding(.horizontal)
        .background(.thinMaterial) // Add a subtle background
        // Consider adding a Divider() below if desired
    }
    
    /// The scrollable list displaying messages.
    @ViewBuilder
    private var messageListView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) { // Use LazyVStack for performance
                    ForEach(store.currentConversation.messages) { msg in
                        MessageBubble(message: msg, own: msg.role == .user)
                            .id(msg.id) // Ensure ID is unique and stable
                            .contextMenu { messageContextMenu(for: msg) }
                            .onTapGesture { UIPasteboard.general.string = msg.content } // Keep simple tap for copy
                    }
                    if store.isLoading {
                        ProgressView("Thinking...")
                            .padding(.top, 10)
                            .frame(maxWidth: .infinity) // Center the progress view
                    }
                }
                .padding(.vertical, 8) // Add padding inside ScrollView
                .padding(.horizontal, 8) // Reduce horizontal padding slightly
            }
            .onChange(of: store.currentConversation.messages.last?.id) {
                let newLastId = store.currentConversation.messages.last?.id
                // Scroll when the ID of the *last* message changes
                if let idToScroll = newLastId {
                    withAnimation(.spring()) { // Smoother animation
                        scrollProxy.scrollTo(idToScroll, anchor: .bottom)
                    }
                }
            }
            // Removed .onChange(of: store.currentConversation.messages.count)
            // as onChange(of: last.id) is often more reliable for auto-scrolling
        }
        .background(Color(.systemGroupedBackground)) // Give the scroll area a subtle background
    }
    
    /// Context menu items for a message bubble.
    @ViewBuilder
    private func messageContextMenu(for message: Message) -> some View {
        Button { UIPasteboard.general.string = message.content } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        Button { store.speakText(message.content) } label: {
            Label("Read Aloud", systemImage: "speaker.wave.2.fill")
        }
        ShareLink(item: message.content) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        // Optional: Add other actions like "Delete" if applicable
    }
    
    /// Builds the toolbar items.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { profileSheetShown = true } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { settingsShown = true } label: {
                Label("Settings", systemImage: "gear")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { store.resetConversation() } label: {
                Label("New Chat", systemImage: "plus.circle")
            }
            .disabled(store.isLoading) // Disable while loading
        }
    }
    
    /// View for the Settings sheet.
    @ViewBuilder
    private var settingsSheetView: some View {
        SettingsSheet(
            useMock: $store.useMock,
            apiKey: $apiKey,
            // Pass other AppStorage bindings if SettingsSheet modifies them
            backendSetter: store.setBackend // Simplified passing
            // Assuming SettingsSheet uses @AppStorage directly for model, temp, tokens
        )
    }
    
    /// View for the Profile/History sheet.
    @ViewBuilder
    private var profileSheetView: some View {
        ProfileSheet(
            conversations: $store.conversations,
            onDelete: store.deleteConversation,
            onSelect: { conversation in
                store.selectConversation(conversation)
                // Dismiss happens automatically in ProfileSheet or handled there
            }
        )
    }
    
    /// Overlay shown when the backend is processing.
    @ViewBuilder
    private var loadingOverlay: some View {
        if store.isLoading {
            Color.black.opacity(0.10)
                .ignoresSafeArea()
                .transition(.opacity) // Add a transition
        }
    }
    
    /// Overlay for displaying speech recognition errors.
    @ViewBuilder
    private var speechErrorOverlay: some View {
        if let err = speech.errorMessage {
            Text(err)
                .font(.caption) // Smaller font might be better for overlay
                .foregroundColor(.white)
                .padding(8)
                .background(Color.red.opacity(0.85))
                .clipShape(Capsule()) // Use Capsule shape
                .padding(.bottom, 50) // Adjust padding as needed
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1) // Ensure it's above other content
                .onAppear {
                    // Optionally dismiss after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if speech.errorMessage == err { // Only clear if it's the same error
                            speech.errorMessage = nil
                        }
                    }
                }
            
        }
    }
    
    // --- HELPER FUNCTIONS ---
    
    /// Sets up the initial chat backend based on settings.
    private func setupBackendOnAppear() {
        if !apiKey.isEmpty && !store.useMock {
            // Assuming SettingsSheet provides default values via its own @AppStorage
            let settings = SettingsSheet(useMock: .constant(false), apiKey: $apiKey, backendSetter: {_,_ in}) // Create dummy to access defaults
            store.setBackend(
                RealOpenAIBackend(
                    apiKey: apiKey,
                    model: settings.defaultModelName, // Need access to defaults
                    temperature: settings.defaultTemperature,
                    maxTokens: settings.defaultMaxTokens
                ),
                useMock: false
            )
        } else {
            // Ensure mock is set if conditions aren't met
            store.setBackend(MockChatBackend(), useMock: true)
        }
        // Request speech authorization early
        speech.requestAuthorization { granted in
            if !granted {
                print("Speech recognition permission denied.")
                // Optionally show an alert to the user here
            }
        }
    }
    
    // --- Static Helper Methods (If any) ---
    // Example: Date formatting, etc.
    
    // MARK: - InputBar (Separate Struct - Recommended)
    // Keep ChatInputBar as a separate struct for better encapsulation
    struct ChatInputBar: View {
        @Binding var input: String
        @ObservedObject var speech: SpeechRecognizer
        @ObservedObject var store: ChatStore
        @FocusState var focused: Bool // Receive FocusState
        
        // Use internal computed property for text field binding
        private var textFieldBinding: Binding<String> {
            Binding(
                get: { input.isEmpty ? speech.transcript : input },
                set: {
                    input = $0
                    // If user starts typing over a transcript, clear the transcript
                    if !speech.transcript.isEmpty && !$0.isEmpty {
                        speech.transcript = ""
                        // Optionally stop recording if user types over it
                        // if speech.isRecording { speech.stopRecording() }
                    }
                }
            )
        }
        
        var body: some View {
            HStack(spacing: 8) { // Reduced spacing
                // Editable field
                TextField("Type or use mic…", text: textFieldBinding, axis: .vertical)
                    .focused($focused) // Use the passed-in FocusState
                    .lineLimit(1...5) // Allow multiple lines
                    .padding(10) // Consistent padding
                    .background(Color(.secondarySystemBackground)) // Background for text field
                    .clipShape(RoundedRectangle(cornerRadius: 18)) // Rounded shape
                    .overlay( // Add border if needed
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onSubmit(submit) // Use onSubmit on TextField
                    .disabled(store.isLoading)
                
                // MIC Button
                micButton
                
                // SEND Button
                sendButton
            }
            .padding(.horizontal, 12) // Main padding for the bar
            .padding(.vertical, 8)
            .background(.thinMaterial) // Background for the whole bar
            .animation(.easeInOut(duration: 0.2), value: speech.isRecording) // Animate mic button changes
        }
        
        // --- InputBar Sub-Components ---
        
        private var micButton: some View {
            Button(action: toggleRecording) {
                Image(systemName: speech.isRecording ? "stop.circle.fill" : "mic.circle.fill") // More distinct icons
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28) // Slightly larger touch target
                    .foregroundStyle(speech.isRecording ? Color.red : Color.blue) // Use foregroundStyle
                    .padding(.vertical, 4)
                    .contentTransition(.symbolEffect(.replace)) // Nice transition
                    .accessibilityLabel(speech.isRecording ? "Stop Recording" : "Start Voice Input")
            }
            .disabled(store.isLoading) // Disable mic while loading response
        }
        
        private var sendButton: some View {
            Button(action: submit) {
                Image(systemName: "arrow.up.circle.fill") // Consistent circle style
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(canSubmit ? Color.blue : Color.gray.opacity(0.5))
            }
            .disabled(!canSubmit || store.isLoading)
            .keyboardShortcut(.return, modifiers: .command) // Optional: Cmd+Enter shortcut
        }
        
        // --- InputBar Logic ---
        
        private var canSubmit: Bool {
            !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        private func toggleRecording() {
            focused = false // Dismiss keyboard when interacting with mic
            if speech.isRecording {
                speech.stopRecording()
                // If transcript has content after stopping, handle it (submit or place in input)
                if !speech.transcript.isEmpty {
                    input = speech.transcript // Put transcript in input field
                    // Decide whether to auto-submit or let user press send
                    // submit() // Uncomment to auto-submit after stopping
                }
            } else {
                input = "" // Clear text input when starting mic
                speech.requestAuthorization { granted in
                    if granted {
                        do { try speech.startRecording() }
                        catch { speech.errorMessage = "Failed to start recording: \(error.localizedDescription)" }
                    } else {
                        speech.errorMessage = "Speech recognition permission needed."
                        // Consider showing an alert directing user to settings
                    }
                }
            }
        }
        
        private func submit() {
            let textToSend = input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            : input.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !textToSend.isEmpty {
                store.sendUserMessage(textToSend)
            }
            // Reset state after sending
            input = ""
            speech.transcript = ""
            if speech.isRecording { speech.stopRecording() } // Ensure recording stops
            focused = false // Dismiss keyboard
        }
    }
}

//MARK: - Helper to access @AppStorage defaults from SettingsSheet
// Needs to be outside `OpenAIChatVoiceDemoView` or static
extension SettingsSheet {
    var defaultModelName: String { _modelName.wrappedValue }
    var defaultTemperature: Double { _temperature.wrappedValue }
    var defaultMaxTokens: Int { _maxTokens.wrappedValue }
}

// MARK: - MESSAGE BUBBLE

struct MessageBubble: View {
    let message: Message
    let own: Bool
    var bubbleColor: Color { own ? .blue.opacity(0.16) : .secondary.opacity(0.09) }
    var textColor: Color { own ? .blue : .primary }
    var body: some View {
        HStack(alignment: .bottom) {
            if own { Spacer(minLength: 16) }
            VStack(alignment: own ? .trailing : .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(message.role.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(message.content)
                    .font(.body)
                    .padding(10)
                    .background(bubbleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .foregroundColor(textColor)
            }
            if !own { Spacer(minLength: 16) }
        }
        .padding(.horizontal, own ? 8 : 16)
        .padding(.vertical, 2)
    }
}

// MARK: - SETTINGS SHEET

struct SettingsSheet: View {
    @Binding var useMock: Bool
    @Binding var apiKey: String
    @AppStorage("model_name") private var modelName: String = "gpt-4o"
    @AppStorage("temperature") private var temperature: Double = 0.7
    @AppStorage("max_tokens") private var maxTokens: Int = 384
    var backendSetter: (ChatBackend, Bool) -> Void
    
    let models = ["gpt-4o", "gpt-4", "gpt-3.5-turbo"]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Chat Backend") {
                    Toggle("Use Mock (offline, for play/testing)", isOn: $useMock)
                        .onChange(of: useMock) {
                            backendSetter(useMock ? MockChatBackend() : RealOpenAIBackend(apiKey: apiKey, model: modelName, temperature: temperature, maxTokens: maxTokens), useMock)
                        }
                }
                Section("OpenAI Configuration") {
                    Picker("Model", selection: $modelName) {
                        ForEach(models, id:\.self) { Text($0) }
                    }
                    Stepper(value: $temperature, in: 0...1, step: 0.05) {
                        Text("Temperature: \(temperature, specifier: "%.2f")")
                    }
                    Stepper(value: $maxTokens, in: 64...2048, step: 32) {
                        Text("Max Tokens: \(maxTokens)")
                    }
                }
                if !useMock {
                    Section("API Key") {
                        SecureField("OpenAI API Key (sk-...)", text: $apiKey)
                            .autocapitalization(.none)
                        if apiKey.isEmpty {
                            Text("🔑 Enter your OpenAI API key to use Real backend.").font(.footnote)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } }
            .onChange(of: apiKey) {
                if !useMock && !apiKey.isEmpty {
                    backendSetter(RealOpenAIBackend(apiKey: apiKey, model: modelName, temperature: temperature, maxTokens: maxTokens), false)
                }
            }
            .onChange(of: modelName) {
                if !useMock && !apiKey.isEmpty {
                    backendSetter(RealOpenAIBackend(apiKey: apiKey, model: modelName, temperature: temperature, maxTokens: maxTokens), false)
                }
            }
            .onChange(of: temperature) {
                if !useMock && !apiKey.isEmpty {
                    backendSetter(RealOpenAIBackend(apiKey: apiKey, model: modelName, temperature: temperature, maxTokens: maxTokens), false)
                }
            }
            .onChange(of: maxTokens) {
                if !useMock && !apiKey.isEmpty {
                    backendSetter(RealOpenAIBackend(apiKey: apiKey, model: modelName, temperature: temperature, maxTokens: maxTokens), false)
                }
            }
        }
    }
}

// MARK: - PROFILE SHEET (History)

struct ProfileSheet: View {
    @Binding var conversations: [Conversation]
    var onDelete: (UUID) -> Void
    var onSelect: (Conversation) -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            if conversations.isEmpty {
                Text("No previous chats.")
                    .padding(.top, 80)
            } else {
                List {
                    ForEach(conversations) { conv in
                        Section {
                            Button {
                                onSelect(conv)
                                dismiss()
                            } label: {
                                VStack(alignment:.leading, spacing: 2) {
                                    Text(conv.title)
                                        .font(.headline)
                                    Text(conv.createdAt, style:.date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text((conv.messages.first{ $0.role == .user }?.content ?? "").prefix(64))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth:.infinity, alignment:.leading)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .onDelete { idx in
                        idx.map { conversations[$0].id }.forEach(onDelete)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - PREVIEW
struct OpenAIChatVoiceDemoView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAIChatVoiceDemoView()
            .preferredColorScheme(.dark)
        OpenAIChatVoiceDemoView()
            .preferredColorScheme(.light)
    }
}
