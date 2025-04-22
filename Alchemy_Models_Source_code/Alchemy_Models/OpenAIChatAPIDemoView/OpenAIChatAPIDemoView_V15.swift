////
////  OpenAIChatAPIDemoView_V13.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
////  OpenAIChatAPIDemoView_V16_SpeechRecognizer.swift
//
////  Incorporating SpeechRecognizer class and authorization flow by AI Assistant on [Current Date]
////
//
//import SwiftUI
//import Speech // For SFSpeechRecognizer, SFSpeechRecognizerAuthorizationStatus etc.
//import AVFoundation // For AVAudioEngine and AVSpeechSynthesizer
//
//// MARK: – App Entry
////
////@main
////struct GPTChatApp: App {
////    var body: some Scene {
////        WindowGroup {
////            RootView()
////        }
////    }
////}
//
//// MARK: – Models
//
//enum Role: String, Codable, Hashable {
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
//            .appendingPathComponent("conversations_v16.json") // Updated filename
//    }
//    
//    static func loadAll() -> [Conversation] {
//        do {
//            guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
//            let data = try Data(contentsOf: fileURL)
//            let convos = try JSONDecoder().decode([Conversation].self, from: data)
//            return convos
//        } catch {
//            print("Error loading conversations: \(error.localizedDescription)")
//            // Consider migrating data from older versions if needed
//            return []
//        }
//    }
//    
//    static func saveAll(_ convos: [Conversation]) {
//        Task.detached(priority: .background) {
//            do {
//                let data = try JSONEncoder().encode(convos)
//                try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
//            } catch {
//                print("Error saving conversations: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//
//// MARK: – OpenAI Client (No changes needed here)
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
//enum OpenAIError: LocalizedError, Equatable {
//    case missingKey, badURL, requestEncodingFailed, networkError(URLError), badStatus(Int), responseDecodingFailed, canceled, streamError(String)
//    var errorDescription: String? {
//        switch self {
//        case .missingKey:           return "Missing OpenAI API key. Please set it in Settings."
//        case .badURL:               return "Internal Error: Invalid API endpoint URL."
//        case .requestEncodingFailed: return "Internal Error: Failed to encode request."
//        case .networkError(let e):  return "Network Error: \(e.localizedDescription)"
//        case .badStatus(let c):     return "OpenAI API Error – Status Code: \(c)"
//        case .responseDecodingFailed: return "Internal Error: Failed to decode API response."
//        case .canceled:             return "API request canceled."
//        case .streamError(let msg): return "Streaming Error: \(msg)"
//        }
//    }
//}
//
//actor OpenAIClient {
//    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
//    private let urlSession: URLSession
//    private var streamDelegate: StreamDelegate?
//    
//    init(urlSession: URLSession = .shared) {
//        self.urlSession = urlSession
//    }
//    
//    fileprivate func stream(model: String,
//                            messages: [ChatCompletionRequest.Msg],
//                            temperature: Double
//    ) -> AsyncThrowingStream<String, Error> {
//        
//        AsyncThrowingStream { continuation in
//            guard let key = AppSettings.shared.apiKey, !key.isEmpty else {
//                continuation.finish(throwing: OpenAIError.missingKey); return
//            }
//            
//            var request = URLRequest(url: baseURL)
//            request.httpMethod = "POST"
//            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            let payload = ChatCompletionRequest(model: model, messages: messages, stream: true, temperature: temperature)
//            do {
//                request.httpBody = try JSONEncoder().encode(payload)
//            } catch {
//                continuation.finish(throwing: OpenAIError.requestEncodingFailed); return
//            }
//            
//            let delegate = StreamDelegate(
//                continuation: continuation,
//                request: request,
//                urlSession: urlSession
//            )
//            self.streamDelegate = delegate
//            delegate.start()
//            
//            defer {
//                Task {
//                    await self.clearStreamDelegateReference()
//                }
//            }
//        }
//    }
//    
//    private func clearStreamDelegateReference() {
//        streamDelegate?.cancel()
//        streamDelegate = nil
//    }
//    
//    private final class StreamDelegate: NSObject, URLSessionDataDelegate {
//        private var task: URLSessionDataTask?
//        private let continuation: AsyncThrowingStream<String, Error>.Continuation
//        private let request: URLRequest
//        private let urlSession: URLSession
//        private var buffer: Data = Data()
//        
//        init(continuation: AsyncThrowingStream<String, Error>.Continuation, request: URLRequest, urlSession: URLSession) {
//            self.continuation = continuation
//            self.request = request
//            self.urlSession = urlSession
//        }
//        
//        func start() {
//            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//            task = session.dataTask(with: request)
//            task?.resume()
//        }
//        
//        func cancel() {
//            task?.cancel()
//            task = nil
//        }
//        
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//            buffer.append(data)
//            processBuffer()
//        }
//        
//        private func processBuffer() {
//            while let range = buffer.range(of: Data("\n".utf8)) {
//                let lineData = buffer.subdata(in: 0..<range.lowerBound)
//                buffer.removeSubrange(0..<range.upperBound)
//                let line = String(decoding: lineData, as: UTF8.self)
//                
//                if line.hasPrefix("data:") {
//                    let jsonString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
//                    guard jsonString != "[DONE]" else { continue }
//                    guard !jsonString.isEmpty, let jsonData = jsonString.data(using: .utf8) else { continue }
//                    
//                    do {
//                        let decoded = try JSONDecoder().decode(DeltaEnvelope.self, from: jsonData)
//                        if let textChunk = decoded.choices.first?.delta.content {
//                            continuation.yield(textChunk)
//                        }
//                    } catch {
//                        continuation.finish(throwing: OpenAIError.responseDecodingFailed)
//                        task?.cancel()
//                        return
//                    }
//                }
//            }
//        }
//        
//        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//            processBuffer()
//            
//            if let urlError = error as? URLError {
//                if urlError.code == .cancelled {
//                    continuation.finish(throwing: OpenAIError.canceled)
//                } else {
//                    continuation.finish(throwing: OpenAIError.networkError(urlError))
//                }
//            } else if let httpResponse = task.response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
//                continuation.finish(throwing: OpenAIError.badStatus(httpResponse.statusCode))
//            } else if let error = error {
//                continuation.finish(throwing: error)
//            } else {
//                continuation.finish()
//            }
//            self.task = nil
//        }
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
//// MARK: – NEW SpeechRecognizer Class
//
//@MainActor // Ensure UI updates happen on main thread
//final class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
//    @Published var transcript: String = ""
//    @Published var isRecording: Bool = false
//    @Published var errorMessage: String? // Published for UI observation
//    
//    // Private properties
//    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))! // Force unwrap assumes availability
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//    private let audioEngine = AVAudioEngine()
//    private let audioSession = AVAudioSession.sharedInstance() // Singleton for audio session
//    
//    override init() {
//        super.init()
//        recognizer.delegate = self // Set delegate in init
//    }
//    
//    // --- Public Methods ---
//    
//    /// Requests authorization for speech recognition. Calls completion on the main thread.
//    func requestAuthorization(completion: @escaping (_ authorized: Bool) -> Void) {
//        SFSpeechRecognizer.requestAuthorization { status in
//            // Ensure completion handler is called on the main thread for UI updates
//            DispatchQueue.main.async {
//                let authorized = status == .authorized
//                if !authorized {
//                    self.handleAuthorizationError(status: status) // Update error message if not authorized
//                }
//                completion(authorized)
//            }
//        }
//    }
//    
//    /// Starts the audio engine and speech recognition task. Throws errors related to audio setup.
//    func startRecording() throws {
//        guard !isRecording else { return } // Prevent starting if already recording
//        
//        // 1. Clear previous state
//        errorMessage = nil
//        transcript = ""
//        
//        // 2. Configure Audio Session
//        do {
//            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        } catch {
//            errorMessage = "Audio session setup failed: \(error.localizedDescription)"
//            throw error // Rethrow for the caller (ViewModel) to potentially handle
//        }
//        
//        // 3. Prepare Recognition Request
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        guard let recognitionRequest = recognitionRequest else {
//            fatalError("Unable to create SFSpeechAudioBufferRecognitionRequest") // Should not happen
//        }
//        recognitionRequest.shouldReportPartialResults = true
//        // Keep microphone input active even pauses occur
//        recognitionRequest.requiresOnDeviceRecognition = false // Use server-side for better accuracy generally
//        
//        // 4. Start Recognition Task
//        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
//            guard let self = self else { return } // Use weak self
//            
//            var isFinal = false
//            if let result = result {
//                // Update MUST be on main thread as it triggers UI (@MainActor isolated)
//                self.transcript = result.bestTranscription.formattedString
//                isFinal = result.isFinal
//                // print("Transcript: \(self.transcript)") // Debugging
//            }
//            
//            // Handle errors or final results
//            if error != nil || isFinal {
//                // Trigger stopRecording on the main actor
//                // This ensures audio engine and taps are managed correctly
//                self.stopRecording()
//                
//                if let error = error {
//                    // Avoid setting error message if it's just the task ending naturally
//                    if (error as NSError).code != 203 || (error as NSError).domain != "kAFAssistantErrorDomain" { // Code 203: "No speech detected"
//                        self.errorMessage = "Recognition Error: \(error.localizedDescription)"
//                        // print("Recognition Error: \(error)") // Debugging
//                    } else if self.transcript.isEmpty {
//                        self.errorMessage = "No speech detected." // Provide specific feedback
//                    }
//                }
//            }
//        }
//        
//        // 5. Configure and Start Audio Engine
//        let inputNode = audioEngine.inputNode
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        
//        // Ensure tap is removed before installing a new one
//        inputNode.removeTap(onBus: 0)
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//            // Append buffer on the audio thread IS allowed by SFSpeechAudioBufferRecognitionRequest
//            self.recognitionRequest?.append(buffer)
//        }
//        
//        audioEngine.prepare()
//        do {
//            try audioEngine.start()
//            isRecording = true // Update state only after successful start
//        } catch {
//            errorMessage = "Audio Engine start failed: \(error.localizedDescription)"
//            stopRecording() // Ensure cleanup if engine fails to start
//            throw error     // Rethrow
//        }
//    }
//    
//    /// Stops the audio engine and speech recognition task.
//    func stopRecording() {
//        // Run guard check and state update on main actor
//        guard isRecording else { return } // Prevent stopping if not recording
//        
//        if audioEngine.isRunning {
//            audioEngine.stop() // Stop the engine first
//        }
//        audioEngine.inputNode.removeTap(onBus: 0) // Remove tap after stopping
//        
//        // End audio input for the request
//        recognitionRequest?.endAudio()
//        // Ensure the request is nilled out *before* cancelling the task might be safer
//        // Although cancelling should handle it.
//        recognitionRequest = nil
//        
//        // Cancel the recognition task; this might trigger the completion handler with an error
//        recognitionTask?.cancel()
//        recognitionTask = nil
//        
//        // Deactivate audio session (optional, depends on app needs)
//        // Consider doing this asynchronously or after a small delay
//        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
//        
//        // Update state last, ensuring all cleanup is done
//        isRecording = false
//        // print("Recording Stopped") // Debugging
//    }
//    
//    // --- Private Helpers ---
//    
//    private func handleAuthorizationError(status: SFSpeechRecognizerAuthorizationStatus) {
//        switch status {
//        case .denied: errorMessage = "Speech recognition permission was denied. Please enable it in Settings."
//        case .restricted: errorMessage = "Speech recognition is restricted on this device."
//        case .notDetermined: errorMessage = "Speech recognition permission not yet requested." // Should ideally not happen here
//        default: errorMessage = "Unknown speech recognition authorization error."
//        }
//        isRecording = false // Ensure recording state is off
//    }
//    
//    // --- SFSpeechRecognizerDelegate Methods ---
//    
//    // This method might be called on a background thread. Dispatch to main actor.
//    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
//        Task { @MainActor in
//            if !available {
//                self.errorMessage = "Speech recognizer became unavailable."
//                self.stopRecording() // Ensure cleanup if recognizer goes offline
//            } else {
//                // Optionally clear error message if it becomes available again
//                // if self.errorMessage == "Speech recognizer became unavailable." {
//                //     self.errorMessage = nil
//                // }
//            }
//        }
//    }
//}
//
//// MARK: – Text‐to‐Speech (No changes needed here)
//
//@MainActor
//final class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
//    @Published var isSpeaking = false
//    private let synthesizer = AVSpeechSynthesizer()
//    
//    override init() {
//        super.init()
//        synthesizer.delegate = self
//    }
//    
//    func speak(_ text: String) {
//        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
//        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
//        
//        do {
//            let audioSession = AVAudioSession.sharedInstance()
//            try audioSession.setCategory(.playback, mode: .default, options: [])
//            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        } catch {
//            print("TTS: Audio Session setup error - \(error.localizedDescription)"); return
//        }
//        
//        let utterance = AVSpeechUtterance(string: text)
//        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
//        synthesizer.speak(utterance)
//    }
//    
//    func stop() {
//        if synthesizer.isSpeaking {
//            synthesizer.stopSpeaking(at: .immediate)
//        }
//    }
//    
//    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
//        Task { @MainActor in self.isSpeaking = true }
//    }
//    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
//        Task { @MainActor in self.isSpeaking = false }
//    }
//    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
//        Task { @MainActor in self.isSpeaking = false }
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
//    @Published var showSystem = true
//    @Published var model = "gpt-4o" // Default to latest
//    @Published var temperature = 0.7
//    
//    // Use the new SpeechRecognizer
//    @StateObject var speechRecognizer = SpeechRecognizer()
//    @StateObject var tts = TextToSpeech()
//    
//    private let client = OpenAIClient()
//    private var apiTask: Task<Void, Never>? = nil
//    
//    init() {
//        if conversations.isEmpty { newChat() }
//        selectedID = selectedID ?? conversations.first?.id
//    }
//    
//    var current: Conversation? {
//        get { selectedID.flatMap { id in conversations.first { $0.id == id } } }
//        set {
//            guard let newValue = newValue, let selectedID = selectedID,
//                  let index = conversations.firstIndex(where: { $0.id == selectedID }) else { return }
//            conversations[index] = newValue
//        }
//    }
//    
//    private func appendMessage(_ message: ChatMessage) {
//        guard let selectedID = selectedID, let index = conversations.firstIndex(where: { $0.id == selectedID }) else { return }
//        conversations[index].messages.append(message)
//    }
//    
//    private func updateLastMessage(text: String) {
//        guard let selectedID = selectedID,
//              let convoIndex = conversations.firstIndex(where: { $0.id == selectedID }),
//              let lastMessageIndex = conversations[convoIndex].messages.indices.last,
//              conversations[convoIndex].messages[lastMessageIndex].role == .assistant
//        else { return }
//        conversations[convoIndex].messages[lastMessageIndex].text = text
//    }
//    
//    func newChat() {
//        let systemMessage = ChatMessage(.system, "You are a helpful and concise assistant.")
//        let newConversation = Conversation(title: "Chat \(conversations.count + 1)", messages: [systemMessage])
//        conversations.insert(newConversation, at: 0)
//        selectedID = newConversation.id
//    }
//    
//    // --- Updated Methods for SpeechRecognizer ---
//    
//    /// Toggles speech recording, handling authorization first.
//    func toggleRecording() {
//        if speechRecognizer.isRecording {
//            speechRecognizer.stopRecording()
//        } else {
//            // Request permission FIRST
//            speechRecognizer.requestAuthorization { [weak self] authorized in
//                guard let self = self else { return }
//                if authorized {
//                    do {
//                        // If authorized, try starting
//                        try self.speechRecognizer.startRecording()
//                    } catch {
//                        // Handle errors from startRecording (e.g., audio session)
//                        // Error message is already set within speechRecognizer by startRecording
//                        print("Error starting recording in ViewModel: \(error.localizedDescription)")
//                        // Optionally show a different alert or log specific VM-level error
//                    }
//                } else {
//                    // Error message is already set within speechRecognizer by requestAuthorization
//                    print("Speech permission denied.")
//                    // Optionally trigger an alert specific to permission denial from VM
//                }
//            }
//        }
//    }
//    
//    func send() {
//        // Prioritize draft text field, then speech transcript
//        let textToSend = draft.isEmpty ? speechRecognizer.transcript : draft
//        let trimmedText = textToSend.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmedText.isEmpty, let currentConvo = current else { return }
//        
//        draft = ""; speechRecognizer.transcript = "" // Clear inputs
//        if speechRecognizer.isRecording { speechRecognizer.stopRecording() } // Stop recording if active
//        
//        appendMessage(ChatMessage(.user, trimmedText))
//        cancelStreaming() // Cancel previous reply task
//        reply(to: currentConvo) // Start new reply task
//    }
//    
//    // -------------------------------------------
//    
//    private func reply(to conversation: Conversation) {
//        isLoading = true
//        var assistantReply = ""
//        var assistantMessageID: UUID? = nil
//        
//        apiTask = Task {
//            do {
//                let apiMessages = conversation.messages.map {
//                    ChatCompletionRequest.Msg(role: $0.role.rawValue, content: $0.text)
//                }
//                
//                await MainActor.run {
//                    let placeholder = ChatMessage(.assistant, "...")
//                    assistantMessageID = placeholder.id
//                    appendMessage(placeholder)
//                }
//                
//                let stream = await client.stream(
//                    model: model,
//                    messages: apiMessages,
//                    temperature: temperature
//                )
//                
//                for try await chunk in stream {
//                    guard !Task.isCancelled else { throw OpenAIError.canceled }
//                    assistantReply += chunk
//                    await MainActor.run { updateLastMessage(text: assistantReply) }
//                }
//                
//                if autoSpeak, !assistantReply.isEmpty {
//                    await MainActor.run { tts.speak(assistantReply) }
//                }
//                
//            } catch let error as OpenAIError {
//                if error != .canceled {
//                    let errorMessage = "⚠️ OpenAI Error: \(error.localizedDescription)" // Specify source
//                    await MainActor.run {
//                        if let msgId = assistantMessageID, updateExistingMessage(id: msgId, text: errorMessage) {}
//                        else { appendMessage(ChatMessage(.assistant, errorMessage)) }
//                    }
//                }
//            } catch { // Handle other errors
//                let errorMessage = "⚠️ Unexpected Error: \(error.localizedDescription)" // Specify source
//                await MainActor.run {
//                    if let msgId = assistantMessageID, updateExistingMessage(id: msgId, text: errorMessage) {}
//                    else { appendMessage(ChatMessage(.assistant, errorMessage)) }
//                }
//            }
//            
//            await MainActor.run { isLoading = false }
//            apiTask = nil
//        }
//    }
//    
//    private func updateExistingMessage(id: UUID, text: String) -> Bool {
//        guard let selected = selectedID,
//              let convoIndex = conversations.firstIndex(where: { $0.id == selected }),
//              let msgIndex = conversations[convoIndex].messages.firstIndex(where: { $0.id == id })
//        else { return false }
//        conversations[convoIndex].messages[msgIndex].text = text
//        return true
//    }
//    
//    func cancelStreaming() {
//        apiTask?.cancel()
//        apiTask = nil
//        if isLoading { isLoading = false }
//        // Maybe update last assistant msg to indicate cancellation
//    }
//    
//    func deleteConversation(at offsets: IndexSet) {
//        let idsToDelete = offsets.map { conversations[$0].id }
//        guard let selected = selectedID, idsToDelete.contains(selected) else {
//            conversations.remove(atOffsets: offsets)
//            if conversations.isEmpty { newChat() }
//            return
//        }
//        
//        guard let deletedIndex = conversations.firstIndex(where: { $0.id == selected }) else {
//            conversations.remove(atOffsets: offsets);
//            if conversations.isEmpty { newChat() }; return
//        }
//        
//        var nextIndex: Int? = nil
//        if conversations.count > 1 {
//            nextIndex = (deletedIndex == 0) ? 0 : deletedIndex - 1
//        }
//        
//        conversations.remove(atOffsets: offsets)
//        if let index = nextIndex, index < conversations.count {
//            selectedID = conversations[index].id
//        } else {
//            selectedID = conversations.first?.id
//        }
//        
//        if conversations.isEmpty { newChat() }
//    }
//}
//
//// MARK: – Views
//
//struct RootView: View {
//    @StateObject private var vm = ChatViewModel()
//    
//    var body: some View {
//        NavigationSplitView {
//            SidebarView()
//                .environmentObject(vm)
//        } detail: {
//            if vm.selectedID != nil {
//                ChatDetailView()
//                    .environmentObject(vm)
//            } else {
//                Text("Select or create a chat.").font(.headline).foregroundStyle(.secondary)
//            }
//        }
//        .sheet(isPresented: .constant(AppSettings.shared.apiKey == nil || AppSettings.shared.apiKey?.isEmpty == true )) {
//            SettingsView()
//                .environmentObject(vm)
//                .interactiveDismissDisabled()
//        }
//    }
//}
//
//struct SidebarView: View {
//    @EnvironmentObject var vm: ChatViewModel
//    
//    var body: some View {
//        List(selection: $vm.selectedID) {
//            ForEach(vm.conversations) { convo in
//                SidebarRow(convo: convo, showSystem: vm.showSystem).tag(convo.id)
//            }
//            .onDelete(perform: vm.deleteConversation)
//        }
//        .navigationTitle("Chats")
//        .toolbar {
//            ToolbarItemGroup(placement: .navigationBarTrailing) { EditButton() }
//            ToolbarItemGroup(placement: .navigationBarLeading) {
//                Button { vm.cancelStreaming(); vm.newChat() } label: { Label("New Chat", systemImage: "plus") }
//            }
//        }
//        .onChange(of: vm.selectedID) { _, _ in
//            vm.cancelStreaming()
//            vm.speechRecognizer.stopRecording() // Stop recording on chat switch
//        }
//    }
//}
//
//struct SidebarRow: View {
//    let convo: Conversation
//    let showSystem: Bool
//    var preview: String {
//        (showSystem ? convo.messages : convo.messages.filter { $0.role != .system })
//            .last?.text ?? "Empty Chat"
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(convo.title).font(.headline)
//            Text(preview.replacingOccurrences(of: "\n", with: " "))
//                .font(.caption).lineLimit(1).foregroundStyle(.secondary)
//        }.padding(.vertical, 4)
//    }
//}
//
//struct ChatDetailView: View {
//    @EnvironmentObject var vm: ChatViewModel
//    @FocusState private var isTextFieldFocused: Bool
//    @State private var showingSettings = false
//    
//    // State for presenting the alert
//    @State private var speechErrorAlertItem: SpeechErrorAlert?
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            ScrollViewReader { proxy in
//                ScrollView {
//                    LazyVStack(alignment: .leading, spacing: 10) {
//                        ForEach(vm.current?.messages.filter { vm.showSystem || $0.role != .system } ?? []) { msg in
//                            Bubble(msg: msg)
//                                .id(msg.id)
//                                .contextMenu { BubbleContextMenu(vm: vm, msg: msg) }
//                        }
//                        if vm.isLoading { TypingIndicator().id("typingIndicator") }
//                    }
//                    .padding(.horizontal).padding(.top)
//                }
//                // Removed onChange(of: vm.current?.messages.count) as it might be redundant with isLoading
//                .onChange(of: vm.isLoading) { _, newValue in if !newValue { scrollToBottom(proxy: proxy, anchor: .bottom) } } // Scroll when loading *stops* too
//                .onChange(of: vm.current?.messages.last?.id) {_, _ in scrollToBottom(proxy: proxy, anchor: .bottom) } // Scroll on new message ID
//                .onAppear { scrollToBottom(proxy: proxy, anchor: .bottom, animated: false) }
//            }
//            InputArea(vm: vm, isTextFieldFocused: $isTextFieldFocused)
//                .focused($isTextFieldFocused)
//        }
//        .navigationTitle(vm.current?.title ?? "Chat")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItemGroup(placement: .navigationBarTrailing) {
//                if vm.isLoading {
//                    Button { vm.cancelStreaming() } label: {
//                        Label("Stop", systemImage: "stop.circle.fill").foregroundStyle(.red)
//                    }
//                }
//                Menu {
//                    Button { showingSettings = true } label: { Label("Settings", systemImage: "gear") }
//                    Divider()
//                    Toggle(isOn: $vm.showSystem) { Label("Show System Messages", systemImage: vm.showSystem ? "eye.slash" : "eye") }
//                    Toggle(isOn: $vm.autoSpeak) { Label("Auto-Speak Replies", systemImage: vm.autoSpeak ? "speaker.slash" : "speaker.wave.2") }
//                } label: { Label("Options", systemImage: "ellipsis.circle") }
//            }
//        }
//        .sheet(isPresented: $showingSettings) { SettingsView().environmentObject(vm) }
//        .gesture(DragGesture().onChanged { _ in isTextFieldFocused = false })
//        // --- Alert for Speech Errors ---
//        .onChange(of: vm.speechRecognizer.errorMessage) { _, newValue in
//            if let message = newValue {
//                speechErrorAlertItem = SpeechErrorAlert(message: message)
//            }
//        }
//        .alert(item: $speechErrorAlertItem) { alertItem in
//            Alert(
//                title: Text("Speech Recognition Error"),
//                message: Text(alertItem.message),
//                dismissButton: .default(Text("OK")) {
//                    // Important: Clear the error in the ViewModel when the alert is dismissed
//                    vm.speechRecognizer.errorMessage = nil
//                }
//            )
//        }
//        // -----------------------------
//    }
//    
//    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom, animated: Bool = true) {
//        // 1. Determine the target ID, keeping it optional initially
//        let targetID: AnyHashable?
//        
//        if vm.isLoading {
//            // If loading, the target is the string identifier for the indicator
//            targetID = "typingIndicator"
//        } else {
//            // If not loading, the target is the UUID of the last message, if it exists
//            targetID = vm.current?.messages.last?.id // This is already UUID?
//        }
//        
//        // 2. Guard against a nil target ID before scrolling
//        guard let finalTargetID = targetID else {
//            // print("Scroll cancelled: No valid target ID found.") // Optional debug log
//            return // Don't attempt to scroll if no ID exists
//        }
//        
//        // 3. Perform the scroll operation (with a slight delay for UI updates)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//            if animated {
//                withAnimation(.smooth(duration: 0.3)) { proxy.scrollTo(finalTargetID, anchor: anchor) }
//            } else {
//                proxy.scrollTo(finalTargetID, anchor: anchor)
//            }
//        }
//    }
//}
//
//// Helper struct for the alert
//struct SpeechErrorAlert: Identifiable {
//    let id = UUID()
//    let message: String
//}
//
//struct BubbleContextMenu: View {
//    @ObservedObject var vm: ChatViewModel
//    let msg: ChatMessage
//    
//    var body: some View {
//        Button { UIPasteboard.general.string = msg.text } label: { Label("Copy", systemImage: "doc.on.doc") }
//        if msg.role == .assistant {
//            Button { vm.tts.speak(msg.text) } label: { Label("Read Aloud", systemImage: "speaker.wave.2") }
//        }
//        ShareLink(item: msg.text) { Label("Share", systemImage: "square.and.arrow.up") }
//    }
//}
//
//struct InputArea: View {
//    @ObservedObject var vm: ChatViewModel // Now uses speechRecognizer via vm
//    var isTextFieldFocused: FocusState<Bool>.Binding
//    
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 10) {
//            // Button now calls vm.toggleRecording()
//            Button { vm.toggleRecording() } label: {
//                Image(systemName: vm.speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle") // Use speechRecognizer state
//                    .resizable().scaledToFit().frame(width: 28, height: 28)
//                    .foregroundStyle(vm.speechRecognizer.isRecording ? Color.red : Color.blue) // Use speechRecognizer state
//                    .animation(.easeIn, value: vm.speechRecognizer.isRecording) // Animate based on speechRecognizer state
//            }.buttonStyle(.plain)
//            
//            TextField("Message...", text: Binding(
//                get: { vm.draft.isEmpty ? vm.speechRecognizer.transcript : vm.draft }, // Read speechRecognizer transcript
//                set: { newValue in
//                    vm.draft = newValue
//                    if !newValue.isEmpty && !vm.speechRecognizer.transcript.isEmpty { // Check speechRecognizer transcript
//                        vm.speechRecognizer.transcript = "" // Clear speechRecognizer transcript if user types
//                    }
//                }
//            ), axis: .vertical)
//            .lineLimit(1...5)
//            .textFieldStyle(.roundedBorder)
//            .focused(isTextFieldFocused)
//            .onSubmit(vm.send)
//            
//            // Send condition now checks speechRecognizer transcript
//            let canSend = !vm.isLoading && (!vm.draft.isEmpty || !vm.speechRecognizer.transcript.isEmpty)
//            Button { if canSend { vm.send() } } label: {
//                Image(systemName: "arrow.up.circle.fill")
//                    .resizable().scaledToFit().frame(width: 28, height: 28)
//                    .foregroundStyle(canSend ? Color.blue : Color.gray)
//            }
//            .disabled(!canSend)
//            .buttonStyle(.plain)
//            .animation(.easeIn, value: canSend)
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//        .background(.thinMaterial)
//    }
//}
//
//struct Bubble: View {
//    let msg: ChatMessage
//    private var isUser: Bool { msg.role == .user }
//    
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 8) {
//            if isUser { Spacer() }
//            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
//                Text(msg.text).textSelection(.enabled)
//                    .padding(.horizontal, 12).padding(.vertical, 8)
//                    .background(bubbleBackground)
//                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//                    .foregroundStyle(bubbleForeground)
//                HStack {
//                    Text(msg.date, style: .time)
//                        .font(.caption2).foregroundStyle(.secondary)
//                }
//                .padding(.horizontal, isUser ? 0 : 4)
//            }
//            .frame(maxWidth: 300, alignment: isUser ? .trailing : .leading)
//            if !isUser { Spacer() }
//        }
//    }
//    private var bubbleBackground: Color { /* ... no changes ... */
//        switch msg.role {
//        case .user: .blue
//        case .assistant: Color(.systemGray5)
//        case .system: Color(.systemYellow).opacity(0.5)
//        }
//    }
//    private var bubbleForeground: Color { /* ... no changes ... */
//        switch msg.role {
//        case .user: .white
//        case .assistant, .system: Color(.label)
//        }
//    }
//}
//
//struct TypingIndicator: View { /* ... no changes ... */
//    @State private var scale: CGFloat = 0.5
//    private let animation = Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)
//    
//    var body: some View {
//        HStack(spacing: 4) {
//            ForEach(0..<3) { i in
//                Circle().frame(width: 6, height: 6)
//                    .scaleEffect(scale)
//                    .animation(animation.delay(Double(i) * 0.2), value: scale)
//            }
//        }
//        .foregroundStyle(.secondary)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.vertical, 8)
//        .onAppear { scale = 1.0 }
//    }
//}
//
//struct SettingsView: View { /* ... Mostly no changes ... */
//    @Environment(\.dismiss) var dismiss
//    @EnvironmentObject var vm: ChatViewModel
//    @AppStorage("openai_api_key") private var apiKey: String?
//    
//    let models = ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"]
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("OpenAI API Key") {
//                    SecureField("Enter your API key (sk-...)", text: Binding(
//                        get: { apiKey ?? "" },
//                        set: { apiKey = $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//                    ))
//                    Link("Get API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
//                        .font(.caption)
//                }
//                Section("Model Configuration") {
//                    Picker("Model", selection: $vm.model) {
//                        ForEach(models, id: \.self) { Text($0).tag($0) }
//                    }
//                    VStack(alignment: .leading) {
//                        Text("Temperature: \(vm.temperature, specifier: "%.2f")")
//                        Slider(value: $vm.temperature, in: 0.0...1.0, step: 0.05)
//                    }
//                }
//                Section("Behavior") {
//                    Toggle(isOn: $vm.showSystem) { Label("Show System Prompts", systemImage: vm.showSystem ? "eye.slash" : "eye") }
//                    Toggle(isOn: $vm.autoSpeak) { Label("Auto-Speak Replies", systemImage: vm.autoSpeak ? "speaker.slash" : "speaker.wave.2") }
//                }
//            }
//            .navigationTitle("Settings")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Done") { dismiss() }
//                        .disabled(apiKey == nil || apiKey?.isEmpty == true) // Stays the same
//                }
//            }
//        }
//    }
//}
//
///*
// REMINDER: Keep necessary keys in your Info.plist:
// 
// <key>NSMicrophoneUsageDescription</key>
// <string>Need microphone access for speech-to-text.</string>
// <key>NSSpeechRecognitionUsageDescription</key>
// <string>Need speech recognition access for transcription.</string>
// 
// */
//
//#Preview("RootView") {
//    RootView()
//}
