//
//  GeminiModelMasterView.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  GeminiModelsMasterView.swift
//  Alchemy_Models_Combined
//  (Single File Implementation for Google Gemini)
//
//  Created: Cong Le
//  Date: 4/13/25 (Adapted from OpenAI version)
//  Version: 1.0 (Gemini Adaptation)
//  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
//  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
//
//  Disclaimer: This adaptation uses mock data based solely on the provided
//  screenshots. A live implementation would require the actual Google AI Gemini
//  API endpoint and response structure. API key handling is kept as a placeholder.
//

import SwiftUI
import Foundation // Needed for URLSession, URLRequest, etc.
import Combine

// MARK: - Enums (Sorting, Errors)

enum SortOption: String, CaseIterable, Identifiable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case dateNewest = "Date (Newest)" // Assuming 'created' maps to a date
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

// Placeholder - Adapt error types if using a live Google API
enum LiveAPIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case missingAPIKey // Placeholder for Google API Key/Credentials
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The API endpoint URL is invalid."
        case .requestFailed(let sc): return "API request failed with status code \(sc)."
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .decodingError(let err): return "Failed to decode API response: \(err.localizedDescription)"
        case .missingAPIKey: return "Google Cloud API Key/Credentials are missing or invalid." // Updated text
        }
    }
}

// MARK: - API Service Protocol

protocol APIServiceProtocol {
    // Function name kept generic
    func fetchModels() async throws -> [GeminiModel]
}

// MARK: - Data Models

// --- Gemini Model Category Enum ---
enum GeminiModelCategory: String, CaseIterable, Comparable {
    case featured = "Featured" // Special category
    case generative = "Generative" // Primary Gemini models (Pro, Flash)
    case vision = "Vision" // Imagen, Veo
    case embedding = "Embedding"
    case experimental = "Experimental" // For previews or experimental tags
    case other = "Other" // AQA, etc.
    
    // Order for sections
    static func < (lhs: GeminiModelCategory, rhs: GeminiModelCategory) -> Bool {
        let order: [GeminiModelCategory] = [.featured, .generative, .vision, .embedding, .experimental, .other]
        return (order.firstIndex(of: lhs) ?? 99) < (order.firstIndex(of: rhs) ?? 99)
    }
}

// --- Main Gemini Model Struct ---
struct GeminiModel: Codable, Identifiable, Hashable {
    let id: String // e.g., "gemini-1.5-pro-preview-0409"
    var name: String // e.g., "Gemini 1.5 Pro"
    var version: String // e.g., "1.5" or "2.5"
    var tier: String? // e.g., "Pro", "Flash", "Flash-Lite"
    var owner: String = "google" // Default owner
    var created: Int // Placeholder Unix timestamp for sorting
    var isPreview: Bool = false
    var isExperimental: Bool = false
    var rateLimitLink: URL? = nil // Optional link
    
    // Descriptions
    var shortDescription: String = "Google AI model." // Default short description
    var detailedDescription: String = "No detailed description available." // For detail view
    
    // Capabilities (Parsed from bullet points or assigned based on name)
    var capabilities: [String] = []
    var inputTypes: [String] = ["text"] // Default input
    
    // --- Computed Meta Properties ---
    var category: GeminiModelCategory {
        let lowerId = id.lowercased()
        if ["gemini-2.5-pro", "gemini-2.5-flash", "gemini-2.0-flash"].contains(lowerId) { return .featured } // Explicitly featured
        if lowerId.contains("imagen") || lowerId.contains("veo") { return .vision }
        if lowerId.contains("embedding") { return .embedding }
        if lowerId.contains("gemini") { return .generative }
        if lowerId.contains("preview") || lowerId.contains("experimental") { return .experimental }
        if lowerId.contains("aqa") { return .other }
        return .other // Fallback
    }
    
    // --- Codable Conformance ---
    // Let Codable synthesize keys for mock data
    
