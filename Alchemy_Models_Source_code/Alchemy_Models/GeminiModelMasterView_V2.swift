//
//  GeminiModelMasterView_V2.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  GeminiModelsMasterView.swift
//  Alchemy_Models_Combined
//  (Single File Implementation for Google Gemini - Updated with Table Data)
//
//  Created: Cong Le
//  Date: 4/13/25 (Adapted from OpenAI version, Updated 4/13/25)
//  Version: 1.1 (Gemini Adaptation - Table Data Update)
//  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
//  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
//
//  Disclaimer: This adaptation uses mock data based primarily on the provided
//  table screenshot. A live implementation would require the actual Google AI Gemini
//  API endpoint and response structure. API key handling is kept as a placeholder.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Enums (Sorting, Errors) - Unchanged
enum SortOption: String, CaseIterable, Identifiable { /* ... */
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

// MARK: - API Service Protocol - Unchanged
protocol APIServiceProtocol {
    func fetchModels() async throws -> [GeminiModel]
}

// MARK: - Data Models (Updated for Table Data)

enum GeminiModelCategory: String, CaseIterable, Comparable { /* ... */
    case featured = "Featured"
    case generative = "Generative"
    case vision = "Vision"
    case embedding = "Embedding"
    case experimental = "Experimental"
    case other = "Other"
    static func < (lhs: GeminiModelCategory, rhs: GeminiModelCategory) -> Bool {
        let order: [GeminiModelCategory] = [.featured, .generative, .vision, .embedding, .experimental, .other]
        return (order.firstIndex(of: lhs) ?? 99) < (order.firstIndex(of: rhs) ?? 99)
    }
}

// --- String Parsing Helper ---
func parseIOSet(from input: String) -> [String] {
    input.split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        .map { $0.replacingOccurrences(of: "and ", with: "") } // Remove "and " prefix if present
        .map { $0.components(separatedBy: CharacterSet(charactersIn: "()"))[0].trimmingCharacters(in: .whitespaces) } // Remove "(experimental)", "(coming soon)" etc.
        .filter { !$0.isEmpty } // Remove empty strings if any artifacts left
}

struct GeminiModel: Codable, Identifiable, Hashable {
    let id: String // e.g., "gemini-2.5-flash-preview-04-17"
    var name: String // e.g., "Gemini 2.5 Flash Preview 04-17"
    var version: String // e.g., "2.5" - Often inferred
    var tier: String? // e.g., "Pro", "Flash" - Often inferred
    var owner: String = "google"
    var created: Int // Placeholder Unix timestamp for sorting
    
    // Flags inferred from name/ID
    var isPreview: Bool = false
    var isExperimental: Bool = false // Check if ID contains "-exp" or name mentions experimental
    var isLive: Bool = false // Check if ID contains "-live"
    
    // Data from Table Screenshot
    var inputTypes: [String] = ["text"]
    var outputTypes: [String] = ["text"]
    var optimizedFor: String = "General purpose tasks."
    
    // Optional/Less structured data
    var rateLimitLink: URL? = nil // Optional
    var shortDescription: String = "Google AI model." // Typically derived from optimizedFor
    var detailedDescription: String = "No detailed description available." // Can be same as short or more elaborate
    var capabilities: [String] = [] // Less used now, 'optimizedFor' is primary
    
    // --- Computed Meta Properties ---
    var category: GeminiModelCategory {
        let lowerId = id.lowercased()
        // Define Featured based on the most prominent models maybe? Or keep dynamic?
        if ["gemini-2.5-pro-preview-03-25"].contains(lowerId) { return .featured } // Example: Make latest Pro preview featured
        if lowerId.contains("imagen") || lowerId.contains("veo") { return .vision }
        if lowerId.contains("embedding") { return .embedding }
        if lowerId.contains("gemini") { return .generative } // Broad category
        if lowerId.contains("exp") || isExperimental { return .experimental }
        if lowerId.contains("aqa") { return .other } // If AQA model existed
        return .other
    }
    
    // --- Codable - Synthesized is fine for Mock ---
    
    // --- Identifiable & Hashable ---
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: GeminiModel, rhs: GeminiModel) -> Bool { lhs.id == rhs.id }
    
    // --- Computed Properties for UI ---
    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
    
