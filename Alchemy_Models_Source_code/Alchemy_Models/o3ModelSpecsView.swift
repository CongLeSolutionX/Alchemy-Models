//
//  o3ModelSpecsView.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

import SwiftUI
import Foundation // Needed for URLSession, URLRequest, Date, etc.

// MARK: - Enums

// Enum for Sorting Options
enum SortOption: String, CaseIterable, Identifiable {
    case idAscending = "ID (A-Z)"
    case idDescending = "ID (Z-A)"
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"

    var id: String { self.rawValue } // For Identifiable conformance
}

// Optional: Define mock errors if needed
enum MockError: Error, LocalizedError {
     case simulatedFetchError
     var errorDescription: String? {
         switch self {
         case .simulatedFetchError:
             return "Simulated network error: Could not fetch models."
         }
     }
}

// Errors specific to the Live API Service
enum LiveAPIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The API endpoint URL is invalid."
        case .requestFailed(let statusCode): return "API request failed with status code \(statusCode)."
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError(let error): return "Failed to decode API response: \(error.localizedDescription)"
        case .missingAPIKey: return "OpenAI API Key is missing or invalid. Please provide a valid key."
        }
    }
}

// MARK: - API Service Protocol

protocol APIServiceProtocol {
    func fetchModels() async throws -> [OpenAIModel]
}

// MARK: - Data Models

struct ModelListResponse: Codable {
    let data: [OpenAIModel]
}

// ----- Rate Limit Structure -----
struct RateLimitTier: Codable, Hashable {
    let tier: String? // e.g., "Tier 5"
    let rpm: Int?     // Requests Per Minute
    let rpd: String?  // Requests Per Day (Using String as it can be '-' or a number)
    let tpm: Int?     // Tokens Per Minute
    let batchQueueLimit: Int?
}

// ----- Main Model Structure -----
struct OpenAIModel: Codable, Identifiable, Hashable {
    // ---- Core Properties (from Basic /v1/models) ----
    let id: String
    let object: String
    let created: Int // Unix timestamp
    let ownedBy: String

    // ---- Extended Properties (Optional - populated from mock/details) ----
    // These might not be present in the basic /v1/models response,
    // so they have default values or are optional. Codable ignores them
    // if they are not in CodingKeys *and* not present in JSON.
    var description: String? = "No description available." // Make optional
    var capabilities: [String]? = ["general"] // Make optional
    var contextWindow: String? = "N/A"     // Make optional
    var typicalUseCases: [String]? = ["Various tasks"] // Make optional

    // ---- Properties Specific to o3 (or similar detailed models) ----
    var inputModalities: [String]? = ["Text"]   // Default assumption
    var outputModalities: [String]? = ["Text"] // Default assumption
    var contextWindowTokens: Int?
    var maxOutputTokens: Int?
    var knowledgeCutoffDate: String? // e.g., "May 31, 2024"
    var reasoningTokenSupport: Bool? = false

    // -- Pricing --
    var priceInputPerMToken: Double?
    var priceOutputPerMToken: Double?
    var priceCachedInputPerMToken: Double?

    // -- Performance Indicators --
    var reasoningRating: Int? // e.g., 1-4
    var speedRating: Int?     // e.g., 1-4

    // -- Features & Endpoints --
    var supportedEndpoints: [String]?
    var supportedFeatures: [String]?
    var unsupportedEndpoints: [String]? // Easier to list what's *not* there sometimes
    var unsupportedFeatures: [String]?

    // -- Snapshots --
    var snapshots: [String]? // e.g., ["o3-2025-04-16"]

    // -- Rate Limits --
    var rateLimits: RateLimitTier? // Use the dedicated struct

    // Conform to Codable (only include keys expected from the basic /v1/models API)
    // This ensures decoding doesn't fail if the extra fields aren't present.
    enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case ownedBy = "owned_by" // Map JSON key 'owned_by' to Swift 'ownedBy'
        // We *exclude* all the optional detailed properties here.
        // Swift's Codable synthesis will use their default values (nil or predefined)
        // if they aren't found during decoding.
    }

    // Computed property for easy date access
    var createdDate: Date {
        Date(timeIntervalSince1970: TimeInterval(created))
    }

    // Hashable conformance (based on unique ID)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: OpenAIModel, rhs: OpenAIModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Model Extension for UI

extension OpenAIModel {
    // Determine the SF Symbol name based on the owner
    var profileSymbolName: String {
        let lowerOwner = ownedBy.lowercased()
        if lowerOwner.contains("openai") { return "building.columns.fill" }
        if lowerOwner == "system" { return "gearshape.fill" }
        if lowerOwner.contains("user") || lowerOwner.contains("org") { return "person.crop.circle.fill" }
        return "questionmark.circle.fill" // Default/fallback
    }

