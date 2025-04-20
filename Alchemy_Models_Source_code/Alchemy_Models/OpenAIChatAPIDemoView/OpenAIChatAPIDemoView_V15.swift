//
//  OpenAIChatAPIDemoView_V13.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.


import SwiftUI
import Speech // For SFSpeechRecognizer
import AVFoundation // For AVAudioEngine and AVSpeechSynthesizer

// MARK: – App Entry

@main
struct GPTChatApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: – Models

enum Role: String, Codable, Hashable { // Added Hashable
    case system, user, assistant
}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var role: Role
    var text: String
    var date: Date

    init(_ role: Role, _ text: String, date: Date = .now, id: UUID = .init()) {
        self.id = id
        self.role = role
        self.text = text
        self.date = date
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
        self.created = created
        self.messages = messages
    }
}

// MARK: – Persistence

extension Conversation {
    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("conversations_v15.json") // Use distinct name if needed
    }

    static func loadAll() -> [Conversation] {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
            let data = try Data(contentsOf: fileURL)
            let convos = try JSONDecoder().decode([Conversation].self, from: data)
            return convos
        } catch {
            print("Error loading conversations: \(error.localizedDescription)")
            return []
        }
    }

    static func saveAll(_ convos: [Conversation]) {
        Task.detached(priority: .background) {
            do {
                let data = try JSONEncoder().encode(convos)
                // Added atomic write and file protection
                try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            } catch {
                print("Error saving conversations: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: – OpenAI Client

fileprivate struct ChatCompletionRequest: Encodable {
    struct Msg: Encodable { let role, content: String }
    let model: String, messages: [Msg], stream: Bool, temperature: Double
}

fileprivate struct DeltaEnvelope: Decodable {
    struct Choice: Decodable { let delta: Delta }
    struct Delta: Decodable { let content: String? }
    let choices: [Choice]
}

enum OpenAIError: LocalizedError, Equatable {
    case missingKey, badURL, requestEncodingFailed, networkError(URLError), badStatus(Int), responseDecodingFailed, canceled, streamError(String)
    var errorDescription: String? {
        switch self {
        case .missingKey:           return "Missing OpenAI API key. Please set it in Settings."
        case .badURL:               return "Internal Error: Invalid API endpoint URL."
        case .requestEncodingFailed: return "Internal Error: Failed to encode request."
        case .networkError(let e):  return "Network Error: \(e.localizedDescription)"
        case .badStatus(let c):     return "OpenAI API Error – Status Code: \(c)"
        case .responseDecodingFailed: return "Internal Error: Failed to decode API response."
        case .canceled:             return "API request canceled."
        case .streamError(let msg): return "Streaming Error: \(msg)"
        }
    }
}

actor OpenAIClient {
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let urlSession: URLSession
    // Holds the delegate instance while the stream is active
    private var streamDelegate: StreamDelegate?

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    fileprivate func stream(model: String,
                            messages: [ChatCompletionRequest.Msg],
                            temperature: Double
    ) -> AsyncThrowingStream<String, Error> {

        AsyncThrowingStream { continuation in
            // 1. Validate API Key
            guard let key = AppSettings.shared.apiKey, !key.isEmpty else {
                continuation.finish(throwing: OpenAIError.missingKey); return
            }

            // 2. Prepare Request
            var request = URLRequest(url: baseURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let payload = ChatCompletionRequest(model: model, messages: messages, stream: true, temperature: temperature)
            do {
                request.httpBody = try JSONEncoder().encode(payload)
            } catch {
                continuation.finish(throwing: OpenAIError.requestEncodingFailed); return
            }

            // 3. Create and Start Stream Delegate
            // Create instance locally before assigning to maintain strong ref via actor property
            let delegate = StreamDelegate(
                continuation: continuation,
                request: request,
                urlSession: urlSession // Pass the actor's session
            )
            // Assign to actor property to keep delegate alive during stream
            self.streamDelegate = delegate
            delegate.start() // Starts the URLSessionDataTask

            // 4. Handle Cleanup *after* stream finishes (using defer)
            do {
                 // This runs when the scope exits (continuation finishes/throws).
                 // Dispatch back to actor's context to safely modify its state.
                 Task {
                    self.clearStreamDelegateReference()
                 }
             }

            // No continuation.onTermination needed. Cleanup is handled by the
            // delegate's completion method and the defer block above.
        }
    }

    // Helper to safely clear the delegate reference on the actor's context
    private func clearStreamDelegateReference() {
         // Ask delegate to cancel its internal task (safety measure)
         streamDelegate?.cancel()
         streamDelegate = nil // Release the strong reference
        // print("Actor cleared streamDelegate reference.") // Optional debug
    }

    // Helper class to manage URLSessionDataTaskDelegate for streaming
    // Marked final to silence Sendable warning
    private final class StreamDelegate: NSObject, URLSessionDataDelegate {
        private var task: URLSessionDataTask?
        private let continuation: AsyncThrowingStream<String, Error>.Continuation
        private let request: URLRequest
        private let urlSession: URLSession // Store session used
        private var buffer: Data = Data()

        // Note: continuation, request, urlSession are immutable lets, safe for Sendable context
        // buffer and task are mutated only within the serial delegate queue/methods
        init(continuation: AsyncThrowingStream<String, Error>.Continuation, request: URLRequest, urlSession: URLSession) {
            self.continuation = continuation
            self.request = request
            self.urlSession = urlSession // Use the session from the actor
        }

        func start() {
            // Create a *new* session instance here with self as delegate
            // This ensures delegate methods are called on this instance.
             let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            task = session.dataTask(with: request)
            task?.resume()
             // Important: Don't use the actor's urlSession directly for the dataTask
             // unless that session was also configured with this delegate instance,
             // which would complicate lifetime management. Creating a session here is cleaner.
        }

        func cancel() {
            task?.cancel()
            task = nil
            // print("StreamDelegate task cancelled internally.") // Optional debug
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
             buffer.append(data)
             processBuffer()
        }

        private func processBuffer() {
           while let range = buffer.range(of: Data("\n".utf8)) {
               let lineData = buffer.subdata(in: 0..<range.lowerBound)
               buffer.removeSubrange(0..<range.upperBound)
               let line = String(decoding: lineData, as: UTF8.self)

               if line.hasPrefix("data:") {
                   let jsonString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                   guard jsonString != "[DONE]" else { continue } // Ignore DONE marker here
                   guard !jsonString.isEmpty, let jsonData = jsonString.data(using: .utf8) else { continue }

                   do {
                       let decoded = try JSONDecoder().decode(DeltaEnvelope.self, from: jsonData)
                       if let textChunk = decoded.choices.first?.delta.content {
                           continuation.yield(textChunk)
                       }
                   } catch {
                       continuation.finish(throwing: OpenAIError.responseDecodingFailed)
                       task?.cancel() // Stop on decoding error
                       return // Exit processing loop
                   }
               }
           }
       }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
             processBuffer() // Process any remaining data

            // Finish the continuation based on error or successful completion
             if let urlError = error as? URLError {
                 if urlError.code == .cancelled {
                     continuation.finish(throwing: OpenAIError.canceled)
                 } else {
                     continuation.finish(throwing: OpenAIError.networkError(urlError))
                 }
             } else if let httpResponse = task.response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                  continuation.finish(throwing: OpenAIError.badStatus(httpResponse.statusCode))
             } else if let error = error { // Other potential non-URL errors
                 continuation.finish(throwing: error)
             } else {
                 // Normal completion, no error & 2xx status
                  continuation.finish()
              }
             self.task = nil // Clear task reference
            // The conclusion of this method (and thus the continuation) triggers the actor's `defer` block
        }
    }
}

// MARK: – Settings

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    @AppStorage("openai_api_key") var apiKey: String?
    private init() {}
}

// MARK: – Speech‐to‐Text

@MainActor
final class SpeechToText: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var error: String?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override init() {
        super.init()
        speechRecognizer.delegate = self
    }

    func toggle() {
        Task { @MainActor in // Ensure toggle logic runs on main actor
            if isRecording {
                stop()
            } else {
                await start()
            }
        }
    }

    private func start() async {
        transcript = ""
        error = nil
        isRecording = false // Reset state

        // 1. Request Authorization
        let authStatus = await SFSpeechRecognizer.requestAuthorization(<#(SFSpeechRecognizerAuthorizationStatus) -> Void#>)
        guard authStatus == .authorized else {
            handleAuthorizationError(status: authStatus); return
        }

        // 2. Configure Audio Session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Audio session setup failed: \(error.localizedDescription)"; return
        }

        // 3. Prepare Recognition Request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create SFSpeechAudioBufferRecognitionRequest")
        }
        recognitionRequest.shouldReportPartialResults = true

        // 4. Start Recognition Task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return } // Capture self weakly

            var isFinal = false
            if let result = result {
                // Update MUST be on main thread as it triggers UI @Published changes
                 // self is already @MainActor isolated, so direct assignment is safe
                self.transcript = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                // stop() must be called on main actor
                 self.stop() // Call the @MainActor isolated stop method
            }
            if let error = error {
                self.error = "Recognition Error: \(error.localizedDescription)"
            }
        }

        // 5. Configure and Start Audio Engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // This closure might run on an audio thread, recognitionRequest is designed to handle this
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true // Update state after successful start
        } catch {
            self.error = "Audio Engine start failed: \(error.localizedDescription)"
            stop() // Ensure cleanup
        }
    }

     func stop() { // Already @MainActor isolated
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil

        // Consider deactivating audio session
        // try? AVAudioSession.sharedInstance().setActive(false)

        if isRecording { // Update state only if it was recording
            isRecording = false
        }
    }

    private func handleAuthorizationError(status: SFSpeechRecognizerAuthorizationStatus) {
        switch status {
        case .denied: error = "Speech recognition permission was denied. Please enable it in Settings."
        case .restricted: error = "Speech recognition is restricted on this device."
        case .notDetermined: error = "Speech recognition permission not yet requested."
        default: error = "Unknown speech recognition authorization error."
        }
        isRecording = false
    }

    // SFSpeechRecognizerDelegate method (Corrected)
    // Marked nonisolated to match protocol, dispatch back to main actor for state changes
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                // Accessing self.error and self.stop() requires MainActor
                self.error = "Speech recognizer became unavailable."
                self.stop() // Call MainActor isolated stop()
            }
        }
    }
}

