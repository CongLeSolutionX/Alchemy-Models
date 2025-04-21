////
////  OpenAIChatAPIDemoView_Vietnamize_Version_V7.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
//// ChatDemoView.swift
//// Single‐file SwiftUI Chat Demo with Mock, OpenAI, and CoreML backends
//// Enhanced with English strings and async/await.
////
//// Requires: Xcode 15+, iOS 17+
////
//
//import SwiftUI
//import Combine
//import Speech
//import AVFoundation
//import CoreML
//
//// MARK: — Models
//
//enum ChatRole: String, Codable, Hashable {
//    case system, user, assistant
//}
//
//struct Message: Identifiable, Codable, Hashable {
//    let id: UUID
//    let role: ChatRole
//    let content: String
//    let timestamp: Date
//    
//    init(role: ChatRole, content: String, timestamp: Date = .now, id: UUID = .init()) {
//        self.id = id; self.role = role; self.content = content; self.timestamp = timestamp
//    }
//    
//    static func system(_ text: String)    -> Message { .init(role: .system,    content: text) }
//    static func user(_ text: String)      -> Message { .init(role: .user,      content: text) }
//    static func assistant(_ text: String) -> Message { .init(role: .assistant, content: text) }
//}
//
//struct Conversation: Identifiable, Codable, Hashable {
//    let id: UUID
//    var title: String
//    var messages: [Message]
//    var createdAt: Date
//    
//    init(id: UUID = .init(),
//         title: String = "",
//         messages: [Message] = [],
//         createdAt: Date = .now)
//    {
//        self.id = id
//        self.messages = messages
//        self.createdAt = createdAt
//        // Auto-generate title from first user message if not provided
//        if title.isEmpty {
//            let firstUser = messages.first(where: { $0.role == .user })?.content ?? "New Chat"
//            self.title = String(firstUser.prefix(32))
//        } else {
//            self.title = title
//        }
//    }
//}
//
//// MARK: — Backend Protocols & Implementations
//
//// Custom Error enum for more specific backend errors
//enum BackendError: Error, LocalizedError {
//    case invalidURL
//    case networkRequestFailed(Error)
//    case noDataReceived
//    case decodingFailed(Error)
//    case encodingFailed(Error)
//    case apiError(String) // For errors reported by the API itself
//    case coreMLModelError(String)
//    case backendNotConfigured
//    case missingAPIKey
//    
//    var errorDescription: String? {
//        switch self {
//        case .invalidURL: return "The API endpoint URL is invalid."
//        case .networkRequestFailed(let error): return "Network request failed: \(error.localizedDescription)"
//        case .noDataReceived: return "No data received from the server."
//        case .decodingFailed(let error): return "Failed to decode the server response: \(error.localizedDescription)"
//        case .apiError(let message): return "API Error: \(message)"
//        case .coreMLModelError(let message): return "CoreML Model Error: \(message)"
//        case .backendNotConfigured: return "The chat backend is not properly configured."
//        case .missingAPIKey: return "The OpenAI API Key is missing."
//        case .encodingFailed(let error): return "Failed to encode the server response: \(error.localizedDescription)"
//        }
//    }
//}
//
//// Updated protocol using async/throws
//protocol ChatBackend {
//    func generateReply(messages: [Message], systemPrompt: String) async throws -> String
//}
//
//struct MockChatBackend: ChatBackend {
//    let replies = [
//        "Sure thing!",
//        "Let me think...",
//        "Could you elaborate?",
//        "Here's my suggestion.",
//        "Absolutely!",
//        "I'm reviewing that...",
//        "Interesting point.",
//        "Okay, got it.",
//    ]
//    
//    func generateReply(messages: [Message], systemPrompt: String) async throws -> String {
//        // Simulate network delay
//        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
//        guard let reply = replies.randomElement() else {
//            throw BackendError.apiError("Mock backend failed to generate reply.")
//        }
//        return reply
//    }
//}
//
//final class RealOpenAIBackend: ChatBackend {
//    let apiKey: String, model: String, temperature: Double, maxTokens: Int
//    
//    init(apiKey: String, model: String, temperature: Double, maxTokens: Int) {
//        self.apiKey = apiKey
//        self.model = model
//        self.temperature = temperature
//        self.maxTokens = maxTokens
//    }
//    
//    // Updated function using async/await and specific errors
//    func generateReply(messages: [Message], systemPrompt: String) async throws -> String {
//        guard !apiKey.isEmpty else { throw BackendError.missingAPIKey }
//        
//        var allMessages = messages
//        if !systemPrompt.isEmpty {
//            allMessages.insert(.system(systemPrompt), at: 0)
//        }
//        
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            throw BackendError.invalidURL
//        }
//        
//        var req = URLRequest(url: url)
//        req.httpMethod = "POST"
//        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        struct Payload: Encodable {
//            let model: String
//            let messages: [[String: String]] // Role and content
//            let temperature: Double
//            let max_tokens: Int
//            // Add stream: false if you are not handling streaming responses
//            let stream: Bool = false
//        }
//        
//        // Convert messages to the required dictionary format
//        let messagePayload = allMessages.map { ["role": $0.role.rawValue, "content": $0.content] }
//        
//        let body = Payload(
//            model: model,
//            messages: messagePayload,
//            temperature: temperature,
//            max_tokens: maxTokens
//        )
//        
//        do {
//            req.httpBody = try JSONEncoder().encode(body)
//        } catch {
//            throw BackendError.encodingFailed(error) // Custom error for encoding failure
//        }
//        
//        // Use async URLSession data task
//        let data: Data
//        let response: URLResponse
//        do {
//            (data, response) = try await URLSession.shared.data(for: req)
//        } catch {
//            throw BackendError.networkRequestFailed(error)
//        }
//        
//        // Check HTTP response status
//        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
//            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
//            // Try to decode error message from OpenAI if available
//            if let errorDetail = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
//                throw BackendError.apiError("(\(statusCode)) \(errorDetail.error.message)")
//            } else {
//                throw BackendError.apiError("Received HTTP status \(statusCode)")
//            }
//        }
//        
//        do {
//            // Define expected successful response structure
//            struct Resp: Decodable {
//                struct Choice: Decodable {
//                    struct Msg: Decodable { let role: String?; let content: String } // Role might be optional
//                    let message: Msg
//                    let finish_reason: String?
//                }
//                let id: String?
//                let object: String?
//                let created: Int?
//                let model: String?
//                let choices: [Choice]
//                struct Usage: Decodable {
//                    let prompt_tokens: Int?
//                    let completion_tokens: Int?
//                    let total_tokens: Int?
//                }
//                let usage: Usage?
//            }
//            
//            // Define expected error response structre from OpenAI
//            struct OpenAIErrorResponse: Decodable {
//                struct ErrorDetail: Decodable {
//                    let message: String
//                    let type: String?
//                    let param: String?
//                    let code: String?
//                }
//                let error: ErrorDetail
//            }
//            
//            let decoded = try JSONDecoder().decode(Resp.self, from: data)
//            
//            guard let text = decoded.choices.first?.message.content else {
//                throw BackendError.apiError("No response content received from API.")
//            }
//            
//            return text
//            
//        } catch {
//            // If decoding fails, it might be an error structure from OpenAI
//            if let errorDetail = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
//                throw BackendError.apiError(errorDetail.error.message)
//            } else {
//                // Otherwise, it's likely a standard decoding error
//                throw BackendError.decodingFailed(error)
//            }
//        }
//    }
//    
//    // Helper struct for decoding OpenAI API errors
//    struct OpenAIErrorResponse: Decodable {
//        struct ErrorDetail: Decodable {
//            let message: String
//            let type: String?
//            let param: String?
//            let code: String?
//        }
//        let error: ErrorDetail
//    }
//    struct EncodingFailedError: Error { let underlyingError: Error }
//    
//}
//
//enum BackendType: String, CaseIterable, Identifiable {
//    case mock = "Mock"
//    case openAI = "OpenAI"
//    case coreML = "CoreML" // Typically runs locally
//    var id: Self { self }
//}
//
//struct CoreMLChatBackend: ChatBackend {
//    let modelName: String
//    private var coreModel: MLModel? // Lazily loaded
//    
//    init(modelName: String) {
//        self.modelName = modelName
//        // Attempt to load the model during initialization
//        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
//            print("Error: CoreML model file '\(modelName).mlmodelc' not found.")
//            self.coreModel = nil
//            return
//        }
//        do {
//            self.coreModel = try MLModel(contentsOf: url)
//            print("CoreML model '\(modelName)' loaded successfully.")
//        } catch {
//            print("Error loading CoreML model '\(modelName)': \(error)")
//            self.coreModel = nil
//        }
//    }
//    
//    func generateReply(messages: [Message], systemPrompt: String) async throws -> String {
//        guard coreModel != nil else {
//            throw BackendError.coreMLModelError("Model '\(modelName)' not loaded or invalid.")
//        }
//        
//        // --- Placeholder for actual CoreML Inference ---
//        // 1. Preprocess `messages` and `systemPrompt` into the format expected by your specific CoreML model.
//        // 2. Create an MLFeatureProvider with the input features.
//        // 3. Use `coreModel.prediction(from: options:)` to get the output.
//        // 4. Postprocess the output MLFeatureProvider to extract the generated text.
//        // -----------------------------------------------
//        
//        // Simulate processing time
//        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
//        
//        // Return a stubbed response for now
//        let lastUserMessage = messages.last(where: { $0.role == .user })?.content ?? "(no input)"
//        return "CoreML (\(modelName)) echo: \(lastUserMessage)"
//        // Replace the above line with actual model prediction result
//    }
//}
//
//// MARK: — Speech Recognizer
//
//final class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate, AVAudioPlayerDelegate {
//    @Published var transcript = ""
//    @Published var isRecording = false
//    @Published var errorMessage: String?
//    
//    var onFinalTranscription: ((String) -> Void)?
//    
//    private var speechRecognizer: SFSpeechRecognizer?
//    private let audioEngine = AVAudioEngine()
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//    
//    // Silence detection parameters
//    private let silenceTimeout: TimeInterval = 1.5 // Seconds of silence before stopping
//    private var silenceTimer: Timer?
//    
//    override init() {
//        super.init()
//        // Initialize with the default locale, consider making this configurable
//        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) // Default to US English
//        self.speechRecognizer?.delegate = self
//    }
//    
//    func setLocale(identifier: String) {
//        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
//        self.speechRecognizer?.delegate = self
//        print("Speech recognizer locale set to: \(identifier)")
//    }
//    
//    func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
//        SFSpeechRecognizer.requestAuthorization { authStatus in
//            DispatchQueue.main.async {
//                var authorized = false
//                var message: String? = nil
//                switch authStatus {
//                case .authorized:
//                    authorized = true
//                case .denied:
//                    message = "Speech recognition permission was denied. Please enable it in Settings."
//                case .restricted:
//                    message = "Speech recognition restricted on this device."
//                case .notDetermined:
//                    message = "Speech recognition not yet authorized."
//                @unknown default:
//                    message = "Unknown speech recognition authorization status."
//                }
//                self.errorMessage = message
//                print("Speech Recognition Auth Status: \(authStatus)")
//                completion(authorized)
//            }
//        }
//    }
//    
//    func startRecording() throws {
//        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
//            errorMessage = "Speech recognizer is not available for the selected language."
//            throw RecognizerError.recognizerUnavailable
//        }
//        guard !isRecording else {
//            print("Already recording.")
//            return
//        }
//        
//        // Clear previous state
//        errorMessage = nil
//        transcript = ""
//        recognitionTask?.cancel()
//        recognitionTask = nil
//        recognitionRequest?.endAudio()
//        recognitionRequest = nil
//        silenceTimer?.invalidate()
//        silenceTimer = nil
//        
//        // Configure Audio Session
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        } catch {
//            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
//            throw RecognizerError.audioSessionError(error)
//        }
//        
//        // Create and configure the recognition request
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create request") }
//        recognitionRequest.shouldReportPartialResults = true
//        // Consider task hint based on use case: .dictation, .search, .confirmation, .unspecified
//        recognitionRequest.taskHint = .dictation
//        
//        // Setup the recognition task
//        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
//            guard let self = self else { return }
//            var isFinal = false
//            
//            if let result = result {
//                let newTranscript = result.bestTranscription.formattedString
//                DispatchQueue.main.async {
//                    self.transcript = newTranscript // Update published transcript
//                }
//                isFinal = result.isFinal
//                if !isFinal {
//                    // Reset silence timer on receiving partial results
//                    self.resetSilenceTimer()
//                }
//            }
//            
//            if error != nil || isFinal {
//                // Stop processing audio
//                self.stopAudioEngine() // Ensure audio engine stops first
//                DispatchQueue.main.async { // Ensure UI updates on main thread
//                    if let error = error {
//                        // Handle specific errors if needed
//                        if (error as NSError).code == 1101 { // Example: Resource unavailable
//                            self.errorMessage = "Recognition resources unavailable. Try again later."
//                        } else {
//                            self.errorMessage = "Recognition Error: \(error.localizedDescription)"
//                        }
//                        print("Recognition task error: \(error.localizedDescription)")
//                    }
//                    if isFinal, let finalTranscript = result?.bestTranscription.formattedString {
//                        print("Final transcript received: \(finalTranscript)")
//                        self.onFinalTranscription?(finalTranscript) // Callback with final result
//                    }
//                    // This ensures stopRecording logic runs *after* potential callbacks
//                    self.stopRecordingInternal()
//                }
//            }
//        }
//        
//        // Configure and start the audio engine
//        let inputNode = audioEngine.inputNode
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        
//        // Check if format is valid before installing tap
//        guard recordingFormat.sampleRate > 0 else {
//            errorMessage = "Invalid recording format."
//            stopRecordingInternal() // Clean up
//            throw RecognizerError.invalidAudioFormat
//        }
//        
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
//            self.recognitionRequest?.append(buffer)
//        }
//        
//        audioEngine.prepare()
//        try audioEngine.start()
//        
//        isRecording = true
//        print("Recording started.")
//        // Start the silence timer initially
//        resetSilenceTimer()
//    }
//    
//    private func stopAudioEngine() {
//        if audioEngine.isRunning {
//            audioEngine.stop()
//            audioEngine.inputNode.removeTap(onBus: 0) // Remove tap after stopping
//            print("Audio engine stopped.")
//        }
//    }
//    
//    private func resetSilenceTimer() {
//        silenceTimer?.invalidate() // Invalidate existing timer
//        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
//            guard let self = self, self.isRecording else { return }
//            print("Silence detected, finalizing transcription.")
//            self.recognitionRequest?.endAudio() // Signal end of audio due to silence
//        }
//        print("Silence timer reset.")
//    }
//    
//    func stopRecording() {
//        if isRecording {
//            print("Stop recording requested externally.")
//            recognitionRequest?.endAudio() // Politely ask the recognizer to finish
//            // stopRecordingInternal will be called by the task delegate when it finishes/errors
//        } else {
//            stopAudioEngine() // Ensure engine is stopped if we weren't technically recording
//            stopRecordingInternal() // Clean up immediately if not recording
//        }
//    }
//    
//    // Centralized cleanup function called internally
//    private func stopRecordingInternal() {
//        if isRecording { // Only print and change state if actually recording
//            isRecording = false
//            print("Recording stopped internally.")
//            silenceTimer?.invalidate()
//            silenceTimer = nil
//            recognitionTask?.cancel() // Ensure task is cancelled
//            recognitionTask = nil
//            recognitionRequest = nil // Release request object
//            
//            // Deactivate audio session
//            do {
//                try AVAudioSession.sharedInstance().setActive(false)
//            } catch {
//                print("Failed to deactivate audio session: \(error.localizedDescription)")
//            }
//        } else {
//            // Still ensure cleanup happens even if isRecording was false
//            silenceTimer?.invalidate()
//            silenceTimer = nil
//            recognitionTask?.cancel()
//            recognitionTask = nil
//            recognitionRequest = nil
//        }
//    }
//    
//    // SFSpeechRecognizerDelegate method
//    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
//        DispatchQueue.main.async {
//            if !available {
//                self.errorMessage = "Speech recognizer became unavailable."
//                self.stopRecording() // Stop if recognizer is lost
//            } else {
//                self.errorMessage = nil // Clear error if it becomes available again
//            }
//            print("Speech recognizer availability changed: \(available)")
//        }
//    }
//    
//    enum RecognizerError: Error {
//        case recognizerUnavailable
//        case audioSessionError(Error)
//        case invalidAudioFormat
//    }
//}
//
//// MARK: — ViewModel
//
//@MainActor
//final class ChatStore: ObservableObject {
//    @Published var conversations: [Conversation] = [] {
//        didSet { saveConversationsToDisk() }
//    }
//    
//    // Represents the conversation currently displayed/active
//    @Published var currentConversation: Conversation = Conversation(messages: [
//        .system("You are a helpful assistant. Respond concisely in English.") // Default system prompt in English
//    ])
//    
//    @Published var currentInput: String = ""
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//    @Published var systemPrompt: String = "You are a helpful assistant." {
//        didSet {
//            // Update system message in current *new* conversation or apply to backend config
//            if currentConversation.messages.count <= 1 || currentConversation.id == initialConversationID { // Only update if it's a new/default chat
//                currentConversation.messages.removeAll { $0.role == .system }
//                currentConversation.messages.insert(.system(systemPrompt), at: 0)
//            }
//            // Reconfigure backend if necessary (e.g., if prompt affects model behavior)
//            configureBackend() // Re-configure to potentially update model params if needed
//        }
//    }
//    private let initialConversationID = UUID() // To identify the very first default conversation
//    
//    // TTS Settings
//    @Published var ttsEnabled: Bool = false
//    @Published var ttsRate: Float = AVSpeechUtteranceDefaultSpeechRate // Use default rate initially
//    @Published var ttsVoiceID: String = "" // Store identifier, default to empty
//    
//    // Backend Configuration (@AppStorage simplifies persistence for these)
//    @AppStorage("openai_api_key") private var apiKey: String = ""
//    @AppStorage("selected_backend_type") private var backendTypeRaw: String = BackendType.mock.rawValue // Default to Mock
//    @AppStorage("selected_openai_model") var openAIModelName: String = "gpt-4o" // Default model
//    @AppStorage("openai_temperature") var openAITemperature: Double = 0.7
//    @AppStorage("openai_max_tokens") var openAIMaxTokens: Int = 384
//    @AppStorage("selected_coreml_model") var coreMLModelName: String = "LocalChat" // Default CoreML model
//    
//    // Available model options for pickers
//    let availableCoreMLModels = ["LocalChat", "TinyChat"] // Example model names
//    let availableOpenAIModels = ["gpt-4o", "gpt-4", "gpt-3.5-turbo"] // Common OpenAI models
//    
//    private(set) var activeBackend: ChatBackend = MockChatBackend() // Initialize with a default
//    private let ttsSynthesizer = AVSpeechSynthesizer()
//    var availableVoices: [AVSpeechSynthesisVoice] = []
//    
//    var selectedBackendType: BackendType {
//        get { BackendType(rawValue: backendTypeRaw) ?? .mock }
//        set { backendTypeRaw = newValue.rawValue; configureBackend() }
//    }
//    
//    init() {
//        loadConversationsFromDisk()
//        initializeTTS()
//        // Create the initial empty conversation on first launch if none loaded
//        if conversations.isEmpty {
//            startNewConversation() // Start with a fresh one using the default prompt
//        } else if currentConversation.id == UUID() /* default UUID */ { // Ensure current is valid if loaded
//            currentConversation = conversations.first ?? Conversation(id: initialConversationID, messages: [.system(systemPrompt)])
//        }
//        configureBackend() // Configure based on stored settings
//    }
//    
//    // Function to initialize TTS and find a default English voice
//    private func initializeTTS() {
//        availableVoices = AVSpeechSynthesisVoice.speechVoices()
//        // Try to find a default US English voice
//        if let defaultVoice = availableVoices.first(where: { $0.language == "en-US" }) {
//            ttsVoiceID = defaultVoice.identifier
//        } else if let anyEnglish = availableVoices.first(where: { $0.language.starts(with: "en") }) {
//            // Fallback to any English voice
//            ttsVoiceID = anyEnglish.identifier
//        } else {
//            // Fallback to the very first available voice if no English voice is found
//            ttsVoiceID = availableVoices.first?.identifier ?? ""
//        }
//        print("TTS Initialized. Available voices: \(availableVoices.count). Default Voice ID: \(ttsVoiceID)")
//    }
//    
//    func setBackend(_ backend: ChatBackend, type: BackendType) {
//        activeBackend = backend
//        selectedBackendType = type // This setter also calls configureBackend via @AppStorage trigger
//        print("Backend manually set to: \(type.rawValue)")
//    }
//    
//    // Clears the current chat input and messages, starting fresh
//    func startNewConversation() {
//        ttsSynthesizer.stopSpeaking(at: .immediate)
//        // Create a completely new conversation object
//        let newConversation = Conversation(id: UUID(), // Generate a new unique ID
//                                           messages: [.system(systemPrompt)]) // Start with current system prompt
//        currentConversation = newConversation
//        currentInput = ""
//        isLoading = false // Ensure loading indicator is off
//        errorMessage = nil // Clear any previous errors
//        print("Started New Conversation (ID: \(newConversation.id))")
//    }
//    
//    // Sends the current input text to the backend
//    func sendMessage(_ text: String) {
//        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmedText.isEmpty, !isLoading else { return }
//        
//        ttsSynthesizer.stopSpeaking(at: .word) // Stop any ongoing speech
//        
//        let userMessage = Message.user(trimmedText)
//        currentConversation.messages.append(userMessage)
//        currentInput = "" // Clear input field immediately
//        isLoading = true
//        errorMessage = nil // Clear previous errors
//        
//        // Execute backend call in a background Task
//        Task {
//            do {
//                // Make sure backend is configured
//                guard activeBackend is MockChatBackend || activeBackend is RealOpenAIBackend || activeBackend is CoreMLChatBackend else {
//                    throw BackendError.backendNotConfigured
//                }
//                
//                // Get reply from the backend
//                let replyText = try await activeBackend.generateReply(
//                    messages: currentConversation.messages,
//                    systemPrompt: systemPrompt // Pass current system prompt
//                )
//                
//                // Process successful reply
//                let assistantMessage = Message.assistant(replyText)
//                self.currentConversation.messages.append(assistantMessage)
//                self.upsertCurrentConversation() // Save or update in history
//                
//                if self.ttsEnabled {
//                    speak(replyText)
//                }
//                
//            } catch {
//                // Handle errors from the backend
//                print("Error sending message: \(error)")
//                if let backendError = error as? BackendError {
//                    self.errorMessage = backendError.localizedDescription
//                } else {
//                    // Generic error message
//                    self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
//                }
//            }
//            // Ensure loading state is turned off regardless of success or failure
//            self.isLoading = false
//        }
//    }
//    
//    // Speaks the given text using TTS
//    func speak(_ text: String) {
//        guard !text.isEmpty else { return }
//        do {
//            // Configure audio session for playback
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {
//            print("Failed to configure AVAudioSession for TTS: \(error.localizedDescription)")
//            // Optionally show an error to the user
//            errorMessage = "Text-to-Speech audio setup failed."
//            return // Don't attempt to speak if session setup fails
//        }
//        
//        let utterance = AVSpeechUtterance(string: text)
//        utterance.rate = ttsRate
//        if let voice = AVSpeechSynthesisVoice(identifier: ttsVoiceID), !ttsVoiceID.isEmpty {
//            utterance.voice = voice
//        } else {
//            // Fallback if selected voice ID is invalid or empty
//            utterance.voice = AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice.speechVoices().first
//            print("Warning: Could not find voice for ID '\(ttsVoiceID)', using default.")
//        }
//        
//        ttsSynthesizer.speak(utterance)
//    }
//    
//    // Deletes a conversation from the history
//    func deleteConversation(id: UUID) {
//        conversations.removeAll { $0.id == id }
//        // If the deleted conversation was the current one, start a new chat
//        if currentConversation.id == id {
//            startNewConversation()
//        }
//        print("Deleted Conversation (ID: \(id))")
//    }
//    
//    // Loads a selected conversation from history into the main view
//    func selectConversation(_ conversation: Conversation) {
//        ttsSynthesizer.stopSpeaking(at: .immediate)
//        currentConversation = conversation
//        currentInput = "" // Clear input when switching
//        isLoading = false
//        errorMessage = nil
//        print("Selected Conversation (ID: \(conversation.id), Title: \(conversation.title))")
//    }
//    
//    // Renames a conversation in the history
//    func renameConversation(_ conversation: Conversation, to newTitle: String) {
//        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmedTitle.isEmpty,
//              let index = conversations.firstIndex(where: { $0.id == conversation.id })
//        else { return }
//        
//        conversations[index].title = trimmedTitle
//        // Update title in the current view if it's the active conversation
//        if currentConversation.id == conversation.id {
//            currentConversation.title = trimmedTitle
//        }
//        print("Renamed Conversation (ID: \(conversation.id)) to '\(trimmedTitle)'")
//    }
//    
//    // Clears all conversations from the history
//    func clearAllHistory() {
//        conversations.removeAll()
//        startNewConversation() // Start fresh after clearing
//        print("Cleared All Conversation History")
//    }
//    
//    // Connects the store to the SpeechRecognizer for handling voice commands
//    func attachSpeechRecognizer(_ recognizer: SpeechRecognizer) {
//        recognizer.onFinalTranscription = { [weak self] text in
//            guard let self = self else { return }
//            print("Received final transcription: \(text)")
//            self.handleVoiceCommand(text.lowercased())
//        }
//    }
//    
//    // Processes transcribed speech for commands or message sending
//    private func handleVoiceCommand(_ command: String) {
//        // Basic command examples (enhance with more robust parsing if needed)
//        switch command {
//        case _ where command.contains("new chat") || command.contains("start over"):
//            startNewConversation()
//        case _ where command.contains("tts on") || command.contains("enable speech"):
//            ttsEnabled = true
//        case _ where command.contains("tts off") || command.contains("disable speech"):
//            ttsEnabled = false
//        case _ where command.contains("use openai"):
//            selectedBackendType = .openAI
//        case _ where command.contains("use mock"):
//            selectedBackendType = .mock
//        case _ where command.contains("use coreml") || command.contains("use local"):
//            selectedBackendType = .coreML
//        default:
//            // If it's not a recognized command, treat it as input
//            sendMessage(command)
//        }
//    }
//    
//    // Configures the active backend based on stored user preferences
//    func configureBackend() {
//        print("Configuring backend. Selected type: \(selectedBackendType)")
//        switch selectedBackendType {
//        case .mock:
//            activeBackend = MockChatBackend()
//            print("Active backend set to Mock.")
//        case .openAI:
//            let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
//            if !trimmedKey.isEmpty {
//                activeBackend = RealOpenAIBackend(
//                    apiKey: trimmedKey,
//                    model: openAIModelName,
//                    temperature: openAITemperature,
//                    maxTokens: openAIMaxTokens
//                )
//                print("Active backend set to OpenAI (Model: \(openAIModelName)).")
//            } else {
//                // Fallback to Mock if API key is missing
//                activeBackend = MockChatBackend()
//                selectedBackendType = .mock // Explicitly switch back in UI state if key missing
//                print("OpenAI API Key missing. Falling back to Mock backend.")
//                // Consider showing an error message to the user
//                // self.errorMessage = "OpenAI API Key is required. Switched to Mock backend."
//            }
//        case .coreML:
//            // Ensure the model name from @AppStorage is used
//            activeBackend = CoreMLChatBackend(modelName: coreMLModelName)
//            print("Active backend set to CoreML (Model: \(coreMLModelName)).")
//        }
//    }
//    
//    // MARK: Persistence
//    
//    private func getDocumentsDirectory() -> URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
//    
//    private var conversationsFileURL: URL {
//        getDocumentsDirectory().appendingPathComponent("chat_conversations.json")
//    }
//    
//    // Loads conversations from a JSON file in the documents directory
//    private func loadConversationsFromDisk() {
//        let fileURL = conversationsFileURL
//        guard FileManager.default.fileExists(atPath: fileURL.path) else {
//            print("Conversations file not found. Starting fresh.")
//            return
//        }
//        
//        do {
//            let data = try Data(contentsOf: fileURL)
//            let decodedConversations = try JSONDecoder().decode([Conversation].self, from: data)
//            self.conversations = decodedConversations
//            // Set the current conversation to the most recent one if available
//            if let firstConvo = conversations.first {
//                self.currentConversation = firstConvo
//            } else {
//                // Ensure a default conversation exists if loading resulted in empty array
//                self.currentConversation = Conversation(id: initialConversationID, messages: [.system(systemPrompt)])
//            }
//            print("Loaded \(conversations.count) conversations from disk.")
//        } catch {
//            print("Failed to load or decode conversations: \(error). Starting fresh.")
//            // Consider deleting the corrupt file or notifying the user
//            self.conversations = [] // Reset if loading fails
//            self.currentConversation = Conversation(id: initialConversationID, messages: [.system(systemPrompt)])
//        }
//    }
//    
//    // Saves the current list of conversations to a JSON file
//    private func saveConversationsToDisk() {
//        Task(priority: .background) { // Perform saving in a background task
//            do {
//                let data = try JSONEncoder().encode(conversations)
//                try data.write(to: conversationsFileURL, options: [.atomicWrite]) // Use atomic write for safety
//                print("Saved \(conversations.count) conversations to disk.")
//            } catch {
//                print("Failed to save conversations: \(error)")
//                // Optionally show an error to the user
//                // DispatchQueue.main.async {
//                //    self.errorMessage = "Failed to save chat history."
//                // }
//            }
//        }
//    }
//    
//    // Adds a new conversation or updates an existing one in the history list
//    private func upsertCurrentConversation() {
//        // Don't save if it's just the initial system message
//        guard currentConversation.messages.count > 1 else { return }
//        
//        if let index = conversations.firstIndex(where: { $0.id == currentConversation.id }) {
//            // Update existing conversation
//            conversations[index] = currentConversation
//            print("Updated existing conversation (ID: \(currentConversation.id)) in history.")
//        } else {
//            // Add as a new conversation if it has more than the system prompt
//            // Ensure title is generated if needed (should be handled by Conversation init)
//            if currentConversation.title.isEmpty || currentConversation.title == "New Chat" {
//                let firstUserMsg = currentConversation.messages.first(where: { $0.role == .user })?.content ?? "Chat \(Date())"
//                currentConversation.title = String(firstUserMsg.prefix(32))
//            }
//            conversations.insert(currentConversation, at: 0) // Insert at the beginning (most recent)
//            print("Added new conversation (ID: \(currentConversation.id), Title: \(currentConversation.title)) to history.")
//        }
//        // Persistence is handled by the `didSet` on `conversations`
//    }
//}
//
//// MARK: — Subviews
//
//struct MessageBubble: View {
//    let msg: Message
//    var isUserMessage: Bool { msg.role == .user }
//    var onResend: ((Message) -> Void)? = nil // Callback for resending
//    var onSpeak: ((String) -> Void)? = nil // Callback for TTS
//    
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 8) {
//            if isUserMessage { Spacer(minLength: 40) } // Push user messages right
//            
//            VStack(alignment: isUserMessage ? .trailing : .leading, spacing: 4) {
//                // Optional: Display role for debugging or clarity
//                // Text(msg.role.rawValue.capitalized)
//                //     .font(.caption2)
//                //     .foregroundColor(.secondary)
//                
//                // Display the message content
//                Text(msg.content)
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 8)
//                    .background(bubbleBackground)
//                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//                    .foregroundColor(isUserMessage ? .white : .primary)
//                    .textSelection(.enabled) // Allow text selection
//                
//                // Timestamp below the bubble
//                Text(msg.timestamp, style: .time)
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal, 4)
//            }
//            .frame(maxWidth: .infinity, alignment: isUserMessage ? .trailing : .leading) // Ensure bubble takes space
//            
//            if !isUserMessage { Spacer(minLength: 40) } // Push assistant messages left
//        }
//        .contextMenu { contextMenuContent } // Add context menu
//    }
//    
//    // Background style for the bubble
//    private var bubbleBackground: some View {
//        isUserMessage
//        ? Color.blue // User message background
//        : Color(uiColor: .secondarySystemBackground) // Assistant message background
//    }
//    
//    // Content for the context menu
//    @ViewBuilder
//    private var contextMenuContent: some View {
//        Button {
//            UIPasteboard.general.string = msg.content
//        } label: {
//            Label("Copy Text", systemImage: "doc.on.doc")
//        }
//        
//        if !isUserMessage { // Only offer speak for assistant messages
//            Button {
//                onSpeak?(msg.content)
//            } label: {
//                Label("Read Aloud", systemImage: "speaker.wave.2.fill")
//            }
//        }
//        
//        if isUserMessage { // Only offer resend for user messages
//            Button {
//                onResend?(msg) // Trigger resend callback
//            } label: {
//                Label("Resend", systemImage: "arrow.clockwise")
//            }
//        }
//        
//        // Share functionality
//        ShareLink(item: msg.content) {
//            Label("Share", systemImage: "square.and.arrow.up")
//        }
//    }
//}
//
//struct ChatInputBar: View {
//    @Binding var text: String
//    @ObservedObject var store: ChatStore // Access store for state like isLoading
//    @ObservedObject var speech: SpeechRecognizer // Access speech recognizer state
//    @FocusState var isTextFieldFocused: Bool
//    
//    // Gesture state for long press
//    @GestureState private var isMicButtonPressed = false
//    
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 8) {
//            // Text Field
//            TextField("Type or hold mic to speak...", text: $text, axis: .vertical)
//                .focused($isTextFieldFocused)
//                .lineLimit(1...5) // Allow multiple lines up to 5
//                .padding(.horizontal, 12)
//                .padding(.vertical, 8)
//                .background(Color(.systemGray6)) // Slightly different background
//                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 20, style: .continuous)
//                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                )
//                .disabled(store.isLoading) // Disable text field while loading
//            
//            // Microphone Button
//            micButton
//            
//            // Send Button
//            sendButton
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//        .background(.thinMaterial) // Use thin material background
//        .onChange(of: speech.transcript) { _, newTranscript in
//            // Update text field in real-time during speech recognition if desired
//            // text = newTranscript // Uncomment this line for real-time transcript update
//        }
//        .animation(.easeInOut(duration: 0.2), value: isMicButtonPressed) // Animate mic button press
//    }
//    
//    // Microphone button view
//    private var micButton: some View {
//        let longPress = LongPressGesture(minimumDuration: 0.1) // Short duration to activate
//            .updating($isMicButtonPressed) { currentState, gestureState, _ in
//                gestureState = currentState // Update gesture state while pressing
//                // Start recording only when the press begins
//                if currentState && !speech.isRecording {
//                    DispatchQueue.main.async { // Ensure UI updates on main thread
//                        isTextFieldFocused = false // Dismiss keyboard
//                        speech.requestAuthorization { authorized in
//                            if authorized {
//                                do {
//                                    try speech.startRecording()
//                                } catch {
//                                    // Handle specific errors from startRecording
//                                    if let recognizerError = error as? SpeechRecognizer.RecognizerError {
//                                        store.errorMessage = recognizerError.localizedDescription // Show user-friendly error
//                                    } else {
//                                        store.errorMessage = "Failed to start recording: \(error.localizedDescription)"
//                                    }
//                                }
//                            } else {
//                                store.errorMessage = speech.errorMessage ?? "Microphone access denied."
//                            }
//                        }
//                    }
//                }
//            }
//            .onEnded { _ in
//                // Action when long press ends
//                if speech.isRecording {
//                    speech.stopRecording()
//                    // let finalTranscript = speech.transcript // Get transcript *before* potentially resetting
//                    // if !finalTranscript.isEmpty {
//                    // // Send message is now handled by the onFinalTranscription callback in ChatStore
//                    // store.sendMessage(finalTranscript) // //<- Removed: Handled by callback
//                    // }
//                }
//            }
//        
//        return Image(systemName: speech.isRecording ? "mic.fill" : "mic") // Use filled mic when recording
//            .resizable()
//            .scaledToFit()
//            .frame(width: 26, height: 26)
//            .padding(8) // Add padding to increase tap area
//            .foregroundColor(speech.isRecording ? .red : (store.isLoading ? .gray : .blue))
//            .background(isMicButtonPressed ? Color.gray.opacity(0.3) : Color.clear) // Visual feedback on press
//            .clipShape(Circle())
//            .gesture(longPress) // Attach the long press gesture
//            .disabled(store.isLoading) // Disable mic while loading
//            .accessibilityLabel(speech.isRecording ? "Recording... Release to send" : "Hold to speak")
//    }
//    
//    // Send button view
//    private var sendButton: some View {
//        Button {
//            store.sendMessage(text)
//            // Text is cleared within store.sendMessage now
//        } label: {
//            Image(systemName: "arrow.up.circle.fill") // Use a standard send icon
//                .resizable()
//                .scaledToFit()
//                .frame(width: 30, height: 30)
//                .foregroundColor(isSendButtonEnabled ? .blue : .gray.opacity(0.5))
//        }
//        .disabled(!isSendButtonEnabled)
//        .animation(.easeInOut, value: isSendButtonEnabled) // Animate enabled state change
//    }
//    
//    // Computed property to determine if the send button should be enabled
//    private var isSendButtonEnabled: Bool {
//        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !store.isLoading
//    }
//}
//
//struct SettingsSheet: View {
//    // AppStorage bindings for persistence (can be replaced with other persistence methods)
//    @AppStorage("openai_api_key") private var apiKey: String = ""
//    @AppStorage("selected_openai_model") private var openAIModelName: String = "gpt-4o"
//    @AppStorage("openai_temperature") private var temperature: Double = 0.7
//    @AppStorage("openai_max_tokens") private var maxTokens: Int = 384
//    @AppStorage("selected_backend_type") private var backendTypeRaw: String = BackendType.mock.rawValue
//    @AppStorage("selected_coreml_model") private var coreMLModelName: String = "LocalChat"
//    // @AppStorage("tts_rate") private var ttsRateValue: Float = 0.5
//    @AppStorage("tts_voice_id") private var selectedVoiceID: String = ""
//    
//    // Available options for pickers
//    let availableCoreMLModels = ["LocalChat", "TinyChat"] // Example CoreML models
//    let availableOpenAIModels = ["gpt-4o", "gpt-4", "gpt-3.5-turbo"] // Example OpenAI models
//    let availableVoices: [AVSpeechSynthesisVoice] // Populated by the parent store
//    
//    // Closure to notify the parent store about changes that require backend reconfiguration
//    var onBackendSettingsUpdate: () -> Void // Simplified: Just notify that settings changed
//    // Binding to control TTS enabled state directly in the parent store
//    @Binding var isTTSEnabled: Bool // Direct binding to ChatStore.ttsEnabled
//    
//    @Environment(\.dismiss) var dismiss
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                // Section: Backend Selection
//                Section("Backend Engine") {
//                    Picker("Provider", selection: $backendTypeRaw) {
//                        ForEach(BackendType.allCases) { type in
//                            Text(type.rawValue).tag(type.rawValue) // Use rawValue for tag
//                        }
//                    }
//                    .onChange(of: backendTypeRaw) { _, _ in onBackendSettingsUpdate() } // Notify on change
//                    
//                    // Conditional Picker for CoreML Model
//                    if BackendType(rawValue: backendTypeRaw) == .coreML {
//                        Picker("CoreML Model", selection: $coreMLModelName) {
//                            ForEach(availableCoreMLModels, id: \.self) { name in
//                                Text(name).tag(name)
//                            }
//                        }
//                        .onChange(of: coreMLModelName) { _, _ in onBackendSettingsUpdate() } // Notify on change
//                    }
//                }
//                
//                // Section: OpenAI Configuration (Conditional)
//                if BackendType(rawValue: backendTypeRaw) == .openAI {
//                    Section("OpenAI Configuration") {
//                        // Model Picker
//                        Picker("Model", selection: $openAIModelName) {
//                            ForEach(availableOpenAIModels, id: \.self) { name in
//                                Text(name).tag(name)
//                            }
//                        }
//                        .onChange(of: openAIModelName) { _, _ in onBackendSettingsUpdate() } // Notify on change
//                        
//                        // Temperature Stepper
//                        VStack(alignment: .leading) {
//                            Text("Temperature: \(temperature, specifier: "%.2f")")
//                            Slider(value: $temperature, in: 0...1, step: 0.05)
//                                .onChange(of: temperature) { _, _ in onBackendSettingsUpdate()} // Notify on change
//                        }
//                        
//                        // Max Tokens Stepper
//                        Stepper("Max Tokens: \(maxTokens)",
//                                value: $maxTokens, in: 64...4096, step: 64) // Wider range for tokens
//                        .onChange(of: maxTokens) { _, _ in onBackendSettingsUpdate() } // Notify on change
//                        
//                        // API Key Input
//                        SecureField("API Key (required)", text: $apiKey)
//                            .textContentType(.password) // Help with password managers
//                            .autocapitalization(.none)
//                            .onChange(of: apiKey) { _, _ in onBackendSettingsUpdate() } // Notify on change
//                        
//                        // Helper text if API Key is missing
//                        if apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
//                            Text("Enter your OpenAI API key to use this backend.")
//                                .font(.caption)
//                                .foregroundColor(.orange)
//                        }
//                    }
//                }
//                
//                // Section: Text-to-Speech (TTS)
//                //                Section("Audio Feedback (TTS)") {
//                //                     // Toggle for enabling/disabling TTS
//                //                      Toggle("Enable Text-to-Speech", isOn: $isTTSEnabled) // Use the binding
//                //
//                //                     // Conditional controls for TTS rate and voice if enabled
//                //                     if isTTSEnabled {
//                //                          // TTS Rate Slider
//                //                          VStack(alignment: .leading) {
//                //                               Text("Speech Rate: \(ttsRateValue, specifier: "%.2f")")
//                //                              Slider(value: $ttsRateValue, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate, step: 0.05)
//                //                          }
//                //
//                //                          // TTS Voice Picker
//                //                          Picker("Voice", selection: $selectedVoiceID) {
//                //                               ForEach(availableVoices, id: \.identifier) { voice in
//                //                                   Text("\(voice.name) (\(voice.language))")
//                //                                      .tag(voice.identifier)
//                //                               }
//                //                           }
//                //                          // Note: Updating ttsRate and voice does NOT require backend reconfiguration
//                //                           // So no `onBackendSettingsUpdate` call here. The ChatStore should react directly.
//                //                      }
//                //                }
//            }
//            .navigationTitle("Settings")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) { // Use .navigationBarTrailing
//                    Button("Done") { dismiss() }
//                }
//            }
//        }
//    }
//}
//
//struct HistorySheet: View {
//    @Binding var conversations: [Conversation] // Bind to the full list in the store
//    var onDelete: (UUID) -> Void // Callback for deleting a conversation
//    var onSelect: (Conversation) -> Void // Callback for selecting a conversation
//    var onRename: (Conversation, String) -> Void // Callback for renaming
//    var onClearAll: () -> Void // Callback for clearing history
//    
//    @Environment(\.dismiss) var dismiss
//    @State private var showingClearConfirm = false // State for confirmation dialog
//    @State private var renamingConversation: Conversation? = nil // Track which convo is being renamed
//    @State private var newName: String = "" // Temp storage for new name input
//    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                // Display list or empty state
//                if conversations.isEmpty {
//                    Spacer()
//                    Text("No Chat History Yet")
//                        .font(.title2)
//                        .foregroundColor(.secondary)
//                    Spacer()
//                } else {
//                    List {
//                        ForEach(conversations) { convo in
//                            historyRow(for: convo) // Use helper function for row content
//                        }
//                        .onDelete { indexSet in
//                            deleteItems(at: indexSet) // Handle swipe-to-delete
//                        }
//                    }
//                    .listStyle(.plain) // Use plain style for a cleaner look
//                }
//                
//                // Clear All Button (conditionally shown)
//                if !conversations.isEmpty {
//                    Button("Clear All History", role: .destructive) {
//                        showingClearConfirm = true // Show confirmation alert
//                    }
//                    .padding()
//                }
//            }
//            .navigationTitle("Chat History")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) { // Consistent placement
//                    Button("Close") { dismiss() }
//                }
//            }
//            .alert("Rename Chat", isPresented: .constant(renamingConversation != nil), actions: {
//                // Alert actions for renaming
//                TextField("Enter new name", text: $newName)
//                    .autocapitalization(.sentences)
//                Button("Cancel", role: .cancel) { renamingConversation = nil; newName = "" }
//                Button("Save") {
//                    if let convo = renamingConversation, !newName.trimmingCharacters(in: .whitespaces).isEmpty {
//                        onRename(convo, newName) // Call rename callback
//                    }
//                    renamingConversation = nil
//                    newName = ""
//                }
//            }, message: {
//                // Message for the rename alert
//                Text("Please enter a new title for this conversation.")
//            })
//            .confirmationDialog( // Confirmation for clearing history
//                "Are you sure you want to delete all chat history? This cannot be undone.",
//                isPresented: $showingClearConfirm,
//                titleVisibility: .visible
//            ) {
//                Button("Delete All", role: .destructive) {
//                    onClearAll() // Call clear callback
//                    dismiss() // Optionally close sheet after clearing
//                }
//                Button("Cancel", role: .cancel) {}
//            }
//        }
//        .presentationDetents([.medium, .large]) // Allow resizing
//    }
//    
//    // Helper function to create a row for the history list
//    private func historyRow(for convo: Conversation) -> some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text(convo.title)
//                    .font(.headline)
//                    .lineLimit(1)
//                Text("Messages: \(convo.messages.filter { $0.role != .system }.count) | \(convo.createdAt, style: .date)")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            Spacer() // Pushes menu to the right
//            
//            // Menu for actions (Open, Rename, Share)
//            Menu {
//                Button {
//                    onSelect(convo) // Call select callback
//                    dismiss() // Close sheet after selection
//                } label: {
//                    Label("Open", systemImage: "folder.fill")
//                }
//                
//                Button {
//                    // Prepare state for renaming alert
//                    renamingConversation = convo
//                    newName = convo.title // Pre-fill text field
//                } label: {
//                    Label("Rename", systemImage: "pencil")
//                }
//                
//                // Share conversation content
//                ShareLink(item: conversationText(convo)) {
//                    Label("Share Transcript", systemImage: "square.and.arrow.up")
//                }
//                
//                // Explicit Delete Button in Menu (optional, as swipe-to-delete exists)
//                // Button(role: .destructive) {
//                //     onDelete(convo.id)
//                // } label: {
//                //     Label("Delete", systemImage: "trash")
//                // }
//                
//            } label: {
//                Image(systemName: "ellipsis.circle")
//                    .imageScale(.large) // Make menu icon slightly larger
//            }
//            .buttonStyle(.borderless) // Make menu look cleaner in the list row
//        }
//        .contentShape(Rectangle()) // Make the whole row tappable for selection
//        .onTapGesture {
//            onSelect(convo)
//            dismiss()
//        }
//    }
//    
//    // Helper function to handle swipe-to-delete
//    private func deleteItems(at offsets: IndexSet) {
//        offsets.map { conversations[$0].id }.forEach(onDelete)
//    }
//    
//    // Helper to format conversation for sharing
//    private func conversationText(_ convo: Conversation) -> String {
//        convo.messages
//            .map { "\($0.role.rawValue.capitalized): \($0.content)" }
//            .joined(separator: "\n\n")
//    }
//    
//}
//
//// MARK: — Main View
//
//struct ChatDemoView: View {
//    @StateObject var store = ChatStore()
//    @StateObject var speech = SpeechRecognizer() // Manages speech recognition state
//    @FocusState private var isInputFocused: Bool // Manages focus state of the input bar
//    
//    // State variables to control sheet presentation
//    @State private var showingSettingsSheet = false
//    @State private var showingHistorySheet = false
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) { // Use zero spacing for seamless layout
//                // Custom Header View
//                chatHeader
//                
//                // Scrollable Message Area
//                messagesScrollView
//                
//                // Input Bar View
//                ChatInputBar(
//                    text: $store.currentInput,
//                    store: store,
//                    speech: speech,
//                    isTextFieldFocused: _isInputFocused // Pass focus state
//                )
//            }
//            .background(Color(.systemGroupedBackground)) // Background for the entire view
//            .navigationBarHidden(true) // Hide default navigation bar, using custom header
//            .sheet(isPresented: $showingSettingsSheet) {
//                // Settings Sheet Presentation
//                SettingsSheet(
//                    availableVoices: store.availableVoices, // Pass available voices
//                    onBackendSettingsUpdate: {
//                        // This closure is called when backend-related settings change
//                        store.configureBackend() // Tell the store to reconfigure
//                    },
//                    isTTSEnabled: $store.ttsEnabled // Bind TTS toggle state
//                )
//            }
//            .sheet(isPresented: $showingHistorySheet) {
//                // History Sheet Presentation
//                HistorySheet(
//                    conversations: $store.conversations,
//                    onDelete: store.deleteConversation(id:),
//                    onSelect: { conversation in
//                        store.selectConversation(conversation)
//                        // showingHistorySheet = false // Dismiss handled internally now
//                    },
//                    onRename: store.renameConversation(_:to:),
//                    onClearAll: store.clearAllHistory // Use correct callback name
//                )
//            }
//            .alert("Error", isPresented: .constant(store.errorMessage != nil), actions: {
//                // Error Alert
//                Button("OK") { store.errorMessage = nil } // Dismiss alert
//            }, message: {
//                // Display the error message from the store
//                Text(store.errorMessage ?? "An unknown error occurred.")
//            })
//            .onAppear {
//                // Initial setup when the view appears
//                store.attachSpeechRecognizer(speech) // Link store to speech recognizer
//                speech.requestAuthorization { _ in /* Handle auth result if needed */ }
//            }
//            .onChange(of: store.selectedBackendType) { _, _ in
//                // Optional: Update header or UI based on backend changes
//                print("Backend type changed in ChatDemoView.")
//            }
//        }
//    }
//    
//    // Custom header view for the chat interface
//    private var chatHeader: some View {
//        HStack {
//            // Display current conversation title
//            Text(store.currentConversation.title)
//                .font(.headline)
//                .lineLimit(1)
//                .truncationMode(.tail)
//                .frame(maxWidth: .infinity, alignment: .leading) // Allow title to take space
//            
//            Spacer() // Pushes icons to the right
//            
//            // TTS Status Indicator (optional)
//            if store.ttsEnabled {
//                Image(systemName: "speaker.wave.2.fill")
//                    .foregroundColor(.secondary)
//                    .accessibilityLabel("Text-to-Speech is enabled")
//            }
//            
//            // Loading Indicator
//            if store.isLoading {
//                ProgressView()
//                    .scaleEffect(0.8) // Make indicator slightly smaller
//                    .padding(.horizontal, 4)
//            }
//            
//            // History Button
//            Button { showingHistorySheet = true } label: {
//                Image(systemName: "clock.arrow.circlepath")
//                    .imageScale(.large)
//            }
//            .disabled(store.isLoading) // Disable while loading
//            .accessibilityLabel("View Chat History")
//            
//            // Settings Button
//            Button { showingSettingsSheet = true } label: {
//                Image(systemName: "gearshape") // Use gearshape icon
//                    .imageScale(.large)
//            }
//            .disabled(store.isLoading) // Disable while loading
//            .accessibilityLabel("Open Settings")
//            
//            // New Chat Button
//            Button { store.startNewConversation() } label: { // Use store function
//                Image(systemName: "square.and.pencil") // Icon for new/compose
//                    .imageScale(.large)
//            }
//            .disabled(store.isLoading) // Disable while loading
//            .accessibilityLabel("Start New Chat")
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 10) // Adjust vertical padding
//        .background(.thinMaterial) // Apply material background to header
//    }
//    
//    // Scrollable view for displaying messages
//    private var messagesScrollView: some View {
//        ScrollViewReader { scrollProxy in
//            ScrollView {
//                LazyVStack(spacing: 12) { // Use LazyVStack for performance
//                    // Display a placeholder if no messages exist (excluding system prompt)
//                    if store.currentConversation.messages.filter({ $0.role != .system }).isEmpty {
//                        Text("Send a message to start chatting!")
//                            .foregroundColor(.secondary)
//                            .padding(.top, 50) // Add padding to center it somewhat
//                    } else {
//                        // Iterate through messages, skipping the system prompt for display
//                        ForEach(store.currentConversation.messages.filter { $0.role != .system }) { message in
//                            MessageBubble(
//                                msg: message,
//                                // Provide callbacks for bubble interactions
//                                onResend: { msgToResend in // Simplified resend just uses current input mechanism
//                                    store.currentInput = msgToResend.content
//                                },
//                                onSpeak: { textToSpeak in
//                                    store.speak(textToSpeak)
//                                }
//                            )
//                            .id(message.id) // Assign ID for scrolling
//                        }
//                    }
//                    
//                    // Optional: Placeholder for typing indicator or loading state
//                    if store.isLoading {
//                        HStack {
//                            Text("Assistant is typing...")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            ProgressView().scaleEffect(0.5)
//                        }.padding(.vertical, 5)
//                    }
//                }
//                .padding(.top, 10) // Add padding at the top of the messages
//                .padding(.horizontal)
//            }
//            .background(Color(.systemGroupedBackground)) // Match overall background
//            .onTapGesture {
//                // Dismiss keyboard when tapping outside the input bar
//                isInputFocused = false
//            }
//            .onChange(of: store.currentConversation.messages.last?.id) { _, newID in
//                // Auto-scroll to the bottom when a new message is added
//                if let id = newID {
//                    withAnimation(.spring()) { // Use spring animation for smooth scroll
//                        scrollProxy.scrollTo(id, anchor: .bottom)
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: — Helper Extensions
//
//extension UIApplication {
//    // Finds the top-most view controller in the hierarchy
//    static var topViewController: UIViewController? {
//        let keyWindow = UIApplication.shared.connectedScenes
//            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
//            .first
//        
//        guard var topController = keyWindow?.rootViewController else {
//            return nil
//        }
//        
//        // Traverse up the hierarchy of presented view controllers
//        while let presentedViewController = topController.presentedViewController {
//            topController = presentedViewController
//        }
//        
//        return topController
//    }
//}
//
//extension UIActivityViewController {
//    // Helper to present a share sheet easily
//    static func presentShareSheet(text: String) {
//        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
//        
//        // On iPad, provide source view/rect to avoid crash
//        if let popoverController = activityViewController.popoverPresentationController {
//            if let sourceView = UIApplication.topViewController?.view {
//                popoverController.sourceView = sourceView
//                popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0) // Center anchor
//                popoverController.permittedArrowDirections = [] // No arrow for centered popover
//            }
//        }
//        
//        UIApplication.topViewController?.present(activityViewController, animated: true)
//    }
//}
//
//// MARK: — Preview
//
//#Preview {
//    ChatDemoView()
//        .preferredColorScheme(.light) // Preview in light mode
//}
//
//#Preview {
//    ChatDemoView()
//        .preferredColorScheme(.dark) // Preview in dark mode
//}
