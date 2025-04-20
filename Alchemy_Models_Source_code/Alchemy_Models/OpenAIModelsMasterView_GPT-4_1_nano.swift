//
//  OpenAIModelsMasterView_GPT-4o_nano.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  OpenAIModelsMasterView.swift
//  Alchemy_Models_Combined
//  (Single File Implementation)
//
//  Created: Cong Le
//  Date: 4/13/25 (Based on previous iterations)
//  Version: 1.2 (Added GPT41NanoDetailView and conditional navigation)
//  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
//  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
//

import SwiftUI
import Foundation // Needed for URLSession, URLRequest, etc.
import Combine // Needed for @StateObject if using ObservableObject later

// MARK: - Enums (Sorting, Errors)

enum SortOption: String, CaseIterable, Identifiable {
    case idAscending = "ID (A-Z)"
    case idDescending = "ID (Z-A)"
    case dateNewest = "Date (Newest)"
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

enum LiveAPIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case missingAPIKey
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The API endpoint URL is invalid."
        case .requestFailed(let sc): return "API request failed with status code \(sc)."
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .decodingError(let err): return "Failed to decode API response: \(err.localizedDescription)"
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

// --- Main Data Model ---
struct OpenAIModel: Codable, Identifiable, Hashable {
    let id: String
    let object: String
    let created: Int // Unix timestamp
    let ownedBy: String

    // --- Default values for fields that might be missing in basic /v1/models response ---
    var description: String = "No description available."
    var capabilities: [String] = ["general"]
    var contextWindow: String = "N/A"
    var typicalUseCases: [String] = ["Various tasks"]
    var shortDescription: String = "General purpose model." // Added previously

    // --- Codable Conformance ---
    enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case ownedBy = "owned_by"
        // Properties with defaults (description, capabilities, contextWindow, typicalUseCases, shortDescription) are NOT listed.
    }

    // --- Computed Properties & Hashable ---
    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: OpenAIModel, rhs: OpenAIModel) -> Bool { lhs.id == rhs.id }
}

// MARK: - Model Extension for UI Logic

extension OpenAIModel {
    // --- Determine SF Symbol name based on ID or owner ---
    var iconName: String {
        let normalizedId = id.lowercased()
        // Specific mappings first
        if normalizedId == "gpt-4.1-nano" { return "speedometer" } // Custom for nano
        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") || normalizedId.contains("chatgpt-4o") { return "sparkles" }
        if normalizedId.contains("o4-mini") || normalizedId.contains("o3-mini") || normalizedId.contains("o1-mini") || normalizedId.contains("gpt-4.1-mini") { return "leaf.fill" }
        if normalizedId.contains("o3") { return "circle.hexagonpath.fill" }
        if normalizedId.contains("o1") || normalizedId.contains("o1-pro") { return "circles.hexagonpath.fill" }
        if normalizedId.contains("gpt-4-turbo") { return "bolt.fill" }
        if normalizedId.contains("gpt-4") && !normalizedId.contains("turbo") && !normalizedId.contains("nano") { return "star.fill"} // Exclude nano
        if normalizedId.contains("gpt-3.5") { return "forward.fill" }
        if normalizedId.contains("dall-e") { return "paintbrush.pointed.fill" }
        if normalizedId.contains("tts") { return "speaker.wave.2.fill" }
        if normalizedId.contains("transcribe") || normalizedId.contains("whisper") { return "waveform" }
        if normalizedId.contains("embedding") { return "arrow.down.right.and.arrow.up.left.circle.fill" }
        if normalizedId.contains("moderation") { return "exclamationmark.shield.fill" }
        if normalizedId.contains("search") { return "magnifyingglass"}
        if normalizedId.contains("computer-use") { return "computermouse.fill" }

        // Fallback based on owner
        let lowerOwner = ownedBy.lowercased()
        if lowerOwner.contains("openai") { return "building.columns.fill" }
        if lowerOwner == "system" { return "gearshape.fill" }
        if lowerOwner.contains("user") || lowerOwner.contains("org") { return "person.crop.circle.fill" }
        return "questionmark.circle.fill" // Default/fallback
    }

    // --- Determine background color for icons ---
    var iconBackgroundColor: Color {
        let normalizedId = id.lowercased()
        // Specific mappings first
        if normalizedId == "gpt-4.1-nano" { return .cyan } // Custom for nano
        if normalizedId.contains("gpt-4.1") || normalizedId.contains("gpt-4o") { return .blue }
        if normalizedId.contains("o4-mini") { return .purple }
        if normalizedId.contains("o3") { return .orange }
        if normalizedId.contains("dall-e") { return .teal }
        if normalizedId.contains("tts") { return .indigo }
        if normalizedId.contains("whisper") || normalizedId.contains("transcribe") { return .pink }
        if normalizedId.contains("embedding") { return .green }
        if normalizedId.contains("moderation") { return .red }
        if normalizedId.contains("search") { return .cyan }
        if normalizedId.contains("computer-use") { return .brown }

        // Fallback based on owner
        let lowerOwner = ownedBy.lowercased()
        if lowerOwner.contains("openai") { return .blue.opacity(0.8) }
        if lowerOwner == "system" { return .orange.opacity(0.8) }
        if lowerOwner.contains("user") || lowerOwner.contains("org") { return .purple.opacity(0.8) }
        return .gray.opacity(0.7) // Default/fallback
    }