    // --- Identifiable & Hashable ---
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: GeminiModel, rhs: GeminiModel) -> Bool { lhs.id == rhs.id }
    
    // --- Computed Properties for UI ---
    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
    
    // --- Determine SF Symbol name based on ID/Name ---
    var iconName: String {
        let lowerName = name.lowercased()
        // Featured icons
        if lowerName.contains("2.5 pro") { return "trophy.fill" }
        if lowerName.contains("2.5 flash") { return "testtube.2" } // Flask alternative
        if lowerName.contains("2.0 flash") { return "sparkles" } // Matches screenshot more closely
        
        // Other types
        if lowerName.contains("imagen") { return "photo.on.rectangle.angled" }
        if lowerName.contains("veo") { return "video.fill" }
        if lowerName.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" }
        if lowerName.contains("aqa") { return "questionmark.bubble.fill" }
        if lowerName.contains("pro") { return "star.fill" } // Generic Pro
        if lowerName.contains("flash") { return "bolt.fill" } // Generic Flash
        
        return "brain.head.profile" // Default Gemini icon
    }
    
    // --- Determine background color for icons ---
    var iconBackgroundColor: Color {
        let lowerName = name.lowercased()
        // Featured colors
        if lowerName.contains("2.5 pro") { return .indigo }
        if lowerName.contains("2.5 flash") { return .blue }
        if lowerName.contains("2.0 flash") { return .purple }
        
        switch category {
        case .featured: return .gray // Should be overridden by name checks above
        case .generative: return .teal
        case .vision: return .orange
        case .embedding: return .green
        case .experimental: return .pink
        case .other: return .brown
        }
    }
}

// MARK: - API Service Implementations

// --- Mock Data Service ---
class MockAPIService: APIServiceProtocol {
    private let mockNetworkDelaySeconds: Double = 0.6
    
