//
//  OpenAIChatAPIDemoView_V6.swift
//  Alchemy_Models
//  Created by Cong Le on 4/20/25.
//

//  Compile‑ready SwiftUI demo chat with voice (STT + TTS),
//  conversation history, settings, rename/delete, mock streaming backend.

import SwiftUI
import Combine
import Speech
import AVFoundation

// MARK: - Domain

enum Role: String, Codable { case system, user, assistant }

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var role: Role
    var text: String
    var time: Date
    
    init(_ role: Role, _ text: String, time: Date = .now, id: UUID = .init()) {
        self.id = id; self.role = role; self.text = text; self.time = time
    }
}

struct Conversation: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var created: Date
    var messages: [ChatMessage]
    
    init(title: String = "New Chat", messages: [ChatMessage] = [], created: Date = .now, id: UUID = .init()) {
        self.id = id; self.title = title; self.messages = messages; self.created = created
    }
}

// MARK: - Backend (mock streaming)

protocol ChatBackend { /// streams token‑by‑token
    func streamReply(for conversation: Conversation) -> AsyncStream<String>
}

struct MockStreamingBackend: ChatBackend {
    func streamReply(for conversation: Conversation) -> AsyncStream<String> {
        .init { continuation in
            // Fake answer chunks
            let fake = ["Sure", ",", " here's", " a", " mock", " reply", " for", " you", "."]
            Task.detached {
                for token in fake {
                    try? await Task.sleep(for: .milliseconds(Int.random(in: 100...350)))
                    continuation.yield(token)
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - Speech helpers

final class SpeechToText: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @MainActor @Published var transcript = ""
    @MainActor @Published var recording = false
    @MainActor @Published var error: String?
    
    private let recognizer = SFSpeechRecognizer(locale: .init(identifier: "en_US"))
    private let audioEngine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    
    @MainActor func toggle() { recording ? stop() : start() }
    
    @MainActor private func start() {
        transcript = ""
        error = nil
        recognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { self.setError("Permission denied"); return }
            DispatchQueue.main.async { self._begin() }
        }
    }
    @MainActor private func _begin() {
        let node = audioEngine.inputNode
        let format = node.outputFormat(forBus: 0)
        let request = SFSpeechAudioBufferRecognitionRequest()
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buf, _ in request.append(buf) }
        audioEngine.prepare(); try? audioEngine.start()
        
        task = recognizer?.recognitionTask(with: request) { [weak self] res, err in
            guard let self else { return }
            if let err { self.setError(err.localizedDescription) }
            self.transcript = res?.bestTranscription.formattedString ?? ""
        }
        recording = true
    }
    @MainActor private func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel(); task = nil; recording = false
    }
    private func setError(_ msg: String) { DispatchQueue.main.async { self.error = msg; self.stop() } }
}

final class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    @Published var speaking = false
    override init() { super.init(); synth.delegate = self }
    
    func say(_ txt: String) {
        guard !txt.isEmpty else { return }
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: txt)
        u.voice = .init(language: "en-US")
        synth.speak(u)
    }
    func stop() { synth.stopSpeaking(at: .immediate) }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { speaking = false }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) { speaking = true }
}

// MARK: - Storage helper (simple JSON file)