    // --- Simplified name for display ---
    var displayName: String {
        // Special case for nano to match screenshot exactly
        if id == "gpt-4.1-nano" { return "GPT-4.1 nano" }
        return id.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

// MARK: - API Service Implementations

// --- Mock Data Service ---
class MockAPIService: APIServiceProtocol {
    private let mockNetworkDelaySeconds: Double = 0.8

    // Enhanced mock models based on screenshots (Includes existing list + nano)
    private func generateMockModels() -> [OpenAIModel] {
         return [
            // Added GPT-4.1 nano (based on screenshot info)
            OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "GPT-4.1 nano is the fastest, most cost-effective GPT-4.1 model.", capabilities: ["text generation", "image input"], contextWindow: "1,047,576", shortDescription: "Fastest, most cost-effective GPT-4.1."),

            // Featured
            OpenAIModel(id: "gpt-4.1", object: "model", created: 1712700000, ownedBy: "openai", description: "Our flagship GPT model for complex tasks.", capabilities: ["text generation", "reasoning", "code", "vision"], contextWindow: "128k", shortDescription: "Flagship GPT model for complex tasks"),
            OpenAIModel(id: "o4-mini", object: "model", created: 1712600000, ownedBy: "openai", description: "A smaller, faster, and more affordable reasoning model, alternative to o4.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Faster, more affordable reasoning model"),
            OpenAIModel(id: "o3", object: "model", created: 1700000000, ownedBy: "openai", description: "The previous generation's most powerful reasoning model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "16k", shortDescription: "Our most powerful reasoning model"),

            // Reasoning Models
            OpenAIModel(id: "o3-mini", object: "model", created: 1699000000, ownedBy: "openai", description: "A smaller, faster, and more affordable alternative to o3.", capabilities: ["text generation", "reasoning"], contextWindow: "16k", shortDescription: "A small model alternative to o3"),
            OpenAIModel(id: "o1", object: "model", created: 1680000000, ownedBy: "openai", description: "Previous generation full o-series reasoning model.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Previous full o-series reasoning model"),
            OpenAIModel(id: "o1-pro", object: "model", created: 1685000000, ownedBy: "openai", description: "Version of o1 with more compute for better responses.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "Version of o1 with more compute"),
            OpenAIModel(id: "o1-mini", object: "model", created: 1675000000, ownedBy: "openai", description: "A small model alternative to o1, very fast.", capabilities: ["text generation", "reasoning"], contextWindow: "8k", shortDescription: "A small model alternative to o1"),

            // Flagship Chat Models
            OpenAIModel(id: "gpt-4o", object: "model", created: 1712800000, ownedBy: "openai", description: "Fast, intelligent, flexible GPT model.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "Fast, intelligent, flexible GPT model"),
            OpenAIModel(id: "gpt-4o-audio", object: "model", created: 1712850000, ownedBy: "openai", description: "GPT-4o models capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "GPT-4o models capable of audio inputs"),
            OpenAIModel(id: "chatgpt-4o-latest", object: "model", created: 1712900000, ownedBy: "openai", description: "GPT-4o model used in ChatGPT.", capabilities: ["text generation", "reasoning", "code", "vision", "audio"], contextWindow: "128k", shortDescription: "GPT-4o model used in ChatGPT"),

            // Cost-optimized Models (Added nano here too for completeness in this category)
            OpenAIModel(id: "gpt-4.1-mini", object: "model", created: 1712500000, ownedBy: "openai", description: "Balanced for intelligence, speed, and cost.", capabilities: ["text generation", "reasoning"], contextWindow: "128k", shortDescription: "Balanced for intelligence, speed, cost"),
           // Duplicating nano definition from above, slightly adjusted description for category context if needed
           // OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1712400000, ownedBy: "openai", description: "Fastest, most cost-effective GPT-4.1 model.", capabilities: ["text generation", "image input"], contextWindow: "1,047,576", shortDescription: "Fastest, most cost-effective GPT-4.1"),
            OpenAIModel(id: "gpt-4o-mini", object: "model", created: 1712300000, ownedBy: "openai", description: "Fast, affordable small model for focused tasks.", capabilities: ["text generation"], contextWindow: "128k", shortDescription: "Fast, affordable small model"),
            OpenAIModel(id: "gpt-4o-mini-audio", object: "model", created: 1712350000, ownedBy: "openai", description: "Smaller model capable of audio inputs and outputs.", capabilities: ["audio processing", "text generation"], contextWindow: "128k", shortDescription: "Smaller model capable of audio inputs"),

            // Realtime Models
            OpenAIModel(id: "gpt-4o-realtime", object: "model", created: 1712860000, ownedBy: "openai", description: "Model capable of realtime text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Model capable of realtime text/audio"),
            OpenAIModel(id: "gpt-4o-mini-realtime", object: "model", created: 1712360000, ownedBy: "openai", description: "Smaller realtime model for text and audio inputs and outputs.", capabilities: ["realtime", "audio", "text"], contextWindow: "128k", shortDescription: "Smaller realtime model for text/audio"),

            // Older GPT Models
            OpenAIModel(id: "gpt-4-turbo", object: "model", created: 1705000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "128k", shortDescription: "An older high-intelligence GPT model"),
            OpenAIModel(id: "gpt-4", object: "model", created: 1680000000, ownedBy: "openai", description: "An older high-intelligence GPT model.", capabilities: ["text generation", "reasoning", "code"], contextWindow: "8k / 32k", shortDescription: "An older high-intelligence GPT model"),
            OpenAIModel(id: "gpt-3.5-turbo", object: "model", created: 1677600000, ownedBy: "openai", description: "Legacy GPT model for cheaper chat and non-chat tasks.", capabilities: ["text generation"], contextWindow: "4k / 16k", shortDescription: "Legacy GPT model for cheaper tasks"),

            // DALL-E Models
            OpenAIModel(id: "dall-e-3", object: "model", created: 1700000000, ownedBy: "openai", description: "Our latest image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our latest image generation model"),
            OpenAIModel(id: "dall-e-2", object: "model", created: 1650000000, ownedBy: "openai", description: "Our first image generation model.", capabilities: ["image generation"], contextWindow: "N/A", shortDescription: "Our first image generation model"),
        ]
            // Filter out duplicates if nano was added twice
           .reduce(into: [OpenAIModel]()) { result, model in
                if !result.contains(where: { $0.id == model.id }) {
                    result.append(model)
                }
            }
    }

    func fetchModels() async throws -> [OpenAIModel] {
         try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
         return generateMockModels()
    }
}

// --- Live Data Service ---
class LiveAPIService: APIServiceProtocol {
    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""
    private let modelsURL = URL(string: "https://api.openai.com/v1/models")!

    func fetchModels() async throws -> [OpenAIModel] {
        let currentKey = storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentKey.isEmpty else { throw LiveAPIError.missingAPIKey }

        var request = URLRequest(url: modelsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(currentKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        print("🚀 Making live API request to: \(modelsURL)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw LiveAPIError.requestFailed(statusCode: 0) }
            print("✅ Received API response with status code: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 401 { throw LiveAPIError.missingAPIKey }
            guard (200...299).contains(httpResponse.statusCode) else { throw LiveAPIError.requestFailed(statusCode: httpResponse.statusCode) }

            do {
                 let decoder = JSONDecoder()
                 let responseWrapper = try decoder.decode(ModelListResponse.self, from: data)
                 print("✅ Successfully decoded \(responseWrapper.data.count) models.")
                 // Make sure shortDescription gets populated if missing from API
                 // (The default in the struct handles this if the key is absent,
                 // but this ensures a *basic* description if key exists but value is null/empty maybe)
                 return responseWrapper.data.map { model in
                      var mutableModel = model
                      if mutableModel.shortDescription.isEmpty || mutableModel.shortDescription == "General purpose model." {
                           mutableModel.shortDescription = model.ownedBy.contains("openai") ? "OpenAI model." : "User or system model."
                      }
                      // Special short description for nano if fetched live
                      if mutableModel.id == "gpt-4.1-nano" {
                          mutableModel.shortDescription = "Fastest, most cost-effective GPT-4.1."
                      }
                      return mutableModel
                 }
            } catch {
                 print("❌ Decoding Error: \(error)")
                 print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Could not decode data")")
                 throw LiveAPIError.decodingError(error)
            }
        } catch let error as LiveAPIError { throw error }
          catch { throw LiveAPIError.networkError(error) }
    }
}

// MARK: - Reusable SwiftUI Helper Views (Error, WrappingHStack, APIKeyInputView)

struct ErrorView: View {
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

struct WrappingHStack<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    let viewForItem: (Item) -> ItemView
    let horizontalSpacing: CGFloat = 8
    let verticalSpacing: CGFloat = 8
    @State private var totalHeight: CGFloat = .zero
    var body: some View {
        VStack {
            GeometryReader { geometry in self.generateContent(in: geometry) }
        }
        .frame(height: totalHeight) // Report height
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
                            width = 0; height -= d.height + verticalSpacing // Move to next row
                        }
                        let result = width
                        if item == self.items.last { width = 0 } else { width -= d.width } // Adjust width
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height // Y position for this item
                        if item == self.items.last { height = 0 } // Reset height for next render pass
                        return result
                    })
            }
        }.background(viewHeightReader($totalHeight)) // Read the total height of ZStack
    }
    // Helper to read the calculated height of the content
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async { // Update state after layout pass
                binding.wrappedValue = rect.size.height
            }
            return .clear // Makes the background view transparent
        }
    }
}

