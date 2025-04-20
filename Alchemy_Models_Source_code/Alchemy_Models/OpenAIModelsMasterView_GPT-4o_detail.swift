////
////  OpenAIModelsMasterView_GPT-4o_detail.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIModelsMasterView.swift
////  Alchemy_Models_Combined
////  (Single File Implementation - GPT-4o Enhanced)
////
////  Created: Cong Le
////  Date: 4/13/25 (Adapted: 2025-04-13 based on GPT-4o screenshots)
////  Version: 1.2 (Incorporated GPT-4o details)
////  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
////  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
////
//
//import SwiftUI
//import Foundation // Needed for URLSession, URLRequest, Date, TimeInterval, etc.
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
//// MARK: - Data Structures for Detail View
//
//struct SnapshotInfo: Codable, Hashable, Identifiable {
//    let id: String // Snapshot ID (e.g., "gpt-4o-2024-08-06")
//    var versionDate: String? { id.components(separatedBy: "-").suffix(3).joined(separator: "-") } // Extract date
//    let isAliasTarget: Bool // Is this the version the main alias points to?
//}
//
//struct RateLimitTier: Codable, Hashable, Identifiable {
//    var id: String { tier } // Use tier name as identifier
//    let tier: String // e.g., "Free", "Tier 1"
//    let rpm: Int?   // Requests Per Minute
//    let rpd: Int?   // Requests Per Day (Often null)
//    let tpm: Int?   // Tokens Per Minute
//    let batchQueueLimit: Int?
//}
//
//// MARK: - Data Models
//
//struct ModelListResponse: Codable {
//    let data: [OpenAIModel]
//}
//
//struct OpenAIModel: Codable, Identifiable, Hashable {
//    // --- Core Properties from API ---
//    let id: String
//    let object: String
//    let created: Int // Unix timestamp
//    let ownedBy: String
//
//    // --- Properties for List / Basic Display (with defaults) ---
//    var description: String = "No description available."
//    var capabilities: [String] = ["general"] // Broad capabilities
//    var contextWindow: String = "N/A" // General context window display string
//    var typicalUseCases: [String] = ["Various tasks"]
//    var shortDescription: String = "General purpose model."
//
//    // --- DETAILED Properties (Primarily for GPT-4o based on screenshots) ---
//    // These might be nil for other models or if fetched from the basic live API
//    var intelligenceRating: Int? = nil // 1-3 scale
//    var speedRating: Int? = nil      // 1-3 scale
//    var priceInputPerMilliTokens: Double? = nil  // USD per 1M input tokens
//    var priceCachedInputPerMilliTokens: Double? = nil // USD per 1M cached input tokens
//    var priceOutputPerMilliTokens: Double? = nil // USD per 1M output tokens
//
//    var inputModalities: [String]? = nil // e.g., ["Text", "Image"]
//    var outputModalities: [String]? = nil // e.g., ["Text"]
//    var unsupportedModalities: [String]? = nil // e.g., ["Audio"]
//
//    var maxContextWindowTokens: Int? = nil // e.g., 128000
//    var maxOutputTokens: Int? = nil      // e.g., 16384
//    var knowledgeCutoffDate: String? = nil // e.g., "Sep 30, 2023"
//
//    // Endpoint/Feature Support (Simpler representation than deep nesting)
//    var supportedEndpoints: [String]? = nil // e.g., ["Chat Completions", "Responses", "Assistants", "Fine-tuning"]
//    var unsupportedEndpoints: [String]? = nil // e.g., ["Realtime", "Batch", "Embeddings", ...]
//    var supportedFeatures: [String]? = nil // e.g., ["Streaming", "Function calling", "Structured outputs", ...]
//
//    var snapshots: [SnapshotInfo]? = nil // Array of snapshot details
//    var rateLimits: [RateLimitTier]? = nil // Array of rate limit tiers
//
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id
//        case object
//        case created
//        case ownedBy = "owned_by"
//        // Properties with defaults (Codable will use default if key missing)
//        case description, capabilities, contextWindow // Note: contextWindow string might be overwritten by detailed int below if present
//        case typicalUseCases, shortDescription
//        // Detailed properties keys (Optional, will be nil if missing JSON)
//        case intelligenceRating, speedRating
//        case priceInputPerMilliTokens = "price_input_usd_pmt" // Example JSON keys
//        case priceCachedInputPerMilliTokens = "price_cached_input_usd_pmt"
//        case priceOutputPerMilliTokens = "price_output_usd_pmt"
//        case inputModalities, outputModalities, unsupportedModalities
//        case maxContextWindowTokens, maxOutputTokens, knowledgeCutoffDate
//        case supportedEndpoints, unsupportedEndpoints, supportedFeatures
//        case snapshots, rateLimits
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
//    var iconName: String { // (Keep existing logic, maybe refine gpt-4o slightly)
//        let normalizedId = id.lowercased()
//        // GPT-4o gets priority
//        if normalizedId.contains("gpt-4o") || normalizedId.contains("chatgpt-4o") { return "wand.and.stars" } // Specific icon for gpt-4o
//        if normalizedId.contains("gpt-4.1") { return "sparkles" }
//        if normalizedId.contains("o4-mini") || normalizedId.contains("o3-mini") || normalizedId.contains("o1-mini") || normalizedId.contains("gpt-4.1-mini") { return "leaf.fill" }
//        if normalizedId.contains("o3") { return "circle.hexagonpath.fill" }
//        if normalizedId.contains("o1") || normalizedId.contains("o1-pro") { return "circles.hexagonpath.fill" }
//        if normalizedId.contains("gpt-4-turbo") { return "bolt.fill" }
//        if normalizedId.contains("gpt-4") && !normalizedId.contains("turbo") { return "star.fill"}
//        if normalizedId.contains("gpt-3.5") { return "forward.fill" }
//        if normalizedId.contains("dall-e") { return "paintbrush.pointed.fill" }
//        if normalizedId.contains("tts") { return "speaker.wave.2.fill" }
//        if normalizedId.contains("transcribe") || normalizedId.contains("whisper") { return "waveform" }
//        if normalizedId.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" }
//        if normalizedId.contains("moderation") { return "exclamationmark.shield.fill" }
//        if normalizedId.contains("search") { return "magnifyingglass"}
//        if normalizedId.contains("computer-use") { return "computermouse.fill" }
//        // Fallback based on owner
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return "building.columns.fill" }
//        if lowerOwner == "system" { return "gearshape.fill" }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return "person.crop.circle.fill" }
//        return "questionmark.circle.fill" // Default/fallback
//    }
//
//    // --- Determine background color for icons ---
//    var iconBackgroundColor: Color { // (Keep existing logic, maybe give gpt-4o a unique color)
//        let normalizedId = id.lowercased()
//        if normalizedId.contains("gpt-4o") { return .cyan } // Unique color for gpt-4o
//        if normalizedId.contains("gpt-4.1") { return .blue }
//        if normalizedId.contains("o4-mini") { return .purple }
//        if normalizedId.contains("o3") { return .orange }
//        if normalizedId.contains("dall-e") { return .teal }
//        if normalizedId.contains("tts") { return .indigo }
//        if normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return .pink }
//        if normalizedId.contains("embedding") { return .green }
//        if normalizedId.contains("moderation") { return .red }
//        if normalizedId.contains("search") { return .cyan }
//        if normalizedId.contains("computer-use") { return .brown }
//        // Fallback based on owner
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return .blue.opacity(0.8) }
//        if lowerOwner == "system" { return .orange.opacity(0.8) }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return .purple.opacity(0.8) }
//        return .gray.opacity(0.7) // Default/fallback
//    }
//
//    // --- Simplified name for display ---
//    var displayName: String { // (Keep existing logic)
//        return id.replacingOccurrences(of: "-", with: " ").capitalized
//    }
//}
//
//// MARK: - API Service Implementations
//
//// --- Mock Data Service ---
//class MockAPIService: APIServiceProtocol {
//    private let mockNetworkDelaySeconds: Double = 0.5 // Slightly faster mock
//
//    // Enhanced mock models including detailed GPT-4o
//    private func generateMockModels() -> [OpenAIModel] {
//        // GPT-4o specific data based on screenshots
//        let gpt4o = OpenAIModel(
//            id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai",
//            description: "Our versatile, high-intelligence flagship model. It accepts both text and image inputs, and produces text outputs (including Structured Outputs). It is the best model for most tasks, and is our most capable model outside of our o-series models.",
//            capabilities: ["text generation", "reasoning", "code", "vision", "audio"], // Combined from description/modality
//            contextWindow: "128k / 8k Vision", // Rough combination
//            typicalUseCases: ["Math Tutor", "Travel Assistant", "Clothing Recommendation", "Recipe Generation"], // From examples
//            shortDescription: "Fast, intelligent, flexible GPT model",
//            // Detailed GPT-4o data:
//            intelligenceRating: 3, speedRating: 2,
//            priceInputPerMilliTokens: 2.50,
//            priceCachedInputPerMilliTokens: 1.25,
//            priceOutputPerMilliTokens: 10.00,
//            inputModalities: ["Text", "Image"], outputModalities: ["Text"], unsupportedModalities: ["Audio"], // Note: Audio contradiction, using endpoint list as source of truth
//            maxContextWindowTokens: 128000, maxOutputTokens: 16384, knowledgeCutoffDate: "Sep 30, 2023",
//            supportedEndpoints: ["Chat Completions", "Responses", "Assistants", "Fine-tuning"],
//            unsupportedEndpoints: ["Realtime", "Batch", "Embeddings", "Speech generation", "Translation", "Completions (legacy)", "Image generation", "Transcription", "Moderation"],
//            supportedFeatures: ["Streaming", "Function calling", "Structured outputs", "Fine-tuning", "Distillation", "Predicted outputs"],
//            snapshots: [
//                SnapshotInfo(id: "gpt-4o-2024-11-20", isAliasTarget: false),
//                SnapshotInfo(id: "gpt-4o-2024-08-06", isAliasTarget: true), // Alias target
//                SnapshotInfo(id: "gpt-4o-2024-05-13", isAliasTarget: false)
//            ],
//            rateLimits: [ // Only including Tier 1 for brevity in mock
//                RateLimitTier(tier: "Tier 1", rpm: 500, rpd: nil, tpm: 30_000, batchQueueLimit: 90_000)
//            ]
//        )
//
//        // Reuse other models from previous implementation (maybe update short descriptions)
//        let otherModels: [OpenAIModel] = [
//             OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k", shortDescription: "Flagship GPT model for complex tasks"),
//             OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Faster, more affordable reasoning model"),
//             OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "16k", shortDescription: "Previous gen powerful reasoning model"),
//             OpenAIModel(id: "o3-mini", object: "model", created: 1699000000, ownedBy: "openai", description: "A smaller, faster, and more affordable alternative to o3.", capabilities: ["text generation", "reasoning"], contextWindow: "16k", shortDescription: "A small model alternative to o3"),
//             OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Previous full o-series reasoning model"),
//             OpenAIModel(id: "o1-pro", object: "model", created: 1685000000, ownedBy: "openai", description: "Version of o1 with more compute for better responses.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Version of o1 with more compute"),
//             OpenAIModel(id: "o1-mini", object: "model", created: 1675000000, ownedBy: "openai", description: "A small model alternative to o1, very fast.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "A small model alternative to o1"),
//             OpenAIModel(id: "gpt-4o-audio", object: "model", created: 1712850000, ownedBy: "openai", description: "GPT-4o models capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "GPT-4o models capable of audio IO"),
//             OpenAIModel(id: "chatgpt-4o-latest", object: "model", created: 1712900000, ownedBy: "openai", description: "GPT-4o model used in ChatGPT.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "GPT-4o model used in ChatGPT"),
//             OpenAIModel(id: "gpt-4.1-mini", object: "model", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Balanced for intelligence, speed, cost"),
//             OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fastest, most cost-effective GPT-4.1"),
//             OpenAIModel(id: "gpt-4o-mini", object: "model", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model"),
//             OpenAIModel(id: "gpt-4o-mini-audio", object: "model", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "Smaller model capable of audio IO"),
//             OpenAIModel(id: "gpt-4o-realtime", object: "model", created: 1712860000, ownedBy: "openai", description: "Model capable of realtime text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Model capable of realtime text/audio"),
//             OpenAIModel(id: "gpt-4o-mini-realtime", object: "model", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Smaller realtime model for text/audio"),
//             OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "128k", shortDescription: "Older high-intelligence GPT model"),
//             OpenAIModel(id: "gpt-4", object: "model", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "8k / 32k", shortDescription: "Older high-intelligence GPT model"),
//             OpenAIModel(id: "gpt-3.5-turbo", object: "model", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", capabilities: ["text generation"], contextWindow: "4k / 16k", shortDescription: "Legacy GPT model for cheaper tasks"),
//             OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Latest image generation model"),
//             OpenAIModel(id: "dall-e-2", object: "model", created: 1650000000, ownedBy: "openai", description: "Our first image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "First image generation model"),
////             // Add more models here if needed, ensuring shortDescription is concise
//        ]
//
//        // Combine and return, potentially sorting or arranging as needed
//        return [gpt4o] + otherModels
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
//class LiveAPIService: APIServiceProtocol { // (No changes needed here, it correctly decodes basic fields)
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
//            if httpResponse.statusCode == 401 { throw LiveAPIError.missingAPIKey } // Rate limit or invalid key
//            guard (200...299).contains(httpResponse.statusCode) else { throw LiveAPIError.requestFailed(statusCode: httpResponse.statusCode) }
//
//            do {
//                 let decoder = JSONDecoder()
//                 let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
//                 print("✅ Successfully decoded \(responseWrapper.data.count) models.")
//                 // Live API only returns basic fields. Detailed fields will remain nil/default.
//                 return responseWrapper.data
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
//struct ErrorView: View { // (Unchanged)
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
//struct WrappingHStack<Item: Hashable, ItemView: View>: View { // (Unchanged)
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
//struct APIKeyInputView: View { // (Unchanged)
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
//                             isInvalidKeyAttempt = true
//                         } else {
//                             apiKey = trimmedKey
//                             onSave(apiKey)
//                             dismiss()
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
//                 inputApiKey = apiKey
//                 isInvalidKeyAttempt = false
//             }
//        }
//    }
//}
//
//// MARK: - Model Views (Featured Card, Standard Row, Detail)
//
//struct FeaturedModelCard: View { // (Unchanged)
//    let model: OpenAIModel
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(model.iconBackgroundColor.opacity(0.3))
//                .frame(height: 120)
//                 .overlay( Image(systemName: model.iconName)
//                      .resizable().scaledToFit().padding(25)
//                      .foregroundStyle(model.iconBackgroundColor) )
//            VStack(alignment: .leading, spacing: 4) {
//                Text(model.displayName).font(.headline)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
//            }.padding([.horizontal, .bottom], 12)
//        }
//        .background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 15))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
//        .frame(minWidth: 0, maxWidth: .infinity)
//    }
//}
//
//struct StandardModelRow: View { // (Unchanged)
//    let model: OpenAIModel
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: model.iconName).resizable().scaledToFit()
//                .padding(7).frame(width: 36, height: 36)
//                .background(model.iconBackgroundColor.opacity(0.85)).foregroundStyle(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//            VStack(alignment: .leading, spacing: 3) {
//                Text(model.displayName).font(.subheadline.weight(.medium)).lineLimit(1)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
//            }
//            Spacer(minLength: 0)
//        }
//        .padding(10).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
//        .overlay( RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1) )
//    }
//}
//
//struct SectionHeader: View { // (Unchanged)
//    let title: String
//    let subtitle: String?
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title).font(.title2.weight(.semibold))
//            if let subtitle = subtitle { Text(subtitle).font(.callout).foregroundColor(.secondary) }
//        }
//        .padding(.bottom, 10).padding(.horizontal)
//    }
//}
//
//// MARK: - Model Detail View (Enhanced for GPT-4o)
//
//struct ModelDetailView: View {
//    let model: OpenAIModel
//
//    // Helper for formatting numbers
//    private func formatNumber(_ number: Int) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
//    }
//
//    var body: some View {
//        List {
//            // --- Top Section: Icon, Name, Description ---
//            Section {
//                VStack(spacing: 15) {
//                    Image(systemName: model.iconName).resizable().scaledToFit()
//                        .padding(15).frame(width: 80, height: 80)
//                        .background(model.iconBackgroundColor).foregroundStyle(.white)
//                        .clipShape(Circle())
//                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
//                    Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
//                    Text(model.description) // Use full description here
//                        .font(.callout)
//                        .multilineTextAlignment(.center)
//                        .foregroundColor(.secondary)
//                        .padding(.horizontal)
//                }
//                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
//            }
//            .listRowBackground(Color.clear)
//
//            // --- Section: Performance Ratings & Specs ---
//             Section("Performance & Specs") {
//                 // Ratings (Visual representation if available)
//                 HStack {
//                     RatingView(label: "Intelligence", rating: model.intelligenceRating, maxRating: 3, filledColor: .blue)
//                     Spacer()
//                     RatingView(label: "Speed", rating: model.speedRating, maxRating: 3, filledColor: .green)
//                 }
//
//                 // Key Specs
//                 if let contextTokens = model.maxContextWindowTokens {
//                     DetailRow(label: "Context Window", value: "\(formatNumber(contextTokens)) tokens")
//                 }
//                 if let outputTokens = model.maxOutputTokens {
//                     DetailRow(label: "Max Output Tokens", value: "\(formatNumber(outputTokens)) tokens")
//                 }
//                 if let cutoff = model.knowledgeCutoffDate {
//                     DetailRow(label: "Knowledge Cutoff", value: cutoff)
//                 }
//             }
//
//            // --- Section: Pricing (if available) ---
//             if model.priceInputPerMilliTokens != nil || model.priceOutputPerMilliTokens != nil {
//                 Section("Pricing (USD per 1M Tokens)") {
//                     if let inputPrice = model.priceInputPerMilliTokens {
//                         DetailRow(label: "Input", value: String(format: "$%.2f", inputPrice))
//                     }
//                     if let cachedPrice = model.priceCachedInputPerMilliTokens {
//                         DetailRow(label: "Cached Input", value: String(format: "$%.2f", cachedPrice))
//                     }
//                     if let outputPrice = model.priceOutputPerMilliTokens {
//                         DetailRow(label: "Output", value: String(format: "$%.2f", outputPrice))
//                     }
//                 }
//             }
//
//             // --- Section: Modalities ---
//             Section("Modalities") {
//                 HStack(alignment: .top, spacing: 20) {
//                     ModalityListView(title: "Input", supported: model.inputModalities, iconPrefix: "arrow.down.circle")
//                     Spacer()
//                     ModalityListView(title: "Output", supported: model.outputModalities, iconPrefix: "arrow.up.circle")
//                 }
//                  // Display unsupported modalities if specified
//                  if let unsupported = model.unsupportedModalities, !unsupported.isEmpty {
//                       VStack(alignment: .leading) {
//                           Text("Not Supported").font(.caption).foregroundColor(.secondary)
//                           WrappingHStack(items: unsupported) { modality in
//                               Label(modality, systemImage: modalityIcon(modality) ?? "questionmark.circle")
//                                    .font(.caption).padding(.horizontal, 6).padding(.vertical, 3)
//                                    .foregroundStyle(.secondary)
//                                    .background(Color.gray.opacity(0.1)).clipShape(Capsule())
//                                    .strikethrough()
//                           }
//                       }
//                       .padding(.top, 5)
//                   }
//             }
//
//             // --- Section: Endpoints ---
//             Section("Endpoints") {
//                 EndpointFeatureListView(title: "Supported", items: model.supportedEndpoints, supported: true)
//                 EndpointFeatureListView(title: "Not Supported", items: model.unsupportedEndpoints, supported: false)
//             }
//
//             // --- Section: Features ---
//            if let features = model.supportedFeatures, !features.isEmpty {
//                Section("Features") {
//                    WrappingHStack(items: features) { feature in
//                        Label(feature, systemImage: featureIcon(feature) ?? "checkmark.circle")
//                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
//                            .background(Color.accentColor.opacity(0.15))
//                            .foregroundColor(Color.accentColor)
//                            .clipShape(Capsule())
//                    }
//                    .padding(.vertical, 4) // Add padding inside section
//                }
//            }
//
//             // --- Section: Snapshots (if available) ---
//            if let snaps = model.snapshots, !snaps.isEmpty {
//                Section("Snapshots") {
//                    ForEach(snaps) { snapshot in
//                        HStack {
//                             Text(snapshot.id)
//                                 .font(.system(.callout, design: .monospaced)) // Monospaced for ID
//                             Spacer()
//                             if snapshot.isAliasTarget {
//                                 Text("Alias Target")
//                                     .font(.caption)
//                                     .foregroundStyle(.secondary)
//                                     .padding(.horizontal, 6)
//                                     .background(Color.gray.opacity(0.15))
//                                     .clipShape(Capsule())
//                             }
//                         }
//                    }
//                }
//            }
//
//              // --- Section: Rate Limits (Example - Tier 1) ---
//            if let limits = model.rateLimits, let tier1 = limits.first(where: {$0.tier == "Tier 1"}) {
//                Section("Rate Limits (Example: Tier 1)") {
//                    if let rpm = tier1.rpm { DetailRow(label: "RPM (Requests/min)", value: formatNumber(rpm)) }
//                    if let tpm = tier1.tpm { DetailRow(label: "TPM (Tokens/min)", value: formatNumber(tpm)) }
//                    if let batch = tier1.batchQueueLimit { DetailRow(label: "Batch Queue Limit", value: formatNumber(batch)) }
//                 }
//             }
//
//            // --- Original Sections (General Info) ---
//            Section("General Info") {
//                DetailRow(label: "Full ID", value: model.id)
//                DetailRow(label: "Type", value: model.object)
//                DetailRow(label: "Owner", value: model.ownedBy)
//                DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
//            }
//            // Capabilities as fallback if specific features aren't listed
//            if (model.supportedFeatures ?? []).isEmpty && !model.capabilities.isEmpty && model.capabilities != ["general"] {
//                Section("Capabilities (General)") {
//                    WrappingHStack(items: model.capabilities) { capability in
//                        Text(capability)
//                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
//                            .background(Color.accentColor.opacity(0.2))
//                            .foregroundColor(.accentColor).clipShape(Capsule())
//                    }
//                }
//            }
//        }
//        .listStyle(.insetGrouped)
//        .navigationTitle(model.displayName) // Use display name in title
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//    // --- Helper Views for Detail Sections ---
//
//    private func DetailRow(label: String, value: String) -> some View { // (Unchanged)
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//            Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
//        }
//        .padding(.vertical, 2)
//        .accessibilityElement(children: .combine)
//    }
//
//    @ViewBuilder
//    private func RatingView(label: String, rating: Int?, maxRating: Int, filledColor: Color) -> some View {
//         if let rating = rating {
//             VStack(alignment: .leading, spacing: 2) {
//                 Text(label).font(.caption).foregroundColor(.secondary)
//                 HStack(spacing: 2) {
//                     ForEach(0..<maxRating, id: \.self) { index in
//                         Image(systemName: index < rating ? "circle.fill" : "circle")
//                             .font(.caption) // Small circles
//                             .foregroundColor(index < rating ? filledColor : .gray.opacity(0.3))
//                     }
//                 }
//             }
//             .accessibilityElement(children: .combine)
//             .accessibilityLabel("\(label): \(rating) out of \(maxRating)")
//         } else { EmptyView() }
//     }
//
//     @ViewBuilder
//     private func ModalityListView(title: String, supported: [String]?, iconPrefix: String) -> some View {
//         VStack(alignment: .leading, spacing: 5) {
//             Text(title).font(.subheadline.weight(.medium))
//             if let items = supported, !items.isEmpty {
//                 ForEach(items, id: \.self) { item in
//                     Label(item, systemImage: modalityIcon(item) ?? (iconPrefix + ".fill"))
//                         .font(.callout)
//                 }
//             } else {
//                 Text("None").font(.callout).foregroundColor(.secondary)
//             }
//         }
//     }
//
//     @ViewBuilder
//     private func EndpointFeatureListView(title: String, items: [String]?, supported: Bool) -> some View {
//         VStack(alignment: .leading, spacing: 5) {
//             Text(title)
//                 .font(.subheadline)
//                 .foregroundColor(supported ? .primary : .secondary)
//             if let items = items, !items.isEmpty {
//                 ForEach(items, id: \.self) { item in
//                     Label {
//                         Text(item).strikethrough(!supported, color: .secondary)
//                     } icon: {
//                         Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
//                               .foregroundColor(supported ? .green : .red)
//                     }
//                     .font(.callout)
//                     .foregroundColor(supported ? .primary : .secondary)
//                 }
//             } else {
//                 Text("None Specified").font(.callout).foregroundColor(.secondary)
//             }
//         }
//         .padding(.vertical, 4)
//     }
//
//    // --- Icon Mapping Helpers ---
//    private func modalityIcon(_ modality: String) -> String? {
//          switch modality.lowercased() {
//          case "text": return "doc.text.fill"
//          case "image", "vision": return "photo.fill"
//          case "audio": return "speaker.wave.2.fill"
//          default: return nil
//          }
//      }
//
//    private func featureIcon(_ feature: String) -> String? {
//        switch feature.lowercased() {
//        case "streaming": return "arrow.triangle.2.circlepath"
//        case "function calling": return "curlybraces.square.fill"
//        case "structured outputs": return "list.bullet.rectangle.portrait.fill"
//        case "fine-tuning": return "tuningfork"
//        case "distillation": return "drop.fill"
//        case "predicted outputs": return "wand.and.rays"
//        default: return "checkmark.seal.fill" // Generic checkmark
//        }
//    }
//}
//
//// MARK: - Main Content View (Adjusted for Sections)
//
//struct OpenAIModelsMasterView: View { // (Structure largely unchanged, filtering adjusted)
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
//    // --- Filters for Sections (Based on Model IDs/Capabilities - Refined) ---
//    // Note: These filters are simplified. A better approach might involve tags or categories within the model data itself.
//    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4o", "gpt-4.1", "o4-mini"].contains($0.id) }.sortedById() }
//    var reasoningModels: [OpenAIModel] { allModels.filter { $0.id.starts(with: "o") || $0.capabilities.contains("reasoning") && !$0.id.starts(with: "gpt-4o") }.sortedById() } // Broaden reasoning
//    var flagshipChatModels: [OpenAIModel] { allModels.filter { ["gpt-4o", "gpt-4.1", "gpt-4-turbo"].contains($0.id) || $0.id.contains("chatgpt-4o") }.sortedById() }
//    var costOptimizedModels: [OpenAIModel] { allModels.filter { $0.id.contains("mini") || $0.id.contains("nano") || $0.id.contains("gpt-3.5") }.sortedById() }
//    var realtimeModels: [OpenAIModel] { allModels.filter { $0.id.contains("realtime") }.sortedById() }
//    var visionModels: [OpenAIModel] { allModels.filter { ($0.capabilities.contains("vision") || $0.inputModalities?.contains("Image") ?? false) }.sortedById() }
//    var imageGenModels: [OpenAIModel] { allModels.filter { $0.id.contains("dall-e") }.sortedById() }
//    var ttsModels: [OpenAIModel] { allModels.filter { $0.id.contains("tts") }.sortedById() }
//    var transcriptionModels: [OpenAIModel] { allModels.filter { $0.id.contains("whisper") || $0.id.contains("transcribe") }.sortedById() }
//    var embeddingsModels: [OpenAIModel] { allModels.filter { $0.id.contains("embedding") }.sortedById() }
//    var moderationModels: [OpenAIModel] { allModels.filter { $0.id.contains("moderation") }.sortedById() }
//    var toolSpecificModels: [OpenAIModel] { allModels.filter { $0.id.contains("search") || $0.id.contains("computer-use") }.sortedById() }
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                if isLoading && allModels.isEmpty {
//                     ProgressView("Fetching Models...")
//                           .frame(maxWidth: .infinity, maxHeight: .infinity)
//                           .background(Color(.systemBackground)).zIndex(1)
//                 } else if let errorMessage = errorMessage, allModels.isEmpty {
//                     ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
//                 } else {
//                    ScrollView(.vertical, showsIndicators: false) {
//                        VStack(alignment: .leading, spacing: 30) {
//                             // --- Header Text ---
//                             VStack(alignment: .leading, spacing: 5) {
//                                 Text("Models")
//                                     .font(.largeTitle.weight(.bold))
//                                 Text("Explore all available models and compare their capabilities.")
//                                     .font(.title3)
//                                     .foregroundColor(.secondary)
//                             }.padding(.horizontal)
//                             Divider().padding(.horizontal)
//                             // --- Featured Models Section ---
//                             SectionHeader(title: "Featured models", subtitle: nil)
//                             ScrollView(.horizontal, showsIndicators: false) {
//                                 HStack(spacing: 15) {
//                                     ForEach(featuredModels) { model in
//                                         NavigationLink(value: model) {
//                                             FeaturedModelCard(model: model).frame(width: 250)
//                                         }.buttonStyle(.plain)
//                                     }
//                                 }.padding(.horizontal).padding(.bottom, 5)
//                             }
//                             // --- Standard Sections ---
//                             // Reorder/group sections logically based on model purpose
//                             displaySection(title: "Flagship Chat Models (GPT-4 Series)", subtitle: "Our most versatile, high-intelligence models with multimodal capabilities.", models: flagshipChatModels)
//                             displaySection(title: "Reasoning Models (O-Series)", subtitle: "Models that excel at complex, multi-step tasks.", models: reasoningModels)
//                             displaySection(title: "Cost-Optimized & Older Models", subtitle: "Smaller, faster, older, or more focused models.", models: costOptimizedModels)
//                            // displaySection(title: "Realtime Models", subtitle: "Models optimized for low-latency interactions.", models: realtimeModels) // Often overlaps
//                            displaySection(title: "Vision Capable Models", subtitle: "Models that can process and understand images.", models: visionModels)
//                            displaySection(title: "Image Generation (DALL·E)", subtitle: "Models that generate images from text prompts.", models: imageGenModels)
//                            displaySection(title: "Text-to-Speech (TTS)", subtitle: "Models that convert text into spoken audio.", models: ttsModels)
//                            displaySection(title: "Transcription (Whisper)", subtitle: "Models that transcribe and translate audio.", models: transcriptionModels)
//                            displaySection(title: "Embeddings", subtitle: "Models that convert text into vector representations.", models: embeddingsModels)
//                            displaySection(title: "Moderation", subtitle: "Models that detect potentially harmful content.", models: moderationModels)
//                            displaySection(title: "Tool-Specific Models", subtitle: "Models designed to support specific built-in tools.", models: toolSpecificModels)
//
//                             Spacer(minLength: 50)
//                        }.padding(.top)
//                    }
//                    .background(Color(.systemBackground))
//                    .edgesIgnoringSafeArea(.bottom)
//                 }
//            }
//            .navigationTitle("OpenAI Models")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { // (Toolbar unchanged)
//                 ToolbarItem(placement: .navigationBarLeading) {
//                     if isLoading { ProgressView().controlSize(.small) }
//                     else { Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(isLoading) }
//                 }
//                 ToolbarItem(placement: .navigationBarTrailing) {
//                     Menu { Toggle(isOn: $useMockData) { Text(useMockData ? "Using Mock Data" : "Using Live API") } }
//                     label: { Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill").foregroundColor(useMockData ? .secondary : .blue) }
//                     .disabled(isLoading)
//                 }
//             }
//             .navigationDestination(for: OpenAIModel.self) { model in // (Unchanged)
//                 ModelDetailView(model: model)
//                       .toolbarBackground(.visible, for: .navigationBar)
//                       .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
//             }
//             .task { if allModels.isEmpty { attemptLoadModels() } } // (Unchanged)
//             .refreshable { await loadModelsAsync(checkApiKey: false) } // (Unchanged)
//             .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) } // (Unchanged)
//             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() } // (Unchanged)
//             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: { // (Unchanged)
//                 Button("OK") { errorMessage = nil }
//             }, message: { Text(errorMessage ?? "An unknown error occurred.") })
//        } // End NavigationStack
//    }
//
//    // --- Helper View Builder for Grid Sections (Unchanged) ---
//    @ViewBuilder
//    private func displaySection(title: String, subtitle: String?, models: [OpenAIModel]) -> some View {
//         if !models.isEmpty {
//             Divider().padding(.horizontal)
//             SectionHeader(title: title, subtitle: subtitle)
//             LazyVGrid(columns: gridColumns, spacing: 15) {
//                 ForEach(models) { model in
//                     NavigationLink(value: model) { StandardModelRow(model: model) }.buttonStyle(.plain)
//                 }
//             }.padding(.horizontal)
//         } else { EmptyView() }
//    }
//
//    // --- Helper Functions for Loading & API Key Handling (Unchanged) ---
//    private func handleToggleChange(to newValue: Bool) {
//         print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
//         allModels = [] ; errorMessage = nil
//         if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true }
//         else { loadModelsAsyncWithLoadingState() }
//    }
//    private func presentApiKeySheet() -> some View {
//         APIKeyInputView( onSave: { _ in print("API Key saved."); loadModelsAsyncWithLoadingState() },
//             onCancel: { print("API Key input cancelled."); useMockData = true } )
//    }
//    private func attemptLoadModels() {
//         guard !isLoading else { return }
//         if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true }
//         else { loadModelsAsyncWithLoadingState() }
//     }
//    private func loadModelsAsyncWithLoadingState() {
//         guard !isLoading else { return }
//         isLoading = true; Task { await loadModelsAsync(checkApiKey: false) }
//    }
//    @MainActor private func loadModelsAsync(checkApiKey: Bool) async {
//         if !isLoading { isLoading = true }
//         if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//             showingApiKeySheet = true; isLoading = false; return
//         }
//         let serviceToUse = currentApiService
//         print("🔄 Loading models using \(useMockData ? "MockAPIService" : "LiveAPIService")...")
//         do {
//             let fetchedModels = try await serviceToUse.fetchModels()
//             self.allModels = fetchedModels; self.errorMessage = nil
//             print("✅ Successfully loaded \(fetchedModels.count) models.")
//         } catch let error as LocalizedError {
//             print("❌ Error loading models: \(error.localizedDescription)"); self.errorMessage = error.localizedDescription
//             if allModels.isEmpty { self.allModels = [] }
//         } catch {
//             print("❌ Unexpected error loading models: \(error)"); self.errorMessage = "Unexpected error: \(error.localizedDescription)"
//             if allModels.isEmpty { self.allModels = [] }
//         }
//         isLoading = false
//    }
//}
//
//// MARK: - Helper Extensions (Unchanged)
//
//extension Array where Element == OpenAIModel {
//    func sortedById() -> [OpenAIModel] { self.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending } }
//}
//
//// MARK: - Previews
//
//#Preview("Main View (Mock Data)") {
//    OpenAIModelsMasterView()
//}
//
////#Preview("Detail View (GPT-4o Mock)") {
////    // Find the mock gpt-4o model to preview
////    let mockService = MockAPIService()
////    let mockModels = try? await mockService.fetchModels() // Call directly for preview
////    let gpt4oModel = mockModels?.first(where: { $0.id == "gpt-4o" })
////        ?? OpenAIModel(id: "gpt-4o-preview-error", object: "model", created: 1, ownedBy: "system") // Fallback
////
////    return NavigationStack { ModelDetailView(model: gpt4oModel) }
////}
////
////#Preview("API Key Input Sheet") {
////    struct SheetPresenter: View { @State var showSheet = true
////        var body: some View { Text("Tap to show sheet (already shown)").sheet(isPresented: $showSheet) { APIKeyInputView(onSave: {_ in}, onCancel: {}) } }
////    }
////    return SheetPresenter()
////}