    // --- SF Symbol ---
    var iconName: String {
        let lowerId = id.lowercased()
        if lowerId.contains("pro") { return "star.leadinghalf.filled" } // More distinct Pro
        if lowerId.contains("flash") { return "bolt.fill" }
        if lowerId.contains("imagen") { return "photo.on.rectangle.angled" }
        if lowerId.contains("veo") { return "video.square.fill" } // Square variant
        if lowerId.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" }
        if isLive { return "antenna.radiowaves.left.and.right.circle.fill" } // Icon for live
        if isPreview { return "eye.fill" } // Icon for preview
        if isExperimental { return "testtube.2" } // Icon for experimental
        return "brain.head.profile" // Default
    }
    
    // --- Background Color ---
    var iconBackgroundColor: Color {
        switch category {
        case .featured: return .indigo
        case .generative: return .teal
        case .vision: return .orange
        case .embedding: return .green
        case .experimental: return .pink
        case .other: return .brown
        }
    }
}

// MARK: - API Service Implementations (Mock Updated)

// --- Mock Data Service (Updated from Table Screenshot) ---
class MockAPIService: APIServiceProtocol {
    private let mockNetworkDelaySeconds: Double = 0.5
    
    private func generateMockGeminiModels() -> [GeminiModel] {
        // Create placeholder timestamps in reverse order of the table (roughly newest first)
        let now = Date()
        let baseTimestamp = Int(now.timeIntervalSince1970)
        var currentTimestamp = baseTimestamp
        
        func nextTs() -> Int {
            currentTimestamp -= 500_000 // Decrement for rough chronological order
            return currentTimestamp
        }
        
        let modelData: [(id: String, name: String, inputs: String, outputs: String, optimized: String)] = [
            // Data directly extracted from the screenshot table
            ("gemini-2.5-flash-preview-04-17", "Gemini 2.5 Flash Preview 04-17", "Audio, images, videos, and text", "Text", "Adaptive thinking, cost efficiency"),
            ("gemini-2.5-pro-preview-03-25", "Gemini 2.5 Pro Preview", "Audio, images, videos, and text", "Text", "Enhanced thinking and reasoning, multimodal understanding, advanced coding, and more"),
            ("gemini-2.0-flash", "Gemini 2.0 Flash", "Audio, images, videos, and text", "Text, images (experimental), and audio (coming soon)", "Next generation features, speed, thinking, realtime streaming, and multimodal generation"),
            ("gemini-2.0-flash-lite", "Gemini 2.0 Flash-Lite", "Audio, images, videos, and text", "Text", "Cost efficiency and low latency"),
            ("gemini-1.5-flash", "Gemini 1.5 Flash", "Audio, images, videos, and text", "Text", "Fast and versatile performance across a diverse variety of tasks"),
            ("gemini-1.5-flash-8b", "Gemini 1.5 Flash-8B", "Audio, images, videos, and text", "Text", "High volume and lower intelligence tasks"),
            ("gemini-1.5-pro", "Gemini 1.5 Pro", "Audio, images, videos, and text", "Text", "Complex reasoning tasks requiring more intelligence"),
            ("gemini-embedding-exp", "Gemini Embedding", "Text", "Text embeddings", "Measuring the relatedness of text strings"), // Assuming -exp ID
            ("imagen-3.0-generate-002", "Imagen 3", "Text", "Images", "Our most advanced image generation model"),
            ("veo-2.0-generate-001", "Veo 2", "Text, images", "Video", "High quality video generation"),
            ("gemini-2.0-flash-live-001", "Gemini 2.0 Flash Live", "Audio, video, and text", "Text, audio", "Low-latency bidirectional voice and video interactions"),
        ]
        
        return modelData.map { data in
            let inputTypes = parseIOSet(from: data.inputs)
            let outputTypes = parseIOSet(from: data.outputs)
            let isPreview = data.name.lowercased().contains("preview")
            let isExperimental = data.id.lowercased().contains("-exp")
            let isLive = data.id.lowercased().contains("-live")
            
            // Infer version/tier (best effort)
            var version = "N/A"
            var tier: String? = nil
            let nameParts = data.name.split(separator: " ")
            if let vIndex = nameParts.firstIndex(where: { $0.range(of: "\\d+\\.\\d+", options: .regularExpression) != nil }) {
                version = String(nameParts[vIndex])
            }
            if data.name.lowercased().contains("pro") { tier = "Pro" }
            else if data.name.lowercased().contains("flash") { tier = "Flash" }
            else if data.name.lowercased().contains("lite") { tier = "Flash-Lite" }
            else if data.name.lowercased().contains("8b") { tier = "Flash-8B" }
            
            return GeminiModel(
                id: data.id,
                name: data.name,
                version: version,
                tier: tier,
                created: nextTs(), // Assign chronologically decreasing timestamp
                isPreview: isPreview,
                isExperimental: isExperimental,
                isLive: isLive,
                inputTypes: inputTypes,
                outputTypes: outputTypes,
                optimizedFor: data.optimized,
                shortDescription: data.optimized, // Use optimizedFor text directly
                detailedDescription: data.optimized // Can be same or more detailed if available elsewhere
                // capabilities: [] // Intentionally empty as optimizedFor is better here
            )
        }
    }
    
