//
//  LlamaFamilyMasterView.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  LlamaFamilyMasterView.swift
//  Alchemy_Models_Combined
//  (Single File Implementation for Llama Family)
//
//  Created: Cong Le
//  Date: 4/13/25 (Adapted from OpenAI Example)
//  Version: 1.0 (Llama Adaptation)
//  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
//  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
//
//  Disclaimer:
//  This document contains personal notes on the topic, compiled from publicly
//  available documentation and various cited sources (like the provided text/screenshots).
//  The materials are intended for educational purposes, personal study, and reference.
//  API details and model data are based on the provided context and may need
//  updates if the source information changes. Data fetching uses a mock service.

import SwiftUI
import Foundation

// MARK: - Enums (Task Types, Errors - Optional but good practice)

// Define task types observed in the data
enum LlamaTaskType: String, Codable, Hashable, CaseIterable {
    case textGeneration = "Text Generation"
    case imageToText = "Image-To-Text"
    case viewer = "Viewer" // For Evals repos
    case codeGeneration = "Code Generation" // From Code Llama description
    case safetyClassification = "Safety Classification" // From Llama Guard
    case promptFiltering = "Prompt Filtering" // From Prompt Guard
    case unknown = "Unknown"

    var iconName: String {
        switch self {
        case .textGeneration: return "text.bubble.fill"
        case .imageToText: return "photo.on.rectangle.angled"
        case .viewer: return "eye.fill"
        case .codeGeneration: return "chevron.left.forwardslash.chevron.right"
        case .safetyClassification: return "shield.lefthalf.filled"
        case .promptFiltering: return "line.3.horizontal.decrease.circle.fill"
        case .unknown: return "questionmark.diamond.fill"
        }
    }
}

// Basic Error structure (can be expanded if using live API later)
enum DataFetchError: Error, LocalizedError {
    case loadFailed(Error? = nil)
    var errorDescription: String? {
        switch self {
        case .loadFailed(let underlyingError):
            return "Failed to load model data. \(underlyingError?.localizedDescription ?? "")"
        }
    }
}

// MARK: - API Service Protocol

// Protocol allows switching between mock and potentially live data later
protocol LlamaAPIServiceProtocol {
    func fetchLlamaModels() async throws -> [LlamaModel]
}

// MARK: - Data Model

struct LlamaModel: Identifiable, Hashable, Codable {
    let id: String // Repository name, e.g., "meta-llama/Llama-2-7b-hf"
    let family: String // e.g., "Llama 2", "Llama 3.1", "Code Llama"
    var taskType: LlamaTaskType
    var updatedDate: Date
    var downloads: String? // String to accommodate "k", "M", etc.
    var likes: String?     // String for "k", "M"
    var discussionCount: String? // New field from screenshot (optional)

    // Computed properties for UI display
    var displayName: String {
        // Attempt to create a cleaner display name
        let parts = id.split(separator: "/")
        guard parts.count == 2 else { return id } // Fallback
        let namePart = String(parts[1])
        // Basic replacements, can be made more sophisticated
        return namePart
            .replacingOccurrences(of: "meta-llama-", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Llama-", with: "Llama ", options: .caseInsensitive)
            .replacingOccurrences(of: "CodeLlama-", with: "CodeLlama ", options: .caseInsensitive)
            .replacingOccurrences(of: "-", with: " ")
    }

    var iconName: String { taskType.iconName } // Delegate to taskType

    var iconBackgroundColor: Color {
        // Simple color mapping based on family name - can be customized
        let lowerFamily = family.lowercased()
        if lowerFamily.contains("llama 4") { return .purple }
        if lowerFamily.contains("llama 3.3") { return .blue }
        if lowerFamily.contains("llama 3.2") { return .cyan }
        if lowerFamily.contains("llama 3.1") { return .green }
        if lowerFamily.contains("llama guard 3") || lowerFamily.contains("llama guard") { return .orange }
        if lowerFamily.contains("prompt guard") { return .yellow }
        if lowerFamily.contains("code llama") { return .gray }
        if lowerFamily.contains("llama 2") { return .indigo }
        return .teal // Default
    }

    // Helper for date formatting
    var formattedUpdateDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: updatedDate)
    }

    // --- Hashable Conformance ---
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: LlamaModel, rhs: LlamaModel) -> Bool { lhs.id == rhs.id }
}

// MARK: - Mock API Service

