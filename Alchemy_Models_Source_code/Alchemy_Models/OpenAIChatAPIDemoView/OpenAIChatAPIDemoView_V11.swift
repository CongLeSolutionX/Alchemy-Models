//
//  OpenAIChatAPIDemoView_V11.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//  An AI-powered chat application using OpenAI's ChatGPT API,
//  featuring real-time streaming responses, speech recognition,
//  and text-to-speech capabilities.
//

import SwiftUI
import Combine
import Speech
import AVFoundation

// MARK: - Domain Models -------------------------------------------------------

enum Role: String, Codable {
    case system, user, assistant
}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var role: Role
    var text: String
    var time: Date
    
    init(_ role: Role, _ text: String, time: Date = .now, id: UUID = .init()) {
        self.id = id
        self.role = role
        self.text = text
        self.time = time
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
        self.id = id
        self.title = title
        self.messages = messages
        self.created = created
    }
}

// MARK: - Real Streaming Backend ----------------------------------------------

protocol ChatBackend {
    /// Async stream delivering reply token‑by‑token.
    func streamReply(for conversation: Conversation, temperature: Double) -> AsyncStream<String>
}

class RealChatBackend: ChatBackend {
    private let apiKey: String
    private let model: String
    
    init(apiKey: String, model: String = "gpt-3.5-turbo") {
        self.apiKey = apiKey
        self.model = model
    }
    
    func streamReply(for conversation: Conversation, temperature: Double) -> AsyncStream<String> {
        AsyncStream<String> { continuation in
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                continuation.finish()
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Prepare the messages in the format expected by OpenAI API
            let messages = conversation.messages.map { message -> [String: String] in
                return [
                    "role": message.role.rawValue,
                    "content": message.text
                ]
            }
            
            // Prepare the request body
            let requestBody: [String: Any] = [
                "model": model,
                "messages": messages,
                "temperature": temperature,
                "stream": true
            ]
            
            // Serialize the request body to JSON data
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                print("Failed to serialize request body: \(error.localizedDescription)")
                continuation.finish()
                return
            }
            
            // Create a URLSession with a delegate to handle streaming
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig,
                                     delegate: ChatAPIURLSessionDelegate(continuation: continuation),
                                     delegateQueue: nil)
            
            let streamingTask = session.dataTask(with: request)
            streamingTask.resume()
        }
    }
}

// Custom URLSessionDataDelegate to handle streaming response
class ChatAPIURLSessionDelegate: NSObject, URLSessionDataDelegate {
    let continuation: AsyncStream<String>.Continuation
    private var buffer = Data()
    
    init(continuation: AsyncStream<String>.Continuation) {
        self.continuation = continuation
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Append the new data to the buffer
        buffer.append(data)
        
        // Process the buffer line by line
        while true {
            if let range = buffer.range(of: Data("\n".utf8)) {
                let lineData = buffer.subdata(in: 0..<range.lowerBound)
                buffer.removeSubrange(0..<range.upperBound)
                
                if let line = String(data: lineData, encoding: .utf8) {
                    processLine(line)
                }
            } else {
                break
            }
        }
    }
    
    private func processLine(_ line: String) {
        guard line.starts(with: "data: ") else { return }
        let dataLine = line.dropFirst(6) // Remove "data: "
        
        if dataLine == "[DONE]" {
            continuation.finish()
            return
        }
        
        // Parse the JSON
        if let jsonData = dataLine.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]] {
                    
                    for choice in choices {
                        if let delta = choice["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            continuation.yield(content)
                        }
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Streaming task completed with error: \(error)")
        }
        continuation.finish()
    }
}

// MARK: - Speech Helpers ------------------------------------------------------

@MainActor
final class SpeechToText: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var transcript = ""
    @Published var recording = false
    @Published var error: String?
    
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private let audioEngine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    
    func toggle() {
        recording ? stop() : start()
    }
    
    private func start() {
        transcript = ""
        error = nil
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
        let request = SFSpeechAudioBufferRecognitionRequest()
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()
        
        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let error { self.setError(error.localizedDescription) }
            self.transcript = result?.bestTranscription.formattedString ?? ""
        }
        recording = true
    }
    
    private func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil
        recording = false
    }
    
    private func setError(_ message: String) {
        error = message
        stop()
    }
}