    func fetchModels() async throws -> [GeminiModel] {
        try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
        return generateMockGeminiModels()
        // throw MockError.simulatedFetchError // Uncomment to test error state
    }
}

// --- Live Data Service (Placeholder - Mapping Comments Updated) ---
class LiveAPIService: APIServiceProtocol { /* ... */
    @AppStorage("userGoogleApiKey") private var storedApiKey: String = ""
    private let modelsURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models")! // EXAMPLE URL
    
    func fetchModels() async throws -> [GeminiModel] { /* ... */
        let currentKey = storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentKey.isEmpty else { throw LiveAPIError.missingAPIKey }
        
        var request = URLRequest(url: modelsURL)
        /* ... request setup ... */
        request.setValue(currentKey, forHTTPHeaderField: "x-goog-api-key") // Example
        
        print("🚀 Making live API request to Google Gemini: \(modelsURL)")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw LiveAPIError.requestFailed(statusCode: 0) }
            /* ... status code checks ... */
            print("✅ Received Google API response with status code: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw LiveAPIError.missingAPIKey }
            guard (200...299).contains(httpResponse.statusCode) else { throw LiveAPIError.requestFailed(statusCode: httpResponse.statusCode) }
            
            // --- Define Google's expected Response Structure ---
            struct GoogleModelListResponse: Codable { let models: [GoogleAPIModelFormat] }
            struct GoogleAPIModelFormat: Codable {
                let name: String // Often like "models/gemini-1.5-pro-latest" - NEED TO PARSE ID from this
                let version: String?
                let displayName: String? // e.g., "Gemini 1.5 Pro"
                let description: String?
                // --- Google's specific fields for I/O ---
                let supportedGenerationMethods: [String]? // e.g., ["generateContent", "embedContent"] -> Helps determine Output
                let inputTokenLimit: Int? // Example metadata
                let outputTokenLimit: Int?
                // Other relevant fields? e.g., supported content types, safety settings...
                // IMPORTANT: Need to know how Google represents input/output types (likely structured, not free text)
            }
            
            do {
                let decoder = JSONDecoder()
                let responseWrapper = try decoder.decode(GoogleModelListResponse.self, from: data)
                print("✅ Successfully decoded \(responseWrapper.models.count) Google models.")
                
                // --- MAP GoogleAPIModelFormat to our GeminiModel ---
                // This mapping requires knowing the actual Google API response structure
                return responseWrapper.models.map { apiModel -> GeminiModel in
                    // --- Parsing Google's 'name' field to get the ID ---
                    let modelId = apiModel.name.split(separator: "/").last.map(String.init) ?? apiModel.name
                    
                    // --- Determine other fields ---
                    let modelName = apiModel.displayName ?? modelId // Use ID as fallback name
                    let modelVersion = apiModel.version ?? "N/A"
                    let description = apiModel.description ?? "No description provided by API."
                    let createdTimestamp = Int(Date().timeIntervalSince1970) // Placeholder
                    
                    // --- Map Input/Output types (Requires knowledge of Google API structure) ---
                    // Example: This is a GUESS based on potential fields
                    var inputTypes: [String] = ["text"] // Default
                    var outputTypes: [String] = ["text"] // Default
                    if let methods = apiModel.supportedGenerationMethods {
                        if methods.contains("embedContent") { outputTypes.append("embedding") }
                        // Inferring capabilities based on methods/description might be needed
                    }
                    // How Google specifies multimodal inputs (images, audio, video) needs to be determined
                    
                    // --- Infer flags ---
                    let isPreview = modelName.lowercased().contains("preview")
                    let isExperimental = modelId.lowercased().contains("-exp") || modelName.lowercased().contains("experimental")
                    let isLive = modelId.lowercased().contains("-live")
                    
                    // --- Tier inference (similar to mock) ---
                    var tier: String? = nil
                    if modelName.lowercased().contains("pro") { tier = "Pro" }
                    else if modelName.lowercased().contains("flash") { tier = "Flash" }
                    // ... etc ...
                    
                    return GeminiModel(
                        id: modelId,
                        name: modelName,
                        version: modelVersion,
                        tier: tier,
                        created: createdTimestamp,
                        isPreview: isPreview,
                        isExperimental: isExperimental,
                        isLive: isLive,
                        inputTypes: inputTypes, // Placeholder mapping
                        outputTypes: outputTypes, // Placeholder mapping
                        optimizedFor: description, // Using API description as "Optimized For"
                        shortDescription: description,
                        detailedDescription: description
                        // rateLimitLink: // Construct if possible from Google docs or API response
                    )
                }
                
                // Original Placeholder:
                // print("⚠️ Live API decoding needs actual Google Response structure - returning empty array.")
                // return []
                
            } catch { /* ... decoding error handling ... */
                print("❌ Decoding Error (Google API): \(error)")
                print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Could not decode data")")
                throw LiveAPIError.decodingError(error)
            }
        } catch let error as LiveAPIError { throw error }
        catch { throw LiveAPIError.networkError(error) }
    }
}