    private func generateMockGeminiModels() -> [GeminiModel] {
        // Timestamps: Approximate, newer models get later timestamps
        let now = Date()
        let ts_2_5_pro = Int(now.timeIntervalSince1970) // Most recent
        let ts_2_5_flash = ts_2_5_pro - 100000
        let ts_2_0_flash = ts_2_5_flash - 200000
        let ts_1_5_pro = ts_2_0_flash - 5000000
        let ts_1_5_flash = ts_1_5_pro - 100000
        let ts_imagen = ts_1_5_flash - 3000000
        let ts_veo = ts_imagen + 50000 // Close to Imagen
        let ts_embedding = ts_veo - 10000000
        let ts_aqa = ts_embedding - 2000000
        
        return [
            // --- Featured Models (From Screenshot 1) ---
            GeminiModel(
                id: "gemini-2.5-pro", name: "2.5 Pro", version: "2.5", tier: "Pro", created: ts_2_5_pro,
                shortDescription: "Our most powerful thinking model.",
                detailedDescription: "Our most powerful thinking model with maximum response accuracy and state-of-the-art performance",
                capabilities: [
                    "Tackle difficult problems, analyze large databases, and more",
                    "Best for complex coding, reasoning, and multimodal understanding"
                ],
                inputTypes: ["audio", "images", "video", "text"]
            ),
            GeminiModel(
                id: "gemini-2.5-flash", name: "2.5 Flash", version: "2.5", tier: "Flash", created: ts_2_5_flash,
                shortDescription: "Best model for price-performance.",
                detailedDescription: "Our best model in terms of price-performance, offering well-rounded capabilities.",
                capabilities: [
                    "Model thinks as needed; or, you can configure a thinking budget",
                    "Best for low latency, high volume tasks that require thinking"
                ],
                inputTypes: ["audio", "images", "video", "text"]
            ),
            GeminiModel(
                id: "gemini-2.0-flash", name: "2.0 Flash", version: "2.0", tier: "Flash", created: ts_2_0_flash,
                shortDescription: "Newest multimodal with next gen features.",
                detailedDescription: "Our newest multimodal model, with next generation features and improved capabilities",
                capabilities: [
                    "Generate code and images, extract data, analyze files, generate graphs, and more",
                    "Low latency, enhanced performance, built to power agentic experiences"
                ],
                inputTypes: ["audio", "images", "video", "text"]
            ),
            
            // --- List Models (From Screenshot 2) ---
            GeminiModel(id: "gemini-2.5-flash-preview-04-17", name: "Gemini 2.5 Flash Preview 04-17", version: "2.5", tier: "Flash", created: ts_2_5_flash + 5000, isPreview: true, shortDescription: "Preview version of 2.5 Flash.", capabilities: ["Generative задачи"]),
            GeminiModel(id: "gemini-2.5-pro-preview", name: "Gemini 2.5 Pro Preview", version: "2.5", tier: "Pro", created: ts_2_5_pro + 5000, isPreview: true, shortDescription: "Preview version of 2.5 Pro.", capabilities: ["Complex reasoning", "Coding"]),
            // Included 2.0 Flash above from featured section
            GeminiModel(id: "gemini-2.0-flash-lite", name: "Gemini 2.0 Flash-Lite", version: "2.0", tier: "Flash-Lite", created: ts_2_0_flash - 10000, shortDescription: "Lighter version of 2.0 Flash.", capabilities: ["Low latency tasks"]),
            GeminiModel(id: "gemini-1.5-flash", name: "Gemini 1.5 Flash", version: "1.5", tier: "Flash", created: ts_1_5_flash, shortDescription: "Previous generation Flash model.", capabilities: ["Balanced performance"]),
            GeminiModel(id: "gemini-1.5-flash-8b", name: "Gemini 1.5 Flash-8B", version: "1.5", tier: "Flash-8B", created: ts_1_5_flash - 5000, shortDescription: "Specific 8B variant of 1.5 Flash.", capabilities: ["Specific use cases"]),
            GeminiModel(
                id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", version: "1.5", tier: "Pro", created: ts_1_5_pro,
                rateLimitLink: URL(string: "https://ai.google.dev/gemini-api/docs/models/gemini#gemini-1.5-pro"), // Example link
                shortDescription: "Previous generation Pro model.",
                capabilities: ["High capability reasoning"]
            ),
            GeminiModel(id: "imagen-3", name: "Imagen 3", version: "3", created: ts_imagen, shortDescription: "Advanced image generation model.", capabilities: ["Image generation"], inputTypes: ["text"]),
            GeminiModel(id: "veo-2", name: "Veo 2", version: "2", created: ts_veo, shortDescription: "Advanced video generation model.", capabilities: ["Video generation"], inputTypes: ["text", "image"]),
            GeminiModel(id: "gemini-2.0-flash-live", name: "Gemini 2.0 Flash Live", version: "2.0", tier: "Flash", created: ts_2_0_flash + 1000, shortDescription: "Live version of 2.0 Flash.", capabilities: ["Realtime interactions"]), // Assuming 'Live' implies realtime?
            GeminiModel(id: "gemini-embedding-experimental", name: "Gemini Embedding Experimental", version: "N/A", created: ts_embedding + 500, isExperimental: true, shortDescription: "Experimental model for text embeddings.", capabilities: ["Text embedding"]),
            GeminiModel(id: "text-embedding-and-embedding", name: "Text Embedding and Embedding", version: "N/A", created: ts_embedding, shortDescription: "Standard embedding models.", capabilities: ["Text embedding"]), // Ambiguous name, kept literal
            GeminiModel(id: "aqa", name: "AQA", version: "N/A", created: ts_aqa, shortDescription: "Model specialized for Attributed Question Answering.", capabilities: ["Question answering"]),
        ]
    }
    
    func fetchModels() async throws -> [GeminiModel] {
        try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
        return generateMockGeminiModels()
        // throw MockError.simulatedFetchError // Uncomment to test error state
    }
}

// --- Live Data Service (Placeholder) ---
class LiveAPIService: APIServiceProtocol {
    // Placeholder for Google Cloud API Key/Credentials storage
    @AppStorage("userGoogleApiKey") private var storedApiKey: String = ""
    // Placeholder - Replace with actual Google Gemini API endpoint
    private let modelsURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models")! // EXAMPLE URL
    
