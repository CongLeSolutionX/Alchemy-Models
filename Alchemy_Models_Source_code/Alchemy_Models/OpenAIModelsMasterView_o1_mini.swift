////
////  OpenAIModelsMasterView_o1_mini.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIModelsMasterView.swift
////  Alchemy_Models_Combined
////  (Single File Implementation - Updated with o1-mini details)
////
////  Created: Cong Le
////  Date: 4/13/25 (Based on previous iterations)
////  Version: 1.2 (Incorporated o1-mini details)
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
//    var capabilities: [String] = ["general"]
//    var contextWindow: String = "N/A"
//    var typicalUseCases: [String] = ["Various tasks"]
//    var shortDescription: String = "General purpose model."
//    // New fields based on o1-mini screenshot (with defaults suitable if API doesn't provide them)
//    var knowledgeCutoff: String = "N/A"
//    var maxOutputTokens: Int? = nil // Optional as it might not be available for all
//
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id
//        case object
//        case created
//        case ownedBy = "owned_by"
//        // Description, capabilities, shortDesc, etc. are NOT listed here, allowing defaults.
//        // If we wanted the API to potentially provide knowledgeCutoff or maxOutputTokens,
//        // we would add them here (likely with snake_case names if API uses that).
//        // For now, we only populate them in the Mock data.
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
//        // Map specific IDs to SF Symbols
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") || normalizedId.contains("chatgpt-4o") { return "sparkles" }
//        if normalizedId.contains("o4-mini") { return "leaf.fill" }
//        if normalizedId.contains("o3-mini") { return "leaf" } // Slightly different for o3 mini
//        if normalizedId.contains("o3") { return "circle.hexagonpath.fill" }
//        if normalizedId.contains("o1-mini") || normalizedId.contains("o1-pro") || normalizedId.contains("o1") { return "circles.hexagonpath.fill" } // Group o1 series
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
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") { return .blue }
//        if normalizedId.contains("o4-mini") { return .purple }
//        if normalizedId.contains("o3-mini") { return .teal.opacity(0.8) } // Slightly different shade
//        if normalizedId.contains("o3") { return .orange }
//        if normalizedId.contains("o1") { return .yellow // Use yellow/orange theme for o1 series
//            .opacity(normalizedId.contains("mini") ? 0.8 : (normalizedId.contains("pro") ? 1.0 : 0.9)) }
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
//        // Special handling for cleaner names
//        if id == "o1-mini" { return "o1-mini" } // Keep as is
//        if id == "o3-mini" { return "o3-mini" } // Keep as is
//        if id == "o4-mini" { return "o4-mini" } // Keep as is
//
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
//    // Enhanced mock models based on screenshots & o1-mini details
//    private func generateMockModels() -> [OpenAIModel] {
//        return [
//            // Featured
//            OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k", shortDescription: "Flagship GPT model for complex tasks", knowledgeCutoff: "Apr 2024", maxOutputTokens: 8192), // Example details
//            OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", capabilities: ["text generation", "reasoning", "chat"], contextWindow: "128k", shortDescription: "Faster, more affordable reasoning model", knowledgeCutoff: "Apr 2024", maxOutputTokens: 16384),
//            OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", capabilities: ["text generation", "reasoning", "code", "chat"], contextWindow: "16k", shortDescription: "Our most powerful reasoning model", knowledgeCutoff: "Dec 2023", maxOutputTokens: 4096),
//
//            // Reasoning Models
//            OpenAIModel(id: "o3-mini", object: "model", created: 1699000000, ownedBy: "openai", description: "A smaller, faster, and more affordable alternative to o3.", capabilities: ["text generation", "reasoning", "chat"], contextWindow: "16k", shortDescription: "A small model alternative to o3", knowledgeCutoff: "Dec 2023", maxOutputTokens: 4096),
//            OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", capabilities: ["text generation", "reasoning", "chat"], contextWindow: "8k", shortDescription: "Previous full o-series reasoning model", knowledgeCutoff: "Sep 2021", maxOutputTokens: 2048),
//            OpenAIModel(id: "o1-pro", object: "model", created: 1685000000, ownedBy: "openai", description: "Version of o1 with more compute for better responses.", capabilities: ["text generation", "reasoning", "chat"], contextWindow: "8k", shortDescription: "Version of o1 with more compute", knowledgeCutoff: "Sep 2021", maxOutputTokens: 2048),
//
//            // *** o1-mini DETAILS ADDED HERE ***
//            OpenAIModel(
//                id: "o1-mini",
//                object: "model",
//                created: 1675000000, // Approx timestamp based on other models
//                ownedBy: "openai",
//                description: """
//                The o1 reasoning model is designed to solve hard problems across domains. o1-mini is a faster and more affordable reasoning model, but we recommend using the newer o3-mini model that features higher intelligence at the same latency and price as o1-mini.
//
//                Pricing per 1M tokens:
//                Input: $1.10
//                Output: $4.40
//                Cached Input: $0.55
//                (Reasoning token support included)
//                """,
//                // Capabilities based on Endpoints/Features screenshot: Chat, Responses, Streaming
//                capabilities: ["text generation", "reasoning", "chat", "responses", "streaming"],
//                contextWindow: "128k", // From screenshot
//                typicalUseCases: ["Reasoning", "Chat"],
//                shortDescription: "A small model alternative to o1.",
//                knowledgeCutoff: "Sep 30, 2023", // From screenshot
//                maxOutputTokens: 65536 // From screenshot
//            ),
//
//            // Flagship Chat Models
//            OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model.", capabilities: ["text generation", "reasoning", "code", "vision", "audio", "chat"], contextWindow: "128k", shortDescription: "Fast, intelligent, flexible GPT model", knowledgeCutoff: "Oct 2023", maxOutputTokens: 8192),
//            OpenAIModel(id: "gpt-4o-audio", object: "model", created: 1712850000, ownedBy: "openai", description: "GPT-4o models capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation", "chat"], contextWindow: "128k", shortDescription: "GPT-4o models capable of audio inputs", knowledgeCutoff: "Oct 2023", maxOutputTokens: 8192),
//            OpenAIModel(id: "chatgpt-4o-latest", object: "model", created: 1712900000, ownedBy: "openai", description: "GPT-4o model used in ChatGPT.", capabilities: ["text generation", "reasoning", "code", "vision", "audio", "chat"], contextWindow: "128k", shortDescription: "GPT-4o model used in ChatGPT", knowledgeCutoff: "Oct 2023", maxOutputTokens: 8192),
//
//            // Cost-optimized Models
//            OpenAIModel(id: "gpt-4.1-mini", object: "model", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", capabilities: ["text generation", "reasoning", "chat"], contextWindow: "128k", shortDescription: "Balanced for intelligence, speed, cost", knowledgeCutoff: "Apr 2024", maxOutputTokens: 16384),
//            OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", capabilities: ["text generation", "chat"], contextWindow: "128k", shortDescription: "Fastest, most cost-effective GPT-4.1", knowledgeCutoff: "Apr 2024", maxOutputTokens: 16384),
//            OpenAIModel(id: "gpt-4o-mini", object: "model", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", capabilities: ["text generation", "chat"], contextWindow: "128k", shortDescription: "Fast, affordable small model", knowledgeCutoff: "Oct 2023", maxOutputTokens: 16384),
//            OpenAIModel(id: "gpt-4o-mini-audio", object: "model", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation", "chat"], contextWindow: "128k", shortDescription: "Smaller model capable of audio inputs", knowledgeCutoff: "Oct 2023", maxOutputTokens: 16384),
//
//            // Realtime Models
//            OpenAIModel(id: "gpt-4o-realtime", object: "model", created: 1712860000, ownedBy: "openai", description: "Model capable of realtime text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text", "chat"], contextWindow: "128k", shortDescription: "Model capable of realtime text/audio", knowledgeCutoff: "Oct 2023", maxOutputTokens: 8192),
//            OpenAIModel(id: "gpt-4o-mini-realtime", object: "model", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text", "chat"], contextWindow: "128k", shortDescription: "Smaller realtime model for text/audio", knowledgeCutoff: "Oct 2023", maxOutputTokens: 16384),
//
//            // Older GPT Models
//            OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code", "chat"], contextWindow: "128k", shortDescription: "An older high-intelligence GPT model", knowledgeCutoff: "Dec 2023", maxOutputTokens: 4096),
//            OpenAIModel(id: "gpt-4", object: "model", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code", "chat"], contextWindow: "8k / 32k", shortDescription: "An older high-intelligence GPT model", knowledgeCutoff: "Sep 2021", maxOutputTokens: 4096), // Context window is variable
//            OpenAIModel(id: "gpt-3.5-turbo", object: "model", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", capabilities: ["text generation", "chat"], contextWindow: "4k / 16k", shortDescription: "Legacy GPT model for cheaper tasks", knowledgeCutoff: "Sep 2021", maxOutputTokens: 4096),
//
//            // DALL-E Models
//            OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our latest image generation model"),
//            OpenAIModel(id: "dall-e-2", object: "model", created: 1650000000, ownedBy: "openai", description: "Our first image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our first image generation model"),
//
//            // Remaining models (assuming IDs and basic details)
//            OpenAIModel(id: "tts-1", object: "model", created: 1690000000, ownedBy: "openai", description: "Text-to-speech model.", capabilities: ["tts"], shortDescription: "Text-to-speech model"),
//            OpenAIModel(id: "tts-1-hd", object: "model", created: 1695000000, ownedBy: "openai", description: "High-definition text-to-speech.", capabilities: ["tts-hd"], shortDescription: "High-definition TTS"),
//            OpenAIModel(id: "whisper-1", object: "model", created: 1677600000, ownedBy: "openai", description: "Speech-to-text model.", capabilities: ["transcription", "translation"], shortDescription: "General speech-to-text"),
//            OpenAIModel(id: "text-embedding-3-small", object: "model", created: 1711200000, ownedBy: "openai", description: "Small text embedding model.", capabilities: ["text embedding"], shortDescription: "Small embedding model"),
//            OpenAIModel(id: "text-embedding-3-large", object: "model", created: 1711300000, ownedBy: "openai", description: "Large text embedding model.", capabilities: ["text embedding"], shortDescription: "Large embedding model"),
//            OpenAIModel(id: "text-embedding-ada-002", object: "model", created: 1670000000, ownedBy: "openai", description: "Older embedding model.", capabilities: ["text embedding"], shortDescription: "Older embedding model"),
//            OpenAIModel(id: "text-moderation-latest", object: "model", created: 1688000000, ownedBy: "openai", description: "Text moderation model.", capabilities: ["content filtering"], shortDescription: "Text moderation"),
//            OpenAIModel(id: "omni-moderation", object: "model", created: 1712880000, ownedBy: "openai", description: "Omni-modal moderation.", capabilities: ["content filtering", "image moderation"], shortDescription: "Omni-modal moderation"),
//            OpenAIModel(id: "gpt-4o-search-preview", object: "model", created: 1712890000, ownedBy: "openai", description: "Model with search capabilities.", capabilities: ["search", "text generation", "chat"], shortDescription: "GPT model for web search"),
//            OpenAIModel(id: "gpt-4o-mini-search-preview", object: "model", created: 1712390000, ownedBy: "openai", description: "Smaller model with search.", capabilities: ["search", "text generation", "chat"], shortDescription: "Fast, affordable small model for search"),
//            OpenAIModel(id: "computer-use-preview", object: "model", created: 1712910000, ownedBy: "openai", description: "Model for computer control tools.", capabilities: ["tool-use", "computer control"], shortDescription: "Specialized model for computer use")
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
//                 let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
//                 print("✅ Successfully decoded \(responseWrapper.data.count) models.")
//                 // Use default values defined in OpenAIModel for missing API fields
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
//    var body: some View { // (Implementation Unchanged)
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
//                    .onChange(of: inputApiKey) { _, _ in isInvalidKeyAttempt = false } // Reset validation state
//
//                if isInvalidKeyAttempt { Text("API Key cannot be empty.").font(.caption).foregroundColor(.red) }
//
//                HStack {
//                    Button("Cancel") { onCancel(); dismiss() }.buttonStyle(.bordered)
//                    Spacer()
//                    Button("Save Key") {
//                        let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
//                        if trimmedKey.isEmpty { isInvalidKeyAttempt = true }
//                        else { apiKey = trimmedKey; onSave(apiKey); dismiss() }
//                    }.buttonStyle(.borderedProminent)
//                }.padding(.top)
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("API Key")
//            .navigationBarTitleDisplayMode(.inline)
//            .onAppear { inputApiKey = apiKey; isInvalidKeyAttempt = false } // Load key & reset validation
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
//    var body: some View { // (Implementation Unchanged)
//        VStack(alignment: .leading, spacing: 10) {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(model.iconBackgroundColor.opacity(0.3))
//                .frame(height: 120)
//                 .overlay( Image(systemName: model.iconName).resizable().scaledToFit().padding(25).foregroundStyle(model.iconBackgroundColor) )
//            VStack(alignment: .leading, spacing: 4) {
//                Text(model.displayName).font(.headline)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
//            }.padding([.horizontal, .bottom], 12)
//        }
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
//        .frame(minWidth: 0, maxWidth: .infinity)
//    }
//}
//
//// --- Standard Model Row View (for Grids) ---
//struct StandardModelRow: View {
//    let model: OpenAIModel
//
//    var body: some View { // (Implementation Unchanged)
//        HStack(spacing: 12) {
//            Image(systemName: model.iconName).resizable().scaledToFit().padding(7)
//                .frame(width: 36, height: 36)
//                .background(model.iconBackgroundColor.opacity(0.85))
//                .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 8))
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
//// --- Reusable Section Header ---
//struct SectionHeader: View {
//    let title: String
//    let subtitle: String?
//
//    var body: some View { // (Implementation Unchanged)
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title).font(.title2.weight(.semibold))
//            if let subtitle = subtitle { Text(subtitle).font(.callout).foregroundColor(.secondary) }
//        }
//        .padding(.bottom, 10).padding(.horizontal)
//    }
//}
//
//// --- Model Detail View (Updated to include new fields) ---
//struct ModelDetailView: View {
//    let model: OpenAIModel
//
//    var body: some View {
//        List {
//            // Icon & Title Section (Unchanged)
//            Section {
//                VStack(spacing: 15) {
//                    Image(systemName: model.iconName).resizable().scaledToFit().padding(15).frame(width: 80, height: 80)
//                        .background(model.iconBackgroundColor).foregroundStyle(.white).clipShape(Circle())
//                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
//                    Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
//                }
//                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
//            }
//            .listRowBackground(Color.clear)
//
//            // Overview Section (Unchanged)
//            Section("Overview") {
//                DetailRow(label: "Full ID", value: model.id)
//                DetailRow(label: "Type", value: model.object)
//                DetailRow(label: "Owner", value: model.ownedBy)
//                DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
//            }
//
//            // Details Section (Updated)
//            Section("Details") {
//                 VStack(alignment: .leading, spacing: 5) {
//                     Text("Description").font(.caption).foregroundColor(.secondary)
//                     Text(model.description) // Use the potentially longer description
//                 }.accessibilityElement(children: .combine)
//
//                 DetailRow(label: "Context Window", value: model.contextWindow)
//
//                 // Added Knowledge Cutoff
//                 if model.knowledgeCutoff != "N/A" {
//                     DetailRow(label: "Knowledge Cutoff", value: model.knowledgeCutoff)
//                 }
//                 // Added Max Output Tokens
//                 if let maxTokens = model.maxOutputTokens {
//                     DetailRow(label: "Max Output Tokens", value: "\(maxTokens)")
//                 }
//            }
//
//            // Capabilities Section (Use WrappingHStack)
//            if !model.capabilities.isEmpty && model.capabilities != ["general"] {
//                Section("Capabilities") {
//                    WrappingHStack(items: model.capabilities) { capability in
//                        Text(capability)
//                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
//                            .background(Color.accentColor.opacity(0.2))
//                            .foregroundColor(.accentColor).clipShape(Capsule())
//                    }
//                    .padding(.vertical, 4) // Add padding around the HStack
//                }
//            }
//
//            // Typical Use Cases Section (Unchanged)
//            if !model.typicalUseCases.isEmpty && model.typicalUseCases != ["Various tasks"] {
//                 Section("Typical Use Cases") {
//                     ForEach(model.typicalUseCases, id: \.self) { useCase in
//                         Label(useCase, systemImage: "play.rectangle").imageScale(.small)
//                     }
//                 }
//            }
//
//            // --- NEW: Pricing Section (Extracted from Description for Display) ---
//            // This requires parsing the description string - simple example
//            if let pricingInfo = extractPricing(from: model.description) {
//                Section("Pricing (per 1M tokens)") {
//                    DetailRow(label: "Input", value: pricingInfo.input)
//                    DetailRow(label: "Output", value: pricingInfo.output)
//                    if let cached = pricingInfo.cachedInput {
//                        DetailRow(label: "Cached Input", value: cached)
//                    }
//                }
//            }
//
//            // --- NEW: Endpoints & Modalities (Mock representation) ---
//            // We don't have structured data for this, showing based on `o1-mini` screenshot
//            // In a real app, this might come from a separate API or be added to the model struct
//             if model.id == "o1-mini" { // Show only for the specific model
//                Section("Endpoints & Modalities") {
//                     HStack { Image(systemName: "text.bubble.fill"); Text("Text Input/Output") }
//                     HStack { Image(systemName: "photo.fill.on.rectangle.fill"); Text("Image: Not Supported").foregroundColor(.secondary) }
//                     HStack { Image(systemName: "speaker.wave.2.fill"); Text("Audio: Not Supported").foregroundColor(.secondary) }
//                     Divider()
//                     HStack { Image(systemName: "bolt.horizontal.circle.fill"); Text("Chat Completions").foregroundColor(.green) }
//                     HStack { Image(systemName: "arrow.up.message.fill"); Text("Responses").foregroundColor(.green) }
//                     HStack { Image(systemName: "xmark.circle.fill"); Text("Other Endpoints Not Supported").foregroundColor(.secondary) }
//                 }
//                 Section("Features") {
//                     HStack { Image(systemName: "play.circle.fill"); Text("Streaming Supported").foregroundColor(.green) }
//                     HStack { Image(systemName: "xmark.circle.fill"); Text("Function Calling Not Supported").foregroundColor(.secondary) }
//                     // Add others as needed
//                 }
//             }
//
//        }
//        .listStyle(.insetGrouped)
//        .navigationTitle("Model Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//    // Helper for a simple detail row view
//    private func DetailRow(label: String, value: String) -> some View {
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//            Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
//        }
//         .padding(.vertical, 2) // Reduced padding for denser look
//         .accessibilityElement(children: .combine)
//    }
//
//    // Helper struct to hold extracted pricing
//    private struct PricingInfo {
//        let input: String
//        let output: String
//        let cachedInput: String?
//    }
//
//    // Simple helper to parse pricing from description (very basic!)
//    private func extractPricing(from description: String) -> PricingInfo? {
//        // Use regex or string scanning for a robust solution
//        // This is a basic example assuming the format in the mock data
//        let lines = description.split(separator: "\n")
//        var input: String?
//        var output: String?
//        var cached: String?
//
//        for line in lines {
//            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
//            if trimmedLine.starts(with: "Input:") { input = String(trimmedLine.dropFirst("Input:".count)).trimmingCharacters(in: .whitespaces) }
//            if trimmedLine.starts(with: "Output:") { output = String(trimmedLine.dropFirst("Output:".count)).trimmingCharacters(in: .whitespaces) }
//            if trimmedLine.starts(with: "Cached Input:") { cached = String(trimmedLine.dropFirst("Cached Input:".count)).trimmingCharacters(in: .whitespaces) }
//        }
//
//        if let input = input, let output = output {
//            return PricingInfo(input: input, output: output, cachedInput: cached)
//        }
//        return nil
//    }
//}
//
//// MARK: - Main Content View (Structure Unchanged)
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
//    // --- Filters for Sections (Based on Model IDs - Ensure o1-mini is included) ---
//    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "o4-mini", "o3"].contains($0.id) }.sortedById() }
//    var reasoningModels: [OpenAIModel] { allModels.filter { ["o4-mini", "o3", "o3-mini", "o1", "o1-pro", "o1-mini"].contains($0.id) }.sortedById() } // o1-mini included here
//    var flagshipChatModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "gpt-4o", "gpt-4o-audio", "chatgpt-4o-latest"].contains($0.id) }.sortedById() }
//    var costOptimizedModels: [OpenAIModel] { allModels.filter { ["o4-mini", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o-mini", "gpt-4o-mini-audio", "o3-mini", "o1-mini"].contains($0.id) }.sortedById() } // o3-mini & o1-mini also fit here
//    var realtimeModels: [OpenAIModel] { allModels.filter { ["gpt-4o-realtime", "gpt-4o-mini-realtime"].contains($0.id) }.sortedById() }
//    var olderGptModels: [OpenAIModel] { allModels.filter { ["gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"].contains($0.id) }.sortedById() }
//    var dalleModels: [OpenAIModel] { allModels.filter { $0.id.contains("dall-e") }.sortedById() }
//    var ttsModels: [OpenAIModel] { allModels.filter { $0.id.contains("tts") }.sortedById() }
//    var transcriptionModels: [OpenAIModel] { allModels.filter { $0.id.contains("whisper") || $0.id.contains("transcribe") }.sortedById() }
//    var embeddingsModels: [OpenAIModel] { allModels.filter { $0.id.contains("embedding") }.sortedById() }
//    var moderationModels: [OpenAIModel] { allModels.filter { $0.id.contains("moderation") }.sortedById() }
//    var toolSpecificModels: [OpenAIModel] { allModels.filter { $0.id.contains("search") || $0.id.contains("computer-use") }.sortedById() }
//
//    var body: some View { // (Main body structure unchanged, relies on filters above)
//        NavigationStack {
//            ZStack {
//                if isLoading && allModels.isEmpty {
//                    ProgressView("Fetching Models...").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemBackground)).zIndex(1)
//                } else if let errorMessage = errorMessage, allModels.isEmpty {
//                    ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
//                } else {
//                    ScrollView(.vertical, showsIndicators: false) {
//                        VStack(alignment: .leading, spacing: 30) {
//                            VStack(alignment: .leading, spacing: 5) {
//                                Text("Models").font(.largeTitle.weight(.bold))
//                                Text("Explore available models and capabilities.").font(.title3).foregroundColor(.secondary) // Slightly modified subtitle
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
//                            // Display sections using the filtered data
//                            displaySection(title: "Reasoning models", subtitle: "o-series models that excel at complex, multi-step tasks.", models: reasoningModels)
//                            displaySection(title: "Flagship chat models", subtitle: "Our versatile, high-intelligence flagship models.", models: flagshipChatModels)
//                            displaySection(title: "Cost-optimized models", subtitle: "Smaller, faster models that cost less to run.", models: costOptimizedModels)
//                            displaySection(title: "Realtime models", subtitle: "Models capable of realtime text and audio inputs and outputs.", models: realtimeModels)
//                            displaySection(title: "Older GPT models", subtitle: "Supported older versions of our general purpose and chat models.", models: olderGptModels)
//                            displaySection(title: "DALL·E", subtitle: "Models that can generate and edit images.", models: dalleModels)
//                            displaySection(title: "Text-to-speech", subtitle: "Models that can convert text into natural sounding audio.", models: ttsModels)
//                            displaySection(title: "Transcription", subtitle: "Model that can transcribe and translate audio into text.", models: transcriptionModels)
//                            displaySection(title: "Embeddings", subtitle: "A set of models that can convert text into vector representations.", models: embeddingsModels)
//                            displaySection(title: "Moderation", subtitle: "Fine-tuned models that detect potentially sensitive or unsafe input.", models: moderationModels)
//                            displaySection(title: "Tool-specific models", subtitle: "Models to support specific built-in tools.", models: toolSpecificModels)
//                            Spacer(minLength: 50)
//                        }.padding(.top)
//                    }
//                    .background(Color(.systemGroupedBackground)) // Consistent background
//                    .edgesIgnoringSafeArea(.bottom)
//                }
//            }
//            .navigationTitle("OpenAI Models")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { // (Toolbar implementation unchanged)
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
//             .navigationDestination(for: OpenAIModel.self) { model in // (Destination unchanged)
//                 ModelDetailView(model: model)
//                       .toolbarBackground(.visible, for: .navigationBar)
//                       .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar)
//             }
//             .task { if allModels.isEmpty { attemptLoadModels() } } // (Task unchanged)
//             .refreshable { await loadModelsAsync(checkApiKey: false) } // (Refreshable unchanged)
//             .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) } // (onChange unchanged)
//             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() } // (Sheet unchanged)
//             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: { Button("OK") { errorMessage = nil } }, message: { Text(errorMessage ?? "An unknown error occurred.") }) // (Alert unchanged)
//        }
//    }
//
//    // Helper View Builder for Sections (Unchanged)
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
//    // Helper Functions for Loading & API Key Handling (Unchanged)
//    private func handleToggleChange(to newValue: Bool) {
//         print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
//         allModels = []; errorMessage = nil
//         if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true }
//         else { loadModelsAsyncWithLoadingState() }
//    }
//    private func presentApiKeySheet() -> some View {
//         APIKeyInputView( onSave: { _ in print("API Key saved."); loadModelsAsyncWithLoadingState() }, onCancel: { print("API Key input cancelled."); useMockData = true } )
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
//
//    @MainActor
//    private func loadModelsAsync(checkApiKey: Bool) async {
//         if !isLoading { isLoading = true } // Set loading if not already
//         // Check for key only if using Live API AND explicitly told to check (avoids prompt on refresh)
//         if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//             showingApiKeySheet = true; isLoading = false; return
//         }
//         let serviceToUse = currentApiService
//         print("🔄 Loading models using \(useMockData ? "MockAPIService" : "LiveAPIService")...")
//         do {
//             let fetchedModels = try await serviceToUse.fetchModels()
//             self.allModels = fetchedModels
//             self.errorMessage = nil
//             print("✅ Successfully loaded \(fetchedModels.count) models.")
//         } catch let error as LocalizedError {
//             print("❌ Error loading models: \(error.localizedDescription)")
//             self.errorMessage = error.localizedDescription
//             // Don't clear models if there was already data (e.g., failed refresh)
//             // Only clear if the initial load failed completely
//             if self.allModels.isEmpty { self.allModels = [] }
//         } catch { // Catch non-localized errors
//             print("❌ Unexpected error loading models: \(error)")
//             self.errorMessage = "An unexpected error occurred."
//             if self.allModels.isEmpty { self.allModels = [] }
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
////#Preview("Detail View (o1-mini)") {
////    // Find the o1-mini model from the mock data generator
////    let mockService = MockAPIService()
////    let models = try! await mockService.fetchModels() // Use try! for preview context
////    let o1MiniModel = models.first { $0.id == "o1-mini" } ?? OpenAIModel(id: "o1-mini-preview-default", object: "model", created: 1, ownedBy: "preview") // Fallback
////
////    NavigationStack { ModelDetailView(model: o1MiniModel) }
////}
//
//#Preview("API Key Input Sheet") {
//    // Need a wrapper view to present the sheet in preview
//    struct SheetPresenter: View {
//        @State var showSheet = true
//        var body: some View {
//            Text("Tap to show sheet (already shown)").font(.caption).foregroundColor(.secondary)
//                .sheet(isPresented: $showSheet) {
//                    APIKeyInputView(onSave: {_ in}, onCancel: {})
//                }
//        }
//    }
//    return SheetPresenter()
//}