// MARK: – Text‐to‐Speech

@MainActor
final class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }

        do { // Configure audio session for playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("TTS: Audio Session setup error - \(error.localizedDescription)"); return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // Fallback to default if nil
        synthesizer.speak(utterance)
        // isSpeaking = true // Handled by didStart delegate
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            // isSpeaking = false // Handled by didFinish/didCancel delegates
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate Methods (Corrected)
    // Marked nonisolated, dispatch back to main actor for state changes

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}

// MARK: – ViewModel

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = Conversation.loadAll() {
        didSet { Conversation.saveAll(conversations) }
    }
    @Published var selectedID: Conversation.ID?
    @Published var draft: String = ""
    @Published var isLoading = false
    @Published var autoSpeak = false
    @Published var showSystem = true
    @Published var model = "gpt-4-turbo"
    @Published var temperature = 0.7

    // Use @StateObject to manage lifecycle within the @MainActor ViewModel
    @StateObject var stt = SpeechToText()
    @StateObject var tts = TextToSpeech()

    private let client = OpenAIClient()
    private var apiTask: Task<Void, Never>? = nil

    init() {
        if conversations.isEmpty { newChat() }
        selectedID = selectedID ?? conversations.first?.id
    }

    var current: Conversation? {
        get { selectedID.flatMap { id in conversations.first { $0.id == id } } }
        set {
            guard let newValue = newValue, let selectedID = selectedID,
                  let index = conversations.firstIndex(where: { $0.id == selectedID }) else { return }
            conversations[index] = newValue
        }
    }

    private func appendMessage(_ message: ChatMessage) {
        guard let selectedID = selectedID, let index = conversations.firstIndex(where: { $0.id == selectedID }) else { return }
        conversations[index].messages.append(message)
    }

    private func updateLastMessage(text: String) {
        guard let selectedID = selectedID,
              let convoIndex = conversations.firstIndex(where: { $0.id == selectedID }),
              let lastMessageIndex = conversations[convoIndex].messages.indices.last,
              conversations[convoIndex].messages[lastMessageIndex].role == .assistant // Only update assistant messages
        else { return }
        conversations[convoIndex].messages[lastMessageIndex].text = text
    }

    func newChat() {
        let systemMessage = ChatMessage(.system, "You are a helpful and concise assistant.")
        let newConversation = Conversation(title: "Chat \(conversations.count + 1)", messages: [systemMessage])
        conversations.insert(newConversation, at: 0)
        selectedID = newConversation.id
    }

    func send() {
        let textToSend = draft.isEmpty ? stt.transcript : draft
        let trimmedText = textToSend.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, let currentConvo = current else { return }

        draft = ""; stt.transcript = "" // Clear inputs
        appendMessage(ChatMessage(.user, trimmedText))
        cancelStreaming() // Cancel previous task
        reply(to: currentConvo) // Start new task
    }

    private func reply(to conversation: Conversation) {
        isLoading = true
        var assistantReply = ""
        var assistantMessageID: UUID? = nil

        apiTask = Task { // Task runs in background
            do {
                 let apiMessages = conversation.messages.map {
                     ChatCompletionRequest.Msg(role: $0.role.rawValue, content: $0.text)
                 }

                // Create placeholder message on MainActor before starting stream
                 await MainActor.run {
                    let placeholder = ChatMessage(.assistant, "...")
                    assistantMessageID = placeholder.id
                    appendMessage(placeholder)
                 }

                let stream = await client.stream(
                    model: model,
                    messages: apiMessages,
                    temperature: temperature
                )

                for try await chunk in stream {
                    guard !Task.isCancelled else { throw OpenAIError.canceled }
                    assistantReply += chunk
                    // Update UI on MainActor
                    await MainActor.run { updateLastMessage(text: assistantReply) }
                }

                // Stream finished successfully
                if autoSpeak, !assistantReply.isEmpty {
                     await MainActor.run { tts.speak(assistantReply) }
                }

            } catch let error as OpenAIError {
                if error != .canceled {
                     let errorMessage = "⚠️ Error: \(error.localizedDescription)"
                     await MainActor.run { // Update UI on MainActor
                         if let msgId = assistantMessageID, updateExistingMessage(id: msgId, text: errorMessage) {}
                         else { appendMessage(ChatMessage(.assistant, errorMessage)) }
                     }
                }
            } catch { // Handle other errors
                let errorMessage = "⚠️ An unexpected error occurred: \(error.localizedDescription)"
                await MainActor.run { // Update UI on MainActor
                    if let msgId = assistantMessageID, updateExistingMessage(id: msgId, text: errorMessage) {}
                    else { appendMessage(ChatMessage(.assistant, errorMessage)) }
                 }
            }

            // Ensure loading state is updated on MainActor
            await MainActor.run { isLoading = false }
             apiTask = nil // Clear task reference
        }
    }
    
    // Helper to update an existing message by ID (requires MainActor context if called from Task)
    private func updateExistingMessage(id: UUID, text: String) -> Bool {
         guard let selected = selectedID,
                let convoIndex = conversations.firstIndex(where: { $0.id == selected }),
                let msgIndex = conversations[convoIndex].messages.firstIndex(where: { $0.id == id })
         else { return false } // Message or conversation not found
         
         conversations[convoIndex].messages[msgIndex].text = text
         return true
     }

     func cancelStreaming() {
         apiTask?.cancel()
         apiTask = nil
          if isLoading { isLoading = false }
          // Consider updating last assistant msg: updateLastMessage(text: current?.messages.last?.text ?? "" + " [Cancelled]")
     }

    func deleteConversation(at offsets: IndexSet) {
       let idsToDelete = offsets.map { conversations[$0].id }
       guard let selected = selectedID, idsToDelete.contains(selected) else {
           // Selection not affected, just remove
           conversations.remove(atOffsets: offsets)
           if conversations.isEmpty { newChat() }
           return
       }
       
       // Find index of deleted selection
        guard let deletedIndex = conversations.firstIndex(where: { $0.id == selected }) else {
            conversations.remove(atOffsets: offsets); // Should not happen
            if conversations.isEmpty { newChat() }; return
        }

       // Determine next selection
       var nextIndex: Int? = nil
       if conversations.count > 1 {
           nextIndex = (deletedIndex == 0) ? 0 : deletedIndex - 1
       }
       
       // Remove and update selection
       conversations.remove(atOffsets: offsets)
       if let index = nextIndex, index < conversations.count {
            selectedID = conversations[index].id
        } else {
            selectedID = conversations.first?.id // Fallback to first or nil
        }
       
       if conversations.isEmpty { newChat() }
   }
}

