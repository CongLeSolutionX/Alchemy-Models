////
////  OpenAIModelsMasterView_o1_pro_detail.swift
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
////  Date: 4/13/25 (Based on previous iterations)
////  Version: 1.2 (Integrated o1-pro details)
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
//// --- Rate Limit Structure ---
//struct RateLimitTier: Codable, Hashable, Identifiable {
//    let id = UUID() // For Identifiable conformance
//    let tierName: String // e.g., "Tier 1", "Tier 2"
//    let rpm: Int? // Requests Per Minute
//    let rpd: Int? // Requests Per Day (Seems unused in screenshot, kept optional)
//    let tpm: Int? // Tokens Per Minute
//    let batchQueueLimit: Int?
//    
//    enum CodingKeys: String, CodingKey { // If needed for JSON mapping
//        case tierName, rpm, rpd, tpm, batchQueueLimit
//    }
//}
//
//// --- Main Model Structure (Expanded) ---
//struct OpenAIModel: Codable, Identifiable, Hashable {
//    // --- Core Properties (likely from live API) ---
//    let id: String
//    let object: String
//    let created: Int // Unix timestamp
//    let ownedBy: String
//    
//    // --- Basic Descriptive Properties (Defaults for consistency) ---
//    var description: String = "No description available."
//    var shortDescription: String = "General purpose model." // Used in lists/cards
//    var capabilities: [String] = ["general"] // Simplified capabilities list
//    var typicalUseCases: [String] = ["Various tasks"] // Simplified use cases
//    
//    // --- Detailed Specification Properties (Populated in Mock, Optional) ---
//    var reasoningScore: Int? = nil // 0-4 scale
//    var speedScore: Int? = nil // 0-4 scale
//    var inputPricePerMillionTokens: Double? = nil // e.g., 150.00
//    var outputPricePerMillionTokens: Double? = nil // e.g., 600.00
//    var inputModalities: [String]? = nil // e.g., ["text", "image"]
//    var outputModalities: [String]? = nil // e.g., ["text"]
//    var contextWindow: Int? = nil // e.g., 200000
//    var contextWindowDisplay: String = "N/A" // Retain original string for display flexibility
//    var maxOutputTokens: Int? = nil // e.g., 100000
//    var knowledgeCutoff: String? = nil // "YYYY-MM-DD" format, e.g., "2023-09-30"
//    var supportsReasoningTokens: Bool? = nil
//    var supportedEndpoints: [String]? = nil // List of endpoint paths or names, e.g., ["/v1/responses"]
//    var supportedFeatures: [String]? = nil // List of feature names, e.g., ["function_calling", "structured_outputs"]
//    var snapshots: [String]? = nil // List of snapshot identifiers, e.g., ["o1-pro-2025-03-19"]
//    var rateLimits: [RateLimitTier]? = nil // Array of rate limit tiers
//    
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id
//        case object
//        case created
//        case ownedBy = "owned_by"
//        // IMPORTANT: Do NOT list the detailed optional properties here unless you are
//        // certain the LIVE API provides them, otherwise decoding will fail.
//        // Rely on default values (nil, empty arrays) for fields missing in live JSON.
//        // The mock data initializer will populate them directly.
//        case description // Include if mock data provides it and you want it mapped
//        case capabilities // Include if mock data provides it
//        case contextWindowDisplay = "contextWindow" // Map original field name
//        case typicalUseCases // Include if mock data provides it
//        case shortDescription // Include if mock data provides it
//    }
//    
//    // --- Custom Initializer to handle potential inconsistencies ---
//    // Allows init from decoder *and* setting defaults/details manually for mock data
//    init(id: String, object: String, created: Int, ownedBy: String, description: String = "No description available.", shortDescription: String = "General purpose model.", capabilities: [String] = ["general"], typicalUseCases: [String] = ["Various tasks"], reasoningScore: Int? = nil, speedScore: Int? = nil, inputPricePerMillionTokens: Double? = nil, outputPricePerMillionTokens: Double? = nil, inputModalities: [String]? = nil, outputModalities: [String]? = nil, contextWindow: Int? = nil, contextWindowDisplay: String = "N/A", maxOutputTokens: Int? = nil, knowledgeCutoff: String? = nil, supportsReasoningTokens: Bool? = nil, supportedEndpoints: [String]? = nil, supportedFeatures: [String]? = nil, snapshots: [String]? = nil, rateLimits: [RateLimitTier]? = nil) {
//        self.id = id
//        self.object = object
//        self.created = created
//        self.ownedBy = ownedBy
//        self.description = description
//        self.shortDescription = shortDescription
//        self.capabilities = capabilities
//        self.typicalUseCases = typicalUseCases
//        self.reasoningScore = reasoningScore
//        self.speedScore = speedScore
//        self.inputPricePerMillionTokens = inputPricePerMillionTokens
//        self.outputPricePerMillionTokens = outputPricePerMillionTokens
//        self.inputModalities = inputModalities
//        self.outputModalities = outputModalities
//        self.contextWindow = contextWindow
//        self.contextWindowDisplay = contextWindowDisplay
//        self.maxOutputTokens = maxOutputTokens
//        self.knowledgeCutoff = knowledgeCutoff
//        self.supportsReasoningTokens = supportsReasoningTokens
//        self.supportedEndpoints = supportedEndpoints
//        self.supportedFeatures = supportedFeatures
//        self.snapshots = snapshots
//        self.rateLimits = rateLimits
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
//        // Updated mapping based on potentially larger set of models
//        if normalizedId.contains("o1-pro") { return "bolt.horizontal.icloud.fill" } // Specific icon for o1-pro
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") || normalizedId.contains("chatgpt-4o") { return "sparkles" }
//        if normalizedId.contains("o4-mini") || normalizedId.contains("o3-mini") || normalizedId.contains("o1-mini") || normalizedId.contains("gpt-4.1-mini") || normalizedId.contains("gpt-4o-mini") { return "leaf.fill" }
//        if normalizedId.contains("o3") { return "circle.hexagonpath.fill" }
//        if normalizedId.contains("o1") && !normalizedId.contains("pro") && !normalizedId.contains("mini") { return "circles.hexagonpath.fill" } // Ensure it doesn't match o1-pro/mini
//        if normalizedId.contains("gpt-4-turbo") { return "bolt.fill" }
//        if normalizedId.contains("gpt-4") && !normalizedId.contains("turbo") && !normalizedId.contains("mini") && !normalizedId.contains("nano") { return "star.fill"}
//        if normalizedId.contains("gpt-3.5") { return "forward.fill" }
//        if normalizedId.contains("dall-e") { return "paintbrush.pointed.fill" }
//        if normalizedId.contains("tts") { return "speaker.wave.2.fill" }
//        if normalizedId.contains("transcribe") || normalizedId.contains("whisper") { return "waveform" }
//        if normalizedId.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" }
//        if normalizedId.contains("moderation") { return "exclamationmark.shield.fill" }
//        if normalizedId.contains("search") { return "magnifyingglass"}
//        if normalizedId.contains("computer-use") { return "computermouse.fill" }
//        if normalizedId.contains("realtime") { return "badge.plus.radiowaves.right" }
//        if normalizedId.contains("audio") { return "waveform.path.ecg" }
//        // Fallback based on owner or general
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
//        // Provide specific colors for key models
//        if normalizedId.contains("o1-pro") { return .orange } // Specific for o1-pro
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") { return .blue }
//        if normalizedId.contains("o4-mini") || normalizedId.contains("gpt-4.1-mini") || normalizedId.contains("gpt-4o-mini") { return .purple }
//        if normalizedId.contains("o3") { return .orange.opacity(0.8) } // Slightly different shade
//        if normalizedId.contains("o1") && !normalizedId.contains("pro") && !normalizedId.contains("mini") { return .gray }
//        if normalizedId.contains("dall-e") { return .teal }
//        if normalizedId.contains("tts") { return .indigo }
//        if normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return .pink }
//        if normalizedId.contains("embedding") { return .green }
//        if normalizedId.contains("moderation") { return .red }
//        if normalizedId.contains("search") { return .cyan }
//        if normalizedId.contains("computer-use") { return .brown }
//        if normalizedId.contains("realtime") { return .purple.opacity(0.7) }
//        // Fallback based on owner
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return .blue.opacity(0.7) }
//        if lowerOwner == "system" { return .orange.opacity(0.6) }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return .purple.opacity(0.6) }
//        return .gray.opacity(0.5) // Default/fallback
//    }
//    
//    // --- Simplified name for display ---
//    var displayName: String {
//        // Keep it simple or apply custom formatting
//        return id.replacingOccurrences(of: "-", with: " ").capitalized
//    }
//    
//    // --- Format prices consistently ---
//    func formatPrice(_ price: Double?) -> String {
//        guard let price = price else { return "N/A" }
//        // Format as currency (e.g., $150.00)
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.currencySymbol = "$" // Assuming USD
//        formatter.maximumFractionDigits = 2
//        formatter.minimumFractionDigits = 2
//        return formatter.string(from: NSNumber(value: price)) ?? "N/A"
//    }
//    
//    // --- Format large numbers (like tokens) ---
//    func formatLargeNumber(_ number: Int?) -> String {
//        guard let number = number else { return "N/A" }
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal // Use commas
//        formatter.groupingSeparator = ","
//        formatter.usesGroupingSeparator = true
//        return formatter.string(from: NSNumber(value: number)) ?? "N/A"
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
//            OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", shortDescription: "Flagship GPT model for complex tasks", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", shortDescription: "Faster, more affordable reasoning model", capabilities: ["text generation", "reasoning"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", shortDescription: "Our most powerful reasoning model", capabilities: ["text generation", "reasoning", "code"], contextWindow: 16000, contextWindowDisplay: "16k"),
//            
//            // Reasoning Models
//            OpenAIModel(id: "o3-mini", object: "model", created: 1699000000, ownedBy: "openai", description: "A smaller, faster, and more affordable alternative to o3.", shortDescription: "A small model alternative to o3", capabilities: ["text generation", "reasoning"], contextWindow: 16000, contextWindowDisplay: "16k"),
//            OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", shortDescription: "Previous full o-series reasoning model", capabilities: ["text generation", "reasoning"], contextWindow: 8000, contextWindowDisplay: "8k"),
//            
//            // ***** ADDED o1-pro Details *****
//            OpenAIModel(
//                id: "o1-pro", object: "model", created: 1685000000, ownedBy: "openai",
//                description: "The o1 series of models are trained with reinforcement learning to think before they answer and perform complex reasoning. The o1-pro model uses more compute to think harder and provide consistently better answers. o1-pro is available in the Responses API only, to enable support for multi-turn model interactions before responding to API requests, and other advanced API features in the future.",
//                shortDescription: "Version of o1 with more compute",
//                capabilities: ["text generation", "reasoning"], // Simplified from text/image -> text
//                reasoningScore: 4, // 4/4 circles
//                speedScore: 1, // 1/4 bolts
//                inputPricePerMillionTokens: 150.00,
//                outputPricePerMillionTokens: 600.00,
//                inputModalities: ["text", "image"],
//                outputModalities: ["text"],
//                contextWindow: 200000,
//                contextWindowDisplay: "200k", // Make display friendly
//                maxOutputTokens: 100000,
//                knowledgeCutoff: "2023-09-30",
//                supportsReasoningTokens: true,
//                supportedEndpoints: ["/v1/responses"], // Based on text "Responses API only"
//                supportedFeatures: ["function_calling", "structured_outputs"], // From "Features" section
//                snapshots: ["o1-pro", "o1-pro-2025-03-19"],
//                rateLimits: [
//                    RateLimitTier(tierName: "Tier 1", rpm: 500, rpd: nil, tpm: 30_000, batchQueueLimit: 90_000),
//                    RateLimitTier(tierName: "Tier 2", rpm: 5_000, rpd: nil, tpm: 450_000, batchQueueLimit: 1_350_000),
//                    RateLimitTier(tierName: "Tier 3", rpm: 5_000, rpd: nil, tpm: 800_000, batchQueueLimit: 50_000_000),
//                    RateLimitTier(tierName: "Tier 4", rpm: 10_000, rpd: nil, tpm: 2_000_000, batchQueueLimit: 200_000_000),
//                    RateLimitTier(tierName: "Tier 5", rpm: 10_000, rpd: nil, tpm: 30_000_000, batchQueueLimit: 5_000_000_000),
//                ]
//            ),
//            // *********************************
//            
//            OpenAIModel(id: "o1-mini", object: "model", created: 1675000000, ownedBy: "openai", description: "A small model alternative to o1, very fast.", shortDescription: "A small model alternative to o1", capabilities: ["text generation", "reasoning"], contextWindow: 8000, contextWindowDisplay: "8k"),
//            
//            // Flagship Chat Models
//            OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model.", shortDescription: "Fast, intelligent, flexible GPT model", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            OpenAIModel(id: "gpt-4o-audio", object: "model", created: 1712850000, ownedBy: "openai", description: "GPT-4o models capable of audio inputs and outputs.", shortDescription: "GPT-4o models capable of audio inputs", capabilities: ["audio processing", "text generation"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            OpenAIModel(id: "chatgpt-4o-latest", object: "model", created: 1712900000, ownedBy: "openai", description: "GPT-4o model used in ChatGPT.", shortDescription: "GPT-4o model used in ChatGPT", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            
//            // Cost-optimized Models
//            OpenAIModel(id: "gpt-4.1-mini", object: "model", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", shortDescription: "Balanced for intelligence, speed, cost", capabilities: ["text generation", "reasoning"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", shortDescription: "Fastest, most cost-effective GPT-4.1", capabilities: ["text generation"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            OpenAIModel(id: "gpt-4o-mini", object: "model", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", shortDescription: "Fast, affordable small model", capabilities: ["text generation"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            OpenAIModel(id: "gpt-4o-mini-audio", object: "model", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", shortDescription: "Smaller model capable of audio inputs", capabilities: ["audio processing", "text generation"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            
//            // Realtime Models
//            OpenAIModel(id: "gpt-4o-realtime", object: "model", created: 1712860000, ownedBy: "openai", description: "Model capable of realtime text and audio inputs and outputs.", shortDescription: "Model capable of realtime text/audio", capabilities: ["realtime", "audio", "text"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            OpenAIModel(id: "gpt-4o-mini-realtime", object: "model", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", shortDescription: "Smaller realtime model for text/audio", capabilities: ["realtime", "audio", "text"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            
//            // Older GPT Models
//            OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", shortDescription: "An older high-intelligence GPT model", capabilities: ["text generation", "reasoning", "code"], contextWindow: 128000, contextWindowDisplay: "128k"),
//            OpenAIModel(id: "gpt-4", object: "model", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", shortDescription: "An older high-intelligence GPT model", capabilities: ["text generation", "reasoning", "code"], contextWindow: 32000, contextWindowDisplay: "8k / 32k"), // Simplified context window for consistency
//            OpenAIModel(id: "gpt-3.5-turbo", object: "model", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", shortDescription: "Legacy GPT model for cheaper tasks", capabilities: ["text generation"], contextWindow: 16000, contextWindowDisplay: "4k / 16k"), // Simplified
//            
//            // DALL-E Models
//            OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", shortDescription: "Our latest image generation model", capabilities: ["image generation"]),
//            OpenAIModel(id: "dall-e-2", object: "model", created: 1650000000, ownedBy: "openai", description: "Our first image generation model.", shortDescription: "Our first image generation model", capabilities: ["image generation"]),
//            
//            // ... (Rest of the mock models: TTS, Transcription, Embeddings, Moderation, Tool-specific) ...
//            // Add these back if needed, following the same pattern
//            
//        ]
//    }
//    
//    func fetchModels() async throws -> [OpenAIModel] {
//        try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
//        return generateMockModels()
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
//                // Create custom decoding strategy if absolutely necessary for live discrepancies
//                // decoder.keyDecodingStrategy = ...
//                // decoder.dateDecodingStrategy = ...
//                let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
//                print("✅ Successfully decoded \(responseWrapper.data.count) models.")
//                // The OpenAIModel init with defaults will handle fields missing in the live API
//                return responseWrapper.data
//            } catch {
//                print("❌ Decoding Error: \(error)")
//                // Log the raw response data for debugging decoding issues
//                if let jsonString = String(data: data, encoding: .utf8)?.prefix(2000) { // Log first 2k chars
//                    print("Raw response data snippet: \(jsonString)...")
//                } else {
//                    print("Could not decode raw response data as UTF-8 string.")
//                }
//                // Optionally, inspect the specific decoding error
//                if let decodingError = error as? DecodingError {
//                    handleDecodingError(decodingError)
//                }
//                throw LiveAPIError.decodingError(error)
//            }
//        } catch let error as LiveAPIError { throw error }
//        catch { throw LiveAPIError.networkError(error) }
//    }
//    
//    // Helper to print more details about decoding errors
//    private func handleDecodingError(_ error: DecodingError) {
//        switch error {
//        case .typeMismatch(let type, let context):
//            print("Decoding Type Mismatch: Type '\(type)' mismatch. Context: \(context.debugDescription)")
//            print("Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
//        case .valueNotFound(let type, let context):
//            print("Decoding Value Not Found: No value found for type '\(type)'. Context: \(context.debugDescription)")
//            print("Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
//        case .keyNotFound(let key, let context):
//            print("Decoding Key Not Found: Key '\(key.stringValue)' not found. Context: \(context.debugDescription)")
//            print("Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
//        case .dataCorrupted(let context):
//            print("Decoding Data Corrupted: Context: \(context.debugDescription)")
//            print("Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
//        @unknown default:
//            print("Unknown Decoding Error: \(error.localizedDescription)")
//        }
//    }
//}
//
//// MARK: - Reusable SwiftUI Helper Views (Error, WrappingHStack, APIKeyInputView)
//
//struct ErrorView: View { /* ... Unchanged ... */
//    let errorMessage: String
//    let retryAction: () -> Void
//    var body: some View {
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
//struct WrappingHStack<Item: Hashable, ItemView: View>: View { /* ... Unchanged ... */
//    let items: [Item]
//    let viewForItem: (Item) -> ItemView
//    let horizontalSpacing: CGFloat = 8
//    let verticalSpacing: CGFloat = 8
//    @State private var totalHeight: CGFloat = .zero
//    var body: some View {
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
//struct APIKeyInputView: View { /* ... Unchanged ... */
//    @Environment(\.dismiss) var dismiss
//    @AppStorage("userOpenAIKey") private var apiKey: String = "" // Two-way binding
//    @State private var inputApiKey: String = "" // Local state for the text field
//    @State private var isInvalidKeyAttempt: Bool = false // State for validation feedback
//    
//    var onSave: (String) -> Void
//    var onCancel: () -> Void
//    
//    var body: some View {
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
//                        // Reset validation state when user types
//                        isInvalidKeyAttempt = false
//                    }
//                
//                if isInvalidKeyAttempt {
//                    Text("API Key cannot be empty.")
//                        .font(.caption)
//                        .foregroundColor(.red)
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
//                        let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
//                        if trimmedKey.isEmpty {
//                            // Show validation error
//                            isInvalidKeyAttempt = true
//                        } else {
//                            apiKey = trimmedKey // Save the valid key to AppStorage
//                            onSave(apiKey)     // Call the callback
//                            dismiss()          // Dismiss the sheet
//                        }
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
//            .onAppear {
//                // Load existing key into the input field when the view appears
//                inputApiKey = apiKey
//                isInvalidKeyAttempt = false // Reset validation on appear
//            }
//        }
//    }
//}
//
//// MARK: - Model Views (Featured Card, Standard Row, DETAIL VIEW UPDATED)
//
//struct FeaturedModelCard: View { /* ... Unchanged ... */
//    let model: OpenAIModel
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(model.iconBackgroundColor.opacity(0.3))
//                .frame(height: 120)
//                .overlay(
//                    Image(systemName: model.iconName)
//                        .resizable().scaledToFit().padding(25)
//                        .foregroundStyle(model.iconBackgroundColor)
//                )
//            VStack(alignment: .leading, spacing: 4) {
//                Text(model.displayName).font(.headline)
//                Text(model.shortDescription)
//                    .font(.caption).foregroundColor(.secondary).lineLimit(2)
//            }.padding([.horizontal, .bottom], 12)
//        }
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
//        .frame(minWidth: 0, maxWidth: .infinity)
//    }
//}
//
//struct StandardModelRow: View { /* ... Unchanged ... */
//    let model: OpenAIModel
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: model.iconName)
//                .resizable().scaledToFit().padding(7)
//                .frame(width: 36, height: 36)
//                .background(model.iconBackgroundColor.opacity(0.85))
//                .foregroundStyle(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//            VStack(alignment: .leading, spacing: 3) {
//                Text(model.displayName).font(.subheadline.weight(.medium)).lineLimit(1)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
//            }
//            Spacer(minLength: 0)
//        }
//        .padding(10).background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 10))
//        .overlay( RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
//    }
//}
//
//struct SectionHeader: View { /* ... Unchanged ... */
//    let title: String
//    let subtitle: String?
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title).font(.title2.weight(.semibold))
//            if let subtitle = subtitle {
//                Text(subtitle).font(.callout).foregroundColor(.secondary)
//            }
//        }.padding(.bottom, 10).padding(.horizontal)
//    }
//}
//
//// --- Enhanced Model Detail View ---
//struct ModelDetailView: View {
//    let model: OpenAIModel
//    
//    var allSupportedEndpoints: [String] = [ // Define all possible endpoints for comparison
//        "/v1/chat/completions", "/v1/responses", "/v1/assistants", "/v1/batch",
//        "/v1/fine_tuning/jobs", "/v1/images/generations", "/v1/audio/speech",
//        "/v1/audio/transcriptions", "/v1/embeddings", "/v1/moderations",
//        "/v1/completions" // Legacy
//    ]
//    var allPossibleFeatures: [String] = [ // Define all possible features
//        "streaming", "function_calling", "structured_outputs", "fine_tuning",
//        "distillation", "predicted_outputs"
//    ]
//    
//    var body: some View {
//        List {
//            // --- Prominent Icon/ID Section ---
//            Section {
//                VStack(spacing: 15) {
//                    Image(systemName: model.iconName)
//                        .resizable().scaledToFit()
//                        .padding(15).frame(width: 80, height: 80)
//                        .background(model.iconBackgroundColor).foregroundStyle(.white)
//                        .clipShape(Circle())
//                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
//                    Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
//                    Text(model.description).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
//                }.frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
//            }.listRowBackground(Color.clear)
//            
//            // --- Overview Section ---
//            Section("Overview") {
//                DetailRow(label: "Full ID", value: model.id)
//                DetailRow(label: "Type", value: model.object)
//                DetailRow(label: "Owner", value: model.ownedBy)
//                DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
//            }
//            
//            // --- Performance & Pricing Section ---
//            if model.reasoningScore != nil || model.speedScore != nil || model.inputPricePerMillionTokens != nil || model.outputPricePerMillionTokens != nil {
//                Section("Performance & Pricing") {
//                    if let score = model.reasoningScore { RatingRow(label: "Reasoning", score: score, maxScore: 4, iconName: "smallcircle.filled.circle.fill") }
//                    if let score = model.speedScore { RatingRow(label: "Speed", score: score, maxScore: 4, iconName: "bolt.fill") }
//                    if model.inputPricePerMillionTokens != nil || model.outputPricePerMillionTokens != nil {
//                        HStack {
//                            Text("Price (per 1M tokens)").font(.callout).foregroundColor(.secondary)
//                            Spacer()
//                            Text("Input: \(model.formatPrice(model.inputPricePerMillionTokens)) / Output: \(model.formatPrice(model.outputPricePerMillionTokens))")
//                                .font(.body).multilineTextAlignment(.trailing)
//                                .foregroundColor(.primary)
//                        }.accessibilityElement(children: .combine)
//                    }
//                    if let cutoff = model.knowledgeCutoff { DetailRow(label: "Knowledge Cutoff", value: cutoff) }
//                }
//            }
//            
//            // --- Specifications Section ---
//            Section("Specifications") {
//                DetailRow(label: "Context Window", value: "\(model.formatLargeNumber(model.contextWindow)) tokens (\(model.contextWindowDisplay))")
//                if let maxOut = model.maxOutputTokens { DetailRow(label: "Max Output Tokens", value: model.formatLargeNumber(maxOut)) }
//                if let supports = model.supportsReasoningTokens { DetailRow(label: "Reasoning Token Support", value: supports ? "Yes" : "No") }
//            }
//            
//            // --- Modalities Section ---
//            if model.inputModalities != nil || model.outputModalities != nil {
//                Section("Modalities") {
//                    if let inputs = model.inputModalities { ModalityRow(label: "Input", modalities: inputs) }
//                    if let outputs = model.outputModalities { ModalityRow(label: "Output", modalities: outputs) }
//                }
//            }
//            
//            // --- Capabilities Section (from original code - now 'Features') ---
//            if !model.capabilities.isEmpty && model.capabilities != ["general"] {
//                Section("Key Traits") { // Rename? Or keep asCapabilities?
//                    WrappingHStack(items: model.capabilities) { capability in
//                        Text(capability.capitalized)
//                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
//                            .background(Color.accentColor.opacity(0.2))
//                            .foregroundColor(.accentColor).clipShape(Capsule())
//                    }
//                }
//            }
//            
//            // --- Endpoints Section ---
//            if let endpoints = model.supportedEndpoints {
//                Section("Supported Endpoints") {
//                    ForEach(allSupportedEndpoints, id: \.self) { endpoint in
//                        SupportedItemView(
//                            label: endpointName(for: endpoint),
//                            isSupported: endpoints.contains(endpoint),
//                            icon: endpointIcon(for: endpoint)
//                        )
//                    }
//                }
//            }
//            
//            // --- Features Section ---
//            if let features = model.supportedFeatures {
//                Section("Supported Features") {
//                    ForEach(allPossibleFeatures, id: \.self) { feature in
//                        SupportedItemView(
//                            label: featureName(for: feature),
//                            isSupported: features.contains(feature),
//                            icon: featureIcon(for: feature)
//                        )
//                    }
//                }
//            }
//            
//            // --- Snapshots ---
//            if let snapshots = model.snapshots, !snapshots.isEmpty {
//                Section("Snapshots") {
//                    ForEach(snapshots, id: \.self) { snapshot in
//                        Text(snapshot).font(.callout)
//                    }
//                }
//            }
//            
//            // --- Rate Limits Section ---
//            if let limits = model.rateLimits, !limits.isEmpty {
//                Section("Rate Limits (RPM / TPM / Batch Queue)") {
//                    VStack(alignment: .leading, spacing: 8) {
//                        // Header Row (Optional)
//                        HStack {
//                            Text("Tier").font(.caption).foregroundColor(.secondary).frame(width: 60, alignment: .leading)
//                            Spacer()
//                            Text("RPM").font(.caption).foregroundColor(.secondary).frame(width: 60, alignment: .trailing)
//                            Text("TPM").font(.caption).foregroundColor(.secondary).frame(width: 90, alignment: .trailing)
//                            Text("Batch").font(.caption).foregroundColor(.secondary).frame(width: 100, alignment: .trailing)
//                        }
//                        // Data Rows
//                        ForEach(limits) { tier in
//                            HStack {
//                                Text(tier.tierName).font(.callout).frame(width: 60, alignment: .leading)
//                                Spacer()
//                                Text(tier.rpm != nil ? "\(tier.rpm!)" : "-").font(.callout).frame(width: 60, alignment: .trailing)
//                                Text(tier.tpm != nil ? model.formatLargeNumber(tier.tpm) : "-").font(.callout).frame(width: 90, alignment: .trailing)
//                                Text(tier.batchQueueLimit != nil ? model.formatLargeNumber(tier.batchQueueLimit) : "-").font(.callout).frame(width: 100, alignment: .trailing)
//                            }
//                            Divider().padding(.vertical, 2)
//                        }
//                    }.padding(.vertical, 5)
//                }
//            }
//            
//        }
//        .listStyle(.insetGrouped)
//        .navigationTitle("Model Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//    
//    // --- Helper Views for Detail View ---
//    @ViewBuilder
//    private func DetailRow(label: String, value: String) -> some View {
//        if !value.isEmpty && value != "N/A" { // Only show if value is meaningful
//            HStack {
//                Text(label).font(.callout).foregroundColor(.secondary)
//                Spacer()
//                Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
//            }
//            .padding(.vertical, 2)
//            .accessibilityElement(children: .combine)
//        } else { EmptyView() }
//    }
//    
//    @ViewBuilder
//    private func RatingRow(label: String, score: Int, maxScore: Int, iconName: String) -> some View {
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//            RatingView(rating: score, maxRating: maxScore, iconName: iconName)
//        }.accessibilityElement(children: .combine)
//            .accessibilityLabel("\(label), rating \(score) out of \(maxScore)")
//    }
//    
//    @ViewBuilder
//    private func ModalityRow(label: String, modalities: [String]) -> some View {
//        HStack(alignment: .top) {
//            Text(label).font(.callout).foregroundColor(.secondary).padding(.top, 2)
//            Spacer()
//            VStack(alignment: .trailing, spacing: 4) {
//                ForEach(modalities, id: \.self) { modality in
//                    HStack(spacing: 4) {
//                        Image(systemName: modalityIcon(for: modality))
//                            .foregroundColor(.accentColor)
//                        Text(modality.capitalized)
//                            .font(.body)
//                    }
//                }
//            }
//        }
//    }
//    
//    // --- Helper to get modality icons ---
//    private func modalityIcon(for modality: String) -> String {
//        switch modality.lowercased() {
//        case "text": return "text.bubble"
//        case "image": return "photo"
//        case "audio": return "waveform"
//        default: return "questionmark"
//        }
//    }
//    
//    // --- Helpers to get endpoint/feature names & icons ---
//    private func endpointName(for path: String) -> String {
//        switch path {
//        case "/v1/chat/completions": return "Chat Completions"
//        case "/v1/responses": return "Responses"
//        case "/v1/assistants": return "Assistants"
//        case "/v1/batch": return "Batch"
//        case "/v1/fine_tuning/jobs": return "Fine-tuning"
//        case "/v1/images/generations": return "Image Generation"
//        case "/v1/audio/speech": return "Speech Generation"
//        case "/v1/audio/transcriptions": return "Transcription"
//        case "/v1/embeddings": return "Embeddings"
//        case "/v1/moderations": return "Moderation"
//        case "/v1/completions": return "Completions (Legacy)"
//        default: return path // Fallback
//        }
//    }
//    private func endpointIcon(for path: String) -> String {
//        switch path {
//        case "/v1/chat/completions", "/v1/completions": return "message"
//        case "/v1/responses": return "arrow.up.message"
//        case "/v1/assistants": return "person.badge.key"
//        case "/v1/batch": return "list.bullet.rectangle.portrait"
//        case "/v1/fine_tuning/jobs": return "slider.horizontal.3"
//        case "/v1/images/generations": return "photo.on.rectangle.angled"
//        case "/v1/audio/speech": return "speaker.wave.2"
//        case "/v1/audio/transcriptions": return "waveform"
//        case "/v1/embeddings": return "arrow.down.right.and.arrow.up.left"
//        case "/v1/moderations": return "exclamationmark.shield"
//        default: return "questionmark.square.dashed"
//        }
//    }
//    
//    private func featureName(for feature: String) -> String {
//        return feature.replacingOccurrences(of: "_", with: " ").capitalized
//    }
//    
//    private func featureIcon(for feature: String) -> String {
//        switch feature {
//        case "streaming": return "play.fill"
//        case "function_calling": return "hammer.fill"
//        case "structured_outputs": return "list.bullet.clipboard.fill"
//        case "fine_tuning": return "slider.horizontal.3" // Reuse icon
//        case "distillation": return "drop.fill"
//        case "predicted_outputs": return "wand.and.stars"
//        default: return "gearshape"
//        }
//    }
//}
//
//// MARK: - Helper Views for Detail View
//
//struct RatingView: View {
//    let rating: Int
//    let maxRating: Int
//    let iconName: String
//    let activeColor: Color = .accentColor // Or specific color like .orange
//    let inactiveColor: Color = .gray.opacity(0.3)
//    
//    var body: some View {
//        HStack(spacing: 3) {
//            ForEach(1...maxRating, id: \.self) { index in
//                Image(systemName: iconName)
//                    .foregroundColor(index <= rating ? activeColor : inactiveColor)
//                    .font(.callout) // Adjust size as needed
//            }
//        }
//    }
//}
//
//struct SupportedItemView: View {
//    let label: String
//    let isSupported: Bool
//    let icon: String
//    
//    var body: some View {
//        HStack {
//            Label { Text(label) } icon: { Image(systemName: icon).foregroundColor(isSupported ? .blue : .secondary) }
//            Spacer()
//            Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle")
//                .foregroundColor(isSupported ? .green : .secondary.opacity(0.6))
//        }
//        .foregroundColor(isSupported ? .primary : .secondary) // Dim text if not supported
//        .padding(.vertical, 2)
//    }
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
//    // --- Filters for Sections (Updated to include o1-pro where relevant) ---
//    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "o4-mini", "o3"].contains($0.id) }.sortedById() }
//    var reasoningModels: [OpenAIModel] { allModels.filter { ["o1-pro", "o4-mini", "o3", "o3-mini", "o1", "o1-mini"].contains($0.id) }.sortedById() } // Added o1-pro
//    var flagshipChatModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "gpt-4o", "gpt-4o-audio", "chatgpt-4o-latest"].contains($0.id) }.sortedById() }
//    var costOptimizedModels: [OpenAIModel] { allModels.filter { ["o4-mini", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o-mini", "gpt-4o-mini-audio", "o1-mini"].contains($0.id) }.sortedById() }
//    var realtimeModels: [OpenAIModel] { allModels.filter { ["gpt-4o-realtime", "gpt-4o-mini-realtime"].contains($0.id) }.sortedById() }
//    var olderGptModels: [OpenAIModel] { allModels.filter { ["gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"].contains($0.id) }.sortedById() }
//    var dalleModels: [OpenAIModel] { allModels.filter { $0.id.contains("dall-e") }.sortedById() }
//    // ... (Other sections remain the same) ...
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
//                    ProgressView("Fetching Models...")
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .background(Color(.systemBackground)).zIndex(1)
//                } else if let errorMessage = errorMessage, allModels.isEmpty {
//                    ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
//                } else {
//                    ScrollView(.vertical, showsIndicators: false) {
//                        VStack(alignment: .leading, spacing: 30) {
//                            VStack(alignment: .leading, spacing: 5) {
//                                Text("Models").font(.largeTitle.weight(.bold))
//                                Text("Explore all available models and compare their capabilities.").font(.title3).foregroundColor(.secondary)
//                            }.padding(.horizontal)
//                            Divider().padding(.horizontal)
//                            SectionHeader(title: "Featured models", subtitle: nil)
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                HStack(spacing: 15) {
//                                    ForEach(featuredModels) { model in
//                                        NavigationLink(value: model) {
//                                            FeaturedModelCard(model: model).frame(width: 250)
//                                        }.buttonStyle(.plain)
//                                    }
//                                }.padding(.horizontal).padding(.bottom, 5)
//                            }
//                            // Display sections using helper
//                            displaySection(title: "Reasoning models", subtitle: "o-series models that excel at complex, multi-step tasks.", models: reasoningModels)
//                            displaySection(title: "Flagship chat models", subtitle: "Our versatile, high-intelligence flagship models.", models: flagshipChatModels)
//                            displaySection(title: "Cost-optimized models", subtitle: "Smaller, faster models that cost less to run.", models: costOptimizedModels)
//                            displaySection(title: "Realtime models", subtitle: "Models capable of realtime text and audio inputs and outputs.", models: realtimeModels)
//                            displaySection(title: "Older GPT models", subtitle: "Supported older versions of our general purpose and chat models.", models: olderGptModels)
//                            displaySection(title: "DALL·E", subtitle: "Models that can generate and edit images, given a natural language prompt.", models: dalleModels)
//                            // ... Add other sections if mocks were included: Tts, Transcription, etc. ...
//                            Spacer(minLength: 50)
//                        } // End Main VStack
//                        .padding(.top)
//                    } // End ScrollView
//                    .background(Color(.systemGroupedBackground)) // Match list style background
//                    .edgesIgnoringSafeArea(.bottom)
//                }
//            } // End ZStack
//            .navigationTitle("OpenAI Models")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) { /* Refresh unchanged */
//                    if isLoading { ProgressView().controlSize(.small) }
//                    else { Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(isLoading) }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) { /* API Toggle unchanged */
//                    Menu { Toggle(isOn: $useMockData) { Text(useMockData ? "Using Mock Data" : "Using Live API") } }
//                    label: { Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill").foregroundColor(useMockData ? .secondary : .blue) }
//                        .disabled(isLoading)
//                }
//            }
//            .navigationDestination(for: OpenAIModel.self) { model in /* Detail Nav unchanged */
//                ModelDetailView(model: model)
//                    .toolbarBackground(.visible, for: .navigationBar)
//                    .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
//            }
//            .task { if allModels.isEmpty { attemptLoadModels() } } // Initial Load
//            .refreshable { await loadModelsAsync(checkApiKey: false) } // Pull-to-refresh
//            .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) } // Toggle change
//            .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() } // API Key Sheet
//            .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: { Button("OK") { errorMessage = nil } }, message: { Text(errorMessage ?? "An unknown error occurred.") }) // Error alert after initial load
//            
//        } // End NavigationStack
//    }
//    
//    // --- Helper View Builder for Sections (Unchanged) ---
//    @ViewBuilder
//    private func displaySection(title: String, subtitle: String?, models: [OpenAIModel]) -> some View {
//        if !models.isEmpty {
//            Divider().padding(.horizontal)
//            SectionHeader(title: title, subtitle: subtitle)
//            LazyVGrid(columns: gridColumns, spacing: 15) {
//                ForEach(models) { model in
//                    NavigationLink(value: model) { StandardModelRow(model: model) }.buttonStyle(.plain)
//                }
//            }.padding(.horizontal)
//        } else { EmptyView() }
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
//    private func presentApiKeySheet() -> some View { /* ... Unchanged ... */
//        APIKeyInputView( onSave: { _ in print("API Key saved."); loadModelsAsyncWithLoadingState() },
//                         onCancel: { print("API Key input cancelled."); useMockData = true } )
//    }
//    private func attemptLoadModels() { /* ... Unchanged ... */
//        guard !isLoading else { return }
//        if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            showingApiKeySheet = true
//        } else { loadModelsAsyncWithLoadingState() }
//    }
//    private func loadModelsAsyncWithLoadingState() { /* ... Unchanged ... */
//        guard !isLoading else { return }
//        isLoading = true; Task { await loadModelsAsync(checkApiKey: false) }
//    }
//    @MainActor private func loadModelsAsync(checkApiKey: Bool) async { /* ... Unchanged ... */
//        if !isLoading { isLoading = true }
//        if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            showingApiKeySheet = true; isLoading = false; return
//        }
//        let serviceToUse = currentApiService
//        print("🔄 Loading models using \(useMockData ? "MockAPIService" : "LiveAPIService")...")
//        do {
//            let fetchedModels = try await serviceToUse.fetchModels()
//            self.allModels = fetchedModels; self.errorMessage = nil
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
//extension Array where Element == OpenAIModel { // Unchanged
//    func sortedById() -> [OpenAIModel] { self.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending } }
//}
//
//// MARK: - Previews
//
//// #Preview("Main View (Mock Data)") { OpenAIModelsMasterView() } // Basic preview
//#Preview("Main View (o1-pro Detail)") {
//    let view = OpenAIModelsMasterView()
//    // This preview won't show the specific detail view directly,
//    // but it will load the mock data which includes the enhanced o1-pro.
//    // Use the "Detail View Example (o1-pro)" preview below for direct detail view testing.
//    return view
//}
//
////#Preview("Detail View Example (o1-pro)") {
////    // Create only the o1-pro mock model forfocused preview
////    let mockService = MockAPIService()
////    Task {
////        if let o1pro = try? await mockService.fetchModels().first(where: { $0.id == "o1-pro" }) {
////            NavigationStack {
////                ModelDetailView(model: o1pro)
////            }
////        } else {
////            Text("Error: Could not load o1-pro mock data for preview.")
////        }
////        
////    }
////    
////    Text("Loading Preview...") // Placeholder while async runs
////}
//
//#Preview("API Key Input Sheet") { /* ... Unchanged ... */
//    struct SheetPresenter: View { @State var showSheet = true; var body: some View { Text("Tap to show sheet (already shown)").sheet(isPresented: $showSheet) { APIKeyInputView(onSave: {_ in}, onCancel: {}) } } }
//    return SheetPresenter()
//}
//
//#Preview("Featured Card") { /* ... Unchanged ... */
//    let model = OpenAIModel(id: "gpt-4.1", object: "model", created: 1, ownedBy: "openai", shortDescription: "Flagship model")
//    return FeaturedModelCard(model: model).padding().frame(width: 280)
//}
//
//#Preview("Standard Row") { /* ... Unchanged ... */
//    let model = OpenAIModel(id: "o4-mini", object: "model", created: 1, ownedBy: "openai", shortDescription: "Faster, affordable reasoning")
//    return StandardModelRow(model: model).padding().frame(width: 350)
//}
