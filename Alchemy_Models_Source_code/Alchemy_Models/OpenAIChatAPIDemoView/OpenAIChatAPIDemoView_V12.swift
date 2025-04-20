////
////  OpenAIChatAPIDemoView_V12.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  MiniGPTChatApp.swift
////  Created 2024‑05‑29 – single‑file production demo
////
//
//import SwiftUI
//import Combine
//import Speech
//import AVFoundation
//
//// MARK: - Domain models -------------------------------------------------------
//
//enum Role: String, Codable { case system, user, assistant }
//
//struct ChatMessage: Identifiable, Codable, Hashable {
//    let id: UUID
//    var role: Role
//    var text: String
//    var time: Date
//    
//    init(_ role: Role, _ text: String,
//         time: Date = .now, id: UUID = .init()) {
//        self.id = id; self.role = role; self.text = text; self.time = time
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
//        self.id = id; self.title = title
//        self.created = created; self.messages = messages
//    }
//}
//
//// MARK: - Secrets helper ------------------------------------------------------
//
//enum Secrets {
//    static let apiKey: String? = {
//        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
//            return env
//        }
//        return UserDefaults.standard.string(forKey: "openai_api_key")
//    }()
//}
//
//// MARK: - OpenAI networking layer (SSE) ---------------------------------------
//
//struct ChatCompletionRequest: Encodable {
//    struct Message: Encodable { let role: String; let content: String }
//    let model: String
//    let messages: [Message]
//    let stream: Bool
//    let temperature: Double
//}
//
//private struct DeltaEnvelope: Decodable {
//    struct Choice: Decodable { let delta: Delta }
//    struct Delta: Decodable { let content: String? }
//    let choices: [Choice]
//}
//
//enum OpenAIError: LocalizedError {
//    case invalidKey, badStatus(Int), cancelled
//    var errorDescription: String? {
//        switch self {
//        case .invalidKey:  "Missing OpenAI API key"
//        case .badStatus(let c): "OpenAI error – status \(c)"
//        case .cancelled:   "Cancelled"
//        }
//    }
//}
//
//actor OpenAIClient {
//    func stream(request: ChatCompletionRequest)
//        -> AsyncThrowingStream<String, Error> {
//        AsyncThrowingStream { continuation in
//            guard let key = Secrets.apiKey else {
//                continuation.finish(throwing: OpenAIError.invalidKey); return
//            }
//            var urlReq = URLRequest(
//                url: URL(string: "https://api.openai.com/v1/chat/completions")!
//            )
//            urlReq.httpMethod = "POST"
//            urlReq.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
//            urlReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            urlReq.httpBody = try? JSONEncoder().encode(request)
//            
//            let delegate = StreamingDelegate(onLine: { line in
//                let json = line.dropFirst(6)              // remove "data: "
//                guard json != "[DONE]",
//                      let data = json.data(using: .utf8),
//                      let env = try? JSONDecoder().decode(DeltaEnvelope.self, from: data),
//                      let piece = env.choices.first?.delta.content else { return }
//                continuation.yield(piece)
//            }, onClose: { status in
//                if status != 200 {
//                    continuation.finish(throwing: OpenAIError.badStatus(status))
//                } else { continuation.finish() }
//            })
//            delegate.start(with: urlReq)
//            continuation.onTermination = { _ in delegate.cancel() }
//        }
//    }
//}
//
//private final class StreamingDelegate: NSObject, URLSessionDataDelegate {
//    private let onLine: (String) -> Void
//    private let onClose: (Int) -> Void
//    private lazy var session = URLSession(configuration: .default,
//                                          delegate: self,
//                                          delegateQueue: nil)
//    private var task: URLSessionDataTask?
//    
//    init(onLine: @escaping (String)->Void,
//         onClose: @escaping (Int)->Void) { self.onLine = onLine; self.onClose = onClose }
//    
//    func start(with req: URLRequest) {
//        task = session.dataTask(with: req)
//        task?.resume()
//    }
//    func cancel() { task?.cancel() }
//    
//    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
//                    didReceive data: Data) {
//        guard let str = String(data: data, encoding: .utf8) else { return }
//        for line in str.split(separator: "\n") where line.hasPrefix("data:") {
//            onLine(String(line))
//        }
//    }
//    func urlSession(_ session: URLSession, task: URLSessionTask,
//                    didCompleteWithError _: Error?) {
//        onClose((task.response as? HTTPURLResponse)?.statusCode ?? -1)
//    }
//}
//
//// MARK: - Backend adapter -----------------------------------------------------
//
//protocol ChatBackend {
//    func streamReply(for conversation: Conversation) -> AsyncStream<String>
//}
//
//struct OpenAIStreamingBackend: ChatBackend {
//    let config: ChatVM.Settings
//    let client = OpenAIClient()
//    
//    func streamReply(for conversation: Conversation) -> AsyncStream<String> {
//        let req = ChatCompletionRequest(
//            model: config.model,
//            messages: conversation.messages.map {
//                .init(role: $0.role.rawValue, content: $0.text)
//            },
//            stream: true,
//            temperature: config.temperature
//        )
//        return .init {_ in
////            continuation in
////            Task {
////                do {
////                    for try await token in await client.stream(request: req) {
////                        continuation.yield(token)
////                    }
////                    continuation.finish()
////                } catch {
////                    continuation.finish(throwing: error)
////                }
////            }
//        }
//    }
//}
//
//// MARK: - Speech helpers ------------------------------------------------------
//
//@MainActor
//final class SpeechToText: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
//    @Published var transcript = ""
//    @Published var recording = false
//    @Published var error: String?
//    
//    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
//    private let audioEngine = AVAudioEngine()
//    private var task: SFSpeechRecognitionTask?
//    
//    func toggle() { recording ? stop() : start() }
//    
//    private func start() {
//        transcript = ""; error = nil
//        recognizer?.delegate = self
//        SFSpeechRecognizer.requestAuthorization { status in
//            guard status == .authorized else {
//                Task { @MainActor in self.setError("Speech permission denied") }
//                return
//            }
//            Task { @MainActor in self.begin() }
//        }
//    }
//    
//    private func begin() {
//        let node = audioEngine.inputNode
//        let format = node.outputFormat(forBus: 0)
//        let req = SFSpeechAudioBufferRecognitionRequest()
//        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buf, _ in
//            req.append(buf)
//        }
//        audioEngine.prepare()
//        try? audioEngine.start()
//        
//        task = recognizer?.recognitionTask(with: req) { [weak self] res, err in
//            guard let self else { return }
//            if let err { self.setError(err.localizedDescription) }
//            transcript = res?.bestTranscription.formattedString ?? ""
//        }
//        recording = true
//    }
//    
//    private func stop() {
//        audioEngine.stop()
//        audioEngine.inputNode.removeTap(onBus: 0)
//        task?.cancel(); task = nil
//        recording = false
//    }
//    private func setError(_ msg: String) { error = msg; stop() }
//}
//
//@MainActor
//final class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
//    @Published var speaking = false
//    private let synth = AVSpeechSynthesizer()
//    override init() { super.init(); synth.delegate = self }
//    
//    func say(_ txt: String) {
//        guard !txt.isEmpty else { return }
//        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
//        let u = AVSpeechUtterance(string: txt)
//        u.voice = .init(language: "en-US")
//        synth.speak(u)
//    }
//    func speechSynthesizer(_ s: AVSpeechSynthesizer,
//                           didStart _: AVSpeechUtterance) { speaking = true }
//    func speechSynthesizer(_ s: AVSpeechSynthesizer,
//                           didFinish _: AVSpeechUtterance) { speaking = false }
//}
//
//// MARK: - Persistence ---------------------------------------------------------
//
//struct Persistence {
//    static let url: URL = {
//        FileManager.default.urls(for: .documentDirectory,
//                                 in: .userDomainMask)[0]
//            .appendingPathComponent("conversations.json")
//    }()
//    static func load() -> [Conversation] {
//        guard let d = try? Data(contentsOf: url),
//              let list = try? JSONDecoder().decode([Conversation].self, from: d)
//        else { return [] }
//        return list
//    }
//    static func save(_ list: [Conversation]) {
//        DispatchQueue.global(qos: .background).async {
//            if let d = try? JSONEncoder().encode(list) {
//                try? d.write(to: url, options: .atomic)
//            }
//        }
//    }
//}
//
//// MARK: - View‑model ----------------------------------------------------------
//
//@MainActor
//final class ChatVM: ObservableObject {
//    @Published var conversations: [Conversation] = Persistence.load()
//    @Published var selection: Conversation.ID?
//    @Published var composing = ""
//    @Published var isLoading = false
//    @Published var settings = Settings()
//    
//    let stt = SpeechToText()
//    let tts = TextToSpeech()
//    
//    struct Settings: Codable {
//        var autoTTS = false
//        var showSystem = false
//        var temperature: Double = 0.7
//        var model: String = "gpt-3.5-turbo"
//    }
//    
//    var backend: ChatBackend
//    var bag = Set<AnyCancellable>()
//    
//    init?(conversations: [Conversation]?, selection: Conversation.ID? = nil, composing: String = "", isLoading: Bool = false, settings: Settings = Settings(), backend: ChatBackend, bag: Set<AnyCancellable> = Set<AnyCancellable>()) {
//        return nil
//    }
////    init() {
////        if conversations.isEmpty { addNewConversation() }
////        selection = conversations.first?.id
////        backend = OpenAIStreamingBackend(config: settings)
////        
////        $conversations
////            .dropFirst()                                         // skip initial load
////            .sink { Persistence.save($0) }
////            .store(in: &bag)
////    }
//    
//    // MARK: intents
//    
//    func addNewConversation() {
//        let sys = ChatMessage(.system, "You are a helpful assistant.")
//        conversations.insert(Conversation(title: "Chat \(conversations.count+1)",
//                                          messages: [sys]), at: 0)
//        selection = conversations.first?.id
//    }
//    func delete(_ offsets: IndexSet) { conversations.remove(atOffsets: offsets) }
//    
//    func rename(_ c: Conversation, to new: String) {
//        guard let i = conversations.firstIndex(where: { $0.id == c.id }) else { return }
//        conversations[i].title = new
//    }
//    
//    var composedText: String {
//        composing.isEmpty ? stt.transcript : composing
//    }
//    
//    func send() {
//        guard var convo = current,
//              !composedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//        else { return }
//        let user = ChatMessage(.user,
//                               composedText.trimmingCharacters(in: .whitespacesAndNewlines))
//        convo.messages.append(user)
//        update(convo)
//        composing = ""; stt.transcript = ""
//        Task { await reply(for: convo) }
//    }
//    
//    private func reply(for convo: Conversation) async {
//        UIImpactFeedbackGenerator(style: .light).impactOccurred()
//        isLoading = true
//        backend = OpenAIStreamingBackend(config: settings) // inject latest
//        var working = convo
//        var buffer = ""
//        do {
//            for await token in backend.streamReply(for: convo) {
//                buffer += token
//                if working.messages.last?.role == .assistant {
//                    working.messages[working.messages.count-1].text = buffer
//                } else {
//                    working.messages.append(ChatMessage(.assistant, buffer))
//                }
//                update(working)
//            }
//            if settings.autoTTS { tts.say(buffer) }
//        } catch {
//            working.messages.append(ChatMessage(.assistant,
//               "⚠️ \(error.localizedDescription)"))
//            update(working)
//        }
//        isLoading = false
//    }
//    
//    var current: Conversation? {
//        conversations.first(where: { $0.id == selection })
//    }
//    private func update(_ convo: Conversation) {
//        guard let i = conversations.firstIndex(where: { $0.id == convo.id }) else { return }
//        conversations[i] = convo
//    }
//}
//
//// MARK: - Views ---------------------------------------------------------------
//
//struct RootView: View {
//    @StateObject private var vm = ChatVM(conversations: [Conversation](), backend: (any ChatBackend).self as! ChatBackend)
//    @State private var showSettings = false
//    @FocusState private var focusText
//    
//    var body: some View {
//        NavigationSplitView {
//            List(selection: $vm.selection) {
//                ForEach(vm.conversations) { c in
//                    ConversationRow(convo: c)
//                        .contextMenu { renameBtn(c); deleteBtn([c]) }
//                }
//                .onDelete(perform: vm.delete)
//            }
//            .navigationTitle("Chats")
//            .toolbar { ToolbarItem { Button("New", systemImage: "plus", action: vm.addNewConversation) } }
//            
//        } detail: {
//            if let convo = vm.current {
//                VStack(spacing: 0) {
//                    ChatScrollView(vm: vm, convo: convo)
//                    ChatInputBar(vm: vm)
//                        .padding(.horizontal)
//                        .padding(.bottom, 6)
//                        .focused($focusText)
//                }
//                .navigationTitle(convo.title)
//                .toolbar { detailBar(convo) }
//                .sheet(isPresented: $showSettings) { SettingsView(vm: vm) }
//                .onTapGesture { focusText = false }
//            } else {
//                ContentUnavailableView("No conversation selected",
//                                       systemImage: "ellipsis.bubble")
//            }
//        }
//    }
//    
//    // MARK: helper buttons
//    @ToolbarContentBuilder
//    private func detailBar(_ c: Conversation) -> some ToolbarContent {
//        ToolbarItemGroup(placement: .navigationBarTrailing) {
//            Button("Settings", systemImage: "gearshape") { showSettings = true }
//            Menu { renameBtn(c); deleteBtn([c]) } label: {
//                Label("More", systemImage: "ellipsis.circle")
//            }
//        }
//    }
//    private func renameBtn(_ c: Conversation) -> some View {
//        Button("Rename", systemImage: "pencil") { promptRename(c) }
//    }
//    private func deleteBtn(_ cs: [Conversation]) -> some View {
//        Button(role: .destructive) {
//            if let idx = vm.conversations.firstIndex(of: cs[0]) {
//                vm.delete(IndexSet(integer: idx))
//            }
//        } label: { Label("Delete", systemImage: "trash") }
//    }
//    private func promptRename(_ c: Conversation) {
//#if canImport(UIKit)
//        let alert = UIAlertController(title: "Rename Chat", message: nil,
//                                      preferredStyle: .alert)
//        alert.addTextField { $0.text = c.title }
//        alert.addAction(.init(title: "Cancel", style: .cancel))
//        alert.addAction(.init(title: "Save", style: .default) { _ in
//            let txt = alert.textFields?.first?.text ?? ""
//            if !txt.isEmpty { vm.rename(c, to: txt) }
//        })
//        UIApplication.shared.top?.present(alert, animated: true)
//#endif
//    }
//}
//
//struct ConversationRow: View {
//    let convo: Conversation
//    var lastLine: String {
//        convo.messages.last(where: { $0.role != .system })?.text ?? ""
//    }
//    var body: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            Text(convo.title).font(.headline)
//            Text(lastLine).font(.footnote).lineLimit(1)
//                .foregroundStyle(.secondary)
//        }.padding(.vertical, 4)
//    }
//}
//
//struct ChatScrollView: View {
//    @ObservedObject var vm: ChatVM
//    let convo: Conversation
//    @State private var dots = ""
//   
//    var body: some View {
//        Text("ChatScrollView")
//    }
////    var body: some View {
////        ScrollViewReader { proxy in
////            ScrollView {
////                LazyVStack(alignment: .leading, spacing: 8) {
////                    ForEach(convo.messages.filter { vm.settings.showSystem || $0.role != .system }) { m in
////                        MessageBubble(m, own: m.role == .user)
////                            .contextMenu {
////                                Button("Copy", systemImage: "doc.on.doc") {
////                                    UIPasteboard.general.string = m.text
////                                }
////                                Button("Read Aloud", systemImage: "speaker.wave.2") {
////                                    vm.tts.say(m.text)
////                                }
////                                ShareLink(item: m.text) {
////                                    Label("Share", systemImage: "square.and.arrow.up")
////                                }
////                            }
////                    }
////                    if vm.isLoading {
////                        Text("Assistant is typing\(dots)")
////                            .monospaced()
////                            .font(.footnote)
////                            .foregroundStyle(.secondary)
////                            .task {
////                                // animate dots …
////                                while vm.isLoading {
////                                    dots = String(repeating: ".", count: (dots.count+1)%4)
////                                    try? await Task.sleep(for: .milliseconds(350))
////                                }
////                                dots = ""
////                            }
////                            .padding(.vertical, 4)
////                    }
////                }
////                .padding(.horizontal)
////            }
////            .onChange(of: convo.messages.last?.id) {
////                withAnimation { proxy.scrollTo(convo.messages.last?.id,
////                                               anchor: .bottom) }
////            }
////        }
////    }
//}
//
//struct MessageBubble: View {
//    let msg: ChatMessage; let own: Bool
//    var color: Color { own ? .blue.opacity(0.2) : .gray.opacity(0.15) }
//    var body: some View {
//        HStack {
//            if own { Spacer() }
//            VStack(alignment: .leading, spacing: 4) {
//                Text(msg.text)
//                    .padding(10)
//                    .background(color)
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//                Text(msg.time, style: .time)
//                    .font(.caption2).foregroundStyle(.secondary)
//                    .padding(own ? .trailing : .leading, 6)
//            }
//            if !own { Spacer() }
//        }
//        .id(msg.id)
//    }
//}
//
//struct ChatInputBar: View {
//    @ObservedObject var vm: ChatVM
//    var body: some View {
//        HStack {
//            Button("", systemImage: vm.stt.recording ? "stop.circle.fill" : "mic.circle") {
//                vm.stt.toggle()
//            }
//            .font(.system(size: 28))
//            .foregroundStyle(vm.stt.recording ? .red : .blue)
//            .accessibilityLabel("Microphone")
//            
//            TextField("Type a message",
//                      text: Binding(get: { vm.composedText },
//                                    set: { vm.composing = $0 }))
//            .textFieldStyle(.roundedBorder)
//            .onSubmit(vm.send)
//            
//            Button("", systemImage: "arrow.up.circle.fill", action: vm.send)
//                .font(.system(size: 28))
//                .disabled(vm.composedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//        }
//    }
//}
//
//struct SettingsView: View {
//    @ObservedObject var vm: ChatVM
//    @Environment(\.dismiss) private var dismiss
//    private let models = ["gpt-4o-preview", "gpt-4-turbo", "gpt-3.5-turbo"]
//    @State private var tmpKey = Secrets.apiKey ?? ""
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("OpenAI Account") {
//                    SecureField("API key", text: $tmpKey, prompt: Text("sk‑..."))
//                        .textContentType(.password)
//                    Button("Save Key", action: saveKey)
//                }
//                Section("Model") {
//                    Picker("Model", selection: $vm.settings.model) {
//                        ForEach(models, id:\.self) { Text($0) }
//                    }.pickerStyle(.menu)
//                    Slider(value: $vm.settings.temperature, in: 0...1, step: 0.05) {
//                        Text("Temperature")
//                    }
//                    Text("\(vm.settings.temperature, specifier: "%.2f")")
//                }
//                Section("General") {
//                    Toggle("Speak replies aloud", isOn: $vm.settings.autoTTS)
//                    Toggle("Show system messages", isOn: $vm.settings.showSystem)
//                }
//            }
//            .navigationTitle("Settings")
//            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
//        }
//    }
//    private func saveKey() {
//        guard !tmpKey.isEmpty else { return }
//        UserDefaults.standard.setValue(tmpKey, forKey: "openai_api_key")
//    }
//}
//
//// MARK: - UIKit helpers -------------------------------------------------------
//
//#if canImport(UIKit)
//extension UIApplication {
//    var top: UIViewController? {
//        guard let scene = connectedScenes.first as? UIWindowScene,
//              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
//        else { return nil }
//        var t = root
//        while let nxt = t.presentedViewController { t = nxt }
//        return t
//    }
//}
//#endif
//
//
//#Preview("RootView") {
//    RootView()
//}
//// MARK: - App entry -----------------------------------------------------------
////
////@main
////struct MiniGPTChatApp: App {
////    var body: some Scene {
////        WindowGroup { RootView() }
////    }
////}
