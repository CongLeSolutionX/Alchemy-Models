//
//  OpenAIChatAPIDemoView_V13.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

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

enum Role: String, Codable {
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
        // Prefer Application Support for non-user-generated data, but Documents is common for simple apps
        // Using Documents Directory for simplicity as in the original code.
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("conversations.json")
    }
    
    static func loadAll() -> [Conversation] {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return [] // No file exists yet
            }
            let data = try Data(contentsOf: fileURL)
            let convos = try JSONDecoder().decode([Conversation].self, from: data)
            return convos
        } catch {
            print("Error loading conversations: \(error.localizedDescription)")
            // Consider migrating corrupt data or deleting the file
            // For now, return empty array on error
            return []
        }
    }
    
    static func saveAll(_ convos: [Conversation]) {
        // Perform saving on a background thread to avoid blocking the main thread
        Task.detached(priority: .background) {
            do {
                let data = try JSONEncoder().encode(convos)
                try data.write(to: fileURL, options: [.atomic, .completeFileProtection]) // Added atomic and file protection
                // print("Conversations saved successfully to \(fileURL.path)") // Optional: for debugging
            } catch {
                // Use await MainActor.run {} if you need to update UI about the error
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
    // Use URLComponents for safer URL construction if needed, but base URL is static here.
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let urlSession: URLSession
    private var streamDelegate: StreamDelegate?
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    // Using AsyncThrowingStream for streaming responses
    fileprivate func stream(model: String,
                            messages: [ChatCompletionRequest.Msg],
                            temperature: Double
    ) -> AsyncThrowingStream<String, Error> {
        
        AsyncThrowingStream { continuation in
            // 1. Validate API Key
            guard let key = AppSettings.shared.apiKey, !key.isEmpty else {
                continuation.finish(throwing: OpenAIError.missingKey)
                return
            }
            
            // 2. Prepare Request
            var request = URLRequest(url: baseURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload = ChatCompletionRequest(
                model: model,
                messages: messages,
                stream: true,
                temperature: temperature
            )
            
            do {
                request.httpBody = try JSONEncoder().encode(payload)
            } catch {
                continuation.finish(throwing: OpenAIError.requestEncodingFailed)
                return
            }
            
            // 3. Create and Start Stream Delegate
            // Keep a strong reference while the stream is active
            streamDelegate = StreamDelegate(
                continuation: continuation,
                request: request,
                urlSession: urlSession
            )
            
            // The delegate handles starting the task and processing events.
            streamDelegate?.start()
            
            // 4. Handle Termination
            continuation.onTermination = { @Sendable [weak self] _ in
                // Ensure delegate cleanup if continuation is terminated externally
                self?.streamDelegate?.cancel()
                self?.streamDelegate = nil // Release the delegate
                // print("Stream terminated.") // Optional debugging
            }
        }
    }
    
    // Helper class to manage the URLSessionDataTaskDelegate for streaming
    private class StreamDelegate: NSObject, URLSessionDataDelegate {
        private var task: URLSessionDataTask?
        private let continuation: AsyncThrowingStream<String, Error>.Continuation
        private let request: URLRequest
        private let urlSession: URLSession
        private var buffer: Data = Data() // Buffer for incomplete SSE lines
        
        init(continuation: AsyncThrowingStream<String, Error>.Continuation, request: URLRequest, urlSession: URLSession) {
            self.continuation = continuation
            self.request = request
            self.urlSession = urlSession
        }
        
        func start() {
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil) // OperationQueue() if needed
            task = session.dataTask(with: request)
            task?.resume()
        }
        
        func cancel() {
            task?.cancel()
            task = nil
            // When cancelling externally, signal the continuation if it hasn't finished
            // Continuation might already be finished, so a check or careful state management is needed
            // This is often handled by the `didCompleteWithError` check below for URLError.cancelled
            // print("Stream task cancelled.") // Optional debugging
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            buffer.append(data)
            processBuffer()
        }
        
        private func processBuffer() {
            // Process buffer line by line based on SSE format (newline separated)
            while let range = buffer.range(of: Data("\n".utf8)) {
                let lineData = buffer.subdata(in: 0..<range.lowerBound)
                buffer.removeSubrange(0..<range.upperBound) // Remove line + newline
                
                let line = String(decoding: lineData, as: UTF8.self)
                
                // SSE lines start with "data: "
                if line.hasPrefix("data:") {
                    let jsonString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces) // "data: ".count == 5
                    
                    guard jsonString != "[DONE]" else {
                        // print("Stream received [DONE] marker.") // Optional debugging
                        // The stream is finished successfully by the server.
                        // Completion will be handled in `didCompleteWithError` when the connection closes.
                        return
                    }
                    
                    guard !jsonString.isEmpty, let jsonData = jsonString.data(using: .utf8) else { continue }
                    
                    do {
                        let decoded = try JSONDecoder().decode(DeltaEnvelope.self, from: jsonData)
                        if let textChunk = decoded.choices.first?.delta.content {
                            continuation.yield(textChunk)
                        }
                    } catch {
                        // print("Stream decoding error: \(error)") // Optional debugging
                        continuation.finish(throwing: OpenAIError.responseDecodingFailed)
                        task?.cancel() // Stop further processing on error
                    }
                }
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            processBuffer() // Process any remaining data in the buffer
            
            if let urlError = error as? URLError {
                if urlError.code == .cancelled {
                    // print("Stream explicitly cancelled.") // Optional debugging
                    continuation.finish(throwing: OpenAIError.canceled)
                } else {
                    // print("Stream network error: \(urlError)") // Optional debugging
                    continuation.finish(throwing: OpenAIError.networkError(urlError))
                }
            } else if let httpResponse = task.response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                // print("Stream finished with bad status: \(httpResponse.statusCode)") // Optional debugging
                continuation.finish(throwing: OpenAIError.badStatus(httpResponse.statusCode))
            } else if error != nil {
                // Handle other potential errors (although rare if not URLError)
                // print("Stream completed with unknown error: \(error!)") // Optional debugging
                continuation.finish(throwing: error!)
            } else {
                // Normal completion (no error, status code was likely 2xx)
                // print("Stream finished successfully.") // Optional debugging
                continuation.finish()
            }
            // Delegate instance will be released once the continuation finishes/terminates
        }
    }
}

// MARK: – Settings

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    @AppStorage("openai_api_key") var apiKey: String?
    
    // Private init ensures singleton pattern
    private init() {}
}