    // Determine the background color for the profile image view
    var profileBackgroundColor: Color {
        let lowerOwner = ownedBy.lowercased()
        if lowerOwner.contains("openai") { return .blue }
        if lowerOwner == "system" { return .orange }
        if lowerOwner.contains("user") || lowerOwner.contains("org") { return .purple }
        return .gray // Default/fallback
    }
}

// MARK: - API Service Implementations

// --- Mock Data Service ---
class MockAPIService: APIServiceProtocol { // Conform to the protocol
    // Simulate network delay
    private let mockNetworkDelaySeconds: Double = 0.5

    // Predefined mock models - ADDING 'o3'
    private func generateMockModels() -> [OpenAIModel] {
        return [
            // ----- o3 Model Data (from screenshot) -----
            OpenAIModel(
                id: "o3",
                object: "model",
                created: 1713225600, // Approx timestamp for 2025-04-16 snapshot
                ownedBy: "openai",
                description: "Our most powerful reasoning model across domains. It sets a new standard for math, science, coding, and visual reasoning tasks. It also excels at technical writing and instruction-following. Use it to think through multi-step problems that involve analysis across text, code, and images.",
                capabilities: ["math", "science", "coding", "visual reasoning", "technical writing", "instruction-following", "multi-step analysis"], // Derived from description
                contextWindow: "200k tokens", // From screenshot text
                typicalUseCases: ["Complex Problem Solving", "Advanced Code Generation", "Scientific Research Analysis", "Visual Data Interpretation", "Multi-Modal Reasoning"], // Derived
                inputModalities: ["Text", "Image"],
                outputModalities: ["Text"],
                contextWindowTokens: 200_000,
                maxOutputTokens: 100_000,
                knowledgeCutoffDate: "May 31, 2024",
                reasoningTokenSupport: true,
                priceInputPerMToken: 10.00,
                priceOutputPerMToken: 40.00,
                priceCachedInputPerMToken: 2.50,
                reasoningRating: 4, // Highest
                speedRating: 1,     // Slowest
                supportedEndpoints: ["Chat Completions (/v1/chat/completions)", "Responses (/v1/responses)"],
                supportedFeatures: ["Streaming", "Structured outputs", "Function calling"],
                unsupportedEndpoints: ["Realtime", "Batch", "Embeddings", "Speech generation", "Translation", "Completions (legacy)", "Assistants", "Fine-tuning", "Image generation", "Transcription", "Moderation"],
                unsupportedFeatures: ["Distillation", "Fine-tuning", "Predicted outputs"],
                snapshots: ["o3-2025-04-16"],
                rateLimits: RateLimitTier(tier: "Tier 5", rpm: 10_000, rpd: "-", tpm: 30_000_000, batchQueueLimit: 5_000_000_000)
            ),
            // ----- Other Mock Models -----
            OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1712602800, ownedBy: "openai", description: "Highly capable GPT-4 model.", capabilities: ["text generation", "code completion", "reasoning"], contextWindow: "128k", typicalUseCases: ["Complex chat", "Content generation", "Code assistance"]),
            OpenAIModel(id: "gpt-3.5-turbo-instruct", object: "model", created: 1694022000, ownedBy: "openai", description: "Instruct-tuned version of GPT-3.5.", capabilities: ["text generation", "instruction following"], contextWindow: "4k", typicalUseCases: ["Direct instruction tasks", "Simple Q&A"]),
            OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Advanced image generation model.", capabilities: ["image generation", "text-to-image"], contextWindow: "N/A", typicalUseCases: ["Art creation", "Product visualization"]),
            OpenAIModel(id: "whisper-1", object: "model", created: 1677600000, ownedBy: "openai", description: "Speech-to-text model.", capabilities: ["audio transcription", "translation"], contextWindow: "N/A", typicalUseCases: ["Meeting transcriptions", "Voice commands"]),
            OpenAIModel(id: "babbage-002", object: "model", created: 1692902400, ownedBy: "openai", description: "Older generation model, faster but less capable.", capabilities: ["text generation"], contextWindow: "4k", typicalUseCases: ["Simple text classification", "Drafting"]),
            OpenAIModel(id: "text-embedding-3-large", object: "model", created: 1711300000, ownedBy: "openai", description: "Large text embedding model.", capabilities: ["text embedding", "semantic search"], contextWindow: "8k", typicalUseCases: ["Recommendation systems", "Clustering"]),
        ]
    }

    func fetchModels() async throws -> [OpenAIModel] {
         // Simulate network delay
         try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
         // Return the structured mock data
         return generateMockModels()
         // ---- To simulate an error uncomment below ----
         // throw MockError.simulatedFetchError
         // -------------------------------------------
    }
}

// --- Live Data Service ---
class LiveAPIService: APIServiceProtocol {

