//
//  gpt-4o-mini-tts.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  OpenAIModelsMasterView.swift
//  Alchemy_Models_Combined
//  (Single File Implementation)
//
//  Created: Cong Le
//  Date: 4/13/25 (Based on previous iterations)
//  Version: 1.2 (Incorporated gpt-4o-mini-tts details)
//  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
//  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
//

import SwiftUI
import Foundation // Needed for URLSession, URLRequest, etc.
import Combine // Needed for @StateObject if using ObservableObject later

// MARK: - Enums (Sorting, Errors)

enum SortOption: String, CaseIterable, Identifiable {
    case idAscending = "ID (A-Z)"
    case idDescending = "ID (Z-A)"
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    var id: String { self.rawValue }
}

enum MockError: Error, LocalizedError {
     case simulatedFetchError
     var errorDescription: String? {
         switch self {
         case .simulatedFetchError: return "Simulated network error: Could not fetch models."
         }
     }
}

enum LiveAPIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case missingAPIKey
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The API endpoint URL is invalid."
        case .requestFailed(let sc): return "API request failed with status code \(sc)."
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .decodingError(let err): return "Failed to decode API response: \(err.localizedDescription)"
        case .missingAPIKey: return "OpenAI API Key is missing or invalid. Please provide a valid key."
        }
    }
}

// MARK: - API Service Protocol

protocol APIServiceProtocol {
    func fetchModels() async throws -> [OpenAIModel]
}

// MARK: - Data Models

struct ModelListResponse: Codable {
    let data: [OpenAIModel]
}

struct OpenAIModel: Codable, Identifiable, Hashable {
    let id: String
    let object: String
    let created: Int // Unix timestamp
    let ownedBy: String

    // --- Default values for fields that might be missing in basic /v1/models response ---
    // These help maintain consistency between detailed mock data and live data.
    var description: String = "No description available."
    var shortDescription: String = "General purpose model." // Updated default
    var capabilities: [String] = ["general"]
    var contextWindow: String = "N/A"
    // Updated default use cases to better represent various task types
    var typicalUseCases: [String] = ["Varies"]

    // Specific fields added based on screenshots, with defaults
    var performanceRating: Int = 2 // Default out of 4
    var speedRating: Int = 2 // Default out of 4
    var inputModalities: [String] = ["text"] // Default
    var outputModalities: [String] = ["text"] // Default
    var endpoints: [String] = ["N/A"] // Supported endpoints
    var pricingInput: String = "N/A" // Pricing per 1M input tokens/units
    var pricingOutput: String = "N/A" // Pricing per 1M output tokens/units

    // --- Codable Conformance ---
    enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case ownedBy = "owned_by"
        // IMPORTANT: description, shortDescription, capabilities, contextWindow, typicalUseCases,
        // performanceRating, speedRating, inputModalities, outputModalities, endpoints,
        // pricingInput, pricingOutput are NOT listed here.
        // Codable will ignore them during JSON decoding if they aren't present,
        // allowing the default values above to be used. Mock data can override these.
    }

    // --- Computed Properties & Hashable ---
    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: OpenAIModel, rhs: OpenAIModel) -> Bool { lhs.id == rhs.id }
}

// MARK: - Model Extension for UI Logic

extension OpenAIModel {
    // --- Determine SF Symbol name based on ID or owner ---
    var iconName: String {
        let normalizedId = id.lowercased()
        // Map specific IDs from screenshots to SF Symbols (or placeholders)
        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") || normalizedId.contains("chatgpt-4o") { return "sparkles" }
        if normalizedId.contains("o4-mini") || normalizedId.contains("o3-mini") || normalizedId.contains("o1-mini") || normalizedId.contains("gpt-4.1-mini") || normalizedId.contains("gpt-4o-mini") { return "leaf.fill" } // Grouped minis
        if normalizedId.contains("o3") { return "circle.hexagonpath.fill" } // Placeholder
        if normalizedId.contains("o1") || normalizedId.contains("o1-pro") { return "circles.hexagonpath.fill" } // Placeholder
        if normalizedId.contains("gpt-4-turbo") { return "bolt.fill" }
        if normalizedId.contains("gpt-4") && !normalizedId.contains("turbo") { return "star.fill"}
        if normalizedId.contains("gpt-3.5") { return "forward.fill" } // Placeholder for legacy
        if normalizedId.contains("dall-e") { return "paintbrush.pointed.fill" }
        // Specific TTS logic
        if normalizedId == "gpt-4o-mini-tts" || normalizedId == "tts-1-hd" { return "speaker.wave.3.fill" } // Higher quality/newer TTS
        if normalizedId.contains("tts") { return "speaker.wave.2.fill" } // General TTS
        if normalizedId.contains("transcribe") || normalizedId.contains("whisper") { return "waveform" }
        if normalizedId.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" } // Placeholder
        if normalizedId.contains("moderation") { return "exclamationmark.shield.fill" }
        if normalizedId.contains("search") { return "magnifyingglass"}
        if normalizedId.contains("computer-use") { return "computermouse.fill" }

        // Fallback based on owner
        let lowerOwner = ownedBy.lowercased()
        if lowerOwner.contains("openai") { return "building.columns.fill" }
        if lowerOwner == "system" { return "gearshape.fill" }
        if lowerOwner.contains("user") || lowerOwner.contains("org") { return "person.crop.circle.fill" }
        return "questionmark.circle.fill" // Default/fallback
    }

    // --- Determine background color for icons ---
    var iconBackgroundColor: Color {
        let normalizedId = id.lowercased()
        // Map specific IDs to colors
        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") { return .blue }
        if normalizedId.contains("o4-mini") || normalizedId.contains("gpt-4o-mini") { return .purple } // Also purple for gpt-4o-mini
        if normalizedId.contains("o3") { return .orange }
        if normalizedId.contains("dall-e") { return .teal }
        // Specific TTS Logic
        if normalizedId == "gpt-4o-mini-tts" { return .purple.opacity(0.9) } // Purple for gpt-4o-mini-tts
        if normalizedId.contains("tts") { return .indigo } // General TTS
        if normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return .pink }
        if normalizedId.contains("embedding") { return .green }
        if normalizedId.contains("moderation") { return .red }
        if normalizedId.contains("search") { return .cyan }
        if normalizedId.contains("computer-use") { return .brown }