// MARK: – Speech‐to‐Text (Optimized)

@MainActor
final class SpeechToText: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var error: String?
    
    // Using a private let for the recognizer ensures it's initialized correctly.
    // Force unwrapping assumes the default locale recognizer always exists.
    // Add optional handling if supporting locales without speech recognition.
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        speechRecognizer.delegate = self // Set the delegate
    }
    
    func toggle() {
        // Ensure UI updates and logic happen on the main thread
        Task { @MainActor in
            if isRecording {
                stop()
            } else {
                await start()
            }
        }
    }
    
    private func start() async {
        // Reset state
        transcript = ""
        error = nil
        isRecording = false // Ensure state consistency before starting
        
        // 1. Request Authorization
        //        let authStatus = await SFSpeechRecognizer.requestAuthorization()
        //        guard authStatus == .authorized else {
        //            handleAuthorizationError(status: authStatus)
        //            return
        //        }
        
        
        
        // Check microphone permission separately (though often implicitly handled by speech)
        // AVAudioSession.sharedInstance().requestRecordPermission { granted in ... } could be added
        
        // Ensure the audio engine's input node is available
        let inputNode = audioEngine.inputNode
        
        // 2. Configure Audio Session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Audio session setup failed: \(error.localizedDescription)"
            return
        }
        
        // 3. Prepare Recognition Request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true // Get results as they come
        
        // 4. Start Recognition Task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return } // Avoid retain cycles
            
            var isFinal = false
            if let result = result {
                // Update the transcript on the main thread
                self.transcript = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop audio engine and task on error or final result
                self.stop()
            }
            if let error = error {
                self.error = "Recognition Error: \(error.localizedDescription)"
            }
        }
        
        // 5. Configure and Start Audio Engine
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // Feed buffer to recognition request (implicitly on an audio processing thread)
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            // Successfully Started
            isRecording = true
        } catch {
            self.error = "Audio Engine start failed: \(error.localizedDescription)"
            stop() // Ensure cleanup if engine fails to start
        }
    }
    
    private func stop() {
        // Stop and release resources gracefully
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio() // Signal end of audio
        recognitionTask?.cancel() // Cancel the task if ongoing
        
        // Clean up references
        recognitionRequest = nil
        recognitionTask = nil
        
        // Deactivate audio session (optional, depending on app needs)
        // try? AVAudioSession.sharedInstance().setActive(false)
        
        // Update state on main thread
        if isRecording {
            isRecording = false
        }
    }
    
    private func handleAuthorizationError(status: SFSpeechRecognizerAuthorizationStatus) {
        switch status {
        case .denied:
            error = "Speech recognition permission was denied. Please enable it in Settings."
        case .restricted:
            error = "Speech recognition is restricted on this device."
        case .notDetermined:
            error = "Speech recognition permission not yet requested." // Should ideally not happen here
        default: // .authorized is handled above
            error = "Unknown speech recognition authorization error."
        }
        isRecording = false // Ensure correct state
    }
    
    // SFSpeechRecognizerDelegate method (Optional)
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Can be used to update UI if recognizer becomes unavailable mid-session
        if !available {
            Task { @MainActor in
                self.error = "Speech recognizer became unavailable."
                self.stop()
            }
        }
    }
}

