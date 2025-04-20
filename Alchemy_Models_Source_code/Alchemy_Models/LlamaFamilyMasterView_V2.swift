//
//  LlamaFamilyMasterView_V2.swift
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
//  Date: 4/13/25 (Adapted from OpenAI Example, Updated with new screenshots)
//  Version: 1.1 (Llama Adaptation)
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
    case viewer = "Viewer" // For Evals/Datasets repos - Changed icon
    case codeGeneration = "Code Generation" // From Code Llama description
    case safetyClassification = "Safety Classification" // From Llama Guard
    case promptFiltering = "Prompt Filtering" // From Prompt Guard
    case unknown = "Unknown"

    var iconName: String {
        switch self {
        case .textGeneration: return "text.bubble.fill"
        case .imageToText: return "photo.on.rectangle.angled"
        case .viewer: return "rectangle.grid.1x2.fill" // Changed icon for datasets/evals
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
    // Defining separate fetches for models and datasets if they come from different sources
    // For now, combining under one fetch as mock data merges them.
    func fetchLlamaAssets() async throws -> [LlamaModel] // Changed name to reflect models + datasets
}

// MARK: - Data Model

struct LlamaModel: Identifiable, Hashable, Codable {
    let id: String // Repository name, e.g., "meta-llama/Llama-2-7b-hf"
    let family: String // e.g., "Llama 2", "Llama 3.1", "Code Llama", "Llama 3.1 Evals"
    var taskType: LlamaTaskType
    var updatedDate: Date
    var downloads: String? // String to accommodate "k", "M", etc.
    var likes: String?     // String for "k", "M"
    var discussionCount: String? // Optional based on screenshots
    var views: String?       // Added for datasets/evals - eye icon
    var computeUnits: String? // Added for lightning bolt icon

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
            // Specific cleanup for variants
            .replacingOccurrences(of: " FP8", with: " (FP8)")
            .replacingOccurrences(of: " Original", with: " (Original)")
    }

    var iconName: String { taskType.iconName } // Delegate to taskType

    var iconBackgroundColor: Color {
         // Simple color mapping based on family name - can be customized
         let lowerFamily = family.lowercased()
         if lowerFamily.contains("llama 4") { return .purple }
         if lowerFamily.contains("llama 3.3") { return .blue }
         if lowerFamily.contains("llama 3.2 vision") { return .orange } // Differentiate vision
         if lowerFamily.contains("llama 3.2") { return .cyan }
         if lowerFamily.contains("llama 3.1") { return .green }
         if lowerFamily.contains("guard") { return .red } // Group guards
         if lowerFamily.contains("prompt guard") { return .yellow }
         if lowerFamily.contains("code llama") { return .gray }
         if lowerFamily.contains("llama 2") { return .indigo }
         if lowerFamily.contains("evals") || lowerFamily.contains("dataset") { return .brown } // Color for evals/datasets
         return .teal // Default
     }

    // Helper for date formatting
    var formattedUpdateDate: String {
        // Use relative date formatter for "X days ago"
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: updatedDate, relativeTo: Date())

        // Alternative: Static date format
        // let formatter = DateFormatter()
        // formatter.dateStyle = .medium
        // formatter.timeStyle = .none
        // return formatter.string(from: updatedDate)
    }

    // --- Hashable Conformance ---
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: LlamaModel, rhs: LlamaModel) -> Bool { lhs.id == rhs.id }
}

// MARK: - Mock API Service

class MockLlamaAPIService: LlamaAPIServiceProtocol {
    private let mockNetworkDelaySeconds: Double = 0.5

