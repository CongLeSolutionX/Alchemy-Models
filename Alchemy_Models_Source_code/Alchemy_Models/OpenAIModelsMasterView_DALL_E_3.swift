////
////  OpenAIModelsMasterView_DALLE_3.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIModelsMasterView.swift
////  Alchemy_Models_Combined
////  (Single File Implementation - Updated for DALL-E 3 Details)
////
////  Created: Cong Le
////  Date: 4/13/25 (Based on previous iterations)
////  Version: 1.2 (Synthesized & DALL-E 3 Update)
////  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
////  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
////
//
//import SwiftUI
//import Foundation // Needed for URLSession, URLRequest, Date, etc.
//import Combine    // Needed for @StateObject if using ObservableObject later
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
//        case .requestFailed(let sc): return "API request failed with status code \(sc). Check API Key and network connection."
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
//    var capabilities: [String] = ["general"]
//    var contextWindow: String = "N/A" // Some models don't have a text window (e.g., DALL-E)
//    var typicalUseCases: [String] = ["Various tasks"]
//    // New field based on screenshots - provide a default
//    var shortDescription: String = "General purpose model."
//
//    // --- Specific fields for DALL-E 3 based on screenshots ---
//    var performance: String? = nil  // e.g., "High"
//    var speed: String? = nil        // e.g., "Slow"
//    var pricing: String? = nil      // e.g., "$0.08 / HD 1024x1024, $0.12 / HD 1024x1792"
//    var inputType: String? = nil    // e.g., "Text"
//    var outputType: String? = nil   // e.g., "Image"
//    var supportedEndpoints: [String]? = nil // e.g., ["Image generation"]
//    var unsupportedEndpoints: [String]? = nil // List derived from screenshot
//    var supportedFeatures: [String]? = nil   // e.g., ["HD Quality", "Variable Resolution"]
//    var unsupportedFeatures: [String]? = nil // e.g., ["Inpainting"]
//
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id
//        case object
//        case created
//        case ownedBy = "owned_by"
//        // IMPORTANT: description, capabilities, contextWindow, typicalUseCases, shortDescription,
//        // performance, speed, pricing, inputType, outputType, supportedEndpoints, etc.
//        // are NOT listed here. Codable will ignore them during JSON decoding from the LIVE API
//        // if they aren't present, allowing default values or nil to be used.
//        // Mock data *can* provide these fields, and they will be used.
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
//    // --- Determine SF Symbol name based on ID or capabilities ---
//    var iconName: String {
//        let normalizedId = id.lowercased()
//
//        // Priority based on core function (extracted from capabilities/id)
//        if capabilities.contains("image generation") || normalizedId.contains("dall-e") { return "paintbrush.pointed.fill" }
//        if capabilities.contains("tts".lowercased()) || normalizedId.contains("tts") { return "speaker.wave.2.fill" }
//        if capabilities.contains("audio transcription") || normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return "waveform" }
//        if capabilities.contains("text embedding") || normalizedId.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" }
//        if capabilities.contains("content filtering") || normalizedId.contains("moderation") { return "exclamationmark.shield.fill" }
//        if capabilities.contains("search") || normalizedId.contains("search") { return "magnifyingglass" }
//        if capabilities.contains("computer control") || normalizedId.contains("computer-use") { return "computermouse.fill" }
//        if capabilities.contains("tool-use") { return "wrench.and.screwdriver.fill" } // Generic tool use
//
//        // General GPT / Reasoning / Chat models by ID
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") || normalizedId.contains("chatgpt-4o") { return "sparkles" }
//        if normalizedId.contains("o4-mini") || normalizedId.contains("o3-mini") || normalizedId.contains("o1-mini") || normalizedId.contains("gpt-4.1-mini") { return "leaf.fill" }
//        if normalizedId.contains("o3") { return "circle.hexagonpath.fill" }
//        if normalizedId.contains("o1") || normalizedId.contains("o1-pro") { return "circles.hexagonpath.fill" }
//        if normalizedId.contains("gpt-4-turbo") { return "bolt.fill" }
//        if normalizedId.contains("gpt-4") && !normalizedId.contains("turbo") { return "star.fill"}
//        if normalizedId.contains("gpt-3.5") { return "forward.fill" }
//
//        // Fallback based on owner
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return "building.columns.fill" }
//        if lowerOwner == "system" { return "gearshape.fill" }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return "person.crop.circle.fill" }
//        return "questionmark.circle.fill" // Default/fallback
//    }
//
//    // Determine background color for icons ---
//    var iconBackgroundColor: Color {
//        let normalizedId = id.lowercased()
//
//        // Priority based on core function
//        if capabilities.contains("image generation") || normalizedId.contains("dall-e") { return .teal }
//        if capabilities.contains("tts") || normalizedId.contains("tts") { return .indigo }
//        if capabilities.contains("audio transcription") || normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return .pink }
//        if capabilities.contains("text embedding") || normalizedId.contains("embedding") { return .green }
//        if capabilities.contains("content filtering") || normalizedId.contains("moderation") { return .red }
//        if capabilities.contains("search") || normalizedId.contains("search") { return .cyan }
//        if capabilities.contains("computer control") || normalizedId.contains("computer-use") { return .brown }
//        if capabilities.contains("tool-use") { return .orange }
//
//        // General GPT / Reasoning / Chat models by ID
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") { return .blue }
//        if normalizedId.contains("o4-mini") { return .purple }
//        if normalizedId.contains("o3") { return .orange }
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
//        // Special handling for specific models if needed
//        if id == "dall-e-3" { return "DALL·E 3" }
//        if id == "dall-e-2" { return "DALL·E 2" }
//        // Generic replacement
//        return id.replacingOccurrences(of: "-", with: " ").capitalized
//    }
//}
//
//// MARK: - API Service Implementations
//
//// --- Mock Data Service ---
//class MockAPIService: APIServiceProtocol {
//    private let mockNetworkDelaySeconds: Double = 0.8
//
//    // Enhanced mock models including detailed DALL-E 3 data
//    private func generateMockModels() -> [OpenAIModel] {
//        return [
//            // Featured
//            OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k", shortDescription: "Flagship GPT model for complex tasks"),
//            OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Faster, more affordable reasoning model"),
//            OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "16k", shortDescription: "Our most powerful reasoning model"),
//
//            // DALL-E Models (Detailed DALL-E 3)
//            OpenAIModel(
//                 id: "dall-e-3",
//                 object: "model",
//                 created: 1700000000, // Example timestamp
//                 ownedBy: "openai",
//                 // Main description from screenshot text block
//                 description: "DALL·E is an AI system that creates realistic images and art from a natural language description. DALL·E 3 currently supports the ability, given a prompt, to create a new image with a specific size. Pricing is based on image generation.",
//                 // Capabilities derived from Modalities and supported Endpoints
//                 capabilities: ["image generation", "text input", "image output"],
//                 contextWindow: "N/A", // Not applicable for image gen
//                 typicalUseCases: ["Generating images from text", "Creating digital art", "Visual content creation"],
//                 // Header summary
//                 shortDescription: "Our latest image generation model",
//                 // Filled from screenshot sections
//                 performance: "High",
//                 speed: "Slow",
//                 pricing: "HD Quality: $0.08 (1024x1024), $0.12 (1024x1792)",
//                 inputType: "Text",
//                 outputType: "Image",
//                 supportedEndpoints: ["Image generation"],
//                 unsupportedEndpoints: [
//                     "Chat Completions", "Responses", "Realtime", "Assistants",
//                     "Batch", "Fine-tuning", "Embeddings", "Speech generation",
//                     "Translation", "Transcription", "Moderation", "Completions (legacy)"
//                 ],
//                 supportedFeatures: ["HD Quality", "Variable Resolution (1024x1024, 1024x1792)"],
//                 unsupportedFeatures: ["Audio Input/Output", "Inpainting"]
//            ),
//            OpenAIModel(
//                 id: "dall-e-2",
//                 object: "model",
//                 created: 1650000000, // Example timestamp
//                 ownedBy: "openai",
//                 description: "Our previous image generation model, capable of creating images from text descriptions.",
//                 capabilities: ["image generation", "text input", "image output"],
//                 contextWindow: "N/A",
//                 typicalUseCases: ["Generating images from text"],
//                 shortDescription: "Previous image generation model",
//                 performance: "Medium", // Assumed comparison based on chart
//                 speed: "Medium",     // Assumed comparison
//                 pricing: "$0.04 (1024x1024)" // From comparison chart
//                 // Fields like unsupportedEndpoints, etc., could be added if known
//            ),
//
//            // Reasoning Models
//            OpenAIModel(id: "o3-mini", object: "model", created: 1699000000, ownedBy: "openai", description: "A smaller, faster, and more affordable alternative to o3.", capabilities: ["text generation", "reasoning"], contextWindow: "16k", shortDescription: "A small model alternative to o3"),
//            OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Previous full o-series reasoning model"),
//            OpenAIModel(id: "o1-pro", object: "model", created: 1685000000, ownedBy: "openai", description: "Version of o1 with more compute for better responses.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Version of o1 with more compute"),
//            OpenAIModel(id: "o1-mini", object: "model", created: 1675000000, ownedBy: "openai", description: "A small model alternative to o1, very fast.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "A small model alternative to o1"),
//
//            // Flagship Chat Models
//            OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "Fast, intelligent, flexible GPT model"),
//            OpenAIModel(id: "gpt-4o-audio", object: "model", created: 1712850000, ownedBy: "openai", description: "GPT-4o models capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "GPT-4o models capable of audio inputs"),
//            OpenAIModel(id: "chatgpt-4o-latest", object: "model", created: 1712900000, ownedBy: "openai", description: "GPT-4o model used in ChatGPT.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "GPT-4o model used in ChatGPT"),
//
//            // Cost-optimized Models
//            OpenAIModel(id: "gpt-4.1-mini", object: "model", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Balanced for intelligence, speed, cost"),
//            OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fastest, most cost-effective GPT-4.1"),
//            OpenAIModel(id: "gpt-4o-mini", object: "model", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model"),
//            OpenAIModel(id: "gpt-4o-mini-audio", object: "model", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "Smaller model capable of audio inputs"),
//
//            // Realtime Models
//            OpenAIModel(id: "gpt-4o-realtime", object: "model", created: 1712860000, ownedBy: "openai", description: "Model capable of realtime text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Model capable of realtime text/audio"),
//            OpenAIModel(id: "gpt-4o-mini-realtime", object: "model", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Smaller realtime model for text/audio"),
//
//            // Older GPT Models
//            OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "128k", shortDescription: "An older high-intelligence GPT model"),
//            OpenAIModel(id: "gpt-4", object: "model", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "8k / 32k", shortDescription: "An older high-intelligence GPT model"),
//            OpenAIModel(id: "gpt-3.5-turbo", object: "model", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", capabilities: ["text generation"], contextWindow: "4k / 16k", shortDescription: "Legacy GPT model for cheaper tasks"),
//
//            // Text-to-speech Models
////            OpenAIModel(id: "tts-1", object: "model", created: 1690000000, ownedBy: "openai", description: "Text-to-speech model optimized for speed.", shortDescription: "Text-to-speech model optimized for speed", capabilities: ["tts"], contextWindow: "N/A"),
////            OpenAIModel(id: "tts-1-hd", object: "model", created: 1695000000, ownedBy: "openai", description: "Text-to-speech model optimized for quality.", shortDescription: "Text-to-speech model optimized for quality", capabilities: ["tts-hd"], contextWindow: "N/A"),
////            OpenAIModel(id: "gpt-4o-mini-tts", object: "model", created: 1712370000, ownedBy: "openai", description: "Text-to-speech model powered by GPT-4o mini.", shortDescription: "TTS model powered by GPT-4o mini", capabilities: ["tts"], contextWindow: "N/A"),
////
////             // Transcription Models
////            OpenAIModel(id: "whisper-1", object: "model", created: 1677600000, ownedBy: "openai", description: "General-purpose speech recognition model.", shortDescription: "General-purpose speech recognition", capabilities: ["audio transcription", "translation"], contextWindow: "N/A"),
////            OpenAIModel(id: "gpt-4o-transcribe", object: "model", created: 1712870000, ownedBy: "openai", description: "Speech-to-text model powered by GPT-4o.", shortDescription: "Speech-to-text powered by GPT-4o", capabilities: ["audio transcription"], contextWindow: "N/A"),
////            OpenAIModel(id: "gpt-4o-mini-transcribe", object: "model", created: 1712380000, ownedBy: "openai", description: "Speech-to-text model powered by GPT-4o mini.", shortDescription: "Speech-to-text powered by GPT-4o mini", capabilities: ["audio transcription"], contextWindow: "N/A"),
////
////            // Embeddings Models
////            OpenAIModel(id: "text-embedding-3-small", object: "model", created: 1711200000, ownedBy: "openai", description: "Small embedding model.", shortDescription: "Small embedding model", capabilities: ["text embedding"], contextWindow: "8k"),
////            OpenAIModel(id: "text-embedding-3-large", object: "model", created: 1711300000, ownedBy: "openai", description: "Most capable embedding model.", shortDescription: "Most capable embedding model", capabilities: ["text embedding"], contextWindow: "8k"),
////            OpenAIModel(id: "text-embedding-ada-002", object: "model", created: 1670000000, ownedBy: "openai", description: "Older embedding model.", shortDescription: "Older embedding model", capabilities: ["text embedding"], contextWindow: "8k"),
////
////            // Moderation Models
////            OpenAIModel(id: "text-moderation-latest", object: "model", created: 1688000000, ownedBy: "openai", description: "Previous generation text-only moderation model.", shortDescription: "Previous generation text moderation", capabilities: ["content filtering"], contextWindow: "N/A"), // Renamed from stable to latest per API docs convention
////            OpenAIModel(id: "omni-moderation", object: "model", created: 1712880000, ownedBy: "openai", description: "Identify potentially harmful content in text and images.", capabilities: ["content filtering", "image moderation"], shortDescription: "Identify potentially harmful content", contextWindow: "N/A"), // Assuming this exists
////
////            // Tool-specific Models (Assuming IDs based on names)
////            OpenAIModel(id: "gpt-4o-search-preview", object: "model", created: 1712890000, ownedBy: "openai", description: "GPT model for web search in Chat Completions.", capabilities: ["search", "text generation"], shortDescription: "GPT model for web search", contextWindow: "128k"),
////            OpenAIModel(id: "gpt-4o-mini-search-preview", object: "model", created: 1712390000, ownedBy: "openai", description: "Fast, affordable small model for web search.", capabilities: ["search", "text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model for search"),
////            OpenAIModel(id: "computer-use-preview", object: "model", created: 1712910000, ownedBy: "openai", description: "Specialized model for computer use tool.", capabilities: ["tool-use", "computer control"], contextWindow: "N/A", shortDescription: "Specialized model for computer use tool") // Placeholder
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
//        guard !currentKey.isEmpty else {
//            print("❌ Error: OpenAI API Key is missing from AppStorage.")
//            throw LiveAPIError.missingAPIKey
//        }
//
//        var request = URLRequest(url: modelsURL)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(currentKey)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        print("🚀 Making live API request to: \(modelsURL)")
//
//        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("❌ Error: Invalid response received from API.")
//                throw LiveAPIError.requestFailed(statusCode: 0)
//            }
//            print("✅ Received API response with status code: \(httpResponse.statusCode)")
//
//            if httpResponse.statusCode == 401 {
//                print("❌ Error: API Key Unauthorized (Status 401).")
//                throw LiveAPIError.missingAPIKey // Treat 401 as invalid key
//            }
//            guard (200...299).contains(httpResponse.statusCode) else {
//                print("❌ Error: API request failed with status code \(httpResponse.statusCode).")
//                throw LiveAPIError.requestFailed(statusCode: httpResponse.statusCode)
//            }
//
//            do {
//                 let decoder = JSONDecoder()
//                 // Handle the response structure which has a 'data' key
//                 let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
//                 print("✅ Successfully decoded \(responseWrapper.data.count) models.")
//                 // Map the response to potentially add default/derived info if needed
//                 // *Note*: Live API for /v1/models is basic. Extended fields added to OpenAIModel
//                 // primarily benefit the mock data for richer UI previews.
//                 return responseWrapper.data.map { model in
//                     var mutableModel = model
//                     // Example: If API doesn't provide shortDescription, derive one.
//                     if mutableModel.shortDescription == "General purpose model." { // Check default value
//                         mutableModel.shortDescription = model.ownedBy.contains("openai") ? "Official OpenAI model." : "User or system model."
//                     }
//                     // LIVE: The API doesn't return performance/pricing/etc for v1/models.
//                     // These fields will remain nil/default unless explicitly set here based on ID lookup,
//                     // but that's complex state management usually handled server-side or via more specific APIs.
//                     return mutableModel
//                 }
//            } catch {
//                 print("❌ Decoding Error: \(error)")
//                 print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Could not decode data")")
//                 throw LiveAPIError.decodingError(error)
//            }
//        } catch let error as LiveAPIError {
//            throw error // Re-throw specific API errors
//        } catch {
//            print("❌ Network Error: \(error)")
//            throw LiveAPIError.networkError(error) // Wrap other errors
//        }
//    }
//}
//
//// MARK: - Reusable SwiftUI Helper Views (Error, WrappingHStack, APIKeyInputView)
//
//struct ErrorView: View {
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
//            .buttonStyle(.borderedProminent).controlSize(.regular).padding(.top)
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
//                    .autocorrectionDisabled()
//                    .textInputAutocapitalization(.never)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 5)
//                            .stroke(isInvalidKeyAttempt ? Color.red : Color.clear, lineWidth: 1)
//                    )
//                    .onChange(of: inputApiKey) { // Use the two-argument version
//                         // Reset validation state when user types
//                         isInvalidKeyAttempt = false
//                    }
//
//                if isInvalidKeyAttempt {
//                     Text("API Key cannot be empty.")
//                          .font(.caption)
//                          .foregroundColor(.red)
//                          .transition(.opacity) // Add a subtle transition
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
//                         if trimmedKey.isEmpty || !trimmedKey.starts(with: "sk-") { // Basic validation
//                             withAnimation {
//                                 isInvalidKeyAttempt = true
//                             }
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
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Top Area: Icon or Placeholder
//            RoundedRectangle(cornerRadius: 12)
//                .fill(model.iconBackgroundColor.opacity(0.3))
//                .frame(height: 120)
//                 .overlay(
//                      Image(systemName: model.iconName)
//                           .resizable()
//                           .scaledToFit()
//                           .padding(25)
//                           .foregroundStyle(model.iconBackgroundColor) // Use color for symbol
//                 )
//
//            // Bottom Area: Text Details
//            VStack(alignment: .leading, spacing: 4) {
//                Text(model.displayName)
//                    .font(.headline)
//                Text(model.shortDescription)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                     .lineLimit(2) // Allow up to 2 lines for short description
//                     .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
//            }
//            .padding([.horizontal, .bottom], 12)
//            .frame(height: 50, alignment: .top) // Give text area some defined height
//        }
//        .background(.regularMaterial) // Use material background
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
//        .frame(minWidth: 0, maxWidth: .infinity) // Ensure it takes width in parent container
//    }
//}
//
//// --- Standard Model Row View (for Grids) ---
//struct StandardModelRow: View {
//    let model: OpenAIModel
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) { // Align to top for multi-line text
//            Image(systemName: model.iconName)
//                .resizable()
//                .scaledToFit()
//                .padding(7)
//                .frame(width: 36, height: 36)
//                .background(model.iconBackgroundColor.opacity(0.85))
//                .foregroundStyle(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 8)) // Slightly rounded square icon
//
//            VStack(alignment: .leading, spacing: 3) {
//                Text(model.displayName)
//                    .font(.subheadline.weight(.medium))
//                    .lineLimit(1) // Keep title to one line
//                Text(model.shortDescription)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .lineLimit(2) // Allow two lines for description
//                    .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
//            }
//            Spacer(minLength: 0) // Push content left
//        }
//        .padding(10)
//        .background(.regularMaterial) // Use material background
//        .clipShape(RoundedRectangle(cornerRadius: 10))
//        .overlay(
//            RoundedRectangle(cornerRadius: 10)
//                .stroke(Color.gray.opacity(0.15), lineWidth: 1) // Subtle border
//        )
//        // No shadow applied here, typical for grid items
//    }
//}
//
//// --- Reusable Section Header ---
//struct SectionHeader: View {
//    let title: String
//    let subtitle: String?
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title)
//                .font(.title2.weight(.semibold))
//            if let subtitle = subtitle, !subtitle.isEmpty {
//                Text(subtitle)
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding(.bottom, 10) // Space below header
//        .padding(.horizontal) // Standard horizontal padding for the section content
//    }
//}
//
//// --- Model Detail View (Enhanced for DALL-E 3 Details) ---
//struct ModelDetailView: View {
//    let model: OpenAIModel
//
//    var body: some View {
//        List {
//            // --- Prominent Icon/ID Section ---
//            Section {
//                VStack(spacing: 15) {
//                    Image(systemName: model.iconName)
//                        .resizable().scaledToFit()
//                        .padding(15).frame(width: 80, height: 80)
//                        .background(model.iconBackgroundColor)
//                        .foregroundStyle(.white)
//                        .clipShape(Circle())
//                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
//                    Text(model.displayName)
//                        .font(.title2.weight(.semibold))
//                        .multilineTextAlignment(.center)
//                    Text(model.shortDescription) // Add short description here
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//                }
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding(.vertical, 10)
//            }
//            .listRowBackground(Color.clear) // Make background transparent
//
//            // --- Core Details Section ---
//            Section("Overview") {
//                DetailRow(label: "Full ID", value: model.id)
//                DetailRow(label: "Type", value: model.object)
//                DetailRow(label: "Owner", value: model.ownedBy)
//                DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
//                 // Display specific fields if they exist
//                 if let performance = model.performance { DetailRow(label: "Performance", value: performance) }
//                 if let speed = model.speed { DetailRow(label: "Speed", value: speed) }
//                 if let pricing = model.pricing { DetailRow(label: "Pricing", value: pricing) }
//                 if let input = model.inputType { DetailRow(label: "Input", value: input) }
//                 if let output = model.outputType { DetailRow(label: "Output", value: output) }
////                 if let context = model.contextWindow, context != "N/A" { DetailRow(label: "Context Window", value: context) }
//            }
//
//            // --- Long Description Section ---
//            Section("Description") {
//                 Text(model.description)
//                     .font(.body)
//                     .foregroundColor(.primary)
//                     .padding(.vertical, 4) // Add padding for readability
//            }
//
//             // --- Capabilities / Supported Features Section ---
//             // Combine general capabilities and specific features
//             let allCapabilities = (model.capabilities.filter { $0 != "general" }) + (model.supportedFeatures ?? [])
//             if !allCapabilities.isEmpty {
//                 Section("Capabilities & Features") {
//                      WrappingHStack(items: Set(allCapabilities).sorted()) { capability in // Use Set to remove duplicates
//                          Label { Text(capability.capitalized) } icon: { capabilityIcon(capability) }
//                               .font(.caption)
//                               .padding(.horizontal, 8).padding(.vertical, 4)
//                               .background(Color.accentColor.opacity(0.15))
//                               .foregroundColor(.accentColor)
//                               .clipShape(Capsule())
//                      }
//                 }
//             }
//
//            // --- Supported Endpoints Section ---
//            if let endpoints = model.supportedEndpoints, !endpoints.isEmpty {
//                Section("Supported Endpoints") {
//                     WrappingHStack(items: endpoints) { endpoint in
//                         Text(endpoint.capitalized)
//                              .font(.caption2).padding(.horizontal, 8).padding(.vertical, 4)
//                              .foregroundStyle(.green.opacity(0.9))
//                              .background(Color.green.opacity(0.1))
//                              .clipShape(Capsule())
//                     }
//                }
//            }
//
//             // --- Unsupported Features/Endpoints Section ---
//             let allUnsupported = (model.unsupportedEndpoints ?? []) + (model.unsupportedFeatures ?? [])
//             if !allUnsupported.isEmpty {
//                 Section("Not Supported") {
//                     WrappingHStack(items: Set(allUnsupported).sorted()) { item in // Use Set to remove duplicates
//                         Text(item.capitalized)
//                               .font(.caption2)
//                               .padding(.horizontal, 8).padding(.vertical, 4)
//                               .foregroundStyle(.red.opacity(0.9))
//                               .background(Color.red.opacity(0.1))
//                               .clipShape(Capsule())
//                     }
//                 }
//             }
//
//            // --- Typical Use Cases Section ---
//            if !model.typicalUseCases.isEmpty && model.typicalUseCases != ["Various tasks"] {
//                 Section("Typical Use Cases") {
//                     ForEach(model.typicalUseCases, id: \.self) { useCase in
//                         // Use a simple Text row for use cases
//                         Text(useCase)
//                             .font(.callout)
//                     }
//                 }
//            }
//
//        }
//        .listStyle(.insetGrouped) // Standard grouped list style
//        .navigationTitle(model.displayName) // Use display name for title
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//     // Helper for capability tags
//    private func capabilityIcon(_ capability: String) -> Image {
//        let lower = capability.lowercased()
//        if lower.contains("image generation") { return Image(systemName: "photo.on.rectangle.angled") }
//        if lower.contains("text input") { return Image(systemName: "text.cursor") }
//        if lower.contains("image output") { return Image(systemName: "photo") }
//        if lower.contains("hd quality") { return Image(systemName: "h.square") }
//        if lower.contains("reasoning") { return Image(systemName: "brain.head.profile") }
//        if lower.contains("code") { return Image(systemName: "chevron.left.forwardslash.chevron.right") }
//        if lower.contains("vision") { return Image(systemName: "eye") }
//        if lower.contains("audio") { return Image(systemName: "speaker.wave.2") }
//        return Image(systemName: "checkmark.circle") // Default checkmark
//    }
//
//    // Standard Detail Row Helper (Unchanged)
//    private func DetailRow(label: String, value: String?) -> some View {
//        // Only show row if value exists and is not empty
//        if let value = value, !value.isEmpty {
//            EmptyView()
//            //HStack {
//                //Text(label).font(.callout).foregroundColor(.secondary)
//                //Spacer()
//                //Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
//           // }
//           // .padding(.vertical, 2)
//            //.accessibilityElement(children: .combine) as! EmptyView
//        } else {
//            EmptyView() // Return nothing if value is nil or empty
//        }
//    }
//}
//
//// MARK: - Main Content View (Using Sections)
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
//    // Adaptive grid to allow items to flow based on available space
//    let gridColumns: [GridItem] = [
//        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 15)
//    ]
//
//    // --- Filters for Sections (Based on Model IDs or Categories) ---
//    // ** Refined Filtering Logic **
//    // Prioritize categories, then specific IDs for ordering/grouping if needed
//    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "o4-mini", "o3"].contains($0.id) }.sortedById() }
//    var reasoningModels: [OpenAIModel] { allModels.filter { $0.id.starts(with: "o") || ($0.capabilities.contains("reasoning") && !$0.id.starts(with: "gpt")) }.sortedById() }
//    var flagshipChatModels: [OpenAIModel] { allModels.filter { $0.id.contains("gpt-4.1") || $0.id.contains("gpt-4o") || $0.id.contains("chatgpt-4o") }.sortedById() }
//    var costOptimizedModels: [OpenAIModel] { allModels.filter { $0.id.contains("-mini") || $0.id.contains("-nano") }.sortedById() }
//    var realtimeModels: [OpenAIModel] { allModels.filter { $0.id.contains("-realtime") }.sortedById() }
//    var olderGptModels: [OpenAIModel] { allModels.filter { ($0.id.starts(with: "gpt-") && !($0.id.contains("4.1") || $0.id.contains("4o") || $0.id.contains("mini") || $0.id.contains("nano"))) }.sortedById() }
//    var dalleModels: [OpenAIModel] { allModels.filter { $0.id.contains("dall-e") || $0.capabilities.contains("image generation") }.sortedById() }
//    var ttsModels: [OpenAIModel] { allModels.filter { $0.id.contains("tts") || $0.capabilities.contains("tts") }.sortedById() }
//    var transcriptionModels: [OpenAIModel] { allModels.filter { $0.id.contains("whisper") || $0.id.contains("transcribe") || $0.capabilities.contains("audio transcription") }.sortedById() }
//    var embeddingsModels: [OpenAIModel] { allModels.filter { $0.id.contains("embedding") || $0.capabilities.contains("text embedding") }.sortedById() }
//    var moderationModels: [OpenAIModel] { allModels.filter { $0.id.contains("moderation") || $0.capabilities.contains("content filtering") }.sortedById() }
//    var toolSpecificModels: [OpenAIModel] { allModels.filter { $0.id.contains("search") || $0.id.contains("computer-use") || $0.capabilities.contains("tool-use") }.sortedById() }
//
//    var body: some View {
//        NavigationStack {
//            ZStack { // Use ZStack for overlaying loading/error states
//                // --- Background Color ---
//                 Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
//
//                // --- Conditional Content Display ---
//                if isLoading && allModels.isEmpty {
//                    // --- Loading State View ---
//                     ProgressView("Fetching Models...")
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .zIndex(1) // Ensure it's above the main content
//
//                 } else if let errorMessage = errorMessage, allModels.isEmpty {
//                     // --- Error State View ---
//                     ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
//                        .background(Color(.systemGroupedBackground)) // Match background
//                        .zIndex(1) // Ensure it's above the main content
//
//                 } else {
//                    // --- Main Scrollable Content ---
//                    ScrollView(.vertical, showsIndicators: true) { // Show indicators for clarity
//                        VStack(alignment: .leading, spacing: 20) { // Main container for sections
//
//                             // --- Sticky Header Text ---
//                             VStack(alignment: .leading, spacing: 5) {
//                                 Text("Models")
//                                     .font(.largeTitle.weight(.bold))
//                                 Text("Explore available models and capabilities.")
//                                     .font(.title3)
//                                     .foregroundColor(.secondary)
//                             }
//                             .padding(.horizontal)
//                             .padding(.top)
//                             // Consider making this sticky if desired using GeometryReader tricks (complex)
//
//                             Divider().padding(.horizontal)
//
//                             // --- Featured Models Section (Horizontal Scroll) ---
//                             if !featuredModels.isEmpty {
//                                 SectionHeader(title: "Featured models", subtitle: "Highlights of the current model lineup.")
//                                 ScrollView(.horizontal, showsIndicators: false) {
//                                     HStack(spacing: 15) {
//                                         ForEach(featuredModels) { model in
//                                             NavigationLink(value: model) {
//                                                 FeaturedModelCard(model: model)
//                                                     .frame(width: 220) // Slightly smaller cards for horizontal scroll
//                                             }
//                                             .buttonStyle(.plain) // Remove default link button styling
//                                         }
//                                     }
//                                     .padding(.horizontal) // Padding *inside* the horizontal scroll
//                                     .padding(.bottom, 5) // Space after the horizontal scroll content
//                                 }
//                             }
//
//                            // --- Display Sections using Grid ---
//                            // Using ViewBuilder helper for cleaner code
//                            displaySection(title: "Reasoning models", subtitle: "o-series models that excel at complex, multi-step tasks.", models: reasoningModels)
//                            displaySection(title: "Flagship chat models", subtitle: "Our versatile, high-intelligence flagship models.", models: flagshipChatModels)
//                            displaySection(title: "Cost-optimized models", subtitle: "Smaller, faster models that cost less to run.", models: costOptimizedModels)
//                            displaySection(title: "Realtime models", subtitle: "Models capable of realtime text and audio inputs and outputs.", models: realtimeModels)
//                            displaySection(title: "Older GPT models", subtitle: "Supported older versions of our general purpose and chat models.", models: olderGptModels)
//                            displaySection(title: "DALL·E", subtitle: "Models that can generate and edit images given a natural language prompt.", models: dalleModels)
//                            displaySection(title: "Text-to-speech", subtitle: "Models that can convert text into natural sounding spoken audio.", models: ttsModels)
//                            displaySection(title: "Transcription", subtitle: "Model that can transcribe and translate audio into text.", models: transcriptionModels)
//                            displaySection(title: "Embeddings", subtitle: "A set of models that can convert text into vector representations.", models: embeddingsModels)
//                            displaySection(title: "Moderation", subtitle: "Fine-tuned models that detect whether input may be sensitive or unsafe.", models: moderationModels)
//                            displaySection(title: "Tool-specific models", subtitle: "Models to support specific built-in tools and functions.", models: toolSpecificModels)
//
//                             Spacer(minLength: 30) // Add some space at the bottom
//
//                        } // End Main VStack
//                    } // End ScrollView
//                    .refreshable { await loadModelsAsync(checkApiKey: false) } // Allow pull-to-refresh
//                 }
//            } // End ZStack
//            .navigationTitle("OpenAI Models") // Set the navigation bar title
//            .navigationBarTitleDisplayMode(.inline) // Use inline style
//            .toolbar {
//                 // --- Refresh/Loading Indicator Toolbar Item ---
//                 ToolbarItem(placement: .navigationBarLeading) {
//                     if isLoading { ProgressView().controlSize(.small) }
//                     else {
//                         Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
//                         .disabled(isLoading) // Disable refresh while loading
//                     }
//                 }
//                 // --- API Source Toggle Menu Toolbar Item ---
//                 ToolbarItem(placement: .navigationBarTrailing) {
//                     Menu {
//                         // Toggle directly controls the 'useMockData' state
//                         Toggle(isOn: $useMockData) {
//                             Text(useMockData ? "Using Mock Data" : "Using Live API")
//                         }
//                     } label: {
//                         // Label changes icon based on the current API source
//                         Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill")
//                           .foregroundColor(useMockData ? .secondary : .blue) // Visual cue for live data
//                     }
//                     .disabled(isLoading) // Disable toggle during load
//                     .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) } // Handle state change
//                 }
//             }
//             // --- Navigation Destination for ModelDetailView ---
//             .navigationDestination(for: OpenAIModel.self) { model in
//                 ModelDetailView(model: model)
//                       .toolbarBackground(.visible, for: .navigationBar) // Ensure background is visible
//                       .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar) // Set background color
//             }
//             // --- Initial Data Load Task ---
//             .task {
//                  if allModels.isEmpty { attemptLoadModels() } // Load data when view appears if empty
//             }
//             // --- API Key Input Sheet ---
//             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
//             // --- Alert for Errors After Initial Load ---
//             // This alert is only shown if there was already data displayed, and a subsequent load fails.
//             .alert("Error Loading Models", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: {
//                 Button("OK") { errorMessage = nil } // Dismiss alert
//             }, message: { Text(errorMessage ?? "An unknown error occurred.") })
//
//        } // End NavigationStack
//        .accentColor(.blue) // Set a global accent color if desired
//    }
//
//    // --- Helper View Builder for Displaying Sections ---
//    @ViewBuilder
//    private func displaySection(title: String, subtitle: String?, models: [OpenAIModel]) -> some View {
//         if !models.isEmpty {
//             Divider().padding(.horizontal) // Separator before the section
//             SectionHeader(title: title, subtitle: subtitle) // Display the header
//             LazyVGrid(columns: gridColumns, spacing: 15) { // Use LazyVGrid for performance
//                 ForEach(models) { model in
//                     NavigationLink(value: model) { // Grid item is a navigation link
//                         StandardModelRow(model: model)
//                     }
//                     .buttonStyle(.plain) // Use plain button style for the row appearance
//                 }
//             }
//             .padding(.horizontal) // Padding for the grid content
//             .padding(.bottom, 5) // Space below the grid
//         }
//         // Do not show anything if the section is empty
//    }
//
//    // --- Helper Functions for Loading, API Key Handling ---
//
//    // Called when the API source toggle changes
//    private func handleToggleChange(to newValue: Bool) {
//         print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API").")
//         // Clear existing data and error state
//         allModels = []
//         errorMessage = nil
//         // If switching to Live API and key is missing, show the input sheet
//         if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//             print("API Key missing, presenting sheet.")
//             showingApiKeySheet = true
//         } else {
//             // Otherwise, load data using the selected source
//             loadModelsAsyncWithLoadingState()
//         }
//    }
//
//    // Creates the API Key Input View for the sheet
//    private func presentApiKeySheet() -> some View {
//         APIKeyInputView(
//             onSave: { savedKey in // Called when user saves a valid key
//                 print("API Key saved via sheet.")
//                 // Automatically trigger loading live data after saving
//                 loadModelsAsyncWithLoadingState()
//             },
//             onCancel: { // Called when user cancels the sheet
//                 print("API Key input cancelled. Reverting to Mock Data.")
//                 // Revert the toggle back to Mock Data if cancelled
//                 useMockData = true
//             }
//         )
//    }
//
//    // Entry point for initiating a data load attempt (e.g., refresh button, initial load)
//    private func attemptLoadModels() {
//         guard !isLoading else { return } // Prevent multiple loads
//         // Check if Live API is selected but key is missing
//         if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//             print("Attempting load with Live API, but key missing. Showing sheet.")
//             showingApiKeySheet = true // Show sheet instead of loading
//         } else {
//             // Proceed with loading (either mock or live with key)
//             loadModelsAsyncWithLoadingState()
//         }
//     }
//
//    // Wraps the async load call with setting the loading state
//    private func loadModelsAsyncWithLoadingState() {
//         guard !isLoading else { return }
//         isLoading = true // Set loading flag
//         print("Starting model load sequence...")
//         Task { await loadModelsAsync(checkApiKey: false) } // Don't re-check key in the main async func
//    }
//
//    // The main asynchronous function to fetch models
//    @MainActor // Ensure UI updates happen on the main thread
//    private func loadModelsAsync(checkApiKey: Bool) async {
//        // Redundant check, but safe
//         if !isLoading { isLoading = true }
//
//         // Optional pre-check (usually handled by attemptLoadModels)
//         if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//             print("Pre-check failed: Key missing for live data.")
//             showingApiKeySheet = true
//             isLoading = false
//             return
//         }
//
//         let serviceToUse = currentApiService // Get the correct service (Mock or Live)
//         print("🔄 Loading models using \(type(of: serviceToUse))...")
//         errorMessage = nil // Clear previous error
//
//         do {
//             let fetchedModels = try await serviceToUse.fetchModels()
//             self.allModels = fetchedModels // Update the state with fetched models
//             print("✅ Successfully loaded \(fetchedModels.count) models.")
//         } catch let error as LocalizedError { // Catch known localized errors
//             print("❌ Error loading models: \(error.localizedDescription)")
//             self.errorMessage = error.localizedDescription
//             // Keep existing models if the error occurred during a refresh
//             // if allModels.isEmpty { self.allModels = [] } // Optional: Clear models on error only if list was empty
//         } catch { // Catch any other unexpected errors
//             print("❌ Unexpected error loading models: \(error)")
//             self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
//             // if allModels.isEmpty { self.allModels = [] }
//         }
//         isLoading = false // Reset loading flag regardless of success or failure
//         print("Model load sequence finished.")
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
////
////#Preview("Main View (Empty/Loading)") {
////    // Simulate loading state by returning the view in an empty/loading setup
////    OpenAIModelsMasterView // Pass state directly for preview
////}
////
////#Preview("Main View (Error State - Initial)") {
////     // Simulate initial error state
////    OpenAIModelsMasterView
////}
////
////#Preview("Featured Card Example") {
////    // Use the Mock Service to get a sample featured model
////    let featuredModel = MockAPIService().generateMockModels().first { $0.id == "gpt-4.1" }!
////    FeaturedModelCard(model: featuredModel)
////        .padding()
////        .frame(width: 250) // Define width for preview
////}
////
////#Preview("Standard Row Example") {
////     // Use the Mock Service to get a sample standard model
////     let standardModel = MockAPIService().generateMockModels().first { $0.id == "gpt-4o-mini" }!
////    StandardModelRow(model: standardModel)
////        .padding()
////         .frame(width: 350) // Wider for preview context
////}
////
////#Preview("Detail View (DALL-E 3)") {
////    // Get the detailed DALL-E 3 model from the mock service
////    let dalle3Model = MockAPIService().generateMockModels().first { $0.id == "dall-e-3" }!
////    NavigationStack { ModelDetailView(model: dalle3Model) }
////}
//
//#Preview("API Key Input Sheet") {
//    // Wrapper view to present the sheet in preview
//    struct SheetPresenter: View {
//        @State var showSheet = true
//        var body: some View {
//            Text("Previewing API Key Sheet")
//                .sheet(isPresented: $showSheet) {
//                    // Provide dummy closures for the preview
//                    APIKeyInputView(onSave: { key in print("Preview: Save key \(key)") }, onCancel: { print("Preview: Cancelled") })
//                }
//        }
//    }
//    return SheetPresenter()
//}