    func fetchModels() async throws -> [GeminiModel] {
        let currentKey = storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        // GUARD: Check if API Key is provided (Adapt based on Google Auth)
        guard !currentKey.isEmpty else { throw LiveAPIError.missingAPIKey }
        
        // --- Build Request (Adapt Headers for Google API) ---
        var request = URLRequest(url: modelsURL)
        request.httpMethod = "GET"
        // GOOGLE API REQUIRES 'x-goog-api-key' header or OAuth token
        request.setValue(currentKey, forHTTPHeaderField: "x-goog-api-key") // Example Using API Key
        // OR: request.setValue("Bearer \(oauthToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        print("🚀 Making live API request to Google Gemini: \(modelsURL)")
        
        // --- Perform Network Call & Handle Response ---
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw LiveAPIError.requestFailed(statusCode: 0) }
            print("✅ Received Google API response with status code: \(httpResponse.statusCode)")
            
            // Check specific error codes from Google API if needed (e.g., 403 Forbidden)
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw LiveAPIError.missingAPIKey } // Unauthorized or Forbidden
            guard (200...299).contains(httpResponse.statusCode) else { throw LiveAPIError.requestFailed(statusCode: httpResponse.statusCode) }
            
            // --- Decode Response (ADAPT to Google's Response Structure) ---
            // Google's response likely has a different structure, e.g., a "models" array.
            // Define a corresponding Codable struct for Google's response.
            struct GoogleModelListResponse: Codable {
                let models: [GoogleAPIModelFormat] // Needs definition based on actual API
            }
            // Define GoogleAPIModelFormat based on the *actual* keys Google returns
            struct GoogleAPIModelFormat: Codable {
                let name: String // Often like "models/gemini-1.5-pro-latest"
                let version: String? // e.g., "1.5"
                let displayName: String? // e.g., "Gemini 1.5 Pro"
                let description: String?
                let inputTokenLimit: Int?
                let outputTokenLimit: Int?
                // ... add other fields from Google's API response
            }
            
            do {
                let decoder = JSONDecoder()
                // Example decoding - ADJUST THIS BASED ON ACTUAL GOOGLE RESPONSE
                // let responseWrapper = try decoder.decode(GoogleModelListResponse.self, from: data)
                // print("✅ Successfully decoded \(responseWrapper.models.count) Google models.")
                
                // --- MAP GoogleAPIModelFormat to our GeminiModel ---
                // This mapping is crucial and depends heavily on the actual Google response.
                // return responseWrapper.models.map { apiModel -> GeminiModel in
                //     let modelId = apiModel.name // Or parse from name
                //     let modelName = apiModel.displayName ?? apiModel.name // Example fallback
                //     let modelVersion = apiModel.version ?? "N/A"
                //    let createdTimestamp = Int(Date().timeIntervalSince1970) // Placeholder timestamp
                //     return GeminiModel(
                //         id: modelId,
                //         name: modelName,
                //         version: modelVersion,
                //         // ... map other fields ...
                //         created: createdTimestamp // Assign a placeholder or derive if possible
                //         // ... populate other GeminiModel fields based on apiModel ...
                //     )
                // }
                
                // Placeholder return until live API structure is known
                print("⚠️ Live API decoding not implemented for Gemini - returning empty array.")
                return []
                
            } catch {
                print("❌ Decoding Error (Google API): \(error)")
                print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Could not decode data")")
                throw LiveAPIError.decodingError(error)
            }
        } catch let error as LiveAPIError { throw error }
        catch { throw LiveAPIError.networkError(error) }
    }
}

// MARK: - Reusable SwiftUI Helper Views (Error, WrappingHStack, APIKeyInputView)