// --- API Key Input View (Sheet) ---
struct APIKeyInputView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("userOpenAIKey") private var apiKey: String = "" // Two-way binding
    @State private var inputApiKey: String = "" // Local state for the text field
    @State private var isInvalidKeyAttempt: Bool = false // State for validation feedback

    var onSave: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter your OpenAI API Key")
                    .font(.headline)
                Text("Your key will be stored securely in UserDefaults on this device. Ensure you are using a key with appropriate permissions.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("sk-...", text: $inputApiKey) // Masked input
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(isInvalidKeyAttempt ? Color.red : Color.clear, lineWidth: 1))
                    .onChange(of: inputApiKey) { _, _ in isInvalidKeyAttempt = false } // Reset error on edit

                if isInvalidKeyAttempt {
                     Text("API Key cannot be empty.").font(.caption).foregroundColor(.red)
                }

                HStack {
                    Button("Cancel") { onCancel(); dismiss() }.buttonStyle(.bordered)
                    Spacer()
                    Button("Save Key") { saveKeyAction() }.buttonStyle(.borderedProminent)
                }.padding(.top)
                Spacer()
            }
            .padding()
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
             .onAppear { inputApiKey = apiKey; isInvalidKeyAttempt = false } // Load existing/reset
        }
    }

    private func saveKeyAction() {
         let trimmedKey = inputApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
         if trimmedKey.isEmpty { isInvalidKeyAttempt = true }
         else { apiKey = trimmedKey; onSave(apiKey); dismiss() }
    }
}

// MARK: - Model Views (Reused Components: Featured Card, Standard Row, DetailRow, SectionHeader)

struct FeaturedModelCard: View { /* ... Unchanged ... */
    let model: OpenAIModel
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 12)
                .fill(model.iconBackgroundColor.opacity(0.3))
                .frame(height: 120)
                 .overlay(
                      Image(systemName: model.iconName)
                           .resizable().scaledToFit().padding(25)
                           .foregroundStyle(model.iconBackgroundColor)
                 )
            VStack(alignment: .leading, spacing: 4) {
                Text(model.displayName).font(.headline)
                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
            } .padding([.horizontal, .bottom], 12)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
         .frame(minWidth: 0, maxWidth: .infinity)
    }
}

struct StandardModelRow: View { /* ... Unchanged ... */
    let model: OpenAIModel
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: model.iconName)
                .resizable().scaledToFit().padding(7).frame(width: 36, height: 36)
                .background(model.iconBackgroundColor.opacity(0.85))
                .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(model.displayName).font(.subheadline.weight(.medium)).lineLimit(1)
                Text(model.shortDescription).font(.caption).foregroundColor(.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(10).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
    }
}

struct SectionHeader: View { /* ... Unchanged ... */
    let title: String
    let subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.weight(.semibold))
            if let subtitle = subtitle { Text(subtitle).font(.callout).foregroundColor(.secondary) }
        }
        .padding(.bottom, 10).padding(.horizontal)
    }
}

struct DetailRow: View { /* ... Unchanged Helper for Generic Detail View ... */
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.callout).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.body).multilineTextAlignment(.trailing).foregroundColor(.primary)
        } .padding(.vertical, 2).accessibilityElement(children: .combine)
    }
}

// MARK: - Generic Model Detail View (Reused for most models)