class MockLlamaAPIService: LlamaAPIServiceProtocol {
    private let mockNetworkDelaySeconds: Double = 0.5

    // Helper to create dates - adjust dates to be somewhat realistic relative to screenshots
    private func date(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func generateMockModels() -> [LlamaModel] {
        // Data meticulously extracted from screenshots and text description
        return [
            // --- Llama 4 ---
            LlamaModel(id: "meta-llama/Llama-4-Scout-17B-16E", family: "Llama 4", taskType: .imageToText, updatedDate: date(year: 2025, month: 4, day: 2), downloads: "716k", likes: "800", discussionCount: nil), // Approx date
            LlamaModel(id: "meta-llama/Llama-4-Scout-17B-16E-Instruct", family: "Llama 4", taskType: .imageToText, updatedDate: date(year: 2025, month: 4, day: 2), downloads: "33.6k", likes: "149", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E", family: "Llama 4", taskType: .imageToText, updatedDate: date(year: 2025, month: 4, day: 2), downloads: "53.5k", likes: "297", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8", family: "Llama 4", taskType: .imageToText, updatedDate: date(year: 2025, month: 4, day: 2), downloads: nil, likes: nil, discussionCount: nil), // Assuming FP8 means Image-to-Text

             // --- Llama 3.3 ---
            LlamaModel(id: "meta-llama/Llama-3.3-70B-Instruct", family: "Llama 3.3", taskType: .textGeneration, updatedDate: date(year: 2024, month: 12, day: 21), downloads: "1.07M", likes: "2.26k", discussionCount: nil),

            // --- Llama 3.3 Evals --- (Marked as Viewer)
            LlamaModel(id: "meta-llama/Llama-3.3-70B-Instruct-evals", family: "Llama 3.3 Evals", taskType: .viewer, updatedDate: date(year: 2024, month: 12, day: 6), downloads: "41.3k", likes: "36", discussionCount: nil),

            // --- Llama 3.2 Language ---
            LlamaModel(id: "meta-llama/Llama-3.2-1B", family: "Llama 3.2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 10, day: 24), downloads: "2.07M", likes: "1.84k", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-3.2-1B-Instruct", family: "Llama 3.2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 10, day: 24), downloads: "2.26M", likes: "887", discussionCount: nil), // Likes might be discussion
            LlamaModel(id: "meta-llama/Llama-3.2-3B", family: "Llama 3.2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 10, day: 24), downloads: "705k", likes: "549", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-3.2-3B-Instruct", family: "Llama 3.2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 10, day: 24), downloads: "1.37M", likes: "1.37k", discussionCount: nil),

             // --- Llama 3.2 Evals --- (Marked as Viewer)
             LlamaModel(id: "meta-llama/Llama-3.2-1B-Instruct-evals", family: "Llama 3.2 Evals", taskType: .viewer, updatedDate: date(year: 2024, month: 10, day: 24), downloads: "142k", likes: "352", discussionCount: nil), // Downloads/likes look different on second screenshot? Using first one.
             LlamaModel(id: "meta-llama/Llama-3.2-3B-Instruct-evals", family: "Llama 3.2 Evals", taskType: .viewer, updatedDate: date(year: 2024, month: 10, day: 24), downloads: "142k", likes: "321", discussionCount: nil), // Using first screenshot values

            // --- Llama 3.2 Vision ---
            LlamaModel(id: "meta-llama/Llama-3.2-11B-Vision", family: "Llama 3.2 Vision", taskType: .imageToText, updatedDate: date(year: 2024, month: 9, day: 26), downloads: "38k", likes: "508", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-3.2-11B-Vision-Instruct", family: "Llama 3.2 Vision", taskType: .imageToText, updatedDate: date(year: 2024, month: 9, day: 26), downloads: "1.09M", likes: "1.42k", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-3.2-90B-Vision", family: "Llama 3.2 Vision", taskType: .imageToText, updatedDate: date(year: 2024, month: 9, day: 26), downloads: "3.09k", likes: "128", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-3.2-90B-Vision-Instruct", family: "Llama 3.2 Vision", taskType: .imageToText, updatedDate: date(year: 2024, month: 9, day: 26), downloads: nil, likes: nil, discussionCount: nil), // Not fully visible, assuming exists

             // --- Llama 3.2 Vision Evals --- (Marked as Viewer)
             LlamaModel(id: "meta-llama/Llama-3.2-1B-Vision-evals", family: "Llama 3.2 Evals", taskType: .viewer, updatedDate: date(year: 2024, month: 9, day: 25), downloads: "48.6k", likes: "130", discussionCount: "6"),
             LlamaModel(id: "meta-llama/Llama-3.2-3B-Vision-evals", family: "Llama 3.2 Evals", taskType: .viewer, updatedDate: date(year: 2024, month: 9, day: 25), downloads: "48.6k", likes: "13", discussionCount: "6"), // Likes differ between screenshots, using first

            // --- Llama 3.1 ---
            LlamaModel(id: "meta-llama/Llama-3.1-8B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 10, day: 16), downloads: "992k", likes: "1.57k", discussionCount: nil), // Using first screenshot values
            LlamaModel(id: "meta-llama/Llama-3.1-8B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 9, day: 25), downloads: "6.16M", likes: "3.86k", discussionCount: nil), // Using second screenshot values
            LlamaModel(id: "meta-llama/Llama-3.1-70B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 9, day: 25), downloads: "139k", likes: "356", discussionCount: nil), // Using second screenshot values
            LlamaModel(id: "meta-llama/Llama-3.1-70B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 9, day: 25), downloads: nil, likes: nil, discussionCount: nil), // Assuming exists based on pattern
            LlamaModel(id: "meta-llama/Llama-3.1-405B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 9, day: 25), downloads: "20.4k", likes: "925", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-3.1-405B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 9, day: 25), downloads: nil, likes: nil, discussionCount: nil), // Assuming exists

             // --- Llama 3.1 Evals --- (Marked as Viewer)
            LlamaModel(id: "meta-llama/Llama-3.1-8B-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: date(year: 2024, month: 10, day: 2), downloads: "79.7k", likes: "902", discussionCount: "22"),
            LlamaModel(id: "meta-llama/Llama-3.1-8B-Instruct-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: date(year: 2024, month: 10, day: 2), downloads: "158k", likes: "1.29k", discussionCount: "31"),
            LlamaModel(id: "meta-llama/Llama-3.1-70B-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: date(year: 2024, month: 10, day: 2), downloads: "824", likes: "9", discussionCount: "0"),
            LlamaModel(id: "meta-llama/Llama-3.1-70B-Instruct-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: date(year: 2024, month: 10, day: 2), downloads: nil, likes: nil, discussionCount: nil), // Assuming exists

            // --- Meta Llama 3 --- (Distinct section in one screenshot, likely overlaps Llama 3.1?) -> Merging into Llama 3.1
             LlamaModel(id: "meta-llama/Meta-Llama-3-8B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 9, day: 27), downloads: "544k", likes: "6.14k"), // Treat as Llama 3.1
             LlamaModel(id: "meta-llama/Meta-Llama-3-8B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 9, day: 27), downloads: "1.09M", likes: "3.92k"), // Treat as Llama 3.1
             LlamaModel(id: "meta-llama/Meta-Llama-3-70B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 9, day: 27), downloads: "451k", likes: "1.47k"), // Treat as Llama 3.1
             LlamaModel(id: "meta-llama/Meta-Llama-3-70B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: date(year: 2024, month: 12, day: 14), downloads: nil, likes: nil), // Treat as Llama 3.1

            // --- Llama Guard 3 ---
            LlamaModel(id: "meta-llama/LlamaGuard-3-8B", family: "Llama Guard 3", taskType: .safetyClassification, updatedDate: date(year: 2024, month: 7, day: 23), downloads: nil, likes: nil, discussionCount: nil), // No stats visible

            // --- Prompt Guard ---
            LlamaModel(id: "meta-llama/PromptGuard-86M", family: "Prompt Guard", taskType: .promptFiltering, updatedDate: date(year: 2024, month: 7, day: 23), downloads: nil, likes: nil, discussionCount: nil), // No stats visible

            // --- Llama 2 Family ---
            LlamaModel(id: "meta-llama/Llama-2-7b-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17), downloads: "899k", likes: "2.03k", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-2-13b-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17), downloads: "69.9k", likes: "597", discussionCount: nil),
            LlamaModel(id: "meta-llama/Llama-2-70b-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17), downloads: "39k", likes: "849", discussionCount: nil), // Likes might be discussions
            LlamaModel(id: "meta-llama/Llama-2-7b-chat-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17), downloads: nil, likes: nil, discussionCount: nil), // Stats not visible
            LlamaModel(id: "meta-llama/Llama-2-13b-chat-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17), downloads: nil, likes: "347", discussionCount: nil), // Only likes visible
            LlamaModel(id: "meta-llama/Llama-2-70b-chat-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17), downloads: nil, likes: nil, discussionCount: nil), // Stats not visible

            // --- Code Llama Family ---
            LlamaModel(id: "meta-llama/CodeLlama-7b-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: date(year: 2024, month: 3, day: 14), downloads: "4.95k", likes: "101", discussionCount: nil),
            LlamaModel(id: "meta-llama/CodeLlama-13b-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: date(year: 2024, month: 3, day: 14), downloads: "408", likes: "17", discussionCount: nil),
            LlamaModel(id: "meta-llama/CodeLlama-34b-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: date(year: 2024, month: 3, day: 14), downloads: "436", likes: "15", discussionCount: nil),
            LlamaModel(id: "meta-llama/CodeLlama-70b-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: date(year: 2024, month: 3, day: 14), downloads: nil, likes: nil, discussionCount: nil), // No stats visible
            // Assuming Python and Instruct versions exist based on text description
            LlamaModel(id: "meta-llama/CodeLlama-7b-Python-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: date(year: 2024, month: 3, day: 14), downloads: nil, likes: nil),
            LlamaModel(id: "meta-llama/CodeLlama-7b-Instruct-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: date(year: 2024, month: 3, day: 14), downloads: nil, likes: nil),
            // ... add other code llama sizes/variants if known ...

             // --- Llama Guard (Original) ---
             LlamaModel(id: "meta-llama/LlamaGuard-7b", family: "Llama Guard", taskType: .safetyClassification, updatedDate: date(year: 2023, month: 12, day: 1), downloads: nil, likes: nil), // Approx date

            // --- Meta Llama 2 Models (Seems duplicate of Llama 2 Family) ---
             LlamaModel(id: "meta-llama/Meta-Llama2-7b", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17), downloads: "4.31k"),
             LlamaModel(id: "meta-llama/Meta-Llama2-7b-chat", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17), downloads: nil, likes: "586"),
             LlamaModel(id: "meta-llama/Meta-Llama2-13b", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17), downloads: nil, likes: "347"),
             LlamaModel(id: "meta-llama/Meta-Llama2-13b-chat", family: "Llama 2", taskType: .textGeneration, updatedDate: date(year: 2024, month: 4, day: 17)),

        ]
    }

    func fetchLlamaModels() async throws -> [LlamaModel] {
        try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
        return generateMockModels()
        // throw DataFetchError.loadFailed() // Uncomment to test error state
    }
}

// MARK: - Reusable SwiftUI Helper Views

// --- Row View for displaying a single Llama Model ---
struct LlamaModelRow: View {
    let model: LlamaModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: model.iconName)
                .font(.title3)
                .frame(width: 28, height: 28)
                .foregroundColor(model.iconBackgroundColor)
                .padding(2) // Slight padding around icon

            // Details VStack
            VStack(alignment: .leading, spacing: 4) {
                Text(model.displayName)
                    .font(.headline)
                    .lineLimit(1)

                // Task Type & Update Date
                HStack(spacing: 8) {
                    Label(model.taskType.rawValue, systemImage: model.taskType.iconName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Text("·") // Separator
                         .foregroundColor(.secondary)
                         .fontWeight(.bold)
                    Text("Updated \(model.formattedUpdateDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Stats (Downloads & Likes)
                HStack(spacing: 10) {
                    if let downloads = model.downloads {
                        Label(downloads, systemImage: "arrow.down.circle")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    if let likes = model.likes {
                        Label(likes, systemImage: "heart")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    if let discussions = model.discussionCount {
                        Label(discussions, systemImage: "bubble.left")
                             .font(.caption2)
                             .foregroundColor(.gray)
                     }
                }
                .padding(.top, 1)
            }
            Spacer() // Pushes content left
        }
        .padding(.vertical, 8) // Padding top/bottom within the row
    }
}

// --- Section View (Card Style) ---
struct LlamaSectionCard<Content: View>: View {
    let title: String
    let description: String?
    let models: [LlamaModel]
    @ViewBuilder let content: (LlamaModel) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Part
            HStack {
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right") // Navigation indicator
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            if let description = description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }

            // List of Models within the card
            VStack(alignment: .leading, spacing: 0) {
                ForEach(models) { model in
                    // Use NavigationLink here if detail view is desired
                    NavigationLink(value: model) { // Value-based navigation
                         content(model)
                              .padding(.horizontal)
                    }
                    .buttonStyle(.plain) // Remove default link styling

                    // Add divider except for the last item
                    if model.id != models.last?.id {
                        Divider().padding(.leading) // Indent divider slightly
                    }
                }
            }
            .padding(.bottom, 5) // Padding below the list before card ends

        }
        .background(Color(.secondarySystemGroupedBackground)) // Card background color
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1) // Subtle border
        )
        .padding(.horizontal) // Padding around the card
    }
}

// --- Simple Error View ---
struct LlamaErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Error Loading Data")
                .font(.title2.weight(.semibold))
            Text(errorMessage)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry", systemImage: "arrow.clockwise", action: retryAction)
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
         .background(Color(.systemBackground)) // Adapts to light/dark
    }
}

// --- Simple Header for the main text block ---
struct LlamaFamilyInfoHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("The Llama Family")
                .font(.largeTitle.weight(.bold))
            Text("*From Meta*")
                .font(.headline)
                .italic()
                .foregroundColor(.secondary)

            Text("""
            Welcome to the official Hugging Face organization for Llama, Llama Guard, and Prompt Guard models from Meta!

            In order to access models here, please visit a repo of one of the three families and accept the license terms and acceptable use policy. Requests are processed hourly.

            In this organization, you can find models in both the original Meta format as well as the Hugging Face transformers format. You can find:
            """)
            .font(.body)

            // Could potentially break down the current/history sections further
            // but keeping it simpler for now.

            Link("Learn more about the models", destination: URL(string: "https://ai.meta.com/llama/")!)
                .font(.body)
                .padding(.top, 5)
        }
        .padding(.horizontal)
        .padding(.bottom) // Space after header before sections
    }
}

// MARK: - Main Content View

struct LlamaFamilyMasterView: View {
    // --- State Variables ---
    @State private var allModels: [LlamaModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    // API Service (Using Mock)
    private let apiService: LlamaAPIServiceProtocol = MockLlamaAPIService()

    // --- Section Definitions & Filters ---
    // Group models by family name for sectioning
    private var modelsByFamily: [String: [LlamaModel]] {
        Dictionary(grouping: allModels.sorted { $0.updatedDate > $1.updatedDate }) { $0.family } // Sort within groups
    }

    // Define section order explicitly based on description/screenshots
    private var sectionOrder: [String] = [
         "Llama 4", // Current
         "Llama 3.3",
         "Llama 3.3 Evals",
         "Llama 3.2",
         "Llama 3.2 Vision",
         "Llama 3.2 Evals",
         "Llama 3.1",
         "Llama 3.1 Evals",
         "Llama Guard 3",
         "Prompt Guard",
         "Llama 2",
         "Code Llama",
         "Llama Guard"
         // Add other families if present in data
    ]

    // Provide descriptions for sections based on text/screenshots
    private func description(for family: String) -> String? {
        switch family {
        case "Llama 4": return "Natively multimodal models leveraging mixture-of-experts."
        case "Llama 3.3": return "Text only instruct-tuned model in 70B size."
        case "Llama 3.2": return "Multilingual pretrained and instruction-tuned models (1B, 3B)."
        case "Llama 3.2 Vision": return "Multimodal pretrained and instruction-tuned models (11B, 90B)."
        case "Llama 3.1": return "Pretrained and fine-tuned text models (8B to 405B)."
        case "Llama 3.1 Evals": return "Detailed benchmark metrics for Llama 3.1 models."
        case "Llama 3.3 Evals": return "Detailed benchmark metrics for Llama 3.3 models."
        case "Llama 3.2 Evals": return "Detailed benchmark metrics for Llama 3.2 models."
        case "Llama Guard 3": return "Llama-3.1-8B aligned to safeguard against MLCommons hazards."
        case "Prompt Guard": return "mDeBERTa-v3-base model to categorize inputs (benign, injection, jailbreak)."
        case "Llama 2": return "Collection of pretrained and fine-tuned text models (7B to 70B)."
        case "Code Llama": return "Code-specialized versions of Llama 2 (base, Python, instruct)."
        case "Llama Guard": return "8B Llama 3 safeguard model for classifying inputs/responses."
        default: return nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack { // For Loading / Error Overlay
                if isLoading && allModels.isEmpty {
                    ProgressView("Loading Models...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.regularMaterial)
                        .zIndex(1)
                } else if let errorMessage = errorMessage, allModels.isEmpty {
                     LlamaErrorView(errorMessage: errorMessage) { loadModels() }
                         .zIndex(1)
                } else {
                    // --- Main Scrollable Content ---
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) { // Spacing between sections
                            // Top Informational Header
                            LlamaFamilyInfoHeader()

                            Divider()

                            // Dynamically create sections based on predefined order
                            ForEach(sectionOrder, id: \.self) { familyName in
                                if let models = modelsByFamily[familyName], !models.isEmpty {
                                    LlamaSectionCard(
                                        title: familyName,
                                        description: description(for: familyName),
                                        models: models
                                    ) { model in
                                        LlamaModelRow(model: model)
                                    }
                                }
                            }
                           Spacer(minLength: 30) // Space at bottom
                        }
                    }
                    .background(Color(.systemBackground)) // Use adaptive background
                    .navigationTitle("Llama Family")
                    .navigationBarTitleDisplayMode(.inline) // Keep title compact
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button { loadModels() } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            .disabled(isLoading)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            if isLoading { ProgressView().controlSize(.small) }
                        }
                    }
                    // --- Navigation Destination (Placeholder/Example) ---
                     .navigationDestination(for: LlamaModel.self) { model in
                         // Replace with an actual Detail View if needed
                         VStack(alignment: .leading) {
                             Text(model.displayName).font(.largeTitle)
                             Text(model.id).font(.caption).foregroundColor(.secondary)
                             Text("Family: \(model.family)")
                             Text("Task: \(model.taskType.rawValue)")
                             Text("Updated: \(model.formattedUpdateDate)")
                             if let dl = model.downloads { Text("Downloads: \(dl)") }
                             if let li = model.likes { Text("Likes: \(li)") }
                             Spacer()
                         }
                         .padding()
                         .navigationTitle("Model Detail") // Example Detail
                     }
                }
            }
            .task { loadModels() } // Initial load
            .refreshable { await loadModelsAsync() } // Pull to refresh
        }
    }

    // --- Data Loading ---
     private func loadModels() {
         guard !isLoading else { return }
         isLoading = true
         errorMessage = nil
         Task { await loadModelsAsync() }
     }

     @MainActor // Ensure UI updates happen on the main thread
     private func loadModelsAsync() async {
         // Do not set isLoading = true again if called by refreshable
         if !isLoading { isLoading = true }
         print("🔄 Loading Llama models using \(type(of: apiService))...")
         do {
             let fetchedModels = try await apiService.fetchLlamaModels()
             // Apply any filtering or sorting needed for the main list here if desired
             self.allModels = fetchedModels
             self.errorMessage = nil
             print("✅ Successfully loaded \(fetchedModels.count) Llama models.")
         } catch let error as LocalizedError {
             print("❌ Error loading Llama models: \(error.localizedDescription)")
             self.errorMessage = error.localizedDescription
             // Keep existing models on refresh failure? Or clear? Clearing if initial load fails.
             if allModels.isEmpty { self.allModels = [] }
         } catch {
             print("❌ Unexpected error loading Llama models: \(error)")
             self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
             if allModels.isEmpty { self.allModels = [] }
         }
         isLoading = false
     }
}

// MARK: - Previews

#Preview("Llama Family View (Mock)") {
    LlamaFamilyMasterView()
}

//#Preview("Llama Section Card Example") {
//    let mockService = MockLlamaAPIService()
//    let models = try! await mockService.fetchLlamaModels() // Use try! for preview simplicity
//    let llama2Models = models.filter { $0.family == "Llama 2" }
//
//    NavigationView { // Wrap in NavView for context
//        ScrollView {
//            LlamaSectionCard(title: "Llama 2", description: "A collection of pretrained and fine-tuned text models.", models: llama2Models) { model in
//                LlamaModelRow(model: model)
//            }
//        }
//    }
//}

#Preview("Llama Model Row Example") {
    let model = LlamaModel(id: "meta-llama/Llama-3.1-8B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: Date(), downloads: "6.16M", likes: "3.86k")
    LlamaModelRow(model: model)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
}

#Preview("Llama Error View") {
    LlamaErrorView(errorMessage: "Could not connect to the server. Please check your internet connection.") {}
}
