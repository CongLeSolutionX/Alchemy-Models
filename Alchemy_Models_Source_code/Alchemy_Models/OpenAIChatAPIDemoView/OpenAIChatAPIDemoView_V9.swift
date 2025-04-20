//
//  OpenAIChatAPIDemoView_V6.swift
//  Alchemy_Models
//  Created by Cong Le on 4/20/25.
//
//
//  MiniGPTChatApp.swift
//  Created 2024‑05‑28
//
//  One‑file, compile‑ready SwiftUI mini messenger
//  – chat history, mock streaming backend,
//  – speech‑to‑text & text‑to‑speech,
//  – MVVM, @MainActor‑safe for Swift 6.
//

import SwiftUI
import Combine
import Speech
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Domain models -------------------------------------------------------

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
    
    init(title: String = "New Chat",
         messages: [ChatMessage] = [],
         created: Date = .now,
         id: UUID = .init()) {
        self.id = id; self.title = title; self.messages = messages; self.created = created
    }
}

// MARK: - Mock streaming backend ---------------------------------------------

protocol ChatBackend {
    /// Async stream delivering reply token‑by‑token.
    func streamReply(for conversation: Conversation) -> AsyncStream<String>
}

struct MockStreamingBackend: ChatBackend {
    func streamReply(for conversation: Conversation) -> AsyncStream<String> {
        .init { cont in
            let fake = ["Sure", ",", " here's", " a", " mock", " reply", " for", " you", "."]
            Task.detached {
                for token in fake {
                    try? await Task.sleep(for: .milliseconds(Int.random(in: 100...300)))
                    cont.yield(token)
                }
                cont.finish()
            }
        }
    }
}

// MARK: - Speech helpers ------------------------------------------------------

@MainActor
final class SpeechToText: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var transcript = ""
    @Published var recording = false
    @Published var error: String?
    
    private let recognizer = SFSpeechRecognizer(locale: .init(identifier: "en_US"))
    private let audioEngine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    
    func toggle() { recording ? stop() : start() }
    
    private func start() {
        transcript = ""; error = nil
        recognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                self.setError("Speech permission denied")
                return
            }
            Task { @MainActor in self.beginRecognition() }
        }
    }
    
    private func beginRecognition() {
        let node = audioEngine.inputNode
        let format = node.outputFormat(forBus: 0)
        let req = SFSpeechAudioBufferRecognitionRequest()
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buf, _ in
            req.append(buf)
        }
        audioEngine.prepare()
        try? audioEngine.start()
        
        task = recognizer?.recognitionTask(with: req) { [weak self] res, err in
            guard let self else { return }
            if let err { self.setError(err.localizedDescription) }
            transcript = res?.bestTranscription.formattedString ?? ""
        }
        recording = true
    }
    
    private func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel(); task = nil
        recording = false
    }
    
    private func setError(_ msg: String) { error = msg; stop() }
}

final class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()    // non‑Sendable, but safe on main actor
    @Published var speaking = false
    
    override init() {
        super.init()
        synth.delegate = self
    }
    
    func say(_ txt: String) {
        guard !txt.isEmpty else { return }
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: txt)
        u.voice = .init(language: "en-US")
        synth.speak(u)
    }
    func stop() { synth.stopSpeaking(at: .immediate) }
    
    // AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ s: AVSpeechSynthesizer,
                           didStart _: AVSpeechUtterance) { speaking = true }
    func speechSynthesizer(_ s: AVSpeechSynthesizer,
                           didFinish _: AVSpeechUtterance) { speaking = false }
}

// MARK: - Persistence ---------------------------------------------------------

struct Persistence {
    static let url: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask)[0]
        return dir.appendingPathComponent("conversations.json")
    }()
    
    static func load() -> [Conversation] {
        guard let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Conversation].self, from: data)
        else { return [] }
        return list
    }
    static func save(_ list: [Conversation]) {
        DispatchQueue.global(qos: .background).async {
            if let d = try? JSONEncoder().encode(list) {
                try? d.write(to: url, options: .atomic)
            }
        }
    }
}

// MARK: - View‑Model ----------------------------------------------------------

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
    private var bag = Set<AnyCancellable>()
    
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
            .store(in: &bag)
    }
    
    // MARK: intents
    
    func addNewConversation() {
        let sys = ChatMessage(.system, "You are a helpful assistant.")
        conversations.insert(Conversation(title: "Chat \(conversations.count+1)",
                                          messages: [sys]), at: 0)
        selection = conversations.first?.id
    }
    func delete(_ offsets: IndexSet) { conversations.remove(atOffsets: offsets) }
    func rename(_ convo: Conversation, to new: String) {
        guard let i = conversations.firstIndex(where: { $0.id == convo.id }) else { return }
        conversations[i].title = new
    }
    
    func send() {
        guard var convo = current,
              !composedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        
        let userMsg = ChatMessage(.user, composedText.trimmingCharacters(in: .whitespacesAndNewlines))
        convo.messages.append(userMsg)
        update(convo)
        composing = ""; stt.transcript = ""
        Task { await generateReply(for: convo) }
    }
    
    private func generateReply(for convo: Conversation) async {
        isLoading = true
        var working = convo
        var buffer = ""
        for await token in backend.streamReply(for: convo) {
            buffer += token
            if working.messages.last?.role == .assistant {
                working.messages[working.messages.count-1].text = buffer
            } else {
                working.messages.append(ChatMessage(.assistant, buffer))
            }
            update(working)
        }
        isLoading = false
        if settings.autoTTS { tts.say(buffer) }
    }
    
    var composedText: String { composing.isEmpty ? stt.transcript : composing }
    
    var current: Conversation? {
        conversations.first(where: { $0.id == selection })
    }
    private func update(_ convo: Conversation) {
        guard let i = conversations.firstIndex(where: { $0.id == convo.id }) else { return }
        conversations[i] = convo
    }
}