struct ModelDetailView: View {
    let model: OpenAIModel
    var body: some View {
        // --- Conditional redirection for specific models ---
        if model.id == "gpt-4.1-nano" {
             // If the model is nano, show the specialized view instead of this generic one.
             // Note: This redirection happens *after* navigation, which is okay here.
             // A cleaner way might involve adjusting the NavigationDestination itself.
             GPT41NanoDetailView()
        } else {
             // --- Default content for other models ---
             List {
                 Section { // Prominent Icon/ID Section
                     VStack(spacing: 15) {
                         Image(systemName: model.iconName).resizable().scaledToFit()
                             .padding(15).frame(width: 80, height: 80)
                             .background(model.iconBackgroundColor).foregroundStyle(.white)
                             .clipShape(Circle())
                             .shadow(color: model.iconBackgroundColor.opacity(0.4), radius: 8, y: 4)
                         Text(model.displayName).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                     }
                     .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 10)
                 }
                 .listRowBackground(Color.clear)

                 Section("Overview") {
                     DetailRow(label: "Full ID", value: model.id)
                     DetailRow(label: "Type", value: model.object)
                     DetailRow(label: "Owner", value: model.ownedBy)
                     DetailRow(label: "Created", value: model.createdDate.formatted(date: .long, time: .shortened))
                 }

                 Section("Details") {
                      VStack(alignment: .leading, spacing: 5) {
                          Text("Description").font(.caption).foregroundColor(.secondary)
                          Text(model.description)
                      }.accessibilityElement(children: .combine)

                      // Use specific context window from model if available and not 'N/A'
                      if model.contextWindow != "N/A"{
                          VStack(alignment: .leading, spacing: 5) {
                             Text("Context Window").font(.caption).foregroundColor(.secondary)
                             Text(model.contextWindow)
                          }.accessibilityElement(children: .combine)
                      }
                 }

                 if !model.capabilities.isEmpty && model.capabilities != ["general"] {
                     Section("Capabilities") {
                         WrappingHStack(items: model.capabilities) { capability in
                             Text(capability)
                                 .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                                 .background(Color.accentColor.opacity(0.2))
                                 .foregroundColor(.accentColor).clipShape(Capsule())
                         }
                     }
                 }

                 if !model.typicalUseCases.isEmpty && model.typicalUseCases != ["Various tasks"] {
                      Section("Typical Use Cases") {
                          ForEach(model.typicalUseCases, id: \.self) { useCase in
                              Label(useCase, systemImage: "play.rectangle").foregroundColor(.primary).imageScale(.small)
                          }
                      }
                 }
             }
             .listStyle(.insetGrouped)
             .navigationTitle("Model Details")
             .navigationBarTitleDisplayMode(.inline)
        } // End else for standard model display
    }
}

// MARK: - Specialized Detail View for GPT-4.1 Nano

struct GPT41NanoDetailView: View {
    // Using static data based on the provided screenshot for GPT-4.1 nano
    @State private var showBatchPricing = false // For the pricing toggle

    // Formatting helpers
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Assuming USD
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 3 // Allow for $0.025
        return formatter
    }()
    let numberFormatter: NumberFormatter = {
       let formatter = NumberFormatter()
       formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
       return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { // Main container

                // --- Top Header Section ---
                ModelHeaderNano()

                Divider()

                // --- Ratings/Specs Section ---
                SpecsGridNano()

                // --- Description & Key Stats ---
                DescriptionStatsNano()

                Divider()

                // --- Pricing Section ---
                PricingSectionNano(showBatchPricing: $showBatchPricing, formatter: currencyFormatter)

                // --- Quick Comparison Section ---
                QuickComparisonNano(formatter: currencyFormatter)

                Divider()

                // --- Modalities Section ---
                ModalitiesSectionNano()

                Divider()

                // --- Endpoints Section ---
                EndpointsSectionNano()

                Divider()

                // --- Features Section ---
                FeaturesSectionNano()

                Divider()

                // --- Snapshots Section ---
                SnapshotsSectionNano()

                Divider()

                // --- Rate Limits Section ---
                RateLimitsSectionNano(formatter: numberFormatter)

            } // End Main VStack
            .padding(.vertical) // Padding top and bottom of scroll content
             .padding(.horizontal) // Consistent horizontal padding
        }
        .navigationTitle("GPT-4.1 nano Details")
        .navigationBarTitleDisplayMode(.inline)
         .background(Color(.systemGroupedBackground)) // Match list style background
         .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - Subviews for GPT41NanoDetailView

private struct ModelHeaderNano: View {
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "speedometer") // Specific icon for nano
                .resizable().scaledToFit().frame(width: 30, height: 30)
                .padding(8).background(Color.cyan.opacity(0.2)).clipShape(Circle())
                .foregroundColor(.cyan)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("GPT-4.1 nano").font(.title2.weight(.semibold))
                    Text("Default")
                       .font(.caption2.weight(.medium))
                       .padding(.horizontal, 6).padding(.vertical, 3)
                       .background(Color.gray.opacity(0.2)).clipShape(Capsule())
                }
                Text("Fastest, most cost-effective GPT-4.1 model").font(.subheadline)
            }
            Spacer()
            HStack { // Buttons
                Button("Compare") { /* Action */ }.buttonStyle(.bordered).controlSize(.small)
                Button("Try in Playground") { /* Action */ }.buttonStyle(.borderedProminent).controlSize(.small)
            }
        }
    }
}

private struct SpecsGridNano: View {
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            SpecItem(title: "Intelligence", value: "Average", iconSystemName: "circle.fill", rating: 2, total: 5, ratingColor: .orange)
            SpecItem(title: "Speed", value: "Very Fast", iconSystemName: "bolt.fill", rating: 4, total: 5, ratingColor: .blue)
            SpecItem(title: "Price", value: "$0.1 · $0.4", subtitle: "Input · Output", iconSystemName: "dollarsign.circle.fill", ratingColor: .green)
            VStack(alignment: .leading, spacing: 5) { // Input/Output Combined
                 Text("Input").font(.caption2).foregroundColor(.secondary)
                 HStack { Image(systemName: "text.alignleft"); Image(systemName: "photo") }
                 Text("Text, Image").font(.caption.weight(.medium))
            }.frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 5) {
                 Text("Output").font(.caption2).foregroundColor(.secondary)
                 HStack { Image(systemName: "text.alignleft") }
                 Text("Text").font(.caption.weight(.medium))
            }.frame(maxWidth: .infinity, alignment: .leading)

        }
        .padding(.vertical, 5)
    }

    // Helper for individual spec items
    struct SpecItem: View {
         let title: String
         let value: String
         var subtitle: String? = nil
         let iconSystemName: String
         var rating: Int? = nil
         var total: Int? = nil
         let ratingColor: Color

         var body: some View {
             VStack(alignment: .leading, spacing: 5) {
                 Text(title).font(.caption2).foregroundColor(.secondary)
                 if let rating = rating, let total = total {
                     HStack(spacing: 2) {
                         ForEach(0..<total, id: \.self) { index in
                             Image(systemName: iconSystemName)
                                 .font(.system(size: 10))
                                 .foregroundColor(index < rating ? ratingColor : .gray.opacity(0.3))
                         }
                     }
                 } else {
                      Image(systemName: iconSystemName).foregroundColor(ratingColor) // For Price/Input/Output
                 }
                 Text(value).font(.caption.weight(.medium))
                 if let subtitle = subtitle { Text(subtitle).font(.caption2).foregroundColor(.secondary)}
             }
             .frame(maxWidth: .infinity, alignment: .leading) // Equal width
         }
    }
}