    // --- Use AppStorage for easy access to UserDefaults ---
    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""

    private let modelsURL = URL(string: "https://api.openai.com/v1/models")!

    func fetchModels() async throws -> [OpenAIModel] {
        let currentKey = storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !currentKey.isEmpty else {
            print("❌ ERROR: OpenAI API Key is missing from storage.")
            throw LiveAPIError.missingAPIKey
        }

        var request = URLRequest(url: modelsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(currentKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        print("🚀 Making live API request to: \(modelsURL) using stored key.")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LiveAPIError.requestFailed(statusCode: 0)
            }

            print("✅ Received API response with status code: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 401 {
                 print("❌ ERROR: API Key is invalid (Unauthorized - 401). Please enter a valid key.")
                 throw LiveAPIError.missingAPIKey
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                 throw LiveAPIError.requestFailed(statusCode: httpResponse.statusCode)
            }

            do {
                 let decoder = JSONDecoder()
                 let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
                 print("✅ Successfully decoded \(responseWrapper.data.count) models.")
                 // NOTE: The decoded models here will only have the basic properties
                 // defined in CodingKeys populated from the JSON. The other optional
                 // properties in OpenAIModel will remain nil or their default values.
                 return responseWrapper.data
            } catch {
                 print("❌ Decoding Error: \(error)")
                 throw LiveAPIError.decodingError(error)
            }
        } catch let error as LiveAPIError {
            print("❌ API Error: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ Network/URLSession Error: \(error)")
            throw LiveAPIError.networkError(error)
        }
    }
}

// MARK: - Reusable SwiftUI Helper Views

// --- Card View ---
struct ModelCardView: View {
    let model: OpenAIModel

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: model.profileSymbolName)
                .resizable().scaledToFit().padding(8)
                .frame(width: 44, height: 44)
                .background(model.profileBackgroundColor.opacity(0.85))
                .foregroundStyle(.white).clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(model.id).font(.headline).lineLimit(1).truncationMode(.tail)
                Text("Owner: \(model.ownedBy)").font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                Text("Created: \(model.createdDate, style: .date)").font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary.opacity(0.5))
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
}

// --- Wrapping HStack for Tags/Capabilities ---
struct WrappingHStack<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    let viewForItem: (Item) -> ItemView
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    var alignment: HorizontalAlignment = .leading // Default alignment

    @State private var totalHeight: CGFloat = .zero

    init(items: [Item],
         alignment: HorizontalAlignment = .leading, // Add alignment parameter
         horizontalSpacing: CGFloat = 8,
         verticalSpacing: CGFloat = 8,
         @ViewBuilder viewForItem: @escaping (Item) -> ItemView) {
        self.items = items
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.viewForItem = viewForItem
    }

    var body: some View {
         VStack {
             GeometryReader { geometry in
                 self.generateContent(in: geometry)
             }
         }
         .frame(height: totalHeight)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        // Store row heights to adjust alignment later if needed
        var rowHeights: [CGFloat] = [0]

        return ZStack(alignment: .topLeading) {
            ForEach(self.items, id: \.self) { item in
                self.viewForItem(item)
                    .padding(.horizontal, horizontalSpacing / 2)
                    .padding(.vertical, verticalSpacing / 2)
                    .alignmentGuide(self.alignment, computeValue: { d in
                        // Update row height tracker
                        rowHeights[rowHeights.count - 1] = max(rowHeights.last ?? 0, d.height)

                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= rowHeights[rowHeights.count - 1] + verticalSpacing // Use tracked row height
                            rowHeights.append(d.height) // Start tracking height for new row
                        }

                        let result = width
                        if item == self.items.last {
                            width = 0 // last item
                        } else {
                            width -= d.width + horizontalSpacing // Account for spacing
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if item == self.items.last {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            _ = geometry.frame(in: .local)
            DispatchQueue.main.async {
                // Add vertical spacing to the last row's height for bottom padding
                let lastRowHeight = geometry.size.height > 0 ? (geometry.size.height + verticalSpacing / 2) : 0
                binding.wrappedValue = lastRowHeight

            }
            return .clear
        }
    }
}

// --- Error View ---
struct ErrorView: View {
     let errorMessage: String
     let retryAction: () -> Void
     var body: some View {
          VStack(alignment: .center, spacing: 15) {
               Image(systemName: "wifi.exclamationmark").resizable().scaledToFit()
                  .frame(width: 60, height: 60).foregroundColor(.red)
               VStack(spacing: 5) {
                    Text("Loading Failed").font(.title3.weight(.medium))
                    Text(errorMessage).font(.callout).foregroundColor(.secondary)
                         .multilineTextAlignment(.center).padding(.horizontal)
               }
               Button { retryAction() } label: { Label("Retry", systemImage: "arrow.clockwise") }
                  .buttonStyle(.borderedProminent).controlSize(.regular).padding(.top)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity).padding()
          .background(Color(.systemGroupedBackground))
     }
}

// --- Helper for Detail Rows ---
struct DetailRow: View {
    let label: String
    let value: String? // Optional value
    let systemImage: String? // Optional icon

    init(label: String, value: String?, systemImage: String? = nil) {
        self.label = label
        self.value = value
        self.systemImage = systemImage
    }

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .center) // Align icons
                }
                Text(label)
            }
            .font(.callout)
            .foregroundColor(.secondary)

            Spacer()

            Text(value ?? "N/A") // Display N/A if value is nil
                .font(.body)
                .multilineTextAlignment(.trailing)
                .foregroundColor(value == nil ? .secondary : .primary) // Dim N/A text
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}