// MARK: – Text‐to‐Speech (Optimized)

@MainActor
final class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("TTS: Attempted to speak empty text.")
            return
        }
        
        // Stop current speech if any
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Configure Audio Session for playback
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // .playback is suitable for TTS. Adjust category/options as needed for your app.
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("TTS: Audio Session setup error - \(error.localizedDescription)")
            // Consider notifying the user or logging the error more formally
            return // Prevent speech attempt if session setup fails
        }
        
        // Create Utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure Voice (ensure the desired voice exists)
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        } else {
            print("TTS: Warning - en-US voice not found. Using default.")
            // Falls back to default system voice if specific one isn't found
        }
        
        // Optional: Adjust pitch and rate
        // utterance.pitchMultiplier = 1.0
        // utterance.rate = AVSpeechUtteranceDefaultSpeechRate // or a specific value
        
        // Start Speaking
        synthesizer.speak(utterance)
        // State update (didStart delegate method handles isSpeaking = true)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate) // or .word for smoother stop
            // State update (didCancel or didFinish delegate methods handle isSpeaking = false)
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate Methods
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // Ensure update happens on the main thread (already guaranteed by @MainActor)
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        // Optional: Deactivate audio session if no other audio is playing
        // try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        // Optional: Deactivate audio session
    }
    
    // didPause, didContinue can also be implemented if needed
}