private struct DescriptionStatsNano: View {
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            Text("GPT-4.1 nano is the fastest, most cost-effective GPT-4.1 model.")
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading) // Take available space

            VStack(alignment: .leading, spacing: 8) {
                StatRow(icon: "arrow.up.left.and.arrow.down.right", value: "1,047,576", label: "context window")
                StatRow(icon: "arrow.down.left.and.arrow.up.right", value: "32,768", label: "max output tokens") // Check icon, might be wrong
                StatRow(icon: "calendar", value: "May 31, 2024", label: "knowledge cutoff")
            }
            .frame(minWidth: 200) // Ensure stats have enough space
        }
    }

    struct StatRow: View {
        let icon: String
        let value: String
        let label: String
        var body: some View {
            HStack {
                Image(systemName: icon).foregroundColor(.secondary).frame(width: 15)
                Text(value).fontWeight(.medium)
                Text(label).foregroundColor(.secondary)
            }
            .font(.caption)
        }
    }
}

private struct PricingSectionNano: View {
    @Binding var showBatchPricing: Bool
    let formatter: NumberFormatter

    var body: some View {
          VStack(alignment: .leading, spacing: 15) {
            Text("Pricing")
                .font(.title3.weight(.semibold))
            Text("Pricing is based on the number of tokens used. For tool-specific models, like search and computer use, there's a fee per tool call. See details in the \(Link("pricing page", destination: URL(string: "https://openai.com/pricing")!)).")
                    .font(.callout)

            HStack {
                Text("Text tokens").font(.headline)
                Spacer()
                Text("Per 1M tokens") // Label for toggle context
                 Toggle("Batch API price", isOn: $showBatchPricing)
                     .labelsHidden() // Hide default toggle label
                     .scaleEffect(0.8) // Make toggle smaller
                     .onChange(of: showBatchPricing) { _,_ in /* No visual change in screenshot */}
            }

            HStack(spacing: 0) { // Use spacing 0 and padding for precise layout
                 PricingBox(title: "Input", price: 0.10, formatter: formatter)
                 PricingBox(title: "Cached input", price: 0.025, formatter: formatter, middle: true)
                 PricingBox(title: "Output", price: 0.40, formatter: formatter)
            }
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))

        }
    }
    // Box for individual price points
    struct PricingBox: View {
         let title: String
         let price: Double
         let formatter: NumberFormatter
         var middle: Bool = false
         var body: some View {
              VStack(spacing: 5){
                   Text(title).font(.caption).foregroundColor(.secondary)
                   Text(formatter.string(from: NSNumber(value: price)) ?? "N/A").font(.title2.weight(.medium))
              }
              .padding()
              .frame(maxWidth: .infinity) // Take equal width
              .background(Color(.secondarySystemGroupedBackground)) // Slightly different bg
              .border(width: middle ? 1 : 0, edges: [.leading, .trailing], color: Color.gray.opacity(0.2)) // Vertical dividers
         }
    }
    // Helper for border modifier
    struct EdgeBorder: Shape { /* ... Standard EdgeBorder implementation ... */
         var width: CGFloat
         var edges: [Edge]
         func path(in rect: CGRect) -> Path {
             edges.map { edge -> Path in
                 switch edge {
                 case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
                 case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
                 case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
                 case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
                 }
             }.reduce(into: Path()) { $0.addPath($1) }
         }
    }
}

// Extension for border helper
extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        //overlay(GPT41NanoDetailView.PricingSectionNano.EdgeBorder(width: width, edges: edges).foregroundColor(color))
        // TODO:
        EmptyView()
    }
}

private struct QuickComparisonNano: View {
    let formatter: NumberFormatter
    let comparisonData: [(name: String, price: Double, proportion: Double)] = [
        ("GPT-4.1 mini", 0.40, 1.0), // Baseline proportion
        ("GPT-4o mini", 0.15, 0.15 / 0.40),
        ("GPT-4.1 nano", 0.10, 0.10 / 0.40)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
             Text("Quick comparison").font(.headline)
             HStack { Spacer(); Text("Input"); Text("Cached input"); Text("Output") } // Column Headers
                 .font(.caption).foregroundColor(.secondary)

             ForEach(comparisonData, id: \.name) { item in
                 ComparisonBar(
                      label: item.name,
                      value: item.price,
                      proportion: item.proportion,
                      formatter: formatter
                 )
             }
        }
    }

    struct ComparisonBar: View {
         let label: String
         let value: Double
         let proportion: Double // Value relative to max (0.0 to 1.0)
         let formatter: NumberFormatter

         var body: some View {
             HStack {
                 Text(label).font(.callout).frame(width: 100, alignment: .leading)
                 GeometryReader { geometry in
                     ZStack(alignment: .leading) {
                         Capsule().fill(Color.gray.opacity(0.2)) // Background full bar
                         Capsule().fill(Color.blue) // Foreground proportional bar
                             .frame(width: geometry.size.width * max(0.05, proportion)) // Ensure minimum visible width
                     }
                 }
                 .frame(height: 10) // Bar height
                 Text(formatter.string(from: NSNumber(value: value)) ?? "N/A")
                      .font(.callout.monospacedDigit()).frame(width: 50, alignment: .trailing)
             }
         }
    }
}