        // Fallback based on owner
        let lowerOwner = ownedBy.lowercased()
        if lowerOwner.contains("openai") { return .blue.opacity(0.8) }
        if lowerOwner == "system" { return .orange.opacity(0.8) }
        if lowerOwner.contains("user") || lowerOwner.contains("org") { return .purple.opacity(0.8) }
        return .gray.opacity(0.7) // Default/fallback
    }

    // --- Simplified name for display ---
    var displayName: String {
        // Specific mapping for gpt-4o-mini-tts
        if id == "gpt-4o-mini-tts" { return "GPT-4o mini TTS" }

        // General replacement logic
        return id.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

// MARK: - API Service Implementations

// --- Mock Data Service ---
class MockAPIService: APIServiceProtocol {
    private let mockNetworkDelaySeconds: Double = 0.8

    // Enhanced mock models based on screenshots and specific request
    func generateMockModels() -> [OpenAIModel] {
        return [
            // Featured
            OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", shortDescription: "Flagship GPT model for complex tasks", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k", typicalUseCases: ["Complex reasoning", "Creative writing", "Code generation", "Visual analysis"], performanceRating: 4, speedRating: 3, inputModalities: ["text", "image"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", shortDescription: "Faster, more affordable reasoning model", capabilities: ["text generation", "reasoning"], contextWindow: "128k", typicalUseCases: ["Summarization", "Data extraction", "Standard chat"], performanceRating: 3, speedRating: 4, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", shortDescription: "Our most powerful reasoning model", capabilities: ["text generation", "reasoning", "code"], contextWindow: "16k", typicalUseCases: ["Complex reasoning (previous gen)", "Code generation"], performanceRating: 3, speedRating: 2, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),

            // Reasoning Models
            OpenAIModel(id: "o3-mini", object: "model", created: 1699000000, ownedBy: "openai", description: "A smaller, faster, and more affordable alternative to o3.", shortDescription: "A small model alternative to o3", capabilities: ["text generation", "reasoning"], contextWindow: "16k", typicalUseCases: ["Standard chat (previous gen)", "Summarization"], performanceRating: 2, speedRating: 3, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", shortDescription: "Previous full o-series reasoning model", capabilities: ["text generation", "reasoning"], contextWindow: "8k", typicalUseCases: ["Basic reasoning", "Legacy applications"], performanceRating: 2, speedRating: 1, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "o1-pro", object: "model", created: 1685000000, ownedBy: "openai", description: "Version of o1 with more compute for better responses.", shortDescription: "Version of o1 with more compute", capabilities: ["text generation", "reasoning"], contextWindow: "8k", typicalUseCases: ["Enhanced legacy applications"], performanceRating: 2, speedRating: 1, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "o1-mini", object: "model", created: 1675000000, ownedBy: "openai", description: "A small model alternative to o1, very fast.", shortDescription: "A small model alternative to o1", capabilities: ["text generation", "reasoning"], contextWindow: "8k", typicalUseCases: ["Simple tasks", "Fast completion"], performanceRating: 1, speedRating: 4, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),

            // Flagship Chat Models
            OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model.", shortDescription: "Fast, intelligent, flexible GPT model", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", typicalUseCases: ["Advanced chat", "Vision queries", "Audio understanding"], performanceRating: 4, speedRating: 4, inputModalities: ["text", "image"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "gpt-4o-audio", object: "model", created: 1712850000, ownedBy: "openai", description: "GPT-4o models capable of audio inputs and outputs.", shortDescription: "GPT-4o models capable of audio inputs", capabilities: ["audio processing", "text generation"], contextWindow: "128k", typicalUseCases: ["Audio interaction", "Voice assistance"], performanceRating: 4, speedRating: 4, inputModalities: ["audio (preview)", "text"], outputModalities: ["audio (preview)", "text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "chatgpt-4o-latest", object: "model", created: 1712900000, ownedBy: "openai", description: "GPT-4o model used in ChatGPT.", shortDescription: "GPT-4o model used in ChatGPT", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", typicalUseCases: ["General chat & assistants", "Integration with ChatGPT features"], performanceRating: 4, speedRating: 4, inputModalities: ["text", "image"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),

            // Cost-optimized Models
            OpenAIModel(id: "gpt-4.1-mini", object: "model", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", shortDescription: "Balanced for intelligence, speed, cost", capabilities: ["text generation", "reasoning"], contextWindow: "128k", typicalUseCases: ["Moderately complex tasks", "Cost-sensitive apps"], performanceRating: 3, speedRating: 4, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", shortDescription: "Fastest, most cost-effective GPT-4.1", capabilities: ["text generation"], contextWindow: "128k", typicalUseCases: ["Simple completion", "High-volume tasks"], performanceRating: 2, speedRating: 4, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "gpt-4o-mini", object: "model", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", shortDescription: "Fast, affordable small model", capabilities: ["text generation"], contextWindow: "128k", typicalUseCases: ["Routing", "Classification", "Simple chat"], performanceRating: 3, speedRating: 4, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "gpt-4o-mini-audio", object: "model", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", shortDescription: "Smaller model capable of audio inputs", capabilities: ["audio processing", "text generation"], contextWindow: "128k", typicalUseCases: ["Basic voice interaction"], performanceRating: 3, speedRating: 4, inputModalities: ["audio (preview)", "text"], outputModalities: ["audio (preview)", "text"], endpoints: ["v1/chat/completions"]),

            // Realtime Models
            OpenAIModel(id: "gpt-4o-realtime", object: "model", created: 1712860000, ownedBy: "openai", description: "Model capable of realtime text and audio inputs and outputs.", shortDescription: "Model capable of realtime text/audio", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", typicalUseCases: ["Realtime voice assistance", "Live interaction"], performanceRating: 4, speedRating: 4, inputModalities: ["audio (realtime)", "text (realtime)"], outputModalities: ["audio (realtime)", "text (realtime)"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "gpt-4o-mini-realtime", object: "model", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", shortDescription: "Smaller realtime model for text/audio", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", typicalUseCases: ["Cost-effective realtime interaction"], performanceRating: 3, speedRating: 4, inputModalities: ["audio (realtime)", "text (realtime)"], outputModalities: ["audio (realtime)", "text (realtime)"], endpoints: ["v1/chat/completions"]),

            // Older GPT Models
            OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", shortDescription: "An older high-intelligence GPT model", capabilities: ["text generation", "reasoning", "code"], contextWindow: "128k", typicalUseCases: ["Legacy high-intelligence tasks"], performanceRating: 3, speedRating: 2, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "gpt-4", object: "model", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", shortDescription: "An older high-intelligence GPT model", capabilities: ["text generation", "reasoning", "code"], contextWindow: "8k / 32k", typicalUseCases: ["Legacy high-intelligence tasks"], performanceRating: 3, speedRating: 1, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),
            OpenAIModel(id: "gpt-3.5-turbo", object: "model", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", shortDescription: "Legacy GPT model for cheaper tasks", capabilities: ["text generation"], contextWindow: "4k / 16k", typicalUseCases: ["Basic chat", "Cost-effective completion"], performanceRating: 2, speedRating: 3, inputModalities: ["text"], outputModalities: ["text"], endpoints: ["v1/chat/completions"]),

            // DALL-E Models
            OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", shortDescription: "Our latest image generation model", capabilities: ["image generation"], contextWindow: "N/A", typicalUseCases: ["High-quality creative images", "Image editing"], performanceRating: 4, speedRating: 3, inputModalities: ["text"], outputModalities: ["image"], endpoints: ["v1/images/generations"]),
            OpenAIModel(id: "dall-e-2", object: "model", created: 1650000000, ownedBy: "openai", description: "Our first image generation model.", shortDescription: "Our first image generation model", capabilities: ["image generation"], contextWindow: "N/A", typicalUseCases: ["Basic image generation", "Variations"], performanceRating: 3, speedRating: 2, inputModalities: ["text"], outputModalities: ["image"], endpoints: ["v1/images/generations"]),

            // Text-to-speech Models (Including gpt-4o-mini-tts)
            // ** NEW Entry based on Screenshots **
            OpenAIModel(
                id: "gpt-4o-mini-tts",
                object: "model",
                created: 1712370000, // Estimated date
                ownedBy: "openai",
                description: "GPT-4o mini TTS is a text-to-speech model built on GPT-4o mini, a fast and powerful language model. Use it to convert text to natural sounding spoken text. Supports various voices. Maximum input tokens: 2000.",
                shortDescription: "Text-to-speech powered by GPT-4o mini",
                capabilities: ["tts", "text-to-speech"], // Explicit capabilities
                contextWindow: "2000 tokens", // Max input tokens
                typicalUseCases: ["Voiceovers", "Reading assistance", "Audio content creation"],
                performanceRating: 3, // Estimated "Higher"
                speedRating: 4, // "Fast"
                inputModalities: ["text"], // Text input only
                outputModalities: ["audio"], // Audio output only
                endpoints: ["v1/audio/speech"], // Only speech endpoint
                pricingInput: "$0.60 / 1M tokens", // Text token input cost
                pricingOutput: "$12.00 / 1M tokens" // Audio token (?) output cost
            ),
            OpenAIModel(id: "tts-1", object: "model", created: 1690000000, ownedBy: "openai", description: "Text-to-speech model optimized for speed.", shortDescription: "Text-to-speech model optimized for speed", capabilities: ["tts"], contextWindow: "N/A", typicalUseCases: ["Realtime TTS", "Low-latency audio"], performanceRating: 2, speedRating: 4, inputModalities: ["text"], outputModalities: ["audio"], endpoints: ["v1/audio/speech"]),
            OpenAIModel(id: "tts-1-hd", object: "model", created: 1695000000, ownedBy: "openai", description: "Text-to-speech model optimized for quality.", shortDescription: "Text-to-speech model optimized for quality", capabilities: ["tts-hd"], contextWindow: "N/A", typicalUseCases: ["High-fidelity audio", "Professional voiceovers"], performanceRating: 3, speedRating: 3, inputModalities: ["text"], outputModalities: ["audio"], endpoints: ["v1/audio/speech"]),

            // Transcription Models
            OpenAIModel(id: "whisper-1", object: "model", created: 1677600000, ownedBy: "openai", description: "General-purpose speech recognition model.", shortDescription: "General-purpose speech recognition", capabilities: ["audio transcription", "translation"], contextWindow: "N/A", typicalUseCases: ["Meeting transcription", "Voice notes", "Audio translation"], performanceRating: 4, speedRating: 3, inputModalities: ["audio"], outputModalities: ["text"], endpoints: ["v1/audio/transcriptions", "v1/audio/translations"]),
            OpenAIModel(id: "gpt-4o-transcribe", object: "model", created: 1712870000, ownedBy: "openai", description: "Speech-to-text model powered by GPT-4o.", shortDescription: "Speech-to-text powered by GPT-4o", capabilities: ["audio transcription"], contextWindow: "N/A", typicalUseCases: ["Advanced transcription"], performanceRating: 4, speedRating: 4, inputModalities: ["audio"], outputModalities: ["text"], endpoints: ["v1/audio/transcriptions"]),
            OpenAIModel(id: "gpt-4o-mini-transcribe", object: "model", created: 1712380000, ownedBy: "openai", description: "Speech-to-text model powered by GPT-4o mini.", shortDescription: "Speech-to-text powered by GPT-4o mini", capabilities: ["audio transcription"], contextWindow: "N/A", typicalUseCases: ["Cost-effective transcription"], performanceRating: 3, speedRating: 4, inputModalities: ["audio"], outputModalities: ["text"], endpoints: ["v1/audio/transcriptions"]),

            // Embeddings Models
            OpenAIModel(id: "text-embedding-3-small", object: "model", created: 1711200000, ownedBy: "openai", description: "Small embedding model.", shortDescription: "Small embedding model", capabilities: ["text embedding"], contextWindow: "8k", typicalUseCases: ["Retrieval Augmented Generation (RAG)", "Clustering", "Classification"], performanceRating: 3, speedRating: 4, pricingInput: "$0.02 / 1M tokens"),
            OpenAIModel(id: "text-embedding-3-large", object: "model", created: 1711300000, ownedBy: "openai", description: "Most capable embedding model.", shortDescription: "Most capable embedding model", capabilities: ["text embedding"], contextWindow: "8k", typicalUseCases: ["High-accuracy RAG", "Complex clustering"], performanceRating: 4, speedRating: 3, pricingInput: "$0.13 / 1M tokens"),
            OpenAIModel(id: "text-embedding-ada-002", object: "model", created: 1670000000, ownedBy: "openai", description: "Older embedding model.", shortDescription: "Older embedding model", capabilities: ["text embedding"], contextWindow: "8k", typicalUseCases: ["Legacy embedding tasks"], performanceRating: 2, speedRating: 3, pricingInput: "$0.10 / 1M tokens"),

            // Moderation Models
            OpenAIModel(id: "text-moderation-latest", object: "model", created: 1688000000, ownedBy: "openai", description: "Latest text-only moderation model.", shortDescription: "Latest text moderation", capabilities: ["content filtering"], contextWindow: "N/A", typicalUseCases: ["Content safety checks"], endpoints: ["v1/moderations"]),
            OpenAIModel(id: "omni-moderation", object: "model", created: 1712880000, ownedBy: "openai", description: "Identify potentially harmful content in text and images.", shortDescription: "Identify potentially harmful content", capabilities: ["content filtering", "image moderation"], contextWindow: "N/A", typicalUseCases: ["Multimodal content safety"], inputModalities: ["text", "image"], endpoints: ["v1/moderations"]),

            // Tool-specific Models (Assuming IDs based on names)
            OpenAIModel(id: "gpt-4o-search-preview", object: "model", created: 1712890000, ownedBy: "openai", description: "GPT model for web search in Chat Completions.", shortDescription: "GPT model for web search", capabilities: ["search", "text generation"], contextWindow: "128k", typicalUseCases: ["Answering questions with web context"], endpoints: ["v1/chat/completions (with tool use)"]),
            OpenAIModel(id: "gpt-4o-mini-search-preview", object: "model", created: 1712390000, ownedBy: "openai", description: "Fast, affordable small model for web search.", shortDescription: "Fast, affordable small model for search", capabilities: ["search", "text generation"], contextWindow: "128k", typicalUseCases: ["Cost-effective web-grounded answers"], endpoints: ["v1/chat/completions (with tool use)"]),
            OpenAIModel(id: "computer-use-preview", object: "model", created: 1712910000, ownedBy: "openai", description: "Specialized model for computer use tool.", shortDescription: "Specialized model for computer use tool", capabilities: ["tool-use", "computer control"], contextWindow: "N/A", typicalUseCases: ["Agentic tasks", "UI automation (preview)"], endpoints: ["Specific tool endpoints (preview)"]) // Placeholder endpoint
        ]
    }

    func fetchModels() async throws -> [OpenAIModel] {
         try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
         return generateMockModels()
         // throw MockError.simulatedFetchError // Uncomment to test error state
    }
}

// --- Live Data Service ---
class LiveAPIService: APIServiceProtocol {
    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""
    private let modelsURL = URL(string: "https://api.openai.com/v1/models")!

    func fetchModels() async throws -> [OpenAIModel] {
        let currentKey = storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentKey.isEmpty else { throw LiveAPIError.missingAPIKey }

        var request = URLRequest(url: modelsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(currentKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        print("🚀 Making live API request to: \(modelsURL)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw LiveAPIError.requestFailed(statusCode: 0) }
            print("✅ Received API response with status code: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 401 { throw LiveAPIError.missingAPIKey }
            guard (200...299).contains(httpResponse.statusCode) else { throw LiveAPIError.requestFailed(statusCode: httpResponse.statusCode) }

            do {
                 let decoder = JSONDecoder()
                 // Handle the response structure which has a 'data' key
                 let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
                 print("✅ Successfully decoded \(responseWrapper.data.count) models.")
                 // Map the response to include default shortDescription and potentially other fields if needed
                 return responseWrapper.data.map { model in
                     var mutableModel = model
                     // If API doesn't provide shortDescription, generate a basic default one
                     if mutableModel.shortDescription == "General purpose model." { // Check default value
                         mutableModel.shortDescription = model.ownedBy.contains("openai") ? "Official OpenAI model." : "User/system model."
                     }
                     // Add logic here if live API *might* return other fields we want defaults for
                     // Example: If API could return an empty capabilities array
                     if mutableModel.capabilities.isEmpty {
                        mutableModel.capabilities = ["general"]
                     }
                     // Add specific checks for gpt-4o-mini-tts defaults if needed, although
                     // the mock data provides the current source of truth for these details.
                     if model.id == "gpt-4o-mini-tts" {
                         if mutableModel.contextWindow == "N/A" { mutableModel.contextWindow = "2000 tokens" }
                         if mutableModel.endpoints == ["N/A"] { mutableModel.endpoints = ["v1/audio/speech"] }
                         if mutableModel.inputModalities == ["text"] && model.outputModalities == ["text"] { // Default check
                            mutableModel.inputModalities = ["text"]
                            mutableModel.outputModalities = ["audio"]
                         }
                     }

                     return mutableModel
                 }
            } catch {
                 print("❌ Decoding Error: \(error)")
                 print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Could not decode data")")
                 throw LiveAPIError.decodingError(error)
            }
        } catch let error as LiveAPIError { throw error }
          catch { throw LiveAPIError.networkError(error) }
    }
}

// MARK: - Reusable SwiftUI Helper Views (Error, WrappingHStack, APIKeyInputView)

struct ErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void
    var body: some View { /* ... Error view implementation (unchanged) ... */
        VStack(alignment: .center, spacing: 15) {
            Image(systemName: "wifi.exclamationmark")
                .resizable().scaledToFit().frame(width: 60, height: 60)
                .foregroundColor(.red)
            VStack(spacing: 5) {
                Text("Loading Failed").font(.title3.weight(.medium))
                Text(errorMessage).font(.callout).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            Button { retryAction() } label: { Label("Retry", systemImage: "arrow.clockwise") }
            .buttonStyle(.borderedProminent).controlSize(.regular).padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding().background(Color(.systemGroupedBackground))
    }
}

struct WrappingHStack<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    let viewForItem: (Item) -> ItemView
    let horizontalSpacing: CGFloat = 8
    let verticalSpacing: CGFloat = 8
    @State private var totalHeight: CGFloat = .zero
    var body: some View { /* ... WrappingHStack implementation (unchanged) ... */
        VStack {
            GeometryReader { geometry in self.generateContent(in: geometry) }
        }
        .frame(height: totalHeight)
    }
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(self.items, id: \.self) { item in
                self.viewForItem(item)
                    .padding(.horizontal, horizontalSpacing / 2)
                    .padding(.vertical, verticalSpacing / 2)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0; height -= d.height + verticalSpacing
                        }
                        let result = width
                        if item == self.items.last { width = 0 } else { width -= d.width }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if item == self.items.last { height = 0 }
                        return result
                    })
            }
        }.background(viewHeightReader($totalHeight))
    }
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async { binding.wrappedValue = rect.size.height }
            return .clear
        }
    }
}