// --- Helper for Capability Tag ---
struct CapabilityTag: View {
    let text: String
    var backgroundColor: Color = Color.accentColor.opacity(0.15)
    var foregroundColor: Color = .accentColor

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
    }
}

// --- Helper for Rating View ---
struct RatingView: View {
    let label: String
    let systemImage: String
    let rating: Int? // Optional rating
    let maxRating: Int
    var activeColor: Color = .yellow
    var inactiveColor: Color = .gray.opacity(0.4)

    var body: some View {
         HStack {
             Text(label)
                 .font(.callout)
                 .foregroundColor(.secondary)
             Spacer()
             HStack(spacing: 3) {
                 if let rating = rating {
                     ForEach(1...maxRating, id: \.self) { index in
                         Image(systemName: systemImage)
                             .foregroundColor(index <= rating ? activeColor : inactiveColor)
                             .imageScale(.small)
                     }
                 } else {
                     Text("N/A")
                         .font(.caption)
                         .foregroundColor(.secondary)
                 }
             }
         }
         .padding(.vertical, 3)
         .accessibilityElement(children: .combine)
         .accessibilityLabel("\(label), \(rating != nil ? "\(rating ?? 0) out of \(maxRating)" : "Not Available")")
    }
}

// --- Helper for Feature/Endpoint List Item ---
struct FeatureListItem: View {
    let name: String
    let isSupported: Bool

    var body: some View {
        HStack {
            Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSupported ? .green : .red)
            Text(name)
                .foregroundColor(isSupported ? .primary : .secondary)
                .strikethrough(!isSupported, color: .secondary) // Strikethrough if not supported
            Spacer()
        }
    }
}

// MARK: - API Key Input View

struct APIKeyInputView: View {
    // Use AppStorage to directly save/read the key
    @AppStorage("userOpenAIKey") private var apiKey: String = ""

    // State for the text field input within the sheet
    @State private var inputKey: String = ""

    // State to track if the user tried saving an empty key
    @State private var isInvalidKeyAttempt: Bool = false

    let onSave: (String) -> Void // Callback when key is saved
    let onCancel: () -> Void   // Callback when cancelled

    // Environment variable to dismiss the sheet
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView { // Embed in NavigationView for Title and Buttons
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter your OpenAI API Key to access live models.")
                    .font(.headline)

                Text("Your API key will be stored securely in device UserDefaults. It will only be used to make direct requests to OpenAI from this app.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // SecureField for API Key Input
                SecureField("sk-...", text: $inputKey) // Use SecureField
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 5) // Add red border if invalid attempt
                            .stroke(isInvalidKeyAttempt ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if isInvalidKeyAttempt {
                    Text("API Key cannot be empty.")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Link(destination: URL(string: "https://platform.openai.com/settings/organization/api-keys")!) {
                    Label("Get your API Key from OpenAI Settings", systemImage: "link")
                }
                .font(.footnote)

                Spacer() // Push buttons to bottom

                HStack {
                    Button("Cancel") {
                        onCancel()
                        dismiss() // Dismiss the sheet
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction) // Allow Esc key

                    Spacer()

                    Button("Save Key") {
                        let trimmedKey = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedKey.isEmpty {
                            isInvalidKeyAttempt = true // Mark attempt as invalid
                        } else {
                            apiKey = trimmedKey // Save the valid key to AppStorage
                            isInvalidKeyAttempt = false // Reset invalid attempt state
                            onSave(apiKey)    // Call the save callback
                            dismiss()         // Dismiss the sheet
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction) // Allow Enter key
                }
            }
            .padding()
            .navigationTitle("OpenAI API Key")
            .navigationBarTitleDisplayMode(.inline)
            // Load existing key into input field when sheet appears
             .onAppear {
                 inputKey = apiKey // Populate field with stored key if it exists
                 isInvalidKeyAttempt = false // Reset validation state on appear
             }
        }
    }
}

// MARK: - Authentication Explanation View

struct OpenAIAuthView: View {
    @State private var organizationID: String = ""
    @State private var projectID: String = ""

