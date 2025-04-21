////
////  OpenAIChatAPIDemoView_Vietnamize_Version_V8.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
//import SwiftUI
//import Combine
//import AVFoundation
//
//// MARK: – App Entry Point
//
//@main
//struct ChatDemoApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ChatDemoView()
//        }
//    }
//}
//
//// MARK: – Models
//
//enum ChatRole: String, Codable, Hashable {
//    case system, user, assistant
//}
//
//struct Message: Identifiable, Codable, Hashable {
//    var id = UUID()
//    let role: ChatRole
//    let content: String
//    var date = Date()
//}
//
//struct Conversation: Identifiable, Codable {
//    var id = UUID()
//    var title: String
//    var messages: [Message]
//    var created: Date = .now
//}
//
//// MARK: – Backend Types
//
//enum BackendType: String, CaseIterable, Identifiable {
//    case mock, openAI, coreML
//    var id: Self { self }
//}
//
//// MARK: – ViewModel
//
//@MainActor
//class ChatStore: ObservableObject {
//    @Published var conversations: [Conversation] = []
//    @Published var current: Conversation
//    @Published var inputText = ""
//    @Published var isLoading = false
//    @Published var error: String? = nil
//    
//    // Settings
//    @Published var backend: BackendType = .mock
//    @Published var systemPrompt: String = "You are a helpful assistant."
//    @Published var ttsEnabled = false
//    @Published var ttsRate: Float = AVSpeechUtteranceDefaultSpeechRate
//    @Published var selectedVoiceID: String = ""
//    
//    let tts = AVSpeechSynthesizer()
//    let voices = AVSpeechSynthesisVoice.speechVoices()
//    
//    init() {
//        // Load sample history
//        let sample = Conversation(
//            title: "Demo Chat",
//            messages: [
//                Message(role: .system, content: systemPrompt),
//                Message(role: .user, content: "Hi, how are you?"),
//                Message(role: .assistant, content: "I'm fine, thanks! How can I assist?")
//            ])
//        conversations = [sample]
//        current = sample
//        
//        // pick default voice
//        if let english = voices.first(where: { $0.language.starts(with: "en") }) {
//            selectedVoiceID = english.identifier
//        }
//    }
//    
//    func send() {
//        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !text.isEmpty, !isLoading else { return }
//        append(.user, text)
//        inputText = ""
//        isLoading = true
//        
//        // Simulate network delay
//        Task {
//            try await Task.sleep(nanoseconds: 800_000_000)
//            let reply = "[\(backend.rawValue).reply] \(text.reversed().map(String.init).joined())"
//            append(.assistant, String(reply))
//            isLoading = false
//            
//            if ttsEnabled {
//                speak(reply)
//            }
//        }
//    }
//    
//    func append(_ role: ChatRole, _ text: String) {
//        let msg = Message(role: role, content: text)
//        current.messages.append(msg)
//        upsertCurrent()
//    }
//    
//    func upsertCurrent() {
//        if let idx = conversations.firstIndex(where: { $0.id == current.id }) {
//            conversations[idx] = current
//        } else {
//            current.title = current.messages.first(where: { $0.role == .user })?.content.prefix(32).description ?? "Chat"
//            conversations.insert(current, at: 0)
//        }
//    }
//    
//    func newChat() {
//        current = Conversation(title: "New Chat", messages: [.init(role: .system, content: systemPrompt)])
//        inputText = ""
//    }
//    
//    func delete(_ id: UUID) {
//        conversations.removeAll { $0.id == id }
//        if current.id == id { newChat() }
//    }
//    
//    func select(_ convo: Conversation) {
//        current = convo
//        inputText = ""
//    }
//    
//    func speak(_ text: String) {
//        let utterance = AVSpeechUtterance(string: text)
//        utterance.rate = ttsRate
//        if let voice = voices.first(where: { $0.identifier == selectedVoiceID }) {
//            utterance.voice = voice
//        }
//        tts.speak(utterance)
//    }
//}
//
//// MARK: – Main Chat View
//
//struct ChatDemoView: View {
//    @StateObject var store = ChatStore()
//    @State private var showSettings = false
//    @State private var showHistory = false
//    @FocusState private var inputFocused: Bool
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                header
//                Divider()
//                messages
//                ChatInputBar(
//                    text: $store.inputText,
//                    isLoading: store.isLoading,
//                    onSend: store.send
//                )
//            }
//            .sheet(isPresented: $showSettings) {
//                SettingsView(store: store)
//            }
//            .sheet(isPresented: $showHistory) {
//                HistoryView(store: store)
//            }
//            .alert(store.error ?? "", isPresented: .constant(store.error != nil)) {
//                Button("OK") { store.error = nil }
//            }
//        }
//    }
//    
//    private var header: some View {
//        HStack {
//            Text(store.current.title)
//                .font(.headline)
//                .lineLimit(1)
//            Spacer()
//            if store.isLoading {
//                ProgressView().scaleEffect(0.8)
//            }
//            Button { showHistory = true } label: {
//                Image(systemName: "clock.circle")
//            }
//            .padding(.horizontal, 4)
//            Button { showSettings = true } label: {
//                Image(systemName: "gear")
//            }
//            .padding(.horizontal, 4)
//            Button { store.newChat() } label: {
//                Image(systemName: "plus.square.on.square")
//            }
//        }
//        .padding()
//    }
//    
//    private var messages: some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                LazyVStack(spacing: 12) {
//                    ForEach(store.current.messages) { m in
//                        MessageBubble(msg: m)
//                            .id(m.id)
//                    }
//                }
//                .padding(.horizontal)
//                .padding(.top, 8)
//            }
//            .background(Color(.systemGroupedBackground))
//            .onChange(of: store.current.messages.last?.id) { id in
//                if let id = id {
//                    withAnimation { proxy.scrollTo(id, anchor: .bottom) }
//                }
//            }
//            .onTapGesture { inputFocused = false }
//        }
//    }
//}
//
//// MARK: – Message Bubble
//
//struct MessageBubble: View {
//    let msg: Message
//    var body: some View {
//        HStack {
//            if msg.role == .assistant { Spacer() }
//            Text(msg.content)
//                .padding(10)
//                .background(msg.role == .user ? .blue : .gray.opacity(0.2))
//                .foregroundColor(msg.role == .user ? .white : .primary)
//                .cornerRadius(12)
//            if msg.role == .user { Spacer() }
//        }
//        .padding(.horizontal, 4)
//    }
//}
//
//// MARK: – Input Bar
//
//struct ChatInputBar: View {
//    @Binding var text: String
//    let isLoading: Bool
//    let onSend: () -> Void
//    @FocusState private var focused: Bool
//    
//    var body: some View {
//        HStack {
//            TextField("Type message…", text: $text, axis: .vertical)
//                .lineLimit(1...4)
//                .textFieldStyle(.roundedBorder)
//                .disabled(isLoading)
//                .focused($focused)
//            Button {
//                onSend()
//                focused = false
//            } label: {
//                Image(systemName: "paperplane.fill")
//                    .rotationEffect(.degrees(45))
//                    .font(.title2)
//            }
//            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
//        }
//        .padding()
//        .background(.ultraThinMaterial)
//    }
//}
//
//// MARK: – Settings Panel
//
//struct SettingsView: View {
//    @ObservedObject var store: ChatStore
//    @Environment(\.dismiss) var dismiss
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("System Prompt") {
//                    TextField("Prompt", text: $store.systemPrompt)
//                }
//                Section("Backend") {
//                    Picker("Type", selection: $store.backend) {
//                        ForEach(BackendType.allCases) { type in
//                            Text(type.rawValue.capitalized).tag(type)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                }
//                Section("Text‑to‑Speech") {
//                    Toggle("Enable TTS", isOn: $store.ttsEnabled)
////                    if store.ttsEnabled {
////                        Slider("Rate", value: $store.ttsRate,
////                               in: 0.0...0.5)
////                        Picker("Voice", selection: $store.selectedVoiceID) {
////                            ForEach(store.voices, id: \.identifier) { v in
////                                Text("\(v.name) (\(v.language))")
////                                    .tag(v.identifier)
////                            }
////                        }
////                    }
//                }
//            }
//            .navigationTitle("Settings")
//            .toolbar {
//                Button("Done") { dismiss() }
//            }
//        }
//    }
//}
//
//// MARK: – History Panel
//
//struct HistoryView: View {
//    @ObservedObject var store: ChatStore
//    @Environment(\.dismiss) var dismiss
//    
//    var body: some View {
//        NavigationStack {
//            List {
//                ForEach(store.conversations) { convo in
//                    Button {
//                        store.select(convo)
//                        dismiss()
//                    } label: {
//                        VStack(alignment: .leading) {
//                            Text(convo.title).font(.headline)
//                            Text("\(convo.messages.count) messages")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//                .onDelete { idx in
//                    idx.map { store.delete(store.conversations[$0].id) }
//                }
//            }
//            .navigationTitle("History")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Close") { dismiss() }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//            }
//        }
//    }
//}