// MARK: – ViewModel

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = Conversation.loadAll() {
        // Use didSet to trigger saving whenever conversations array is modified
        didSet { Conversation.saveAll(conversations) }
    }
    @Published var selectedID: Conversation.ID?
    @Published var draft: String = ""
    @Published var isLoading = false // For network activity
    @Published var autoSpeak = false
    @Published var showSystem = true // Default to true or false as preferred
    // Standard models - consider adding more like gpt-4o
    @Published var model = "gpt-4-turbo" // Default to a capable model
    @Published var temperature = 0.7 // Default temperature
    
    // State Objects for dependencies managed by the ViewModel
    @StateObject var stt = SpeechToText()
    @StateObject var tts = TextToSpeech()
    
    private let client = OpenAIClient()
    private var apiTask: Task<Void, Never>? = nil // To manage the streaming task
    
    init() {
        // Load existing conversations or create a new one if none exist
        if conversations.isEmpty {
            newChat() // Creates the initial chat
        }
        // Select the first conversation by default if available
        selectedID = selectedID ?? conversations.first?.id
    }
    
    // Computed property to safely access the current conversation
    var current: Conversation? {
        get {
            guard let selectedID = selectedID else { return nil }
            return conversations.first { $0.id == selectedID }
        }
        set {
            guard let newValue = newValue, let selectedID = selectedID else { return }
            if let index = conversations.firstIndex(where: { $0.id == selectedID }) {
                conversations[index] = newValue
            }
        }
    }
    
    // Safely modify the current conversation's messages
    private func appendMessage(_ message: ChatMessage) {
        guard let selectedID = selectedID,
              let index = conversations.firstIndex(where: { $0.id == selectedID }) else { return }
        conversations[index].messages.append(message)
    }
    
    // Safely update the last message (for streaming assistant reply)
    private func updateLastMessage(text: String) {
        guard let selectedID = selectedID,
              let convoIndex = conversations.firstIndex(where: { $0.id == selectedID }),
              !conversations[convoIndex].messages.isEmpty else { return }
        
        let lastMessageIndex = conversations[convoIndex].messages.count - 1
        // Ensure we only update assistant messages
        if conversations[convoIndex].messages[lastMessageIndex].role == .assistant {
            conversations[convoIndex].messages[lastMessageIndex].text = text
        }
    }
    
    func newChat() {
        // Add a default system message
        let systemMessage = ChatMessage(.system, "You are a helpful and concise assistant.")
        let newConversation = Conversation(
            title: "Chat \(conversations.count + 1)", // Dynamic title
            messages: [systemMessage]
        )
        conversations.insert(newConversation, at: 0) // Add to the top
        selectedID = newConversation.id // Select the new chat
    }
    
    func send() {
        // Determine text source (draft or STT transcript)
        let textToSend = draft.isEmpty ? stt.transcript : draft
        let trimmedText = textToSend.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty, let currentConvo = current else {
            // Maybe provide feedback if text is empty?
            return
        }
        
        // Clear input fields
        draft = ""
        stt.transcript = "" // Clear STT transcript after sending
        
        // Append user message locally first
        appendMessage(ChatMessage(.user, trimmedText))
        
        // Cancel any previous API task before starting a new one
        cancelStreaming()
        
        // Start the API call
        reply(to: currentConvo) // Pass the current state
    }
    
    private func reply(to conversation: Conversation) {
        isLoading = true
        
        // Start the background task for the API stream
        apiTask = Task {
            var assistantReply = ""
            var assistantMessageID: UUID? = nil
            
            do {
                // Prepare messages for API (filter out system message if not shown, or include based on logic)
                // Let's include system message for context, adjust if needed
                let apiMessages = conversation.messages.map {
                    ChatCompletionRequest.Msg(role: $0.role.rawValue, content: $0.text)
                }
                
                let stream = await client.stream(
                    model: model,
                    messages: apiMessages,
                    temperature: temperature
                )
                
                // Add a placeholder assistant message to update
                let placeholderAssistantMessage = ChatMessage(.assistant, "...")
                assistantMessageID = placeholderAssistantMessage.id
                await MainActor.run { // Ensure UI update is on main thread
                    appendMessage(placeholderAssistantMessage)
                }
                
                for try await chunk in stream {
                    // Check for cancellation before processing each chunk
                    guard !Task.isCancelled else {
                        throw OpenAIError.canceled
                    }
                    
                    assistantReply += chunk
                    // Update the placeholder message on the main thread
                    await MainActor.run {
                        updateLastMessage(text: assistantReply)
                    }
                }
                
                // Stream finished successfully
                if autoSpeak, !assistantReply.isEmpty {
                    await MainActor.run { tts.speak(assistantReply) }
                }
                
            } catch let error as OpenAIError {
                if error != .canceled { // Don't show error if explicitly cancelled
                    let errorMessage = "⚠️ Error: \(error.localizedDescription)"
                    await MainActor.run {
                        // Update existing message or add new error message
                        if let msgId = assistantMessageID, let convoIndex = conversations.firstIndex(where: { $0.id == conversation.id }), let msgIndex = conversations[convoIndex].messages.firstIndex(where: {$0.id == msgId}) {
                            conversations[convoIndex].messages[msgIndex].text = errorMessage
                        } else {
                            appendMessage(ChatMessage(.assistant, errorMessage))
                        }
                    }
                }
            } catch { // Handle other potential errors
                let errorMessage = "⚠️ An unexpected error occurred: \(error.localizedDescription)"
                await MainActor.run {
                    if let msgId = assistantMessageID, let convoIndex = conversations.firstIndex(where: { $0.id == conversation.id }), let msgIndex = conversations[convoIndex].messages.firstIndex(where: {$0.id == msgId}) {
                        conversations[convoIndex].messages[msgIndex].text = errorMessage
                    } else {
                        appendMessage(ChatMessage(.assistant, errorMessage))
                    }
                }
            }
            
            // Ensure loading indicator is turned off on the main thread
            await MainActor.run {
                isLoading = false
            }
            apiTask = nil // Clear task reference on completion/error
        }
    }
    
    func cancelStreaming() {
        apiTask?.cancel()
        apiTask = nil
        if isLoading { // Only reset isLoading if a task was actually running
            isLoading = false
            // Optional: If cancelled mid-stream, update the last assistant message
            // to indicate cancellation or keep the partial reply.
            // updateLastMessage(text: current?.messages.last?.text ?? "" + " [Cancelled]")
        }
    }
    
    // Function to delete a conversation
    func deleteConversation(at offsets: IndexSet) {
        let idsToDelete = offsets.map { conversations[$0].id }
        
        // If the selected conversation is being deleted, select another one or none
        if let selected = selectedID, idsToDelete.contains(selected) {
            // Find the index of the conversation being deleted
            if let deletedIndex = conversations.firstIndex(where: { $0.id == selected }) {
                // Determine the next selection
                var nextIndex: Int? = nil
                if conversations.count > 1 {
                    if deletedIndex == 0 { // If first element deleted, select the next one
                        nextIndex = 0 // The element at index 1 will become index 0
                    } else { // Otherwise, select the previous one
                        nextIndex = deletedIndex - 1
                    }
                }
                // Remove the conversations
                conversations.remove(atOffsets: offsets)
                // Update selection based on calculated nextIndex
                if let index = nextIndex, index < conversations.count {
                    selectedID = conversations[index].id
                } else {
                    selectedID = conversations.first?.id // Fallback to first or nil
                }
            } else {
                conversations.remove(atOffsets: offsets) // Should not happen if selectedID exists
            }
            
        } else {
            // If the selected conversation is not among those deleted, just remove them
            conversations.remove(atOffsets: offsets)
        }
        
        // If no conversations left, create a new one
        if conversations.isEmpty {
            newChat()
        }
    }
}