// MARK: - Reusable SwiftUI Helper Views (Error, WrappingHStack, APIKeyInputView) - Unchanged

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

// MARK: - Model Views (Featured Card, Detail View Updated)

// --- Featured Model Card View (Updated for 'optimizedFor') ---
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
    
    //    var body: some View {
    //        VStack(alignment: .leading, spacing: 10) { // Reduced spacing slightly
    //            // Header: Icon and Name
    //            HStack { /* ... Icon ... */
    //                 Image(systemName: model.iconName).font(.title2).frame(width: 30, height: 30)
    //                     .foregroundStyle(model.iconBackgroundColor)
    //                 Text(model.name).font(.title3.weight(.semibold))
    //                 Spacer()
    //                 if model.isPreview {
    //                      Text("Preview").font(.caption2.bold()).foregroundColor(.orange).padding(.horizontal, 6).padding(.vertical, 2).background(Color.orange.opacity(0.15)).clipShape(Capsule())
    //                  }
    //             }
    //
    //            // Display "Optimized For" Text
    //            Text(model.optimizedFor)
    //                .font(.callout)
    //                .foregroundColor(.secondary)
    //                .lineLimit(3) // Allow enough lines for the description
    //                .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
    //
    //            Spacer() // Pushes content up
    //
    //            // Input/Output Summary (Optional, uncomment if desired)
    //            /*
    //            HStack {
    //                WrappingHStack(items: model.inputTypes.prefix(2)) { type in // Show max 2 inputs
    //                    Text(type.capitalized).font(.caption2).padding(3).background(.gray.opacity(0.1)).clipShape(Capsule())
    //                }
    //                Spacer()
    //                WrappingHStack(items: model.outputTypes.prefix(2)) { type in // Show max 2 outputs
    //                     Text(type.capitalized).font(.caption2).padding(3).background(.gray.opacity(0.1)).clipShape(Capsule())
    //                }
    //            }
    //            .foregroundColor(.secondary)
    //            */
    //
    //        }
    //        .padding()
    //        .frame(maxWidth: .infinity, minHeight: 180, idealHeight: 200) // Adjusted height
    //        .background(.regularMaterial)
    //        .clipShape(RoundedRectangle(cornerRadius: 12))
    //        .overlay( /* ... */ )
    //    }
}


// --- Standard Model Row View (Minor updates for flags) ---
struct StandardModelRowGemini: View {
    let model: GeminiModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Use a consistent icon or model-specific one
            Image(systemName: model.iconName)
                .foregroundColor(model.iconBackgroundColor) // Color the icon
            
            Text(model.name).font(.body)
            
            // --- Flags ---
            if model.isPreview { flagCapsule("Preview", color: .orange) }
            if model.isLive { flagCapsule("Live", color: .green) }
            if model.isExperimental { flagCapsule("Exp", color: .pink) }
            