struct ErrorView: View { /* ... Unchanged ... */
    let errorMessage: String
    let retryAction: () -> Void
    var body: some View {
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

struct WrappingHStack<Item: Hashable, ItemView: View>: View { /* ... Unchanged ... */
    let items: [Item]
    let viewForItem: (Item) -> ItemView
    let horizontalSpacing: CGFloat = 8
    let verticalSpacing: CGFloat = 8
    @State private var totalHeight: CGFloat = .zero
    var body: some View {
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

// --- API Key Input View (Adapted for Google) ---
struct APIKeyInputViewGemini: View {
    @Environment(\.dismiss) var dismiss
    // Use a different AppStorage key for Google
    @AppStorage("userGoogleApiKey") private var apiKey: String = ""
    @State private var inputApiKey: String = ""
    @State private var isInvalidKeyAttempt: Bool = false
    
    var onSave: (String) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter your Google Cloud API Key") // Updated title
                    .font(.headline)
                Text("Your key will be stored in UserDefaults. Ensure it's enabled for the 'Generative Language API' on Google Cloud.") // Updated instructions
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("AIza...", text: $inputApiKey) // Example Google Key prefix
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isInvalidKeyAttempt ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .onChange(of: inputApiKey) { _,_ in isInvalidKeyAttempt = false }
                
                if isInvalidKeyAttempt {
                    Text("API Key cannot be empty.")
                        .font(.caption).foregroundColor(.red)
                }
                
                HStack {
                    Button("Cancel") { onCancel(); dismiss() }.buttonStyle(.bordered)
                    Spacer()
                    Button("Save Key") {
                        let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedKey.isEmpty { isInvalidKeyAttempt = true }
                        else { apiKey = trimmedKey; onSave(apiKey); dismiss() }
                    }.buttonStyle(.borderedProminent)
                }
                .padding(.top)
                Spacer()
            }
            .padding()
            .navigationTitle("Google API Key") // Updated nav title
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { inputApiKey = apiKey; isInvalidKeyAttempt = false }
        }
    }
}

// MARK: - Model Views (Featured Card, Standard Row, Detail - Gemini Adapted)

// --- Featured Model Card View (Gemini Style) ---
struct FeaturedModelCardGemini: View {
    let model: GeminiModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Icon and Name
            HStack {
                Image(systemName: model.iconName)
                    .font(.title2) // Slightly smaller icon
                    .frame(width: 30, height: 30)
                    .foregroundStyle(model.iconBackgroundColor) // Use color for symbol itself
                // .background(model.iconBackgroundColor.opacity(0.2)) // Optional subtle background circle
                // .clipShape(Circle())
                Text(model.name)
                    .font(.title3.weight(.semibold))
                Spacer()
            }
            
            // Description
            Text(model.detailedDescription) // Use the longer description
                .font(.callout)
                .foregroundColor(.secondary)
                .lineLimit(3) // Allow a bit more text
            
            // Bullet points for capabilities
            VStack(alignment: .leading, spacing: 5) {
                ForEach(model.capabilities.prefix(3), id: \.self) { capability in // Show max 3 capabilities
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill") // Use bullet points
                            .font(.system(size: 6))
                            .foregroundColor(.secondary)
                            .padding(.top, 5) // Align with text
                        Text(capability)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true) // Allow text wrap
                    }
                }
            }
            Spacer() // Pushes content up
        }
        .padding()
        .frame(maxWidth: .infinity, idealHeight: 220) // Control height
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        // .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2) // Optional subtle shadow
    }
}

// --- Standard Model Row View (Simple List Style) ---
struct StandardModelRowGemini: View {
    let model: GeminiModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Use '+' icon consistent with screenshot 2 (or model icon)
            Image(systemName: "plus.circle") // Or use model.iconName
                .foregroundColor(.secondary)
            // .foregroundColor(model.iconBackgroundColor) // Color the icon
            
            Text(model.name) // Display the full name from the list
                .font(.body)
            
            if model.isPreview {
                Text("Preview")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
            if model.isExperimental {
                Text("Exp")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color.pink.opacity(0.2))
                    .foregroundColor(.pink)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Optional Link Icon
            if model.rateLimitLink != nil {
                Image(systemName: "link")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8) // Adjust padding for list appearance
        // Remove background/border for a cleaner list look
    }
}