// --- API Key Input View (Sheet) ---
struct APIKeyInputView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("userOpenAIKey") private var apiKey: String = "" // Two-way binding
    @State private var inputApiKey: String = "" // Local state for the text field
    @State private var isInvalidKeyAttempt: Bool = false // State for validation feedback

    var onSave: (String) -> Void
    var onCancel: () -> Void

    var body: some View { /* ... APIKeyInputView implementation (unchanged) ... */
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter your OpenAI API Key")
                    .font(.headline)
                Text("Your key will be stored securely in UserDefaults on this device. Ensure you are using a key with appropriate permissions.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("sk-...", text: $inputApiKey) // Use SecureField
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isInvalidKeyAttempt ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .onChange(of: inputApiKey) { _, _ in
                         // Reset validation state when user types
                         isInvalidKeyAttempt = false
                    }

                if isInvalidKeyAttempt {
                     Text("API Key cannot be empty.")
                          .font(.caption)
                          .foregroundColor(.red)
                }

                HStack {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Save Key") {
                         let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                         if trimmedKey.isEmpty {
                             // Show validation error
                             isInvalidKeyAttempt = true
                         } else {
                             apiKey = trimmedKey // Save the valid key to AppStorage
                             onSave(apiKey)     // Call the callback
                             dismiss()          // Dismiss the sheet
                         }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top)

                Spacer()
            }
            .padding()
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
             .onAppear {
                 // Load existing key into the input field when the view appears
                 inputApiKey = apiKey
                 isInvalidKeyAttempt = false // Reset validation on appear
             }
        }
    }
}

