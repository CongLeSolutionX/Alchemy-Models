//
//  OpenAIChatAPIDemoView_V10.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

import SwiftUI
import Combine
import Speech
import AVFoundation
import CryptoKit

// MARK: - ‑‑‑ DOMAIN OBJECTS ‑‑‑ -------------------------------------------------

enum Role: String, Codable { case system, user, assistant }

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var role: Role
    var text: String
    var time: Date
    init(_ role: Role, _ text: String,
         time: Date = .now, id: UUID = .init()) {
        self.id = id; self.role = role; self.text = text; self.time = time
    }
}

struct Conversation: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var created: Date
    var tokensUsed: Int     // running estimate
    var messages: [ChatMessage]
    
    init(title: String = "New Chat",
         messages: [ChatMessage] = [],
         created: Date = .now,
         tokens: Int = 0,
         id: UUID = .init()) {
        self.id = id; self.title = title
        self.created = created; self.messages = messages
        self.tokensUsed = tokens
    }
}

// MARK: - ‑‑‑ OPENAI BACKEND ‑‑‑ --------------------------------------------------

protocol ChatBackend {                 // already used by view‑model
    func streamReply(for conversation: Conversation) -> AsyncThrowingStream<Token,Error>
    typealias Token = String
}

struct OpenAIBackend: ChatBackend {
    struct Constants {
        static let endpoint = "https://api.openai.com/v1/chat/completions"
        static let model    = "gpt-3.5-turbo"
    }
    
    private var key: String?
    init(key: String?) { self.key = key }
    
    func streamReply(for convo: Conversation) -> AsyncThrowingStream<Token,Error> {
        AsyncThrowingStream { cont in
            guard let apiKey = key, !apiKey.isEmpty else {
                cont.finish(throwing: BackendError.missingKey); return
            }
            var req = URLRequest(url: URL(string: Constants.endpoint)!)
            req.httpMethod = "POST"
            req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            struct Out: Encodable {
                struct Msg: Encodable { var role, content: String }
                var model = Constants.model
                var messages: [Msg]
                var stream = true
            }
            let payload = Out(messages: convo.messages.map { .init(role: $0.role.rawValue,
                                                                   content: $0.text) })
            req.httpBody = try! JSONEncoder().encode(payload)
            
            // MARK: –‑ streaming with URLSession.bytes(for:)
            let task = URLSession.shared.bytes(for: req)
            Task {
                do {
                    for try await line in task.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let trimmed = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if trimmed == "[DONE]" { cont.finish(); break }
                        if let token = try parseToken(from: trimmed) {
                            cont.yield(token)
                        }
                    }
                } catch {
                    cont.finish(throwing: error)
                }
            }
        }
    }
    
    // helpers -------------------------------------------------------
    private func parseToken(from jsonLine: String) throws -> String? {
        struct Delta: Decodable { let content: String? }
        struct Choice: Decodable { let delta: Delta }
        struct Resp: Decodable { let choices: [Choice] }
        let data = Data(jsonLine.utf8)
        let obj = try JSONDecoder().decode(Resp.self, from: data)
        return obj.choices.first?.delta.content
    }
    enum BackendError: LocalizedError { case missingKey
        var errorDescription: String? {
            switch self { case .missingKey: "OpenAI API key not configured" }
        }
    }
}

// MARK: - ‑‑‑ KEYCHAIN tiny helper ‑‑‑ -------------------------------------------

enum Secrets {
    private static let service = "MiniGPTChatApp"
    private static let account = "openai_key"
    
    static var key: String? {
        get {
            let q: [String:Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: account,
                                   kSecReturnData as String: true]
            var out: CFTypeRef?
            let status = SecItemCopyMatching(q as CFDictionary, &out)
            guard status == errSecSuccess,
                  let data = out as? Data,
                  let str = String(data: data, encoding: .utf8) else { return nil }
            return str
        }
        set {
            let data = (newValue ?? "").data(using: .utf8)!
            let q: [String:Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: account]
            SecItemDelete(q as CFDictionary)
            guard !data.isEmpty else { return }
            let ins = q.merging([kSecValueData as String: data]) { $1 }
            SecItemAdd(ins as CFDictionary, nil)
        }
    }
}

// MARK: - ‑‑‑ SPEECH I/O (unchanged) ‑‑‑ -----------------------------------------