private struct ModalitiesSectionNano: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Modalities").font(.title3.weight(.semibold))
            HStack(alignment: .top, spacing: 20) {
                ModalityItem(icon: "text.bubble", name: "Text", capability: "Input and output")
                ModalityItem(icon: "photo", name: "Image", capability: "Input only")
                ModalityItem(icon: "speaker.slash", name: "Audio", capability: "Not supported", supported: false)
            }
        }
    }

      // Helper for modality items
      struct ModalityItem: View {
          let icon: String
          let name: String
          let capability: String
          var supported: Bool = true

          var body: some View {
              HStack(spacing: 8) {
                   Image(systemName: icon)
                       .font(.title2)
                       .foregroundColor(supported ? .primary : .secondary)
                       .frame(width: 25)

                   VStack(alignment: .leading, spacing: 2) {
                       Text(name).font(.headline)
                       Text(capability).font(.caption).foregroundColor(.secondary)
                   }
              }
              .opacity(supported ? 1.0 : 0.6) // Dim if not supported
              .frame(maxWidth: .infinity, alignment: .leading) // Equal width
          }
      }
}

private struct EndpointsSectionNano: View {
    // Structure: [(Icon, Name, Path, Supported)]
    let endpointData: [(String, String, String?, Bool)] = [
         ("message.fill", "Chat Completions", "v1/chat/completions", true),
         ("arrow.uturn.down.circle.fill", "Responses", "v1/responses", true), // Placeholder icon
         ("antenna.radiowaves.left.and.right.slash", "Realtime", nil, false),
         ("square.stack.3d.up.fill", "Batch", "v1/batch", true), // Assuming true based on table
         ("arrow.down.right.and.arrow.up.left.circle.fill", "Embeddings", nil, false),
         ("photo.fill", "Image generation", nil, false),
         ("speaker.wave.2.fill", "Speech generation", nil, false),
         ("waveform", "Transcription", nil, false),
         ("globe", "Translation", nil, false), // Placeholder icon
         ("exclamationmark.shield.fill", "Moderation", nil, false),
         ("text.badge.xmark", "Completions (legacy)", nil, false),
         ("person.fill.questionmark", "Assistants", "v1/assistants", true),
         ("slider.horizontal.3", "Fine-tuning", nil, false)
    ]
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2) // Two columns

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Endpoints").font(.title3.weight(.semibold))
             LazyVGrid(columns: columns, alignment: .leading, spacing: 15) {
                ForEach(endpointData, id: \.1) { item in
                    EndpointItem(icon: item.0, name: item.1, path: item.2, supported: item.3)
                }
            }
        }
    }
    // Helper View for each Endpoint/Feature item
    struct EndpointItem: View {
         let icon: String
         let name: String
         let path: String? // Path or brief description/status
         let supported: Bool

         var body: some View {
              HStack(alignment: .top, spacing: 8) {
                   Image(systemName: icon)
                       .font(.body.weight(.medium)) // Slightly smaller items
                       .foregroundColor(supported ? .blue : .secondary)
                       .frame(width: 20, alignment: .center)

                   VStack(alignment: .leading, spacing: 2) {
                       Text(name).font(.subheadline.weight(.semibold))
                       if supported {
                           if let path = path { Text(path).font(.caption).foregroundColor(.secondary).lineLimit(1) }
                           else { Text("Supported").font(.caption).foregroundColor(.secondary)}
                       } else {
                            Text("Not supported").font(.caption).foregroundColor(.secondary)
                       }
                  }
                  Spacer() // Allows item to fill grid space
              }
              .opacity(supported ? 1.0 : 0.6)
         }
    }
}

private struct FeaturesSectionNano: View {
    // Structure: [(Icon, Name, Supported)]
     let featureData: [(String, String, Bool)] = [
         ("point.3.connected.trianglepath.dotted", "Streaming", true),
         ("function", "Function calling", true), // Placeholder icon
         ("list.bullet.rectangle.portrait", "Structured outputs", true),
         ("wand.and.stars.inverse", "Fine-tuning", false),
         ("atom", "Distillation", false), // Placeholder icon
         ("eye.trianglebadge.exclamationmark", "Predicted outputs", false) // Placeholder icon
    ]
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2) // Two columns

    var body: some View {
          VStack(alignment: .leading, spacing: 15) {
             Text("Features").font(.title3.weight(.semibold))
             LazyVGrid(columns: columns, alignment: .leading, spacing: 15) {
                 ForEach(featureData, id: \.1) { item in
                     // Reuse EndpointItem view structure
                     EndpointsSectionNano.EndpointItem(icon: item.0, name: item.1, path: nil, supported: item.2)
                 }
             }
        }
    }
}

private struct SnapshotsSectionNano: View {
     // Structure: [(Icon, Name, Alias/Date)]
    let snapshotData: [(String, String, String)] = [
        ("speedometer", "gpt-4.1-nano", "gpt-4.1-nano"), // Likely the alias
        ("calendar.circle", "gpt-4.1-nano-2025-04-14", "") // Date version
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Snapshots").font(.title3.weight(.semibold))
            Text("Snapshots let you lock in a specific version of the model so that performance and behavior remain consistent. Below is a list of all available snapshots and aliases for GPT-4.1 nano.")
                   .font(.callout)

            ForEach(snapshotData, id: \.1) { item in
                 HStack {
                      Image(systemName: item.0).foregroundColor(.blue)
                      Text(item.1).font(.subheadline.weight(.medium))
                      if !item.2.isEmpty {
                           Text("(\(item.2))").font(.caption).foregroundColor(.secondary)
                      }
                      Spacer()
                 }
            }
        }
    }
}

private struct RateLimitsSectionNano: View {
    let formatter: NumberFormatter
    // Tier, RPM, RPD, TPM, Batch Queue Limit (Use -1 for N/A or '-')
     let rateLimitData: [(String, Int, Int, Int, Int)] = [
        ("Free", 3, 200, 40_000, -1),
        ("Tier 1", 500, 10_000, 200_000, 2_000_000),
        ("Tier 2", 5_000, -1, 2_000_000, 20_000_000),
        ("Tier 3", 5_000, -1, 4_000_000, 40_000_000),
        ("Tier 4", 10_000, -1, 10_000_000, 1_000_000_000),
        ("Tier 5", 30_000, -1, 150_000_000, 15_000_000_000)
     ]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
             Text("Rate limits").font(.title3.weight(.semibold))
             Text("Rate limits ensure fair and reliable access to the API by placing specific caps on requests or tokens used within a given time period. Your usage tier determines how high these limits are set and automatically increases as you spend more money on the API.")
                     .font(.callout)