    // Helper to create dates based on "X days ago" from a reference date (e.g., mid-April 2025)
    private func dateFromDaysAgo(_ days: Int, referenceDate: Date = Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 13))!) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: referenceDate) ?? referenceDate
    }

    // Helper for specific dates
    private func specificDate(year: Int, month: Int, day: Int) -> Date {
         Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
     }

    private func generateMockModels() -> [LlamaModel] {
        // Data meticulously extracted/updated from ALL provided screenshots and text
        // Dates are approximated based on "X days ago" relative to April 13, 2025
        return [
             // --- Llama 4 Models --- (Approx dates from Apr 13, 2025)
             LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(11), downloads: "1.97k", likes: "67", discussionCount: nil, views: nil, computeUnits: nil),
             LlamaModel(id: "meta-llama/Llama-4-Scout-17B-16E", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(11), downloads: "33.6k", likes: "149", discussionCount: nil, views: nil, computeUnits: nil),
             LlamaModel(id: "meta-llama/Llama-4-Scout-17B-16E-Instruct", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(11), downloads: "716k", likes: "800", discussionCount: nil, views: nil, computeUnits: "⚡"), // Assuming bolt means compute
             LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E-Instruct", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(11), downloads: "53.5k", likes: "297", discussionCount: nil, views: nil, computeUnits: "⚡"), // Assuming bolt means compute
             LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(11), downloads: "45.1k", likes: "103", discussionCount: nil, views: nil, computeUnits: "⚡"), // FP8 likely relates to compute/quant
             LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E-Original", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(15), downloads: nil, likes: "66", discussionCount: nil, views: nil, computeUnits: nil),
             LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E-Instruct-Original", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(15), downloads: nil, likes: "32", discussionCount: nil, views: nil, computeUnits: nil),
             LlamaModel(id: "meta-llama/Llama-4-Scout-17B-16E-Original", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(15), downloads: nil, likes: "49", discussionCount: nil, views: nil, computeUnits: nil),
             LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8-Original", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(15), downloads: nil, likes: "29", discussionCount: nil, views: nil, computeUnits: nil), // FP8 + Original
             LlamaModel(id: "meta-llama/Llama-4-Scout-17B-16E-Instruct-Original", family: "Llama 4", taskType: .imageToText, updatedDate: dateFromDaysAgo(15), downloads: nil, likes: "47", discussionCount: nil, views: nil, computeUnits: nil),

            // --- Llama 3.3 Model ---
            LlamaModel(id: "meta-llama/Llama-3.3-70B-Instruct", family: "Llama 3.3", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 12, day: 21), downloads: "1.07M", likes: "2.26k"),

            // --- Llama 3.3 Evals Dataset ---
            LlamaModel(id: "meta-llama/Llama-3.3-70B-Instruct-evals", family: "Llama 3.3 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 12, day: 6), downloads: "439", likes: "36", discussionCount: nil, views: "41.3k", computeUnits: nil),

            // --- Llama 3.2 Language Models ---
            LlamaModel(id: "meta-llama/Llama-3.2-1B", family: "Llama 3.2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 10, day: 24), downloads: "2.07M", likes: "1.84k"),
            LlamaModel(id: "meta-llama/Llama-3.2-1B-Instruct", family: "Llama 3.2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 10, day: 24), downloads: "2.26M", likes: "887"),
            LlamaModel(id: "meta-llama/Llama-3.2-3B", family: "Llama 3.2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 10, day: 24), downloads: "705k", likes: "549"),
            LlamaModel(id: "meta-llama/Llama-3.2-3B-Instruct", family: "Llama 3.2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 10, day: 24), downloads: "1.37M", likes: "1.37k"),

            // --- Llama 3.2 Evals Datasets ---
            LlamaModel(id: "meta-llama/Llama-3.2-1B-evals", family: "Llama 3.2 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 9, day: 25), downloads: "130", likes: "6", views: "48.6k"),
            LlamaModel(id: "meta-llama/Llama-3.2-3B-evals", family: "Llama 3.2 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 9, day: 25), downloads: "229", likes: "7", views: "48.6k"),
            LlamaModel(id: "meta-llama/Llama-3.2-1B-Instruct-evals", family: "Llama 3.2 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 9, day: 25), downloads: "352", likes: nil, views: "142k"), // Likes not visible in dataset section
            LlamaModel(id: "meta-llama/Llama-3.2-3B-Instruct-evals", family: "Llama 3.2 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 9, day: 25), downloads: "321", likes: "13", views: "142k"),

            // --- Llama 3.2 Vision Models ---
            LlamaModel(id: "meta-llama/Llama-3.2-11B-Vision", family: "Llama 3.2 Vision", taskType: .imageToText, updatedDate: specificDate(year: 2024, month: 9, day: 26), downloads: "38k", likes: "508"),
            LlamaModel(id: "meta-llama/Llama-3.2-11B-Vision-Instruct", family: "Llama 3.2 Vision", taskType: .imageToText, updatedDate: specificDate(year: 2024, month: 9, day: 26), downloads: "1.09M", likes: "1.42k"),
            LlamaModel(id: "meta-llama/Llama-3.2-90B-Vision", family: "Llama 3.2 Vision", taskType: .imageToText, updatedDate: specificDate(year: 2024, month: 9, day: 26), downloads: "3.09k", likes: "128"),
            LlamaModel(id: "meta-llama/Llama-3.2-90B-Vision-Instruct", family: "Llama 3.2 Vision", taskType: .imageToText, updatedDate: specificDate(year: 2024, month: 9, day: 26)), // No stats

            // --- Llama 3.1 Models ---
            LlamaModel(id: "meta-llama/Llama-3.1-8B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 10, day: 16), downloads: "992k", likes: "1.57k"),
            LlamaModel(id: "meta-llama/Llama-3.1-8B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 9, day: 25), downloads: "6.16M", likes: "3.86k"),
            LlamaModel(id: "meta-llama/Llama-3.1-70B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 9, day: 25), downloads: "139k", likes: "356"),
            LlamaModel(id: "meta-llama/Llama-3.1-70B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 12, day: 14)),// From Meta-Llama-3 screenshot
            LlamaModel(id: "meta-llama/Llama-3.1-405B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 9, day: 25), downloads: "20.4k", likes: "925"),
            LlamaModel(id: "meta-llama/Llama-3.1-405B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 9, day: 25)), // Assuming exists
            // Merged Meta-Llama-3 entries (assuming they are Llama 3.1)
            LlamaModel(id: "meta-llama/Meta-Llama-3-8B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 9, day: 27), downloads: "544k", likes: "6.14k"),
            LlamaModel(id: "meta-llama/Meta-Llama-3-8B-Instruct", family: "Llama 3.1", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 9, day: 27), downloads: "1.09M", likes: "3.92k"),
            LlamaModel(id: "meta-llama/Meta-Llama-3-70B", family: "Llama 3.1", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 9, day: 27), downloads: "451k", likes: "1.47k"),

            // --- Llama 3.1 Evals Datasets ---
            LlamaModel(id: "meta-llama/Llama-3.1-8B-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 10, day: 2), downloads: "902", likes: "22", views: "79.7k"),
            LlamaModel(id: "meta-llama/Llama-3.1-8B-Instruct-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 10, day: 2), downloads: "1.29k", likes: "31", views: "158k"),
            LlamaModel(id: "meta-llama/Llama-3.1-70B-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 10, day: 2), downloads: "824", likes: "9", views: "79.7k"),
            LlamaModel(id: "meta-llama/Llama-3.1-70B-Instruct-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 10, day: 2), downloads: "153", likes: "13", views: "158k"),
             LlamaModel(id: "meta-llama/Llama-3.1-405B-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 10, day: 2), downloads: "97", likes: "14", views: "79.7k"),
             LlamaModel(id: "meta-llama/Llama-3.1-405B-Instruct-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: specificDate(year: 2024, month: 10, day: 2), downloads: "68", likes: "21", views: "158k"),

            // --- Llama Guard 3 ---
            LlamaModel(id: "meta-llama/LlamaGuard-3-8B", family: "Llama Guard 3", taskType: .safetyClassification, updatedDate: specificDate(year: 2024, month: 7, day: 23)),

            // --- Prompt Guard ---
            LlamaModel(id: "meta-llama/PromptGuard-86M", family: "Prompt Guard", taskType: .promptFiltering, updatedDate: specificDate(year: 2024, month: 7, day: 23)),

            // --- Llama 2 Family ---
            LlamaModel(id: "meta-llama/Llama-2-7b-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 4, day: 17), downloads: "899k", likes: "2.03k"),
            LlamaModel(id: "meta-llama/Llama-2-13b-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 4, day: 17), downloads: "69.9k", likes: "597"),
            LlamaModel(id: "meta-llama/Llama-2-70b-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 4, day: 17), downloads: "39k", likes: "849"), // Likes might be discussions
            LlamaModel(id: "meta-llama/Llama-2-7b-chat-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 4, day: 17), likes: "586"), // From Meta-Llama2 screenshot
            LlamaModel(id: "meta-llama/Llama-2-13b-chat-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 4, day: 17), likes: "347"),
            LlamaModel(id: "meta-llama/Llama-2-70b-chat-hf", family: "Llama 2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 4, day: 17)),
            // Including Meta-Llama2 named ones
            LlamaModel(id: "meta-llama/Meta-Llama2-7b", family: "Llama 2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 4, day: 17), downloads: "4.31k"),
            LlamaModel(id: "meta-llama/Meta-Llama2-13b", family: "Llama 2", taskType: .textGeneration, updatedDate: specificDate(year: 2024, month: 4, day: 17), likes: "347"), // Stats repeated

            // --- Code Llama Family ---
            LlamaModel(id: "meta-llama/CodeLlama-7b-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14), downloads: "4.95k", likes: "101"),
            LlamaModel(id: "meta-llama/CodeLlama-13b-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14), downloads: "408", likes: "17"),
            LlamaModel(id: "meta-llama/CodeLlama-34b-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14), downloads: "436", likes: "15"),
            LlamaModel(id: "meta-llama/CodeLlama-70b-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14)), // No stats visible
            LlamaModel(id: "meta-llama/CodeLlama-7b-Python-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14)),
            LlamaModel(id: "meta-llama/CodeLlama-7b-Instruct-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14)),
            LlamaModel(id: "meta-llama/CodeLlama-13b-Python-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14)),
            LlamaModel(id: "meta-llama/CodeLlama-13b-Instruct-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14)),
            LlamaModel(id: "meta-llama/CodeLlama-34b-Python-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14)),
            LlamaModel(id: "meta-llama/CodeLlama-34b-Instruct-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14)),
             LlamaModel(id: "meta-llama/CodeLlama-70b-Python-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14)),
             LlamaModel(id: "meta-llama/CodeLlama-70b-Instruct-hf", family: "Code Llama", taskType: .codeGeneration, updatedDate: specificDate(year: 2024, month: 3, day: 14)),

             // --- Llama Guard (Original) ---
             LlamaModel(id: "meta-llama/LlamaGuard-7b", family: "Llama Guard", taskType: .safetyClassification, updatedDate: specificDate(year: 2023, month: 12, day: 1)),
        ]
    }

    func fetchLlamaAssets() async throws -> [LlamaModel] {
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
                .font(.title3) // Slightly larger icon
                .frame(width: 28, height: 28, alignment: .center)
                .foregroundColor(model.iconBackgroundColor)
                .padding(2)

            // Details VStack
            VStack(alignment: .leading, spacing: 5) { // Increased spacing slightly
                Text(model.displayName)
                    .font(.headline) // More prominent name
                    .lineLimit(1)

                // Task Type & Update Date
                HStack(spacing: 6) {
                    Label(model.taskType.rawValue, systemImage: model.taskType.iconName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Text("·")
                         .foregroundColor(.secondary)
                         .fontWeight(.light) // Less prominent separator
                    Text("Updated \(model.formattedUpdateDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Stats (Views, Downloads, Likes, Compute) - display if available
                HStack(spacing: 10) {
                     if let views = model.views {
                         Label(views, systemImage: "eye")
                             .font(.caption2)
                             .foregroundColor(.gray)
                     }
                    if let downloads = model.downloads {
                        Label(downloads, systemImage: "arrow.down.circle")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    if let compute = model.computeUnits {
                        // Displaying bolt as text for simplicity, could use Image
                        Label( String(compute.count), systemImage: "bolt.fill")
                             .font(.caption2)
                             .foregroundColor(.orange) // Color for bolt
                     }
                    if let likes = model.likes {
                        Label(likes, systemImage: "heart")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    // Discussion count removed as it wasn't visible in newer screenshots
                }
                .padding(.top, 2) // Adjust vertical positioning
            }
            Spacer() // Pushes content left
        }
        .padding(.vertical, 10) // Adjust padding
    }
}

// --- Section View (Card Style) ---
struct LlamaSectionCard<Content: View>: View {
    let title: String
    let description: String?
    let models: [LlamaModel] // Accepts LlamaModel
    let isDatasetSection: Bool // Flag to potentially style differently
    @ViewBuilder let content: (LlamaModel) -> Content // Content takes LlamaModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Part
            HStack {
                 // Use different icon for datasets
                 Image(systemName: isDatasetSection ? "cylinder.split.1x2" : "shippingbox")
                      .foregroundColor(.secondary)
                      .font(.title3) // Match title size

                Text(title)
                    .font(.title3.weight(.semibold))
                 Text("(\(models.count))") // Show count in header
                      .font(.title3.weight(.regular))
                      .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "chevron.right") // Navigation indicator
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            if let description = description, !description.isEmpty { // Check if description exists
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            } else if description == nil || description!.isEmpty {
                 // Add a small gap if no description, so list isn't flush with header
                 Spacer().frame(height: 5)
            }

            // List of Models within the card
            VStack(alignment: .leading, spacing: 0) {
                ForEach(models) { model in
                    NavigationLink(value: model) {
                         content(model)
                              .padding(.horizontal)
                    }
                    .buttonStyle(.plain)

                    if model.id != models.last?.id { Divider().padding(.leading) }
                }
            }
            .padding(.bottom, 5)
        }
        .background(Color(.secondarySystemGroupedBackground)) // Card background color
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay( RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1) )
        .padding(.horizontal)
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
        .padding().background(Color(.systemBackground))
    }
}

// --- Header for the main text block (Optional - Can integrate into main view) ---
struct LlamaFamilyInfoHeader: View {
     var body: some View {
         VStack(alignment: .leading, spacing: 15) {
             Text("The Llama Family")
                 .font(.largeTitle.weight(.bold))
             Text("*From Meta*").font(.headline).italic().foregroundColor(.secondary)
             Text("""
             Welcome to the official Hugging Face organization for Llama, Llama Guard, and Prompt Guard models from Meta!

             In order to access models here, please visit a repo of one of the three families and accept the license terms and acceptable use policy. Requests are processed hourly.

             In this organization, you can find models in both the original Meta format as well as the Hugging Face transformers format. You can find:
             """)
             .font(.body)
             Link("Learn more about the models", destination: URL(string: "https://ai.meta.com/llama/")!)
                 .font(.body).padding(.top, 5)
         }
         .padding(.horizontal).padding(.bottom)
     }
}

// --- Detail View Placeholder ---
struct LlamaDetailView: View {
     let model: LlamaModel
     // Basic placeholder - build out as needed
     var body: some View {
         List {
             Section("Overview") {
                 HStack { Text("ID"); Spacer(); Text(model.id).font(.caption).foregroundColor(.secondary)}
                 HStack { Text("Display Name"); Spacer(); Text(model.displayName)}
                 HStack { Text("Family"); Spacer(); Text(model.family)}
                 HStack { Text("Task"); Spacer(); Text(model.taskType.rawValue)}
                 HStack { Text("Updated"); Spacer(); Text(model.formattedUpdateDate)}
             }
             Section("Stats") {
                 if let v = model.views { HStack { Text("Views"); Spacer(); Text(v)} }
                 if let d = model.downloads { HStack { Text("Downloads"); Spacer(); Text(d)} }
                 if let l = model.likes { HStack { Text("Likes"); Spacer(); Text(l)} }
                 if let c = model.computeUnits { HStack { Text("Compute"); Spacer(); Text(c)} }
             }
             // Add more sections for description, etc.
         }
         .navigationTitle("Model Details")
           .navigationBarTitleDisplayMode(.inline)
     }
}

// MARK: - Main Content View

struct LlamaFamilyMasterView: View {
    @State private var allAssets: [LlamaModel] = [] // Changed name
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    private let apiService: LlamaAPIServiceProtocol = MockLlamaAPIService()

    // --- Section Definitions & Filters ---
    // Separate models and datasets (evals)
    private var modelsOnly: [LlamaModel] { allAssets.filter { $0.taskType != .viewer } }
    private var datasetsOnly: [LlamaModel] { allAssets.filter { $0.taskType == .viewer } }

    // Group models by family name for sectioning
    private var modelsByFamily: [String: [LlamaModel]] {
        Dictionary(grouping: modelsOnly.sorted { $0.updatedDate > $1.updatedDate }) { $0.family }
    }
    // Group datasets by family name
    private var datasetsByFamily: [String: [LlamaModel]] {
         Dictionary(grouping: datasetsOnly.sorted { $0.updatedDate > $1.updatedDate }) { $0.family }
     }

    // Define model section order explicitly
    private var modelSectionOrder: [String] = [
         "Llama 4", "Llama 3.3", "Llama 3.2", "Llama 3.2 Vision", "Llama 3.1",
         "Llama Guard 3", "Prompt Guard", "Llama 2", "Code Llama", "Llama Guard"
    ]
    // Define dataset section order explicitly
    private var datasetSectionOrder: [String] = [
         "Llama 3.3 Evals", "Llama 3.2 Evals", "Llama 3.1 Evals"
    ]

    // Descriptions map (can be expanded)
    private func description(for family: String) -> String? {
         // Add descriptions if needed, reusing from previous version
         return nil // Placeholder - keeping sections cleaner for now
     }

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading && allAssets.isEmpty {
                    ProgressView("Loading Assets...").frame(maxWidth: .infinity, maxHeight: .infinity).background(.regularMaterial).zIndex(1)
                } else if let errorMessage = errorMessage, allAssets.isEmpty {
                    LlamaErrorView(errorMessage: errorMessage) { loadAssets() }.zIndex(1)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) { // Increased spacing
                           // Optional: Integrate header here directly
                           // LlamaFamilyInfoHeader()

                            // --- Models Section ---
                            HStack {
                                 Image(systemName: "shippingbox.fill") // Icon for Models
                                 Text("Models")
                                     .font(.title2.weight(.bold))
                                 Text("(\(modelsOnly.count))") // Display count
                                     .font(.title2)
                                     .foregroundColor(.secondary)
                                 Spacer()
                                 // Search Icon Placeholder
                                 Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                             }
                             .padding(.horizontal)
                             .padding(.top) // Add padding above the first section header

                            HStack {
                                Spacer() // Push sort button to the right
                                Button { /* Add Sort Action */ } label: {
                                    Label("Sort: Recently updated", systemImage: "arrow.up.arrow.down")
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .tint(.secondary) // Subtle button color
                            }
                            .padding(.horizontal)

                            ForEach(modelSectionOrder, id: \.self) { familyName in
                                if let models = modelsByFamily[familyName], !models.isEmpty {
                                    LlamaSectionCard(
                                        title: familyName,
                                        description: description(for: familyName),
                                        models: models,
                                        isDatasetSection: false // Mark as model section
                                    ) { model in LlamaModelRow(model: model) }
                                }
                            }

                            // --- Datasets Section ---
                             Divider().padding(.vertical, 10)

                             HStack {
                                  Image(systemName: "cylinder.split.1x2.fill") // Icon for Datasets
                                  Text("Datasets")
                                      .font(.title2.weight(.bold))
                                  Text("(\(datasetsOnly.count))") // Display count
                                      .font(.title2)
                                      .foregroundColor(.secondary)
                                  Spacer()
                                  // Search Icon Placeholder
                                  Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                              }
                              .padding([.horizontal])

                             HStack {
                                 Spacer() // Push sort button to the right
                                 Button { /* Add Sort Action */ } label: {
                                     Label("Sort: Recently updated", systemImage: "arrow.up.arrow.down")
                                 }
                                 .font(.caption)
                                 .buttonStyle(.bordered)
                                 .tint(.secondary)
                             }
                             .padding(.horizontal)

                             ForEach(datasetSectionOrder, id: \.self) { familyName in
                                 if let datasets = datasetsByFamily[familyName], !datasets.isEmpty {
                                     LlamaSectionCard(
                                         title: familyName,
                                         description: description(for: familyName),
                                         models: datasets,
                                         isDatasetSection: true // Mark as dataset section
                                     ) { dataset in LlamaModelRow(model: dataset) }
                                 }
                             }

                            Spacer(minLength: 30)
                        }
                    }
                    .background(Color(.systemBackground))
                    .navigationTitle("Llama Family Assets") // More generic title
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button { loadAssets() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                                .disabled(isLoading)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            if isLoading { ProgressView().controlSize(.small) }
                        }
                    }
                    .navigationDestination(for: LlamaModel.self) { asset in
                         LlamaDetailView(model: asset) // Use the placeholder detail view
                     }
                }
            }
            .task { if allAssets.isEmpty { loadAssets() } } // Load only if empty
            .refreshable { await loadAssetsAsync() }
        }
    }

    // --- Data Loading ---
    private func loadAssets() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task { await loadAssetsAsync() }
    }

    @MainActor
    private func loadAssetsAsync() async {
        if !isLoading { isLoading = true }
        errorMessage = nil // Clear error message on new load attempt
        print("🔄 Loading Llama assets using \(type(of: apiService))...")
        do {
            let fetchedAssets = try await apiService.fetchLlamaAssets()
            self.allAssets = fetchedAssets
            print("✅ Successfully loaded \(fetchedAssets.count) Llama assets.")
        } catch let error as LocalizedError {
            print("❌ Error loading Llama assets: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            // Only clear if the initial load failed
            if allAssets.isEmpty { self.allAssets = [] }
        } catch {
            print("❌ Unexpected error loading Llama assets: \(error)")
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            if allAssets.isEmpty { self.allAssets = [] }
        }
        isLoading = false
    }
}

// MARK: - Previews

#Preview("Llama Family View (Mock)") {
    LlamaFamilyMasterView()
}

//#Preview("Llama Model Row (Model)") {
//    let model = LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E-Instruct", family: "Llama 4", taskType: .imageToText, updatedDate: Date().addingTimeInterval(-86400 * 11), downloads: "53.5k", likes: "297", computeUnits: "⚡")
//    LlamaModelRow(model: model)
//        .padding().background(Color(.secondarySystemGroupedBackground))
//}
//
//#Preview("Llama Model Row (Dataset/Evals)") {
//     let model = LlamaModel(id: "meta-llama/Llama-3.1-8B-Instruct-evals", family: "Llama 3.1 Evals", taskType: .viewer, updatedDate: Date().addingTimeInterval(-86400*180), downloads: "1.29k", likes: "31", views: "158k")
//    LlamaModelRow(model: model)
//         .padding().background(Color(.secondarySystemGroupedBackground))
// }
//
//#Preview("Llama Section Card (Models)") {
//    let mockService = MockLlamaAPIService()
//    let models = try! await mockService.fetchLlamaAssets().filter { $0.family == "Llama 4" }
//
//    NavigationView {
//        ScrollView {
//            LlamaSectionCard(title: "Llama 4", description: "Natively multimodal models leveraging mixture-of-experts.", models: models, isDatasetSection: false) { model in
//                LlamaModelRow(model: model)
//            }
//        }
//    }
//}
//
//#Preview("Llama Section Card (Datasets)") {
//    let mockService = MockLlamaAPIService()
//    let models = try! await mockService.fetchLlamaAssets().filter { $0.family == "Llama 3.1 Evals" }
//
//    NavigationView {
//        ScrollView {
//            LlamaSectionCard(title: "Llama 3.1 Evals", description: "Detailed benchmark metrics.", models: models, isDatasetSection: true) { model in
//                LlamaModelRow(model: model)
//            }
//        }
//    }
//}

#Preview("Llama Error View") {
    LlamaErrorView(errorMessage: "Could not connect to the server.") {}
}
//
//#Preview("Llama Detail View Placeholder") {
//     let model = LlamaModel(id: "meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8", family: "Llama 4", taskType: .imageToText, updatedDate: Date().addingTimeInterval(-86400 * 11), downloads: "45.1k", likes: "103", views: nil, computeUnits: "⚡")
//    NavigationView { LlamaDetailView(model: model) }
//}