// --- Reusable Section Header (Unchanged) ---
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 10)
        .padding(.horizontal)
    }
}

// --- Model Detail View (Gemini Adapted) ---
struct ModelDetailViewGemini: View {
    let model: GeminiModel
    
    var body: some View {
        List {
            // Top Section with Icon/Name
            Section {
                VStack(spacing: 15) {
                    Image(systemName: model.iconName).resizable().scaledToFit()
                        .padding(15).frame(width: 80, height: 80)
                        .background(model.iconBackgroundColor.opacity(0.2)) // Subtle background
                        .foregroundColor(model.iconBackgroundColor) // Color the icon itself
                        .clipShape(RoundedRectangle(cornerRadius: 16)) // Squarish icon like examples
                    Text(model.name).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                    Text(model.shortDescription).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center)
                    if model.isPreview {
                        Text("Preview").font(.caption.weight(.medium)).foregroundColor(.orange)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15)).clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
            }
            .listRowBackground(Color.clear)
            
            Section("Overview") {
                DetailRow(label: "Full ID", value: model.id)
                DetailRow(label: "Version", value: model.version)
                if let tier = model.tier { DetailRow(label: "Tier", value: tier) }
                DetailRow(label: "Owner", value: model.owner)
                DetailRow(label: "Created (Placeholder)", value: model.createdDate.formatted(date: .long, time: .shortened))
            }
            
            Section("Description") {
                Text(model.detailedDescription)
            }
            
            // Use capabilities section from OpenAI example, adapt if needed
            if !model.capabilities.isEmpty {
                Section("Capabilities / Use Cases") {
                    WrappingHStack(items: model.capabilities) { capability in
                        Text(capability)
                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor).clipShape(Capsule())
                    }
                }
            }
            