struct Persistence {
    static let url: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("conversations.json")
    }()
    static func load() -> [Conversation] {
        (try? Data(contentsOf: url))
            .flatMap { try? JSONDecoder().decode([Conversation].self, from: $0) } ?? []
    }
    static func save(_ list: [Conversation]) {
        DispatchQueue.global(qos: .background).async {
            let data = try? JSONEncoder().encode(list)
            try? data?.write(to: url, options: .atomic)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ChatVM: ObservableObject {
    @Published var conversations: [Conversation] = Persistence.load()
    @Published var selection: Conversation.ID?
    @Published var composing = ""
    @Published var isLoading = false
    @Published var settings = Settings()
    
    let stt = SpeechToText()
    let tts = TextToSpeech()
    private var backend: ChatBackend = MockStreamingBackend()
    private var cancellables = Set<AnyCancellable>()
    
    struct Settings: Codable {
        var autoTTS = false
        var showSystem = false
        var temperature: Double = 0.7
    }
    
    init() {
        if conversations.isEmpty { addNewConversation() }
        selection = conversations.first?.id
        
        $conversations
            .dropFirst()
            .sink { Persistence.save($0) }
            .store(in: &cancellables)
    }
    
    // MARK: intents
    func addNewConversation() {
        let sys = ChatMessage(.system, "You are a helpful assistant.")
        conversations.insert(Conversation(title: "Chat \(conversations.count+1)",
                                          messages: [sys]), at: 0)
        selection = conversations.first?.id
    }
    func delete(_ ids: IndexSet) { conversations.remove(atOffsets: ids) }
    func rename(_ convo: Conversation, to new: String) {
        guard let i = conversations.firstIndex(where: { $0.id == convo.id }) else { return }
        conversations[i].title = new
    }
    
    func send() {
        guard var convo = current, !composing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMsg = ChatMessage(.user, composing.trimmingCharacters(in: .whitespacesAndNewlines))
        convo.messages.append(userMsg)
        update(convo)
        composing = ""; stt.transcript = ""
        Task { await generateReply(for: convo) }
    }
    
    private func generateReply(for convo: Conversation) async {
        isLoading = true
        var updated = convo
        var content = ""
        for await token in backend.streamReply(for: convo) {
            content += token
            if updated.messages.last?.role == .assistant {
                updated.messages[updated.messages.count-1].text = content
            } else {
                updated.messages.append(ChatMessage(.assistant, content))
            }
            update(updated)
        }
        isLoading = false
        if settings.autoTTS { tts.say(content) }
    }
    
    var current: Conversation? {
        get { conversations.first(where: { $0.id == selection }) }
    }
    func update(_ convo: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == convo.id }) else { return }
        conversations[idx] = convo
    }
}

// MARK: - Views

struct RootView: View {
    @StateObject private var vm = ChatVM()
    @State private var showSettings = false
    @FocusState private var focus
    
    var body: some View {
        NavigationSplitView {
            List(selection: $vm.selection) {
                ForEach(vm.conversations) { c in
                    ConversationRow(convo: c)
                        .contextMenu { renameButton(c); deleteButton([c]) }
                        .badge(c.messages.filter { $0.role == .assistant }.count) // unread-ish
                }
                .onDelete(perform: vm.delete)
            }
            .navigationTitle("Chats")
            .toolbar { ToolbarItem { Button("New", systemImage: "plus", action: vm.addNewConversation) } }
        } detail: {
            if let convo = vm.current {
                VStack(spacing: 0) {
                    ChatScrollView(vm: vm, convo: convo)
                    ChatInputBar(vm: vm)
                        .focused($focus)
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                }
                .navigationTitle(convo.title)
                .toolbar { topToolbar(convo) }
                .sheet(isPresented: $showSettings) { SettingsView(vm: vm) }
                .onTapGesture { focus = false } // dismiss keyboard
            } else {
                ContentUnavailableView("No conversation selected", systemImage: "ellipsis.bubble")
            }
        }
    }
    
    // MARK: toolbars / helpers
    @ToolbarContentBuilder
    private func topToolbar(_ convo: Conversation) -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(LocalizedStringKey("Settings"), systemImage: "gearshape") { showSettings = true }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                renameButton(convo)
                deleteButton([convo])
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }
    private func renameButton(_ c: Conversation) -> some View {
        Button("Rename", systemImage: "pencil") {
            promptRename(c)
        }
    }
    private func deleteButton(_ list: [Conversation]) -> some View {
        Button(role: .destructive) {
            if let idx = vm.conversations.firstIndex(of: list[0]) {
                vm.delete(IndexSet(integer: idx))
            }
        } label: { Label("Delete", systemImage: "trash") }
    }
    private func promptRename(_ convo: Conversation) {
        var text = convo.title
        let alert = UIAlertController(title: "Rename Chat", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = text }
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Save", style: .default, handler: { _ in
            text = alert.textFields?.first?.text ?? ""
            if !text.isEmpty { vm.rename(convo, to: text) }
        }))
        UIApplication.shared.top?.present(alert, animated: true)
    }
}

