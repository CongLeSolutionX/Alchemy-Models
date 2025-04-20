////
////  OpenAIModelsMasterView_ChatGPT_4o.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIModelsMasterView.swift
////  Alchemy_Models_Combined
////  (Single File Implementation for ChatGPT-4o Focus)
////
////  Created: Cong Le
////  Date: 4/13/25 (Based on previous iterations, updated 4/13/25 for GPT-4o details)
////  Version: 1.2 (Synthesized & Adapted to Screenshots for ChatGPT-4o)
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
//     case simulatedFetchError
//     var errorDescription: String? {
//         switch self {
//         case .simulatedFetchError: return "Simulated network error: Could not fetch models."
//         }
//     }
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
//    // These help maintain consistency between detailed mock data and live data.
//    var description: String = "No description available."
//    var capabilities: [String] = ["general"] // Default capability
//    var contextWindow: String = "N/A"
//    var typicalUseCases: [String] = ["Various tasks"] // Default use case
//    // New field based on screenshots - provide a default
//    var shortDescription: String = "General purpose model."
//
//    // --- Non-Codable Properties Specific to ChatGPT-4o (populated in mock or potentially derived) ---
//    // These won't be decoded from the basic API but are useful for the Detail View
//    var intelligenceRating: Int? = nil // e.g., 3/3
//    var speedRating: Int? = nil         // e.g., 2/3
//    var priceInputMillions: Double? = nil  // e.g., 5.00
//    var priceOutputMillions: Double? = nil // e.g., 15.00
//    var maxOutputTokens: Int? = nil        // e.g., 16384
//    var knowledgeCutoff: String? = nil     // e.g., "Sep 30, 2023"
//    var modalities: [ModalityInfo]? = nil
//    var endpoints: [EndpointInfo]? = nil
//    var features: [FeatureInfo]? = nil
//    var snapshots: [String]? = nil         // e.g., ["chatgpt-4o-latest"]
//
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id
//        case object
//        case created
//        case ownedBy = "owned_by"
//        // IMPORTANT: description, capabilities, contextWindow, typicalUseCases, shortDescription,
//        // and all the new non-codable properties are NOT listed here.
//        // Codable will ignore them during JSON decoding if they aren't present,
//        // allowing default values or manual population (like in mocks) to be used.
//    }
//
//    // --- Computed Properties & Hashable ---
//    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
//    func hash(into hasher: inout Hasher) { hasher.combine(id) }
//    static func == (lhs: OpenAIModel, rhs: OpenAIModel) -> Bool { lhs.id == rhs.id }
//}
//
//// Helper structs for detailed info (not Codable by default)
//struct ModalityInfo: Hashable { let name: String; let input: Bool; let output: Bool; let icon: String }
//struct EndpointInfo: Hashable { let name: String; let supported: Bool; let icon: String }
//struct FeatureInfo: Hashable { let name: String; let supported: Bool; let icon: String }
//
//// MARK: - Model Extension for UI Logic
//
//extension OpenAIModel {
//    // --- Determine SF Symbol name based on ID or owner ---
//    var iconName: String {
//        let normalizedId = id.lowercased()
//        // Specific icons for GPT-4o variants first
//        if normalizedId.contains("chatgpt-4o") || normalizedId.contains("gpt-4o") { return "sparkles.square.fill.on.square" } // More distinct icon for 4o
//        if normalizedId.contains("gpt-4.1") { return "sparkles" } // Original sparkles for 4.1
//        if normalizedId.contains("o4-mini") || normalizedId.contains("o3-mini") || normalizedId.contains("o1-mini") || normalizedId.contains("gpt-4.1-mini") || normalizedId.contains("gpt-4o-mini") { return "leaf.fill" }
//        if normalizedId.contains("o3") { return "circle.hexagonpath.fill" }
//        if normalizedId.contains("o1") || normalizedId.contains("o1-pro") { return "circles.hexagonpath.fill" }
//        if normalizedId.contains("gpt-4-turbo") { return "bolt.fill" }
//        if normalizedId.contains("gpt-4") && !normalizedId.contains("turbo") && !normalizedId.contains("4o") { return "star.fill"} // Ensure it doesn't catch 4o
//        if normalizedId.contains("gpt-3.5") { return "forward.fill" }
//        if normalizedId.contains("dall-e") { return "paintbrush.pointed.fill" }
//        if normalizedId.contains("tts") { return "speaker.wave.2.fill" }
//        if normalizedId.contains("transcribe") || normalizedId.contains("whisper") { return "waveform" }
//        if normalizedId.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" }
//        if normalizedId.contains("moderation") { return "exclamationmark.shield.fill" }
//        if normalizedId.contains("search") { return "magnifyingglass"}
//        if normalizedId.contains("computer-use") { return "computermouse.fill" }
//        if normalizedId.contains("realtime") { return "stopwatch.fill" } // Icon for realtime
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
//         let normalizedId = id.lowercased()
//         // Specific colors for GPT-4o variants first
//         if normalizedId.contains("chatgpt-4o") || normalizedId.contains("gpt-4o") { return Color.cyan } // Distinct color for 4o
//         if normalizedId.contains("gpt-4.1") { return .blue }
//         if normalizedId.contains("o4-mini") { return .purple }
//         if normalizedId.contains("o3") { return .orange }
//         if normalizedId.contains("dall-e") { return .teal }
//         if normalizedId.contains("tts") { return .indigo }
//         if normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return .pink }
//         if normalizedId.contains("embedding") { return .green }
//         if normalizedId.contains("moderation") { return .red }
//         if normalizedId.contains("search") { return .cyan.opacity(0.7) } // Slightly different cyan
//         if normalizedId.contains("computer-use") { return .brown }
//         if normalizedId.contains("realtime") { return .yellow } // Color for realtime
//
//         // Fallback based on owner
//         let lowerOwner = ownedBy.lowercased()
//         if lowerOwner.contains("openai") { return .blue.opacity(0.8) }
//         if lowerOwner == "system" { return .orange.opacity(0.8) }
//         if lowerOwner.contains("user") || lowerOwner.contains("org") { return .purple.opacity(0.8) }
//         return .gray.opacity(0.7) // Default/fallback
//    }
//
//    // --- Simplified name for display ---
//    var displayName: String {
//        // Specific handling for known aliases/models
//        if id.lowercased() == "chatgpt-4o-latest" { return "ChatGPT-4o" }
//        if id.lowercased() == "gpt-4o" { return "GPT-4o" }
//         // General replacement
//         return id.replacingOccurrences(of: "-", with: " ").capitalized
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
//        // --- GPT-4o Specific Data ---
//        let gpt4o_modalities: [ModalityInfo] = [
//            .init(name: "Text", input: true, output: true, icon: "text.bubble"),
//            .init(name: "Image", input: true, output: false, icon: "photo"),
//            .init(name: "Audio", input: false, output: false, icon: "speaker.slash") // Not supported per screenshot
//        ]
//        let gpt4o_endpoints: [EndpointInfo] = [
//            .init(name: "Chat Completions", supported: true, icon: "message"),
//            .init(name: "Responses", supported: true, icon: "bubble.left.and.bubble.right"), // Assuming v1/responses
//            .init(name: "Realtime", supported: false, icon: "stopwatch"),
//            .init(name: "Batch", supported: false, icon: "square.stack.3d.up"),
//            .init(name: "Embeddings", supported: false, icon: "arrow.down.right.and.arrow.up.left"),
//            .init(name: "Speech Generation", supported: false, icon: "waveform.path.ecg"),
//            .init(name: "Translation", supported: false, icon: "character.bubble"),
//            .init(name: "Completions (Legacy)", supported: false, icon: "text.cursor"),
//            .init(name: "Assistants", supported: false, icon: "person.badge.key"),
//            .init(name: "Fine-tuning", supported: false, icon: "slider.horizontal.3"),
//            .init(name: "Image Generation", supported: false, icon: "photo.on.rectangle.angled"),
//            .init(name: "Transcription", supported: false, icon: "waveform"),
//            .init(name: "Moderation", supported: false, icon: "exclamationmark.shield")
//        ]
//        let gpt4o_features: [FeatureInfo] = [
//             .init(name: "Streaming", supported: true, icon: "play.circle"),
//             .init(name: "Function Calling", supported: false, icon: "wrench.and.screwdriver"), // Not supported per sc.
//             .init(name: "Structured Outputs", supported: false, icon: "list.bullet.rectangle"),
//             .init(name: "Fine-tuning", supported: false, icon: "slider.horizontal.3"),
//             .init(name: "Distillation", supported: false, icon: "drop"),
//             .init(name: "Predicted Outputs", supported: true, icon: "lightbulb") // Supported per sc.
//        ]
//        let gpt4o_description = "ChatGPT-4o points to the GPT-4o snapshot currently used in ChatGPT. GPT-4o is our versatile, high-intelligence flagship model. It accepts both text and image inputs, and produces text outputs. It is the best model for most tasks, and is our most capable model outside of our o-series models."
//        let gpt4o_short_description = "GPT-4o model used in ChatGPT."
//        let gpt4o_use_cases = ["Math Tutor", "Travel Assistant", "Clothing Recommendation", "Recipe Generation"]
//
//        // --- All Mock Models Definition ---
//        return [
//            // Add the detailed ChatGPT-4o model first using the alias from screenshot
//            OpenAIModel(
//                id: "chatgpt-4o-latest", object: "model", created: 1712900000, ownedBy: "openai",
//                description: gpt4o_description,
//                capabilities: ["text generation", "reasoning", "code", "vision", "chat"], // Capabilities based on description
//                contextWindow: "128,000 tokens",
//                typicalUseCases: gpt4o_use_cases,
//                shortDescription: gpt4o_short_description,
//                // Add the new detailed properties
//                intelligenceRating: 3, speedRating: 2,
//                priceInputMillions: 5.00,
//                priceOutputMillions: 15.00,
//                maxOutputTokens: 16384, knowledgeCutoff: "Sep 30, 2023",
//                modalities: gpt4o_modalities, endpoints: gpt4o_endpoints, features: gpt4o_features,
//                snapshots: ["chatgpt-4o-latest"]
//            ),
//
//             // Include the base gpt-4o ID as well if needed, potentially less detailed or linking to the above
//             OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model (Base ID). See chatgpt-4o-latest for full details.", capabilities: ["text generation", "reasoning", "code", "vision", "audio", "chat"], contextWindow: "128k", shortDescription: "Fast, intelligent, flexible GPT model"), // Provide base 4o
//
//            // --- Rest of the models from previous implementation ---
//            // Featured
//            OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k", shortDescription: "Flagship GPT model for complex tasks"),
//            OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Faster, more affordable reasoning model"),
//            OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "16k", shortDescription: "Our most powerful reasoning model"),
//
//            // Reasoning Models
//            OpenAIModel(id: "o3-mini", object: "model", created: 1699000000, ownedBy: "openai", description: "A smaller, faster, and more affordable alternative to o3.", capabilities: ["text generation", "reasoning"], contextWindow: "16k", shortDescription: "A small model alternative to o3"),
//            OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Previous full o-series reasoning model"),
//            OpenAIModel(id: "o1-pro", object: "model", created: 1685000000, ownedBy: "openai", description: "Version of o1 with more compute for better responses.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Version of o1 with more compute"),
//            OpenAIModel(id: "o1-mini", object: "model", created: 1675000000, ownedBy: "openai", description: "A small model alternative to o1, very fast.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "A small model alternative to o1"),
//
//            // Other GPT Models (Simplified after 4o)
//            OpenAIModel(id: "gpt-4o-audio", object: "model", created: 1712850000, ownedBy: "openai", description: "GPT-4o models capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "GPT-4o models capable of audio inputs"),
//            OpenAIModel(id: "gpt-4.1-mini", object: "model", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Balanced for intelligence, speed, cost"),
//            OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fastest, most cost-effective GPT-4.1"),
//            OpenAIModel(id: "gpt-4o-mini", object: "model", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model"),
//            OpenAIModel(id: "gpt-4o-mini-audio", object: "model", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "Smaller model capable of audio inputs"),
//            OpenAIModel(id: "gpt-4o-realtime", object: "model", created: 1712860000, ownedBy: "openai", description: "Model capable of realtime text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Model capable of realtime text/audio"),
//            OpenAIModel(id: "gpt-4o-mini-realtime", object: "model", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Smaller realtime model for text/audio"),
//            OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "128k", shortDescription: "An older high-intelligence GPT model"),
//            OpenAIModel(id: "gpt-4", object: "model", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "8k / 32k", shortDescription: "An older high-intelligence GPT model"),
//            OpenAIModel(id: "gpt-3.5-turbo", object: "model", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", capabilities: ["text generation"], contextWindow: "4k / 16k", shortDescription: "Legacy GPT model for cheaper tasks"),
//
//            // Other Models
//            OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our latest image generation model"),
//            OpenAIModel(id: "dall-e-2", object: "model", created: 1650000000, ownedBy: "openai", description: "Our first image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our first image generation model"),
//            // ... (Add other models like TTS, Whisper, Embeddings, Moderation, Tools if needed, following the previous structure)
//             // Rest of the models (TTS, Transcription, Embeddings, Moderation, Tools) from the prior implementation...
//             // Text-to-speech Models
//            OpenAIModel(id: "tts-1", object: "model", created: 1690000000, ownedBy: "openai", description: "Text-to-speech model optimized for speed.", capabilities: ["tts"], contextWindow: "N/A", shortDescription: "Text-to-speech model optimized for speed"),
//            OpenAIModel(id: "tts-1-hd", object: "model", created: 1695000000, ownedBy: "openai", description: "Text-to-speech model optimized for quality.", capabilities: ["tts"], contextWindow: "N/A", shortDescription: "Text-to-speech model optimized for quality"), // Corrected cap.
//            OpenAIModel(id: "gpt-4o-mini-tts", object: "model", created: 1712370000, ownedBy: "openai", description: "Text-to-speech model powered by GPT-4o mini.", capabilities: ["tts"], contextWindow: "N/A", shortDescription: "TTS model powered by GPT-4o mini"),
//
//             // Transcription Models
//            OpenAIModel(id: "whisper-1", object: "model", created: 1677600000, ownedBy: "openai", description: "General-purpose speech recognition model.", capabilities: ["audio transcription", "translation"], contextWindow: "N/A", shortDescription: "General-purpose speech recognition"),
//            OpenAIModel(id: "gpt-4o-transcribe", object: "model", created: 1712870000, ownedBy: "openai", description: "Speech-to-text model powered by GPT-4o.", capabilities: ["audio transcription"], contextWindow: "N/A", shortDescription: "Speech-to-text powered by GPT-4o"),
//            OpenAIModel(id: "gpt-4o-mini-transcribe", object: "model", created: 1712380000, ownedBy: "openai", description: "Speech-to-text model powered by GPT-4o mini.", capabilities: ["audio transcription"], contextWindow: "N/A", shortDescription: "Speech-to-text powered by GPT-4o mini"),
//
//             // Embeddings Models
//            OpenAIModel(id: "text-embedding-3-small", object: "model", created: 1711200000, ownedBy: "openai", description: "Small embedding model.", capabilities: ["text embedding"], contextWindow: "8k", shortDescription: "Small embedding model"),
//            OpenAIModel(id: "text-embedding-3-large", object: "model", created: 1711300000, ownedBy: "openai", description: "Most capable embedding model.", capabilities: ["text embedding"], contextWindow: "8k", shortDescription: "Most capable embedding model"),
//            OpenAIModel(id: "text-embedding-ada-002", object: "model", created: 1670000000, ownedBy: "openai", description: "Older embedding model.", capabilities: ["text embedding"], contextWindow: "8k", shortDescription: "Older embedding model"),
//
//             // Moderation Models
//            OpenAIModel(id: "text-moderation-latest", object: "model", created: 1688000000, ownedBy: "openai", description: "Previous generation text-only moderation model.", capabilities: ["content filtering"], contextWindow: "N/A", shortDescription: "Previous generation text moderation"),
//            OpenAIModel(id: "omni-moderation", object: "model", created: 1712880000, ownedBy: "openai", description: "Identify potentially harmful content in text and images.", capabilities: ["content filtering", "image moderation"], contextWindow: "N/A", shortDescription: "Identify potentially harmful content"),
//
//             // Tool-specific Models (Assuming IDs based on names)
//            OpenAIModel(id: "gpt-4o-search-preview", object: "model", created: 1712890000, ownedBy: "openai", description: "GPT model for web search in Chat Completions.", capabilities: ["search", "text generation"], contextWindow: "128k", shortDescription: "GPT model for web search"),
//             OpenAIModel(id: "gpt-4o-mini-search-preview", object: "model", created: 1712390000, ownedBy: "openai", description: "Fast, affordable small model for web search.", capabilities: ["search", "text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model for search"),
//             OpenAIModel(id: "computer-use-preview", object: "model", created: 1712910000, ownedBy: "openai", description: "Specialized model for computer use tool.", capabilities: ["tool-use", "computer control"], contextWindow: "N/A", shortDescription: "Specialized model for computer use tool")
//        ]
//    }
//
//    func fetchModels() async throws -> [OpenAIModel] {
//         try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
//         return generateMockModels()
//         // throw MockError.simulatedFetchError // Uncomment to test error state
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
//                 let decoder = JSONDecoder()
//                 let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
//                 print("✅ Successfully decoded \(responseWrapper.data.count) models.")
//                 // Map the response, potentially add default values if needed, though mock data is richer
//                 return responseWrapper.data.map { model in
//                     var mutableModel = model
//                     // Only provide a very basic default shortDescription if the API model lacks it AND our default wasn't set
//                     if mutableModel.shortDescription == "General purpose model." { // Check default value in struct
//                        mutableModel.shortDescription = model.ownedBy.contains("openai") ? "OpenAI base model." : "User/System base model."
//                     }
//                     // Add GPT-4o specific details if we fetch live and ID matches
//                     // NOTE: This requires manual mapping based on known API data, not ideal.
//                     // It's better handled via mock or a dedicated fetch for model details.
//                     if mutableModel.id.lowercased() == "gpt-4o" || mutableModel.id.lowercased() == "chatgpt-4o-latest" {
//                         // mutableModel.priceInputMillions = 5.00 // Example - don't hardcode API details here
//                         // mutableModel.knowledgeCutoff = "Sep 30, 2023"
//                     }
//                     return mutableModel
//                 }
//            } catch {
//                 print("❌ Decoding Error: \(error)")
//                 print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Could not decode data")")
//                 throw LiveAPIError.decodingError(error)
//            }
//        } catch let error as LiveAPIError { throw error }
//          catch { throw LiveAPIError.networkError(error) }
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
//            .buttonStyle(.borderedProminent).controlSize(.regular).padding(.top)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding().background(Color(.systemGroupedBackground))
//    }
//}
//
//struct WrappingHStack<Item: Hashable, ItemView: View>: View {
//    let items: [Item]? // Make optional
//    let viewForItem: (Item) -> ItemView
//    let horizontalSpacing: CGFloat = 8
//    let verticalSpacing: CGFloat = 8
//    @State private var totalHeight: CGFloat = .zero
//
//    init(items: [Item]?, @ViewBuilder viewForItem: @escaping (Item) -> ItemView) {
//        self.items = items
//        self.viewForItem = viewForItem
//    }
//
//    var body: some View { /* ... WrappingHStack implementation (adapted for optional items) ... */
//        if let items = items, !items.isEmpty {
//            VStack { GeometryReader { geometry in self.generateContent(in: geometry, for: items) } }
//                .frame(height: totalHeight)
//        } else { EmptyView() }
//    }
//
//    private func generateContent(in g: GeometryProxy, for items: [Item]) -> some View {
//        var width = CGFloat.zero
//        var height = CGFloat.zero
//        return ZStack(alignment: .topLeading) {
//            ForEach(items, id: \.self) { item in // Use the provided items
//                self.viewForItem(item)
//                    .padding(.horizontal, horizontalSpacing / 2)
//                    .padding(.vertical, verticalSpacing / 2)
//                    .alignmentGuide(.leading, computeValue: { d in
//                        if (abs(width - d.width) > g.size.width) {
//                            width = 0; height -= d.height + verticalSpacing }
//                        let result = width
//                        if item == items.last { width = 0 } else { width -= d.width }
//                        return result
//                    })
//                    .alignmentGuide(.top, computeValue: { d in
//                        let result = height
//                        if item == items.last { height = 0 }
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
//// --- API Key Input View (Sheet) ---
//struct APIKeyInputView: View {
//    @Environment(\.dismiss) var dismiss
//    @AppStorage("userOpenAIKey") private var apiKey: String = "" // Two-way binding
//    @State private var inputApiKey: String = "" // Local state for the text field
//    @State private var isInvalidKeyAttempt: Bool = false // State for validation feedback
//
//    var onSave: (String) -> Void
//    var onCancel: () -> Void
//
//    var body: some View { /* ... APIKeyInputView implementation (unchanged) ... */
//        NavigationView {
//            VStack(alignment: .leading, spacing: 20) {
//                Text("Enter your OpenAI API Key")
//                    .font(.headline)
//                Text("Your key will be stored securely in UserDefaults on this device. Ensure you are using a key with appropriate permissions.")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//
//                SecureField("sk-...", text: $inputApiKey) // Use SecureField
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 5)
//                            .stroke(isInvalidKeyAttempt ? Color.red : Color.clear, lineWidth: 1)
//                    )
//                    .onChange(of: inputApiKey) { _, _ in
//                         // Reset validation state when user types
//                         isInvalidKeyAttempt = false
//                    }
//
//                if isInvalidKeyAttempt {
//                     Text("API Key cannot be empty.")
//                          .font(.caption)
//                          .foregroundColor(.red)
//                }
//
//                HStack {
//                    Button("Cancel") {
//                        onCancel()
//                        dismiss()
//                    }
//                    .buttonStyle(.bordered)
//
//                    Spacer()
//
//                    Button("Save Key") {
//                         let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
//                         if trimmedKey.isEmpty {
//                             // Show validation error
//                             isInvalidKeyAttempt = true
//                         } else {
//                             apiKey = trimmedKey // Save the valid key to AppStorage
//                             onSave(apiKey)     // Call the callback
//                             dismiss()          // Dismiss the sheet
//                         }
//                    }
//                    .buttonStyle(.borderedProminent)
//                }
//                .padding(.top)
//
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("API Key")
//            .navigationBarTitleDisplayMode(.inline)
//             .onAppear {
//                 // Load existing key into the input field when the view appears
//                 inputApiKey = apiKey
//                 isInvalidKeyAttempt = false // Reset validation on appear
//             }
//        }
//    }
//}
//
//// MARK: - Model Views (Featured Card, Standard Row, Detail)
//
//// --- Featured Model Card View ---
//struct FeaturedModelCard: View {
//    let model: OpenAIModel
//
//    var body: some View { /* ... FeaturedModelCard implementation (unchanged) ... */
//        VStack(alignment: .leading, spacing: 10) {
//            // Placeholder for the gradient background / large icon look
//            RoundedRectangle(cornerRadius: 12)
//                .fill(model.iconBackgroundColor.opacity(0.3)) // Use background color as base
//                .frame(height: 120) // Fixed height for the top area
//                 .overlay(
//                      Image(systemName: model.iconName)
//                           .resizable()
//                           .scaledToFit()
//                           .padding(25)
//                           .foregroundStyle(model.iconBackgroundColor) // Use color for symbol
//                 )
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(model.displayName)
//                    .font(.headline)
//                Text(model.shortDescription) // Use the short description
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                     .lineLimit(2)
//            }
//            .padding([.horizontal, .bottom], 12)
//        }
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
//         .frame(minWidth: 0, maxWidth: .infinity) // Ensure it takes width in HStack
//    }
//}
//
//// --- Standard Model Row View (for Grids) ---
//struct StandardModelRow: View {
//    let model: OpenAIModel
//
//    var body: some View { /* ... StandardModelRow implementation (unchanged) ... */
//        HStack(spacing: 12) {
//            Image(systemName: model.iconName)
//                .resizable()
//                .scaledToFit()
//                .padding(7)
//                .frame(width: 36, height: 36)
//                .background(model.iconBackgroundColor.opacity(0.85))
//                .foregroundStyle(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 8)) // Rounded square icon
//
//            VStack(alignment: .leading, spacing: 3) {
//                Text(model.displayName)
//                    .font(.subheadline.weight(.medium))
//                    .lineLimit(1)
//                Text(model.shortDescription) // Use short description
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .lineLimit(2) // Allow two lines
//            }
//            Spacer(minLength: 0) // Allow Spacer to shrink
//        }
//        .padding(10)
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 10))
//        .overlay(
//            RoundedRectangle(cornerRadius: 10)
//                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
//        )
//         // No shadow for grid items usually
//    }
//}
//
//// --- Reusable Section Header ---
//struct SectionHeader: View {
//    let title: String
//    let subtitle: String?
//
//    var body: some View { /* ... SectionHeader implementation (unchanged) ... */
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title)
//                .font(.title2.weight(.semibold))
//            if let subtitle = subtitle {
//                Text(subtitle)
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding(.bottom, 10) // Space below header
//        .padding(.horizontal) // Standard horizontal padding
//    }
//}
//
//// --- Model Detail View (Enhanced for ChatGPT-4o) ---
//struct ModelDetailView: View {
//    let model: OpenAIModel
//
//    // Determine if this is the specific ChatGPT-4o model (using alias)
//    private var isChatGpt4o: Bool {
//        model.id.lowercased() == "chatgpt-4o-latest"
//    }
//
//    var body: some View {
//        List {
//            // --- Prominent Header ---
//            Section {
//                VStack(spacing: 15) {
//                    Image(systemName: model.iconName).resizable().scaledToFit()
//                        .padding(15).frame(width: 80, height: 80)
//                        .background(model.iconBackgroundColor).foregroundStyle(.white)
//                        .clipShape(Circle())
//                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
//                    Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
//                     // Specific Subtitle/Description for 4o
//                     if isChatGpt4o {
//                         Text(model.shortDescription)
//                             .font(.subheadline)
//                             .foregroundColor(.secondary)
//                             .multilineTextAlignment(.center)
//                             .padding(.horizontal)
//                     }
//                }
//                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
//            }
//            .listRowBackground(Color.clear)
//
//            // --- Standard Overview Section ---
//            Section("Overview") {
//                DetailRow(label: "Full ID", value: model.id)
//                DetailRow(label: "Type", value: model.object)
//                DetailRow(label: "Owner", value: model.ownedBy)
//                DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
//            }
//
//            // --- Enhanced Details for ChatGPT-4o ---
//            Section("Details") {
//                 VStack(alignment: .leading, spacing: 5) {
//                     Text("Description").font(.caption).foregroundColor(.secondary)
//                     Text(model.description) // Use the longer description
//                 }.accessibilityElement(children: .combine)
//
//                 DetailRow(label: "Context Window", value: model.contextWindow)
//
//                 // Add specific 4o details if available
//                 if isChatGpt4o {
//                     if let maxOutput = model.maxOutputTokens {
//                         DetailRow(label: "Max Output Tokens", value: "\(maxOutput.formatted()) tokens")
//                     }
//                     if let cutoff = model.knowledgeCutoff {
//                         DetailRow(label: "Knowledge Cutoff", value: cutoff)
//                     }
//                 }
//            }
//
//            // --- Performance Metrics (Specific to ChatGPT-4o) ---
//            if isChatGpt4o {
//                Section("Performance") {
//                     HStack {
//                         Text("Intelligence").font(.callout).foregroundColor(.secondary)
//                         Spacer()
//                         RatingView(label: "High", rating: model.intelligenceRating ?? 0, maxRating: 3, icon: "bolt.fill")
//                     }
//                      HStack {
//                          Text("Speed").font(.callout).foregroundColor(.secondary)
//                          Spacer()
//                          RatingView(label: "Medium", rating: model.speedRating ?? 0, maxRating: 3, icon: "bolt.fill")
//                      }
//                }
//            }
//
//             // --- Pricing Section (Specific to ChatGPT-4o) ---
//             if isChatGpt4o {
//                 Section("Pricing (per 1M tokens)") {
//                     if let inputPrice = model.priceInputMillions {
//                         DetailRow(label: "Input", value: String(format: "$%.2f", inputPrice))
//                     }
//                      if let outputPrice = model.priceOutputMillions {
//                         DetailRow(label: "Output", value: String(format: "$%.2f", outputPrice))
//                     }
//                     Link("View Pricing Page", destination: URL(string: "https://openai.com/api/pricing/")!)
//                         .font(.callout)
//                 }
//             }
//
//            // --- Modalities Section (Specific to ChatGPT-4o) ---
//            if isChatGpt4o, let modalities = model.modalities, !modalities.isEmpty {
//                 Section("Modalities") {
//                     ForEach(modalities, id: \.self) { modality in
//                         HStack {
//                             Label(modality.name, systemImage: modality.icon)
//                             Spacer()
//                             if modality.input && modality.output { Text("Input & Output").font(.caption).foregroundColor(.secondary) }
//                             else if modality.input { Text("Input Only").font(.caption).foregroundColor(.secondary) }
//                             else if modality.output { Text("Output Only").font(.caption).foregroundColor(.secondary) }
//                             else { Text("Not Supported").font(.caption).foregroundColor(.red) }
//                         }
//                     }
//                 }
//            }
//
//            // --- Endpoints Section (Specific to ChatGPT-4o) ---
//            if isChatGpt4o, let endpoints = model.endpoints, !endpoints.isEmpty {
//                 Section("API Endpoints") {
//                     ForEach(endpoints, id: \.self) { endpoint in
//                         HStack {
//                             Label(endpoint.name, systemImage: endpoint.icon)
//                             Spacer()
//                             Image(systemName: endpoint.supported ? "checkmark.circle.fill" : "xmark.circle.fill")
//                                 .foregroundColor(endpoint.supported ? .green : .red)
//                         }
//                         .foregroundColor(endpoint.supported ? .primary : .secondary) // Dim unsupported
//                     }
//                 }
//            }
//
//            // --- Features Section (Specific to ChatGPT-4o) ---
//            if isChatGpt4o, let features = model.features, !features.isEmpty {
//                 Section("Features") {
//                     ForEach(features, id: \.self) { feature in
//                          HStack {
//                              Label(feature.name, systemImage: feature.icon)
//                             Spacer()
//                             Image(systemName: feature.supported ? "checkmark.circle.fill" : "xmark.circle.fill")
//                                 .foregroundColor(feature.supported ? .green : .red)
//                         }
//                          .foregroundColor(feature.supported ? .primary : .secondary) // Dim unsupported
//                     }
//                 }
//            }
//
//            // --- Capabilities Section (Displays the string array from the model) ---
//            if !model.capabilities.isEmpty && model.capabilities != ["general"] {
//                Section("Base Capabilities") {
//                    WrappingHStack(items: model.capabilities) { capability in
//                        Text(capability)
//                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
//                            .background(Color.accentColor.opacity(0.2))
//                            .foregroundColor(.accentColor).clipShape(Capsule())
//                    }
//                }
//            }
//
//            // --- Typical Use Cases Section (Displays the string array) ---
//            if !model.typicalUseCases.isEmpty && model.typicalUseCases != ["Various tasks"] {
//                 Section("Typical Use Cases") {
//                     ForEach(model.typicalUseCases, id: \.self) { useCase in
//                         Label(useCase, systemImage: "play.rectangle")
//                             .foregroundColor(.primary).imageScale(.small)
//                     }
//                 }
//            }
//
//            // --- Snapshots Section (Specific to ChatGPT-4o) ---
//            if isChatGpt4o, let snapshots = model.snapshots, !snapshots.isEmpty {
//                Section("Snapshots / Aliases") {
//                    ForEach(snapshots, id: \.self) { snapshotId in
//                        Text(snapshotId).font(.callout).foregroundColor(.secondary)
//                    }
//                }
//            }
//        }
//        .listStyle(.insetGrouped)
//        .navigationTitle(model.displayName) // Set title to model name
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//    // Standard Detail Row Helper
//    private func DetailRow(label: String, value: String) -> some View { /* ... DetailRow implementation (unchanged) ... */
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//            Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
//        }
//         .padding(.vertical, 2)
//         .accessibilityElement(children: .combine)
//    }
//
//     // Helper View for Performance Ratings
//     private func RatingView(label: String, rating: Int, maxRating: Int, icon: String) -> some View {
//         HStack(spacing: 2) {
//             ForEach(0..<maxRating, id: \.self) { index in
//                 Image(systemName: icon)
//                     .foregroundColor( index < rating ? .yellow : .gray.opacity(0.4))
//             }
//             Text("(\(label))") // Optionally show label like "High"
//                 .font(.caption)
//                 .foregroundColor(.secondary)
//                 .padding(.leading, 4)
//         }
//     }
//}
//
//// MARK: - Main Content View (Adapted for Sections)
//
//struct OpenAIModelsMasterView: View {
//    // --- State Variables ---
//    @State private var allModels: [OpenAIModel] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String? = nil
//    @State private var useMockData = true // Default to Mock
//    @State private var showingApiKeySheet = false
//    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""
//
//    // --- API Service Instance ---
//    private var currentApiService: APIServiceProtocol {
//        useMockData ? MockAPIService() : LiveAPIService()
//    }
//
//    // --- Grid Layout ---
//    let gridColumns: [GridItem] = [
//        GridItem(.flexible(), spacing: 15),
//        GridItem(.flexible(), spacing: 15)
//    ]
//
//    // --- Filters for Sections (Based on Model IDs) ---
//    // Updated filters to potentially place 'chatgpt-4o-latest' in flagship chat
//    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "o4-mini", "o3"].contains($0.id) }.sortedById() }
//    var reasoningModels: [OpenAIModel] { allModels.filter { ["o4-mini", "o3", "o3-mini", "o1", "o1-pro", "o1-mini"].contains($0.id) }.sortedById() }
//    var flagshipChatModels: [OpenAIModel] { allModels.filter { $0.id.contains("gpt-4.1") || $0.id.contains("gpt-4o")}.sortedById() } // Capture 4o variants here
//    var costOptimizedModels: [OpenAIModel] { allModels.filter { ["o4-mini", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o-mini", "gpt-4o-mini-audio", "o1-mini"].contains($0.id) }.sortedById() }
//    var realtimeModels: [OpenAIModel] { allModels.filter { $0.id.contains("realtime") }.sortedById() }
//    var olderGptModels: [OpenAIModel] { allModels.filter { ["gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"].contains($0.id) && !$0.id.contains("4o")}.sortedById() } // Exclude 4o here
//    var dalleModels: [OpenAIModel] { allModels.filter { $0.id.contains("dall-e") }.sortedById() }
//    var ttsModels: [OpenAIModel] { allModels.filter { $0.id.contains("tts") }.sortedById() }
//    var transcriptionModels: [OpenAIModel] { allModels.filter { $0.id.contains("whisper") || $0.id.contains("transcribe") }.sortedById() }
//    var embeddingsModels: [OpenAIModel] { allModels.filter { $0.id.contains("embedding") }.sortedById() }
//    var moderationModels: [OpenAIModel] { allModels.filter { $0.id.contains("moderation") }.sortedById() }
//    var toolSpecificModels: [OpenAIModel] { allModels.filter { $0.id.contains("search") || $0.id.contains("computer-use") }.sortedById() }
//
//    var body: some View { /* ... Main View Body (`NavigationStack`, `ZStack`, `ScrollView`, section logic) remains largely unchanged from previous state ... */
//        NavigationStack {
//            ZStack { // Keep ZStack for overlaying ProgressView/ErrorView
//                // --- Conditional Content Display ---
//                if isLoading && allModels.isEmpty {
//                     ProgressView("Fetching Models...")//.scaleEffect(1.5)
//                           .frame(maxWidth: .infinity, maxHeight: .infinity)
//                           .background(Color(.systemBackground)) // Ensure it covers content
//                           .zIndex(1) // Make sure it's on top
//                 } else if let errorMessage = errorMessage, allModels.isEmpty {
//                     ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
//                 } else {
//                    // --- Main Scrollable Content ---
//                    ScrollView(.vertical, showsIndicators: false) {
//                        VStack(alignment: .leading, spacing: 30) { // Main container for sections
//
//                             // --- Header Text (Mimics website) ---
//                             VStack(alignment: .leading, spacing: 5) {
//                                 Text("Models")
//                                     .font(.largeTitle.weight(.bold))
//                                 Text("Explore all available models and compare their capabilities.")
//                                     .font(.title3)
//                                     .foregroundColor(.secondary)
//                             }
//                             .padding(.horizontal)
//
//                             Divider().padding(.horizontal)
//
//                             // --- Featured Models Section ---
//                             SectionHeader(title: "Featured models", subtitle: nil)
//                             ScrollView(.horizontal, showsIndicators: false) {
//                                 HStack(spacing: 15) {
//                                     ForEach(featuredModels) { model in
//                                         NavigationLink(value: model) {
//                                             FeaturedModelCard(model: model)
//                                                 .frame(width: 250) // Fixed width for horizontal scroll
//                                         }
//                                         .buttonStyle(.plain) // Remove link styling
//                                     }
//                                 }
//                                 .padding(.horizontal) // Padding for HStack content
//                                 .padding(.bottom, 5) // Space after horizontal scroll
//                             }
//
//                             // --- Standard Sections with Grid ---
//                             // Use displaySection helper
//                             displaySection(title: "Flagship chat models", subtitle: "Our versatile, high-intelligence flagship models.", models: flagshipChatModels)
//                             displaySection(title: "Reasoning models", subtitle: "o-series models that excel at complex, multi-step tasks.", models: reasoningModels)
//                             displaySection(title: "Cost-optimized models", subtitle: "Smaller, faster models that cost less to run.", models: costOptimizedModels)
//                             displaySection(title: "Realtime models", subtitle: "Models capable of realtime text and audio inputs and outputs.", models: realtimeModels)
//                             displaySection(title: "Older GPT models", subtitle: "Supported older versions of our general purpose and chat models.", models: olderGptModels)
//                             displaySection(title: "DALL·E", subtitle: "Models that can generate and edit images, given a natural language prompt.", models: dalleModels)
//                             displaySection(title: "Text-to-speech", subtitle: "Models that can convert text into natural sounding spoken audio.", models: ttsModels)
//                             displaySection(title: "Transcription", subtitle: "Model that can transcribe and translate audio into text.", models: transcriptionModels)
//                             displaySection(title: "Embeddings", subtitle: "A set of models that can convert text into vector representations.", models: embeddingsModels)
//                             displaySection(title: "Moderation", subtitle: "Fine-tuned models that detect whether input may be sensitive or unsafe.", models: moderationModels)
//                             displaySection(title: "Tool-specific models", subtitle: "Models to support specific built-in tools.", models: toolSpecificModels)
//
//                             Spacer(minLength: 50) // Add space at the bottom
//
//                        } // End Main VStack
//                        .padding(.top) // Padding at the top of the scroll view
//                    } // End ScrollView
//                    .background(Color(.systemGroupedBackground)) // List background color
//                    .edgesIgnoringSafeArea(.bottom) // Allow content to go to bottom edge
//                 }
//            } // End ZStack
//            .navigationTitle("OpenAI Models")
//            .navigationBarTitleDisplayMode(.inline) // Use inline to match web simpler header
//            .toolbar { /* --- Toolbar remains unchanged --- */
//                 // --- Refresh/Loading Indicator ---
//                 ToolbarItem(placement: .navigationBarLeading) {
//                     if isLoading { ProgressView().controlSize(.small) }
//                     else {
//                         Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
//                         .disabled(isLoading)
//                     }
//                 }
//                 // --- Toggle API Source Button ---
//                 ToolbarItem(placement: .navigationBarTrailing) {
//                     Menu {
//                         Toggle(isOn: $useMockData) {
//                             Text(useMockData ? "Using Mock Data" : "Using Live API")
//                         }
//                     } label: {
//                         Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill")
//                           .foregroundColor(useMockData ? .secondary : .blue)
//                     }
//                     .disabled(isLoading)
//                 }
//             }
//             // --- Navigation Destination (Uses the updated ModelDetailView) ---
//             .navigationDestination(for: OpenAIModel.self) { model in
//                 ModelDetailView(model: model) // This now shows detailed 4o info conditionally
//                       .toolbarBackground(.visible, for: .navigationBar)
//                       .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
//             }
//             // --- Initial Load & API Key Sheet Logic (Unchanged) ---
//             .task {
//                  if allModels.isEmpty { attemptLoadModels() }
//             }
//             .refreshable { await loadModelsAsync(checkApiKey: false) } // Don't re-prompt on pull-to-refresh
//             .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
//             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
//             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: {
//                 Button("OK") { errorMessage = nil }
//             }, message: { Text(errorMessage ?? "An unknown error occurred.") })
//
//        } // End NavigationStack
//    }
//
//    // --- Helper View Builder for Sections (Unchanged) ---
//    @ViewBuilder
//    private func displaySection(title: String, subtitle: String?, models: [OpenAIModel]) -> some View {
//         if !models.isEmpty {
//             Divider().padding(.horizontal)
//             SectionHeader(title: title, subtitle: subtitle)
//             LazyVGrid(columns: gridColumns, spacing: 15) {
//                 ForEach(models) { model in
//                     NavigationLink(value: model) {
//                         StandardModelRow(model: model)
//                     }
//                     .buttonStyle(.plain) // Remove link styling
//                 }
//             }
//             .padding(.horizontal)
//         } else {
//             // EmptyView() // Don't show empty sections
//         }
//    }
//
//    // --- Helper Functions for Loading & API Key Handling (Unchanged) ---
//    private func handleToggleChange(to newValue: Bool) { /* ... Unchanged ... */
//        print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
//        allModels = []
//        errorMessage = nil
//        if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            showingApiKeySheet = true
//        } else {
//            loadModelsAsyncWithLoadingState()
//        }
//    }
//
//    private func presentApiKeySheet() -> some View { /* ... Unchanged ... */
//        APIKeyInputView(
//            onSave: { _ in
//                print("API Key saved.")
//                loadModelsAsyncWithLoadingState()
//            },
//            onCancel: {
//                print("API Key input cancelled.")
//                useMockData = true // Revert toggle
//            }
//        )
//    }
//
//    private func attemptLoadModels() { /* ... Unchanged ... */
//        guard !isLoading else { return }
//        if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            showingApiKeySheet = true
//        } else {
//            loadModelsAsyncWithLoadingState()
//        }
//    }
//
//    private func loadModelsAsyncWithLoadingState() { /* ... Unchanged ... */
//        guard !isLoading else { return }
//        isLoading = true
//        errorMessage = nil // Clear previous errors on new load attempt
//        allModels = []     // Clear models on new load attempt
//        Task { await loadModelsAsync(checkApiKey: false) }
//    }
//
//    @MainActor
//    private func loadModelsAsync(checkApiKey: Bool) async { /* ... Unchanged (except print statements maybe cleared) ... */
//         if !isLoading { isLoading = true } // Ensure flag is set if called directly
//         if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//             showingApiKeySheet = true; isLoading = false; return
//         }
//         let serviceToUse = currentApiService
//         print("🔄 Loading models using \(useMockData ? "MockAPIService" : "LiveAPIService")...")
//         do {
//             let fetchedModels = try await serviceToUse.fetchModels()
//             self.allModels = fetchedModels.sorted { // Sort fetched models here for consistency
//                  $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending
//              }
//             self.errorMessage = nil
//             print("✅ Successfully loaded \(fetchedModels.count) models.")
//         } catch let error as LocalizedError {
//             print("❌ Error loading models: \(error.localizedDescription)")
//             self.errorMessage = error.localizedDescription
//             self.allModels = [] // Ensure models are cleared on error
//         } catch {
//             print("❌ Unexpected error loading models: \(error)")
//             self.errorMessage = "Unexpected error: \(error.localizedDescription)"
//             self.allModels = [] // Ensure models are cleared on error
//         }
//         isLoading = false
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
//#Preview("Main View (Mock Data)") {
//    OpenAIModelsMasterView()
//}
//
////#Preview("Detail View (ChatGPT-4o)") {
////    // Find the specific model from the mock data
////    let mockService = MockAPIService()
////    let mockModels = try? await mockService.fetchModels()
////    let chatGpt4oModel = mockModels?.first(where: { $0.id == "chatgpt-4o-latest" })
////                    ?? OpenAIModel(id: "preview-4o", object: "model", created: 1, ownedBy: "preview", description: "Preview Model") // Fallback
////
////    NavigationStack { ModelDetailView(model: chatGpt4oModel) }
////}
////
////#Preview("Detail View (Other Model)") {
////    // Find a different model to show the non-4o detail view
////    let mockService = MockAPIService()
////    let mockModels = try? await mockService.fetchModels()
////    let otherModel = mockModels?.first(where: { $0.id == "dall-e-3" })
////                     ?? OpenAIModel(id: "preview-dalle", object: "model", created: 1, ownedBy: "preview", description: "Preview DALL-E") // Fallback
////
////    NavigationStack { ModelDetailView(model: otherModel) }
////}
//
//#Preview("API Key Input Sheet") {
//    struct SheetPresenter: View {
//        @State var showSheet = true
//        var body: some View {
//            Text("Tap to show sheet (already shown)")
//                .sheet(isPresented: $showSheet) {
//                    APIKeyInputView(onSave: {_ in}, onCancel: {})
//                }
//        }
//    }
//    return SheetPresenter()
//}