// MARK: – Views

struct RootView: View {
    // Use StateObject for the ViewModel as it owns the data source
    @StateObject private var vm = ChatViewModel()
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(vm) // Pass ViewModel down
        } detail: {
            // Detail view depends on selection
            if vm.selectedID != nil {
                ChatDetailView()
                    .environmentObject(vm) // Pass ViewModel down
            } else {
                // Placeholder when no conversation is selected
                Text("Select a chat or create a new one.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        // Present Settings automatically if API Key is missing
        .sheet(isPresented: .constant(AppSettings.shared.apiKey == nil || AppSettings.shared.apiKey?.isEmpty ?? true )) {
            SettingsView()
                .environmentObject(vm)
                .interactiveDismissDisabled() // Prevent dismissal until key is entered
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var vm: ChatViewModel
    
    var body: some View {
        // Use a List for selectable rows
        List(selection: $vm.selectedID) {
            // Iterate over conversations for sidebar rows
            ForEach(vm.conversations) { convo in
                SidebarRow(convo: convo, showSystem: vm.showSystem)
                    .tag(convo.id) // Important for selection binding
            }
            .onDelete(perform: vm.deleteConversation) // Enable swipe-to-delete
        }
        .navigationTitle("Chats")
        .toolbar {
            // Toolbar for adding new chat and editing
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                EditButton() // Standard edit button for delete functionality
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    vm.cancelStreaming() // Cancel any ongoing stream before switching
                    vm.newChat()
                } label: {
                    Label("New Chat", systemImage: "plus")
                }
            }
        }
        // Deselect row when switching between conversations or deleting
        .onChange(of: vm.selectedID) { _, _ in
            vm.cancelStreaming() // Cancel any ongoing stream
        }
    }
}

struct SidebarRow: View {
    let convo: Conversation
    let showSystem: Bool
    
    // Compute preview text based on settings
    var preview: String {
        // Prefer last non-system message unless showing system messages
        let relevantMessages = showSystem ? convo.messages : convo.messages.filter { $0.role != .system }
        return relevantMessages.last?.text ?? "Empty Chat" // Provide fallback text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ") // Replace newlines for preview
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(convo.title).font(.headline)
            Text(preview)
                .font(.caption) // Use caption for preview text
                .lineLimit(1) // Ensure single line preview
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4) // Add some vertical padding
    }
}