// MARK: - Model Views (Featured Card, Standard Row, Detail)

// --- Featured Model Card View ---
struct FeaturedModelCard: View {
    let model: OpenAIModel

    var body: some View { /* ... FeaturedModelCard implementation (unchanged) ... */
        VStack(alignment: .leading, spacing: 10) {
            // Placeholder for the gradient background / large icon look
            RoundedRectangle(cornerRadius: 12)
                .fill(model.iconBackgroundColor.opacity(0.3)) // Use background color as base
                .frame(height: 120) // Fixed height for the top area
                 .overlay(
                      Image(systemName: model.iconName)
                           .resizable()
                           .scaledToFit()
                           .padding(25)
                           .foregroundStyle(model.iconBackgroundColor) // Use color for symbol
                 )

            VStack(alignment: .leading, spacing: 4) {
                Text(model.displayName)
                    .font(.headline)
                Text(model.shortDescription) // Use the short description
                    .font(.caption)
                    .foregroundColor(.secondary)
                     .lineLimit(2)
            }
            .padding([.horizontal, .bottom], 12)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
         .frame(minWidth: 0, maxWidth: .infinity) // Ensure it takes width in HStack
    }
}

// --- Standard Model Row View (for Grids) ---
struct StandardModelRow: View {
    let model: OpenAIModel