// MARK: sub‑views

struct ConversationRow: View {
    let convo: Conversation
    var lastLine: String {
        convo.messages.last(where: { $0.role != .system })?.text ?? ""
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(convo.title).font(.headline)
            Text(lastLine).font(.footnote).lineLimit(1).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ChatScrollView: View {
    @ObservedObject var vm: ChatVM
    let convo: Conversation
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(convo.messages.filter { vm.settings.showSystem || $0.role != .system }) { msg in
                        MessageBubble(msg: msg, own: msg.role == .user)
                            .contextMenu {
                                Button("Copy", systemImage: "doc.on.doc") {
                                    UIPasteboard.general.string = msg.text
                                }
                                Button("Read Aloud", systemImage: "speaker.wave.2") { vm.tts.say(msg.text) }
                                ShareLink(item: msg.text) { Label("Share", systemImage: "square.and.arrow.up") }
                            }
                    }
                    if vm.isLoading { ProgressView().padding() }
                }
                .padding(.horizontal)
            }
            .onChange(of: convo.messages.last?.id) {
                withAnimation(.easeInOut) { proxy.scrollTo(convo.messages.last?.id, anchor: .bottom) }
            }
        }
    }
}

struct MessageBubble: View {
    let msg: ChatMessage
    let own: Bool
    var color: Color { own ? .blue.opacity(0.2) : .gray.opacity(0.15) }
    
    var body: some View {
        HStack {
            if own { Spacer() }
            VStack(alignment: .leading, spacing: 4) {
                Text(msg.text)
                    .padding(10)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(msg.time, style: .time)
                    .font(.caption2).foregroundColor(.secondary)
                    .padding(own ? .trailing : .leading, 6)
            }
            if !own { Spacer() }
        }
        .id(msg.id)
    }
}

struct ChatInputBar: View {
    @ObservedObject var vm: ChatVM
    @State private var rename = ""
    
    var body: some View {
        HStack {
            Button(LocalizedStringKey("Text Input"), systemImage: vm.stt.recording ? "stop.circle.fill" : "mic.circle") {
                vm.stt.toggle()
            }
            .font(.system(size: 28))
            .foregroundStyle(vm.stt.recording ? .red : .blue)
            .accessibilityLabel("Microphone")
            
            TextField("Type a message",
                      text: Binding(get: { vm.composing.isEmpty ? vm.stt.transcript : vm.composing },
                                     set: { vm.composing = $0 }))
            .textFieldStyle(.roundedBorder)
            .onSubmit(vm.send)
            
            Button(LocalizedStringKey("Send"), systemImage: "arrow.up.circle.fill", action: vm.send)
                .font(.system(size: 28))
                .disabled(vm.composing.isEmpty && vm.stt.transcript.isEmpty)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var vm: ChatVM
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Toggle("Speak replies aloud", isOn: $vm.settings.autoTTS)
                    Toggle("Show system messages", isOn: $vm.settings.showSystem)
                }
                Section("Model (mock)") {
                    Slider(value: $vm.settings.temperature, in: 0...1) {
                        Text("Temperature")
                    } minimumValueLabel: { Text("0") } maximumValueLabel: { Text("1") }
                    Text("Temperature: \(vm.settings.temperature, specifier: "%.2f")")
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - UIApplication helper (for alert presentation)

extension UIApplication {
    var top: UIViewController? {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        var top = root
        while let nxt = top.presentedViewController { top = nxt }
        return top
    }
}
#Preview("RootView") {
    RootView()
}
//
//// MARK: - App entry
//
//@main
//struct MiniGPTChatApp: App {
//    var body: some Scene { WindowGroup { RootView() } }
//}