struct ChatDetailView: View {
    @EnvironmentObject var vm: ChatViewModel
    // Focus state for the text field
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) { // Remove spacing for seamless look
            // Scrollable chat messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) { // Use LazyVStack for performance
                        // Filter messages based on showSystem setting
                        ForEach(vm.current?.messages.filter { vm.showSystem || $0.role != .system } ?? []) { msg in
                            Bubble(msg: msg)
                                .id(msg.id) // Assign ID for scrolling
                                .contextMenu { BubbleContextMenu(vm: vm, msg: msg) } // Context menu per bubble
                        }
                        // Typing indicator placeholder
                        if vm.isLoading {
                            TypingIndicator()
                                .id("typingIndicator") // Assign ID if needed for scrolling
                        }
                    }
                    .padding(.horizontal) // Padding for message bubbles
                    .padding(.top) // Padding at the top of the scroll view
                }
                // Automatically scroll to bottom on new message or loading state change
                //                .onChange(of: vm.current?.messages.count) { _, _ in scrollToBottom(proxy: proxy) }
                //                .onChange(of: vm.isLoading) { _, newValue in if newValue { scrollToBottom(proxy: proxy, anchor: .bottom) } }
                //                .onAppear { // Scroll to bottom when view appears
                //                    scrollToBottom(proxy: proxy, anchor: .bottom, animated: false)
                //                }
            }
            
            // Input area
            InputArea(vm: vm, isTextFieldFocused: $isTextFieldFocused)
                .focused($isTextFieldFocused) // Bind focus state
        }
        .navigationTitle(vm.current?.title ?? "Chat")
        .navigationBarTitleDisplayMode(.inline) // Compact title
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Stop button (visible when loading)
                if vm.isLoading {
                    Button {
                        vm.cancelStreaming()
                    } label: {
                        Label("Stop", systemImage: "stop.circle.fill")
                            .foregroundStyle(.red) // Indicate stopping action
                    }
                }
                
                // Standard options menu
                Menu {
                    Button { showingSettings = true } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    Divider()
                    // Direct toggles in the menu
                    Toggle(isOn: $vm.showSystem) {
                        Label("Show System Messages", systemImage: vm.showSystem ? "eye.slash" : "eye")
                    }
                    Toggle(isOn: $vm.autoSpeak) {
                        Label("Auto-Speak Replies", systemImage: vm.autoSpeak ? "speaker.slash" : "speaker.wave.2")
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                        .symbolVariant(vm.isLoading ? .fill : .none) // Indicate loading status
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(vm) // Pass VM to settings sheet
        }
        // Dismiss keyboard when scrolling starts
        .gesture(DragGesture().onChanged { _ in isTextFieldFocused = false })
    }
    
    // Helper to scroll to bottom
    //    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom, animated: Bool = true) {
    //        let targetID = vm.isLoading ? "typingIndicator" : vm.current?.messages.last?.id
    //        guard let id = targetID else { return }
    //        
    //        if animated {
    //            withAnimation(.smooth(duration: 0.3)) {
    //                proxy.scrollTo(id, anchor: anchor)
    //            }
    //        } else {
    //            proxy.scrollTo(id, anchor: anchor)
    //        }
    //    }
}

// Context menu content, extracted for clarity
struct BubbleContextMenu: View {
    @ObservedObject var vm: ChatViewModel
    let msg: ChatMessage
    
