////
////  OpenAIChatAPIDemoView_V5.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
//import SwiftUI
//import AVFoundation
//
//// MARK: - MODEL/STATE
//
//enum ChatRole: String, Codable, CaseIterable {
//    case system, user, assistant
//}
//
//struct Message: Identifiable, Codable, Hashable {
//    var id = UUID()
//    let role: ChatRole
//    let content: String
//    let timestamp: Date
//    
//    // Convenience
//    static func system(_ content: String) -> Message {
//        Message(role: .system, content: content, timestamp: .now)
//    }
//    static func user(_ content: String) -> Message {
//        Message(role: .user, content: content, timestamp: .now)
//    }
//    static func assistant(_ content: String) -> Message {
//        Message(role: .assistant, content: content, timestamp: .now)
//    }
//    
//    init(role: ChatRole, content: String, timestamp: Date = .now) {
//        self.role = role
//        self.content = content
//        self.timestamp = timestamp
//    }
//}
//
//struct Conversation: Identifiable, Codable, Hashable {
//    let id: UUID
//    var messages: [Message]
//    var title: String
//    var createdAt: Date
//    init(messages: [Message], title: String = "", createdAt: Date = .now, id: UUID = UUID()) {
//        self.id = id
//        self.messages = messages
//        self.title = title.isEmpty ? (messages.first(where: { $0.role == .user })?.content.prefix(32).description ?? "Chat") : title
//        self.createdAt = createdAt
//    }
//}
//
//// MARK: - MOCK SERVICE
//
//protocol ChatBackend {
//    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void)
//}
//
//struct MockChatBackend: ChatBackend {
//    let replies: [String] = [
//        "Absolutely! Let me walk you through this.",
//        "Here's an idea you might like.",
//        "That's an interesting question. So, ...",
//        "Let me look that up for you.",
//        "I'm your AI assistant—how can I help further?"
//    ]
//    
//    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
//            completion(.success(self.replies.randomElement() ?? "Sorry, please ask something else!"))
//        }
//    }
//}
//
//// MARK: - OPENAI SERVICE
//
//final class RealOpenAIBackend: ChatBackend {
//    let apiKey: String
//    let model: String
//    let temperature: Double
//    let maxTokens: Int
//    
//    init(apiKey: String, model: String, temperature: Double, maxTokens: Int) {
//        self.apiKey = apiKey
//        self.model = model
//        self.temperature = temperature
//        self.maxTokens = maxTokens
//    }
//    
//    func streamChat(messages: [Message], systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void) {
//        // Omitted: Similar as in original streaming code,
//        // but for synchronous demo, just fetch one response for simplicity
//        var fullMessages = messages
//        if !systemPrompt.isEmpty {
//            fullMessages.insert(.system(systemPrompt), at: 0)
//        }
//        // For brevity, just use non-streamed, not streaming Demo
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            completion(.failure(NSError(domain: "InvalidURL", code: 1)))
//            return
//        }
//        var req = URLRequest(url: url)
//        req.httpMethod = "POST"
//        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        struct RequestPayload: Encodable {
//            let model: String
//            let messages: [[String: String]]
//            let temperature: Double
//            let max_tokens: Int
//        }
//        let payload = RequestPayload(
//            model: model,
//            messages: fullMessages.map { ["role": $0.role.rawValue, "content": $0.content] },
//            temperature: temperature,
//            max_tokens: maxTokens
//        )
//        do {
//            req.httpBody = try JSONEncoder().encode(payload)
//        } catch { completion(.failure(error)); return }
//        URLSession.shared.dataTask(with: req) { data, resp, error in
//            if let error = error { completion(.failure(error)); return }
//            guard let data = data else { completion(.failure(NSError(domain: "NoData", code: 2))); return }
//            do {
//                struct Model: Decodable {
//                    struct Choice: Decodable { let message: MessageContent }
//                    struct MessageContent: Decodable { let role: String; let content: String }
//                    let choices: [Choice]
//                }
//                let model = try JSONDecoder().decode(Model.self, from: data)
//                let message = model.choices.first?.message.content ?? "No response"
//                completion(.success(message))
//            } catch { completion(.failure(error)) }
//        }.resume()
//    }
//}
//
//// MARK: - VIEW MODEL / STORE
//
//@MainActor
//final class ChatStore: ObservableObject {
//    // Conversation history
//    @Published var conversations: [Conversation] = [
//        Conversation(messages: [ .system("You are a helpful assistant!"), .user("What's the weather like in Paris?"), .assistant("I'm an AI model with no real-time data access, so I can't provide live weather updates. You can check your favorite weather app for up-to-date information!")])
//    ]
//    @Published var currentConversation: Conversation = Conversation(messages: [ .system("You are a helpful assistant! Your style is cheerful and concise.")])
//    @Published var input: String = ""
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//    @Published var systemPrompt: String = "You are a helpful assistant!"
//    @Published var useMock: Bool = true
//    @Published var ttsEnabled: Bool = false
//
//    private let tts = AVSpeechSynthesizer()
//
//    var backend: ChatBackend = MockChatBackend() // Swappable
//
//    // MARK: Actions
//
//    func setBackend(_ backend: ChatBackend, useMock: Bool) {
//        self.backend = backend
//        self.useMock = useMock
//    }
//    
//    func resetConversation() {
//        currentConversation = Conversation(messages: [ .system(systemPrompt) ])
//        input = ""
//    }
//    func sendUserMessage() {
//        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//        let userMsg = Message.user(trimmed)
//        currentConversation.messages.append(userMsg)
//        input = ""
//        isLoading = true
//        backend.streamChat(messages: currentConversation.messages, systemPrompt: systemPrompt) { [weak self] result in
//            DispatchQueue.main.async {
//                guard let self else { return }
//                switch result {
//                case .success(let response):
//                    let assistantMsg = Message.assistant(response)
//                    self.currentConversation.messages.append(assistantMsg)
//                    self.isLoading = false
//                    if self.ttsEnabled { self.speakText(response)}
//                    // Save to history slot
//                    self.saveCurrentToHistory()
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
//        // Only save if not duplicate
//        if !conversations.contains(where: { $0.messages == currentConversation.messages }) && currentConversation.messages.count > 1 {
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
//struct OpenAIStreamingChatView: View {
//    @StateObject private var store = ChatStore()
//    @AppStorage("openai_api_key") private var apiKey: String = ""
//    @State private var settingsShown = false
//    @State private var profileSheetShown = false
//    @FocusState private var focused: Bool
//    @Environment(\.colorScheme) var colorScheme
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                // Conversation Title
//                HStack {
//                    Text(store.currentConversation.title)
//                        .font(.title2.bold())
//                    Spacer()
//                }
//                .padding(.vertical, 6)
//                .padding(.horizontal, 16)
//                
//                // Message list
//                ScrollViewReader { scrollProxy in
//                    ScrollView {
//                        VStack(alignment:.leading, spacing: 6) {
//                            ForEach(store.currentConversation.messages) { msg in
//                                MessageBubble(
//                                    message: msg,
//                                    own: msg.role == .user
//                                )
//                                .id(msg.id)
//                                .contextMenu {
//                                    Button("Copy") { UIPasteboard.general.string = msg.content }
//                                    Button("Read Aloud") { store.speakText(msg.content) }
//                                    ShareLink(item: msg.content)
//                                }
//                                .onTapGesture {
//                                    UIPasteboard.general.string = msg.content
//                                }
//                            }
//                            if store.isLoading {
//                                ProgressView("Thinking...").padding(.horizontal)
//                            }
//                        }
//                        .padding(.vertical, 8)
//                        .onChange(of: store.currentConversation.messages.count) { _ in
//                            withAnimation { scrollProxy.scrollTo(store.currentConversation.messages.last?.id, anchor: .bottom) }
//                        }
//                    }
//                }
//                
//                // Input bar
//                HStack {
//                    TextField("Type your message...", text: $store.input, axis: .vertical)
//                        .focused($focused)
//                        .textFieldStyle(.roundedBorder)
//                        .autocorrectionDisabled()
//                        .frame(minHeight: 36)
//                        .onSubmit {
//                            focused = true
//                            send()
//                        }
//                        .disabled(store.isLoading)
//                    Button {
//                        send()
//                        focused = true
//                    } label: {
//                        Image(systemName: "paperplane.fill")
//                            .foregroundColor(store.input.trimmingCharacters(in: .whitespaces).isEmpty || store.isLoading ? .gray : .blue)
//                    }
//                    .disabled(store.input.trimmingCharacters(in: .whitespaces).isEmpty || store.isLoading)
//                }
//                .padding(8)
//                .background(.background)
//                .overlay(Divider(), alignment: .top)
//            }
//            .navigationTitle("Chat with GPT (Demo)")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button {
//                        profileSheetShown = true
//                    } label: {
//                        Label("Profile", systemImage: "person.circle")
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button {
//                        settingsShown = true
//                    } label: {
//                        Label("Settings", systemImage: "gear")
//                    }
//                }
//            }
//            .sheet(isPresented: $settingsShown) {
//                SettingsSheet(
//                    useMock: $store.useMock,
//                    apiKey: $apiKey,
//                    backendSetter: { backend, useMock in
//                        store.setBackend(backend, useMock: useMock)
//                    }
//                )
//            }
//            .sheet(isPresented: $profileSheetShown) {
//                ProfileSheet(
//                    conversations: $store.conversations,
//                    onDelete: store.deleteConversation,
//                    onSelect: store.selectConversation
//                )
//            }
//            .alert(isPresented: .constant(store.errorMessage != nil)) {
//                Alert(title: Text("Error"), message: Text(store.errorMessage ?? ""), dismissButton: .default(Text("Dismiss"), action: {
//                    store.errorMessage = nil
//                }))
//            }
//            .overlay(
//                store.isLoading ? Color.black.opacity(0.15).ignoresSafeArea() : nil
//            )
//        }
//        .preferredColorScheme(.light)
//        .onAppear {
//            if !apiKey.isEmpty && !store.useMock {
//                store.setBackend(
//                    RealOpenAIBackend(apiKey: apiKey, model: "gpt-4o", temperature: 0.7, maxTokens: 384),
//                    useMock: false
//                )
//            }
//        }
//    }
//    private func send() {
//        store.sendUserMessage()
//    }
//}
//
//// MARK: - BUBBLE
//
//struct MessageBubble: View {
//    let message: Message
//    let own: Bool
//    
//    var bubbleColor: Color {
//        own ? .blue.opacity(0.18) : .secondary.opacity(0.12)
//    }
//    var textColor: Color {
//        own ? .blue : .primary
//    }
//    var body: some View {
//        HStack(alignment:.bottom) {
//            if own { Spacer(minLength: 24) }
//            VStack(alignment: own ? .trailing : .leading, spacing: 2) {
//                HStack {
//                    Text(message.role.rawValue.capitalized)
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                        .accessibilityHidden(true)
//                    Text(message.timestamp, style:.time)
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                        .accessibilityHidden(true)
//                }
//                Text(message.content)
//                    .font(.body)
//                    .padding(10)
//                    .background(bubbleColor)
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//                    .foregroundColor(textColor)
//                    .accessibilityLabel("\(message.role.rawValue.capitalized) says: \(message.content)")
//            }
//            if !own { Spacer(minLength: 24) }
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
//    
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
//                            Text("🔑 Please enter your OpenAI API key to use Real backend.").font(.footnote)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Settings")
//            .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } }
//            .onChange(of: apiKey) { newKey in
//                if !useMock, !newKey.isEmpty {
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
//           // .navigationTitle("Chat History")
////            .toolbar { ToolbarItem(placement:.cancellationAction) { Button("Close") { dismiss() } } }
//        }
//        .presentationDetents([.large])
//    }
//}
//
//// MARK: - PREVIEW
//
//struct OpenAIStreamingChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        OpenAIStreamingChatView()
//    }
//}