             Text("Standard (Long Context = 128k input tokens)")
                 .font(.caption.weight(.semibold)).padding(.bottom, -5)

             VStack(spacing: 0) { // Table structure
                 // Header Row
                 RateLimitHeader()
                 // Data Rows
                 ForEach(rateLimitData, id: \.0) { rowData in
                     RateLimitRow(data: rowData, formatter: formatter)
                 }
             }
             .background(Color.gray.opacity(0.05))
             .clipShape(RoundedRectangle(cornerRadius: 8))
             .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))

        }
    }

    struct RateLimitHeader: View {
         let headers = ["Tier", "RPM", "RPD", "TPM", "Batch Queue Limit"]
         var body: some View {
             HStack {
                  ForEach(headers, id: \.self) { header in
                      Text(header).font(.caption.weight(.semibold)).frame(maxWidth: .infinity, alignment: .trailing)
                  }
             }
              .padding(.horizontal).padding(.vertical, 8)
              .background(Color.gray.opacity(0.15))
         }
    }

    struct RateLimitRow: View {
        let data: (String, Int, Int, Int, Int)
        let formatter: NumberFormatter
        var body: some View {
             HStack {
                 Text(data.0).font(.caption).frame(maxWidth: .infinity, alignment: .trailing) // Tier
                 Text(formatNumber(data.1)).font(.caption.monospacedDigit()).frame(maxWidth: .infinity, alignment: .trailing) // RPM
                 Text(formatNumber(data.2)).font(.caption.monospacedDigit()).frame(maxWidth: .infinity, alignment: .trailing) // RPD
                 Text(formatNumber(data.3)).font(.caption.monospacedDigit()).frame(maxWidth: .infinity, alignment: .trailing) // TPM
                 Text(formatNumber(data.4)).font(.caption.monospacedDigit()).frame(maxWidth: .infinity, alignment: .trailing) // Batch
            }
            .padding(.horizontal).padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground)) // Alternate row bg slightly
            .border(width: 1, edges: [.top], color: Color.gray.opacity(0.1)) // Separator line
        }

        private func formatNumber(_ number: Int) -> String {
            guard number != -1 else { return "–" } // Use en-dash for missing values
            return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
        }
    }
}

// MARK: - Main Content View (Master List - Modified Navigation)

struct OpenAIModelsMasterView: View {
    // --- State Variables ---
    @State private var allModels: [OpenAIModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var useMockData = true // Default to Mock
    @State private var showingApiKeySheet = false
    @AppStorage("userOpenAIKey") private var storedApiKey: String = ""

    // --- API Service Instance ---
    private var currentApiService: APIServiceProtocol {
        useMockData ? MockAPIService() : LiveAPIService()
    }

    // --- Grid Layout ---
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]

