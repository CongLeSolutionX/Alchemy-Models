////
////  OpenAIModelsMasterView_o3_mini.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIModelsMasterView_o3_mini_Detailed.swift
////  Alchemy_Models_Combined
////  (Single File Implementation - Enhanced for o3-mini details)
////
////  Created: Cong Le
////  Date: 4/13/25 (Updated with o3-mini specifics: 4/13/25)
////  Version: 1.2 (Synthesized & Adapted for o3-mini)
////  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
////  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
////
//
//import SwiftUI
//import Foundation
//import Combine
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
//    // --- Default values ---
//    var description: String = "No description available."
//    var capabilities: [String] = ["general"] // High-level capabilities
//    var contextWindow: String = "N/A"
//    var typicalUseCases: [String] = ["Various tasks"]
//    var shortDescription: String = "General purpose model."
//
//    // --- o3-mini Specific Data (will be populated in MockAPIService or potentially fetched) ---
//    // We keep the OpenAIModel struct relatively lean and add specific display logic in the View
//    // or fetch more detailed data if the API provided it.
//
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id
//        case object
//        case created
//        case ownedBy = "owned_by"
//        // description, capabilities, contextWindow, typicalUseCases, shortDescription
//        // are NOT in CodingKeys, allowing defaults if missing from basic API response.
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
//    // --- Determine SF Symbol name ---
//    var iconName: String {
//        let normalizedId = id.lowercased()
//        if normalizedId == "o3-mini" { return "leaf.fill" } // Specific icon for o3-mini based on reasoning/speed balance
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") || normalizedId.contains("chatgpt-4o") { return "sparkles" }
//        if normalizedId.contains("o4-mini") { return "leaf.fill" }
//        if normalizedId.contains("o3") { return "circle.hexagonpath.fill" }
//        if normalizedId.contains("o1") || normalizedId.contains("o1-pro") || normalizedId.contains("o1-mini") { return "circles.hexagonpath.fill" }
//        if normalizedId.contains("gpt-4.1-mini") || normalizedId.contains("gpt-4.1-nano") { return "leaf.fill" }
//        if normalizedId.contains("gpt-4o-mini") { return "leaf.fill" }
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
//        if normalizedId.contains("realtime") { return "bolt.badge.clock.fill" }
//
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return "building.columns.fill" }
//        if lowerOwner == "system" { return "gearshape.fill" }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return "person.crop.circle.fill" }
//        return "questionmark.circle.fill"
//    }
//
//    // --- Determine background color ---
//    var iconBackgroundColor: Color {
//        let normalizedId = id.lowercased()
//        if normalizedId == "o3-mini" { return .green } // Specific color for o3-mini
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
//        if normalizedId.contains("realtime") { return .yellow }
//
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return .blue.opacity(0.8) }
//        if lowerOwner == "system" { return .orange.opacity(0.8) }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return .purple.opacity(0.8) }
//        return .gray.opacity(0.7)
//    }
//
//    // --- Simplified name ---
//    var displayName: String {
//        return id.replacingOccurrences(of: "-", with: " ").capitalized
//    }
//}
//
//// MARK: - API Service Implementations
//
//// --- Mock Data Service ---
//class MockAPIService: APIServiceProtocol {
//    private let mockNetworkDelaySeconds: Double = 0.5
//
//    private func generateMockModels() -> [OpenAIModel] {
//        return [
//            // Featured & Reasoning (Include updated o3-mini)
//            OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k", shortDescription: "Flagship GPT model for complex tasks"),
//            OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Faster, more affordable reasoning model"),
//            OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "16k", shortDescription: "Our most powerful reasoning model"),
//            // *** Updated o3-mini Entry ***
//            OpenAIModel(id: "o3-mini", object: "model", created: 1706659200, ownedBy: "openai", // Approx Jan 31, 2025 based on snapshot
//                description: "o3-mini is our newest small reasoning model, providing high intelligence at the same cost and latency targets of o1-mini. o3-mini supports key developer features, like Structured Outputs and Batch API.",
//                capabilities: ["text generation", "reasoning", "chat completions", "batch api", "structured outputs", "streaming"], // Merged from screenshots
//                contextWindow: "200k", // From specs
//                typicalUseCases: ["Landing Page Generation", "Analyze Return Policy", "Text to SQL", "Graph Entity Extraction"], // From examples
//                shortDescription: "A small model alternative to o3" // From header
//            ),
//            // ...(Rest of the mock models from previous code)...
//             OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Previous full o-series reasoning model"),
//             OpenAIModel(id: "o1-pro", object: "model", created: 1685000000, ownedBy: "openai", description: "Version of o1 with more compute for better responses.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Version of o1 with more compute"),
//             OpenAIModel(id: "o1-mini", object: "model", created: 1675000000, ownedBy: "openai", description: "A small model alternative to o1, very fast.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "A small model alternative to o1"),
//
//             // Flagship Chat Models
//             OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "Fast, intelligent, flexible GPT model"),
//             OpenAIModel(id: "gpt-4o-audio", object: "model", created: 1712850000, ownedBy: "openai", description: "GPT-4o models capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "GPT-4o models capable of audio inputs"),
//             OpenAIModel(id: "chatgpt-4o-latest", object: "model", created: 1712900000, ownedBy: "openai", description: "GPT-4o model used in ChatGPT.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "GPT-4o model used in ChatGPT"),
//
//             // Cost-optimized Models
//             OpenAIModel(id: "gpt-4.1-mini", object: "model", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Balanced for intelligence, speed, cost"),
//             OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fastest, most cost-effective GPT-4.1"),
//             OpenAIModel(id: "gpt-4o-mini", object: "model", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model"),
//             OpenAIModel(id: "gpt-4o-mini-audio", object: "model", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "Smaller model capable of audio inputs"),
//
//             // Realtime Models
//             OpenAIModel(id: "gpt-4o-realtime", object: "model", created: 1712860000, ownedBy: "openai", description: "Model capable of realtime text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Model capable of realtime text/audio"),
//             OpenAIModel(id: "gpt-4o-mini-realtime", object: "model", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Smaller realtime model for text/audio"),
//
//             // Older GPT Models
//             OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "128k", shortDescription: "An older high-intelligence GPT model"),
//             OpenAIModel(id: "gpt-4", object: "model", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "8k / 32k", shortDescription: "An older high-intelligence GPT model"),
//             OpenAIModel(id: "gpt-3.5-turbo", object: "model", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", capabilities: ["text generation"], contextWindow: "4k / 16k", shortDescription: "Legacy GPT model for cheaper tasks"),
//
//             // DALL-E Models
//             OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our latest image generation model"),
//             OpenAIModel(id: "dall-e-2", object: "model", created: 1650000000, ownedBy: "openai", description: "Our first image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our first image generation model"),
//
//             // Text-to-speech Models
//            OpenAIModel(id: "tts-1", object: "model", created: 1690000000, ownedBy: "openai", description: "Text-to-speech model optimized for speed.", capabilities: ["tts"], contextWindow: "N/A", shortDescription: "Text-to-speech model optimized for speed"),
//            OpenAIModel(id: "tts-1-hd", object: "model", created: 1695000000, ownedBy: "openai", description: "Text-to-speech model optimized for quality.", capabilities: ["tts-hd"], contextWindow: "N/A", shortDescription: "Text-to-speech model optimized for quality"),
//            OpenAIModel(id: "gpt-4o-mini-tts", object: "model", created: 1712370000, ownedBy: "openai", description: "Text-to-speech model powered by GPT-4o mini.", capabilities: ["tts"], contextWindow: "N/A", shortDescription: "TTS model powered by GPT-4o mini"),
//
//              // Transcription Models
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
//            OpenAIModel(id: "text-moderation-latest", object: "model", created: 1688000000, ownedBy: "openai", description: "Previous generation text-only moderation model.", capabilities: ["content filtering"], contextWindow: "N/A", shortDescription: "Previous generation text moderation"), // Renamed from stable to latest per API docs convention
//            OpenAIModel(id: "omni-moderation", object: "model", created: 1712880000, ownedBy: "openai", description: "Identify potentially harmful content in text and images.", capabilities: ["content filtering", "image moderation"], contextWindow: "N/A", shortDescription: "Identify potentially harmful content"), // Assuming this exists
//
//             // Tool-specific Models (Assuming IDs based on names)
//            OpenAIModel(id: "gpt-4o-search-preview", object: "model", created: 1712890000, ownedBy: "openai", description: "GPT model for web search in Chat Completions.", capabilities: ["search", "text generation"], contextWindow: "128k", shortDescription: "GPT model for web search"),
//             OpenAIModel(id: "gpt-4o-mini-search-preview", object: "model", created: 1712390000, ownedBy: "openai", description: "Fast, affordable small model for web search.", capabilities: ["search", "text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model for search"),
//             OpenAIModel(id: "computer-use-preview", object: "model", created: 1712910000, ownedBy: "openai", description: "Specialized model for computer use tool.", capabilities: ["tool-use", "computer control"], contextWindow: "N/A", shortDescription: "Specialized model for computer use tool") // Placeholder
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
//        //print("🚀 Making live API request to: \(modelsURL)") // Keep logging minimal unless debugging
//
//        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//            guard let httpResponse = response as? HTTPURLResponse else { throw LiveAPIError.requestFailed(statusCode: 0) }
//            //print("✅ Received API response with status code: \(httpResponse.statusCode)")
//
//            if httpResponse.statusCode == 401 { throw LiveAPIError.missingAPIKey } // Treat 401 as invalid key specifically
//            guard (200...299).contains(httpResponse.statusCode) else { throw LiveAPIError.requestFailed(statusCode: httpResponse.statusCode) }
//
//            do {
//                 let decoder = JSONDecoder()
//                 let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
//                 //print("✅ Successfully decoded \(responseWrapper.data.count) models.")
//
//                 // *Important*: Live API might not return all fields. Defaults in OpenAIModel handle this.
//                 // We *don't* inject o3-mini specific details here as they aren't in the standard API response.
//                 // The detailed view will conditionally display them based on the mock data or hardcoded logic for o3-mini.
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
//// MARK: - Reusable SwiftUI Helper Views
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
//    private func generateContent(in g: GeometryProxy) -> some View { /* ... unchanged ... */
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
//    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View { /* ... unchanged ... */
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
//    var onSave: (String) -> Void
//    var onCancel: () -> Void
//    var body: some View { /* ... APIKeyInputView implementation (unchanged) ... */
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
//                     Text("API Key cannot be empty.")
//                          .font(.caption).foregroundColor(.red)
//                }
//
//                HStack {
//                    Button("Cancel") { onCancel(); dismiss() }.buttonStyle(.bordered)
//                    Spacer()
//                    Button("Save Key") {
//                         let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
//                         if trimmedKey.isEmpty {
//                             isInvalidKeyAttempt = true
//                         } else {
//                             apiKey = trimmedKey
//                             onSave(apiKey)
//                             dismiss()
//                         }
//                    }.buttonStyle(.borderedProminent)
//                }
//                .padding(.top)
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
//// --- Helper for Ratings ---
//struct RatingView: View {
//    let label: String
//    let rating: Int // Out of 5
//    let maxRating: Int = 5
//    let filledSymbol: String // e.g., "brain.head.profile" or "bolt.fill"
//    let emptySymbol: String? // Optional empty state symbol
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 3) {
//            Text(label)
//                .font(.caption)
//                .foregroundColor(.secondary)
//            HStack(spacing: 2) {
//                ForEach(0..<maxRating, id: \.self) { index in
//                    Image(systemName: index < rating ? filledSymbol : (emptySymbol ?? filledSymbol))
//                        .foregroundColor(index < rating ? .primary : .gray.opacity(0.4))
//                }
//            }
//            .font(.subheadline) // Adjust size of symbols
//        }
//    }
//}
//
//// --- Helper for Support Status ---
//struct SupportStatusLabel: View {
//    let label: String
//    let isSupported: Bool
//
//    var body: some View {
//        Label {
//            Text(label)
//                .strikethrough(!isSupported, color: .secondary) // Strikethrough if not supported
//                .foregroundColor(isSupported ? .primary : .secondary)
//        } icon: {
//            Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
//                .foregroundColor(isSupported ? .green : .red.opacity(0.8))
//        }
//        .font(.callout)
//        .imageScale(.small)
//    }
//}
//
//// --- Helper for Pricing Row ---
//struct PricingRow: View {
//    let label: String
//    let price: String
//    let unit: String = "/ 1M tokens"
//
//    var body: some View {
//        HStack {
//            Text(label)
//                .font(.callout)
//                .foregroundColor(.secondary)
//            Spacer()
//            HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(price)
//                    .font(.body.weight(.medium))
//                Text(unit)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//        }
//    }
//}
//
//// MARK: - Model Views (Featured Card, Standard Row, Detail - Detail Enhanced for o3-mini)
//
//struct FeaturedModelCard: View {
//    let model: OpenAIModel
//    var body: some View { /* ... FeaturedModelCard implementation (unchanged) ... */
//        VStack(alignment: .leading, spacing: 10) {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(model.iconBackgroundColor.opacity(0.3))
//                .frame(height: 120)
//                 .overlay(
//                      Image(systemName: model.iconName)
//                           .resizable().scaledToFit().padding(25)
//                           .foregroundStyle(model.iconBackgroundColor)
//                 )
//            VStack(alignment: .leading, spacing: 4) {
//                Text(model.displayName).font(.headline)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
//            }
//            .padding([.horizontal, .bottom], 12)
//        }
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
//         .frame(minWidth: 0, maxWidth: .infinity)
//    }
//}
//
//struct StandardModelRow: View {
//    let model: OpenAIModel
//    var body: some View { /* ... StandardModelRow implementation (unchanged) ... */
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
//        .padding(10).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
//        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
//    }
//}
//
//struct SectionHeader: View {
//    let title: String
//    let subtitle: String?
//    var body: some View { /* ... SectionHeader implementation (unchanged) ... */
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title).font(.title2.weight(.semibold))
//            if let subtitle = subtitle { Text(subtitle).font(.callout).foregroundColor(.secondary) }
//        }
//        .padding(.bottom, 10).padding(.horizontal)
//    }
//}
//
//// --- !!! Model Detail View (Enhanced for o3-mini) !!! ---
//struct ModelDetailView: View {
//    let model: OpenAIModel
//
//    var body: some View {
//        List {
//            // --- Top Section: Icon and Name ---
//            Section {
//                VStack(spacing: 15) {
//                    Image(systemName: model.iconName)
//                        .resizable().scaledToFit()
//                        .padding(15).frame(width: 80, height: 80)
//                        .background(model.iconBackgroundColor).foregroundStyle(.white)
//                        .clipShape(Circle())
//                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
//                    Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
//                    Text(model.shortDescription).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center)
//                }
//                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical)
//            }
//            .listRowBackground(Color.clear) // Remove default background for this section
//
//            // --- o3-mini Specific Sections ---
//            if model.id == "o3-mini" {
//                o3MiniSpecificSections
//            } else {
//                // --- Default Sections for other models ---
//                defaultSections
//            }
//
//            // --- Use Cases Section (Consistent for all) ---
//             if !model.typicalUseCases.isEmpty && model.typicalUseCases != ["Various tasks"] {
//                 Section("Prompt Examples / Use Cases") {
//                     ForEach(model.typicalUseCases, id: \.self) { useCase in
//                         Text(useCase) // Simpler display for examples
//                             // Label(useCase, systemImage: "play.rectangle") // Alternative with icon
//                             .font(.callout)
//                             .foregroundColor(.primary)
//                     }
//                 }
//            }
//
//        } // End List
//        .listStyle(.insetGrouped)
//        .navigationTitle("Model Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//    // --- o3-mini Specific Content Builder ---
//    @ViewBuilder
//    private var o3MiniSpecificSections: some View {
//        // Ratings & Pricing Section
//        Section {
//            HStack(alignment: .top, spacing: 20) {
//                RatingView(label: "Reasoning", rating: 4, filledSymbol: "brain.head.profile", emptySymbol: "brain.head.profile")
//                RatingView(label: "Speed", rating: 3, filledSymbol: "bolt.fill", emptySymbol: "bolt.slash.fill") // Using slash for empty
//                Spacer() // Push ratings to the left
//            }
//            PricingRow(label: "Input", price: "$1.10")
//            PricingRow(label: "Cached Input", price: "$0.55")
//            PricingRow(label: "Output", price: "$4.40")
//        } header: { Text("Performance & Pricing") }
//
//        // Description Section
//        Section("Description") {
//            Text(model.description) // Use the long description from mock data
//        }
//
//        // Key Specs Section
//        Section("Key Specifications") {
//            DetailRow(label: "Context Window", value: "200,000 tokens")
//            DetailRow(label: "Max Output Tokens", value: "100,000 tokens")
//            DetailRow(label: "Knowledge Cutoff", value: "Sep 30, 2023")
//            DetailRow(label: "Reasoning Tokens", value: "Supported") // Based on text "Reasoning token support"
//        }
//
//        // Modalities Section
//        Section("Modalities") {
//            SupportStatusLabel(label: "Text Input", isSupported: true)
//            SupportStatusLabel(label: "Text Output", isSupported: true)
//            SupportStatusLabel(label: "Image Input/Output", isSupported: false)
//            SupportStatusLabel(label: "Audio Input/Output", isSupported: false)
//        }
//
//        // Endpoints Section (Based on Screenshot 1)
//        Section("Endpoints") {
//            SupportStatusLabel(label: "Chat Completions (/v1/chat/completions)", isSupported: true)
//            SupportStatusLabel(label: "Responses (/v1/responses)", isSupported: true)
//            SupportStatusLabel(label: "Batch API (/v1/batch)", isSupported: true)
//            SupportStatusLabel(label: "Realtime", isSupported: false)
//            SupportStatusLabel(label: "Assistants API (/v1/assistants)", isSupported: false)
//            SupportStatusLabel(label: "Fine-tuning", isSupported: false)
//            SupportStatusLabel(label: "Embeddings", isSupported: false)
//            SupportStatusLabel(label: "Image Generation", isSupported: false)
//            SupportStatusLabel(label: "Speech Generation (TTS)", isSupported: false)
//            SupportStatusLabel(label: "Transcription (Whisper)", isSupported: false)
//            SupportStatusLabel(label: "Translation", isSupported: false)
//            SupportStatusLabel(label: "Moderation", isSupported: false)
//            SupportStatusLabel(label: "Completions (Legacy)", isSupported: false)
//        }
//
//        // Features Section (Based on Screenshot 1)
//        Section("Features") {
//            SupportStatusLabel(label: "Streaming", isSupported: true)
//            SupportStatusLabel(label: "Structured Outputs", isSupported: true)
//            SupportStatusLabel(label: "Function Calling", isSupported: false) // Screenshot 1 overrides desc text
//            SupportStatusLabel(label: "Fine-tuning (Feature)", isSupported: false)
//            SupportStatusLabel(label: "Distillation", isSupported: false)
//            SupportStatusLabel(label: "Predicted Outputs", isSupported: false)
//        }
//
//        // Snapshots Section
//        Section("Available Snapshots") {
//            Text("`o3-mini` (Latest alias)")
//                .font(.system(.callout, design: .monospaced))
//            Text("`o3-mini-2025-01-31`")
//                .font(.system(.callout, design: .monospaced))
//        }
//    }
//
//    // --- Default Content Builder for other models ---
//     @ViewBuilder
//     private var defaultSections: some View {
//         Section("Overview") {
//             DetailRow(label: "Full ID", value: model.id)
//             DetailRow(label: "Type", value: model.object)
//             DetailRow(label: "Owner", value: model.ownedBy)
//             DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
//         }
//
//         Section("Details") {
//              VStack(alignment: .leading, spacing: 5) {
//                  Text("Description").font(.caption).foregroundColor(.secondary)
//                  Text(model.description)
//              }.accessibilityElement(children: .combine)
//              VStack(alignment: .leading, spacing: 5) {
//                  Text("Context Window").font(.caption).foregroundColor(.secondary)
//                  Text(model.contextWindow)
//              }.accessibilityElement(children: .combine)
//         }
//
//         // Show generic 'capabilities' if not 'general'
//         if !model.capabilities.isEmpty && !(model.capabilities.count == 1 && model.capabilities.first == "general") {
//             Section("Capabilities") {
//                 WrappingHStack(items: model.capabilities) { capability in
//                     Text(capability)
//                         .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
//                         .background(Color.accentColor.opacity(0.2))
//                         .foregroundColor(.accentColor).clipShape(Capsule())
//                 }
//             }
//         }
//     }
//
//    // Helper Detail Row (Unchanged)
//    private func DetailRow(label: String, value: String) -> some View {
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//            Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
//        }
//        .padding(.vertical, 2)
//        .accessibilityElement(children: .combine)
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
//    // --- Filters for Sections (Based on Model IDs - Update with new models if needed) ---
//    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "o4-mini", "o3"].contains($0.id) }.sortedById() }
//    var reasoningModels: [OpenAIModel] { allModels.filter { ["o4-mini", "o3", "o3-mini", "o1", "o1-pro", "o1-mini"].contains($0.id) }.sortedById() }
//    var flagshipChatModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "gpt-4o", "gpt-4o-audio", "chatgpt-4o-latest"].contains($0.id) }.sortedById() }
//    var costOptimizedModels: [OpenAIModel] { allModels.filter { ["o4-mini", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o-mini", "gpt-4o-mini-audio", "o3-mini", "o1-mini"].contains($0.id) }.sortedById() } // Added o3-mini
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
//                     ProgressView("Fetching Models...")
//                           .frame(maxWidth: .infinity, maxHeight: .infinity)
//                           .background(Color(.systemBackground)).zIndex(1)
//                 } else if let errorMessage = errorMessage, allModels.isEmpty {
//                     ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
//                 } else {
//                    // --- Main Scrollable Content ---
//                    ScrollView(.vertical, showsIndicators: false) {
//                        VStack(alignment: .leading, spacing: 30) {
//
//                             // --- Header Text ---
//                             VStack(alignment: .leading, spacing: 5) {
//                                 Text("Models").font(.largeTitle.weight(.bold))
//                                 Text("Explore available models and compare capabilities.")
//                                     .font(.title3).foregroundColor(.secondary)
//                             }.padding(.horizontal)
//
//                             Divider().padding(.horizontal)
//
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
//
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
//
//                             Spacer(minLength: 50) // Add space at the bottom
//
//                        }.padding(.top)
//                    } // End ScrollView
//                    .background(Color(.systemBackground))
//                    .edgesIgnoringSafeArea(.bottom)
//                 }
//            } // End ZStack
//            .navigationTitle("OpenAI Models")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { // --- Toolbar (Unchanged) ---
//                 ToolbarItem(placement: .navigationBarLeading) {
//                     if isLoading { ProgressView().controlSize(.small) }
//                     else { Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(isLoading) }
//                 }
//                 ToolbarItem(placement: .navigationBarTrailing) {
//                     Menu {
//                         Toggle(isOn: $useMockData) { Text(useMockData ? "Using Mock Data" : "Using Live API") }
//                     } label: {
//                         Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill")
//                           .foregroundColor(useMockData ? .secondary : .blue)
//                     }.disabled(isLoading)
//                 }
//             }
//             .navigationDestination(for: OpenAIModel.self) { model in
//                 ModelDetailView(model: model) // Navigate to potentially enhanced detail view
//                       .toolbarBackground(.visible, for: .navigationBar)
//                       .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
//             }
//             .task { if allModels.isEmpty { attemptLoadModels() } }
//             .refreshable { await loadModelsAsync(checkApiKey: false) }
//             .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
//             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
//             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: {
//                 Button("OK") { errorMessage = nil }
//             }, message: { Text(errorMessage ?? "An unknown error occurred.") })
//        } // End NavigationStack
//    }
//
//    // --- Helper View Builder for Sections (Unchanged) ---
//    @ViewBuilder
//    private func displaySection(title: String, subtitle: String?, models: [OpenAIModel]) -> some View { /* ... unchanged ... */
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
//    // --- Helper Functions for Loading & API Key Handling (Unchanged) ---
//    private func handleToggleChange(to newValue: Bool) { /* ... unchanged ... */
//         allModels = []; errorMessage = nil
//         if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true }
//         else { loadModelsAsyncWithLoadingState() }
//    }
//    private func presentApiKeySheet() -> some View { /* ... unchanged ... */
//         APIKeyInputView( onSave: { _ in loadModelsAsyncWithLoadingState() }, onCancel: { useMockData = true } )
//    }
//    private func attemptLoadModels() { /* ... unchanged ... */
//         guard !isLoading else { return }
//         if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true }
//         else { loadModelsAsyncWithLoadingState() }
//     }
//    private func loadModelsAsyncWithLoadingState() { /* ... unchanged ... */
//         guard !isLoading else { return }
//         isLoading = true; Task { await loadModelsAsync(checkApiKey: false) }
//    }
//    @MainActor private func loadModelsAsync(checkApiKey: Bool) async { /* ... unchanged ... */
//         if !isLoading { isLoading = true }
//         if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//             showingApiKeySheet = true; isLoading = false; return
//         }
//         let serviceToUse = currentApiService
//         do {
//             let fetchedModels = try await serviceToUse.fetchModels()
//             self.allModels = fetchedModels; self.errorMessage = nil
//         } catch let error as LocalizedError {
//             self.errorMessage = error.localizedDescription; if allModels.isEmpty { self.allModels = [] }
//         } catch {
//             self.errorMessage = "Unexpected error: \(error.localizedDescription)"; if allModels.isEmpty { self.allModels = [] }
//         }
//         isLoading = false
//    }
//}
//
//// MARK: - Helper Extensions
//
//extension Array where Element == OpenAIModel {
//    func sortedById() -> [OpenAIModel] { // Unchanged
//        self.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
//    }
//}
//
//// MARK: - Previews
//
//#Preview("Main View (Mock)") { OpenAIModelsMasterView() }
//
//#Preview("Detail View (o3-mini)") {
//    // Create a mock o3-mini model instance directly for preview
//    let o3MiniMock = MockAPIService().fetchModels // Simplified way to get mocks
//    let model = OpenAIModel(id: "o3-mini", object: "model", created: 1706659200, ownedBy: "openai",
//                            description: "o3-mini is our newest small reasoning model, providing high intelligence at the same cost and latency targets of o1-mini. o3-mini supports key developer features, like Structured Outputs and Batch API.",
//                            capabilities: ["text generation", "reasoning", "chat completions", "batch api", "structured outputs", "streaming"],
//                            contextWindow: "200k",
//                            typicalUseCases: ["Landing Page Generation", "Analyze Return Policy", "Text to SQL", "Graph Entity Extraction"],
//                            shortDescription: "A small model alternative to o3")
//    NavigationStack { ModelDetailView(model: model) }
//}
//
//#Preview("Detail View (Generic)") {
//    let model = OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "128k", shortDescription: "An older high-intelligence GPT model")
//    NavigationStack { ModelDetailView(model: model) }
//}
//
//// ...(Other previews remain unchanged)...
//#Preview("Empty/Loading State Sim") { ProgressView("Fetching...").frame(width: 200, height: 200) }
//#Preview("Error State Sim") { ErrorView(errorMessage: "Network Failed") {}.frame(width: 300, height: 300) }
//#Preview("Featured Card") { FeaturedModelCard(model: OpenAIModel(id: "gpt-4.1", object: "model", created: 1, ownedBy: "openai", shortDescription: "Flagship")).padding().frame(width: 280) }
//#Preview("Standard Row") { StandardModelRow(model: OpenAIModel(id: "o3-mini", object: "model", created: 1, ownedBy: "openai", shortDescription: "Affordable reasoning")).padding().frame(width: 350) }
//#Preview("API Key Sheet") { struct SheetPresenter: View { @State var show = true; var body: some View { Text("Tap").sheet(isPresented: $show) { APIKeyInputView(onSave: {_ in}, onCancel: {})}}} ; return SheetPresenter() }