    var body: some View {
        Button {
            UIPasteboard.general.string = msg.text
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        if msg.role == .assistant { // Only allow speaking assistant messages? Adjust if needed.
            Button {
                vm.tts.speak(msg.text)
            } label: {
                Label("Read Aloud", systemImage: "speaker.wave.2")
            }
            // Add stop speaking button if currently speaking this message? (More complex state)
        }
        
        // ShareLink for easy sharing
        ShareLink(item: msg.text) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}

// Input Area View
struct InputArea: View {
    @ObservedObject var vm: ChatViewModel // Observe ViewModel changes Needed for disabling button etc.
    var isTextFieldFocused: FocusState<Bool>.Binding // Use Binding for focus state
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Microphone button
            Button {
                vm.stt.toggle() // Toggle speech-to-text
            } label: {
                Image(systemName: vm.stt.isRecording ? "stop.circle.fill" : "mic.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(vm.stt.isRecording ? Color.red : Color.blue)
                    .animation(.easeIn, value: vm.stt.isRecording)
            }
            .buttonStyle(.plain) // Use plain style for custom look
            
            // Text Field for typing messages
            TextField("Message...", text: Binding(
                get: { vm.draft.isEmpty ? vm.stt.transcript : vm.draft },
                set: { vm.draft = $0; if !$0.isEmpty { vm.stt.transcript = "" } } // Clear STT if typing manually
            ), axis: .vertical) // Allow vertical expansion
            .lineLimit(1...5) // Limit lines to prevent excessive height
            .textFieldStyle(.roundedBorder)
            .focused(isTextFieldFocused) // Bind focus state
            .onSubmit(vm.send) // Send on Return key
            
            // Send button (conditionally enabled)
            let canSend = !vm.isLoading && (!vm.draft.isEmpty || !vm.stt.transcript.isEmpty)
            Button {
                if canSend { vm.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(canSend ? Color.blue : Color.gray) // Change color when disabled
            }
            .disabled(!canSend) // Disable button when cannot send
            .buttonStyle(.plain)
            .animation(.easeIn, value: canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial) // Subtle background for separation
    }
}

// Chat Bubble View
struct Bubble: View {
    let msg: ChatMessage
    private var isUser: Bool { msg.role == .user }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) { // Align content to bottom
            if isUser { Spacer() } // Push user messages to the right
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Selectable Text for easy copying
                Text(msg.text)
                    .textSelection(.enabled) // Enable text selection
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smoother corners
                    .foregroundStyle(bubbleForeground) // Ensure text color contrast
                // Use alignmentGuide for tail effect if needed
                // .alignmentGuide(.leading) { d in d[HorizontalAlignment.trailing] } // Example for tail
                
                // Timestamp below the bubble
                Text(msg.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 300, alignment: isUser ? .trailing : .leading) // Limit bubble width
            
            if !isUser { Spacer() } // Push assistant messages to the left
        }
    }
    
    // Computed properties for bubble styling
    private var bubbleBackground: Color {
        switch msg.role {
        case .user: return .blue // User message background
        case .assistant: return Color(.systemGray5) // Assistant message background
        case .system: return Color(.systemYellow).opacity(0.5) // System message background (if shown)
        }
    }
    
    private var bubbleForeground: Color {
        switch msg.role {
        case .user: return .white // User message text color
        case .assistant: return Color(.label) // Assistant text color (adapts to light/dark mode)
        case .system: return Color(.label) // System text color
        }
    }
}

// Typing Indicator View
struct TypingIndicator: View {
    @State private var dots = ""
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 4) {
            Circle().frame(width: 6, height: 6).opacity(dots.count >= 1 ? 1 : 0)
            Circle().frame(width: 6, height: 6).opacity(dots.count >= 2 ? 1 : 0)
            Circle().frame(width: 6, height: 6).opacity(dots.count >= 3 ? 1 : 0)
        }
        .foregroundStyle(.secondary)
        .animation(.spring().speed(1.5), value: dots.count)
        .onReceive(timer) { _ in
            dots = String(repeating: ".", count: (dots.count % 3) + 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Align left
        .padding(.vertical, 8)
    }
}

// Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: ChatViewModel // Use EnvironmentObject if passed
    
    // Use AppStorage directly for settings that don't need immediate ViewModel updates
    @AppStorage("openai_api_key") private var apiKey: String?
    
    // Available models (Consider fetching dynamically or using an enum)
    let models = ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"] // Added gpt-4o
    
    var body: some View {
        NavigationStack {
            Form {
                // API Key Section
                Section("OpenAI API Key") {
                    // SecureField for sensitive input
                    SecureField("Enter your API key (sk-...)", text: Binding(
                        get: { apiKey ?? "" },
                        set: { apiKey = $0.trimmingCharacters(in: .whitespacesAndNewlines) } // Trim whitespace
                    ))
                    Link("Get API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                }
                
                // Model Configuration Section
                Section("Model Configuration") {
                    Picker("Model", selection: $vm.model) {
                        ForEach(models, id: \.self) { modelName in
                            Text(modelName).tag(modelName)
                        }
                    }
                    
                    // Temperature Slider with Label
                    VStack(alignment: .leading) {
                        Text("Temperature: \(vm.temperature, specifier: "%.2f")")
                        Slider(value: $vm.temperature, in: 0.0...1.0, step: 0.05) // Standard Range
                    }
                }
                
                // Behavior Settings Section
                Section("Behavior") {
                    // Use Labels for better accessibility
                    Toggle(isOn: $vm.showSystem) {
                        Label("Show System Prompts", systemImage: vm.showSystem ? "eye.slash" : "eye")
                    }
                    Toggle(isOn: $vm.autoSpeak) {
                        Label("Auto-Speak Replies", systemImage: vm.autoSpeak ? "speaker.slash" : "speaker.wave.2")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    // Disable Done button if API Key is missing?
                    .disabled(apiKey == nil || apiKey?.isEmpty == true)
                }
            }
        }
    }
}