    // --- Filters for Sections (Based on Model IDs) ---
    var featuredModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "o4-mini", "o3"].contains($0.id) }.sortedById() }
    var reasoningModels: [OpenAIModel] { allModels.filter { ["o4-mini", "o3", "o3-mini", "o1", "o1-pro", "o1-mini"].contains($0.id) }.sortedById() }
    var flagshipChatModels: [OpenAIModel] { allModels.filter { ["gpt-4.1", "gpt-4o", "gpt-4o-audio", "chatgpt-4o-latest"].contains($0.id) }.sortedById() }
    // Updated cost-optimized filter to include nano
    var costOptimizedModels: [OpenAIModel] { allModels.filter { ["o4-mini", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o-mini", "gpt-4o-mini-audio", "o1-mini"].contains($0.id) }.sortedById() }
    var realtimeModels: [OpenAIModel] { allModels.filter { ["gpt-4o-realtime", "gpt-4o-mini-realtime"].contains($0.id) }.sortedById() }
    var olderGptModels: [OpenAIModel] { allModels.filter { ["gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"].contains($0.id) }.sortedById() }
    var dalleModels: [OpenAIModel] { allModels.filter { $0.id.contains("dall-e") }.sortedById() }
    // [...] /* Other sections unchanged */
    var toolSpecificModels: [OpenAIModel] { allModels.filter { $0.id.contains("search") || $0.id.contains("computer-use") }.sortedById() }

    var body: some View {
        NavigationStack {
            ZStack {
                 if isLoading && allModels.isEmpty { /* ProgressView unchanged */
                      ProgressView("Fetching Models...").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemBackground)).zIndex(1)
                 } else if let errorMessage = errorMessage, allModels.isEmpty { /* ErrorView unchanged */
                     ErrorView(errorMessage: errorMessage) { attemptLoadModels() }
                 } else {
                    // --- Main Scrollable Content ---
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) {
                             // --- Header Text ---
                             VStack(alignment: .leading, spacing: 5) { /* Unchanged Header */
                                 Text("Models").font(.largeTitle.weight(.bold))
                                 Text("Explore all available models...").font(.title3).foregroundColor(.secondary)
                             } .padding(.horizontal)
                             Divider().padding(.horizontal)
                             // --- Featured Models Section ---
                             SectionHeader(title: "Featured models", subtitle: nil)
                             ScrollView(.horizontal, showsIndicators: false) { /* Horizontal Scroll unchanged */
                                 HStack(spacing: 15) { ForEach(featuredModels) { model in NavigationLink(value: model) { FeaturedModelCard(model: model).frame(width: 250) } } }.padding(.horizontal).padding(.bottom, 5)
                             }
                             // --- Standard Sections with Grid ---
                             // Note: The displaySection helper is used multiple times
                             displaySection(title: "Reasoning models", subtitle: "o-series models...", models: reasoningModels)
                             displaySection(title: "Flagship chat models", subtitle: "Our versatile...", models: flagshipChatModels)
                             displaySection(title: "Cost-optimized models", subtitle: "Smaller, faster models...", models: costOptimizedModels) // Includes nano now
                             // ... [Other sections using displaySection] ...
                             displaySection(title: "Tool-specific models", subtitle: "Models to support...", models: toolSpecificModels)

                             Spacer(minLength: 50)
                        } .padding(.top)
                    }
                    .background(Color(.systemBackground))
                    .edgesIgnoringSafeArea(.bottom)
                 }
            } // End ZStack
            .navigationTitle("OpenAI Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { /* Toolbar unchanged */
                 ToolbarItem(placement: .navigationBarLeading) { if isLoading { ProgressView().controlSize(.small) } else { Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(isLoading) } }
                 ToolbarItem(placement: .navigationBarTrailing) { Menu { Toggle(isOn: $useMockData) { Text(useMockData ? "Using Mock Data" : "Using Live API") } } label: { Label("API Source", systemImage: useMockData ? "doc.plaintext.fill" : "cloud.fill").foregroundColor(useMockData ? .secondary : .blue) }.disabled(isLoading) }
             }
             // --- MODIFIED Navigation Destination ---
             .navigationDestination(for: OpenAIModel.self) { model in
                 // Conditionally show the specialized view for nano
                 if model.id == "gpt-4.1-nano" {
                     GPT41NanoDetailView()
                         .toolbarBackground(.visible, for: .navigationBar)
                         .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar) // Match style
                 } else {
                     // Show the generic detail view for all other models
                     ModelDetailView(model: model)
                         .toolbarBackground(.visible, for: .navigationBar)
                         .toolbarBackground(Color(.secondarySystemBackground), for: .navigationBar) // Standard detail bg
                 }
             }
             // --- Initial Load & API Key Sheet Logic (Unchanged) ---
             .task { if allModels.isEmpty { attemptLoadModels() } }
             .refreshable { await loadModelsAsync(checkApiKey: false) }
             .onChange(of: useMockData) { _, newValue in handleToggleChange(to: newValue) }
             .sheet(isPresented: $showingApiKeySheet) { presentApiKeySheet() }
             .alert("Error", isPresented: .constant(errorMessage != nil && !allModels.isEmpty), actions: { Button("OK") { errorMessage = nil } }, message: { Text(errorMessage ?? "An unknown error occurred.") })

        } // End NavigationStack
    }

    // --- Helper View Builder for Sections (Unchanged) ---
    @ViewBuilder
    private func displaySection(title: String, subtitle: String?, models: [OpenAIModel]) -> some View {
         if !models.isEmpty {
             Divider().padding(.horizontal)
             SectionHeader(title: title, subtitle: subtitle)
             LazyVGrid(columns: gridColumns, spacing: 15) {
                 ForEach(models) { model in
                     NavigationLink(value: model) { StandardModelRow(model: model) }
                     .buttonStyle(.plain)
                 }
             } .padding(.horizontal)
         }
    }

    // --- Helper Functions for Loading & API Key Handling (Unchanged) ---
     private func handleToggleChange(to newValue: Bool) { /* ... unchanged ... */
         print("Toggle changed: Switched to \(newValue ? "Mock Data" : "Live API")")
         allModels = []
         errorMessage = nil
         if !newValue && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             showingApiKeySheet = true
         } else {
             loadModelsAsyncWithLoadingState()
         }
     }

    private func presentApiKeySheet() -> some View { /* ... unchanged ... */
         APIKeyInputView( onSave: { _ in print("API Key saved."); loadModelsAsyncWithLoadingState() }, onCancel: { print("API Key input cancelled."); useMockData = true })
    }

    private func attemptLoadModels() { /* ... unchanged ... */
         guard !isLoading else { return }
         if !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true } else { loadModelsAsyncWithLoadingState() }
     }

    private func loadModelsAsyncWithLoadingState() { /* ... unchanged ... */
         guard !isLoading else { return }
         isLoading = true; Task { await loadModelsAsync(checkApiKey: false) }
    }

    @MainActor
    private func loadModelsAsync(checkApiKey: Bool) async { /* ... unchanged ... */
         if !isLoading { isLoading = true }
         if checkApiKey && !useMockData && storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showingApiKeySheet = true; isLoading = false; return }
         let serviceToUse = currentApiService
         print("🔄 Loading models using \(useMockData ? "MockAPIService" : "LiveAPIService")...")
         do { let fetchedModels = try await serviceToUse.fetchModels(); self.allModels = fetchedModels; self.errorMessage = nil; print("✅ Successfully loaded \(fetchedModels.count) models.")
         } catch let error as LocalizedError { print("❌ Error loading models: \(error.localizedDescription)"); self.errorMessage = error.localizedDescription; if allModels.isEmpty { self.allModels = [] }
         } catch { print("❌ Unexpected error: \(error)"); self.errorMessage = "Unexpected error: \(error.localizedDescription)"; if allModels.isEmpty { self.allModels = [] } }
         isLoading = false
    }
}

// MARK: - Helper Extensions (Unchanged)

extension Array where Element == OpenAIModel {
    func sortedById() -> [OpenAIModel] {
        self.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
    }
}

// MARK: - Previews

#Preview("Main View (Mock Data)") {
    OpenAIModelsMasterView()
}

#Preview("GPT-4.1 Nano Detail View") {
    NavigationStack { // Wrap in NavStack for title display
         GPT41NanoDetailView()
    }
}

#Preview("Featured Card (Nano)") {
    let model = OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1, ownedBy: "openai", shortDescription: "Fastest, most cost-effective GPT-4.1.")
    return FeaturedModelCard(model: model)
        .padding().frame(width: 280)
}

#Preview("Standard Row (Nano)") {
     let model = OpenAIModel(id: "gpt-4.1-nano", object: "model", created: 1, ownedBy: "openai", shortDescription: "Fastest, most cost-effective GPT-4.1.")
     return StandardModelRow(model: model)
        .padding().frame(width: 350)
}

#Preview("API Key Input Sheet") { /* ... unchanged ... */
    struct SheetPresenter: View { @State var showSheet = true; var body: some View { Text("Tap to show sheet").sheet(isPresented: $showSheet) { APIKeyInputView(onSave: {_ in}, onCancel: {}) } } }
    return SheetPresenter()
}