            if !model.inputTypes.isEmpty {
                Section("Input Types") {
                    WrappingHStack(items: model.inputTypes) { type in
                        Label(type.capitalized, systemImage: inputTypeIcon(type))
                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Link Section
            if let url = model.rateLimitLink {
                Section("Links") {
                    Link(destination: url) { Label("Rate Limits / More Info", systemImage: "link") }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(model.name) // Use shorter name for title
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper function for icon based on input type
    private func inputTypeIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "text": return "doc.text.fill"
        case "audio": return "waveform"
        case "images", "image": return "photo.fill"
        case "video": return "video.fill"
        default: return "questionmark.circle"
        }
    }
    
    private func DetailRow(label: String, value: String) -> some View { /* ... Unchanged ... */
        HStack {
            Text(label).font(.callout).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Main Content View (Gemini Adapted)

struct GeminiModelsMasterView: View {
    // --- State Variables ---
    @State private var allModels: [GeminiModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var useMockData = true // Default to Mock
    @State private var showingApiKeySheet = false
    @State private var currentSortOrder: SortOption = .dateNewest // Default sort
    @AppStorage("userGoogleApiKey") private var storedApiKey: String = "" // Use Google key storage
    
    // --- API Service Instance ---
    private var currentApiService: APIServiceProtocol {
        useMockData ? MockAPIService() : LiveAPIService()
    }
    
    // --- Computed Properties for Filtering and Sorting ---
    var featuredModels: [GeminiModel] {
        allModels.filter { $0.category == .featured }.sorted(by: sortComparator)
    }
    
    var nonFeaturedModelsByCategory: [(GeminiModelCategory, [GeminiModel])] {
        let grouped = Dictionary(grouping: allModels.filter { $0.category != .featured }, by: { $0.category })
        return grouped.map { (key: $0.key, value: $0.value.sorted(by: sortComparator)) }
            .sorted { $0.0 < $1.0 } // Sort sections by category order
    }
    
    var sortComparator: (GeminiModel, GeminiModel) -> Bool {
        switch currentSortOrder {
        case .nameAscending: return { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending: return { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .dateNewest: return { $0.created > $1.created } // Higher timestamp = newer
        case .dateOldest: return { $0.created < $1.created }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // --- Conditional Content Display ---
                if isLoading && allModels.isEmpty {
                    ProgressView("Fetching Models...").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemBackground)).zIndex(1)
                } else if let errorMessage = errorMessage, allModels.isEmpty {
                    ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
                } else {
                    // --- Main List Content (Using List for better structure) ---
                    List {
                        // --- Header Section ---
                        Section {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Gemini models")
                                    .font(.largeTitle.weight(.bold))
                                // Subtitle removed to better match screenshot look
                            }
                            .listRowInsets(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5)) // Adjusted padding
                            
                            Button {
                                print("Feedback action triggered") // Placeholder action
                            } label: {
                                Text("Send feedback")
                                    .font(.callout)
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity, alignment: .trailing) // Align right
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 5))
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        
                        // --- Featured Models Section (Horizontal Scroll in List) ---
                        if !featuredModels.isEmpty {
                            Section {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(featuredModels) { model in
                                            NavigationLink(value: model) {
                                                FeaturedModelCardGemini(model: model)
                                                    .frame(width: 300) // Adjust width as needed
                                            }
                                            .buttonStyle(.plain) // Remove link styling
                                        }
                                    }
                                    .padding(.horizontal, 5) // Padding inside scroll view
                                    .padding(.vertical, 10)
                                }
                                .listRowInsets(EdgeInsets()) // Remove list default padding
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear) // Make background clear for the scrollview section
                        }
                        
                        // --- Other Models Grouped by Category ---
                        ForEach(nonFeaturedModelsByCategory, id: \.0) { category, models in
                            // Use Section with header for each category
                            Section {
                                ForEach(models) { model in
                                    NavigationLink(value: model) {
                                        StandardModelRowGemini(model: model)
                                    }
                                }
                            } header: {
                                // Use plain text header matching screenshot 2 style
                                Text(category.rawValue)
                                    .font(.headline) // Example Styling
                                    .padding(.vertical, 5)
                            }
                            // .headerProminence(.increased) // Optional: Make header more prominent
                        }
                    } // End List
                    .listStyle(.plain) // Use plain style to mimic screenshot look
                    // .background(Color(.systemBackground)) // Background color
                }
            } // End ZStack
            // --- Navigation Bar Setup ---
            .navigationTitle("Gemini Models") // Set title, but hide it below
            .navigationBarTitleDisplayMode(.inline) // Use inline but keep it hidden
            .toolbar {
                // --- Sort Menu ---
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort By", selection: $currentSortOrder) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                    }
                    .disabled(isLoading)
                }
                // --- API Source Toggle ---
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Toggle(isOn: $useMockData) {
                            Text(useMockData ? "Using Mock Data" : "Using Live API")
                        }
                    } label: {
                        Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill")
                            .foregroundColor(useMockData ? .secondary : .blue) // Use Gemini colors?
                    }
                    .disabled(isLoading)
                }
                // --- Refresh Button (Optional - List has pull-to-refresh) ---
                //                 ToolbarItem(placement: .navigationBarTrailing) {
                //                      if isLoading { ProgressView().controlSize(.small) }
                //                      else { Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") } }
                //                 }
            }
            // --- Navigation Destination ---
            .navigationDestination(for: GeminiModel.self) { model in
                // Use the adapted detail view
                ModelDetailViewGemini(model: model)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
            }
            // --- Initial Load & API Key Handling ---
            .task { if allModels.isEmpty { attemptLoadModels() } }
            .refreshable { await loadModelsAsync(checkApiKey: false) } // Support pull-to-refresh
            .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
            .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
            // --- Error Alert ---
            .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: {
                Button("OK") { errorMessage = nil }
            }, message: { Text(errorMessage ?? "An unknown error occurred.") })
        } // End NavigationStack
    }
    
    // --- Helper Functions for Loading & API Key Handling ---
    private func handleToggleChange(to newValue: Bool) {
        print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
        allModels = []
        errorMessage = nil
        if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showingApiKeySheet = true // Prompt for key if switching to Live and key is missing
        } else {
            loadModelsAsyncWithLoadingState() // Load immediately if Mock or key exists
        }
    }
    
    private func presentApiKeySheet() -> some View {
        // Use the Gemini-specific API Key view
        APIKeyInputViewGemini(
            onSave: { _ in print("Google API Key saved."); loadModelsAsyncWithLoadingState() },
            onCancel: { print("Google API Key input cancelled."); useMockData = true } // Revert toggle
        )
    }
    
    private func attemptLoadModels() {
        guard !isLoading else { return }
        // Check if Live API is selected AND key is missing before prompting
        if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showingApiKeySheet = true
        } else {
            loadModelsAsyncWithLoadingState() // Proceed with loading
        }
    }
    
    private func loadModelsAsyncWithLoadingState() {
        guard !isLoading else { return }
        isLoading = true
        // Run the async load within a Task
        Task { await loadModelsAsync(checkApiKey: false) } // Don't need initial check here as it's handled before calling
    }
    
    @MainActor
    private func loadModelsAsync(checkApiKey: Bool) async {
        if !isLoading { isLoading = true } // Double-check loading state
        // This specific check is less relevant now with the sheet logic handling it upfront
        // if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        //     showingApiKeySheet = true; isLoading = false; return
        // }
        let serviceToUse = currentApiService
        print("🔄 Loading models using \(useMockData ? "MockAPIService (Gemini)" : "LiveAPIService (Gemini)")...")
        do {
            let fetchedModels = try await serviceToUse.fetchModels()
            self.allModels = fetchedModels // Sort happens in computed properties
            self.errorMessage = nil
            print("✅ Successfully loaded \(fetchedModels.count) Gemini models.")
        } catch let error as LocalizedError {
            print("❌ Error loading Gemini models: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            if allModels.isEmpty { self.allModels = [] } // Clear models on error if list was empty
        } catch {
            print("❌ Unexpected error loading Gemini models: \(error)")
            self.errorMessage = "Unexpected error: \(error.localizedDescription)"
            if allModels.isEmpty { self.allModels = [] }
        }
        isLoading = false
    }
}