@MainActor
final class SpeechToText: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var transcript = ""; @Published var recording = false; @Published var err: String?
    private let recognizer = SFSpeechRecognizer(locale: .init(identifier: "en_US"))
    private let audioEngine = AVAudioEngine(); private var task: SFSpeechRecognitionTask?
    func toggle() { recording ? stop() : start() }
    private func start() {
        recognizer?.delegate = self; err = nil; transcript = ""
        SFSpeechRecognizer.requestAuthorization { st in
            guard st == .authorized else { self.err = "Speech permission denied"; return }
            Task { @MainActor in self.begin() }
        }
    }
    private func begin() {
        let node = audioEngine.inputNode; let fmt = node.outputFormat(forBus: 0)
        let req = SFSpeechAudioBufferRecognitionRequest()
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf,_ in req.append(buf) }
        audioEngine.prepare(); try? audioEngine.start()
        task = recognizer?.recognitionTask(with: req) { [weak self] res, e in
            if let e { self?.err = e.localizedDescription }
            self?.transcript = res?.bestTranscription.formattedString ?? ""
        }; recording = true
    }
    private func stop() {
        audioEngine.stop(); audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel(); task = nil; recording = false
    }
}

final class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer(); @Published var speaking = false
    func say(_ s: String) { guard !s.isEmpty else { return }
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: s); u.voice = .init(language: "en-US"); synth.speak(u) }
    func speechSynthesizer(_: AVSpeechSynthesizer, didStart _: AVSpeechUtterance) { speaking = true }
    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance){ speaking = false }
}

// MARK: - ‑‑‑ PERSISTENCE (JSON) ‑‑‑ --------------------------------------------

struct Store {
    static let ver = 2
    static let url: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("conversations_v\(ver).json")
    }()
    static func load() -> [Conversation] {
        guard let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Conversation].self, from: data) else { return [] }
        return list
    }
    static func save(_ arr: [Conversation]) {
        DispatchQueue.global(qos: .utility).async {
            if let d = try? JSONEncoder().encode(arr) {
                try? d.write(to: url, options: .atomic)
            }
        }
    }
}

// MARK: - ‑‑‑ VIEW‑MODEL ‑‑‑ ----------------------------------------------------

@MainActor
final class ChatVM: ObservableObject {
    // published
    @Published var list: [Conversation] = Store.load()
    @Published var sel: Conversation.ID?
    @Published var composing = ""
    @Published var isLoading = false
    @Published var settings = Settings()
    @Published var error: String?
    
    // helpers
    let stt = SpeechToText(); let tts = TextToSpeech()
    private var backend: ChatBackend { OpenAIBackend(key: Secrets.key) }
    private var bag = Set<AnyCancellable>()
    
    struct Settings: Codable {
        var autoSpeak = false
        var showSystem = false
    }
    
    init() {
        if list.isEmpty { newChat() }
        sel = list.first?.id
        $list.dropFirst().sink { Store.save($0) }.store(in: &bag)
    }
    
    // Computed
    var current: Conversation? { list.first { $0.id == sel } }
    var inputText: String { composing.isEmpty ? stt.transcript : composing }
    var totalTokens: Int { current?.tokensUsed ?? 0 }
    
    // intents --------------------------------------------------------
    func newChat() {
        let sys = ChatMessage(.system, "You are a helpful assistant.")
        list.insert(Conversation(messages: [sys]), at: 0)
        sel = list.first?.id
    }
    func delete(_ offs: IndexSet) { list.remove(atOffsets: offs) }
    func rename(_ c: Conversation, new: String) {
        guard let i = list.firstIndex(of: c) else { return }
        list[i].title = new
    }
    
    func send() {
        guard var convo = current,
              !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        let user = ChatMessage(.user, inputText.trimmingCharacters(in: .whitespacesAndNewlines))
        composing = ""; stt.transcript = ""
        convo.messages.append(user); update(convo)
        Task { await generate(for: convo) }
    }
    
