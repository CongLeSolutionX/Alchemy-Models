////
////  OpenAIModelsMasterView_o4_mini.swift
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
////  Version: 1.2 (Added O4-Mini Details & View)
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
//// MARK: - Detailed Data Sub-Structs (for o4-mini)
//
//struct PerformanceMetrics: Codable, Hashable {
//    var reasoning: String? // e.g., "Higher"
//    var speed: String?     // e.g., "Medium"
//    var priceRange: String? // e.g., "$1.1 - $4.4"
//    var inputTypes: [String]? // e.g., ["Text", "Image"]
//    var outputTypes: [String]? // e.g., ["Text"]
//}
//
//struct KeySpecs: Codable, Hashable {
//    var contextWindowTokens: Int?
//    var maxOutputTokens: Int?
//    var knowledgeCutoff: String? // e.g., "May 31, 2024"
//    var reasoningTokenSupport: Bool?
//}
//
//struct PricingInfo: Codable, Hashable {
//    var inputPerMillionTokens: Double?
//    var cachedInputPerMillionTokens: Double?
//    var outputPerMillionTokens: Double?
//    var unit: String = "/ 1M tokens" // Default unit
//}
//
//struct ModalityInfo: Codable, Hashable, Identifiable {
//    var id: String { name }
//    var name: String // "Text", "Image", "Audio"
//    var support: String // "Input and output", "Input only", "Not supported"
//    var icon: String // SF Symbol name
//}
//
//struct EndpointInfo: Codable, Hashable, Identifiable {
//    var id: String { name }
//    var name: String // "Chat Completions", "Realtime", etc.
//    var path: String? // e.g., "/v1/chat/completions" (optional)
//    var supported: Bool
//    var icon: String // SF Symbol name
//}
//
//struct FeatureInfo: Codable, Hashable, Identifiable {
//    var id: String { name }
//    var name: String // "Streaming", "Function calling", etc.
//    var supported: Bool
//    var icon: String // SF Symbol name
//}
//
//struct SnapshotInfo: Codable, Hashable, Identifiable {
//    var id: String { name }
//    var name: String // Alias or specific version name
//    var type: String // e.g., "Latest Alias", "Stable Version"
//    var icon: String // SF Symbol name
//}
//
//struct RateLimitTier: Codable, Hashable, Identifiable {
//    var id: String { tierName }
//    var tierName: String // "Free", "Tier 1", etc.
//    var rpm: String? // Requests per minute
//    var rpd: String? // Requests per day (often "-")
//    var tpm: String? // Tokens per minute
//    var batchQueueLimit: String?
//    var usageTier: String? // "Free", "Pay-as-you-go", etc. (implied, adding for clarity)
//}
//
//// MARK: - Main Data Model (Expanded)
//struct ModelListResponse: Codable {
//    let data: [OpenAIModel]
//}
//
//struct OpenAIModel: Codable, Identifiable, Hashable {
//    // --- Core Properties (from original structure) ---
//    let id: String
//    let object: String
//    let created: Int // Unix timestamp
//    let ownedBy: String
//
//    // --- Default values for potentially missing fields (less detailed models) ---
//    var description: String = "No description available."
//    var capabilities: [String] = ["general"]
//    var contextWindow: String = "N/A" // General string for simpler models
//    var typicalUseCases: [String] = ["Various tasks"]
//    var shortDescription: String = "General purpose model."
//    var tagline: String? = nil // Added from o4-mini
//
//    // --- Detailed Properties (primarily for o4-mini, optional for others) ---
//    var performance: PerformanceMetrics? = nil
//    var specs: KeySpecs? = nil
//    var pricing: PricingInfo? = nil
//    var modalities: [ModalityInfo]? = nil
//    var endpoints: [EndpointInfo]? = nil
//    var features: [FeatureInfo]? = nil
//    var snapshots: [SnapshotInfo]? = nil
//    var rateLimits: [RateLimitTier]? = nil
//
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id, object, created
//        case ownedBy = "owned_by"
//        // --- Add keys for new detailed properties if they exist in JSON ---
//        // If using only mock data for detail, these don't strictly need to be here
//        // as long as default init values handle missing keys.
//        case description, capabilities, contextWindow, typicalUseCases, shortDescription, tagline
//        case performance, specs, pricing, modalities, endpoints, features, snapshots, rateLimits
//    }
//
//    // --- Computed Properties & Hashable ---
//    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
//    func hash(into hasher: inout Hasher) { hasher.combine(id) }
//    static func == (lhs: OpenAIModel, rhs: OpenAIModel) -> Bool { lhs.id == rhs.id }
//}
//
//// MARK: - Model Extension for UI Logic (Mostly Unchanged)
//
//extension OpenAIModel {
//    // Keep existing icon logic, maybe adjust for o4-mini if needed
//    var iconName: String {
//        let normalizedId = id.lowercased()
//        if normalizedId.contains("o4-mini") || normalizedId.contains("o3-mini") || normalizedId.contains("o1-mini") || normalizedId.contains("gpt-4.1-mini") { return "leaf.fill" } // Group minis
//        if normalizedId.contains("gpt-4.1") && !normalizedId.contains("mini") { return "sparkles" }
//        if normalizedId.contains("gpt-4o") { return "wand.and.stars" } // Better icon for 'o'
//        if normalizedId.contains("o3") && !normalizedId.contains("mini") { return "circle.hexagonpath.fill" }
//        if normalizedId.contains("o1") { return "circles.hexagonpath.fill" }
//        if normalizedId.contains("gpt-4-turbo") { return "bolt.fill" }
//        if normalizedId.contains("gpt-4") && !normalizedId.contains("turbo") && !normalizedId.contains("4o") && !normalizedId.contains("4.1") { return "star.fill"} // Careful with overlaps
//        if normalizedId.contains("gpt-3.5") { return "forward.fill" }
//        if normalizedId.contains("dall-e") { return "paintbrush.pointed.fill" }
//        if normalizedId.contains("tts") { return "speaker.wave.2.fill" }
//        if normalizedId.contains("transcribe") || normalizedId.contains("whisper") { return "waveform" }
//        if normalizedId.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" }
//        if normalizedId.contains("moderation") { return "exclamationmark.shield.fill" }
//        if normalizedId.contains("search") { return "magnifyingglass"}
//        if normalizedId.contains("computer-use") { return "computermouse.fill" }
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return "building.columns.fill" }
//        if lowerOwner == "system" { return "gearshape.fill" }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return "person.crop.circle.fill" }
//        return "questionmark.circle.fill"
//    }
//
//    var iconBackgroundColor: Color {
//        let normalizedId = id.lowercased()
//        if normalizedId.contains("o4-mini") || normalizedId.contains("gpt-4.1-mini") { return .purple } // Group minis
//        if normalizedId.contains("gpt-4.1") && !normalizedId.contains("mini") { return .blue }
//        if normalizedId.contains("gpt-4o") { return .cyan } // Differentiate 4o
//        if normalizedId.contains("o3") { return .orange }
//        if normalizedId.contains("dall-e") { return .teal }
//        if normalizedId.contains("tts") { return .indigo }
//        if normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return .pink }
//        if normalizedId.contains("embedding") { return .green }
//        if normalizedId.contains("moderation") { return .red }
//        if normalizedId.contains("search") { return .cyan }
//        if normalizedId.contains("computer-use") { return .brown }
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return .blue.opacity(0.8) }
//        if lowerOwner == "system" { return .orange.opacity(0.8) }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return .purple.opacity(0.8) }
//        return .gray.opacity(0.7)
//    }
//
//    var displayName: String {
//        return id.replacingOccurrences(of: "-", with: " ").capitalized // Keep simple naming
//    }
//}
//
//// MARK: - API Service Implementations (Mock Updated)
//
//// --- Mock Data Service ---
//class MockAPIService: APIServiceProtocol {
//    private let mockNetworkDelaySeconds: Double = 0.8
//
//    private func generateMockModels() -> [OpenAIModel] {
//        // --- Define o4-mini details ---
//        let o4MiniDetails = OpenAIModel(
//            id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai",
//            description: "o4-mini is our latest small o-series model. It's optimized for fast, effective reasoning with exceptionally efficient performance in coding and visual tasks.\nLearn more about how to use our reasoning models in our [reasoning guide](link-placeholder).", // Added markdown link placeholder
//            capabilities: ["text generation", "reasoning", "coding", "visual tasks"], // Added from text
//            contextWindow: "200k tokens", // Specific value
//            typicalUseCases: [], // Not explicitly listed beyond description
//            shortDescription: "Faster, more affordable reasoning model",
//            tagline: "Faster, more affordable reasoning model",
//            performance: PerformanceMetrics(
//                reasoning: "Higher", speed: "Medium", priceRange: "$1.1 - $4.4",
//                inputTypes: ["Text", "Image"], outputTypes: ["Text"]
//            ),
//            specs: KeySpecs(
//                contextWindowTokens: 200_000, maxOutputTokens: 100_000,
//                knowledgeCutoff: "May 31, 2024", reasoningTokenSupport: true
//            ),
//            pricing: PricingInfo(
//                inputPerMillionTokens: 1.10, cachedInputPerMillionTokens: 0.275, outputPerMillionTokens: 4.40
//            ),
//            modalities: [
//                ModalityInfo(name: "Text", support: "Input and output", icon: "text.bubble.fill"),
//                ModalityInfo(name: "Image", support: "Input only", icon: "photo.fill"),
//                ModalityInfo(name: "Audio", support: "Not supported", icon: "speaker.slash.fill")
//            ],
//            endpoints: [
//                EndpointInfo(name: "Chat Completions", path: "/v1/chat/completions", supported: true, icon: "message.fill"),
//                EndpointInfo(name: "Responses", path: "/v1/responses", supported: true, icon: "arrow.uturn.left.circle.fill"), // Assume 'Responses' is a valid endpoint shown
//                EndpointInfo(name: "Realtime", supported: false, icon: "bolt.fill"),
//                EndpointInfo(name: "Assistants", supported: false, icon: "person.2.fill"),
//                EndpointInfo(name: "Batch", path: "/v1/batch", supported: true, icon: "list.bullet.rectangle.fill"),
//                EndpointInfo(name: "Embeddings", supported: false, icon: "arrow.down.right.and.arrow.up.left.circle.fill"),
//                EndpointInfo(name: "Fine-tuning", supported: false, icon: "slider.horizontal.3"),
//                EndpointInfo(name: "Image generation", supported: false, icon: "photo.on.rectangle.angled"),
//                EndpointInfo(name: "Speech generation", supported: false, icon: "waveform.path.ecg"),
//                EndpointInfo(name: "Transcription", supported: false, icon: "mic.fill"),
//                EndpointInfo(name: "Moderation", supported: false, icon: "exclamationmark.shield.fill"),
//                EndpointInfo(name: "Completions (legacy)", supported: false, icon: "text.append")
//            ],
//            features: [
//                FeatureInfo(name: "Streaming", supported: true, icon: "play.circle.fill"),
//                FeatureInfo(name: "Function calling", supported: true, icon: "hammer.fill"),
//                FeatureInfo(name: "Structured outputs", supported: true, icon: "curlybraces.square.fill"),
//                FeatureInfo(name: "Fine-tuning", supported: false, icon: "slider.horizontal.3"),
//                FeatureInfo(name: "Distillation", supported: false, icon: "drop.fill"), // Placeholder icon
//                FeatureInfo(name: "Predicted outputs", supported: false, icon: "wand.and.rays") // Placeholder icon
//            ],
//            snapshots: [
//                SnapshotInfo(name: "o4-mini", type: "Latest Alias", icon: "tag.fill"),
//                SnapshotInfo(name: "o4-mini-2025-04-16", type: "Stable Version", icon: "calendar.badge.clock") // Example, date from screenshot
//            ],
//            rateLimits: [
//                RateLimitTier(tierName: "Free", rpm: nil, rpd: "-", tpm: "100,000", batchQueueLimit: "1,000,000", usageTier: "Free"),
//                RateLimitTier(tierName: "Tier 1", rpm: "1,000", rpd: "-", tpm: "200,000", batchQueueLimit: "2,000,000", usageTier: "Pay-as-you-go"),
//                RateLimitTier(tierName: "Tier 2", rpm: "2,000", rpd: "-", tpm: "5,000,000", batchQueueLimit: "4,000,000", usageTier: "Pay-as-you-go"),
//                RateLimitTier(tierName: "Tier 3", rpm: "5,000", rpd: "-", tpm: "10,000,000", batchQueueLimit: "40,000,000", usageTier: "Pay-as-you-go"),
//                RateLimitTier(tierName: "Tier 4", rpm: "10,000", rpd: "-", tpm: "100,000,000", batchQueueLimit: "1,000,000,000", usageTier: "Pay-as-you-go"),
//                RateLimitTier(tierName: "Tier 5", rpm: "30,000", rpd: "-", tpm: "150,000,000", batchQueueLimit: "15,000,000,000", usageTier: "Pay-as-you-go")
//            ]
//        )
//
//        return [
//             // Add the detailed o4-mini model
//             o4MiniDetails,
//
//             // --- Other models from previous version (ensure IDs don't clash, keep structure simpler) ---
//             OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k", shortDescription: "Flagship GPT model"),
//             OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "16k", shortDescription: "Previous powerful reasoning model"),
//             OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "Fast, intelligent, flexible GPT model"),
//             OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Latest image generation model"),
//             // ... add other simplified models as needed ...
//        ]
//    }
//
//    func fetchModels() async throws -> [OpenAIModel] {
//         try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
//         return generateMockModels()
//    }
//}
//
//// --- Live Data Service (Unchanged - will not populate detailed fields) ---
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
//                 // Note: Live API won't fill the detailed properties added above.
//                 // They will retain their default nil/empty values.
//                 // The shortDescription logic might need adjustment if relying on live data.
//                 return responseWrapper.data.map { model in
//                     var mutableModel = model
//                     if mutableModel.shortDescription == "General purpose model." {
//                         mutableModel.shortDescription = model.ownedBy.contains("openai") ? "OpenAI model." : "User or system model."
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
//// MARK: - Reusable SwiftUI Helper Views (Existing + New for O4Mini)
//
//// --- Existing ErrorView (Unchanged) ---
//struct ErrorView: View {
//    let errorMessage: String
//    let retryAction: () -> Void
//    var body: some View { /* ... Implementation above ... */
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
//// --- Existing WrappingHStack (Unchanged) ---
//struct WrappingHStack<Item: Hashable, ItemView: View>: View {
//    let items: [Item]
//    let viewForItem: (Item) -> ItemView
//    let horizontalSpacing: CGFloat = 8
//    let verticalSpacing: CGFloat = 8
//    @State private var totalHeight: CGFloat = .zero
//    var body: some View { /* ... Implementation above ... */
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
//// --- Existing APIKeyInputView (Unchanged) ---
//struct APIKeyInputView: View {
//    @Environment(\.dismiss) var dismiss
//    @AppStorage("userOpenAIKey") private var apiKey: String = "" // Two-way binding
//    @State private var inputApiKey: String = "" // Local state for the text field
//    @State private var isInvalidKeyAttempt: Bool = false // State for validation feedback
//
//    var onSave: (String) -> Void
//    var onCancel: () -> Void
//    var body: some View { /* ... Implementation above ... */
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
//// --- Existing FeaturedModelCard (Unchanged) ---
//struct FeaturedModelCard: View {
//    let model: OpenAIModel
//    var body: some View { /* ... Implementation above ... */
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
//            }.padding([.horizontal, .bottom], 12)
//        }
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
//         .frame(minWidth: 0, maxWidth: .infinity)
//    }
//}
//
//// --- Existing StandardModelRow (Unchanged) ---
//struct StandardModelRow: View {
//    let model: OpenAIModel
//    var body: some View { /* ... Implementation above ... */
//        HStack(spacing: 12) {
//            Image(systemName: model.iconName)
//                .resizable().scaledToFit().padding(7)
//                .frame(width: 36, height: 36)
//                .background(model.iconBackgroundColor.opacity(0.85))
//                .foregroundStyle(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//
//            VStack(alignment: .leading, spacing: 3) {
//                Text(model.displayName).font(.subheadline.weight(.medium)).lineLimit(1)
//                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
//            }
//            Spacer(minLength: 0)
//        }
//        .padding(10)
//        .background(.regularMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 10))
//        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
//    }
//}
//
//// --- Existing SectionHeader (Unchanged) ---
//struct SectionHeader: View {
//    let title: String
//    let subtitle: String?
//    var body: some View { /* ... Implementation above ... */
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title).font(.title2.weight(.semibold))
//            if let subtitle = subtitle { Text(subtitle).font(.callout).foregroundColor(.secondary) }
//        }
//        .padding(.bottom, 10).padding(.horizontal)
//    }
//}
//
//// --- Existing Generic ModelDetailView (Unchanged) ---
//struct ModelDetailView: View {
//    let model: OpenAIModel
//    var body: some View { /* ... Implementation above ... */
//        List {
//            Section { // Prominent Icon/ID Section
//                VStack(spacing: 15) {
//                    Image(systemName: model.iconName).resizable().scaledToFit()
//                        .padding(15).frame(width: 80, height: 80)
//                        .background(model.iconBackgroundColor).foregroundStyle(.white)
//                        .clipShape(Circle())
//                        .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
//                    Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
//                }
//                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
//            }.listRowBackground(Color.clear)
//
//            Section("Overview") {
//                DetailRow(label: "Full ID", value: model.id)
//                DetailRow(label: "Type", value: model.object)
//                DetailRow(label: "Owner", value: model.ownedBy)
//                DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
//            }
//
//            Section("Details") {
//                 VStack(alignment: .leading, spacing: 5) {
//                     Text("Description").font(.caption).foregroundColor(.secondary)
//                     Text(model.description)
//                 }.accessibilityElement(children: .combine)
//                 VStack(alignment: .leading, spacing: 5) {
//                     Text("Context Window").font(.caption).foregroundColor(.secondary)
//                     Text(model.contextWindow)
//                 }.accessibilityElement(children: .combine)
//            }
//
//            if !model.capabilities.isEmpty && model.capabilities != ["general"] {
//                Section("Capabilities") {
//                    WrappingHStack(items: model.capabilities) { capability in
//                        Text(capability)
//                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
//                            .background(Color.accentColor.opacity(0.2))
//                            .foregroundColor(.accentColor).clipShape(Capsule())
//                    }
//                }
//            }
//
//            if !model.typicalUseCases.isEmpty && model.typicalUseCases != ["Various tasks"] {
//                 Section("Typical Use Cases") {
//                     ForEach(model.typicalUseCases, id: \.self) { useCase in
//                         Label(useCase, systemImage: "play.rectangle")
//                             .foregroundColor(.primary).imageScale(.small)
//                     }
//                 }
//            }
//        }
//        .listStyle(.insetGrouped)
//        .navigationTitle("Model Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//    private func DetailRow(label: String, value: String) -> some View { /* ... Implementation above ... */
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//            Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
//        }
//         .padding(.vertical, 2)
//         .accessibilityElement(children: .combine)
//    }
//}
//
//// MARK: - NEW: Specialized View for O4-Mini
//
//struct O4MiniDetailView: View {
//    let model: OpenAIModel // Expects the *detailed* o4-mini model data
//
//    // Grid columns for endpoints/features
//    let gridColumns: [GridItem] = [
//        GridItem(.flexible(), spacing: 15),
//        GridItem(.flexible(), spacing: 15)
//    ]
//
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 30) {
//                // --- Header Section ---
//                o4MiniHeader
//
//                // --- Performance Gauges ---
//                if let performance = model.performance {
//                    o4MiniPerformanceGauges(performance: performance)
//                }
//
//                // --- Overview Text ---
//                o4MiniOverview
//
//                // --- Key Specs ---
//                if let specs = model.specs {
//                   o4MiniKeySpecs(specs: specs)
//                }
//
//                Divider()
//
//                // --- Pricing Section ---
//                if let pricing = model.pricing {
//                    o4MiniPricing(pricing: pricing)
//                }
//
//                // --- Quick Comparison Placeholder ---
//                // o4MiniQuickComparison() // Requires more complex UI
//
//                Divider()
//
//                // --- Modalities ---
//                if let modalities = model.modalities {
//                    o4MiniModalities(modalities: modalities)
//                }
//
//                Divider()
//
//                // --- Endpoints ---
//                if let endpoints = model.endpoints {
//                   o4MiniCapabilitiesSection(title: "Endpoints", items: endpoints)
//                }
//
//                Divider()
//
//                // --- Features ---
//                if let features = model.features {
//                   o4MiniCapabilitiesSection(title: "Features", items: features)
//                }
//
//                Divider()
//
//                // --- Snapshots ---
//                if let snapshots = model.snapshots {
//                    o4MiniSnapshots(snapshots: snapshots)
//                }
//
//                Divider()
//
//                // --- Rate Limits ---
//                if let rateLimits = model.rateLimits {
//                    o4MiniRateLimits(rateLimits: rateLimits)
//                }
//
//                Spacer(minLength: 40) // Bottom padding
//            }
//            .padding() // Overall padding for the VStack content
//        }
//        .navigationTitle(model.displayName) // Set title for the detailed view
//        .navigationBarTitleDisplayMode(.inline)
//        .background(Color(.systemGroupedBackground)) // Match list background
//        .edgesIgnoringSafeArea(.bottom)
//    }
//
//    // --- Subview Builders for O4MiniDetailView ---
//
//    private var o4MiniHeader: some View {
//        HStack(alignment: .center, spacing: 15) {
//            Image(systemName: model.iconName)
//                .resizable().scaledToFit().padding(8)
//                .frame(width: 50, height: 50)
//                .background(model.iconBackgroundColor.opacity(0.85))
//                .foregroundStyle(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//
//            VStack(alignment: .leading, spacing: 3) {
//                Text(model.displayName)
//                    .font(.title2.weight(.bold))
//                if let tagline = model.tagline {
//                    Text(tagline)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//            }
//            Spacer()
//            // Placeholder buttons
//            Button {} label: { Text("Compare").font(.callout) }.buttonStyle(.bordered).controlSize(.small)
//            Button {} label: { Text("Try in Playground").font(.callout) }.buttonStyle(.borderedProminent).controlSize(.small)
//
//        }
//        .padding(.bottom, 10) // Space after header
//    }
//
//    private func o4MiniPerformanceGauges(performance: PerformanceMetrics) -> some View {
//        HStack(alignment: .top, spacing: 10) {
//            GaugeItem(icon: "brain.head.profile", label: "Reasoning", value: performance.reasoning ?? "N/A", level: .high)
//            GaugeItem(icon: "speedometer", label: "Speed", value: performance.speed ?? "N/A", level: .medium)
//            GaugeItem(icon: "dollarsign.circle", label: "Price", value: performance.priceRange ?? "N/A", level: .value)
//            GaugeItem(icon: "text.bubble.fill", label: "Input", value: performance.inputTypes?.joined(separator: ", ") ?? "N/A", level: .value)
//            GaugeItem(icon: "text.bubble", label: "Output", value: performance.outputTypes?.joined(separator: ", ") ?? "N/A", level: .value)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical)
//        // .background(.secondarySystemBackground)
//         .clipShape(RoundedRectangle(cornerRadius: 10))
//    }
//
//    private var o4MiniOverview: some View {
//        VStack(alignment: .leading) {
//             // Basic text rendering, could add markdown support later
//             Text( SanitizeMarkdown(model.description))
//                .font(.callout)
//                .lineSpacing(4)
//        }
//    }
//
//    private func o4MiniKeySpecs(specs: KeySpecs) -> some View {
//        VStack(alignment: .leading, spacing: 12) {
//            SpecItem(icon: "arrow.up.left.and.arrow.down.right.circle.fill", label: specs.contextWindowTokens?.formattedOrZero() ?? "N/A", unit: "context window")
//            SpecItem(icon: "arrow.right.to.line.circle.fill", label: specs.maxOutputTokens?.formattedOrZero() ?? "N/A", unit: "max output tokens")
//            SpecItem(icon: "calendar.badge.clock", label: specs.knowledgeCutoff ?? "N/A", unit: "Knowledge cutoff")
//            SpecItem(icon: "puzzlepiece.extension.fill", label: specs.reasoningTokenSupport == true ? "Supported" : "N/A", unit: "Reasoning token support")
//        }
//        .padding(.vertical)
//    }
//
//    private func o4MiniPricing(pricing: PricingInfo) -> some View {
//        VStack(alignment: .leading, spacing: 15) {
//            Text("Pricing")
//                .font(.title3.weight(.semibold))
//            Text("Pricing is based on the number of tokens used. For tool-specific models, like search and computer use, there's a fee per tool call. See details in the [pricing page](link-placeholder).")
//                .font(.caption)
//                .foregroundColor(.secondary)
//
//            HStack(alignment: .top, spacing: 10) {
//                PricingBox(label: "Input", value: pricing.inputPerMillionTokens, unit: pricing.unit)
//                PricingBox(label: "Cached input", value: pricing.cachedInputPerMillionTokens, unit: pricing.unit)
//                PricingBox(label: "Output", value: pricing.outputPerMillionTokens, unit: pricing.unit)
//            }
//            .frame(maxWidth: .infinity)
//             .padding(.top, 5)
//
//            // Quick Comparison Placeholder (Text-based)
//             VStack(alignment: .leading) {
//                 Text("Quick comparison").font(.caption).foregroundStyle(.secondary)
//                 Text("o3: $10.00") // Example from screenshot
//                 Text("o4-mini: $1.10")
//                 Text("o3-mini: $1.10")
//             }.font(.caption).padding(.top, 5)
//
//        }
//    }
//
//    private func o4MiniModalities(modalities: [ModalityInfo]) -> some View {
//         VStack(alignment: .leading, spacing: 15) {
//            Text("Modalities")
//                 .font(.title3).fontWeight(.semibold)
//             ForEach(modalities) { modality in
//                 HStack {
//                     Image(systemName: modality.icon)
//                         .frame(width: 25, alignment: .center)
//                             .foregroundColor(modality.support == "Not supported" ? .secondary : .accentColor)
//                     VStack(alignment: .leading) {
//                         Text(modality.name).font(.subheadline)
//                         Text(modality.support)
//                             .font(.caption)
//                             .foregroundColor(modality.support == "Not supported" ? .secondary : .primary)
//                     }
//                     Spacer()
//                 }
//             }
//         }
//    }
//
//    // Generic section for Endpoints and Features using a grid
//    @ViewBuilder
//    private func o4MiniCapabilitiesSection<T: Identifiable & Hashable>(title: String, items: [T]) -> some View {
//        // Type check to extract relevant data - uses generics for flexibility
//        if let endpointItems = items as? [EndpointInfo] {
//             o4MiniCapabilityGridView(title: title, items: endpointItems) { item in
//                 CapabilityCard(icon: item.icon, name: item.name, supported: item.supported, detail: item.path)
//             }
//        } else if let featureItems = items as? [FeatureInfo] {
//            o4MiniCapabilityGridView(title: title, items: featureItems) { item in
//                CapabilityCard(icon: item.icon, name: item.name, supported: item.supported, detail: nil)
//            }
//        } else {
//            EmptyView() // Handle cases where type doesn't match
//        }
//    }
//
//    // Helper Grid View for Capabilities
//    private func o4MiniCapabilityGridView<Item: Identifiable & Hashable, CardView: View>(
//        title: String,
//        items: [Item],
//        @ViewBuilder cardForItem: @escaping (Item) -> CardView
//    ) -> some View {
//        VStack(alignment: .leading, spacing: 15) {
//            Text(title)
//                .font(.title3.weight(.semibold))
//            LazyVGrid(columns: gridColumns, spacing: 15) {
//                 ForEach(items) { item in
//                     cardForItem(item)
//                 }
//            }
//        }
//    }
//
//    private func o4MiniSnapshots(snapshots: [SnapshotInfo]) -> some View {
//        VStack(alignment: .leading, spacing: 15) {
//            Text("Snapshots")
//                .font(.title3.weight(.semibold))
//            Text("Snapshots let you lock in a specific version of the model so that performance and behavior remain consistent. Below is a list of all available snapshots and aliases for o4-mini.")
//                .font(.caption)
//                .foregroundColor(.secondary)
//
//            ForEach(snapshots) { snapshot in
//                 HStack {
//                     Image(systemName: snapshot.icon)
//                         .frame(width: 25, alignment: .center)
//                         .foregroundColor(.accentColor)
//                     VStack(alignment: .leading) {
//                         Text(snapshot.name).font(.subheadline.monospaced()) // Monospaced for IDs
//                         Text(snapshot.type).font(.caption).foregroundColor(.secondary)
//                     }
//                 }
//            }
//        }
//    }
//
//    private func o4MiniRateLimits(rateLimits: [RateLimitTier]) -> some View {
//        VStack(alignment: .leading, spacing: 15) {
//            Text("Rate limits")
//                .font(.title3.weight(.semibold))
//            Text("Rate limits ensure fair and reliable access to the API by placing specific caps on requests or tokens used within a given time period. Your usage tier determines how high these limits are set and automatically increases as you spend more on the API.")
//                .font(.caption)
//                .foregroundColor(.secondary)
//
//            // --- Rate Limit Table using Grid ---
//            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
//                 // --- Header Row ---
//                 GridRow {
//                     Text("Tier").font(.caption.weight(.semibold)).gridColumnAlignment(.leading)
//                     Text("RPM").font(.caption.weight(.semibold)).gridColumnAlignment(.trailing)
//                     Text("TPM").font(.caption.weight(.semibold)).gridColumnAlignment(.trailing)
//                     Text("Batch Queue").font(.caption.weight(.semibold)).gridColumnAlignment(.trailing)
//                 }
//                 .foregroundColor(.secondary)
//                 Divider().gridCellUnsizedAxes(.horizontal) // Full width divider
//
//                 // --- Data Rows ---
//                 ForEach(rateLimits) { tier in
//                     GridRow {
//                         Text(tier.tierName).font(.caption)
//                         Text(tier.rpm ?? "-").font(.caption.monospacedDigit()).gridColumnAlignment(.trailing)
//                         Text(tier.tpm ?? "-").font(.caption.monospacedDigit()).gridColumnAlignment(.trailing)
//                         Text(tier.batchQueueLimit ?? "-").font(.caption.monospacedDigit()).gridColumnAlignment(.trailing)
//                     }
//                     if tier.id != rateLimits.last?.id { // Don't draw divider after last row
//                           Divider().gridCellUnsizedAxes(.horizontal)
//                     }
//                 }
//            }
//            .padding(.vertical, 10)
//            .padding(.horizontal)
//            .background(.secondary)
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//        }
//    }
//
//    // --- Helper Subviews specific to O4MiniDetailView ---
//
//    // Helper for Performance Gauges
//    struct GaugeItem: View {
//        let icon: String
//        let label: String
//        let value: String
//        let level: GaugeLevel // Enum to define level (e.g., low, medium, high, or just value)
//
//        enum GaugeLevel { case low, medium, high, value }
//
//        var body: some View {
//            VStack(spacing: 4) {
//                Image(systemName: icon).foregroundColor(.secondary)
//                Text(label).font(.caption).foregroundColor(.secondary)
//                // Simple text for now, could be replaced with actual gauge UI
//                Text(value).font(.footnote.weight(.medium)).lineLimit(1)
//            }
//            .frame(maxWidth: .infinity) // Distribute equally
//        }
//    }
//
//    // Helper for Key Specs
//    struct SpecItem: View {
//        let icon: String
//        let label: String
//        let unit: String
//
//        var body: some View {
//            HStack(spacing: 8) {
//                Image(systemName: icon)
//                    .frame(width: 25, alignment: .center)
//                    .foregroundColor(.accentColor)
//                Text(label).font(.subheadline.weight(.medium))
//                 Text(unit).font(.subheadline).foregroundColor(.secondary)
//                Spacer()
//            }
//        }
//    }
//
//    // Helper for Pricing Boxes
//    struct PricingBox: View {
//        let label: String
//        let value: Double?
//        let unit: String
//
//        var body: some View {
//            VStack(alignment: .leading, spacing: 3) {
//                Text(label).font(.caption).foregroundColor(.secondary)
//                if let value = value {
//                    Text("$\(value, specifier: "%.3f")") // Format to 3 decimal places like screenshot
//                        .font(.title3.weight(.semibold).monospacedDigit())
//                } else {
//                    Text("N/A").font(.title3.weight(.semibold))
//                }
//                Text(unit).font(.caption2).foregroundColor(.secondary)
//            }
//            .padding()
//            .frame(maxWidth: .infinity) // Distribute equally
//            .background(.tertiary) // Slightly different bg
//             .clipShape(RoundedRectangle(cornerRadius: 8))
//        }
//    }
//
//    // Helper card for Endpoints/Features Grid
//    struct CapabilityCard: View {
//        let icon: String
//        let name: String
//        let supported: Bool
//        let detail: String? // Optional detail like endpoint path
//
//        var body: some View {
//            HStack(spacing: 8) {
//                 Image(systemName: icon)
//                     .foregroundColor(supported ? .green : .secondary)
//                     .frame(width: 20, alignment: .center)
//                VStack(alignment: .leading, spacing: 2) {
//                    Text(name).font(.caption.weight(.medium))
//                    if let detail = detail {
//                        Text(detail).font(.caption2).foregroundColor(.secondary).lineLimit(1)
//                    } else {
//                        // Show supported status if no detail
//                         Text(supported ? "Supported" : "Not supported").font(.caption2).foregroundColor(.secondary)
//                    }
//                }
//                 Spacer(minLength: 0)
//            }
//            .padding(10)
//            .background(.regularMaterial)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//             .overlay(
//                 RoundedRectangle(cornerRadius: 8)
//                     .stroke( supported ? Color.green.opacity(0.5) : Color.gray.opacity(0.15), lineWidth: 1)
//             )
//        }
//    }
//}
//
//// --- Helper for Markdown Removal (Basic) ---
//func SanitizeMarkdown(_ text: String) -> String {
//    // Very basic removal of markdown links like [text](url) -> text
//    return text.replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^\\)]+\\)", with: "$1", options: .regularExpression)
//}
//
//// --- Helper for formatting numbers ---
//extension Int {
//    func formattedOrZero() -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        formatter.groupingSeparator = ","
//        return formatter.string(from: NSNumber(value: self)) ?? "0"
//    }
//}
//
//// MARK: - Main Content View (Modified for Navigation)
//
//struct OpenAIModelsMasterView: View {
//    // --- State Variables (Unchanged) ---
//    @State private var allModels: [OpenAIModel] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String? = nil
//    @State private var useMockData = true // Default to Mock
//    @State private var showingApiKeySheet = false
//    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""
//
//    // --- API Service Instance (Unchanged) ---
//    private var currentApiService: APIServiceProtocol {
//        useMockData ? MockAPIService() : LiveAPIService()
//    }
//
//    // --- Grid Layout (Unchanged) ---
//    let gridColumns: [GridItem] = [
//        GridItem(.flexible(), spacing: 15),
//        GridItem(.flexible(), spacing: 15)
//    ]
//
//    // --- Filters for Sections (Adjusted to use the expanded model) ---
//    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "o4-mini", "o3"].contains($0.id) }.sortedById() }
//    // Adapt other filters if needed, but they might not have detailed data unless mocked
//    var reasoningModels: [OpenAIModel] { allModels.filter { $0.id.starts(with: "o") }.sortedById() } // Simpler filter
//    var flagshipChatModels: [OpenAIModel] { allModels.filter { $0.id.contains("gpt-4") }.sortedById() } // Simpler filter
//    // ... other filters can remain simple or be expanded ...
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
//                            // --- Header ---
//                             VStack(alignment: .leading, spacing: 5) {
//                                 Text("Models").font(.largeTitle.weight(.bold))
//                                 Text("Explore available models.").font(.title3).foregroundColor(.secondary)
//                             }.padding(.horizontal)
//                             Divider().padding(.horizontal)
//
//                             // --- Featured Section (Horizontal Scroll) ---
//                             SectionHeader(title: "Featured models", subtitle: nil)
//                             ScrollView(.horizontal, showsIndicators: false) {
//                                 HStack(spacing: 15) {
//                                     ForEach(featuredModels) { model in
//                                         NavigationLink(value: model) { // Use model for navigation value
//                                             FeaturedModelCard(model: model).frame(width: 250)
//                                         } .buttonStyle(.plain)
//                                     }
//                                 }.padding(.horizontal).padding(.bottom, 5)
//                             }
//
//                             // --- Standard Sections Grid (Example) ---
//                            displaySection(title: "Reasoning models", subtitle: nil, models: reasoningModels)
//                            displaySection(title: "Flagship chat models", subtitle: nil, models: flagshipChatModels)
//                            // ... add back other sections as needed ...
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
//            .toolbar { /* ... Toolbar Items (Unchanged) ... */
//                 ToolbarItem(placement: .navigationBarLeading) {
//                     if isLoading { ProgressView().controlSize(.small) }
//                     else { Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(isLoading) }
//                 }
//                 ToolbarItem(placement: .navigationBarTrailing) {
//                     Menu {
//                         Toggle(isOn: $useMockData) { Text(useMockData ? "Using Mock Data" : "Using Live API") }
//                     } label: {
//                         Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill")
//                             .foregroundColor(useMockData ? .secondary : .blue)
//                     }.disabled(isLoading)
//                 }
//             }
//             // --- **** MODIFIED NAVIGATION DESTINATION **** ---
//             .navigationDestination(for: OpenAIModel.self) { model in
//                 // Route to specific view for o4-mini, generic for others
//                 if model.id == "o4-mini" {
//                     O4MiniDetailView(model: model) // Use the new detailed view
//                         .toolbarBackground(.visible, for: .navigationBar)
//                         .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
//                 } else {
//                     ModelDetailView(model: model) // Use the existing generic view
//                         .toolbarBackground(.visible, for: .navigationBar)
//                         .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
//                 }
//             }
//             .task { if allModels.isEmpty { attemptLoadModels() } }
//             .refreshable { await loadModelsAsync(checkApiKey: false) }
//             .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
//             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
//             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: {
//                 Button("OK") { errorMessage = nil }
//             }, message: { Text(errorMessage ?? "An unknown error occurred.") })
//
//        } // End NavigationStack
//    }
//
//    // --- Helper View Builder for Sections (Unchanged) --
//    @ViewBuilder
//    private func displaySection(title: String, subtitle: String?, models: [OpenAIModel]) -> some View {
//         if !models.isEmpty {
//             Divider().padding(.horizontal)
//             SectionHeader(title: title, subtitle: subtitle)
//             LazyVGrid(columns: gridColumns, spacing: 15) {
//                 ForEach(models) { model in
//                     NavigationLink(value: model) { // Use model for value
//                         StandardModelRow(model: model)
//                     }.buttonStyle(.plain)
//                 }
//             }.padding(.horizontal)
//         } else { EmptyView() }
//    }
//
//    // --- Helper Functions for Loading & API Key Handling (Unchanged) ---
//    private func handleToggleChange(to newValue: Bool) { /* ... Implementation Above ...*/
//         print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
//         allModels = []; errorMessage = nil
//         if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//             showingApiKeySheet = true
//         } else { loadModelsAsyncWithLoadingState() }
//    }
//    private func presentApiKeySheet() -> some View { /* ... Implementation Above ...*/
//         APIKeyInputView( onSave: { _ in print("API Key saved."); loadModelsAsyncWithLoadingState() },
//             onCancel: { print("API Key input cancelled."); useMockData = true } )
//    }
//    private func attemptLoadModels() { /* ... Implementation Above ...*/
//         guard !isLoading else { return }
//         if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//             showingApiKeySheet = true
//         } else { loadModelsAsyncWithLoadingState() }
//     }
//    private func loadModelsAsyncWithLoadingState() { /* ... Implementation Above ...*/
//         guard !isLoading else { return }
//         isLoading = true; Task { await loadModelsAsync(checkApiKey: false) }
//    }
//    @MainActor private func loadModelsAsync(checkApiKey: Bool) async { /* ... Implementation Above ...*/
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
//             self.errorMessage = error.localizedDescription
//             if allModels.isEmpty { self.allModels = [] }
//         } catch {
//             print("❌ Unexpected error loading models: \(error)")
//             self.errorMessage = "Unexpected error: \(error.localizedDescription)"
//             if allModels.isEmpty { self.allModels = [] }
//         }
//         isLoading = false
//    }
//}
//
//// MARK: - Helper Extensions (Included existing)
//
//extension Array where Element == OpenAIModel {
//    func sortedById() -> [OpenAIModel] {
//        self.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
//    }
//}
//
//// MARK: - Previews (Include new previews for O4Mini Detail)
//
//#Preview("Main View (Mock Data)") { OpenAIModelsMasterView() }
//
//#Preview("Generic Detail View") {
//    let model = OpenAIModel(id: "gpt-4.1", object: "model", created: 1, ownedBy: "openai")
//    NavigationStack { ModelDetailView(model: model) }
//}
//
////#Preview("O4-Mini Detail View") {
////     // Create a detailed o4-mini model instance directly for preview
////     let o4MiniPreviewModel = MockAPIService().generateMockModels().first { $0.id == "o4-mini" }!
////     NavigationStack {
////         // Use a conditional check just like in the main view's navigation to be safe
////         if o4MiniPreviewModel.id == "o4-mini" {
////             O4MiniDetailView(model: o4MiniPreviewModel)
////         } else {
////             Text("Error: Could not load o4-mini preview data.")
////         }
////     }
////}
//
//#Preview("API Key Input Sheet") {
//    struct SheetPresenter: View { @State var showSheet = true; var body: some View { Text("").sheet(isPresented: $showSheet) { APIKeyInputView(onSave: {_ in}, onCancel: {}) } } }
//    return SheetPresenter()
//}