            Spacer()
            if model.rateLimitLink != nil { /* ... Link Icon ... */ }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func flagCapsule(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
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

// --- Model Detail View (Updated for new fields) ---
struct ModelDetailViewGemini: View {
    let model: GeminiModel
    
    var body: some View {
        List {
            // --- Top Section ---
            Section { /* ... Icon, Name, Short Description, Preview Flag ... */
                VStack(spacing: 15) {
                    Image(systemName: model.iconName).resizable().scaledToFit().padding(15).frame(width: 80, height: 80)
                        .background(model.iconBackgroundColor.opacity(0.2)).foregroundColor(model.iconBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Text(model.name).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                    // Use optimizedFor as the main description here if shortDescription is derived from it
                    Text(model.shortDescription).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center)
                    // Use helper for flags
                    HStack {
                        if model.isPreview { flagCapsule("Preview", color: .orange) }
                        if model.isLive { flagCapsule("Live", color: .green) }
                        if model.isExperimental { flagCapsule("Experimental", color: .pink) }
                    }
                }.frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
            }.listRowBackground(Color.clear)
            
            // --- Overview Section (Added Optimized For) ---
            Section("Overview") {
                DetailRow(label: "Full ID", value: model.id)
                DetailRow(label: "Version", value: model.version)
                if let tier = model.tier { DetailRow(label: "Tier", value: tier) }
                // Display Optimized For prominently
                VStack(alignment: .leading, spacing: 4) { // Use VStack for multi-line value
                    Text("Optimized For").font(.callout).foregroundColor(.secondary)
                    Text(model.optimizedFor).font(.body).foregroundColor(.primary)
                }.padding(.vertical, 2)
                DetailRow(label: "Owner", value: model.owner)
                DetailRow(label: "Created (Mock)", value: model.createdDate.formatted(date: .long, time: .shortened))
            }
            
            // --- Detailed Description (Optional) ---
            Section("Detailed Description") { Text(model.detailedDescription) }
            
            // --- Input Types ---
            if !model.inputTypes.isEmpty {
                Section("Input Types") {
                    WrappingHStack(items: model.inputTypes) { type in tagView(type, icon: inputOutputTypeIcon(type)) }
                }
            }
            
            // --- Output Types ---
            if !model.outputTypes.isEmpty {
                Section("Output Types") {
                    WrappingHStack(items: model.outputTypes) { type in tagView(type, icon: inputOutputTypeIcon(type)) }
                }
            }
            
            // --- Capabilities (Only shown if populated) ---
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
            
            //            if !model.inputTypes.isEmpty {
            //                Section("Input Types") {
            //                    WrappingHStack(items: model.inputTypes) { type in
            //                        Label(type.capitalized, systemImage: inputTypeIcon(type))
            //                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
            //                            .background(Color.gray.opacity(0.15))
            //                            .clipShape(Capsule())
            //                    }
            //                }
            //            }
            
            // --- Links Section ---
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
}

// --- Helper for Input/Output Type Icons ---
private func inputOutputTypeIcon(_ type: String) -> String {
    switch type.lowercased() {
    case "text": return "doc.text.fill"
    case "audio": return "waveform"
    case "images", "image": return "photo.fill"
    case "video": return "video.fill"
    case "embedding", "embeddings": return "arrow.down.right.and.arrow.up.left.circle.fill"
    default: return "questionmark.circle"
    }
}

// --- Helper for Detail Row (Unchanged) ---
private func DetailRow(label: String, value: String) -> some View { /* ... Unchanged ... */
    HStack {
        Text(label).font(.callout).foregroundColor(.secondary)
        Spacer()
        Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
}

// --- Reusable Flag Capsule ---
@ViewBuilder
private func flagCapsule(_ text: String, color: Color) -> some View { /* Duplicate from Row view, consider placing in a shared location */
    Text(text)
        .font(.caption.weight(.medium)).foregroundColor(color)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(color.opacity(0.15)).clipShape(Capsule())
}

// --- Reusable Tag View for I/O Types ---
@ViewBuilder
private func tagView(_ text: String, icon: String) -> some View {
    Label(text.capitalized, systemImage: icon)
        .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.gray.opacity(0.15))
        .clipShape(Capsule())
}


// MARK: - Main Content View - Largely Unchanged Logic, UI updates cascade

struct GeminiModelsMasterView: View {
    // --- State Variables & API Service Setup ---
    @State private var allModels: [GeminiModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var useMockData = true
    @State private var showingApiKeySheet = false
    @State private var currentSortOrder: SortOption = .dateNewest
    @AppStorage("userGoogleApiKey") private var storedApiKey: String = ""
    
    private var currentApiService: APIServiceProtocol {
        useMockData ? MockAPIService() : LiveAPIService()
    }
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
                // Conditional Content (Loading/Error/List)
                if isLoading && allModels.isEmpty { /* ... ProgressView ... */ }
                else if let errorMessage = errorMessage,
                        allModels.isEmpty {
                    ErrorView(errorMessage: errorMessage) {
                        attemptLoadModels()
                    }
                }
                else {
                    // --- Main List Content ---
                    List {
                        // Header Section (Unchanged)
                        Section { /* ... Title, Feedback Button ... */ }
                            .listRowSeparator(.hidden).listRowBackground(Color.clear)
                        
                        // Featured Models Section (Horizontal Scroll - UI updated via FeaturedModelCardGemini)
                        if !featuredModels.isEmpty {
                            Section { /* ... Horizontal ScrollView ... */
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(featuredModels) { model in
                                            NavigationLink(value: model) {
                                                FeaturedModelCardGemini(model: model) // Updated Card
                                                    .frame(width: 300)
                                            }.buttonStyle(.plain)
                                        }
                                    }.padding(.horizontal, 5).padding(.vertical, 10)
                                }.listRowInsets(EdgeInsets())
                            }
                            .listRowSeparator(.hidden).listRowBackground(Color.clear)
                        }
                        
                        // Other Models Grouped by Category (UI updated via StandardModelRowGemini)
                        ForEach(nonFeaturedModelsByCategory, id: \.0) { category, models in
                            Section {
                                ForEach(models) { model in
                                    NavigationLink(value: model) {
                                        StandardModelRowGemini(model: model) // Updated Row
                                    }
                                }
                            } header: { /* ... Category Header ... */ }
                        }
                    } // End List
                    .listStyle(.plain)
                } // End Conditional Content
            } // End ZStack
            .navigationTitle("Gemini Models") // Keep title for accessibility
            .navigationBarTitleDisplayMode(.inline) // But hide inline
            .toolbar { /* ... Sort, API Source Toggle ... */ }
            .navigationDestination(for: GeminiModel.self) { model in
                ModelDetailViewGemini(model: model) // Updated Detail View
                /* ... Toolbar background setup ... */
            }
            // --- Data Loading / Sheet / Alert Logic (Unchanged) ---
            .task { if allModels.isEmpty { attemptLoadModels() } }
            .refreshable { await loadModelsAsync(checkApiKey: false) }
            .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
            .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
            .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: { /* ... */ }, message: { /* ... */ })
        } // End NavigationStack
    }
    
    // --- Helper Functions for Loading & API Key Handling (Unchanged Logic) ---
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