    private func generate(for convo: Conversation) async {
        isLoading = true; error = nil
        var working = convo; var buf = ""; var tok = 0
        do {
            for try await token in backend.streamReply(for: convo) {
                buf += token; tok += 1
                if working.messages.last?.role == .assistant {
                    working.messages[working.messages.count-1].text = buf
                } else { working.messages.append(ChatMessage(.assistant, buf)) }
                working.tokensUsed = convo.tokensUsed + tok
                update(working)
            }
            if settings.autoSpeak { tts.say(buf) }
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
    
    private func update(_ c: Conversation) {
        guard let i = list.firstIndex(where: { $0.id == c.id }) else { return }
        list[i] = c
    }
}

// MARK: - ‑‑‑ UI ‑‑‑ -------------------------------------------------------------

struct RootView: View {
    @StateObject private var vm = ChatVM()
    @State private var showSettings = false
    @FocusState private var focus
    var body: some View {
        NavigationSplitView {
            List(selection: $vm.sel) {
                ForEach(vm.list) { ConversationRow($0) }
                    .onDelete(perform: vm.delete)
            }
            .navigationTitle("Chats")
           // .toolbar { Button("New", systemImage: "plus", action: vm.newChat) }
        } detail: {
            if let convo = vm.current {
                VStack(spacing: 0) {
                    ChatScroll(vm: vm, convo: convo)
                    InputBar(vm: vm).padding(.horizontal).padding(.bottom, 5)
                        .focused($focus)
                }
                .navigationTitle("\(convo.title) • \(convo.tokensUsed) tok")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(LocalizedStringKey("Settings"), systemImage: "gearshape") { showSettings = true }
                    }
                }
                .sheet(isPresented: $showSettings) { SettingsView(vm: vm) }
            } else {
                ContentUnavailableView("No chat", systemImage: "ellipsis.bubble")
            }
        }
    }
}

// --- Conversation list row
struct ConversationRow: View { let convo: Conversation
    init(_ c: Conversation) { self.convo = c }
    var preview: String {
        convo.messages.last(where: { $0.role != .system })?.text ?? ""
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(convo.title).font(.headline)
            Text(preview).font(.footnote).lineLimit(1).foregroundStyle(.secondary)
        }.padding(.vertical, 4)
    }
}

// --- Chat Scroll area
struct ChatScroll: View {
    @ObservedObject var vm: ChatVM; let convo: Conversation
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(convo.messages
                        .filter { vm.settings.showSystem || $0.role != .system }) { m in
                        Bubble(msg: m, own: m.role == .user)
                            .contextMenu {
                                Button("Copy", systemImage: "doc.on.doc"){ UIPasteboard.general.string = m.text }
                                Button("Speak", systemImage:"speaker.wave.2"){ vm.tts.say(m.text) }
                                Button("Regenerate", systemImage:"arrow.counterclockwise") {
                                    vm.send() // naive: resend last user message
                                }
                            }
                    }
                    if vm.isLoading { ProgressView().padding() }
                    if let err = vm.error {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
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

// --- Bubble
struct Bubble: View {
    let msg: ChatMessage; let own: Bool
    var color: Color { own ? .blue.opacity(0.22) : .gray.opacity(0.18) }
    var body: some View {
        HStack {
            if own { Spacer() }
            VStack(alignment: .leading, spacing: 4) {
                Text(msg.text)//.markdownTextStyle()         // iOS17 markdown rendering
                    .padding(10)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(msg.time, style: .time)
                    .font(.caption2).foregroundStyle(.secondary)
                    .padding(own ? .trailing : .leading, 6)
            }
            if !own { Spacer() }
        }.id(msg.id)
    }
}

// --- Input bar
struct InputBar: View {
    @ObservedObject var vm: ChatVM
    var body: some View {
        HStack {
            Button(LocalizedStringKey("Voice"), systemImage: vm.stt.recording ? "stop.circle.fill" : "mic.circle") {
                vm.stt.toggle()
            }.font(.system(size: 26)).foregroundStyle(vm.stt.recording ? .red : .blue)
            TextField("Message", text:
                        Binding(get: { vm.inputText },
                                set: { vm.composing = $0 }))
                .textFieldStyle(.roundedBorder)
                .onSubmit(vm.send)
            Button(LocalizedStringKey("Send"), systemImage: "arrow.up.circle.fill", action: vm.send)
                .font(.system(size: 28))
                .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

// --- Settings
struct SettingsView: View {
    @ObservedObject var vm: ChatVM
    @Environment(\.dismiss) private var close
    @State private var tempKey = Secrets.key ?? ""
    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI") {
                    SecureField("API Key", text: $tempKey)
                        .autocapitalization(.none)
                    Button("Save Key") { Secrets.key = tempKey; close() }
                }
                Section("Options") {
                    Toggle("Speak replies", isOn: $vm.settings.autoSpeak)
                    Toggle("Show system messages", isOn: $vm.settings.showSystem)
                }
                if let err = vm.error {
                    Text(err).foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { close() } } }
        }
    }
}

// MARK: - App entry
@main struct MiniGPTChatApp: App { var body: some Scene { WindowGroup { RootView() } } }