    var body: some View { /* ... StandardModelRow implementation (unchanged) ... */
        HStack(spacing: 12) {
            Image(systemName: model.iconName)
                .resizable()
                .scaledToFit()
                .padding(7)
                .frame(width: 36, height: 36)
                .background(model.iconBackgroundColor.opacity(0.85))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8)) // Rounded square icon

            VStack(alignment: .leading, spacing: 3) {
                Text(model.displayName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(model.shortDescription) // Use short description
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2) // Allow two lines
            }
            Spacer(minLength: 0) // Allow Spacer to shrink
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

// --- Reusable Section Header ---
struct SectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View { /* ... SectionHeader implementation (unchanged) ... */
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 10) // Space below header
        .padding(.horizontal) // Standard horizontal padding
    }
}

// --- Model Detail View (Updated to show more fields) ---
struct ModelDetailView: View {
    let model: OpenAIModel

    var body: some View {
        List {
            Section { // Prominent Icon/ID Section
                /* ... Icon and Name (unchanged) ... */
                VStack(spacing: 15) {
                    Image(systemName: model.iconName).resizable().scaledToFit()
                        .padding(15).frame(width: 80, height: 80)
                        .background(model.iconBackgroundColor).foregroundStyle(.white)
                        .clipShape(Circle())
                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
                    Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
            }
            .listRowBackground(Color.clear) // Make section background transparent

            Section("Overview") {
                DetailRow(label: "Full ID", value: model.id)
                DetailRow(label: "Type", value: model.object)
                DetailRow(label: "Owner", value: model.ownedBy)
                DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
                // Display Performance & Speed Ratings
                HStack {
                  DetailRatingRow(label: "Performance", rating: model.performanceRating, maxRating: 4, icon: "gauge.medium")
                  Spacer()
                  DetailRatingRow(label: "Speed", rating: model.speedRating, maxRating: 4, icon: "bolt.fill")
                }.padding(.vertical, 2)
            }

            Section("Details") {
                 VStack(alignment: .leading, spacing: 5) {
                     Text("Description").font(.caption).foregroundColor(.secondary)
                     Text(model.description) // Use the longer description here
                 }
                 .padding(.vertical, 4)
                 .accessibilityElement(children: .combine)

                 DetailRow(label: "Context Window", value: model.contextWindow)
            }

            Section("Modalities & Pricing") {
                 VStack(alignment: .leading, spacing: 1) {
                    Text("Input Modalities").font(.caption).foregroundColor(.secondary)
                    WrappingHStack(items: model.inputModalities) { modality in modalityTag(modality) }
                 }
                 .padding(.vertical, 4)
                 VStack(alignment: .leading, spacing: 1) {
                    Text("Output Modalities").font(.caption).foregroundColor(.secondary)
                    WrappingHStack(items: model.outputModalities) { modality in modalityTag(modality) }
                 }
                 .padding(.vertical, 4)

                 if model.pricingInput != "N/A" {
                    DetailRow(label: "Pricing (Input)", value: model.pricingInput)
                 }
                if model.pricingOutput != "N/A" {
                   DetailRow(label: "Pricing (Output)", value: model.pricingOutput)
                }
            }

            if !model.capabilities.isEmpty && model.capabilities != ["general"] {
                Section("Capabilities") {
                    WrappingHStack(items: model.capabilities) { capability in capabilityTag(capability) }
                    .padding(.vertical, 4)
                }
            }

            if !model.typicalUseCases.isEmpty && model.typicalUseCases != ["Varies"] {
                 Section("Typical Use Cases") {
                     ForEach(model.typicalUseCases, id: \.self) { useCase in
                         Label(useCase, systemImage: "play.rectangle")
                             .font(.callout) // Smaller font
                             .foregroundColor(.primary).imageScale(.small)
                             .padding(.vertical, 2)
                     }
                 }
            }

            if !model.endpoints.isEmpty && model.endpoints != ["N/A"] {
                 Section("Supported Endpoints") {
                     ForEach(model.endpoints, id: \.self) { endpoint in
                         Text(endpoint).font(.callout.monospaced())
                             .foregroundColor(.secondary)
                             .padding(.vertical, 2)
                     }
                 }
            } else {
                 Section("Supported Endpoints") {
                     Text("Information unavailable or not applicable.").font(.callout).foregroundColor(.secondary)
                 }
            }

            // Add Rate Limits (as text info)
            Section("Rate Limits") {
                 Text("Rate limits depend on your usage tier. Refer to OpenAI documentation for specific limits.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Model Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // --- Helper for Detail Rows ---
    private func DetailRow(label: String, value: String) -> some View { /* ... DetailRow implementation (unchanged) ... */
        HStack(alignment: .top) { // Align top for multiline values
            Text(label).font(.callout).foregroundColor(.secondary)
                 .frame(width: 120, alignment: .leading) // Give label fixed width
            Text(value).font(.callout).multilineTextAlignment(.leading).foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
         .padding(.vertical, 4)
         .accessibilityElement(children: .combine)
    }

    // --- Helper for Rating Rows ---
    private func DetailRatingRow(label: String, rating: Int, maxRating: Int, icon: String) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            ForEach(0..<maxRating, id: \.self) { index in
                 Image(systemName: index < rating ? icon : "\(icon).slash")
                      .foregroundColor(index < rating ? .orange : .gray.opacity(0.5))
                      .imageScale(.small)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(rating) out of \(maxRating)")
    }

    // --- Helper for Tag Views ---
    private func modalityTag(_ text: String) -> some View {
         let (icon, color) = modalityVisuals(text)
         return Label(text.capitalized, systemImage: icon ?? "questionmark")
             .font(.caption)
             .padding(.horizontal, 8).padding(.vertical, 4)
             .background(color.opacity(0.15))
             .foregroundColor(color)
             .clipShape(Capsule())
   }

    private func capabilityTag(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.2))
            .foregroundColor(.accentColor).clipShape(Capsule())
    }

    // --- Map modalities to visuals ---
    private func modalityVisuals(_ modality: String) -> (icon: String?, color: Color) {
        switch modality.lowercased() {
        case "text": return ("doc.text", .blue)
        case "image": return ("photo", .green)
        case "audio": return ("waveform", .purple)
        case "vision": return ("eye", .teal)
        case "code": return ("curlybraces", .orange)
        case "tts": return ("speaker.wave.2", .indigo)
        case "realtime": return ("stopwatch", .red)
        case "search": return ("magnifyingglass", .cyan)
        case "tool-use", "computer control": return ("wrench.and.screwdriver", .brown)
        default: return ("questionmark.circle", .gray)
        }
    }
}

// MARK: - Main Content View (Adapted for Sections)

struct OpenAIModelsMasterView: View {
    // --- State Variables ---
    @State private var allModels: [OpenAIModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var useMockData = true // Default to Mock
    @State private var showingApiKeySheet = false
    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""

    // --- API Service Instance ---
    private var currentApiService: APIServiceProtocol {
        useMockData ? MockAPIService() : LiveAPIService()
    }

    // --- Grid Layout ---
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]

    // --- Filters for Sections (Updated with refined logic) ---
    // Use sets for efficient checking
    let featuredIds: Set = ["gpt-4.1", "o4-mini", "o3", "gpt-4o"] // Added 4o as featured
    var featuredModels: [OpenAIModel] { allModels.filter { featuredIds.contains($0.id) }.sortedById() }

    let reasoningIds: Set = ["gpt-4.1", "o4-mini", "o3", "o3-mini", "o1", "o1-pro", "o1-mini", "gpt-4o"]
    var reasoningModels: [OpenAIModel] { allModels.filter { reasoningIds.contains($0.id) }.sortedById() }

    let flagshipChatIds: Set = ["gpt-4.1", "gpt-4o", "gpt-4o-audio", "chatgpt-4o-latest"]
    var flagshipChatModels: [OpenAIModel] { allModels.filter { flagshipChatIds.contains($0.id) }.sortedById() }

    let costOptimizedIds: Set = ["o4-mini", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o-mini", "gpt-4o-mini-audio", "o1-mini", "gpt-3.5-turbo", "gpt-4o-mini-tts"] // Added 3.5t and new TTS
    var costOptimizedModels: [OpenAIModel] { allModels.filter { costOptimizedIds.contains($0.id) }.sortedById() }

    let realtimeIds: Set = ["gpt-4o-realtime", "gpt-4o-mini-realtime"]
    var realtimeModels: [OpenAIModel] { allModels.filter { realtimeIds.contains($0.id) }.sortedById() }

    let olderGptIds: Set = ["gpt-4-turbo", "gpt-4", "gpt-3.5-turbo", "o1", "o1-pro"] // Added older o-series
    var olderGptModels: [OpenAIModel] { allModels.filter { olderGptIds.contains($0.id) }.sortedById() }

    // Remaining sections (no changes to logic needed)
    var dalleModels: [OpenAIModel] { allModels.filter { $0.id.contains("dall-e") }.sortedById() }
    var ttsModels: [OpenAIModel] { allModels.filter { $0.capabilities.contains("tts") || $0.id.contains("tts") }.sortedById() } // Use capability OR id
    var transcriptionModels: [OpenAIModel] { allModels.filter { $0.capabilities.contains("audio transcription") || $0.id.contains("whisper") || $0.id.contains("-transcribe") }.sortedById() }
    var embeddingsModels: [OpenAIModel] { allModels.filter { $0.capabilities.contains("text embedding") }.sortedById() }
    var moderationModels: [OpenAIModel] { allModels.filter { $0.capabilities.contains("content filtering") }.sortedById() }
    var toolSpecificModels: [OpenAIModel] { allModels.filter { $0.capabilities.contains { cap in ["search", "tool-use", "computer control"].contains(cap) } }.sortedById() }

    var body: some View { /* ... Body implementation (unchanged from v1.1, uses new filters) ... */
        NavigationStack {
            ZStack { // Keep ZStack for overlaying ProgressView/ErrorView
                // --- Conditional Content Display ---
                if isLoading && allModels.isEmpty {
                     ProgressView("Fetching Models...")//.scaleEffect(1.5)
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
                           .background(Color(.systemBackground)) // Ensure it covers content
                           .zIndex(1) // Make sure it's on top
                 } else if let errorMessage = errorMessage, allModels.isEmpty {
                     ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
                 } else {
                    // --- Main Scrollable Content ---
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) { // Main container for sections

                             // --- Header Text (Mimics website) ---
                             VStack(alignment: .leading, spacing: 5) {
                                 Text("Models")
                                     .font(.largeTitle.weight(.bold))
                                 Text("Explore all available models and compare their capabilities.")
                                     .font(.title3)
                                     .foregroundColor(.secondary)
                             }
                             .padding(.horizontal)
                           // --- Compare Models Button ---
                           // Button("Compare models") { /* Action */ }
                           //     .buttonStyle(.borderedProminent)
                           //     .padding(.horizontal)

                             Divider().padding(.horizontal)

                             // --- Featured Models Section ---
                             SectionHeader(title: "Featured models", subtitle: nil)
                             ScrollView(.horizontal, showsIndicators: false) {
                                 HStack(spacing: 15) {
                                     ForEach(featuredModels) { model in
                                         NavigationLink(value: model) {
                                             FeaturedModelCard(model: model)
                                                 .frame(width: 250) // Fixed width for horizontal scroll
                                         }
                                         .buttonStyle(.plain) // Remove link styling
                                     }
                                 }
                                 .padding(.horizontal) // Padding for HStack content
                                 .padding(.bottom, 5) // Space after horizontal scroll
                             }

                             // --- Standard Sections with Grid ---
                             displaySection(title: "Reasoning models", subtitle: "o-series models that excel at complex, multi-step tasks.", models: reasoningModels)
                             displaySection(title: "Flagship chat models", subtitle: "Our versatile, high-intelligence flagship models.", models: flagshipChatModels)
                             displaySection(title: "Cost-optimized models", subtitle: "Smaller, faster models that cost less to run.", models: costOptimizedModels)
                             displaySection(title: "Realtime models", subtitle: "Models capable of realtime text and audio inputs and outputs.", models: realtimeModels)
                             displaySection(title: "Older GPT models", subtitle: "Supported older versions of our general purpose and chat models.", models: olderGptModels)
                             displaySection(title: "DALL·E", subtitle: "Models that can generate and edit images, given a natural language prompt.", models: dalleModels)
                             displaySection(title: "Text-to-speech", subtitle: "Models that can convert text into natural sounding spoken audio.", models: ttsModels)
                             displaySection(title: "Transcription", subtitle: "Model that can transcribe and translate audio into text.", models: transcriptionModels)
                             displaySection(title: "Embeddings", subtitle: "A set of models that can convert text into vector representations.", models: embeddingsModels)
                             displaySection(title: "Moderation", subtitle: "Fine-tuned models that detect whether input may be sensitive or unsafe.", models: moderationModels)
                             displaySection(title: "Tool-specific models", subtitle: "Models to support specific built-in tools.", models: toolSpecificModels)

                             Spacer(minLength: 50) // Add space at the bottom

                        } // End Main VStack
                        .padding(.top) // Padding at the top of the scroll view
                    } // End ScrollView
                    .background(Color(.systemBackground)) // List background color
                    .edgesIgnoringSafeArea(.bottom) // Allow content to go to bottom edge
                 }
            } // End ZStack
            .navigationTitle("OpenAI Models")
            .navigationBarTitleDisplayMode(.inline) // Use inline to match web simpler header
            .toolbar {
                 // --- Refresh/Loading Indicator ---
                 ToolbarItem(placement: .navigationBarLeading) {
                     if isLoading { ProgressView().controlSize(.small) }
                     else {
                         Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                         .disabled(isLoading)
                     }
                 }
                 // --- Toggle API Source Button ---
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Menu {
                         Toggle(isOn: $useMockData) {
                             Text(useMockData ? "Using Mock Data" : "Using Live API")
                         }
                     } label: {
                         Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill")
                           .foregroundColor(useMockData ? .secondary : .blue)
                     }
                     .disabled(isLoading)
                 }
             }
             // --- Navigation Destination (Unchanged) ---
             .navigationDestination(for: OpenAIModel.self) { model in
                 ModelDetailView(model: model)
                       .toolbarBackground(.visible, for: .navigationBar)
                       .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
             }
             // --- Initial Load & API Key Sheet Logic ---
             .task {
                  if allModels.isEmpty { attemptLoadModels() }
             }
             .refreshable { await loadModelsAsync(checkApiKey: false) } // Don't re-prompt on pull-to-refresh
             .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
             // --- Alert for errors *after* initial load (if needed) ---
             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: {
                 Button("OK") { errorMessage = nil }
             }, message: { Text(errorMessage ?? "An unknown error occurred.") })

        } // End NavigationStack
    }

    // --- Helper View Builder for Sections ---
    @ViewBuilder
    private func displaySection(title: String, subtitle: String?, models: [OpenAIModel]) -> some View { /* ... displaySection implementation (unchanged) ... */
         if !models.isEmpty {
             Divider().padding(.horizontal)
             SectionHeader(title: title, subtitle: subtitle)
             LazyVGrid(columns: gridColumns, spacing: 15) {
                 ForEach(models) { model in
                     NavigationLink(value: model) {
                         StandardModelRow(model: model)
                     }
                     .buttonStyle(.plain) // Remove link styling
                 }
             }
             .padding(.horizontal)
         } else {
             // Optionally show something if a section's models are empty after filtering
             // EmptyView()
         }
    }

    // --- Helper Functions for Loading & API Key Handling ---
    private func handleToggleChange(to newValue: Bool) { /* ... handleToggleChange implementation (unchanged) ... */
         print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
         allModels = []
         errorMessage = nil
         if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             showingApiKeySheet = true
         } else {
             loadModelsAsyncWithLoadingState()
         }
    }