// MARK: – Views

struct RootView: View {
    @StateObject private var vm = ChatViewModel() // Owns the VM

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(vm) // Pass down owned VM
        } detail: {
            if vm.selectedID != nil {
                ChatDetailView()
                    .environmentObject(vm) // Pass down owned VM
            } else {
                Text("Select or create a chat.").font(.headline).foregroundStyle(.secondary)
            }
        }
        // Use constant binding for sheet presentation logic
        .sheet(isPresented: .constant(AppSettings.shared.apiKey == nil || AppSettings.shared.apiKey?.isEmpty == true )) {
             SettingsView()
                .environmentObject(vm) // Pass VM to Settings
                 .interactiveDismissDisabled() // Require API key
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var vm: ChatViewModel

    var body: some View {
        List(selection: $vm.selectedID) {
            ForEach(vm.conversations) { convo in
                SidebarRow(convo: convo, showSystem: vm.showSystem).tag(convo.id)
            }
            .onDelete(perform: vm.deleteConversation)
        }
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { EditButton() }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button { vm.cancelStreaming(); vm.newChat() } label: { Label("New Chat", systemImage: "plus") }
            }
        }
        .onChange(of: vm.selectedID) { _, _ in vm.cancelStreaming() } // Cancel stream on selection change
    }
}

