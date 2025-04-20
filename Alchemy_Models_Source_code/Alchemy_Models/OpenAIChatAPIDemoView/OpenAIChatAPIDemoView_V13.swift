////
////  OpenAIChatAPIDemoView_V13.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
//import SwiftUI
//import Speech
//import AVFoundation
//
//// MARK: – App Entry
//
//@main
//struct GPTChatApp: App {
//    var body: some Scene {
//        WindowGroup {
//            RootView()
//        }
//    }
//}
//
//// MARK: – Models
//
//enum Role: String, Codable {
//    case system, user, assistant
//}
//
//struct ChatMessage: Identifiable, Codable, Hashable {
//    let id: UUID
//    var role: Role
//    var text: String
//    var date: Date
//    
//    init(_ role: Role, _ text: String, date: Date = .now, id: UUID = .init()) {
//        self.id = id
//        self.role = role
//        self.text = text
//        self.date = date
//    }
//}
//
//struct Conversation: Identifiable, Codable, Hashable {
//    let id: UUID
//    var title: String
//    var created: Date
//    var messages: [ChatMessage]
//    
//    init(title: String = "New Chat",
//         messages: [ChatMessage] = [],
//         created: Date = .now,
//         id: UUID = .init()) {
//        self.id = id
//        self.title = title
//        self.created = created
//        self.messages = messages
//    }
//}
//
//// MARK: – Persistence
//
//extension Conversation {
//    private static var fileURL: URL {
//        FileManager.default
//            .urls(for: .documentDirectory, in: .userDomainMask)[0]
//            .appendingPathComponent("conversations.json")
//    }
//    static func loadAll() -> [Conversation] {
//        guard let data = try? Data(contentsOf: fileURL),
//              let convos = try? JSONDecoder().decode([Conversation].self, from: data)
//        else { return [] }
//        return convos
//    }
//    static func saveAll(_ convos: [Conversation]) {
//        Task.detached(priority: .background) {
//            guard let data = try? JSONEncoder().encode(convos) else { return }
//            try? data.write(to: fileURL, options: .atomic)
//        }
//    }
//}
//
//// MARK: – OpenAI Client
//
//fileprivate struct ChatCompletionRequest: Encodable {
//    struct Msg: Encodable { let role, content: String }
//    let model: String, messages: [Msg], stream: Bool, temperature: Double
//}
//
//fileprivate struct DeltaEnvelope: Decodable {
//    struct Choice: Decodable { let delta: Delta }
//    struct Delta: Decodable { let content: String? }
//    let choices: [Choice]
//}
//
//enum OpenAIError: LocalizedError {
//    case missingKey, badStatus(Int), canceled
//    var errorDescription: String? {
//        switch self {
//        case .missingKey:      return "Missing OpenAI API key"
//        case .badStatus(let c):return "OpenAI error – status \(c)"
//        case .canceled:        return "Request canceled"
//        }
//    }
//}
//
//actor OpenAIClient {
//    private let base = URL(string: "https://api.openai.com/v1/chat/completions")!
//    fileprivate func stream(model: String,
//                messages: [ChatCompletionRequest.Msg],
//                temperature: Double
//    ) -> AsyncThrowingStream<String, Error> {
//        AsyncThrowingStream { cont in
//            guard let key = AppSettings.shared.apiKey, !key.isEmpty else {
//                cont.finish(throwing: OpenAIError.missingKey)
//                return
//            }
//            var req = URLRequest(url: base)
//            req.httpMethod = "POST"
//            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
//            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            let payload = ChatCompletionRequest(
//                model: model,
//                messages: messages,
//                stream: true,
//                temperature: temperature
//            )
//            req.httpBody = try? JSONEncoder().encode(payload)
//            
//            let task = URLSession.shared.dataTask(with: req) { _, resp, err in
//                if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
//                    cont.finish(throwing: OpenAIError.badStatus(http.statusCode))
//                }
//            }
//            let delegate = SessionDelegate(onLine: { line in
//                // strip "data: "
//                let json = line.dropFirst(6)
//                guard json != "[DONE]",
//                      let data = json.data(using: .utf8),
//                      let env = try? JSONDecoder().decode(DeltaEnvelope.self, from: data),
//                      let piece = env.choices.first?.delta.content
//                else { return }
//                cont.yield(piece)
//            }, onClose: { status in
//                if status == 200 { cont.finish() }
//                else { cont.finish(throwing: OpenAIError.badStatus(status)) }
//            })
//            
//            delegate.start(with: req)
//            cont.onTermination = { _ in delegate.cancel() }
//        }
//    }
//}
//
//// Delegate to accumulate SSE
//private class SessionDelegate: NSObject, URLSessionDataDelegate {
//    private let onLine: (String)->Void, onClose: (Int)->Void
//    private var task: URLSessionDataTask?
//    
//    init(onLine: @escaping (String)->Void,
//         onClose: @escaping (Int)->Void) {
//        self.onLine = onLine; self.onClose = onClose
//    }
//    func start(with req: URLRequest) {
//        let sess = URLSession(configuration: .default,
//                              delegate: self,
//                              delegateQueue: nil)
//        task = sess.dataTask(with: req)
//        task?.resume()
//    }
//    func cancel() { task?.cancel() }
//    
//    func urlSession(_ s: URLSession,
//                    dataTask: URLSessionDataTask,
//                    didReceive data: Data) {
//        guard let txt = String(data: data, encoding: .utf8) else { return }
//        for line in txt.split(separator: "\n") where line.hasPrefix("data:") {
//            onLine(String(line))
//        }
//    }
//    func urlSession(_ s: URLSession,
//                    task: URLSessionTask,
//                    didCompleteWithError _: Error?) {
//        let status = (task.response as? HTTPURLResponse)?.statusCode ?? -1
//        onClose(status)
//    }
//}
//
//// MARK: – Settings
//
//final class AppSettings: ObservableObject {
//    static let shared = AppSettings()
//    @AppStorage("openai_api_key") var apiKey: String?
//    private init() {}
//}
//
//// MARK: – Speech‐to‐Text
//
//@MainActor
//final class SpeechToText: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
//    @Published var transcript: String = ""
//    @Published var isRecording = false
//    @Published var error: String?
//    
//    private let engine = AVAudioEngine()
//    private let req = SFSpeechAudioBufferRecognitionRequest()
//    private var task: SFSpeechRecognitionTask?
//    private let recognizer = SFSpeechRecognizer()
//    
//    func toggle() {
//        isRecording ? stop() : Task { await start() }
//    }
//    private func start() async {
//        transcript = ""; error = nil
//        let status = await SFSpeechRecognizer.requestAuthorization()
//        guard status == .authorized else {
//            error = "Speech permission denied"; return
//        }
//        guard let node = engine.inputNode else { return }
//        node.installTap(onBus: 0,
//                        bufferSize: 1024,
//                        format: node.outputFormat(forBus: 0)
//        ) { buf, _ in self.req.append(buf) }
//        engine.prepare()
//        try? engine.start()
//        task = recognizer?.recognitionTask(with: req) { [weak self] res, err in
//            if let err { self?.error = err.localizedDescription }
//            self?.transcript = res?.bestTranscription.formattedString ?? ""
//        }
//        isRecording = true
//    }
//    private func stop() {
//        engine.inputNode.removeTap(onBus: 0)
//        engine.stop()
//        task?.cancel(); task = nil
//        isRecording = false
//    }
//}
//
//// MARK: – Text‐to‐Speech
//
//@MainActor
//final class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
//    @Published var isSpeaking = false
//    private let synth = AVSpeechSynthesizer()
//    override init() { super.init(); synth.delegate = self }
//    
//    func speak(_ text: String) {
//        guard !text.isEmpty else { return }
//        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
//        let utt = AVSpeechUtterance(string: text)
//        utt.voice = .init(language: "en-US")
//        synth.speak(utt)
//    }
//    func speechSynthesizer(_: AVSpeechSynthesizer, didStart _: AVSpeechUtterance) {
//        isSpeaking = true
//    }
//    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
//        isSpeaking = false
//    }
//}
//
//// MARK: – ViewModel
//
//@MainActor
//final class ChatViewModel: ObservableObject {
//    @Published var conversations: [Conversation] = Conversation.loadAll() {
//        didSet { Conversation.saveAll(conversations) }
//    }
//    @Published var selectedID: Conversation.ID?
//    @Published var draft: String = ""
//    @Published var isLoading = false
//    @Published var autoSpeak = false
//    @Published var showSystem = false
//    @Published var model = "gpt-3.5-turbo"
//    @Published var temperature = 0.7
//    
//    let stt = SpeechToText()
//    let tts = TextToSpeech()
//    private let client = OpenAIClient()
//    
//    init() {
//        if conversations.isEmpty { newChat() }
//        selectedID = conversations.first?.id
//    }
//    
//    var current: Conversation {
//        get { conversations.first { $0.id == selectedID }! }
//        set {
//            if let idx = conversations.firstIndex(where: { $0.id == newValue.id }) {
//                conversations[idx] = newValue
//            }
//        }
//    }
//    
//    func newChat() {
//        let sys = ChatMessage(.system, "You are a helpful assistant.")
//        let convo = Conversation(title: "Chat \(conversations.count+1)", messages: [sys])
//        conversations.insert(convo, at: 0)
//        selectedID = convo.id
//    }
//    
//    func send() {
//        let text = draft.isEmpty ? stt.transcript : draft
//        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//        draft = ""; stt.transcript = ""
//        
//        var convo = current
//        convo.messages.append(.init(.user, trimmed))
//        current = convo
//        reply(to: convo)
//    }
//    
//    private func reply(to convo: Conversation) {
//        isLoading = true
//        Task {
//            var working = convo
//            var buffer = ""
//            do {
//                let seq = await client.stream(
//                    model: model,
//                    messages: working.messages.map { .init(role: $0.role.rawValue, content: $0.text) },
//                    temperature: temperature
//                )
//                for try await piece in seq {
//                    buffer += piece
//                    if working.messages.last?.role == .assistant {
//                        working.messages[working.messages.count-1].text = buffer
//                    } else {
//                        working.messages.append(.init(.assistant, buffer))
//                    }
//                    current = working
//                }
//                if autoSpeak { tts.speak(buffer) }
//            } catch {
//                working.messages.append(.init(.assistant, "⚠️ " + (error.localizedDescription)))
//                current = working
//            }
//            isLoading = false
//        }
//    }
//}
//
//// MARK: – Views
//
//struct RootView: View {
//    @StateObject private var vm = ChatViewModel()
//    @FocusState private var focus: Bool
//    
//    var body: some View {
//        NavigationSplitView {
//            List(selection: $vm.selectedID) {
//                ForEach(vm.conversations) { convo in
//                    SidebarRow(convo: convo, showSystem: vm.showSystem)
//                }
//                .onDelete { vm.conversations.remove(atOffsets: $0) }
//            }
//            .navigationTitle("Chats")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button { vm.newChat() } label: {
//                        Label("New", systemImage: "plus")
//                    }
//                }
//            }
//        } detail: {
//            if let _ = vm.selectedID {
//                ChatDetailView()
//                    .environmentObject(vm)
//                    .focused($focus)
//            } else {
//                Text("No conversation selected")
//                    .foregroundStyle(.secondary)
//            }
//        }
//    }
//}
//
//struct SidebarRow: View {
//    let convo: Conversation
//    let showSystem: Bool
//    var preview: String {
//        let msgs = showSystem ? convo.messages : convo.messages.filter { $0.role != .system }
//        return msgs.last?.text ?? ""
//    }
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(convo.title).font(.headline)
//            Text(preview)
//                .font(.footnote)
//                .lineLimit(1)
//                .foregroundStyle(.secondary)
//        }
//        .padding(.vertical, 4)
//    }
//}
//
//struct ChatDetailView: View {
//    @EnvironmentObject var vm: ChatViewModel
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            ScrollViewReader { prox in
//                ScrollView {
//                    LazyVStack(alignment: .leading, spacing: 8) {
//                        ForEach(vm.current.messages.filter { vm.showSystem || $0.role != .system }) { msg in
//                            Bubble(msg: msg, isMe: msg.role == .user)
//                                .contextMenu { menu(for: msg) }
//                        }
//                        if vm.isLoading {
//                            TypingIndicator()
//                        }
//                    }
//                    .padding()
//                    .onChange(of: vm.current.messages.count) { _ in
//                        prox.scrollTo(vm.current.messages.last?.id, anchor: .bottom)
//                    }
//                }
//            }
//            HStack {
//                Button {
//                    vm.stt.toggle()
//                } label: {
//                    Image(systemName: vm.stt.isRecording ? "stop.circle.fill" : "mic.circle")
//                        .font(.system(size: 28))
//                        .foregroundStyle(vm.stt.isRecording ? .red : .blue)
//                }
//                TextField("Message...", text: Binding(
//                    get: { vm.draft.isEmpty ? vm.stt.transcript : vm.draft },
//                    set: { vm.draft = $0 }
//                ))
//                .textFieldStyle(.roundedBorder)
//                .focused($focus)
//                .onSubmit { vm.send() }
//                
//                Button {
//                    vm.send()
//                } label: {
//                    Image(systemName: "arrow.up.circle.fill")
//                        .font(.system(size: 28))
//                }
//                .disabled(vm.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && vm.stt.transcript.isEmpty)
//            }
//            .padding()
//        }
//        .navigationTitle(vm.current.title)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Menu {
//                    Button("Settings", action: showSettings)
//                    Toggle("Show system messages", isOn: $vm.showSystem)
//                    Toggle("Auto‑speak replies", isOn: $vm.autoSpeak)
//                } label: {
//                    Label("Options", systemImage: "ellipsis.circle")
//                }
//            }
//        }
//        .sheet(isPresented: .constant(AppSettings.shared.apiKey == nil)) {
//            SettingsView()
//        }
//    }
//    
//    @State private var showingSettings = false
//    func showSettings() { showingSettings = true }
//    
//    @ViewBuilder
//    private func menu(for msg: ChatMessage) -> some View {
//        Button("Copy", systemImage: "doc.on.doc") {
//            UIPasteboard.general.string = msg.text
//        }
//        Button("Read Aloud", systemImage: "speaker.wave.2") {
//            vm.tts.speak(msg.text)
//        }
//        ShareLink(item: msg.text) {
//            Label("Share", systemImage: "square.and.arrow.up")
//        }
//    }
//}
//
//struct Bubble: View {
//    let msg: ChatMessage, isMe: Bool
//    var body: some View {
//        HStack {
//            if isMe { Spacer() }
//            VStack(alignment: .leading, spacing: 4) {
//                Text(msg.text)
//                    .padding(10)
//                    .background(isMe ? .blue.opacity(0.2) : .gray.opacity(0.15))
//                    .clipShape(RoundedRectangle(cornerRadius: 12))
//                Text(msg.date, style: .time)
//                    .font(.caption2)
//                    .foregroundStyle(.secondary)
//            }
//            if !isMe { Spacer() }
//        }
//        .id(msg.id)
//    }
//}
//
//struct TypingIndicator: View {
//    @State private var dots = ""
//    var body: some View {
//        Text("Assistant is typing\(dots)")
//            .font(.footnote.monospaced())
//            .foregroundStyle(.secondary)
//            .onAppear {
//                Task {
//                    while true {
//                        try? await Task.sleep(nanoseconds: 400_000_000)
//                        dots = String(repeating: ".", count: (dots.count + 1) % 4)
//                    }
//                }
//            }
//            .padding(.vertical, 4)
//    }
//}
//
//struct SettingsView: View {
//    @Environment(\.dismiss) var dismiss
//    @AppStorage("openai_api_key") private var apiKey: String?
//    @EnvironmentObject var vm: ChatViewModel
//    
//    let models = ["gpt-4o-preview", "gpt-4-turbo", "gpt-3.5-turbo"]
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("OpenAI Key") {
//                    SecureField("sk-…", text: Binding(
//                        get: { apiKey ?? "" },
//                        set: { apiKey = $0 }
//                    ))
//                }
//                Section("Model & Temp") {
//                    Picker("Model", selection: $vm.model) {
//                        ForEach(models, id: \.self) { Text($0) }
//                    }
//                    Slider(value: $vm.temperature, in: 0...1, step: 0.05) {
//                        Text("Temp")
//                    }
//                    Text("\(vm.temperature, specifier: "%.2f")")
//                }
//                Section("Behavior") {
//                    Toggle("Show system", isOn: $vm.showSystem)
//                    Toggle("Auto‑TTS", isOn: $vm.autoSpeak)
//                }
//            }
//            .navigationTitle("Settings")
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Done") { dismiss() }
//                }
//            }
//        }
//    }
//}
