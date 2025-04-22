////
////  ChatApp_UsingAppleVoiceUserInterfaceDesign.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/21/25.
////
//
////
////  SynthesizedChatApp.swift
////  Single-file SwiftUI Chat Demo
////
////  Combines Mock, OpenAI, and CoreML backends with Text & Speech I/O.
////  Integrates VUI principles like natural language input/output, feedback, and error handling.
////
////  Requires: Xcode 15+, iOS 17+
////  Created: Synthesized on [Date]
////
//
//import SwiftUI
//import Combine
//import Speech // For Speech Recognition (Input)
//import AVFoundation // For Text-to-Speech (Output) & Audio Session Management
//import CoreML // For potential local model inference
//
//// MARK: — 1. Data Models
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
//        self.id = id
//        self.role = role
//        self.content = content
//        self.timestamp = timestamp
//    }
//    
//    // Static factory methods for convenience
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
//            let firstUser = messages.first(where: { $0.role == .user })?.content ?? "New Chat" // Default title
//            self.title = String(firstUser.prefix(32)) // Limit title length
//        } else {
//            self.title = title
//        }
//    }
//}
//
//// MARK: — 2. Backend Protocols & Implementations
//
//// Protocol defining the contract for any chat service
//protocol ChatBackend {
//    func streamChat(
//        messages: [Message],
//        systemPrompt: String,
//        completion: @escaping (Result<String, Error>) -> Void
//    )
//}
//
//// Mock implementation for testing and development
//struct MockChatBackend: ChatBackend {
//    let replies = [
//        "Chắc chắn rồi!", "Okay!", "Để tôi xem...", "Tôi hiểu rồi.",
//        "Bạn muốn biết thêm gì?", "Có thể nói rõ hơn không?", "Một ý tưởng hay!"
//    ]
//    func streamChat(
//        messages: [Message],
//        systemPrompt: String,
//        completion: @escaping (Result<String, Error>) -> Void
//    ) {
//        // Simulate network delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            completion(.success(replies.randomElement()!))
//        }
//    }
//}
//
//// Implementation using the OpenAI API
//final class RealOpenAIBackend: ChatBackend {
//    let apiKey: String
//    let model: String
//    let temperature: Double
//    let maxTokens: Int
//    
//    init(apiKey: String, model: String, temperature: Double, maxTokens: Int) {
//        self.apiKey = apiKey
//        self.model = model
//        self.temperature = temperature
//        self.maxTokens = maxTokens
//    }
//    
//    func streamChat(
//        messages: [Message],
//        systemPrompt: String,
//        completion: @escaping (Result<String, Error>) -> Void)
//    {
//        // VUI: Include system prompt for context/personality
//        var allMessages = messages
//        if !systemPrompt.isEmpty {
//            allMessages.insert(.system(systemPrompt), at: 0)
//        }
//        
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            DispatchQueue.main.async { completion(.failure(NSError(domain: "InvalidURL", code: 0))) }
//            return
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        // Define the structure matching the OpenAI API request body
//        struct RequestPayload: Encodable {
//            struct MessagePayload: Encodable { let role: String; let content: String }
//            let model: String
//            let messages: [MessagePayload]
//            let temperature: Double
//            let max_tokens: Int // Renamed to match API
//        }
//        
//        // Map our Message model to the API's expected format
//        let body = RequestPayload(
//            model: self.model, // Use the model specified during initialization
//            messages: allMessages.map { RequestPayload.MessagePayload(role: $0.role.rawValue, content: $0.content) },
//            temperature: self.temperature,
//            max_tokens: self.maxTokens
//        )
//        
//        do {
//            request.httpBody = try JSONEncoder().encode(body)
//        } catch {
//            DispatchQueue.main.async { completion(.failure(error)) }
//            return
//        }
//        
//        // Perform the network request
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            // VUI: Clear and actionable error handling
//            if let networkError = error {
//                DispatchQueue.main.async { completion(.failure(networkError)) }
//                return
//            }
//            guard let responseData = data else {
//                DispatchQueue.main.async { completion(.failure(NSError(domain: "NoData", code: 1))) }
//                return
//            }
//            
//            // Define the structure matching the OpenAI API response body
//            struct ResponsePayload: Decodable {
//                struct Choice: Decodable {
//                    struct Message: Decodable { let content: String }
//                    let message: Message
//                }
//                let choices: [Choice]
//            }
//            
//            // Decode the response
//            do {
//                let decodedResponse = try JSONDecoder().decode(ResponsePayload.self, from: responseData)
//                let replyText = decodedResponse.choices.first?.message.content ?? "Xin lỗi, tôi không nhận được phản hồi." // VUI: Graceful failure message
//                DispatchQueue.main.async { completion(.success(replyText)) }
//            } catch {
//                // Try decoding potential error response from OpenAI
//                struct ErrorResponse: Decodable {
//                    struct ErrorDetail: Decodable { let message: String }
//                    let error: ErrorDetail?
//                }
//                let errorMsg: String
//                if let decodedError = try? JSONDecoder().decode(ErrorResponse.self, from: responseData),
//                   let message = decodedError.error?.message {
//                    errorMsg = "API Error: \(message)"
//                } else {
//                    errorMsg = "Lỗi giải mã phản hồi: \(error.localizedDescription)"
//                }
//                let wrappedError = NSError(domain: "DecodingError", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMsg])
//                DispatchQueue.main.async { completion(.failure(wrappedError)) }
//            }
//        }.resume()
//    }
//}
//
//// Enum for different backend types
//enum BackendType: String, CaseIterable, Identifiable {
//    case mock = "Mock"
//    case openAI = "OpenAI"
//    case coreML = "CoreML (Local)"
//    var id: Self { self }
//}
//
//// Implementation using a local CoreML model (Placeholder)
//final class CoreMLChatBackend: ChatBackend { // Changed struct to final class
//    let modelName: String
//    lazy var coreModel: MLModel? = {
//        // Attempt to load the compiled CoreML model
//        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
//            print("Error: CoreML model '\(modelName).mlmodelc' not found.")
//            return nil
//        }
//        do {
//            print("Attempting to load CoreML model at URL: \(url.path)") // Added print
//            let model = try MLModel(contentsOf: url)
//            print("Successfully loaded CoreML model: \(modelName)") // Added print
//            return model
//        } catch {
//            print("Error loading CoreML model '\(modelName)': \(error)")
//            return nil
//        }
//    }() // Ensure the () are here to execute the closure for lazy init
//    
//    init(modelName: String) { // Add an initializer for the class
//        self.modelName = modelName
//        // You could optionally trigger lazy loading here if desired, but lazy usually means on first use
//        // _ = self.coreModel
//    }
//    
//    func streamChat(
//        messages: [Message],
//        systemPrompt: String,
//        completion: @escaping (Result<String, Error>) -> Void
//    ) {
//        // Accessing coreModel here is now allowed because it's a class
//        guard let model = coreModel else {
//            let error = NSError(domain: "CoreMLError", code: 1, userInfo: [NSLocalizedDescriptionKey: "CoreML model '\(modelName)' could not be loaded."]) // Improved error message
//            DispatchQueue.main.async { completion(.failure(error)) }
//            return
//        }
//        
//        // --- Placeholder for actual CoreML inference ---
//        // This would involve:
//        // 1. Preprocessing `messages` into the format the model expects (e.g., token IDs).
//        // 2. Creating an `MLFeatureProvider` input.
//        // 3. Calling `model.prediction(from: input)`.
//        // 4. Postprocessing the output features back into text.
//        // ----------------------------------------------
//        
//        // Simulate processing delay and echo the last message
//        let lastUserInput = messages.last(where: { $0.role == .user })?.content ?? ""
//        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
//            let reply = "CoreML (\(self.modelName)) trả lời: '\(lastUserInput)'"
//            DispatchQueue.main.async { completion(.success(reply)) }
//        }
//    }
//}
//// MARK: — 3. Speech Recognizer (Speech-to-Text)
//
//final class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
//    // Published properties to update the UI
//    @Published var transcript = ""
//    @Published var isRecording = false
//    @Published var errorMessage: String? // VUI: Expose errors for UI feedback
//    
//    // Callback for when transcription is finalized (e.g., by silence or stopping)
//    var onFinalTranscription: ((String) -> Void)?
//    
//    // Speech recognition components
//    private let recognizer: SFSpeechRecognizer? // Use the specified Vietnamese locale
//    private let audioEngine = AVAudioEngine() // Processes audio buffers
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? // Request for buffering audio
//    private var recognitionTask: SFSpeechRecognitionTask? // The actual recognition task
//    
//    // Silence detection mechanism
//    private let silenceTimeout: TimeInterval = 1.8 // Adjust as needed
//    private var silenceTimer: Timer?
//    
//    override init() {
//        // VUI: Set the locale for better regional understanding
//        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
//        super.init()
//        self.recognizer?.delegate = self // Set delegate if needed for availability changes
//    }
//    
//    // VUI: Request user authorization clearly
//    func requestAuthorization(completion: @escaping (Bool) -> Void) {
//        SFSpeechRecognizer.requestAuthorization { authStatus in
//            let authorized = authStatus == .authorized
//            DispatchQueue.main.async {
//                if !authorized {
//                    self.errorMessage = "Quyền truy cập microphone và nhận dạng giọng nói là cần thiết. Vui lòng bật trong Cài đặt."
//                }
//                completion(authorized)
//            }
//        }
//    }
//    
//    // Start the recording and recognition process
//    func startRecording() throws {
//        // Reset state
//        errorMessage = nil
//        transcript = ""
//        isRecording = true
//        recognitionTask?.cancel(); recognitionTask = nil
//        recognitionRequest?.endAudio(); recognitionRequest = nil
//        silenceTimer?.invalidate(); silenceTimer = nil
//        
//        // Configure audio session
//        let audioSession = AVAudioSession.sharedInstance()
//        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        
//        // Create recognition request
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        guard let recognitionRequest = recognitionRequest else {
//            fatalError("Unable to create SFSpeechAudioBufferRecognitionRequest")
//        }
//        recognitionRequest.shouldReportPartialResults = true // VUI: Show live transcript
//        recognitionRequest.taskHint = .dictation // Optimize for dictation
//        
//        // Check recognizer availability
//        guard let speechRecognizer = recognizer, speechRecognizer.isAvailable else {
//            errorMessage = "Bộ nhận dạng giọng nói không khả dụng cho tiếng Việt."
//            stopRecording() // Clean up
//            return
//        }
//        
//        // Start recognition task
//        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
//            guard let self = self else { return }
//            var isFinal = false
//            
//            if let result = result {
//                // VUI: Update transcript for live feedback
//                DispatchQueue.main.async {
//                    self.transcript = result.bestTranscription.formattedString
//                }
//                isFinal = result.isFinal
//                // Reset silence timer on receiving new results
//                self.resetSilenceTimer()
//            }
//            
//            // VUI: Handle errors clearly
//            if error != nil || isFinal {
//                DispatchQueue.main.async {
//                    if let error = error {
//                        self.errorMessage = "Lỗi nhận dạng: \(error.localizedDescription)"
//                    }
//                    self.finishTranscription() // Stop recording on error or final result
//                }
//            }
//        }
//        
//        // Configure audio engine input node
//        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
//        audioEngine.inputNode.removeTap(onBus: 0) // Remove existing tap first
//        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//            self.recognitionRequest?.append(buffer)
//        }
//        
//        // Prepare and start audio engine
//        audioEngine.prepare()
//        try audioEngine.start()
//        
//        // Start the initial silence timer
//        resetSilenceTimer()
//    }
//    
//    // Reset the silence timer
//    private func resetSilenceTimer() {
//        silenceTimer?.invalidate()
//        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
//            guard let self = self, self.isRecording else { return }
//            print("Silence detected.")
//            DispatchQueue.main.async { // Ensure finishTranscription is called on main thread
//                self.finishTranscription()
//            }
//        }
//    }
//    
//    // Call this when recording should stop and final transcript is processed
//    func finishTranscription() {
//        guard isRecording else { return } // Prevent multiple calls
//        
//        let finalTranscript = self.transcript // Capture current transcript
//        stopRecording() // Stop audio engine, session, etc.
//        
//        // VUI: Handle final transcript
//        if !finalTranscript.isEmpty {
//            onFinalTranscription?(finalTranscript)
//        }
//    }
//    
//    // Stop audio engine, invalidate timers, clean up resources
//    func stopRecording() {
//        guard isRecording else { return } // Prevent multiple calls if already stopped
//        isRecording = false // Update state immediately
//        
//        silenceTimer?.invalidate(); silenceTimer = nil
//        
//        if audioEngine.isRunning {
//            audioEngine.stop()
//            audioEngine.inputNode.removeTap(onBus: 0)
//        }
//        recognitionRequest?.endAudio() // Signal end of audio
//        recognitionTask?.finish() // Finish task if not already finalized
//        
//        // Deactivate audio session (important for releasing resources)
//        do {
//            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
//        } catch {
//            // VUI: Log deactivation errors
//            print("Error deactivating audio session: \(error.localizedDescription)")
//            DispatchQueue.main.async {
//                self.errorMessage = "Lỗi dừng audio session."
//            }
//        }
//        
//        // Nullify task and request *after* stopping engine and session
//        recognitionTask = nil
//        recognitionRequest = nil
//    }
//    
//    // SFSpeechRecognizerDelegate method (optional)
//    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
//        if !available {
//            DispatchQueue.main.async {
//                self.errorMessage = "Bộ nhận dạng giọng nói không còn khả dụng."
//                self.stopRecording()
//            }
//        }
//    }
//}
//
//// MARK: — 4. ViewModel (Central State Management)
//@MainActor
//final class ChatStore: ObservableObject {
//    // MARK: - Published Properties (UI State)
//    @Published var conversations: [Conversation] = [] { didSet { saveToDisk() } }
//    @Published var current: Conversation // Will be initialized below
//    @Published var input: String = ""
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//    
//    // Settings synced with UserDefaults
//    @AppStorage("system_prompt") var systemPrompt: String = "Bạn là một trợ lý AI hữu ích nói tiếng Việt."
//    @AppStorage("tts_enabled") var ttsEnabled: Bool = false
//    @AppStorage("tts_rate") var ttsRate: Double = 1.0 // AVSpeechUtteranceDefaultSpeechRate * 1.0 might be better if API changes
//    @AppStorage("tts_voice_id") var ttsVoiceID: String = ""
//    @AppStorage("openai_api_key") var apiKey: String = ""
//    @AppStorage("backend_type") private var backendTypeRaw: String = BackendType.mock.rawValue
//    @AppStorage("coreml_model_name") var coreMLModelName: String = "TinyChat"
//    @AppStorage("openai_model_name") var openAIModelName: String = "gpt-4o"
//    @AppStorage("openai_temperature") var openAITemperature: Double = 0.7
//    @AppStorage("openai_max_tokens") var openAIMaxTokens: Int = 512
//    
//    // Available models for settings
//    let availableCoreMLModels = ["TinyChat", "LocalChat"]
//    let availableOpenAIModels = ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"]
//    let availableVoices: [AVSpeechSynthesisVoice]
//    
//    // MARK: - Private Properties
//    private(set) var backend: ChatBackend
//    private let ttsSynth = AVSpeechSynthesizer()
//    private var ttsDelegate: TTSSpeechDelegate?
//    
//    // MARK: - Computed Properties
//    var backendType: BackendType {
//        get { BackendType(rawValue: backendTypeRaw) ?? .mock }
//        set { backendTypeRaw = newValue.rawValue; configureBackend() }
//    }
//    
//    // MARK: - Initialization
//    init() {
//        // ----- Phase 1: Initialize all stored properties -----
//        
//        // Initialize properties that *don't* depend on reading 'self' yet
//        self.availableVoices = AVSpeechSynthesisVoice.speechVoices().sorted { v1, v2 in
//            let v1Vi = v1.language.starts(with: "vi")
//            let v2Vi = v2.language.starts(with: "vi")
//            if v1Vi != v2Vi { return v1Vi } // Prioritize Vietnamese
//            return v1.name < v2.name
//        }
//        self.backend = MockChatBackend() // Start with a temporary backend
//        self.ttsDelegate = TTSSpeechDelegate() // Initialize the delegate helper
//        
//        // Initialize 'current' with a temporary placeholder.
//        // We *must* give it a value here. It will be overwritten in Phase 2.
//        self.current = Conversation(id: UUID(), title: "", messages: [])
//        
//        // Note: @AppStorage properties (apiKey, systemPrompt, ttsVoiceID, etc.)
//        // are automatically initialized from UserDefaults by the wrapper at this point.
//        
//        // ----- Phase 2: Perform logic *after* all properties are initialized -----
//        // Now 'self' is fully available.
//        
//        // 1. Set the TTS delegate
//        self.ttsSynth.delegate = self.ttsDelegate
//        
//        // 2. Correct ttsVoiceID if needed (now safe to read self.ttsVoiceID)
//        let initialTTSVoiceID = self.ttsVoiceID // Read the potentially empty value loaded by @AppStorage
//        if initialTTSVoiceID.isEmpty || self.availableVoices.first(where: { $0.identifier == initialTTSVoiceID }) == nil {
//            // Assign a default Vietnamese voice or the first available voice
//            self.ttsVoiceID = self.availableVoices.first(where: {$0.language.starts(with: "vi-VN")})?.identifier ?? self.availableVoices.first?.identifier ?? ""
//        }
//        
//        // 3. Create the *real* initial conversation template using the loaded systemPrompt
//        let realInitialConversation = Conversation(messages: [.system(self.systemPrompt)]) // Now safe to read self.systemPrompt
//        
//        // 4. Load saved conversations from disk FIRST
//        loadFromDisk() // This populates self.conversations
//        
//        // 5. Configure the actual backend based on loaded settings (reads @AppStorage values)
//        configureBackend() // Now safe to call
//        
//        // 6. Assign the final 'current' conversation
//        if let mostRecent = conversations.first {
//            self.current = mostRecent // Use the most recent saved chat if history exists
//            // Optional: Ensure system prompt consistency in loaded chats
//            if self.current.messages.first?.role != .system {
//                self.current.messages.insert(.system(self.systemPrompt), at: 0)
//                // If you modified 'current', update the main array too for consistency on next save
//                if let index = self.conversations.firstIndex(where: { $0.id == self.current.id }) {
//                    self.conversations[index] = self.current
//                }
//            } else if self.current.messages.first?.content != self.systemPrompt {
//                // Policy decision: Do you want to UPDATE the system message in old chats
//                // if the user changed the setting? Or leave old chats as they were?
//                // Example: Update it:
//                // self.current.messages[0] = .system(self.systemPrompt)
//                // if let index = self.conversations.firstIndex(where: { $0.id == self.current.id }) {
//                //     self.conversations[index] = self.current
//                // }
//            }
//        } else {
//            // If no history was loaded, use the freshly created initial conversation template
//            self.current = realInitialConversation
//        }
//        
//        // Initialization complete
//    } // End init
//    
//    // ... (rest of the ChatStore methods: setBackend, configureBackend, resetChat, etc.) ...
//    
//    // MARK: - Backend Management
//    func setBackend(_ newBackend: ChatBackend, type: BackendType) {
//        backend = newBackend
//        // Update AppStorage which triggers configureBackend via the computed property's setter
//        backendTypeRaw = type.rawValue
//        print("Backend explicitly set to: \(type.rawValue)")
//    }
//    
//    private func configureBackend() {
//        print("Configuring backend for type: \(self.backendType.rawValue)") // Use self explicitly for clarity inside method
//        
//        // --- Safety Check: OpenAI ---
//        if self.backendType == .openAI && self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            print("Warning: OpenAI backend selected but API key is missing. Falling back to Mock.")
//            // Update state on the main thread for potential UI feedback
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                // Check if we are not already on Mock to avoid infinite loop if setter calls configure again
//                if self.backendType != .mock {
//                    self.errorMessage = "Khóa API OpenAI bị thiếu. Sử dụng Mock backend."
//                    self.backend = MockChatBackend() // Set directly
//                    self.backendTypeRaw = BackendType.mock.rawValue // Update storage last
//                }
//            }
//            return // Stop configuration here
//        }
//        
//        // --- Safety Check: CoreML ---
//        if self.backendType == .coreML {
//            let coreMLBackend = CoreMLChatBackend(modelName: self.coreMLModelName) // Create instance to check model
//            if coreMLBackend.coreModel == nil {
//                print("Warning: CoreML model '\(self.coreMLModelName)' failed to load. Falling back to Mock.")
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    if self.backendType != .mock {
//                        self.errorMessage = "Không tải được mô hình CoreML '\(self.coreMLModelName)'. Sử dụng Mock backend."
//                        self.backend = MockChatBackend()
//                        self.backendTypeRaw = BackendType.mock.rawValue
//                    }
//                }
//                return // Stop configuration here
//            }
//            // If model loaded successfully, assign the created backend instance
//            self.backend = coreMLBackend
//        } else {
//            // --- Configure other backends (Mock, or OpenAI if key was present) ---
//            switch self.backendType {
//            case .mock:
//                self.backend = MockChatBackend()
//            case .openAI:
//                // Key presence was checked earlier
//                self.backend = RealOpenAIBackend(
//                    apiKey: self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
//                    model: self.openAIModelName,
//                    temperature: self.openAITemperature,
//                    maxTokens: self.openAIMaxTokens
//                )
//            case .coreML:
//                // This case was handled above, but include for safety/exhaustiveness
//                print("CoreML should have been configured already. Re-checking.")
//                let backendCheck = CoreMLChatBackend(modelName: self.coreMLModelName)
//                self.backend = (backendCheck.coreModel != nil) ? backendCheck : MockChatBackend()
//                
//            }
//        }
//        print("Backend configured successfully to: \(self.backendType.rawValue)")
//    }
//    
//    // MARK: - Chat Actions
//    func resetChat() {
//        stopSpeaking() // Stop TTS if active
//        // Create a new conversation based on the *current* system prompt setting
//        self.current = Conversation(messages: [.system(self.systemPrompt)])
//        self.input = ""
//        self.isLoading = false
//        self.errorMessage = nil
//        // Don't save to history until messages are added.
//        print("Chat reset.")
//    }
//    
//    func sendMessage(_ text: String) {
//        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmedText.isEmpty, !isLoading else { return }
//        
//        stopSpeaking() // Stop previous TTS
//        
//        let userMessage = Message.user(trimmedText)
//        // Append user message *immediately* for UI responsiveness
//        current.messages.append(userMessage)
//        
//        // Create a copy of messages *before* the async call
//        let messagesForBackend = current.messages
//        
//        input = ""
//        isLoading = true
//        errorMessage = nil
//        
//        print("Sending messages to backend (\(backendType.rawValue)). Count: \(messagesForBackend.count)")
//        
//        backend.streamChat(messages: messagesForBackend, systemPrompt: systemPrompt) { [weak self] result in
//            // Ensure updates happen on the main thread
//            DispatchQueue.main.async {
//                guard let self = self else { return }
//                self.isLoading = false
//                
//                switch result {
//                case .success(let replyText):
//                    print("Received reply: \(replyText.prefix(50))...")
//                    let assistantMessage = Message.assistant(replyText)
//                    self.current.messages.append(assistantMessage)
//                    self.upsertConversation() // Save the updated conversation
//                    
//                    if self.ttsEnabled {
//                        self.speak(replyText)
//                    }
//                    
//                case .failure(let error):
//                    print("Backend error: \(error.localizedDescription)")
//                    self.errorMessage = "Lỗi Backend: \(error.localizedDescription)"
//                    // Optional: Decide whether to remove the user's message that caused the error
//                    // if let lastMsg = self.current.messages.last, lastMsg.id == userMessage.id {
//                    //     self.current.messages.removeLast()
//                    // }
//                }
//            }
//        }
//    }
//    
//    func speak(_ text: String) {
//        guard ttsEnabled, !text.isEmpty else { return }
//        
//        if ttsSynth.delegate == nil {
//            ttsDelegate = TTSSpeechDelegate()
//            ttsSynth.delegate = ttsDelegate
//        }
//        
//        // Ensure correct audio configuration before speaking
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
//            // Activation is handled by delegate now -> try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
//        } catch {
//            print("Failed to set audio session category for TTS: \(error)")
//            // Optionally inform the user
//            // self.errorMessage = "Lỗi cấu hình âm thanh cho TTS."
//            // return // Decide if you should stop here
//        }
//        
//        let utterance = AVSpeechUtterance(string: text)
//        utterance.rate = Float(ttsRate) // Use Float for rate
//        utterance.voice = AVSpeechSynthesisVoice(identifier: ttsVoiceID)
//        ?? AVSpeechSynthesisVoice(language: "vi-VN") // Fallback to default Vietnamese
//        ?? AVSpeechSynthesisVoice.speechVoices().first // Absolute fallback
//        
//        if utterance.voice == nil {
//            print("Warning: No suitable TTS voice found for identifier '\(ttsVoiceID)' or language 'vi-VN'. Using system default.")
//        }
//        
//        print("Attempting to speak: \(text.prefix(50))... using voice: \(utterance.voice?.name ?? "Unknown")")
//        ttsSynth.speak(utterance)
//    }
//    
//    // MARK: - Helper to stop TTS cleanly
//    func stopSpeaking() {
//        if ttsSynth.isSpeaking {
//            ttsSynth.stopSpeaking(at: .word) // Use .word for smoother interruption usually
//            print("Stopped speaking.")
//            // Delegate will handle audio session deactivation
//        }
//    }
//    
//    // MARK: - History Management
//    func deleteConversation(id: UUID) {
//        conversations.removeAll { $0.id == id }
//        if current.id == id {
//            resetChat() // Reset if the current one was deleted
//        }
//        print("Deleted conversation: \(id). Remaining: \(conversations.count)")
//        // saveToDisk handled by didSet
//    }
//    
//    func selectConversation(_ conversation: Conversation) {
//        stopSpeaking() // Stop TTS when switching
//        // Ensure system prompt consistency if needed (using the pattern from init)
//        var selectedConvo = conversation
//        if selectedConvo.messages.first?.role != .system {
//            selectedConvo.messages.insert(.system(self.systemPrompt), at: 0)
//        } else if selectedConvo.messages.first?.content != self.systemPrompt {
//            // Decide update policy here (e.g., update the system message in the loaded convo)
//            // selectedConvo.messages[0] = .system(self.systemPrompt)
//        }
//        self.current = selectedConvo
//        print("Selected conversation: \(current.id) - \(current.title)")
//    }
//    
//    func renameConversation(_ conversation: Conversation, to newTitle: String) {
//        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmedTitle.isEmpty, let index = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
//        conversations[index].title = trimmedTitle
//        if current.id == conversation.id {
//            current.title = trimmedTitle
//        }
//        print("Renamed conversation \(conversation.id) to: \(trimmedTitle)")
//        // saveToDisk handled by didSet
//    }
//    
//    func clearHistory() {
//        stopSpeaking() // Stop any TTS
//        conversations.removeAll()
//        resetChat() // Reset to a new empty chat state
//        print("Cleared all conversation history.")
//        // saveToDisk will be triggered by conversations.removeAll() via didSet
//    }
//    
//    // MARK: - Voice Command Handling
//    func handleVoiceCommand(_ command: String) {
//        let lowercasedCommand = command.lowercased().trimmingCharacters(in: .whitespaces)
//        guard !lowercasedCommand.isEmpty else { return }
//        print("Handling voice command: '\(lowercasedCommand)'")
//        
//        // Map commands to specific actions
//        let commandActions: [String: () -> Void] = [
//            "chat mới": { self.resetChat() },
//            "new chat": { self.resetChat() },
//            "bật đọc": { self.ttsEnabled = true },
//            "tts on": { self.ttsEnabled = true },
//            "tắt đọc": { self.ttsEnabled = false },
//            "tts off": { self.ttsEnabled = false },
//            "dùng mock": { self.backendType = .mock },
//            "use mock": { self.backendType = .mock },
//            "dùng open ai": { self.attemptSetBackend(.openAI) },
//            "dùng real": { self.attemptSetBackend(.openAI) },
//            "use real": { self.attemptSetBackend(.openAI) },
//            "dùng coreml": { self.attemptSetBackend(.coreML) },
//            "dùng local": { self.attemptSetBackend(.coreML) },
//            "use coreml": { self.attemptSetBackend(.coreML) },
//            "use local": { self.attemptSetBackend(.coreML) }
//        ]
//        
//        // Execute command if found, otherwise send as message
//        if let action = commandActions[lowercasedCommand] {
//            action()
//        } else {
//            print("Voice command not recognized, sending as message.")
//            sendMessage(command) // Send the original casing
//        }
//    }
//    
//    // Helper for voice command backend switching with checks
//    private func attemptSetBackend(_ type: BackendType) {
//        switch type {
//        case .openAI:
//            if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                print("Voice command failed: Cannot switch to OpenAI, API key missing.")
//                errorMessage = "Thiếu API key để dùng OpenAI."
//            } else {
//                backendType = .openAI
//            }
//        case .coreML:
//            let tempBackend = CoreMLChatBackend(modelName: coreMLModelName)
//            if tempBackend.coreModel == nil {
//                print("Voice command failed: Cannot switch to CoreML, model '\(coreMLModelName)' failed.")
//                errorMessage = "Không thể tải mô hình CoreML '\(coreMLModelName)'."
//            } else {
//                backendType = .coreML
//            }
//        case .mock:
//            backendType = .mock // Should always succeed
//        }
//    }
//    
//    // MARK: - Persistence
//    private func loadFromDisk() {
//        guard let data = UserDefaults.standard.data(forKey: "ChatHistory_v2") else {
//            print("No chat history found in UserDefaults.")
//            // Ensure conversations is empty if nothing is loaded
//            self.conversations = []
//            return
//        }
//        do {
//            let decoder = JSONDecoder()
//            let loadedConversations = try decoder.decode([Conversation].self, from: data)
//            self.conversations = loadedConversations // Update the main array
//            print("Loaded \(loadedConversations.count) conversations from UserDefaults.")
//        } catch {
//            print("Failed to decode chat history: \(error). Clearing corrupted data.")
//            // Clear potentially corrupted data
//            self.conversations = []
//            UserDefaults.standard.removeObject(forKey: "ChatHistory_v2")
//            DispatchQueue.main.async {
//                self.errorMessage = "Lịch sử chat bị lỗi và đã được xóa."
//            }
//        }
//    }
//    
//    private func saveToDisk() {
//        guard !conversations.isEmpty else {
//            // If conversations array is empty, remove the key
//            if UserDefaults.standard.object(forKey: "ChatHistory_v2") != nil {
//                UserDefaults.standard.removeObject(forKey: "ChatHistory_v2")
//                print("Removed chat history key from UserDefaults.")
//            }
//            return
//        }
//        do {
//            let encoder = JSONEncoder()
//            // encoder.outputFormatting = .prettyPrinted // Optional: for debugging
//            let data = try encoder.encode(conversations)
//            UserDefaults.standard.set(data, forKey: "ChatHistory_v2")
//            print("Saved \(conversations.count) conversations to UserDefaults.")
//        } catch {
//            print("Failed to encode chat history: \(error)")
//            DispatchQueue.main.async {
//                self.errorMessage = "Không thể lưu lịch sử chat."
//            }
//        }
//    }
//    
//    private func upsertConversation() {
//        guard current.messages.contains(where: { $0.role == .user }) else {
//            // Don't save if there's no user message yet (e.g., just system prompt)
//            return
//        }
//        
//        // Auto-update title if it's still a placeholder or empty
//        let generatedTitle = String(current.messages.first(where: { $0.role == .user })?.content.prefix(32) ?? "Chat")
//        if current.title.isEmpty || current.title == "Loading..." || current.title == "New Chat" {
//            current.title = generatedTitle
//        }
//        
//        if let index = conversations.firstIndex(where: { $0.id == current.id }) {
//            // Update existing
//            print("Upserting: Updating conversation ID \(current.id) at index \(index)")
//            conversations[index] = current
//        } else {
//            // Insert new at the beginning
//            print("Upserting: Inserting new conversation ID \(current.id) with title '\(current.title)'")
//            conversations.insert(current, at: 0)
//        }
//        // saveToDisk() handled by didSet observer on `conversations`
//    }
//} // End ChatStore
//// MARK: - 4.1 TTS Delegate (for Audio Session Management)
//
//// VUI: Manage audio session for TTS playback clarity
//class TTSSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
//    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
//        do {
//            // Activate audio session when speech starts
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
//            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
//            print("Audio session activated for TTS.")
//        } catch {
//            print("Error activating audio session for TTS: \(error)")
//        }
//    }
//    
//    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
//        deactivateAudioSession()
//    }
//    
//    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
//        deactivateAudioSession()
//    }
//    
//    private func deactivateAudioSession() {
//        // Deactivate audio session when speech finishes or is cancelled
//        // Use a slight delay to prevent abrupt cutoff or issues if speech restarts quickly
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            do {
//                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
//                print("Audio session deactivated after TTS.")
//            } catch {
//                print("Error deactivating audio session after TTS: \(error)")
//            }
//        }
//    }
//}
//
//// MARK: — 5. UI Subviews
//
//// Displays a single message bubble
//struct MessageBubble: View {
//    let message: Message
//    let onRespeak: (String) -> Void // Callback to trigger TTS for this message
//    
//    var isUser: Bool { message.role == .user }
//    
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 8) {
//            // VUI: Clear visual distinction between user and assistant
//            if isUser { Spacer(minLength: 40) } // Indent user messages
//            
//            if message.role == .assistant {
//                Image(systemName: "sparkles") // Simple assistant icon
//                    .font(.caption)
//                    .foregroundColor(.purple)
//                    .padding(.bottom, 5) // Align roughly with text baseline
//            }
//            
//            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
//                // Content bubble
//                Text(message.content)
//                    .textSelection(.enabled) // Allow copying text
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 8)
//                    .background(isUser ? Color.blue.opacity(0.9) : Color.gray.opacity(0.2))
//                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//                    .foregroundColor(isUser ? .white : .primary) // Ensure readability
//                    .frame(minWidth: 20) // Prevent tiny bubbles
//                
//                // Timestamp - subtle, below the bubble
//                Text(message.timestamp, style: .time)
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//                
//            } // End VStack
//            
//            if message.role == .user {
//                Image(systemName: "person.crop.circle") // Simple user icon
//                    .font(.caption)
//                    .foregroundColor(.blue)
//                    .padding(.bottom, 5)
//            }
//            
//            if !isUser { Spacer(minLength: 40) } // Indent assistant messages
//            
//        }
//        .contextMenu {
//            // VUI: Useful actions on messages
//            Button { UIPasteboard.general.string = message.content } label: {
//                Label("Copy Text", systemImage: "doc.on.doc")
//            }
//            if message.role == .assistant {
//                Button { onRespeak(message.content) } label: {
//                    Label("Đọc Lại", systemImage: "speaker.wave.2.fill")
//                }
//            }
//            ShareLink(item: message.content) {
//                Label("Chia sẻ Tin nhắn", systemImage: "square.and.arrow.up")
//            }
//        }
//    }
//}
//
//// The bar at the bottom for text and voice input
//struct ChatInputBar: View {
//    @Binding var text: String
//    @ObservedObject var store: ChatStore // To send messages
//    @ObservedObject var speech: SpeechRecognizer // To handle voice input
//    @FocusState var isTextFieldFocused: Bool // To manage keyboard focus
//    
//    @GestureState private var isMicPressed: Bool = false // Track a long press on the mic
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Display speech recognizer transcript or error when active
//            if speech.isRecording || speech.errorMessage != nil {
//                HStack {
//                    Text(speech.errorMessage ?? speech.transcript)
//                        .font(.caption)
//                        .foregroundColor(speech.errorMessage != nil ? .red : .secondary)
//                        .lineLimit(1)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(.horizontal)
//                        .padding(.bottom, 4)
//                    if speech.isRecording {
//                        ProgressView().scaleEffect(0.8)
//                    }
//                }.transition(.opacity.combined(with: .move(edge: .bottom)))
//            }
//            
//            // Main input row
//            HStack(alignment: .bottom, spacing: 8) {
//                // Text Field
//                TextField("Nhập tin nhắn hoặc giữ micro để nói...", text: $text, axis: .vertical)
//                    .focused($isTextFieldFocused)
//                    .lineLimit(1...5) // Allow multi-line input
//                    .padding(.vertical, 8)
//                    .padding(.horizontal, 12)
//                    .background(Color(.secondarySystemBackground))
//                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 20, style: .continuous)
//                            .stroke(isTextFieldFocused ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
//                    )
//                    .onSubmit { // Send on return key press
//                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                            store.sendMessage(text)
//                        }
//                    }
//                    .disabled(store.isLoading) // Disable when processing
//                
//                // Microphone Button
//                micButton
//                
//                // Send Button (only shown if mic isn't pressed and text field has content)
//                if !isMicPressed && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                    sendButton
//                }
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 8)
//            .background(.thinMaterial) // Subtle background separation
//            .animation(.easeInOut(duration: 0.2), value: isMicPressed) // Animate mic/send visibility
//            .animation(.easeInOut, value: speech.isRecording) // Animate transcript visibility
//        }
//    }
//    
//    // Microphone Button View
//    private var micButton: some View {
//        // VUI: Long press gesture for voice input
//        let longPress = LongPressGesture(minimumDuration: 0.25)
//            .updating($isMicPressed) { currentState, gestureState, _ in
//                gestureState = currentState // Update gesture state while pressing
//                // Start recording only when the press begins effectively
//                if currentState && !speech.isRecording {
//                    // Haptic feedback for press start
//                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//                    // Request auth and start recording
//                    speech.requestAuthorization { authorized in
//                        if authorized {
//                            DispatchQueue.main.async { // Ensure UI updates are on main thread
//                                try? speech.startRecording()
//                            }
//                        }
//                    }
//                    isTextFieldFocused = false // Dismiss keyboard
//                }
//            }
//            .onEnded { _ in
//                // VUI: Trigger finalization when mic is released
//                if speech.isRecording {
//                    // Haptic feedback for press end
//                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                    speech.finishTranscription() // Use the dedicated method to stop and process
//                }
//            }
//        
//        return Image(systemName: speech.isRecording ? "mic.fill" : "mic.circle")
//            .resizable()
//            .scaledToFit()
//            .frame(width: 28, height: 28)
//            .foregroundColor(isMicPressed || speech.isRecording ? .red : .blue) // VUI: Clear visual feedback for recording state
//            .padding(5)
//            .contentShape(Rectangle()) // Increase hit area
//            .gesture(longPress)
//            .disabled(store.isLoading) // Disable mic during backend processing
//            .accessibilityLabel(speech.isRecording ? "Đang ghi âm, thả để gửi" : "Giữ để nói")
//    }
//    
//    // Send Button View
//    private var sendButton: some View {
//        Button {
//            store.sendMessage(text)
//        } label: {
//            Image(systemName: "arrow.up.circle.fill")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 28, height: 28)
//                .foregroundColor(
//                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading
//                    ? .gray.opacity(0.5) : .blue // VUI: Indicate disabled state
//                )
//        }
//        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading)
//        .transition(.opacity.combined(with: .scale)) // Animate send button appearance
//        .accessibilityLabel("Gửi tin nhắn")
//    }
//}
//
//// Settings View Presented as a Sheet
//struct SettingsSheet: View {
//    // Use @ObservedObject for the store to react to its changes
//    @ObservedObject var store: ChatStore
//    
//    // Local state for temporary edits before applying
//    @State private var localApiKey: String
//    @State private var localOpenAIModelName: String
//    @State private var localOpenAITemperature: Double
//    @State private var localOpenAIMaxTokens: Int
//    @State private var localBackendType: BackendType
//    @State private var localCoreMLModelName: String
//    @State private var localSystemPrompt: String
//    @State private var localTtsEnabled: Bool
//    @State private var localTtsRate: Float
//    @State private var localTtsVoiceID: String
//    
//    @Environment(\.dismiss) var dismiss
//    
//    // Closure to apply changes back to the ChatStore
//    var onUpdate: (ChatBackend, BackendType) -> Void
//    
//    init(store: ChatStore, onUpdate: @escaping (ChatBackend, BackendType) -> Void) {
//        self.store = store
//        self.onUpdate = onUpdate
//        // Initialize local state from the store's current values
//        _localApiKey = State(initialValue: store.apiKey)
//        _localOpenAIModelName = State(initialValue: store.openAIModelName)
//        _localOpenAITemperature = State(initialValue: store.openAITemperature)
//        _localOpenAIMaxTokens = State(initialValue: store.openAIMaxTokens)
//        _localBackendType = State(initialValue: store.backendType)
//        _localCoreMLModelName = State(initialValue: store.coreMLModelName)
//        _localSystemPrompt = State(initialValue: store.systemPrompt)
//        _localTtsEnabled = State(initialValue: store.ttsEnabled)
//        _localTtsRate = State(initialValue: Float(store.ttsRate))
//        _localTtsVoiceID = State(initialValue: store.ttsVoiceID)
//    }
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                // MARK: Backend Selection
//                Section("Backend Engine") {
//                    Picker("Chọn Backend", selection: $localBackendType) {
//                        ForEach(BackendType.allCases) { type in
//                            Text(type.rawValue).tag(type)
//                        }
//                    }
//                    .pickerStyle(.menu) // Or .inline / .segmented
//                    
//                    // CoreML Model Selection (Conditional)
//                    if localBackendType == .coreML {
//                        Picker("Chọn CoreML Model", selection: $localCoreMLModelName) {
//                            ForEach(store.availableCoreMLModels, id: \.self) { model in
//                                Text(model).tag(model)
//                            }
//                        }
//                    }
//                    
//                    // VUI: Provide context about the current backend
//                    Text("Backend hiện tại: \(store.backendType.rawValue)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                
//                // MARK: OpenAI Configuration (Conditional)
//                if localBackendType == .openAI {
//                    Section("Cấu hình OpenAI") {
//                        Picker("Model", selection: $localOpenAIModelName) {
//                            ForEach(store.availableOpenAIModels, id: \.self) { Text($0) }
//                        }
//                        
//                        HStack {
//                            Text("Nhiệt độ (Sáng tạo):")
//                            Slider(value: $localOpenAITemperature, in: 0...1, step: 0.05)
//                            Text("\(localOpenAITemperature, specifier: "%.2f")")
//                                .frame(width: 40)
//                        }
//                        
//                        Stepper("Tokens Tối đa: \(localOpenAIMaxTokens)",
//                                value: $localOpenAIMaxTokens, in: 64...4096, step: 64)
//                        
//                        SecureField("API Key (openai.com)", text: $localApiKey)
//                            .textContentType(.password) // Hint for Keychain etc.
//                            .autocapitalization(.none)
//                            .disableAutocorrection(true)
//                        
//                        if localApiKey.isEmpty {
//                            // VUI: Clear instructions/warnings
//                            Text("Cần có API key để sử dụng backend OpenAI.")
//                                .font(.footnote).foregroundColor(.orange)
//                        }
//                    }
//                }
//                
//                // MARK: General Settings
//                Section("Cài đặt Chung") {
//                    VStack(alignment: .leading) {
//                        Text("System Prompt (Personality)")
//                        TextEditor(text: $localSystemPrompt)
//                            .frame(height: 100)
//                            .font(.body)
//                            .border(Color.gray.opacity(0.3), width: 1)
//                            .clipShape(RoundedRectangle(cornerRadius: 6))
//                    }
//                }
//                
//                // MARK: Text-to-Speech Settings
//                Section("Đọc Phản Hồi (TTS)") {
//                    Toggle("Bật Đọc Phản Hồi", isOn: $localTtsEnabled)
//                    
//                    if localTtsEnabled {
//                        Picker("Giọng Đọc", selection: $localTtsVoiceID) {
//                            ForEach(store.availableVoices, id: \.identifier) { voice in
//                                Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
//                            }
//                        }
//                        
//                        HStack {
//                            Text("Tốc độ đọc:")
//                            Slider(value: $localTtsRate, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate)
//                            Text("\(localTtsRate, specifier: "%.2f")")
//                                .frame(width: 40)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Cài đặt Chat")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Hủy") { dismiss() }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Lưu") {
//                        applyChanges()
//                        dismiss()
//                    }
//                    // VUI: Disable save if OpenAI key is needed but missing
//                    .disabled(localBackendType == .openAI && localApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//                }
//            }
//        }
//    }
//    
//    // Apply the local changes back to the store
//    private func applyChanges() {
//        // 1. Update non-backend settings directly
//        // These don't require backend reconfiguration on their own.
//        store.systemPrompt = localSystemPrompt
//        store.ttsEnabled = localTtsEnabled
//        store.ttsRate = Double(localTtsRate) // Convert Float to Double
//        store.ttsVoiceID = localTtsVoiceID
//        
//        // 2. Determine if *any* backend-related setting has changed
//        let backendSettingsChanged = (
//            store.apiKey != localApiKey ||
//            store.openAIModelName != localOpenAIModelName ||
//            store.openAITemperature != localOpenAITemperature ||
//            store.openAIMaxTokens != localOpenAIMaxTokens ||
//            store.coreMLModelName != localCoreMLModelName ||
//            store.backendType != localBackendType // Include the type itself
//        )
//        
//        // 3. If any relevant setting changed, update *all* backend settings in the store
//        //    and ensure the backendType setter is called to trigger reconfiguration.
//        if backendSettingsChanged {
//            print("Backend-related settings changed. Applying updates and triggering reconfiguration...")
//            
//            // Update the store's @AppStorage values
//            store.apiKey = localApiKey
//            store.openAIModelName = localOpenAIModelName
//            store.openAITemperature = localOpenAITemperature
//            store.openAIMaxTokens = localOpenAIMaxTokens
//            store.coreMLModelName = localCoreMLModelName
//            
//            // IMPORTANT: Assign backendType *last*. Even if the type itself didn't change,
//            // assigning the same value triggers its `set` block, which calls `configureBackend()`.
//            // This ensures the backend instance is recreated with the latest settings (like new API key or model name).
//            store.backendType = localBackendType
//            
//        } else {
//            print("No backend-related settings changed.")
//        }
//        
//        print("Settings applyChanges finished. Store backend type is now: \(store.backendType.rawValue)")
//    }
//}
//
//// History View Presented as a Sheet
//struct HistorySheet: View {
//    @Binding var conversations: [Conversation] // Use binding to allow deletion/updates
//    let onDelete: (UUID) -> Void
//    let onSelect: (Conversation) -> Void
//    let onRename: (Conversation, String) -> Void
//    let onClear: () -> Void
//    
//    @Environment(\.dismiss) var dismiss
//    @State private var showingRenameAlert = false
//    @State private var conversationToRename: Conversation? = nil
//    @State private var newConversationTitle: String = ""
//    @State private var showingClearConfirm = false
//    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                if conversations.isEmpty {
//                    // VUI: Clear empty state message
//                    ContentUnavailableView(
//                        "Không có lịch sử chat",
//                        systemImage: "bubble.middle.bottom.fill",
//                        description: Text("Các đoạn chat đã lưu sẽ xuất hiện ở đây.")
//                    )
//                    .padding(.vertical, 50) // Add some spacing
//                } else {
//                    List {
//                        ForEach(conversations) { convo in
//                            historyRow(for: convo)
//                                .contentShape(Rectangle()) // Make entire row tappable
//                                .onTapGesture {
//                                    onSelect(convo)
//                                    dismiss()
//                                }
//                        }
//                        .onDelete(perform: deleteItems)
//                    }
//                    .listStyle(.plain) // Use plain style for better appearance in sheet
//                }
//                
//                // Clear History Button (conditionally shown)
//                if !conversations.isEmpty {
//                    Button("Xóa Tất Cả Lịch Sử", role: .destructive) {
//                        showingClearConfirm = true // Show confirmation first
//                    }
//                    .padding(.vertical)
//                }
//            }
//            .navigationTitle("Lịch sử Chat")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) { EditButton() }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Xong") { dismiss() }
//                }
//            }
//            .alert("Đổi tên Đoạn Chat", isPresented: $showingRenameAlert, presenting: conversationToRename) { convo in
//                TextField("Tên mới", text: $newConversationTitle)
//                    .autocapitalization(.sentences)
//                Button("OK") {
//                    if let c = conversationToRename, !newConversationTitle.trimmingCharacters(in: .whitespaces).isEmpty {
//                        onRename(c, newConversationTitle)
//                    }
//                }
//                Button("Hủy", role: .cancel) {}
//            } message: { convo in
//                Text("Nhập tên mới cho \"\(convo.title)\"")
//            }
//            .alert("Xác nhận Xóa?", isPresented: $showingClearConfirm) {
//                Button("Xóa Tất Cả", role: .destructive) {
//                    onClear()
//                    dismiss()
//                }
//                Button("Hủy", role: .cancel) {}
//            } message: {
//                Text("Bạn có chắc muốn xóa toàn bộ lịch sử chat? Hành động này không thể hoàn tác.")
//            }
//        }
//        .presentationDetents([.medium, .large]) // Allow resizing the sheet
//    }
//    
//    // Creates a single row in the history list
//    private func historyRow(for conversation: Conversation) -> some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text(conversation.title)
//                    .font(.headline)
//                    .lineLimit(1)
//                // Show date and message count for context
//                Text("\(conversation.messages.filter{$0.role != .system}.count) tin nhắn - \(conversation.createdAt, style: .date)")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            Spacer()
//            // Menu for additional actions
//            Menu {
//                Button {
//                    conversationToRename = conversation
//                    newConversationTitle = conversation.title // Pre-fill
//                    showingRenameAlert = true
//                } label: {
//                    Label("Đổi tên", systemImage:"pencil")
//                }
//                
//                ShareLink(item: formatConversationForSharing(conversation)) {
//                    Label("Chia sẻ", systemImage: "square.and.arrow.up")
//                }
//                
//                Button(role: .destructive) {
//                    onDelete(conversation.id)
//                } label: {
//                    Label("Xóa", systemImage: "trash")
//                }
//            } label: {
//                Image(systemName: "ellipsis.circle")
//                    .foregroundColor(.secondary)
//                    .padding(.leading, 5) // Add padding to make it easier to tap
//            }
//            .buttonStyle(.borderless) // Make menu button less intrusive
//        }
//    }
//    
//    // Handles deletion from the List's onDelete modifier
//    private func deleteItems(at offsets: IndexSet) {
//        offsets.map { conversations[$0].id }.forEach(onDelete)
//    }
//    
//    // Formats a conversation into a shareable text string
//    private func formatConversationForSharing(_ conversation: Conversation) -> String {
//        var shareText = "Chat: \(conversation.title)\nNgày: \(conversation.createdAt.formatted(date: .long, time: .shortened))\n\n"
//        for message in conversation.messages where message.role != .system {
//            let prefix = message.role == .user ? "You:" : "AI:"
//            shareText += "\(prefix) \(message.content)\n\n"
//        }
//        return shareText.trimmingCharacters(in: .whitespacesAndNewlines)
//    }
//}
//
//// MARK: — 6. Main View
//
//struct ChatDemoView: View {
//    // State Objects: Own the lifecycle of these crucial objects
//    @StateObject var store = ChatStore()
//    @StateObject var speech = SpeechRecognizer()
//    
//    // Focus state for the input text field
//    @FocusState var isInputFocused: Bool
//    
//    // State for presenting modal sheets
//    @State private var showSettingsSheet = false
//    @State private var showHistorySheet = false
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                // Custom Header
//                chatHeader
//                
//                // Messages Area
//                messagesScrollView
//                
//                // Input Bar (Text + Voice)
//                ChatInputBar(
//                    text: $store.input,
//                    store: store,
//                    speech: speech,
//                    isTextFieldFocused: _isInputFocused // Pass the focus state binding
//                )
//            }
//            // VUI: Hide default navigation bar for custom header
//            .navigationBarHidden(true)
//            // VUI: Present settings modally
//            .sheet(isPresented: $showSettingsSheet) {
//                SettingsSheet(store: store) { backend, type in
//                    // This closure applies changes made in SettingsSheet
//                    // The SettingsSheet now handles applying changes internally
//                    // We might still need to trigger backend update if needed,
//                    // but the store's AppStorage should handle it.
//                    print("Settings sheet dismissed. Backend might be reconfiguring.")
//                }
//            }
//            // VUI: Present history modally
//            .sheet(isPresented: $showHistorySheet) {
//                HistorySheet(
//                    conversations: $store.conversations,
//                    onDelete: store.deleteConversation(id:),
//                    onSelect: { conversation in
//                        store.selectConversation(conversation)
//                        showHistorySheet = false // Dismiss after selection
//                    },
//                    onRename: store.renameConversation(_:to:),
//                    onClear: store.clearHistory // Pass the clear function
//                )
//            }
//            // VUI: Display errors using alerts
//            .alert("Lỗi", isPresented: .constant(store.errorMessage != nil), actions: {
//                Button("OK") { store.errorMessage = nil } // Action to dismiss the alert
//            }, message: {
//                Text(store.errorMessage ?? "Đã xảy ra lỗi không xác định.") // Fallback message
//            })
//            .onAppear {
//                // VUI: Request speech recognition authorization on appear
//                speech.requestAuthorization { _ in /* Optional: Handle result */ }
//                // Link speech recognizer results to the store's command handler
//                speech.onFinalTranscription = { [weak store] transcript in
//                    store?.handleVoiceCommand(transcript)
//                }
//            }
//            // Dismiss keyboard when tapping outside the input bar
//            .onTapGesture {
//                isInputFocused = false
//            }
//        }
//        // VUI: Adapt to light/dark mode automatically
//        .preferredColorScheme(nil)
//    }
//    
//    // Custom Header View Component
//    private var chatHeader: some View {
//        HStack(spacing: 10) {
//            // Display current conversation title
//            Text(store.current.title)
//                .font(.headline)
//                .lineLimit(1)
//                .frame(maxWidth: .infinity, alignment: .leading) // Allow title to take space
//            
//            Spacer() // Push buttons to the right
//            
//            // VUI: Indicator for Text-to-Speech status
//            if store.ttsEnabled {
//                Image(systemName: "speaker.wave.2.fill")
//                    .foregroundColor(.blue) // Use accent color for active state
//                    .imageScale(.medium)
//                    .transition(.scale.combined(with: .opacity)) // Animate appearance
//                    .accessibilityLabel("Đọc phản hồi đang bật")
//            } else {
//                Image(systemName: "speaker.slash.fill")
//                    .foregroundColor(.gray)
//                    .imageScale(.medium)
//                    .transition(.scale.combined(with: .opacity))
//                    .accessibilityLabel("Đọc phản hồi đang tắt")
//            }
//            
//            // Button to open History Sheet
//            Button { showHistorySheet = true } label: {
//                Label("Lịch sử", systemImage: "clock.arrow.circlepath")
//            }
//            .labelStyle(.iconOnly) // Show only the icon
//            
//            // Button to open Settings Sheet
//            Button { showSettingsSheet = true } label: {
//                Label("Cài đặt", systemImage: "gearshape.fill") // Use filled icon for clarity
//            }
//            .labelStyle(.iconOnly)
//            
//            // Button to start a new chat
//            Button { store.resetChat() } label: {
//                Label("Chat Mới", systemImage: "plus.circle.fill")
//            }
//            .labelStyle(.iconOnly)
//            
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 10)
//        .background(.thinMaterial) // Subtle background for separation
//        .animation(.default, value: store.ttsEnabled) // Animate TTS icon change
//    }
//    
//    // Scrollable View for Messages
//    private var messagesScrollView: some View {
//        ScrollViewReader { proxy in // Allows programmatic scrolling
//            ScrollView {
//                LazyVStack(spacing: 16) { // Add more spacing between bubbles
//                    // Iterate through messages, excluding the system prompt
//                    ForEach(store.current.messages.filter { $0.role != .system }) { message in
//                        MessageBubble(message: message, onRespeak: store.speak) // Pass respeak closure
//                            .id(message.id) // Assign ID for scrolling
//                            .padding(.horizontal, 8) // Add horizontal padding
//                    }
//                    // VUI: Show loading indicator while waiting for response
//                    if store.isLoading {
//                        HStack(spacing: 8) {
//                            ProgressView()
//                                .tint(.secondary) // Use less prominent color
//                            Text("AI đang suy nghĩ...")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.vertical)
//                        .transition(.opacity) // Animate appearance
//                    }
//                }
//                .padding(.vertical) // Padding inside the scroll view
//            }
//            .background(Color(.systemGroupedBackground)) // Use system background color
//            // VUI: Automatically scroll to new messages
//            .onChange(of: store.current.messages.last?.id) { _, newId in
//                if let id = newId {
//                    // Scroll with animation when a new message arrives
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Slight delay allows layout
//                        withAnimation(.spring(duration: 0.4)) {
//                            proxy.scrollTo(id, anchor: .bottom)
//                        }
//                    }
//                }
//            }
//            // Scroll to bottom initially if needed (might conflict with loading history)
//            // .onAppear {
//            //     if let lastId = store.current.messages.last?.id {
//            //         proxy.scrollTo(lastId, anchor: .bottom)
//            //     }
//            // }
//        }
//    }
//}
//
//// MARK: — 7. Helper Extensions
//
//// Helper to find the topmost view controller for presenting alerts/share sheets
//extension UIApplication {
//    static var topViewController: UIViewController? {
//        // Get the active scene
//        let scenes = UIApplication.shared.connectedScenes
//        let windowScene = scenes.first as? UIWindowScene
//        let window = windowScene?.windows.first { $0.isKeyWindow }
//        
//        // Find the root view controller
//        var topController = window?.rootViewController
//        
//        // Traverse presented view controllers
//        while let presentedViewController = topController?.presentedViewController {
//            topController = presentedViewController
//        }
//        return topController
//    }
//}
//
//// Helper to easily present the standard iOS Share Sheet
//extension UIActivityViewController {
//    static func present(text: String) {
//        guard let topVC = UIApplication.topViewController else {
//            print("Error: Could not find top view controller to present share sheet.")
//            return
//        }
//        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
//        
//        // Handle iPad presentation
//        if let popoverController = activityViewController.popoverPresentationController {
//            popoverController.sourceView = topVC.view // Anchor to the view
//            // Center the popover:
//            popoverController.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
//            popoverController.permittedArrowDirections = [] // No arrow for centered sheet
//        }
//        
//        topVC.present(activityViewController, animated: true, completion: nil)
//    }
//}
//
//// MARK: — 8. Preview Provider
//
//#Preview {
//    ChatDemoView()
//    // Example environment overrides for preview if needed:
//        .environmentObject(ChatStore()) // Provide a specific store configuration for preview
//        .preferredColorScheme(.dark) // Preview in dark mode
//}