struct SidebarRow: View {
    let convo: Conversation
    let showSystem: Bool
    var preview: String {
        (showSystem ? convo.messages : convo.messages.filter { $0.role != .system })
            .last?.text ?? "Empty Chat"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(convo.title).font(.headline)
            Text(preview.replacingOccurrences(of: "\n", with: " "))
                .font(.caption).lineLimit(1).foregroundStyle(.secondary)
        }.padding(.vertical, 4)
    }
}

struct ChatDetailView: View {
    @EnvironmentObject var vm: ChatViewModel
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(vm.current?.messages.filter { vm.showSystem || $0.role != .system } ?? []) { msg in
                            Bubble(msg: msg)
                                .id(msg.id)
                                .contextMenu { BubbleContextMenu(vm: vm, msg: msg) }
                         }
                         if vm.isLoading { TypingIndicator().id("typingIndicator") }
                     }
                    .padding(.horizontal).padding(.top)
                }
                .onChange(of: vm.current?.messages.count) { _, _ in scrollToBottom(proxy: proxy) }
                .onChange(of: vm.isLoading) { _, newValue in if newValue { scrollToBottom(proxy: proxy, anchor: .bottom) } }
                .onAppear { scrollToBottom(proxy: proxy, anchor: .bottom, animated: false) }
            }
            InputArea(vm: vm, isTextFieldFocused: $isTextFieldFocused)
                .focused($isTextFieldFocused) // Bind focus state
        }
        .navigationTitle(vm.current?.title ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
             ToolbarItemGroup(placement: .navigationBarTrailing) {
                  if vm.isLoading {
                      Button { vm.cancelStreaming() } label: {
                          Label("Stop", systemImage: "stop.circle.fill").foregroundStyle(.red)
                      }
                  }
                  Menu {
                      Button { showingSettings = true } label: { Label("Settings", systemImage: "gear") }
                      Divider()
                      Toggle(isOn: $vm.showSystem) { Label("Show System Messages", systemImage: vm.showSystem ? "eye.slash" : "eye") }
                      Toggle(isOn: $vm.autoSpeak) { Label("Auto-Speak Replies", systemImage: vm.autoSpeak ? "speaker.slash" : "speaker.wave.2") }
                  } label: { Label("Options", systemImage: "ellipsis.circle") }
             }
        }
        .sheet(isPresented: $showingSettings) { SettingsView().environmentObject(vm) }
        .gesture(DragGesture().onChanged { _ in isTextFieldFocused = false }) // Dismiss keyboard on scroll
    }

     private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom, animated: Bool = true) {
        let targetID: UUID? = vm.current?.messages.last?.id
        guard let id = vm.isLoading ? "typingIndicator" : targetID as (any Hashable)? else { return }

        if animated {
            withAnimation(.smooth(duration: 0.3)) { proxy.scrollTo(id, anchor: anchor) }
        } else {
            proxy.scrollTo(id, anchor: anchor)
        }
    }
}