// MARK: - Previews (Updated with new Mock Data)

#Preview("Gemini Main View (Table Mock)") {
    EmptyView()
    //    GeminiModelsMasterView()
}

//#Preview("Gemini Featured Card (Table Mock)") {
//    // Find a model from the new mock data (e.g., 2.5 Pro Preview)
//    let mockService = MockAPIService()
//    let previewModel = try! await mockService.fetchModels().first { $0.id == "gemini-2.5-pro-preview-03-25" } ?? GeminiModel(id: "preview-placeholder", name: "Preview", version: "1.0", created: 1, optimizedFor: "Example Optimization")
//    FeaturedModelCardGemini(model: previewModel)
//        .padding().frame(width: 320)
//}

//#Preview("Gemini Standard Row (Table Mock)") {
//    let mockService = MockAPIService()
//    let previewModel = try! await mockService.fetchModels().first { $0.id == "gemini-1.5-flash-8b" } ?? GeminiModel(id: "row-placeholder", name: "Row", version: "1.0", created: 1)
//    StandardModelRowGemini(model: previewModel)
//        .padding().previewLayout(.sizeThatFits)
//}

//#Preview("Gemini Detail View (Table Mock)") {
//    let mockService = MockAPIService()
//    let previewModel = try! await mockService.fetchModels().first { $0.id == "gemini-2.0-flash" } ?? GeminiModel(id: "detail-placeholder", name: "Detail", version: "1.0", created: 1, inputTypes: ["text", "audio"], outputTypes: ["text", "image"], optimizedFor: "Complex multi-turn conversations.")
//    NavigationStack { ModelDetailViewGemini(model: previewModel) }
//}


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
