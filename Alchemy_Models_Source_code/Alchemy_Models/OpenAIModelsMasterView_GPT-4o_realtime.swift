////
////  OpenAIModelsMasterView_GPT-4o_realtime.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIModelsMasterView.swift
////  Alchemy_Models_Combined
////  (Single File Implementation)
////
////  Created: Cong Le
////  Date: 4/13/25 (Updated 4/20/25 for GPT-4o Realtime details)
////  Version: 1.2 (Integrated GPT-4o Realtime Specs)
////  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
////  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
////
//
//import SwiftUI
//import Foundation // Needed for URLSession, URLRequest, etc.
//import Combine // Needed for @StateObject if using ObservableObject later
//
//// MARK: - Enums (Sorting, Errors)
//
//enum SortOption: String, CaseIterable, Identifiable {
//    case idAscending = "ID (A-Z)"
//    case idDescending = "ID (Z-A)"
//    case dateNewest = "Date (Newest)"
//    case dateOldest = "Date (Oldest)"
//    var id: String { self.rawValue }
//}
//
//enum MockError: Error, LocalizedError {
//    case simulatedFetchError
//    var errorDescription: String? {
//        switch self {
//        case .simulatedFetchError: return "Simulated network error: Could not fetch models."
//        }
//    }
//}
//
//enum LiveAPIError: Error, LocalizedError {
//    case invalidURL
//    case requestFailed(statusCode: Int)
//    case networkError(Error)
//    case decodingError(Error)
//    case missingAPIKey
//    var errorDescription: String? {
//        switch self {
//        case .invalidURL: return "The API endpoint URL is invalid."
//        case .requestFailed(let sc): return "API request failed with status code \(sc)."
//        case .networkError(let err): return "Network error: \(err.localizedDescription)"
//        case .decodingError(let err): return "Failed to decode API response: \(err.localizedDescription)"
//        case .missingAPIKey: return "OpenAI API Key is missing or invalid. Please provide a valid key."
//        }
//    }
//}
//
//// MARK: - API Service Protocol
//
//protocol APIServiceProtocol {
//    func fetchModels() async throws -> [OpenAIModel]
//}
//
//// MARK: - Data Models
//
//struct ModelListResponse: Codable {
//    let data: [OpenAIModel]
//}
//
//struct OpenAIModel: Codable, Identifiable, Hashable {
//    let id: String
//    let object: String
//    let created: Int // Unix timestamp
//    let ownedBy: String
//    
//    // --- Default values for fields that might be missing in basic /v1/models response ---
//    var description: String = "No description available."
//    var capabilities: [String] = ["general"] // Broad category, consider replacing/augmenting with modalities/features
//    var contextWindow: String = "N/A"
//    var typicalUseCases: [String] = ["Various tasks"]
//    var shortDescription: String = "General purpose model."
//    
//    // --- New properties based on detailed views / GPT-4o Realtime screenshot ---
//    var knowledgeCutoff: String? = nil // e.g., "Sep 30, 2023"
//    var maxOutputTokens: String? = nil // e.g., "4,096"
//    var modalities: [String]? = nil // e.g., ["Text Input/Output", "Audio Input/Output"]
//    var supportedEndpoints: [String]? = nil // e.g., ["v1/realtime"]
//    var supportedFeatures: [String]? = nil // e.g., ["Function calling"]
//    var pricingText: String? = nil // Text token pricing
//    var pricingAudio: String? = nil // Audio token pricing
//    
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id
//        case object
//        case created
//        case ownedBy = "owned_by"
//        // IMPORTANT: Default/Optional fields NOT listed here are ignored by JSON decoding
//        // if absent, retaining their default/nil values. If present in JSON (e.g., mock),
//        // they WILL be decoded.
//        case description // Include if potentially in JSON
//        case capabilities // Include if potentially in JSON
//        case contextWindow // Include if potentially in JSON
//        case typicalUseCases // Include if potentially in JSON
//        case shortDescription // Include if potentially in JSON
//        case knowledgeCutoff // Include if potentially in JSON
//        case maxOutputTokens // Include if potentially in JSON
//        case modalities // Include if potentially in JSON
//        case supportedEndpoints // Include if potentially in JSON
//        case supportedFeatures // Include if potentially in JSON
//        case pricingText // Include if potentially in JSON
//        case pricingAudio // Include if potentially in JSON
//    }
//    
//    // --- Initializer allowing default overrides (useful for mocks) ---
//    init(id: String, object: String = "model", created: Int, ownedBy: String,
//         description: String = "No description available.",
//         capabilities: [String] = ["general"],
//         contextWindow: String = "N/A",
//         typicalUseCases: [String] = ["Various tasks"],
//         shortDescription: String = "General purpose model.",
//         knowledgeCutoff: String? = nil,
//         maxOutputTokens: String? = nil,
//         modalities: [String]? = nil,
//         supportedEndpoints: [String]? = nil,
//         supportedFeatures: [String]? = nil,
//         pricingText: String? = nil,
//         pricingAudio: String? = nil) {
//        self.id = id
//        self.object = object
//        self.created = created
//        self.ownedBy = ownedBy
//        self.description = description
//        self.capabilities = capabilities // May be redundant if using modalities/features
//        self.contextWindow = contextWindow
//        self.typicalUseCases = typicalUseCases
//        self.shortDescription = shortDescription
//        self.knowledgeCutoff = knowledgeCutoff
//        self.maxOutputTokens = maxOutputTokens
//        self.modalities = modalities
//        self.supportedEndpoints = supportedEndpoints
//        self.supportedFeatures = supportedFeatures
//        self.pricingText = pricingText
//        self.pricingAudio = pricingAudio
//    }
//    
//    // --- Computed Properties & Hashable ---
//    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
//    func hash(into hasher: inout Hasher) { hasher.combine(id) }
//    static func == (lhs: OpenAIModel, rhs: OpenAIModel) -> Bool { lhs.id == rhs.id }
//}
//
//// MARK: - Model Extension for UI Logic
//
//extension OpenAIModel {
//    // --- Determine SF Symbol name based on ID or owner ---
//    var iconName: String {
//        let normalizedId = id.lowercased()
//        // Map specific IDs from screenshots to SF Symbols (or placeholders)
//        if normalizedId.contains("gpt-4o-realtime") { return "bolt.badge.clock.fill" } // Specific icon for realtime
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") || normalizedId.contains("chatgpt-4o") { return "sparkles" }
//        if normalizedId.contains("o4-mini") || normalizedId.contains("o3-mini") || normalizedId.contains("o1-mini") || normalizedId.contains("gpt-4.1-mini") { return "leaf.fill" }
//        if normalizedId.contains("o3") { return "circle.hexagonpath.fill" } // Placeholder
//        if normalizedId.contains("o1") || normalizedId.contains("o1-pro") { return "circles.hexagonpath.fill" } // Placeholder
//        if normalizedId.contains("gpt-4-turbo") { return "bolt.fill" }
//        if normalizedId.contains("gpt-4") && !normalizedId.contains("turbo") { return "star.fill"}
//        if normalizedId.contains("gpt-3.5") { return "forward.fill" } // Placeholder for legacy
//        if normalizedId.contains("dall-e") { return "paintbrush.pointed.fill" }
//        if normalizedId.contains("tts") { return "speaker.wave.2.fill" }
//        if normalizedId.contains("transcribe") || normalizedId.contains("whisper") { return "waveform" }
//        if normalizedId.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" } // Placeholder
//        if normalizedId.contains("moderation") { return "exclamationmark.shield.fill" }
//        if normalizedId.contains("search") { return "magnifyingglass"}
//        if normalizedId.contains("computer-use") { return "computermouse.fill" }
//        
//        // Fallback based on owner
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return "building.columns.fill" }
//        if lowerOwner == "system" { return "gearshape.fill" }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return "person.crop.circle.fill" }
//        return "questionmark.circle.fill" // Default/fallback
//    }
//    
//    // --- Determine background color for icons ---
//    var iconBackgroundColor: Color {
//        let normalizedId = id.lowercased()
//        // Map specific IDs to colors
//        if normalizedId.contains("gpt-4o-realtime") { return .cyan } // Specific color for realtime
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") { return .blue }
//        if normalizedId.contains("o4-mini") { return .purple }
//        if normalizedId.contains("o3") { return .orange }
//        if normalizedId.contains("dall-e") { return .teal }
//        if normalizedId.contains("tts") { return .indigo }
//        if normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return .pink }
//        if normalizedId.contains("embedding") { return .green }
//        if normalizedId.contains("moderation") { return .red }
//        if normalizedId.contains("search") { return .cyan.opacity(0.8) } // Slightly different cyan
//        if normalizedId.contains("computer-use") { return .brown }
//        
//        // Fallback based on owner
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return .blue.opacity(0.8) }
//        if lowerOwner == "system" { return .orange.opacity(0.8) }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return .purple.opacity(0.8) }
//        return .gray.opacity(0.7) // Default/fallback
//    }
//    
//    // --- Simplified name for display ---
//    var displayName: String {
//        // Special handling for realtime preview ID if needed
//        if id.contains("gpt-4o-realtime-preview") { return "GPT-4o Realtime Preview" }
//        return id.replacingOccurrences(of: "-", with: " ").capitalized
//    }
//    
//    // --- Helpers for Detail View ---
//    var formattedTextPricing: String? {
//        guard let pricingText = pricingText else { return nil }
//        // Example: Assume "Input: $5.00, Cached: $2.50, Output: $20.00"
//        return pricingText // Or parse and format nicely
//    }
//    var formattedAudioPricing: String? {
//        guard let pricingAudio = pricingAudio else { return nil }
//        // Example: Assume "Input: $40.00, Cached: $2.50, Output: $80.00"
//        return pricingAudio // Or parse and format nicely
//    }
//}
//
//// MARK: - API Service Implementations
//
//// --- Mock Data Service ---
//class MockAPIService: APIServiceProtocol {
//    private let mockNetworkDelaySeconds: Double = 0.8
//    
//    // Enhanced mock models based on screenshots
//    private func generateMockModels() -> [OpenAIModel] {
//        return [
//            // Featured
//            OpenAIModel(id: "gpt-4.1", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k", shortDescription: "Flagship GPT model for complex tasks", modalities: ["Text Input/Output", "Image Input"]),
//            OpenAIModel(id: "o4-mini", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Faster, more affordable reasoning model", modalities: ["Text Input/Output"]),
//            OpenAIModel(id: "o3", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "16k", shortDescription: "Our most powerful reasoning model", modalities: ["Text Input/Output"]),
//            
//            // Reasoning Models
//            OpenAIModel(id: "o3-mini", created: 1699000000, ownedBy: "openai", description: "A smaller, faster, and more affordable alternative to o3.", capabilities: ["text generation", "reasoning"], contextWindow: "16k", shortDescription: "A small model alternative to o3", modalities: ["Text Input/Output"]),
//            OpenAIModel(id: "o1", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Previous full o-series reasoning model", modalities: ["Text Input/Output"]),
//            OpenAIModel(id: "o1-pro", created: 1685000000, ownedBy: "openai", description: "Version of o1 with more compute for better responses.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Version of o1 with more compute", modalities: ["Text Input/Output"]),
//            OpenAIModel(id: "o1-mini", created: 1675000000, ownedBy: "openai", description: "A small model alternative to o1, very fast.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "A small model alternative to o1", modalities: ["Text Input/Output"]),
//            
//            // Flagship Chat Models
//            OpenAIModel(id: "gpt-4o", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "Fast, intelligent, flexible GPT model", modalities: ["Text Input/Output", "Image Input", "Audio Input"]), // Audio Output via TTS usually separate?
//            OpenAIModel(id: "gpt-4o-audio", created: 1712850000, ownedBy: "openai", description: "GPT-4o models capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "GPT-4o models capable of audio inputs", modalities: ["Audio Input", "Text Output"]), // Clarify output modality
//            OpenAIModel(id: "chatgpt-4o-latest", created: 1712900000, ownedBy: "openai", description: "GPT-4o model used in ChatGPT.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "GPT-4o model used in ChatGPT", modalities: ["Text Input/Output", "Image Input", "Audio Input"]),
//            
//            // Cost-optimized Models
//            OpenAIModel(id: "gpt-4.1-mini", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Balanced for intelligence, speed, cost", modalities: ["Text Input/Output"]),
//            OpenAIModel(id: "gpt-4.1-nano", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fastest, most cost-effective GPT-4.1", modalities: ["Text Input/Output"]),
//            OpenAIModel(id: "gpt-4o-mini", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model", modalities: ["Text Input/Output"]),
//            OpenAIModel(id: "gpt-4o-mini-audio", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "Smaller model capable of audio inputs", modalities: ["Audio Input", "Text Output"]),
//            
//            // >>> START: GPT-4o Realtime Update <<<
//            OpenAIModel(
//                id: "gpt-4o-realtime", // Using the specific preview ID might be better: "gpt-4o-realtime-preview" ?
//                created: 1712860000, // Example date
//                ownedBy: "openai",
//                description: "Preview release of the GPT-4o Realtime model, capable of responding to audio and text inputs in realtime over WebRTC or a WebSocket interface.",
//                capabilities: ["realtime", "function-calling"], // Simplified, use modalities/features
//                contextWindow: "128,000", // Use comma for readability
//                shortDescription: "Realtime text/audio model (Preview)",
//                knowledgeCutoff: "Sep 30, 2023",
//                maxOutputTokens: "4,096",
//                modalities: ["Text Input/Output", "Audio Input/Output"], // Based on screenshot
//                supportedEndpoints: ["v1/realtime"],
//                supportedFeatures: ["Function calling"],
//                pricingText: "Input $5.00, Cached $2.50, Output $20.00 (per 1M tokens)",
//                pricingAudio: "Input $40.00, Cached $2.50, Output $80.00 (per 1M tokens)"
//            ),
//            // >>> END: GPT-4o Realtime Update <<<
//            
//            OpenAIModel(id: "gpt-4o-mini-realtime", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Smaller realtime model for text/audio", modalities: ["Text Input/Output", "Audio Input/Output"]),
//            
//            // Older GPT Models
//            OpenAIModel(id: "gpt-4-turbo", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "128k", shortDescription: "An older high-intelligence GPT model", modalities: ["Text Input/Output"]),
//            OpenAIModel(id: "gpt-4", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "8k / 32k", shortDescription: "An older high-intelligence GPT model", modalities: ["Text Input/Output"]),
//            OpenAIModel(id: "gpt-3.5-turbo", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", capabilities: ["text generation"], contextWindow: "4k / 16k", shortDescription: "Legacy GPT model for cheaper tasks", modalities: ["Text Input/Output"]),
//            
//            // DALL-E Models
//            OpenAIModel(id: "dall-e-3", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our latest image generation model", modalities: ["Text Input", "Image Output"]),
//            OpenAIModel(id: "dall-e-2", created: 1650000000, ownedBy: "openai", description: "Our first image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our first image generation model", modalities: ["Text Input", "Image Output"]),
//            
//            // Text-to-speech Models
//            OpenAIModel(id: "tts-1", created: 1690000000, ownedBy: "openai", description: "Text-to-speech model optimized for speed.", capabilities: ["tts"], contextWindow: "4096 chars", shortDescription: "Text-to-speech model optimized for speed", modalities: ["Text Input", "Audio Output"]),
//            OpenAIModel(id: "tts-1-hd", created: 1695000000, ownedBy: "openai", description: "Text-to-speech model optimized for quality.", capabilities: ["tts-hd"], contextWindow: "4096 chars", shortDescription: "Text-to-speech model optimized for quality", modalities: ["Text Input", "Audio Output"]),
//            OpenAIModel(id: "gpt-4o-mini-tts", created: 1712370000, ownedBy: "openai", description: "Text-to-speech model powered by GPT-4o mini.", capabilities: ["tts"], contextWindow: "N/A", shortDescription: "TTS model powered by GPT-4o mini", modalities: ["Text Input", "Audio Output"]),
//            
//            // Transcription Models
//            OpenAIModel(id: "whisper-1", created: 1677600000, ownedBy: "openai", description: "General-purpose speech recognition model.", capabilities: ["audio transcription", "translation"], contextWindow: "N/A", shortDescription: "General-purpose speech recognition", modalities: ["Audio Input", "Text Output"]),
//            OpenAIModel(id: "gpt-4o-transcribe", created: 1712870000, ownedBy: "openai", description: "Speech-to-text model powered by GPT-4o.", capabilities: ["audio transcription"], contextWindow: "N/A", shortDescription: "Speech-to-text powered by GPT-4o", modalities: ["Audio Input", "Text Output"]),
//            OpenAIModel(id: "gpt-4o-mini-transcribe", created: 1712380000, ownedBy: "openai", description: "Speech-to-text model powered by GPT-4o mini.", capabilities: ["audio transcription"], contextWindow: "N/A", shortDescription: "Speech-to-text powered by GPT-4o mini", modalities: ["Audio Input", "Text Output"]),
//            
//            // Embeddings Models
//            OpenAIModel(id: "text-embedding-3-small", created: 1711200000, ownedBy: "openai", description: "Small embedding model.", capabilities: ["text embedding"], contextWindow: "8191 tokens", shortDescription: "Small embedding model", modalities: ["Text Input", "Vector Output"]),
//            OpenAIModel(id: "text-embedding-3-large", created: 1711300000, ownedBy: "openai", description: "Most capable embedding model.", capabilities: ["text embedding"], contextWindow: "8191 tokens", shortDescription: "Most capable embedding model", modalities: ["Text Input", "Vector Output"]),
//            OpenAIModel(id: "text-embedding-ada-002", created: 1670000000, ownedBy: "openai", description: "Older embedding model.", capabilities: ["text embedding"], contextWindow: "8191 tokens", shortDescription: "Older embedding model", modalities: ["Text Input", "Vector Output"]),
//            
//            // Moderation Models
//            OpenAIModel(id: "text-moderation-latest", created: 1688000000, ownedBy: "openai", description: "Latest text moderation model.", capabilities: ["content filtering"], contextWindow: "32768 bytes", shortDescription: "Latest text moderation model", modalities: ["Text Input", "Classification Output"]),
//            OpenAIModel(id: "omni-moderation", created: 1712880000, ownedBy: "openai", description: "Identify potentially harmful content in text and images.", capabilities: ["content filtering", "image moderation"], contextWindow: "N/A", shortDescription: "Identify potentially harmful content", modalities: ["Text Input", "Image Input", "Classification Output"]),
//            
//            // Tool-specific Models
//            OpenAIModel(id: "gpt-4o-search-preview", created: 1712890000, ownedBy: "openai", description: "GPT model for web search in Chat Completions.", capabilities: ["search", "text generation"], contextWindow: "128k", shortDescription: "GPT model for web search", modalities: ["Text Input/Output"], supportedFeatures: ["Web Search Tool"]),
//            OpenAIModel(id: "gpt-4o-mini-search-preview", created: 1712390000, ownedBy: "openai", description: "Fast, affordable small model for web search.", capabilities: ["search", "text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model for search", modalities: ["Text Input/Output"], supportedFeatures: ["Web Search Tool"]),
//            OpenAIModel(id: "computer-use-preview", created: 1712910000, ownedBy: "openai", description: "Specialized model for computer use tool.", capabilities: ["tool-use", "computer control"], contextWindow: "N/A", shortDescription: "Specialized model for computer use tool", modalities: ["Text Input/Output"], supportedFeatures: ["Computer Use Tool"]),
//        ]
//    }
//    
//    func fetchModels() async throws -> [OpenAIModel] {
//        try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
//        return generateMockModels()
//        // throw MockError.simulatedFetchError // Uncomment to test error state
//    }
//}
//
//// --- Live Data Service ---
//class LiveAPIService: APIServiceProtocol {
//    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""
//    private let modelsURL = URL(string: "https://api.openai.com/v1/models")!
//    
//    func fetchModels() async throws -> [OpenAIModel] {
//        let currentKey = storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !currentKey.isEmpty else { throw LiveAPIError.missingAPIKey }
//        
//        var request = URLRequest(url: modelsURL)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(currentKey)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        print("🚀 Making live API request to: \(modelsURL)")
//        
//        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//            guard let httpResponse = response as? HTTPURLResponse else { throw LiveAPIError.requestFailed(statusCode: 0) }
//            print("✅ Received API response with status code: \(httpResponse.statusCode)")
//            
//            if httpResponse.statusCode == 401 { throw LiveAPIError.missingAPIKey }
//            guard (200...299).contains(httpResponse.statusCode) else { throw LiveAPIError.requestFailed(statusCode: httpResponse.statusCode) }
//            
//            do {
//                let decoder = JSONDecoder()
//                let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
//                print("✅ Successfully decoded \(responseWrapper.data.count) models.")
//                
//                // Map response: Add default details if needed, or enrich based on ID if possible
//                // For live data, fields like knowledgeCutoff, modalities, etc., will likely be nil
//                // unless OpenAI adds them to the /v1/models endpoint in the future.
//                // The default values in the struct handle this.
//                return responseWrapper.data.map { model in
//                    var mutableModel = model
//                    // Example: Assign a default short description if API doesn't provide one based on type
//                    if model.id.lowercased().contains("gpt") {
//                        mutableModel.shortDescription = "General purpose chat model."
//                    } else if model.id.lowercased().contains("tts") {
//                        mutableModel.shortDescription = "Text-to-speech model."
//                    } // ... etc.
//                    // Live API won't have detailed pricing, features etc. Let defaults/nil work.
//                    return mutableModel
//                }
//            } catch {
//                print("❌ Decoding Error: \(error)")
//                print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Could not decode data")")
//                throw LiveAPIError.decodingError(error)
//            }
//        } catch let error as LiveAPIError { throw error }
//        catch { throw LiveAPIError.networkError(error) }
//    }
//}
//
//// MARK: - Reusable SwiftUI Helper Views (Error, WrappingHStack, APIKeyInputView)
//
//struct ErrorView: View {
//    let errorMessage: String
//    let retryAction: () -> Void
//    var body: some View { /* ... Error view implementation (unchanged) ... */
//        VStack(alignment: .center, spacing: 15) {
//            Image(systemName: "wifi.exclamationmark")
//                .resizable().scaledToFit().frame(width: 60, height: 60)
//                .foregroundColor(.red)
//            VStack(spacing: 5) {
//                Text("Loading Failed").font(.title3.weight(.medium))
//                Text(errorMessage).font(.callout).foregroundColor(.secondary)
//                    .multilineTextAlignment(.center).padding(.horizontal)
//            }
//            Button { retryAction() } label: { Label("Retry", systemImage: "arrow.clockwise") }
//                .buttonStyle(.borderedProminent).controlSize(.regular).padding(.top)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding().background(Color(.systemGroupedBackground))
//    }
//}
//
//struct WrappingHStack<Item: Hashable, ItemView: View>: View {
//    let items: [Item]
//    let viewForItem: (Item) -> ItemView
//    let horizontalSpacing: CGFloat = 8
//    let verticalSpacing: CGFloat = 8
//    @State private var totalHeight: CGFloat = .zero
//    var body: some View { /* ... WrappingHStack implementation (unchanged) ... */
//        VStack {
//            GeometryReader { geometry in self.generateContent(in: geometry) }
//        }
//        .frame(height: totalHeight)
//    }
//    private func generateContent(in g: GeometryProxy) -> some View {
//        var width = CGFloat.zero
//        var height = CGFloat.zero
//        return ZStack(alignment: .topLeading) {
//            ForEach(self.items, id: \.self) { item in
//                self.viewForItem(item)
//                    .padding(.horizontal, horizontalSpacing / 2)
//                    .padding(.vertical, verticalSpacing / 2)
//                    .alignmentGuide(.leading, computeValue: { d in
//                        if (abs(width - d.width) > g.size.width) {
//                            width = 0; height -= d.height + verticalSpacing
//                        }
//                        let result = width
//                        if item == self.items.last { width = 0 } else { width -= d.width }
//                        return result
//                    })
//                    .alignmentGuide(.top, computeValue: { d in
//                        let result = height
//                        if item == self.items.last { height = 0 }
//                        return result
//                    })
//            }
//        }.background(viewHeightReader($totalHeight))
//    }
//    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
//        GeometryReader { geometry -> Color in
//            let rect = geometry.frame(in: .local)
//            DispatchQueue.main.async { binding.wrappedValue = rect.size.height }
//            return .clear
//        }
//    }
//}
//
//struct APIKeyInputView: View {
//    @Environment(\.dismiss) var dismiss
//    @AppStorage("userOpenAIKey") private var apiKey: String = ""
//    @State private var inputApiKey: String = ""
//    @State private var isInvalidKeyAttempt: Bool = false
//    
//    var onSave: (String) -> Void
//    var onCancel: () -> Void
//    
//    var body: some View { /* ... API Key Input View (unchanged) ... */
//        NavigationView {
//            VStack(alignment: .leading, spacing: 20) {
//                Text("Enter your OpenAI API Key")
//                    .font(.headline)
//                Text("Your key will be stored securely in UserDefaults on this device. Ensure you are using a key with appropriate permissions.")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                
//                SecureField("sk-...", text: $inputApiKey)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 5)
//                            .stroke(isInvalidKeyAttempt ? Color.red : Color.clear, lineWidth: 1)
//                    )
//                    .onChange(of: inputApiKey) { _, _ in isInvalidKeyAttempt = false }
//                
//                if isInvalidKeyAttempt {
//                    Text("API Key cannot be empty.").font(.caption).foregroundColor(.red)
//                }
//                
//                HStack {
//                    Button("Cancel") { onCancel(); dismiss() }
//                        .buttonStyle(.bordered)
//                    Spacer()
//                    Button("Save Key") {
//                        let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
//                        if trimmedKey.isEmpty { isInvalidKeyAttempt = true }
//                        else { apiKey = trimmedKey; onSave(apiKey); dismiss() }
//                    }
//                    .buttonStyle(.borderedProminent)
//                }
//                .padding(.top)
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("API Key")
//            .navigationBarTitleDisplayMode(.inline)
//            .onAppear { inputApiKey = apiKey; isInvalidKeyAttempt = false }
//        }
//    }
//}
//
//// MARK: - Model Views (Featured Card, Standard Row, Detail - Updated Detail)
//
//struct FeaturedModelCard: View {
//    let model: OpenAIModel
//    var body: some View { /* ... Featured Model Card (unchanged) ... */
//        VStack(alignment: .leading, spacing: 10) {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(model.iconBackgroundColor.opacity(0.3))
//                .frame(height: 120)
//                .overlay( Image(systemName: model.iconName).resizable().scaledToFit().padding(25).foregroundStyle(model.iconBackgroundColor) )
//            VStack(alignment: .leading, spacing: 4) {
//                Text(model.displayName).font(.headline)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
//            }
//            .padding([.horizontal, .bottom], 12)
//        }
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
//        .frame(minWidth: 0, maxWidth: .infinity)
//    }
//}
//
//struct StandardModelRow: View {
//    let model: OpenAIModel
//    var body: some View { /* ... Standard Model Row (unchanged) ... */
//        HStack(spacing: 12) {
//            Image(systemName: model.iconName)
//                .resizable().scaledToFit().padding(7).frame(width: 36, height: 36)
//                .background(model.iconBackgroundColor.opacity(0.85)).foregroundStyle(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//            VStack(alignment: .leading, spacing: 3) {
//                Text(model.displayName).font(.subheadline.weight(.medium)).lineLimit(1)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
//            }
//            Spacer(minLength: 0)
//        }
//        .padding(10)
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 10))
//        .overlay( RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1) )
//    }
//}
//
//struct SectionHeader: View {
//    let title: String
//    let subtitle: String?
//    var body: some View { /* ... Section Header (unchanged) ... */
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title).font(.title2.weight(.semibold))
//            if let subtitle = subtitle { Text(subtitle).font(.callout).foregroundColor(.secondary) }
//        }
//        .padding(.bottom, 10).padding(.horizontal)
//    }
//}
//
//// --- Updated Model Detail View ---
//struct ModelDetailView: View {
//    let model: OpenAIModel
//    var body: some View {
//        List {
//            // --- Top Icon/Title Section ---
//            Section {
//                VStack(spacing: 15) {
//                    Image(systemName: model.iconName).resizable().scaledToFit()
//                        .padding(15).frame(width: 80, height: 80)
//                        .background(model.iconBackgroundColor).foregroundStyle(.white)
//                        .clipShape(Circle())
//                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
//                    Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
//                    Text(model.shortDescription).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
//                }
//                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
//            }
//            .listRowInsets(EdgeInsets()) // Remove default padding
//            .listRowBackground(Color.clear) // Make background clear
//            
//            // --- Overview Section ---
//            Section("Overview") {
//                DetailRow(label: "Full ID", value: model.id)
//                DetailRow(label: "Type", value: model.object)
//                DetailRow(label: "Owner", value: model.ownedBy)
//                DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
//                if let cutoff = model.knowledgeCutoff { DetailRow(label: "Knowledge Cutoff", value: cutoff) }
//            }
//            
//            // --- Details Section ---
//            Section("Details") {
//                DetailRowV(label: "Description", value: model.description)
//                DetailRow(label: "Context Window", value: model.contextWindow)
//                if let maxTokens = model.maxOutputTokens { DetailRow(label: "Max Output Tokens", value: maxTokens) }
//            }
//            
//            // --- Modalities Section ---
//            if let modalities = model.modalities, !modalities.isEmpty {
//                Section("Modalities") {
//                    TagListView(tags: modalities, tagColor: .blue, icon: "square.stack.3d.up.fill")
//                }
//            }
//            
//            // --- Features Section ---
//            if let features = model.supportedFeatures, !features.isEmpty {
//                Section("Supported Features") {
//                    TagListView(tags: features, tagColor: .green, icon: "wrench.and.screwdriver.fill")
//                }
//            }
//            
//            // --- Endpoints Section ---
//            if let endpoints = model.supportedEndpoints, !endpoints.isEmpty {
//                Section("Supported Endpoints") {
//                    TagListView(tags: endpoints, tagColor: .orange, icon: "link")
//                }
//            }
//            
//            // --- Pricing Section ---
//            if model.pricingText != nil || model.pricingAudio != nil {
//                Section("Pricing (Per 1M Tokens)") {
//                    if let textPrice = model.formattedTextPricing {
//                        DetailRowV(label: "Text Tokens", value: textPrice)
//                    }
//                    if let audioPrice = model.formattedAudioPricing {
//                        DetailRowV(label: "Audio Tokens", value: audioPrice)
//                    }
//                }
//            }
//            
//        }
//        .listStyle(.insetGrouped)
//        .navigationTitle("Model Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//    
//    // --- Helper Views for Detail Rows ---
//    private func DetailRow(label: String, value: String) -> some View {
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//            Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
//        }
//        .padding(.vertical, 2)
//        .accessibilityElement(children: .combine)
//    }
//    
//    private func DetailRowV(label: String, value: String) -> some View {
//        VStack(alignment: .leading, spacing: 3) {
//            Text(label).font(.caption).foregroundColor(.secondary)
//            Text(value).font(.body).foregroundColor(.primary)
//        }
//        .padding(.vertical, 4)
//        .accessibilityElement(children: .combine)
//    }
//    
//    // --- Helper View for Tag Lists ---
//    private func TagListView(tags: [String], tagColor: Color, icon: String? = nil) -> some View {
//        WrappingHStack(items: tags) { tag in
//            HStack(spacing: 4) {
//                if let icon = icon { Image(systemName: icon).imageScale(.small) }
//                Text(tag)
//            }
//            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
//            .background(tagColor.opacity(0.15))
//            .foregroundColor(tagColor)
//            .clipShape(Capsule())
//            .overlay(Capsule().stroke(tagColor.opacity(0.3), lineWidth: 1))
//        }
//        .padding(.vertical, 4)
//    }
//}
//
//// MARK: - Main Content View (Adapted for Sections)
//
//struct OpenAIModelsMasterView: View {
//    // --- State Variables (unchanged) ---
//    @State private var allModels: [OpenAIModel] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String? = nil
//    @State private var useMockData = true // Default to Mock
//    @State private var showingApiKeySheet = false
//    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""
//    
//    // --- API Service Instance (unchanged) ---
//    private var currentApiService: APIServiceProtocol {
//        useMockData ? MockAPIService() : LiveAPIService()
//    }
//    
//    // --- Grid Layout (unchanged) ---
//    let gridColumns: [GridItem] = [
//        GridItem(.flexible(), spacing: 15),
//        GridItem(.flexible(), spacing: 15)
//    ]
//    
//    // --- Filters for Sections (Potentially update includes) ---
//    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "o4-mini", "o3"].contains($0.id) }.sortedById() }
//    var reasoningModels: [OpenAIModel] { allModels.filter { ["o4-mini", "o3", "o3-mini", "o1", "o1-pro", "o1-mini"].contains($0.id) }.sortedById() }
//    var flagshipChatModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "gpt-4o", "gpt-4o-audio", "chatgpt-4o-latest"].contains($0.id) }.sortedById() }
//    var costOptimizedModels: [OpenAIModel] { allModels.filter { ["o4-mini", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o-mini", "gpt-4o-mini-audio", "o1-mini"].contains($0.id) }.sortedById() }
//    // Updated Realtime to include both regular and mini
//    var realtimeModels: [OpenAIModel] { allModels.filter { $0.id.contains("-realtime") }.sortedById() }
//    var olderGptModels: [OpenAIModel] { allModels.filter { ["gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"].contains($0.id) }.sortedById() }
//    var dalleModels: [OpenAIModel] { allModels.filter { $0.id.contains("dall-e") }.sortedById() }
//    var ttsModels: [OpenAIModel] { allModels.filter { $0.id.contains("tts") }.sortedById() }
//    var transcriptionModels: [OpenAIModel] { allModels.filter { $0.id.contains("whisper") || $0.id.contains("transcribe") }.sortedById() }
//    var embeddingsModels: [OpenAIModel] { allModels.filter { $0.id.contains("embedding") }.sortedById() }
//    var moderationModels: [OpenAIModel] { allModels.filter { $0.id.contains("moderation") }.sortedById() }
//    var toolSpecificModels: [OpenAIModel] { allModels.filter { $0.id.contains("search") || $0.id.contains("computer-use") }.sortedById() }
//    
//    var body: some View {
//        NavigationStack {
//            ZStack { // Keep ZStack for overlaying ProgressView/ErrorView
//                if isLoading && allModels.isEmpty {
//                    ProgressView("Fetching Models...").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemBackground)).zIndex(1)
//                } else if let errorMessage = errorMessage, allModels.isEmpty {
//                    ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
//                } else {
//                    ScrollView(.vertical, showsIndicators: false) {
//                        VStack(alignment: .leading, spacing: 30) {
//                            // --- Header ---
//                            VStack(alignment: .leading, spacing: 5) {
//                                Text("Models").font(.largeTitle.weight(.bold))
//                                Text("Explore all available models and compare their capabilities.").font(.title3).foregroundColor(.secondary)
//                            }.padding(.horizontal)
//                            Divider().padding(.horizontal)
//                            // --- Sections (using displaySection helper) ---
//                            displayFeaturedSection() // Special display for featured
//                            displaySection(title: "Reasoning models", subtitle: "o-series models that excel at complex, multi-step tasks.", models: reasoningModels)
//                            displaySection(title: "Flagship chat models", subtitle: "Our versatile, high-intelligence flagship models.", models: flagshipChatModels)
//                            displaySection(title: "Cost-optimized models", subtitle: "Smaller, faster models that cost less to run.", models: costOptimizedModels)
//                            displaySection(title: "Realtime models", subtitle: "Models capable of realtime text and audio inputs and outputs.", models: realtimeModels)
//                            displaySection(title: "Older GPT models", subtitle: "Supported older versions of our general purpose and chat models.", models: olderGptModels)
//                            displaySection(title: "DALL·E", subtitle: "Models that can generate and edit images, given a natural language prompt.", models: dalleModels)
//                            displaySection(title: "Text-to-speech", subtitle: "Models that can convert text into natural sounding spoken audio.", models: ttsModels)
//                            displaySection(title: "Transcription", subtitle: "Model that can transcribe and translate audio into text.", models: transcriptionModels)
//                            displaySection(title: "Embeddings", subtitle: "A set of models that can convert text into vector representations.", models: embeddingsModels)
//                            displaySection(title: "Moderation", subtitle: "Fine-tuned models that detect whether input may be sensitive or unsafe.", models: moderationModels)
//                            displaySection(title: "Tool-specific models", subtitle: "Models to support specific built-in tools.", models: toolSpecificModels)
//                            Spacer(minLength: 50)
//                        }.padding(.top)
//                    } // End ScrollView
//                    .background(Color(.systemBackground))
//                    .edgesIgnoringSafeArea(.bottom)
//                }
//            } // End ZStack
//            .navigationTitle("OpenAI Models")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { /* Toolbar items (unchanged) */
//                ToolbarItem(placement: .navigationBarLeading) {
//                    if isLoading { ProgressView().controlSize(.small) }
//                    else { Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(isLoading) }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Menu { Toggle(isOn: $useMockData) { Text(useMockData ? "Using Mock Data" : "Using Live API") } }
//                    label: { Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill").foregroundColor(useMockData ? .secondary : .blue) }
//                        .disabled(isLoading)
//                }
//            }
//            // --- Navigation Destination uses updated Detail View ---
//            .navigationDestination(for: OpenAIModel.self) { model in
//                ModelDetailView(model: model)
//                    .toolbarBackground(.visible, for: .navigationBar)
//                    .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
//                // Consider adding a 'title' based on model.displayName here if preferred
//            }
//            .task { if allModels.isEmpty { attemptLoadModels() } }
//            .refreshable { await loadModelsAsync(checkApiKey: false) }
//            .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
//            .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
//            .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: { Button("OK") { errorMessage = nil } }, message: { Text(errorMessage ?? "An unknown error occurred.") })
//        } // End NavigationStack
//    }
//    
//    // --- Helper View Builder for Sections ---
//    @ViewBuilder
//    private func displaySection(title: String, subtitle: String?, models: [OpenAIModel]) -> some View {
//        if !models.isEmpty {
//            Divider().padding(.horizontal)
//            SectionHeader(title: title, subtitle: subtitle)
//            LazyVGrid(columns: gridColumns, spacing: 15) {
//                ForEach(models) { model in
//                    NavigationLink(value: model) { StandardModelRow(model: model) }
//                        .buttonStyle(.plain)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    // --- Special Helper for Featured Section ---
//    @ViewBuilder
//    private func displayFeaturedSection() -> some View {
//        let models = featuredModels
//        if !models.isEmpty {
//            SectionHeader(title: "Featured models", subtitle: nil)
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 15) {
//                    ForEach(models) { model in
//                        NavigationLink(value: model) {
//                            FeaturedModelCard(model: model).frame(width: 250)
//                        }.buttonStyle(.plain)
//                    }
//                }
//                .padding(.horizontal).padding(.bottom, 5)
//            }
//        }
//    }
//    
//    // --- Helper Functions for Loading & API Key Handling (unchanged) ---
//    private func handleToggleChange(to newValue: Bool) { /*...*/
//        print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
//        allModels = []
//        errorMessage = nil
//        if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            showingApiKeySheet = true
//        } else { loadModelsAsyncWithLoadingState() }
//    }
//    private func presentApiKeySheet() -> some View { /*...*/
//        APIKeyInputView( onSave: { _ in print("API Key saved."); loadModelsAsyncWithLoadingState() }, onCancel: { print("API Key input cancelled."); useMockData = true } )
//    }
//    private func attemptLoadModels() { /*...*/
//        guard !isLoading else { return }
//        if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            showingApiKeySheet = true
//        } else { loadModelsAsyncWithLoadingState() }
//    }
//    private func loadModelsAsyncWithLoadingState() { /*...*/
//        guard !isLoading else { return }
//        isLoading = true
//        Task { await loadModelsAsync(checkApiKey: false) }
//    }
//    @MainActor private func loadModelsAsync(checkApiKey: Bool) async { /*...*/
//        if !isLoading { isLoading = true }
//        if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            showingApiKeySheet = true; isLoading = false; return
//        }
//        let serviceToUse = currentApiService
//        print("🔄 Loading models using \(useMockData ? "MockAPIService" : "LiveAPIService")...")
//        do {
//            let fetchedModels = try await serviceToUse.fetchModels()
//            self.allModels = fetchedModels
//            self.errorMessage = nil
//            print("✅ Successfully loaded \(fetchedModels.count) models.")
//        } catch let error as LocalizedError {
//            print("❌ Error loading models: \(error.localizedDescription)")
//            self.errorMessage = error.localizedDescription
//            if allModels.isEmpty { self.allModels = [] }
//        } catch {
//            print("❌ Unexpected error loading models: \(error)")
//            self.errorMessage = "Unexpected error: \(error.localizedDescription)"
//            if allModels.isEmpty { self.allModels = [] }
//        }
//        isLoading = false
//    }
//}
//
//// MARK: - Helper Extensions
//
//extension Array where Element == OpenAIModel {
//    // Helper to sort models alphabetically by ID for consistent section display
//    func sortedById() -> [OpenAIModel] {
//        self.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
//    }
//}
//
//// MARK: - Previews
//
//#Preview("Main View (Mock Data)") { OpenAIModelsMasterView() }
////#Preview("Detail View (GPT-4o Realtime)") {
////    // Find the specific model from mock data
////    let mockService = MockAPIService()
////    let realtimeModel = try! await mockService.fetchModels().first { $0.id == "gpt-4o-realtime" }!
////    NavigationStack { ModelDetailView(model: realtimeModel) }
////}
//
//#Preview("API Key Input Sheet") {
//    struct SheetPresenter: View {
//        @State var showSheet = true
//        var body: some View { Text("Sheet Preview").sheet(isPresented: $showSheet) { APIKeyInputView(onSave: {_ in}, onCancel: {}) } }
//    }
//    return SheetPresenter()
//}
