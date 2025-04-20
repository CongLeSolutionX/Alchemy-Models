////
////  OpenAIModelsMasterView_GPT-4o_audio.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIModelsMasterView_vGPT4oAudio.swift
////  Alchemy_Models_Combined
////  (Single File Implementation with GPT-4o Audio Details)
////
////  Created: Cong Le
////  Date: 4/13/25 (Based on previous iterations, incorporating GPT-4o Audio specifics)
////  Version: 1.2
////  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
////  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
////
//
//import SwiftUI
//import Foundation // Needed for URLSession, URLRequest, Date etc.
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
//// Wrapper for the overall API list response
//struct ModelListResponse: Codable {
//    let data: [OpenAIModel]
//}
//
//// Main data model for an OpenAI model
//struct OpenAIModel: Codable, Identifiable, Hashable {
//    // --- Core Properties (from standard /v1/models) ---
//    let id: String
//    let object: String
//    let created: Int // Unix timestamp
//    let ownedBy: String
//
//    // --- Optional Detailed Properties (added based on model specifics/screenshots) ---
//    // These have default values so they work with both mock (detailed) and live (basic) data.
//    // Basic Info / Descriptions
//    var description: String = "No description available."
//    var shortDescription: String = "General purpose model."
//    var capabilities: [String] = ["general"] // General task capabilities
//    var typicalUseCases: [String] = ["Various tasks"]
//
//    // Technical Specs
//    var contextWindow: String = "N/A"
//    var maxOutputTokens: String? = nil // Optional, e.g., "16,384 tokens"
//    var knowledgeCutoff: String? = nil // Optional, e.g., "Sep 30, 2023"
//
//    // Pricing (Store as strings for flexible formatting)
//    var pricingTextTokens: String? = nil // e.g., "$2.50 / 1M (Input), $10.00 / 1M (Output)"
//    var pricingAudioTokens: String? = nil // e.g., "$40.00 / 1M (Input), $80.00 / 1M (Output)"
//
//    // Modalities (Simplification - derived or explicit, using strings for now)
//    var inputModalities: [String]? = ["Text"] // Default
//    var outputModalities: [String]? = ["Text"] // Default
//
//    // Features & Endpoints (Lists of supported items)
//    var supportedEndpoints: [String]? = nil // e.g., ["Chat Completions"]
//    var supportedFeatures: [String]? = nil  // e.g., ["Streaming", "Function Calling"]
//
//    // Snapshots/Versions
//    var snapshots: [String]? = nil // List of snapshot IDs/aliases, e.g., ["gpt-4o-audio-preview"]
//
//    // Subjective Ratings (Optional - might be better derived or not stored directly)
//    var intelligenceRating: String? = nil // e.g., "High"
//    var speedRating: String? = nil // e.g., "Medium"
//
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id, object, created
//        case ownedBy = "owned_by"
//        // IMPORTANT: The optional detailed properties are *not* listed here.
//        // Codable will ignore them during standard JSON decoding if they aren't present
//        // in the live API response, allowing the default values above to be used.
//        // If mock data *does* include them, they *will* be overwritten by the mock values during decoding.
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
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") { return "sparkles" }
//        if normalizedId.contains("gpt-4o-audio") { return "waveform.badge.mic"} // SPECIFIC ICON for Audio model
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
//        if normalizedId.contains("gpt-4o-audio") { return .purple } // SPECIFIC COLOR
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") { return .blue }
//        if normalizedId.contains("o4-mini") { return .purple }
//        if normalizedId.contains("o3") { return .orange }
//        if normalizedId.contains("dall-e") { return .teal }
//        if normalizedId.contains("tts") { return .indigo }
//        if normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return .pink }
//        if normalizedId.contains("embedding") { return .green }
//        if normalizedId.contains("moderation") { return .red }
//        if normalizedId.contains("search") { return .cyan }
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
//        // Remove common prefixes/suffixes for cleaner display if needed
//        // Example: "gpt-4-turbo" -> "GPT-4 Turbo"
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
//    // Enhanced mock models based on screenshots, esp. GPT-4o Audio
//    private func generateMockModels() -> [OpenAIModel] {
//        return [
//            // Featured
//            OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", shortDescription: "Flagship GPT model for complex tasks", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k"),
//            OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", shortDescription: "Faster, more affordable reasoning model", capabilities: ["text generation", "reasoning"], contextWindow: "128k"),
//            OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", shortDescription: "Our most powerful reasoning model", capabilities: ["text generation", "reasoning", "code"], contextWindow: "16k"),
//
//            // Reasoning Models
//            OpenAIModel(id: "o3-mini", object: "model", created: 1699000000, ownedBy: "openai", description: "A smaller, faster, and more affordable alternative to o3.", shortDescription: "A small model alternative to o3", capabilities: ["text generation", "reasoning"], contextWindow: "16k"),
//            OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", shortDescription: "Previous full o-series reasoning model", capabilities: ["text generation", "reasoning"], contextWindow: "8k"),
//            OpenAIModel(id: "o1-pro", object: "model", created: 1685000000, ownedBy: "openai", description: "Version of o1 with more compute for better responses.", shortDescription: "Version of o1 with more compute", capabilities: ["text generation", "reasoning"], contextWindow: "8k"),
//            OpenAIModel(id: "o1-mini", object: "model", created: 1675000000, ownedBy: "openai", description: "A small model alternative to o1, very fast.", shortDescription: "A small model alternative to o1", capabilities: ["text generation", "reasoning"], contextWindow: "8k"),
//
//            // Flagship Chat Models
//            OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model.", shortDescription: "Fast, intelligent, flexible GPT model", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k"),
//
//            // *** GPT-4o Audio - Enriched with Screenshot Data ***
//            OpenAIModel(
//                id: "gpt-4o-audio", object: "model", created: 1712850000, ownedBy: "openai", // Assuming timestamp
//                description: "This is a preview release of the GPT-4o Audio models. These models accept audio inputs and outputs, and can be used in the Chat Completions REST API.",
//                shortDescription: "GPT-4o models capable of audio inputs and outputs.",
//                capabilities: ["audio processing", "text generation"], // Core API capabilities
//                typicalUseCases: ["Audio interaction", "Voice chat"], // Example use cases
//                contextWindow: "128,000 tokens",
//                maxOutputTokens: "16,384 tokens",
//                knowledgeCutoff: "Sep 30, 2023",
//                pricingTextTokens: "$2.50 / 1M (Input), $10.00 / 1M (Output)",
//                pricingAudioTokens: "$40.00 / 1M (Input), $80.00 / 1M (Output)",
//                inputModalities: ["Text", "Audio"],
//                outputModalities: ["Text", "Audio"],
//                supportedEndpoints: ["Chat Completions (/v1/chat/completions)"],
//                supportedFeatures: ["Streaming", "Function calling"],
//                snapshots: ["gpt-4o-audio-preview", "gpt-4o-audio-preview-2024-12-17", "gpt-4o-audio-preview-2024-10-01"],
//                intelligenceRating: "High",
//                speedRating: "Medium"
//            ),
//
//            OpenAIModel(id: "chatgpt-4o-latest", object: "model", created: 1712900000, ownedBy: "openai", description: "GPT-4o model used in ChatGPT.", shortDescription: "GPT-4o model used in ChatGPT", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k"),
//
//            // Cost-optimized Models
//            OpenAIModel(id: "gpt-4.1-mini", object: "model", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", shortDescription: "Balanced for intelligence, speed, cost", capabilities: ["text generation", "reasoning"], contextWindow: "128k"),
//            OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", shortDescription: "Fastest, most cost-effective GPT-4.1", capabilities: ["text generation"], contextWindow: "128k"),
//            OpenAIModel(id: "gpt-4o-mini", object: "model", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", shortDescription: "Fast, affordable small model", capabilities: ["text generation"], contextWindow: "128k"),
//            OpenAIModel(id: "gpt-4o-mini-audio", object: "model", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", shortDescription: "Smaller model capable of audio inputs", capabilities: ["audio processing", "text generation"], contextWindow: "128k"),
//
//            // Realtime Models
//            OpenAIModel(id: "gpt-4o-realtime", object: "model", created: 1712860000, ownedBy: "openai", description: "Model capable of realtime text and audio inputs and outputs.", shortDescription: "Model capable of realtime text/audio", capabilities: ["realtime", "audio", "text"], contextWindow: "128k"),
//            OpenAIModel(id: "gpt-4o-mini-realtime", object: "model", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", shortDescription: "Smaller realtime model for text/audio", capabilities: ["realtime", "audio", "text"], contextWindow: "128k"),
//
//            // Older GPT Models
//            OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", shortDescription: "An older high-intelligence GPT model", capabilities: ["text generation", "reasoning", "code"], contextWindow: "128k"),
//            OpenAIModel(id: "gpt-4", object: "model", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", shortDescription: "An older high-intelligence GPT model", capabilities: ["text generation", "reasoning", "code"], contextWindow: "8k / 32k"),
//            OpenAIModel(id: "gpt-3.5-turbo", object: "model", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", shortDescription: "Legacy GPT model for cheaper tasks", capabilities: ["text generation"], contextWindow: "4k / 16k"),
//
//            // DALL-E Models
//            OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", shortDescription: "Our latest image generation model", capabilities: ["image generation"], contextWindow: "N/A", inputModalities: ["Text"], outputModalities: ["Image"]),
//            OpenAIModel(id: "dall-e-2", object: "model", created: 1650000000, ownedBy: "openai", description: "Our first image generation model.", shortDescription: "Our first image generation model", capabilities: ["image generation"], contextWindow: "N/A", inputModalities: ["Text"], outputModalities: ["Image"]),
//
//            // Other models (can be expanded similarly if needed)
//            // ... TTS, Transcription, Embeddings, Moderation, Tools ...
//            // Example:
//            OpenAIModel(id: "tts-1", object: "model", created: 1690000000, ownedBy: "openai", description: "Text-to-speech model optimized for speed.", shortDescription: "Text-to-speech model optimized for speed", capabilities: ["tts"], contextWindow: "4096 bytes", inputModalities: ["Text"], outputModalities: ["Audio"]),
//            OpenAIModel(id: "whisper-1", object: "model", created: 1677600000, ownedBy: "openai", description: "General-purpose speech recognition model.", shortDescription: "General-purpose speech recognition", capabilities: ["audio transcription", "translation"], contextWindow: "N/A", inputModalities: ["Audio"], outputModalities: ["Text"]),
//            OpenAIModel(id: "text-embedding-3-large", object: "model", created: 1711300000, ownedBy: "openai", description: "Most capable embedding model.", shortDescription: "Most capable embedding model", capabilities: ["text embedding"], contextWindow: "8191 tokens", inputModalities: ["Text"], outputModalities: ["Embeddings"]),
//            OpenAIModel(id: "omni-moderation", object: "model", created: 1712880000, ownedBy: "openai", description: "Identify potentially harmful content in text and images.", shortDescription: "Identify potentially harmful content", capabilities: ["content filtering", "image moderation"], contextWindow: "N/A", inputModalities: ["Text", "Image"], outputModalities: ["Classification"]),
//
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
//                 // Handle the response structure which has a 'data' key
//                 let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
//                 print("✅ Successfully decoded \(responseWrapper.data.count) models.")
//                 // Map the response to include default shortDescription if needed
//                 // (And potentially derive other defaults if necessary for consistency)
//                 return responseWrapper.data.map { model in
//                     var mutableModel = model
//                     // If API doesn't provide shortDescription, generate a default one based on owner
//                     if mutableModel.shortDescription == "General purpose model." { // Check default value
//                         mutableModel.shortDescription = model.ownedBy.contains("openai") ? "OpenAI model." : "User or system model."
//                     }
//                     // If the live API ever *does* return some of the other fields, Codable will pick them up.
//                     // Otherwise, the defaults defined in the struct will be used.
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
//        VStack { GeometryReader { geometry in self.generateContent(in: geometry) } }
//        .frame(height: totalHeight)
//    }
//    private func generateContent(in g: GeometryProxy) -> some View {
//        var width = CGFloat.zero; var height = CGFloat.zero
//        return ZStack(alignment: .topLeading) {
//            ForEach(self.items, id: \.self) { item in
//                self.viewForItem(item)
//                    .padding(.horizontal, horizontalSpacing / 2)
//                    .padding(.vertical, verticalSpacing / 2)
//                    .alignmentGuide(.leading, computeValue: { d in
//                        if (abs(width - d.width) > g.size.width) { width = 0; height -= d.height + verticalSpacing }
//                        let result = width
//                        if item == self.items.last { width = 0 } else { width -= d.width }
//                        return result
//                    })
//                    .alignmentGuide(.top, computeValue: { d in let result = height; if item == self.items.last { height = 0 }; return result })
//            }
//        }.background(viewHeightReader($totalHeight))
//    }
//    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
//        GeometryReader { geo -> Color in DispatchQueue.main.async { binding.wrappedValue = geo.frame(in: .local).size.height }; return .clear }
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
//                Text("Enter your OpenAI API Key").font(.headline)
//                Text("Your key will be stored securely in UserDefaults on this device. Ensure you are using a key with appropriate permissions.").font(.caption).foregroundColor(.secondary)
//                SecureField("sk-...", text: $inputApiKey).textFieldStyle(RoundedBorderTextFieldStyle())
//                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(isInvalidKeyAttempt ? Color.red : Color.clear, lineWidth: 1))
//                    .onChange(of: inputApiKey) { _, _ in isInvalidKeyAttempt = false }
//                if isInvalidKeyAttempt { Text("API Key cannot be empty.").font(.caption).foregroundColor(.red) }
//                HStack {
//                    Button("Cancel") { onCancel(); dismiss() }.buttonStyle(.bordered)
//                    Spacer()
//                    Button("Save Key") {
//                         let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
//                         if trimmedKey.isEmpty { isInvalidKeyAttempt = true }
//                         else { apiKey = trimmedKey; onSave(apiKey); dismiss() }
//                    }.buttonStyle(.borderedProminent)
//                }.padding(.top)
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("API Key")
//            .navigationBarTitleDisplayMode(.inline)
//             .onAppear { inputApiKey = apiKey; isInvalidKeyAttempt = false }
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
//            RoundedRectangle(cornerRadius: 12) // Placeholder background
//                .fill(model.iconBackgroundColor.opacity(0.3))
//                .frame(height: 120)
//                 .overlay( Image(systemName: model.iconName).resizable().scaledToFit().padding(25).foregroundStyle(model.iconBackgroundColor) )
//            VStack(alignment: .leading, spacing: 4) {
//                Text(model.displayName).font(.headline)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2) // Use short desc
//            }.padding([.horizontal, .bottom], 12)
//        }
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
//         .frame(minWidth: 0, maxWidth: .infinity)
//    }
//}
//
//// --- Standard Model Row View (for Grids) ---
//struct StandardModelRow: View {
//    let model: OpenAIModel
//
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: model.iconName).resizable().scaledToFit().padding(7).frame(width: 36, height: 36)
//                .background(model.iconBackgroundColor.opacity(0.85)).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 8))
//            VStack(alignment: .leading, spacing: 3) {
//                Text(model.displayName).font(.subheadline.weight(.medium)).lineLimit(1)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2) // Use short desc
//            }
//            Spacer(minLength: 0)
//        }
//        .padding(10).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
//        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
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
//            Text(title).font(.title2.weight(.semibold))
//            if let subtitle = subtitle, !subtitle.isEmpty { Text(subtitle).font(.callout).foregroundColor(.secondary) }
//        }
//        .padding(.bottom, 10).padding(.horizontal)
//    }
//}
//
//// --- Model Detail View (Enhanced with new fields) ---
//struct ModelDetailView: View {
//    let model: OpenAIModel
//    var body: some View {
//        List {
//            // --- Top Branding Section ---
//            Section {
//                VStack(spacing: 15) {
//                    Image(systemName: model.iconName).resizable().scaledToFit()
//                        .padding(15).frame(width: 80, height: 80)
//                        .background(model.iconBackgroundColor).foregroundStyle(.white)
//                        .clipShape(Circle())
//                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
//                    Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
//                    if !model.shortDescription.isEmpty && model.shortDescription != "General purpose model." {
//                         Text(model.shortDescription).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center)
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
//            }
//            .listRowBackground(Color.clear).listRowSeparator(.hidden)
//
//            // --- General Information ---
//            Section("Overview") {
//                DetailRow(label: "Full ID", value: model.id)
//                DetailRow(label: "Type", value: model.object)
//                DetailRow(label: "Owner", value: model.ownedBy)
//                DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
//            }
//
//            // --- Detailed Description ---
//            if !model.description.isEmpty && model.description != "No description available." {
//                 Section("Description") { Text(model.description) }
//            }
//
//             // --- Technical Specifications ---
//            Section("Technical Specs") {
//                DetailRow(label: "Context Window", value: model.contextWindow)
//                if let maxOut = model.maxOutputTokens { DetailRow(label: "Max Output", value: maxOut) }
//                if let cutoff = model.knowledgeCutoff { DetailRow(label: "Knowledge Cutoff", value: cutoff) }
//            }
//
//            // --- Intelligence & Speed Ratings (If provided) ---
//            if model.intelligenceRating != nil || model.speedRating != nil {
//                Section("Ratings") {
//                    if let intel = model.intelligenceRating { DetailRow(label: "Intelligence", value: intel) }
//                    if let speed = model.speedRating { DetailRow(label: "Speed", value: speed) }
//                }
//            }
//
//            // --- Pricing Info (If provided) ---
//            if model.pricingTextTokens != nil || model.pricingAudioTokens != nil {
//                Section("Pricing (per 1M Tokens)") {
//                    if let textPrice = model.pricingTextTokens { DetailRow(label: "Text Tokens", value: textPrice) }
//                    if let audioPrice = model.pricingAudioTokens { DetailRow(label: "Audio Tokens", value: audioPrice) }
//                     Link("See Pricing Page", destination: URL(string: "https://openai.com/pricing")!)
//                        .font(.caption)
//                        .foregroundColor(.blue)
//                        .padding(.top, 2)
//                }
//            }
//
//            // --- Modalities (If provided and differs from default) ---
//            if (model.inputModalities != nil && model.inputModalities != ["Text"]) || (model.outputModalities != nil && model.outputModalities != ["Text"]) {
//                Section("Modalities") {
//                    if let inputs = model.inputModalities { DisplayTags(label: "Input", tags: inputs) }
//                    if let outputs = model.outputModalities { DisplayTags(label: "Output", tags: outputs) }
//                }
//            }
//
//             // --- Capabilities (Core Task types) ---
//            if !model.capabilities.isEmpty && model.capabilities != ["general"] {
//                Section("Capabilities") { DisplayTags(label: nil, tags: model.capabilities) }
//            }
//
//            // --- Features ---
//            if let features = model.supportedFeatures, !features.isEmpty {
//                Section("Features") { DisplayList(items: features, symbol: "checkmark.circle.fill", color: .green) }
//            }
//
//            // --- Endpoints ---
//            if let endpoints = model.supportedEndpoints, !endpoints.isEmpty {
//                Section("Endpoints") { DisplayList(items: endpoints, symbol: "link", color: .blue) }
//            }
//
//            // --- Snapshots ---
//            if let snapshots = model.snapshots, !snapshots.isEmpty {
//                Section("Snapshots / Aliases") { DisplayList(items: snapshots, symbol: "tag.fill", color: .orange) }
//            }
//        }
//        .listStyle(.insetGrouped)
//        .navigationTitle(model.displayName) // Use DisplayName for cleaner title
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//    // --- Helper Row View ---
//    private func DetailRow(label: String, value: String) -> some View {
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//            Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
//        }
//         .padding(.vertical, 2).accessibilityElement(children: .combine)
//    }
//
//    // --- Helper for displaying Tags/Capabilities/Modalities ---
//    @ViewBuilder
//    private func DisplayTags(label: String?, tags: [String]) -> some View {
//        VStack(alignment: .leading) {
//            if let label = label { Text(label).font(.caption).foregroundColor(.secondary) }
//            WrappingHStack(items: tags) { tag in
//                Text(tag.capitalized)
//                    .font(.caption)
//                    .padding(.horizontal, 8).padding(.vertical, 4)
//                    .background(Color.accentColor.opacity(0.15))
//                    .foregroundColor(.accentColor)
//                    .clipShape(Capsule())
//            }
//        }
//         .padding(.vertical, 2)
//         .accessibilityElement(children: .combine)
//    }
//
//    // --- Helper for displaying Lists (Endpoints, Features, Snapshots) ---
//     @ViewBuilder
//     private func DisplayList(items: [String], symbol: String, color: Color) -> some View {
//         ForEach(items, id: \.self) { item in
//             Label(item, systemImage: symbol)
//                 .foregroundColor(color)
//                 .imageScale(.small)
//                 .font(.callout)
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
//    let gridColumns: [GridItem] = [ GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15) ]
//
//    // --- Filters for Sections (Based on Model IDs - review categories if needed) ---
//    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "o4-mini", "o3"].contains($0.id) }.sortedById() }
//    var reasoningModels: [OpenAIModel] { allModels.filter { $0.id.contains("o1") || $0.id.contains("o3") || $0.id.contains("o4") }.sortedById() } // Broader filter
//    var flagshipChatModels: [OpenAIModel] { allModels.filter { $0.id.contains("gpt-4.1") || $0.id.contains("gpt-4o") }.sortedById() } // Includes audio variants
//    var costOptimizedModels: [OpenAIModel] { allModels.filter { $0.id.contains("mini") || $0.id.contains("nano") }.sortedById() }
//    var realtimeModels: [OpenAIModel] { allModels.filter { $0.id.contains("realtime") }.sortedById() }
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
//                // --- Conditional Content Display ---
//                if isLoading && allModels.isEmpty {
//                     ProgressView("Fetching Models...").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemBackground)).zIndex(1)
//                 } else if let errorMessage = errorMessage, allModels.isEmpty {
//                     ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
//                 } else {
//                    // --- Main Scrollable Content ---
//                    ScrollView(.vertical, showsIndicators: false) {
//                        VStack(alignment: .leading, spacing: 30) { // Main container for sections
//                             // --- Header Text ---
//                             VStack(alignment: .leading, spacing: 5) {
//                                 Text("Models").font(.largeTitle.weight(.bold))
//                                 Text("Explore all available models and compare their capabilities.").font(.title3).foregroundColor(.secondary)
//                             }.padding(.horizontal)
//                             Divider().padding(.horizontal)
//                             // --- Featured Models Section ---
//                             SectionHeader(title: "Featured models", subtitle: nil)
//                             ScrollView(.horizontal, showsIndicators: false) {
//                                 HStack(spacing: 15) {
//                                     ForEach(featuredModels) { model in
//                                         NavigationLink(value: model) { FeaturedModelCard(model: model).frame(width: 250) }
//                                         .buttonStyle(.plain)
//                                     }
//                                 }.padding(.horizontal).padding(.bottom, 5)
//                             }
//                             // --- Standard Sections with Grid ---
//                             displaySection(title: "Reasoning models", subtitle: "o-series models that excel at complex, multi-step tasks.", models: reasoningModels)
//                             displaySection(title: "Flagship chat models", subtitle: "Our versatile, high-intelligence flagship models.", models: flagshipChatModels)
//                             displaySection(title: "Cost-optimized models", subtitle: "Smaller, faster models that cost less to run.", models: costOptimizedModels)
//                             displaySection(title: "Realtime models", subtitle: "Models capable of realtime text and audio inputs and outputs.", models: realtimeModels)
//                             displaySection(title: "Older GPT models", subtitle: "Supported older versions of our general purpose and chat models.", models: olderGptModels)
//                             displaySection(title: "DALL·E", subtitle: "Models that can generate and edit images, given a natural language prompt.", models: dalleModels)
//                             displaySection(title: "Text-to-speech", subtitle: "Models that can convert text into natural sounding spoken audio.", models: ttsModels)
//                             displaySection(title: "Transcription", subtitle: "Model that can transcribe and translate audio into text.", models: transcriptionModels)
//                             displaySection(title: "Embeddings", subtitle: "A set of models that can convert text into vector representations.", models: embeddingsModels)
//                             displaySection(title: "Moderation", subtitle: "Fine-tuned models that detect whether input may be sensitive or unsafe.", models: moderationModels)
//                             displaySection(title: "Tool-specific models", subtitle: "Models to support specific built-in tools.", models: toolSpecificModels)
//                             Spacer(minLength: 50) // Add space at the bottom
//                        } // End Main VStack
//                        .padding(.top)
//                    } // End ScrollView
//                    .background(Color(.systemBackground))
//                    .edgesIgnoringSafeArea(.bottom)
//                 }
//            } // End ZStack
//            .navigationTitle("OpenAI Models")
//            .navigationBarTitleDisplayMode(.inline) // Use inline to match web simpler header
//            .toolbar {
//                 // --- Refresh/Loading Indicator ---
//                 ToolbarItem(placement: .navigationBarLeading) {
//                     if isLoading { ProgressView().controlSize(.small) }
//                     else { Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(isLoading) }
//                 }
//                 // --- Toggle API Source Button ---
//                 ToolbarItem(placement: .navigationBarTrailing) {
//                     Menu { Toggle(isOn: $useMockData) { Text(useMockData ? "Using Mock Data" : "Using Live API") } }
//                     label: { Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill").foregroundColor(useMockData ? .secondary : .blue) }
//                     .disabled(isLoading)
//                 }
//             }
//             // --- Navigation Destination ---
//             .navigationDestination(for: OpenAIModel.self) { model in
//                 ModelDetailView(model: model)
//                       .toolbarBackground(.visible, for: .navigationBar)
//                       .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar) // Adapt color if needed
//             }
//             // --- Initial Load & API Key Sheet Logic ---
//             .task { if allModels.isEmpty { attemptLoadModels() } }
//             .refreshable { await loadModelsAsync(checkApiKey: false) }
//             .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
//             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
//             // --- Alert for errors *after* initial load ---
//             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: { Button("OK") { errorMessage = nil } }, message: { Text(errorMessage ?? "An unknown error occurred.") })
//        } // End NavigationStack
//    }
//
//    // --- Helper View Builder for Sections ---
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
//         }
//    }
//
//    // --- Helper Functions for Loading & API Key Handling ---
//    private func handleToggleChange(to newValue: Bool) {
//         print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
//         allModels = []; errorMessage = nil
//         if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true }
//         else { loadModelsAsyncWithLoadingState() }
//    }
//    private func presentApiKeySheet() -> some View {
//         APIKeyInputView(onSave: { _ in print("API Key saved."); loadModelsAsyncWithLoadingState() },
//                         onCancel: { print("API Key input cancelled."); useMockData = true })
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
//             print("❌ Error loading models: \(error.localizedDescription)")
//             self.errorMessage = error.localizedDescription; if allModels.isEmpty { self.allModels = [] }
//         } catch {
//             print("❌ Unexpected error loading models: \(error)")
//             self.errorMessage = "Unexpected error: \(error.localizedDescription)"; if allModels.isEmpty { self.allModels = [] }
//         }
//         isLoading = false
//    }
//}
//
//// MARK: - Helper Extensions
//
//extension Array where Element == OpenAIModel {
//    // Helper to sort models alphabetically by ID for consistent section display
//    func sortedById() -> [OpenAIModel] { self.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending } }
//}
//
//// MARK: - Previews
//
//#Preview("Main View (Mock Data)") { OpenAIModelsMasterView() }
//#Preview("Main View (Empty/Loading)") { ProgressView("Fetching Models...").frame(width: 200, height: 200) }
//#Preview("Main View (Error State)") { ErrorView(errorMessage: "Failed to connect. Please retry.") {}.frame(width: 300, height: 300) }
//#Preview("Featured Card Example") {
//    let model = OpenAIModel(id: "gpt-4.1", object: "model", created: 1, ownedBy: "openai", shortDescription: "Flagship model")
//    return FeaturedModelCard(model: model).padding().frame(width: 280)
//}
//#Preview("Standard Row Example") {
//     let model = OpenAIModel(id: "o4-mini", object: "model", created: 1, ownedBy: "openai", shortDescription: "Faster, affordable reasoning")
//     return StandardModelRow(model: model).padding().frame(width: 350)
//}
////#Preview("Detail View (GPT-4o Audio)") {
////    // Fetch the enriched model from the mock service for preview
////    let mockModels = MockAPIService().generateMockModels()
////    let gpt4oAudioModel = mockModels.first { $0.id == "gpt-4o-audio" }! // Force unwrap for preview simplicity
////    NavigationStack { ModelDetailView(model: gpt4oAudioModel) }
////}
////#Preview("Detail View (Standard Model)") {
////    let mockModels = MockAPIService().generateMockModels()
////    let standardModel = mockModels.first { $0.id == "gpt-4-turbo" }!
////    NavigationStack { ModelDetailView(model: standardModel) }
////}
//#Preview("API Key Input Sheet") {
//    struct SheetPresenter: View { @State var showSheet = true
//        var body: some View { Text("Tap to show sheet (already shown)").sheet(isPresented: $showSheet) { APIKeyInputView(onSave: {_ in}, onCancel: {}) } }
//    }
//    return SheetPresenter()
//}