    private var curlExample: String {
        var command = """
        curl https://api.openai.com/v1/models \\
          -H "Authorization: Bearer <YOUR_API_KEY>"
        """
        if !organizationID.trimmingCharacters(in: .whitespaces).isEmpty {
            command += " \\\n  -H \"OpenAI-Organization: \(organizationID.trimmingCharacters(in: .whitespaces))\""
        }
        if !projectID.trimmingCharacters(in: .whitespaces).isEmpty {
            command += " \\\n  -H \"OpenAI-Project: \(projectID.trimmingCharacters(in: .whitespaces))\""
        }
        return command
    }

    private let apiKeySettingsURL = URL(string: "https://platform.openai.com/settings/organization/api-keys")!
    private let orgSettingsURL = URL(string: "https://platform.openai.com/settings/organization/general")!
    private let projectSettingsURL = URL(string: "https://platform.openai.com/settings")!

    var body: some View {
        // Removed NavigationView to allow embedding
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Section { // API Key Auth & Warning
                    VStack(alignment: .leading, spacing: 10) {
                        Label("API Key Authentication", systemImage: "key.fill").font(.title2.weight(.semibold))
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            Text("Important Security Reminder").font(.headline).foregroundColor(.orange)
                        }
                        Text("Your API key grants access. **Never share it or expose it in client-side code.** Always load it securely on your server.").font(.callout)
                        Text("Manage your API keys:")
                        Link(destination: apiKeySettingsURL) { Label("API Key Settings", systemImage: "arrow.up.right.square") }
                            .buttonStyle(.bordered)
                    }
                }
                Divider()
                Section { // Standard Auth Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Standard Authentication").font(.title3.weight(.medium))
                        Text("Uses HTTP Bearer authentication via `Authorization` header:").font(.callout)
                        CodeBlock(code: "Authorization: Bearer <YOUR_SECURELY_LOADED_API_KEY>")
                    }
                }
                Divider()
                Section { // Optional Org/Project Headers
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Optional Org/Project Headers").font(.title3.weight(.medium))
                        Text("Specify organization/project usage with these headers:").font(.callout)
                        VStack(alignment: .leading) { // Org ID Input
                            Text("Organization ID:")
                            TextField("Enter Organization ID (Optional)", text: $organizationID)
                                .textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none).disableAutocorrection(true)
                            Link("Find Organization ID", destination: orgSettingsURL).font(.caption)
                        }.padding(.bottom, 5)
                        VStack(alignment: .leading) { // Project ID Input
                            Text("Project ID:")
                            TextField("Enter Project ID (Optional)", text: $projectID)
                                .textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none).disableAutocorrection(true)
                            Link("Find Project ID", destination: projectSettingsURL).font(.caption)
                        }
                        Text("Example Request (cURL):").padding(.top, 10)
                        CodeBlock(code: curlExample)
                        Text("Usage bills to the specified organization/project.").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        // No Navigation Title here - handled by containing view if embedded
    }
}

// Helper View for Code Blocks (Used in OpenAIAuthView)
struct CodeBlock: View {
    let code: String
    var body: some View {
        Text(code)
            .font(.system(.callout, design: .monospaced)).padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground)).cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.separator), lineWidth: 1))
            .textSelection(.enabled)
    }
}

// MARK: - Detail View (Enhanced for o3)

struct ModelDetailView: View {
    let model: OpenAIModel