final class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var speaking = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func say(_ text: String) {
        guard !text.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        speaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speaking = false
    }
}

// MARK: - Persistence ---------------------------------------------------------

struct Persistence {
    static let url: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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
            if let data = try? JSONEncoder().encode(list) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}

// MARK: - ViewModel -----------------------------------------------------------

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = Persistence.load()
    @Published var selection: Conversation.ID?
    
    @Published var composing = ""
    @Published var isLoading = false
    @Published var settings = Settings()
    
    let speechToText = SpeechToText()
    let textToSpeech = TextToSpeech()
    
    private var backend: ChatBackend
    private var cancellables = Set<AnyCancellable>()
    
    struct Settings: Codable {
        var autoTTS = false
        var showSystem = false
        var temperature: Double = 0.7
    }
    
    init() {
        // Initialize backend with API key from Info.plist
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAI_API_Key") as? String ?? ""
        backend = RealChatBackend(apiKey: apiKey)
        
        if conversations.isEmpty { addNewConversation() }
        selection = conversations.first?.id
        
        $conversations
            .dropFirst()
            .sink { Persistence.save($0) }
            .store(in: &cancellables)
    }
    
    // MARK: - Intent Functions
    
    func addNewConversation() {
        let systemMessage = ChatMessage(.system, "You are a helpful assistant.")
        conversations.insert(Conversation(title: "Chat \(conversations.count + 1)",
                                          messages: [systemMessage]), at: 0)
        selection = conversations.first?.id
    }
    
    func delete(_ offsets: IndexSet) {
        conversations.remove(atOffsets: offsets)
    }
    
    func rename(_ conversation: Conversation, to newTitle: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[index].title = newTitle
    }
    
    func send() {
        guard var conversation = currentConversation,
              !composedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        
        let userMessage = ChatMessage(.user, composedText.trimmingCharacters(in: .whitespacesAndNewlines))
        conversation.messages.append(userMessage)
        update(conversation)
        composing = ""
        speechToText.transcript = ""
        Task {
            await generateReply(for: conversation)
        }
    }
    
    private func generateReply(for conversation: Conversation) async {
        isLoading = true
        var workingConversation = conversation
        var buffer = ""
        for await token in backend.streamReply(for: conversation, temperature: settings.temperature) {
            buffer += token
            if workingConversation.messages.last?.role == .assistant {
                workingConversation.messages[workingConversation.messages.count - 1].text = buffer
            } else {
                workingConversation.messages.append(ChatMessage(.assistant, buffer))
            }
            update(workingConversation)
        }
        isLoading = false
        if settings.autoTTS {
            textToSpeech.say(buffer)
        }
    }
    
    var composedText: String {
        composing.isEmpty ? speechToText.transcript : composing
    }
    
    var currentConversation: Conversation? {
        conversations.first(where: { $0.id == selection })
    }
    
    private func update(_ conversation: Conversation) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[index] = conversation
    }
}

// MARK: - Views ----------------------------------------------------------------