// MARK: - Previews

#Preview("Gemini Main View (Mock)") {
    GeminiModelsMasterView()
}

#Preview("Gemini Featured Card") {
    let model = GeminiModel(id: "gemini-2.5-pro", name: "2.5 Pro", version: "2.5", tier: "Pro", created: Int(Date().timeIntervalSince1970), shortDescription: "Our most powerful thinking model.", detailedDescription: "Maximum response accuracy and state-of-the-art performance", capabilities: ["Tackle difficult problems", "Best for complex coding"])
    return FeaturedModelCardGemini(model: model)
        .padding().frame(width: 320)
}

#Preview("Gemini Standard Row") {
    let model = GeminiModel(id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", version: "1.5", tier: "Pro", created: 1, isPreview: false)
    return StandardModelRowGemini(model: model)
        .padding()
}

#Preview("Gemini Detail View") {
    let model = GeminiModel(id: "gemini-2.5-flash", name: "2.5 Flash", version: "2.5", tier: "Flash", created: Int(Date().timeIntervalSince1970), shortDescription: "Best model for price-performance.", detailedDescription: "Offering well-rounded capabilities for high volume tasks.", capabilities: ["Model thinks as needed", "Best for low latency"], inputTypes: ["audio", "image", "video", "text"])
    return NavigationStack { ModelDetailViewGemini(model: model) }
}

#Preview("Gemini API Key Sheet") {
    struct SheetPresenter: View {
        @State var showSheet = true
        var body: some View {
            Text("Preview").sheet(isPresented: $showSheet) {
                APIKeyInputViewGemini(onSave: {_ in}, onCancel: {})
            }
        }
    }
    return SheetPresenter()
}