// MARK: - Views ----------------------------------------------------------------

struct RootView: View {
    @StateObject private var vm = ChatVM()
    @State private var showingSettings = false
    @FocusState private var focusTextField
    
    var body: some View {
        NavigationSplitView {
            List(selection: $vm.selection) {
                ForEach(vm.conversations) { c in
                    ConversationRow(c)
                        .contextMenu {
                            renameButton(c)
                            deleteButton([c])
                        }
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
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                        .focused($focusTextField)
                }
                .navigationTitle(convo.title)
                .toolbar { detailToolbar(convo) }
                .sheet(isPresented: $showingSettings) { SettingsView(vm: vm) }
                .onTapGesture { focusTextField = false }
            } else {
                ContentUnavailableView("No conversation selected",
                                       systemImage: "ellipsis.bubble")
            }
        }
    }
    
    // MARK: helper buttons / toolbars
    
    private func detailToolbar(_ c: Conversation) -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(LocalizedStringKey("Settings"), systemImage: "gearshape") { showingSettings = true }
            Menu {
                renameButton(c)
                deleteButton([c])
            } label: { Label("More", systemImage: "ellipsis.circle") }
        }
    }
    
    private func renameButton(_ c: Conversation) -> some View {
        Button("Rename", systemImage: "pencil") { promptRename(c) }
    }
    private func deleteButton(_ cs: [Conversation]) -> some View {
        Button(role: .destructive) {
            if let idx = vm.conversations.firstIndex(of: cs[0]) {
                vm.delete(IndexSet(integer: idx))
            }
        } label: { Label("Delete", systemImage: "trash") }
    }
    
    private func promptRename(_ c: Conversation) {
        #if canImport(UIKit)
        let alert = UIAlertController(title: "Rename Chat", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = c.title }
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Save", style: .default) { _ in
            let txt = alert.textFields?.first?.text ?? ""
            if !txt.isEmpty { vm.rename(c, to: txt) }
        })
        UIApplication.shared.top?.present(alert, animated: true)
        #endif
    }
}

struct ConversationRow: View {
    let convo: Conversation
    var lastLine: String {
        convo.messages.last(where: { $0.role != .system })?.text ?? ""
    }
    init(_ c: Conversation) { self.convo = c }
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
                    ForEach(convo.messages.filter { vm.settings.showSystem || $0.role != .system }) { m in
                        MessageBubble(m, own: m.role == .user)
                            .contextMenu {
                                Button("Copy", systemImage: "doc.on.doc") {
                                    UIPasteboard.general.string = m.text
                                }
                                Button("Read Aloud",
                                       systemImage: "speaker.wave.2") { vm.tts.say(m.text) }
                                ShareLink(item: m.text) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                            }
                    }
                    if vm.isLoading { ProgressView().padding() }
                }
                .padding(.horizontal)
            }
            .onChange(of: convo.messages.last?.id) {
                withAnimation { proxy.scrollTo(convo.messages.last?.id,
                                               anchor: .bottom) }
            }
        }
    }
}

struct MessageBubble: View {
    let msg: ChatMessage
    let own: Bool
    init(_ m: ChatMessage, own: Bool) { self.msg = m; self.own = own }
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
                    .font(.caption2).foregroundStyle(.secondary)
                    .padding(own ? .trailing : .leading, 6)
            }
            if !own { Spacer() }
        }
        .id(msg.id)
    }
}

struct ChatInputBar: View {
    @ObservedObject var vm: ChatVM
    
    var body: some View {
        HStack {
            Button(LocalizedStringKey("Record"), systemImage: vm.stt.recording ? "stop.circle.fill" : "mic.circle") {
                vm.stt.toggle()
            }
            .font(.system(size: 28))
            .foregroundStyle(vm.stt.recording ? .red : .blue)
            .accessibilityLabel("Microphone")
            
            TextField("Type a message", text:
                        Binding(get: { vm.composedText },
                                set: { vm.composing = $0 }))
            .textFieldStyle(.roundedBorder)
            .onSubmit(vm.send)
            
            Button(LocalizedStringKey("Send"), systemImage: "arrow.up.circle.fill", action: vm.send)
                .font(.system(size: 28))
                .disabled(vm.composedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var vm: ChatVM
    @Environment(\.dismiss) private var dismiss
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
                    }
                    Text("Temperature: \(vm.settings.temperature, specifier: "%.2f")")
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - UIKit helpers -------------------------------------------------------

#if canImport(UIKit)
extension UIApplication {
    var top: UIViewController? {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        var t = root
        while let nxt = t.presentedViewController { t = nxt }
        return t
    }
}
#endif

// MARK: - App entry -----------------------------------------------------------
//
//@main
//struct MiniGPTChatApp: App {
//    var body: some Scene { WindowGroup { RootView() } }
//}

// MARK: - Previews ------------------------------------------------------------

#Preview("Chat") { RootView() }