struct BubbleContextMenu: View {
    @ObservedObject var vm: ChatViewModel // Observe for TTS state if needed
    let msg: ChatMessage

    var body: some View {
        Button { UIPasteboard.general.string = msg.text } label: { Label("Copy", systemImage: "doc.on.doc") }
        if msg.role == .assistant {
             Button { vm.tts.speak(msg.text) } label: { Label("Read Aloud", systemImage: "speaker.wave.2") }
        }
        ShareLink(item: msg.text) { Label("Share", systemImage: "square.and.arrow.up") }
    }
}

struct InputArea: View {
    @ObservedObject var vm: ChatViewModel
    var isTextFieldFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) { // Align to bottom for mic button
            Button { vm.stt.toggle() } label: {
                Image(systemName: vm.stt.isRecording ? "stop.circle.fill" : "mic.circle")
                    .resizable().scaledToFit().frame(width: 28, height: 28)
                    .foregroundStyle(vm.stt.isRecording ? Color.red : Color.blue)
                    .animation(.easeIn, value: vm.stt.isRecording)
            }.buttonStyle(.plain)

            // Bind text field directly to draft, managing STT logic in binding
            TextField("Message...", text: Binding(
                get: { vm.draft.isEmpty ? vm.stt.transcript : vm.draft },
                set: { newValue in
                     vm.draft = newValue
                     // If user starts typing, clear the STT transcript
                    if !newValue.isEmpty && !vm.stt.transcript.isEmpty {
                         vm.stt.transcript = ""
                     }
                 }
            ), axis: .vertical)
             .lineLimit(1...5)
             .textFieldStyle(.roundedBorder)
             .focused(isTextFieldFocused)
             .onSubmit(vm.send)

            let canSend = !vm.isLoading && (!vm.draft.isEmpty || !vm.stt.transcript.isEmpty)
            Button { if canSend { vm.send() } } label: {
                 Image(systemName: "arrow.up.circle.fill")
                     .resizable().scaledToFit().frame(width: 28, height: 28)
                     .foregroundStyle(canSend ? Color.blue : Color.gray)
            }
            .disabled(!canSend)
            .buttonStyle(.plain)
            .animation(.easeIn, value: canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }
}