    var body: some View {
        List {
            // Section: Header Profile
            Section {
                VStack(spacing: 15) {
                     Image(systemName: model.profileSymbolName).resizable().scaledToFit()
                         .padding(15).frame(width: 80, height: 80)
                         .background(model.profileBackgroundColor).foregroundStyle(.white)
                         .clipShape(Circle())
                         .shadow(color: model.profileBackgroundColor.opacity(0.4), radius: 8, y: 4)
                     Text(model.id).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
            }.listRowBackground(Color.clear)

            // Section: Description
            if let description = model.description, description != "No description available." {
                 Section("Description") {
                     Text(description)
                         .font(.body)
                         .lineSpacing(4)
                 }
            }

            // Section: Performance (Reasoning & Speed)
            Section("Performance Indicators") {
                 RatingView(label: "Reasoning", systemImage: "lightbulb.fill", rating: model.reasoningRating, maxRating: 4, activeColor: .yellow)
                 RatingView(label: "Speed", systemImage: "bolt.fill", rating: model.speedRating, maxRating: 4, activeColor: .cyan)
            }

             // Section: Pricing (o3 specific)
             if model.priceInputPerMToken != nil || model.priceOutputPerMToken != nil {
                 Section("Pricing (Per 1 Million Tokens)") {
                     DetailRow(label: "Input", value: formatCurrency(model.priceInputPerMToken), systemImage: "arrow.down.circle.fill")
                     if let cachedPrice = model.priceCachedInputPerMToken {
                         DetailRow(label: "Cached Input", value: formatCurrency(cachedPrice), systemImage: "archivebox.fill")
                     }
                     DetailRow(label: "Output", value: formatCurrency(model.priceOutputPerMToken), systemImage: "arrow.up.circle.fill")
                 }
             }

            // Section: Capabilities & Limits
            Section("Capabilities & Limits") {
                 DetailRow(label: "Context Window", value: model.contextWindowTokens != nil ? "\(formatNumber(model.contextWindowTokens)) tokens" : model.contextWindow, systemImage: "rectangle.expand.vertical") // Use token count if available
                 DetailRow(label: "Max Output Tokens", value: formatNumber(model.maxOutputTokens), systemImage: "arrow.up.message.fill")
                 DetailRow(label: "Knowledge Cutoff", value: model.knowledgeCutoffDate, systemImage: "calendar.badge.exclamationmark")
                if model.reasoningTokenSupport == true {
                    HStack {
                        // Simple checkmark indicator for boolean flags
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Reasoning Token Support")
                            .font(.callout)
                        Spacer()
                    }
                }
            }

            // Section: Modalities
            if let inputModalities = model.inputModalities, let outputModalities = model.outputModalities {
                Section("Modalities") {
                    HStack {
                        Text("Input:")
                            .font(.callout).foregroundColor(.secondary)
                        Spacer()
                        WrappingHStack(items: inputModalities, alignment: .trailing, horizontalSpacing: 4, verticalSpacing: 4) { modality in // Align right
                            CapabilityTag(text: modality, backgroundColor: .blue.opacity(0.15), foregroundColor: .blue)
                        }
                    }
                    HStack {
                        Text("Output:")
                            .font(.callout).foregroundColor(.secondary)
                        Spacer()
                        WrappingHStack(items: outputModalities, alignment: .trailing, horizontalSpacing: 4, verticalSpacing: 4) { modality in // Align right
                            CapabilityTag(text: modality, backgroundColor: .green.opacity(0.15), foregroundColor: .green)
                        }
                    }
                }

            }

            // Section: Capabilities (Tags)
            if let capabilities = model.capabilities, capabilities != ["general"] {
                Section("Primary Capabilities") {
                    WrappingHStack(items: capabilities) { capability in
                        CapabilityTag(text: capability)
                    }
                }
            }

            // Section: Use Cases
             if let useCases = model.typicalUseCases, useCases != ["Various tasks"] {
                  Section("Typical Use Cases") {
                      ForEach(useCases, id: \.self) { useCase in
                          Label(useCase, systemImage: "play.rectangle")
                              .foregroundColor(.primary).imageScale(.small)
                      }
                  }
             }

            // Section: Endpoints & Features
             Section("Endpoints & Features") {
                if let endpoints = model.supportedEndpoints {
                    Text("Supported Endpoints:").font(.caption).foregroundColor(.gray)
                    ForEach(endpoints, id: \.self) { FeatureListItem(name: $0, isSupported: true) }
                }
                if let endpoints = model.unsupportedEndpoints, !endpoints.isEmpty {
                    if model.supportedEndpoints != nil { Divider().padding(.vertical, 2) } // Add separator
                    Text("Unsupported Endpoints:").font(.caption).foregroundColor(.gray)
                    ForEach(endpoints, id: \.self) { FeatureListItem(name: $0, isSupported: false) }
                }

                 Divider().padding(.vertical, 4)

                if let features = model.supportedFeatures {
                    Text("Supported Features:").font(.caption).foregroundColor(.gray)
                    ForEach(features, id: \.self) { FeatureListItem(name: $0, isSupported: true) }
                }
                 if let features = model.unsupportedFeatures, !features.isEmpty {
                     if model.supportedFeatures != nil { Divider().padding(.vertical, 2)}
                     Text("Unsupported Features:").font(.caption).foregroundColor(.gray)
                     ForEach(features, id: \.self) { FeatureListItem(name: $0, isSupported: false) }
                 }
            }

            // Section: Snapshots
            if let snapshots = model.snapshots, !snapshots.isEmpty {
                 Section("Available Snapshots") {
                     ForEach(snapshots, id: \.self) { snapshot in
                         Label(snapshot, systemImage: "camera.aperture")
                             .imageScale(.small)
                     }
                 }
            }

            // Section: Rate Limits (Show Tier 5 from mock data)
             if let limits = model.rateLimits {
                 Section("Rate Limits (\(limits.tier ?? "Default"))") {
                     DetailRow(label: "RPM", value: formatNumber(limits.rpm), systemImage: "gauge.medium")
                     DetailRow(label: "RPD", value: limits.rpd, systemImage: "calendar") // Use string for RPD
                     DetailRow(label: "TPM", value: formatNumber(limits.tpm), systemImage: "text.quote")
                     DetailRow(label: "Batch Queue", value: formatNumber(limits.batchQueueLimit), systemImage: "square.stack.3d.up.fill")
                 }
             }

            // Section: Actions (Placeholder)
            Section("Actions") {
                 Button { print("Simulate: Trying model \(model.id)") } label: {
                      Label("Try in Playground (Simulated)", systemImage: "play.circle.fill")
                          .frame(maxWidth: .infinity)
                 }
                 .buttonStyle(.borderedProminent)
                 .tint(model.profileBackgroundColor)
                 .listRowInsets(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(model.id) // Use model ID as nav title
        .navigationBarTitleDisplayMode(.inline)
    }

    // --- Formatting Helpers ---
    private func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "N/A" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2 // Or more if needed for fractions of cents
        return formatter.string(from: NSNumber(value: value)) ?? "N/A"
    }

    private func formatNumber(_ value: Int?) -> String {
        guard let value = value else { return "N/A" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        // Add grouping for large numbers
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = "," // Locale-specific usually handled automatically
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "N/A"
    }
}

// MARK: - Main Content View

struct OpenAIModelsCardView: View {
    // --- State Variables ---
    @State private var allModels: [OpenAIModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var searchText = ""
    @State private var currentSortOrder: SortOption = .idAscending
    @State private var useMockData = true // Default to using Mock data
    @State private var showingApiKeySheet = false
    @State private var showingAuthInfoSheet = false // State for auth info sheet

    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""

    // --- Computed Properties ---
    private var currentApiService: APIServiceProtocol {
        if useMockData {
            print("🔧 Using MockAPIService instance")
            return MockAPIService()
        } else {
            print("☁️ Using LiveAPIService instance")
            return LiveAPIService()
        }
    }

    var filteredAndSortedModels: [OpenAIModel] {
        // Filter
        let filtered: [OpenAIModel]
        if searchText.isEmpty {
            filtered = allModels
        } else {
            filtered = allModels.filter {
                $0.id.localizedCaseInsensitiveContains(searchText) ||
                ($0.description ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.capabilities?.contains { $0.localizedCaseInsensitiveContains(searchText) } ?? false)
            }
        }
        // Sort
        switch currentSortOrder {
            case .idAscending:  return filtered.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
            case .idDescending: return filtered.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedDescending }
            case .dateNewest:   return filtered.sorted { $0.created > $1.created }
            case .dateOldest:   return filtered.sorted { $0.created < $1.created }
        }
    }

    // --- Body ---
    var body: some View {
        NavigationStack {
            ZStack {
                // --- Main Content Area ---
                 if isLoading && allModels.isEmpty {
                      ProgressView("Fetching Models...").scaleEffect(1.5)
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
                 } else if let errorMessage = errorMessage, allModels.isEmpty {
                      ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
                 } else if filteredAndSortedModels.isEmpty && !searchText.isEmpty {
                      ContentUnavailableView.search(text: searchText)
                 } else if filteredAndSortedModels.isEmpty && searchText.isEmpty {
                     ContentUnavailableView("No OpenAI Models Found", systemImage: "rectangle.stack.badge.questionmark", description: Text(useMockData ? "Mock data is empty." : "Could not fetch models from the live API."))
                 } else {
                    // --- Model List ---
                     List {
                         ForEach(filteredAndSortedModels) { model in
                             NavigationLink(value: model) {
                                 ModelCardView(model: model)
                             }
                             .listRowInsets(EdgeInsets())
                             .listRowBackground(Color.clear)
                             .listRowSeparator(.hidden)
                             .padding(.horizontal, 16)
                             .padding(.vertical, 6)
                         }
                     }
                     .listStyle(.plain)
                     .contentMargins(.vertical, 0, for: .scrollContent)
                     .background(Color(.systemGroupedBackground))
                     .searchable(text: $searchText, prompt: "Search Models (ID, Desc, Caps)")
                 }
            }
             .navigationTitle("OpenAI Models")
             // --- Toolbar Items ---
             .toolbar {
                 // Leading: Refresh/Loading
                 ToolbarItem(placement: .navigationBarLeading) {
                     if isLoading { ProgressView().controlSize(.small) }
                     else {
                         Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                            .disabled(isLoading)
                     }
                 }
                 // Trailing: Sort Menu & Auth Info
                 ToolbarItemGroup(placement: .navigationBarTrailing) {
                     // Auth Info Button
                      Button {
                          showingAuthInfoSheet = true
                      } label: {
                           Label("Authentication Info", systemImage: "key.viewfinder")
                      }

                     // Sort Menu
                      Menu {
                          Picker("Sort Order", selection: $currentSortOrder) {
                              ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) }
                          }
                      } label: {
                           Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                      }
                      .disabled(allModels.isEmpty || isLoading)
                 }
                 // Bottom Bar: API Source Toggle
                 ToolbarItem(placement: .bottomBar) {
                     Toggle(isOn: $useMockData) {
                         Text(useMockData ? "Using Mock Data" : "Using Live API")
                              .font(.caption)
                     }
                     .toggleStyle(.button).buttonStyle(.bordered)
                     .tint(useMockData ? .gray : .blue).padding(.horizontal).disabled(isLoading)
                 }
             }
             // --- Navigation ---
             .navigationDestination(for: OpenAIModel.self) { model in
                 ModelDetailView(model: model)
                     .toolbarBackground(.visible, for: .navigationBar)
                     .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar)
             }
             // --- Lifecycle & State Handling ---
             .task { if allModels.isEmpty { attemptLoadModels() } }
             .refreshable { await loadModelsAsync(checkApiKey: false) } // Don't prompt on pull-refresh
             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: {
                 Button("OK") { errorMessage = nil }
             }, message: { Text(errorMessage ?? "An unknown error occurred.") })
             // --- React to Toggle Changes ---
              .onChange(of: useMockData) { oldValue, newValue in
                   print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
                   allModels = []; errorMessage = nil; searchText = "" // Clear state
                   if newValue == false { // Switching TO Live
                        if storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                             showingApiKeySheet = true // Prompt if key missing
                        } else { loadModelsAsyncWithLoadingState() } // Load if key exists
                   } else { // Switching TO Mock
                        loadModelsAsyncWithLoadingState() // Just load mock
                   }
              }
              // --- Sheets ---
              .sheet(isPresented: $showingApiKeySheet) { // API Key Input Sheet
                   APIKeyInputView(
                       onSave: { _ in loadModelsAsyncWithLoadingState() }, // Load on save
                       onCancel: { useMockData = true } // Revert toggle on cancel
                   )
              }
              .sheet(isPresented: $showingAuthInfoSheet) { // Authentication Info Sheet
                  OpenAIAuthView() // Show the auth explanation view
              }
        } // End NavigationStack
    }

    // MARK: - Data Loading Helper Functions

    private func loadModelsAsyncWithLoadingState() {
        guard !isLoading else { return }
        isLoading = true
        Task { await loadModelsAsync(checkApiKey: false) }
    }

     private func attemptLoadModels() {
         guard !isLoading else { return }
         if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             showingApiKeySheet = true // Live & no key -> prompt
         } else {
             loadModelsAsyncWithLoadingState() // Mock or (Live & key exists) -> load
         }
     }

    @MainActor
     private func loadModelsAsync(checkApiKey: Bool) async {
        if !isLoading { isLoading = true } // Ensure loading state

        // Optional re-check (though attemptLoadModels should handle it)
        if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             print("API Key check failed during load attempt.")
             showingApiKeySheet = true; isLoading = false; return
        }

        let serviceToUse = currentApiService
        print("🔄 Loading models using \(useMockData ? "MockAPIService" : "LiveAPIService")...")
        do {
            let fetchedModels = try await serviceToUse.fetchModels()
            self.allModels = fetchedModels
            self.errorMessage = nil
            print("✅ Successfully loaded \(fetchedModels.count) models.")
        } catch let error as LocalizedError {
            print("❌ Error loading models: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            if allModels.isEmpty { self.allModels = [] }
        } catch {
            print("❌ Unexpected error loading models: \(error)")
             self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
             if allModels.isEmpty { self.allModels = [] }
        }
        isLoading = false
    }
}

// MARK: - Previews

#Preview("List (Defaults to Mock)") {
    OpenAIModelsCardView()
}

//#Preview("Detail View (o3 Mock)") {
//     // Find the mock o3 model to preview
//     let mockService = MockAPIService()
//     let mockModels = try? await mockService.fetchModels() // Can fail if MockError is thrown
//     let o3Model = mockModels?.first { $0.id == "o3" }
//         ?? OpenAIModel(id: "o3-preview-error", object: "model", created: 0, ownedBy: "preview") // Fallback
//
//    NavigationStack {
//          ModelDetailView(model: o3Model)
//     }
//}

#Preview("Card View (GPT-4)") {
    let model = OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1712602800, ownedBy: "openai")
    return ModelCardView(model: model).padding()
}

#Preview("Error View") {
    ErrorView(errorMessage: "Network timeout. Server did not respond.") {
        print("Retry tapped in preview")
    }
}

#Preview("Auth Info Sheet Content") {
    OpenAIAuthView()
}