struct RootView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettings = false
    @FocusState private var focusTextField
    
    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selection) {
                ForEach(viewModel.conversations) { conversation in
                    ConversationRow(conversation)
                        .contextMenu {
                            renameButton(conversation)
                            deleteButton([conversation])
                        }
                }
                .onDelete(perform: viewModel.delete)
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem {
                    Button(action: viewModel.addNewConversation) {
                        Label("New", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let conversation = viewModel.currentConversation {
                VStack(spacing: 0) {
                    ChatScrollView(viewModel: viewModel, conversation: conversation)
                    ChatInputBar(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                        .focused($focusTextField)
                }
                .navigationTitle(conversation.title)
                .toolbar { detailToolbar(conversation) }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(viewModel: viewModel)
                }
                .onTapGesture {
                    focusTextField = false
                }
            } else {
                ContentUnavailableView("No conversation selected",
                                       systemImage: "ellipsis.bubble")
            }
        }
    }
    
    // MARK: - Helper Buttons and Toolbars
    
    private func detailToolbar(_ conversation: Conversation) -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: { showingSettings = true }) {
                Label("Settings", systemImage: "gearshape")
            }
            Menu {
                renameButton(conversation)
                deleteButton([conversation])
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }
    
    private func renameButton(_ conversation: Conversation) -> some View {
        Button(action: { promptRename(conversation) }) {
            Label("Rename", systemImage: "pencil")
        }
    }
    
    private func deleteButton(_ conversations: [Conversation]) -> some View {
        Button(role: .destructive) {
            if let conversation = conversations.first,
               let index = viewModel.conversations.firstIndex(of: conversation) {
                viewModel.delete(IndexSet(integer: index))
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func promptRename(_ conversation: Conversation) {
#if canImport(UIKit)
        let alert = UIAlertController(title: "Rename Chat", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = conversation.title }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let text = alert.textFields?.first?.text ?? ""
            if !text.isEmpty { viewModel.rename(conversation, to: text) }
        })
        UIApplication.shared.topViewController?.present(alert, animated: true)
#endif
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    var lastLine: String {
        conversation.messages.last(where: { $0.role != .system })?.text ?? ""
    }
    
    init(_ conversation: Conversation) {
        self.conversation = conversation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(conversation.title)
                .font(.headline)
            Text(lastLine)
                .font(.footnote)
                .lineLimit(1)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ChatScrollView: View {
    @ObservedObject var viewModel: ChatViewModel
    let conversation: Conversation
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(conversation.messages.filter { viewModel.settings.showSystem || $0.role != .system }) { message in
                        MessageBubble(message, own: message.role == .user)
                            .contextMenu {
                                Button(action: {
#if canImport(UIKit)
                                    UIPasteboard.general.string = message.text
#endif
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                Button(action: {
                                    viewModel.textToSpeech.say(message.text)
                                }) {
                                    Label("Read Aloud", systemImage: "speaker.wave.2")
                                }
                                ShareLink(item: message.text) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                            }
                    }
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: conversation.messages.last?.id) {
                withAnimation {
                    proxy.scrollTo(conversation.messages.last?.id, anchor: .bottom)
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let own: Bool
    
    init(_ message: ChatMessage, own: Bool) {
        self.message = message
        self.own = own
    }
    
    var color: Color {
        own ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15)
    }
    
    var body: some View {
        HStack {
            if own { Spacer() }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .padding(10)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(message.time, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(own ? .trailing : .leading, 6)
            }
            if !own { Spacer() }
        }
        .id(message.id)
    }
}

struct ChatInputBar: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.speechToText.toggle()
            }) {
                Image(systemName: viewModel.speechToText.recording ? "stop.circle.fill" : "mic.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(viewModel.speechToText.recording ? .red : .blue)
            }
            .accessibilityLabel("Microphone")
            
            TextField("Type a message", text:
                        Binding(get: { viewModel.composedText },
                                set: { viewModel.composing = $0 }))
            .textFieldStyle(.roundedBorder)
            .onSubmit(viewModel.send)
            
            Button(action: viewModel.send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
            }
            .disabled(viewModel.composedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Toggle("Speak replies aloud", isOn: $viewModel.settings.autoTTS)
                    Toggle("Show system messages", isOn: $viewModel.settings.showSystem)
                }
                Section("Model Settings") {
                    Slider(value: $viewModel.settings.temperature, in: 0...1) {
                        Text("Temperature")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("1")
                    }
                    Text("Temperature: \(viewModel.settings.temperature, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - UIKit Helpers -------------------------------------------------------

#if canImport(UIKit)
extension UIApplication {
    var topViewController: UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        return topViewController(from: root)
    }
    
    private func topViewController(from controller: UIViewController) -> UIViewController {
        if let presented = controller.presentedViewController {
            return topViewController(from: presented)
        } else if let navigation = controller as? UINavigationController,
                  let top = navigation.topViewController {
            return topViewController(from: top)
        } else if let tab = controller as? UITabBarController,
                  let selected = tab.selectedViewController {
            return topViewController(from: selected)
        } else {
            return controller
        }
    }
}
#endif

#Preview("RootView"){
    RootView()
}
// MARK: - App Entry Point -----------------------------------------------------
//
//@main
//struct AIChatApp: App {
//    var body: some Scene {
//        WindowGroup {
//            RootView()
//        }
//    }
//}