struct Bubble: View {
    let msg: ChatMessage
    private var isUser: Bool { msg.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer() }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                 Text(msg.text).textSelection(.enabled)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(bubbleForeground)
                HStack { // Keep date separate for alignment
                    Text(msg.date, style: .time)
                     .font(.caption2).foregroundStyle(.secondary)
                }
                 .padding(.horizontal, isUser ? 0 : 4) // Adjust padding for alignment
            }
            .frame(maxWidth: 300, alignment: isUser ? .trailing : .leading)
            if !isUser { Spacer() }
        }
    }

    private var bubbleBackground: Color {
        switch msg.role {
        case .user: .blue
        case .assistant: Color(.systemGray5)
        case .system: Color(.systemYellow).opacity(0.5)
        }
    }
    private var bubbleForeground: Color {
        switch msg.role {
        case .user: .white
        case .assistant, .system: Color(.label) // Adapts to light/dark
        }
    }
}

struct TypingIndicator: View {
    @State private var scale: CGFloat = 0.5
    private let animation = Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)

    var body: some View {
        HStack(spacing: 4) {
             ForEach(0..<3) { i in
                 Circle().frame(width: 6, height: 6)
                      .scaleEffect(scale)
                      .animation(animation.delay(Double(i) * 0.2), value: scale)
             }
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .onAppear { scale = 1.0 } // Start animation
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: ChatViewModel // Use VM passed from parent
    @AppStorage("openai_api_key") private var apiKey: String?

    let models = ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"] // Added gpt-4o

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI API Key") {
                    SecureField("Enter your API key (sk-...)", text: Binding(
                        get: { apiKey ?? "" },
                        set: { apiKey = $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    ))
                    Link("Get API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                }
                Section("Model Configuration") {
                    Picker("Model", selection: $vm.model) {
                        ForEach(models, id: \.self) { Text($0).tag($0) }
                    }
                    VStack(alignment: .leading) {
                         Text("Temperature: \(vm.temperature, specifier: "%.2f")")
                        Slider(value: $vm.temperature, in: 0.0...1.0, step: 0.05)
                    }
                }
                Section("Behavior") {
                    Toggle(isOn: $vm.showSystem) { Label("Show System Prompts", systemImage: vm.showSystem ? "eye.slash" : "eye") }
                    Toggle(isOn: $vm.autoSpeak) { Label("Auto-Speak Replies", systemImage: vm.autoSpeak ? "speaker.slash" : "speaker.wave.2") }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .disabled(apiKey == nil || apiKey?.isEmpty == true) // Ensure API Key exists
                }
            }
        }
    }
}

/*
 REMINDER: Add necessary keys to your Info.plist:

 <key>NSMicrophoneUsageDescription</key>
 <string>Need microphone access for speech-to-text.</string>
 <key>NSSpeechRecognitionUsageDescription</key>
 <string>Need speech recognition access for transcription.</string>

 */