    private func presentApiKeySheet() -> some View { /* ... presentApiKeySheet implementation (unchanged) ... */
         APIKeyInputView(
             onSave: { _ in
                 print("API Key saved.")
                 loadModelsAsyncWithLoadingState()
             },
             onCancel: {
                 print("API Key input cancelled.")
                 useMockData = true // Revert toggle
             }
         )
    }

    private func attemptLoadModels() { /* ... attemptLoadModels implementation (unchanged) ... */
         guard !isLoading else { return }
         if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             showingApiKeySheet = true
         } else {
             loadModelsAsyncWithLoadingState()
         }
     }

    private func loadModelsAsyncWithLoadingState() { /* ... loadModelsAsyncWithLoadingState implementation (unchanged) ... */
         guard !isLoading else { return }
         isLoading = true
         Task { await loadModelsAsync(checkApiKey: false) }
    }

    @MainActor
    private func loadModelsAsync(checkApiKey: Bool) async { /* ... loadModelsAsync implementation (unchanged, relies on APIService logic) ... */
         if !isLoading { isLoading = true } // Ensure flag is set
         if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             showingApiKeySheet = true; isLoading = false; return
         }
         let serviceToUse = currentApiService
         print("🔄 Loading models using \(useMockData ? "MockAPIService" : "LiveAPIService")...")
         do {
             let fetchedModels = try await serviceToUse.fetchModels()
             self.allModels = fetchedModels
             self.errorMessage = nil
             print("✅ Successfully loaded \(fetchedModels.count) models.")
         } catch let error as LocalizedError {
             print("❌ Error loading models: \(error.localizedDescription)")
             self.errorMessage = error.localizedDescription
             if allModels.isEmpty { self.allModels = [] }
         } catch {
             print("❌ Unexpected error loading models: \(error)")
             self.errorMessage = "Unexpected error: \(error.localizedDescription)"
             if allModels.isEmpty { self.allModels = [] }
         }
         isLoading = false
    }
}

// MARK: - Helper Extensions

extension Array where Element == OpenAIModel {
    // Helper to sort models alphabetically by ID for consistent section display
    func sortedById() -> [OpenAIModel] { /* ... sortedById implementation (unchanged) ... */
        self.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
    }
}

// MARK: - Previews

#Preview("Main View (Mock Data)") {
    OpenAIModelsMasterView()
}

#Preview("Detail View (gpt-4o-mini-tts)") {
    let model = MockAPIService().generateMockModels().first { $0.id == "gpt-4o-mini-tts" }!
    NavigationStack { ModelDetailView(model: model) }
}

// #Preview("Main View (Empty/Loading)") { ... } // Existing previews (unchanged)
// #Preview("Main View (Error State)") { ... }
// #Preview("Featured Card Example") { ... }
// #Preview("Standard Row Example") { ... }
// #Preview("API Key Input Sheet") { ... }
