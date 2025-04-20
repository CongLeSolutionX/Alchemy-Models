////
////  OpenAIModelsMasterView_o3_detail.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  OpenAIModelsMasterView_o3_Integrated.swift
////  Alchemy_Models_Combined
////  (Single File Implementation - Integrated o3 Details)
////
////  Created: Cong Le
////  Date: 4/13/25 (Based on previous iterations + o3 integration)
////  Version: 1.2 (Synthesized & Adapted to o3 Screenshots)
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
//// ---- START: New Data Structures for Detailed Model Info ----
//
//struct PricingInfo: Codable, Hashable {
//    var inputPerMToken: Double?
//    var cachedInputPerMToken: Double?
//    var outputPerMToken: Double?
//    var notes: String? = "Pricing is based on the number of tokens used. Tool-specific models may have separate fees." // Default note
//}
//
//struct EndpointInfo: Codable, Hashable, Identifiable {
//    var id: String { path } // Conform to Identifiable using path
//    var path: String
//    var supported: Bool
//    var details: [String: Bool]? // e.g., ["realtime": false, "batch": false]
//}
//
//struct FeatureInfo: Codable, Hashable, Identifiable {
//    var id: String { name } // Conform to Identifiable using name
//    var name: String
//    var supported: Bool
//}
//
//struct RateLimitTier: Codable, Hashable, Identifiable {
//    var id: String { name } // Conform to Identifiable using name
//    var name: String // "Free", "Tier 1", etc.
//    var rpm: Int?
//    var rpd: String? // Can be Int or "Not supported"
//    var tpm: Int?
//    var batchQueueLimit: Int?
//}
//
//struct RateLimitInfo: Codable, Hashable {
//    var tiers: [RateLimitTier]?
//}
//
//struct SnapshotInfo: Codable, Hashable, Identifiable {
//    var id: String { alias + (version ?? "") } // Conform to Identifiable
//    var alias: String // "o3"
//    var version: String? // "o3-2025-04-16"
//    var date: Date? // Optional: if we parse the version string
//}
//
//// ---- END: New Data Structures ----
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
//// Updated OpenAIModel to include new detailed fields
//struct OpenAIModel: Codable, Identifiable, Hashable {
//    let id: String
//    let object: String
//    let created: Int // Unix timestamp
//    let ownedBy: String
//
//    // --- Basic Info ---
//    var description: String = "No description available."
//    var shortDescription: String = "General purpose model." // Based on previous implementation
//
//    // --- Screenshot Derived Data ---
//    var isDefault: Bool?                     // New: From "Default" tag
//    var reasoningRating: Int?                // New: 1-5 dots
//    var speedRating: Int?                    // New: 1-5 lightning bolts (map visually)
//    var inputModalities: [String]?           // New: e.g., ["text", "image"]
//    var outputModalities: [String]?          // New: e.g., ["text"]
//    var capabilities: [String] = ["general"] // Existing, can be populated more richly
//    var contextWindowTokens: Int?            // New: From screenshot (e.g., 200000)
//    var maxOutputTokens: Int?                // New: From screenshot (e.g., 100000)
//    var knowledgeCutoff: String?             // New: e.g., "May 31, 2024"
//    var supportsReasoningTokens: Bool?       // New: Based on label
//    var pricing: PricingInfo?                // New: Nested struct for pricing details
//    var endpoints: [EndpointInfo]?           // New: Nested struct array for API endpoints
//    var features: [FeatureInfo]?             // New: Nested struct array for supported features
//    var rateLimits: RateLimitInfo?           // New: Nested struct for rate limits
//    var snapshots: [SnapshotInfo]?           // New: Nested struct array for model versions
//    // Optional fields for easier handling in Views
//    var quickComparePriceInput: Double?      // For the bar chart like comparison
//    var reasoningGuideUrl: URL?              // Link from the description
//
//    // --- Codable Conformance ---
//    enum CodingKeys: String, CodingKey {
//        case id
//        case object
//        case created
//        case ownedBy = "owned_by"
//        // IMPORTANT: Most new detailed fields (ratings, pricing, endpoints, etc.)
//        // are NOT listed here. They will rely on default values (nil/empty)
//        // unless explicitly provided by the *mock data*. The live /v1/models
//        // endpoint likely won't return these details.
//        case description // Keep ones potentially in live API
//        case capabilities
//        // `shortDescription` relies on default or logic in LiveAPIService
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
//    // (Keep existing logic, can be refined with new model IDs)
//    var iconName: String {
//        let normalizedId = id.lowercased()
//        if normalizedId.contains("o3") { return "brain.head.profile" } // Specific icon for o3
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") || normalizedId.contains("chatgpt-4o") { return "sparkles" }
//        if normalizedId.contains("o4-mini") || normalizedId.contains("o3-mini") || normalizedId.contains("o1-mini") || normalizedId.contains("gpt-4.1-mini") { return "leaf.fill" }
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
//        let lowerOwner = ownedBy.lowercased()
//        if lowerOwner.contains("openai") { return "building.columns.fill" }
//        if lowerOwner == "system" { return "gearshape.fill" }
//        if lowerOwner.contains("user") || lowerOwner.contains("org") { return "person.crop.circle.fill" }
//        return "questionmark.circle.fill"
//    }
//
//    // --- Determine background color for icons ---
//    // (Keep existing logic, can be refined)
//    var iconBackgroundColor: Color {
//        let normalizedId = id.lowercased()
//        if normalizedId.contains("o3") { return .orange } // Specific color for o3
//        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") { return .blue }
//        if normalizedId.contains("o4-mini") { return .purple }
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
//    // --- Simplified name for display ---
//      var displayName: String { id.replacingOccurrences(of: "-", with: " ").capitalized }
//}
//
//// MARK: - API Service Implementations
//
//// --- Mock Data Service ---
//class MockAPIService: APIServiceProtocol {
//    private let mockNetworkDelaySeconds: Double = 0.5
//
//    // Generate detailed o3 model
//    private func createO3Model() -> OpenAIModel {
//        return OpenAIModel(
//            id: "o3",
//            object: "model",
//            created: 1700000000, // Approx timestamp
//            ownedBy: "openai",
//            description: "o3 is a well-rounded and powerful model across domains. It sets a new standard for math, science, coding, and visual reasoning tasks. It also excels at technical writing and instruction-following. Use it to think through multi-step problems that involve analysis across text, code, and images.",
//            shortDescription: "Our most powerful reasoning model",
//            isDefault: true,
//            reasoningRating: 5, // 5 dots = highest
//            speedRating: 1,     // 1 lightning bolt = slowest
//            inputModalities: ["text", "image"],
//            outputModalities: ["text"],
//            capabilities: ["math", "science", "coding", "visual reasoning", "technical writing", "instruction-following", "multi-step problem solving", "image analysis", "text analysis", "code analysis"],
//            contextWindowTokens: 200_000,
//            maxOutputTokens: 100_000,
//            knowledgeCutoff: "May 31, 2024",
//            supportsReasoningTokens: true,
//            pricing: PricingInfo(
//                inputPerMToken: 10.00,
//                cachedInputPerMToken: 2.50,
//                outputPerMToken: 40.00 // Added output price
//            ),
//            endpoints: [
//                EndpointInfo(path: "/v1/chat/completions", supported: true, details: [
//                    "Realtime": false, "Batch": false, "Embeddings": false,
//                    "Speech generation": false, "Translation": false, "Completions (legacy)": false
//                ]),
//                EndpointInfo(path: "/v1/responses", supported: true, details: [
//                    "Assistants": false, "Fine-tuning": false, "Image generation": false,
//                    "Transcription": false, "Moderation": false
//                ])
//            ],
//            features: [
//                FeatureInfo(name: "Streaming", supported: true),
//                FeatureInfo(name: "Structured outputs", supported: true),
//                FeatureInfo(name: "Function calling", supported: true),
//                FeatureInfo(name: "Fine-tuning", supported: false),
//                FeatureInfo(name: "Distillation", supported: false),
//                FeatureInfo(name: "Predicted outputs", supported: false)
//            ],
//            rateLimits: RateLimitInfo(tiers: [
//                RateLimitTier(name: "Free", rpd: "Not supported"),
//                RateLimitTier(name: "Tier 1", rpm: 500, tpm: 30_000, batchQueueLimit: 90_000),
//                RateLimitTier(name: "Tier 2", rpm: 5_000, tpm: 450_000, batchQueueLimit: 1_350_000),
//                RateLimitTier(name: "Tier 3", rpm: 5_000, tpm: 800_000, batchQueueLimit: 50_000_000), // Corrected TPM based on image
//                RateLimitTier(name: "Tier 4", rpm: 10_000, tpm: 2_000_000, batchQueueLimit: 200_000_000),
//                RateLimitTier(name: "Tier 5", rpm: 10_000, tpm: 30_000_000, batchQueueLimit: 5_000_000_000) // Huge batch limit
//            ]),
//            snapshots: [
//                SnapshotInfo(alias: "o3"),
//                SnapshotInfo(alias: "o3", version: "o3-2025-04-16") // No date parsing logic for now
//            ],
//            quickComparePriceInput: 10.00, // For the bar chart comparison
//            reasoningGuideUrl: URL(string: "https://platform.openai.com/docs/guides/reasoning") // Example URL
//        )
//    }
//
//    // Enhanced mock models including o3
//    private func generateMockModels() -> [OpenAIModel] {
//         // Combine the detailed o3 model with others from the previous implementation
//         return [
//            createO3Model(), // Add the detailed o3 model
//
//            // Add other models (copied & slightly adapted from previous code)
//            OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", shortDescription: "Flagship GPT model for complex tasks"),
//            OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", shortDescription: "Faster, more affordable reasoning model", quickComparePriceInput: 1.10), // Added price for comparison
//            OpenAIModel(id: "o3-mini", object: "model", created: 1699000000, ownedBy: "openai", shortDescription: "A small model alternative to o3"),
//            OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", shortDescription: "Previous full o-series reasoning model", quickComparePriceInput: 15.00), // Added price for comparison
//            OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", shortDescription: "Fast, intelligent, flexible GPT model", inputModalities: ["text", "image", "audio"], outputModalities: ["text", "audio"]),
//            OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", shortDescription: "Our latest image generation model", inputModalities: ["text"], outputModalities: ["image"])
//            // ... add more simplified models as needed
//        ]
//    }
//
//    func fetchModels() async throws -> [OpenAIModel] {
//         try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
//         return generateMockModels()
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
//                 print("✅ Successfully decoded \(responseWrapper.data.count) live models.")
//                 // IMPORTANT: Live API likely won't return detailed fields.
//                 // The default values (nil/empty arrays) in OpenAIModel will be used.
//                 // We only map the basic fields provided by the API.
//                return responseWrapper.data.map { model in
//                    var mutableModel = model
//                    // Existing logic to create a default shortDescription if missing
//                    if mutableModel.shortDescription == "General purpose model." { // Check default value
//                        mutableModel.shortDescription = model.ownedBy.contains("openai") ? "OpenAI base model." : "User or system model."
//                    }
//                    // COULD add logic here to populate *some* details if the ID matches 'o3',
//                    // but this is brittle. Mock data is better for showing detailed views.
//                    return mutableModel
//                }
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
//// MARK: - Reusable SwiftUI Helper Views (Unchanged except Detail View modifications)
//
//// --- ErrorView (unchanged) ---
//struct ErrorView: View {
//    let errorMessage: String
//    let retryAction: () -> Void
//    var body: some View {
//        VStack(alignment: .center, spacing: 15) {
//            Image(systemName: "wifi.exclamationmark").resizable().scaledToFit().frame(width: 60, height: 60).foregroundColor(.red)
//            VStack(spacing: 5) { Text("Loading Failed").font(.title3.weight(.medium)); Text(errorMessage).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal) }
//            Button { retryAction() } label: { Label("Retry", systemImage: "arrow.clockwise") }.buttonStyle(.borderedProminent).controlSize(.regular).padding(.top)
//        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding().background(Color(.systemGroupedBackground))
//    }
//}
//
//// --- WrappingHStack (unchanged) ---
//struct WrappingHStack<Item: Hashable, ItemView: View>: View {
//    let items: [Item]
//    let viewForItem: (Item) -> ItemView
//    let horizontalSpacing: CGFloat = 8; let verticalSpacing: CGFloat = 8
//    @State private var totalHeight: CGFloat = .zero
//    var body: some View { VStack { GeometryReader { geometry in self.generateContent(in: geometry) } }.frame(height: totalHeight) }
//    private func generateContent(in g: GeometryProxy) -> some View { var width = CGFloat.zero; var height = CGFloat.zero; return ZStack(alignment: .topLeading) { ForEach(self.items, id: \.self) { item in self.viewForItem(item).padding(.horizontal, horizontalSpacing / 2).padding(.vertical, verticalSpacing / 2).alignmentGuide(.leading, computeValue: { d in if (abs(width - d.width) > g.size.width) { width = 0; height -= d.height + verticalSpacing }; let result = width; if item == self.items.last { width = 0 } else { width -= d.width }; return result }).alignmentGuide(.top, computeValue: { d in let result = height; if item == self.items.last { height = 0 }; return result }) } }.background(viewHeightReader($totalHeight)) }
//    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View { GeometryReader { geometry -> Color in let rect = geometry.frame(in: .local); DispatchQueue.main.async { binding.wrappedValue = rect.size.height }; return .clear } }
//}
//
//// --- APIKeyInputView (unchanged) ---
//struct APIKeyInputView: View {
//    @Environment(\.dismiss) var dismiss
//    @AppStorage("userOpenAIKey") private var apiKey: String = ""
//    @State private var inputApiKey: String = ""
//    @State private var isInvalidKeyAttempt: Bool = false
//    var onSave: (String) -> Void; var onCancel: () -> Void
//    var body: some View { NavigationView { VStack(alignment: .leading, spacing: 20) { Text("Enter your OpenAI API Key").font(.headline); Text("Your key will be stored securely in UserDefaults...").font(.caption).foregroundColor(.secondary); SecureField("sk-...", text: $inputApiKey).textFieldStyle(RoundedBorderTextFieldStyle()).overlay(RoundedRectangle(cornerRadius: 5).stroke(isInvalidKeyAttempt ? Color.red : Color.clear, lineWidth: 1)).onChange(of: inputApiKey) { _, _ in isInvalidKeyAttempt = false }; if isInvalidKeyAttempt { Text("API Key cannot be empty.").font(.caption).foregroundColor(.red) }; HStack { Button("Cancel") { onCancel(); dismiss() }.buttonStyle(.bordered); Spacer(); Button("Save Key") { let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines); if trimmedKey.isEmpty { isInvalidKeyAttempt = true } else { apiKey = trimmedKey; onSave(apiKey); dismiss() } }.buttonStyle(.borderedProminent) }.padding(.top); Spacer() }.padding().navigationTitle("API Key").navigationBarTitleDisplayMode(.inline).onAppear { inputApiKey = apiKey; isInvalidKeyAttempt = false } } }
//}
//
//// --- FeaturedModelCard (unchanged) ---
//struct FeaturedModelCard: View {
//    let model: OpenAIModel
//    var body: some View { VStack(alignment: .leading, spacing: 10) { RoundedRectangle(cornerRadius: 12).fill(model.iconBackgroundColor.opacity(0.3)).frame(height: 120).overlay(Image(systemName: model.iconName).resizable().scaledToFit().padding(25).foregroundStyle(model.iconBackgroundColor)); VStack(alignment: .leading, spacing: 4) { Text(model.displayName).font(.headline); Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2) }.padding([.horizontal, .bottom], 12) }.background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 15)).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3).frame(minWidth: 0, maxWidth: .infinity) }
//}
//
//// --- StandardModelRow (unchanged) ---
//struct StandardModelRow: View {
//    let model: OpenAIModel
//    var body: some View { HStack(spacing: 12) { Image(systemName: model.iconName).resizable().scaledToFit().padding(7).frame(width: 36, height: 36).background(model.iconBackgroundColor.opacity(0.85)).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 8)); VStack(alignment: .leading, spacing: 3) { Text(model.displayName).font(.subheadline.weight(.medium)).lineLimit(1); Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2) }; Spacer(minLength: 0) }.padding(10).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1)) }
//}
//
//// --- SectionHeader (unchanged) ---
//struct SectionHeader: View {
//    let title: String; let subtitle: String?
//    var body: some View { VStack(alignment: .leading, spacing: 4) { Text(title).font(.title2.weight(.semibold)); if let subtitle = subtitle { Text(subtitle).font(.callout).foregroundColor(.secondary) } }.padding(.bottom, 10).padding(.horizontal) }
//}
//
//// MARK: - Model Detail View (SIGNIFICANTLY UPDATED for o3)
//
//struct ModelDetailView: View {
//    let model: OpenAIModel
//
//    // Environment variable for linking
//    @Environment(\.openURL) var openURL
//
//    var body: some View {
//        List {
//            // --- Top Header Section ---
//            Section {
//                VStack(spacing: 12) {
//                     // Icon
//                     Image(systemName: model.iconName).resizable().scaledToFit()
//                        .padding(18).frame(width: 70, height: 70) // Slightly larger icon
//                        .background(model.iconBackgroundColor.opacity(0.9))
//                        .foregroundStyle(.white)
//                        .clipShape(Circle())
//
//                     // Title & Default Tag
//                     HStack(spacing: 6) {
//                         Text(model.displayName).font(.title2.weight(.semibold))
//                         if model.isDefault == true {
//                             Text("Default").font(.caption.weight(.medium))
//                                 .padding(.horizontal, 8).padding(.vertical, 3)
//                                 .background(Color.green.opacity(0.2))
//                                 .foregroundStyle(Color.green)
//                                 .clipShape(Capsule())
//                         }
//                     }
//                     // Short Description
//                     Text(model.shortDescription)
//                        .font(.subheadline).foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//
//                     // Action Buttons (Mimicking Screenshot)
//                     HStack {
//                         Button("Compare") { /* TODO: Implement Compare Action */ }
//                             .buttonStyle(.bordered)
//                         Button("Try in Playground") { /* TODO: Implement Playground Action */ }
//                             .buttonStyle(.borderedProminent)
//                     }
//                     .padding(.top, 5)
//                }
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding(.vertical, 10)
//            }
//            .listRowInsets(EdgeInsets()) // Remove default padding
//            .listRowBackground(Color.clear) // Make background clear
//
//            // --- Ratings Section ---
//            Section("Ratings") {
//                 RatingsRow(label: "Reasoning", rating: model.reasoningRating, maxRating: 5, iconName: "brain.head.profile", activeColor: .orange)
//                 RatingsRow(label: "Speed", rating: model.speedRating, maxRating: 5, iconName: "bolt.fill", activeColor: .blue) // Assume 5 bolts max for visual
//             }
//
//             // --- Modalities Section ---
//             Section("Modalities") {
//                 ModalitiesRow(label: "Input", modalities: model.inputModalities)
//                 ModalitiesRow(label: "Output", modalities: model.outputModalities)
//                 if model.inputModalities?.contains("audio") != true && model.outputModalities?.contains("audio") != true {
//                     DetailRow(label: "Audio", value: "Not supported").foregroundColor(.secondary)
//                 }
//             }
//
//             // --- Key Specs / Capabilities Section ---
//             Section("Key Specifications") {
//                 if let tokens = model.contextWindowTokens {
//                     DetailRow(label: "Context Window", value: tokens.formatted(.number) + " tokens")
//                 }
//                 if let tokens = model.maxOutputTokens {
//                     DetailRow(label: "Max Output Tokens", value: tokens.formatted(.number) + " tokens")
//                 }
//                 if let cutoff = model.knowledgeCutoff {
//                     DetailRow(label: "Knowledge Cutoff", value: cutoff)
//                 }
//                 if model.supportsReasoningTokens == true {
//                     Label("Reasoning token support", systemImage: "checkmark.circle.fill")
//                         .foregroundColor(.green)
//                 }
//             }
//
//             // --- Detailed Description ---
//             Section("Description") {
//                 Text(model.description)
//                     .font(.callout)
//                     .foregroundColor(.primary) // Ensure readable
//                 if let url = model.reasoningGuideUrl {
//                     Button { openURL(url) } label: {
//                         Label("Learn more about reasoning models", systemImage: "link")
//                     }
//                      .font(.callout)
//                 }
//             }
//
//             // --- Pricing Section ---
//            if let pricing = model.pricing {
//                Section("Pricing (per 1M tokens)") {
//                    HStack(spacing: 15) {
//                        PriceCard(label: "Input", price: pricing.inputPerMToken)
//                        PriceCard(label: "Cached Input", price: pricing.cachedInputPerMToken)
//                        PriceCard(label: "Output", price: pricing.outputPerMToken)
//                    }
//                     .frame(maxWidth: .infinity) // Distribute cards
//                    if let notes = pricing.notes {
//                         Text(notes).font(.caption).foregroundColor(.secondary).padding(.top, 5)
//                    }
//                    // Placeholder for Batch API toggle/info (as UI is complex)
//                     Text("Batch API pricing may differ. Refer to pricing page.")
//                        .font(.caption).foregroundColor(.secondary)
//                 }
//            }
//
//             // --- Endpoints Section ---
//             if let endpoints = model.endpoints, !endpoints.isEmpty {
//                 Section("Endpoints") {
//                     ForEach(endpoints) { endpoint in
//                         EndpointRow(endpoint: endpoint)
//                     }
//                 }
//             }
//
//             // --- Features Section ---
//             if let features = model.features, !features.isEmpty {
//                 Section("Features") {
//                     ForEach(features) { feature in
//                         FeatureRow(feature: feature)
//                     }
//                 }
//             }
//
//             // --- Capabilities Section ---
//            Section("Capabilities - TODO") {
//                Text("This model is currently not supported for any capabilities.")
//                    .font(.caption)
//            }
////            if let capabilities = model.capabilities.first,
////                !capabilities.isEmpty &&
////                capabilities != "general" {
////                 Section("Capabilities") {
////                     WrappingHStack(items: capabilities) { capability in
////                         Text(capability.capitalized)
////                             .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
////                             .background(Color.accentColor.opacity(0.2))
////                             .foregroundColor(.accentColor).clipShape(Capsule())
////                     }
////                 }
////             }
//
//            // --- Snapshots Section ---
//            if let snapshots = model.snapshots, !snapshots.isEmpty {
//                Section("Snapshots") {
//                    Text("Snapshots let you lock in a specific version of the model.").font(.caption).foregroundColor(.secondary)
//                    ForEach(snapshots) { snapshot in
//                        HStack {
//                            Text(snapshot.alias)
//                                .font(.callout.weight(.medium))
//                            if let version = snapshot.version, version != snapshot.alias {
//                                Text("(\(version))")
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                            }
//                        }
//                    }
//                }
//            }
//
//            // --- Rate Limit Section ( Simplified View )---
//            if let rateLimits = model.rateLimits, let tiers = rateLimits.tiers, !tiers.isEmpty {
//                 Section("Rate Limits (Example: Tier 1)") {
//                     if let tier1 = tiers.first(where: { $0.name == "Tier 1" }) {
//                          VStack(alignment: .leading) {
//                              Text("Rate limits ensure fair usage. Limits vary by usage tier.").font(.caption).foregroundColor(.secondary)
//                              DetailRow(label: "Requests Per Minute (RPM)", value: tier1.rpm?.description ?? "-")
//                              DetailRow(label: "Tokens Per Minute (TPM)", value: tier1.tpm?.formatted(.number) ?? "-")
//                          }
//                     } else {
//                         Text("Rate limit information not available for Tier 1.")
//                              .font(.caption).foregroundColor(.secondary)
//                     }
//                     Text("Full details available on the OpenAI rate limits page.")
//                         .font(.caption).foregroundColor(.secondary)
//                 }
//            }
//
//        } // End List
//        .listStyle(.insetGrouped)
//        .navigationTitle(model.displayName) // Use model name in title
//        .navigationBarTitleDisplayMode(.inline)
//         .toolbarBackground(.visible, for: .navigationBar)
//         .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
//    }
//
//    // MARK: - Detail View Helper Subviews
//
//    // --- Simple Key-Value Row ---
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
//    // --- Ratings Display Row ---
//    private func RatingsRow(label: String, rating: Int?, maxRating: Int, iconName: String, activeColor: Color) -> some View {
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//            HStack(spacing: 3) {
//                 if let rating = rating {
//                     ForEach(1...maxRating, id: \.self) { index in
//                         Image(systemName: iconName)
//                             .foregroundStyle(index <= rating ? activeColor : Color.gray.opacity(0.3))
//                             .imageScale(.small)
//                     }
//                } else {
//                     Text("N/A").font(.caption).foregroundColor(.secondary)
//                }
//            }
//        }
//        .padding(.vertical, 2)
////        .accessibilityElement(children: .combine) {
////            $0.label = label
////            $0.value = "\(rating ?? 0) out of \(maxRating)"
////        }
//    }
//
//    // --- Modalities Display Row ---
//    private func modalityIcon(_ modality: String) -> String {
//        switch modality.lowercased() {
//        case "text": return "text.bubble.fill"
//        case "image": return "photo.fill"
//        case "audio": return "speaker.wave.2.fill"
//        default: return "questionmark.circle.fill"
//        }
//    }
//
//    private func ModalitiesRow(label: String, modalities: [String]?) -> some View {
//        HStack {
//            Text(label).font(.callout).foregroundColor(.secondary)
//            Spacer()
//             if let modalities = modalities, !modalities.isEmpty {
//                 HStack(spacing: 8) {
//                     ForEach(modalities, id: \.self) { modality in
//                         Label(modality.capitalized, systemImage: modalityIcon(modality))
//                            .font(.caption)
//                          //  .padding(.horizontal, 6).padding(.vertical, 3)
//                           // .background(Color.secondary.opacity(0.1))
//                          //  .clipShape(Capsule())
//                     }
//                 }
//             } else {
//                 Text("N/A").font(.caption).foregroundColor(.secondary)
//             }
//        }
//        .padding(.vertical, 2)
//    }
//
//     // --- Pricing Card ---
//     private func PriceCard(label: String, price: Double?) -> some View {
//         VStack(alignment: .center, spacing: 4) {
//             Text(label)
//                  .font(.caption)
//                  .foregroundStyle(.secondary)
//             if let price = price {
//                 Text(price, format: .currency(code: "USD").precision(.fractionLength(2)))
//                       .font(.headline.weight(.semibold))
//             } else {
//                 Text("-")
//                       .font(.headline.weight(.regular))
//                       .foregroundStyle(.secondary)
//             }
//         }
//         .padding(10)
//         .frame(minWidth: 0, maxWidth: .infinity) // Allow equal distribution
//         .background(.thinMaterial)
//         .clipShape(RoundedRectangle(cornerRadius: 8))
//         .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
//     }
//
//    // --- Endpoint Row ---
//    private func EndpointRow(endpoint: EndpointInfo) -> some View {
//         VStack(alignment: .leading) {
//             HStack {
//                 Image(systemName: endpoint.supported ? "checkmark.circle.fill" : "xmark.circle.fill")
//                     .foregroundStyle(endpoint.supported ? .green : .secondary)
//                 Text(endpoint.path).font(.callout.monospaced()) // Monospaced for path
//                 Spacer()
//             }
//             // Display details like realtime/batch if available
//             if let details = endpoint.details, !details.isEmpty {
//                 HStack(spacing: 10) {
//                     ForEach(details.sorted(by: { $0.key < $1.key }), id: \.key) { key, supported in
//                         Text("\(key.capitalized): \(supported ? "Yes" : "No")")
//                     }
//                 }
//                 .font(.caption).foregroundStyle(.secondary).padding(.leading, 25)
//             }
//         }
//         .padding(.vertical, 3)
//    }
//
//    // --- Feature Row ---
//    private func FeatureRow(feature: FeatureInfo) -> some View {
//         HStack {
//             Image(systemName: feature.supported ? "checkmark.circle.fill" : "xmark.circle.fill")
//                 .foregroundStyle(feature.supported ? .green : .secondary)
//             Text(feature.name)
//             Spacer()
//         }
//          .font(.callout)
//          .padding(.vertical, 3)
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
//    @State private var useMockData = true
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
//    // --- Filters for Sections (Simplified Examples) ---
//    // NOTE: In a real app, filtering should be more robust, perhaps using tags/categories
//    var featuredModels: [OpenAIModel] { allModels.filter { ["o3", "gpt-4.1", "o4-mini"].contains($0.id) }.sortedById() }
//    var reasoningModels: [OpenAIModel] { allModels.filter { $0.id.contains("o1") || $0.id.contains("o3") || $0.id.contains("o4") }.sortedById() }
//    var chatModels: [OpenAIModel] { allModels.filter { $0.id.contains("gpt") }.sortedById() }
//    var otherModels: [OpenAIModel] { allModels.filter { !$0.id.contains("gpt") && !$0.id.contains("o") }.sortedById() } // Catch-all
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                if isLoading && allModels.isEmpty { // Full screen loading
//                     ProgressView("Fetching Models...").frame(maxWidth: .infinity, maxHeight: .infinity)//.background(.systemBackground).zIndex(1)
//                } else if let errorMessage = errorMessage, allModels.isEmpty { // Full screen error
//                     ErrorView(errorMessage: errorMessage) { attemptLoadModels() }.zIndex(1)
//                } else { // Show Content
//                    ScrollView(.vertical, showsIndicators: false) {
//                        VStack(alignment: .leading, spacing: 30) {
//                             // --- Header ---
//                             VStack(alignment: .leading, spacing: 5) { Text("Models").font(.largeTitle.weight(.bold)); Text("Explore available models.").font(.title3).foregroundColor(.secondary) }.padding(.horizontal)
//                             Divider().padding(.horizontal)
//
//                             // --- Featured Models Section ---
//                              if !featuredModels.isEmpty {
//                                  SectionHeader(title: "Featured models", subtitle: nil)
//                                  ScrollView(.horizontal, showsIndicators: false) {
//                                       HStack(spacing: 15) {
//                                            ForEach(featuredModels) { model in
//                                                 NavigationLink(value: model) {
//                                                     FeaturedModelCard(model: model).frame(width: 250)
//                                                 }.buttonStyle(.plain)
//                                             }
//                                       }.padding(.horizontal).padding(.bottom, 5)
//                                  }
//                              }
//
//                             // --- Standard Sections with Grid ---
//                             // Use the simplified filters or more complex ones as needed
//                             displaySection(title: "Reasoning Models", subtitle: "o-series models for complex tasks.", models: reasoningModels)
//                             displaySection(title: "Chat Models", subtitle: "General purpose and chat-tuned models.", models: chatModels)
//                             displaySection(title: "Other Models", subtitle: "Specialized models (image, audio, etc.)", models: otherModels)
//
//                             Spacer(minLength: 50)
//                        }
//                        .padding(.top)
//                    }
//                    .background(Color(.systemBackground))
//                    .edgesIgnoringSafeArea(.bottom)
//                }
//            } // End ZStack
//            .navigationTitle("OpenAI Models")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                 ToolbarItem(placement: .navigationBarLeading) { if isLoading { ProgressView().controlSize(.small) } else { Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(isLoading) } }
//                 ToolbarItem(placement: .navigationBarTrailing) { Menu { Toggle(isOn: $useMockData) { Text(useMockData ? "Using Mock Data" : "Using Live API") } } label: { Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill").foregroundColor(useMockData ? .secondary : .blue) }.disabled(isLoading) }
//             }
//             .navigationDestination(for: OpenAIModel.self) { model in ModelDetailView(model: model) }
//             .task { if allModels.isEmpty { attemptLoadModels() } }
//             .refreshable { await loadModelsAsync(checkApiKey: false) }
//             .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
//             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
//             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: { Button("OK") { errorMessage = nil } }, message: { Text(errorMessage ?? "An unknown error occurred.") })
//
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
//                 ForEach(models) { model in NavigationLink(value: model) { StandardModelRow(model: model) }.buttonStyle(.plain) }
//             }.padding(.horizontal)
//         }
//    }
//
//    // --- Loading Functions (Unchanged) ---
//    private func handleToggleChange(to newValue: Bool) { print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")"); allModels = []; errorMessage = nil; if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true } else { loadModelsAsyncWithLoadingState() } }
//    private func presentApiKeySheet() -> some View { APIKeyInputView(onSave: { _ in print("API Key saved."); loadModelsAsyncWithLoadingState() }, onCancel: { print("API Key input cancelled."); useMockData = true }) }
//    private func attemptLoadModels() { guard !isLoading else { return }; if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true } else { loadModelsAsyncWithLoadingState() } }
//    private func loadModelsAsyncWithLoadingState() { guard !isLoading else { return }; isLoading = true; Task { await loadModelsAsync(checkApiKey: false) } }
//    @MainActor private func loadModelsAsync(checkApiKey: Bool) async { if !isLoading { isLoading = true }; if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true; isLoading = false; return }; let serviceToUse = currentApiService; print("🔄 Loading models using \(useMockData ? "MockAPIService" : "LiveAPIService")..."); do { let fetchedModels = try await serviceToUse.fetchModels(); self.allModels = fetchedModels; self.errorMessage = nil; print("✅ Successfully loaded \(fetchedModels.count) models.") } catch let error as LocalizedError { print("❌ Error loading models: \(error.localizedDescription)"); self.errorMessage = error.localizedDescription; if allModels.isEmpty { self.allModels = [] } } catch { print("❌ Unexpected error loading models: \(error)"); self.errorMessage = "Unexpected error: \(error.localizedDescription)"; if allModels.isEmpty { self.allModels = [] } }; isLoading = false }
//}
//
//// MARK: - Helper Extensions
//
//extension Array where Element == OpenAIModel {
//    func sortedById() -> [OpenAIModel] { self.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending } }
//}
//
//// MARK: - Previews
//
//#Preview("Master View (With o3 Mock)") {
//    OpenAIModelsMasterView() // Default uses mock data, which now includes o3
//}
//
////#Preview("o3 Detail View") {
////    // Preview the detail view specifically with the mock o3 model
////    let mockService = MockAPIService()
////    let o3Model = try? await mockService.fetchModels().first { $0.id == "o3" }
////
////    NavigationStack {
////        if let o3Model = o3Model {
////            ModelDetailView(model: o3Model)
////        } else {
////            Text("Failed to load o3 mock model for preview.")
////        }
////    }
////}
////
////#Preview("API Key Input Sheet") {
////    struct SheetPresenter: View { @State var showSheet = true; var body: some View { Text("Preview").sheet(isPresented: $showSheet) { APIKeyInputView(onSave: {_ in}, onCancel: {}) } } }
////    SheetPresenter()
////}
