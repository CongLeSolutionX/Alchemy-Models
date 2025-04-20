//
//  DeepSeekModelsMasterView_V3.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  DeepSeekModelsListView.swift
//  DeepSeek_Models_Viewer
//  (Single File Implementation - Flat List Version)
//
//  Created: Cong Le
//  Date: 4/20/25 (Based on screenshots and previous examples)
//  Version: 2.0 (Refactored for Flat List Layout)
//  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
//  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
//

import SwiftUI
import Foundation // Needed for URL?

// MARK: - API Service Protocol

protocol DeepSeekAPIServiceProtocol {
    func fetchModels() async throws -> [DeepSeekModel]
}

// MARK: - Data Models (Simplified for Flat List)

// Note: Kept PaperInfo in case dataset info is needed later, but not used for models now.
struct PaperInfo: Codable, Hashable, Identifiable {
    var id: String { title }
    let title: String
    let date: String
    let link: URL?
    let reads: String?
}

// Updated DeepSeekModel for the flat list layout
struct DeepSeekModel: Codable, Identifiable, Hashable {
    let id: String // Full model path, e.g., deepseek-ai/DeepSeek-R1
    var displayName: String { // Attempt to create a cleaner display name
        let parts = id.split(separator: "/")
        return parts.count > 1 ? String(parts[1]) : id
    }
    let category: String // e.g., "Text Generation", "Viewer" (for Datasets)
    let lastUpdated: String // e.g., "Updated 24 days ago"
    let downloads: String? // e.g., "1.73M"
    let likes: String? // e.g., "12k"
    let inferenceMetric: String? // New metric represented by bolt icon, e.g., could be ops/s or similar

    // --- Simple Hashable Conformance ---
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: DeepSeekModel, rhs: DeepSeekModel) -> Bool { lhs.id == rhs.id }
}

// Representing the Dataset item shown
struct DeepSeekDataset: Codable, Identifiable, Hashable {
    let id: String // e.g., deepseek-ai/DeepSeek-Prover-V1
    let category: String = "Viewer" // Hardcoded from screenshot
    let lastUpdated: String // e.g., "Updated Sep 12, 2024"
    let filesMetric: String? // Metric with file icon, e.g., "27.5k"
    let downloads: String? // e.g., "571"
    let likes: String? // e.g., "59"

    // --- Simple Hashable Conformance ---
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: DeepSeekDataset, rhs: DeepSeekDataset) -> Bool { lhs.id == rhs.id }
}

// MARK: - API Service Implementations

// --- Mock Data Service ---
class MockDeepSeekService: DeepSeekAPIServiceProtocol {
    private let mockNetworkDelaySeconds: Double = 0.3

    // --- Generate Mock Models Based on the NEW Screenshot ---
    private func generateMockModels() -> [DeepSeekModel] {
        return [
            // Row 1
             DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Zero", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "5.7k", likes: "899", inferenceMetric: nil),
             DeepSeekModel(id: "deepseek-ai/DeepSeek-R1", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "1.73M", likes: "12k", inferenceMetric: "⚡"), // Assuming bolt means something

            // Row 2
             DeepSeekModel(id: "deepseek-ai/DeepSeek-V3-0324", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "243k", likes: "2.68k", inferenceMetric: "⚡"),
             DeepSeekModel(id: "deepseek-ai/DeepSeek-V3", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "749k", likes: "3.81k", inferenceMetric: "⚡"),

            // Row 3
             DeepSeekModel(id: "deepseek-ai/DeepSeek-V3-Base", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "8.75k", likes: "1.63k", inferenceMetric: nil),
             DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B", category: "Text Generation", lastUpdated: "Updated Feb 23", downloads: "1.7M", likes: "1.16k", inferenceMetric: "⚡"), // Added new model

            // Row 4
             DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B", category: "Text Generation", lastUpdated: "Updated Feb 23", downloads: "1.11M", likes: "615", inferenceMetric: nil),
             DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Distill-llama-8B", category: "Text Generation", lastUpdated: "Updated Feb 23", downloads: "870k", likes: "698", inferenceMetric: "⚡"), // Assuming bolt

            // Row 5
            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Distill-Qwen-14B", category: "Text Generation", lastUpdated: "Updated Feb 23", downloads: "908k", likes: "499", inferenceMetric: nil),
            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B", category: "Text Generation", lastUpdated: "Updated Feb 23", downloads: "2.49M", likes: "1.34k", inferenceMetric: "⚡"), // Assuming bolt
             // Add more models if needed to reach the "69" count, or simulate the "Expand" button
        ]
    }

    // We are focusing on Models, but we can add a mock dataset too
    private func generateMockDatasets() -> [DeepSeekDataset] {
        return [
            DeepSeekDataset(id: "deepseek-ai/DeepSeek-Prover-V1", lastUpdated: "Updated Sep 12, 2024", filesMetric: "27.5k", downloads: "571", likes: "59")
        ]
    }

    func fetchModels() async throws -> [DeepSeekModel] {
        try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
        // In a real scenario, you might fetch models and datasets separately.
        // For this mock, we just return models.
        return generateMockModels()
    }

    // Add a separate function if needed for datasets
    func fetchDatasets() async throws -> [DeepSeekDataset] {
        try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
               return generateMockDatasets()
    }
}

// Enum for sections (optional, if you decide to add Datasets later)
enum ContentSection: String, CaseIterable {
    case models = "Models"
    case datasets = "Datasets"
}

// MARK: - Reusable SwiftUI Helper Views

// --- Model Card View (New Row Item) ---
struct ModelCardView: View {
    let model: DeepSeekModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Increased spacing slightly
            // Top Row: Icon and Model ID
            HStack {
                Image(systemName: "cpu.fill") // Consistent icon for all models now
                    .foregroundColor(.secondary)
                    .font(.callout) // Slightly larger default icon
                Text(model.id)
                    .font(.system(.callout, weight: .medium)) // Adjusted font
                    .lineLimit(1)
                Spacer()
            }

            // Second Row: Category and Update Date
            HStack(spacing: 4) { // Reduced spacing
                Image(systemName: "pencil.line") // Icon seen in screenshot
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(model.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("•") // Separator
                     .font(.caption)
                     .foregroundColor(.secondary)
                Text(model.lastUpdated)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Third Row: Metrics
            HStack(spacing: 12) { // Increased spacing between metrics
                MetricView(value: model.downloads, systemImage: "arrow.down.circle")
                // Conditionally display the bolt icon/metric
                if model.inferenceMetric != nil {
                    MetricView(value: nil, systemImage: "bolt.fill") // Show only bolt icon if value is nil
                    // Or if the metric has a value:
                    // MetricView(value: model.inferenceMetric, systemImage: "bolt.fill")
                }
                MetricView(value: model.likes, systemImage: "heart")
                Spacer() // Push metrics left
            }
        }
        .padding(12) // Consistent padding
        .background(Color(.secondarySystemGroupedBackground)) // Background color matching screenshot
        .clipShape(RoundedRectangle(cornerRadius: 8)) // Rounded corners
        .overlay(
             RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5) // Subtle border
        )
    }
}

// --- Dataset Card View ---
struct DatasetCardView: View {
    let dataset: DeepSeekDataset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cylinder.split.1x2.fill") // Icon for dataset
                    .foregroundColor(.secondary)
                    .font(.callout)
                Text(dataset.id)
                    .font(.system(.callout, weight: .medium))
                    .lineLimit(1)
                Spacer()
            }

            HStack(spacing: 4) {
                Image(systemName: "eyeglasses") // Viewer icon
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(dataset.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("•")
                     .font(.caption)
                     .foregroundColor(.secondary)
                Text(dataset.lastUpdated)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack(spacing: 12) {
                MetricView(value: dataset.filesMetric, systemImage: "doc.on.doc") // Files icon
                MetricView(value: dataset.downloads, systemImage: "arrow.down.circle")
                MetricView(value: dataset.likes, systemImage: "heart")
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
             RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// --- Reusable Metric View ---
struct MetricView: View {
    let value: String?
    let systemImage: String

    var body: some View {
        // Only display if there's a value OR if it's the bolt icon (which might be shown always)
        // Updated logic: Only show if value exists OR if it's the special bolt icon
        if let value = value, !value.isEmpty {
             Label(value, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .font(.caption)
                .foregroundColor(.secondary)
        } else if systemImage == "bolt.fill" { // Explicit check for bolt icon display even without value
             Image(systemName: systemImage)
                 .font(.caption)
                 .foregroundColor(.secondary) // Or maybe .yellow ?
        } else if value != nil && value!.isEmpty && systemImage == "bolt.fill" {
             // Handle case where inferenceMetric is "", show only bolt
             Image(systemName: systemImage)
                 .font(.caption)
                 .foregroundColor(.secondary)
        }
        // If value is nil and it's not the bolt icon, display nothing
    }
}

// MARK: - Main Content View (Updated for Flat List)

struct DeepSeekModelsListView: View {
    // --- State Variables ---
    @State private var allModels: [DeepSeekModel] = []
    @State private var allDatasets: [DeepSeekDataset] = [] // Add state for datasets
    @State private var isLoadingModels = false
    @State private var isLoadingDatasets = false
    @State private var modelErrorMessage: String? = nil
    @State private var datasetErrorMessage: String? = nil
    @State private var showAllModels = false // For the "Expand" button

    // --- API Service ---
    // Use concrete type directly if only mock is used, or keep protocol for flexibility
    private let apiService = MockDeepSeekService()

    // Computed property for display limit
    private var displayLimit: Int? {
        showAllModels ? nil : 10 // Show 10 items initially (matches screenshot roughly)
    }

    private var isLoading: Bool { isLoadingModels || isLoadingDatasets }
    private var errorMessage: String? { modelErrorMessage ?? datasetErrorMessage }

    var body: some View {
        NavigationStack {
            List {
                 // --- Models Section ---
                 Section {
                     // Header for Models
                     ListHeaderView(title: "Models", count: allModels.count)

                     // Display subset or all models
                     ForEach(allModels.prefix(displayLimit ?? allModels.count)) { model in
                           NavigationLink { ModelDetailView(model: model) } label: {
                               ModelCardView(model: model)
                           }
                           .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)) // Add inset for spacing
                           .listRowSeparator(.hidden) // Hide default separators
                       }

                     // "Expand Models" Button
                     if !showAllModels && allModels.count > (displayLimit ?? 0) {
                         Button {
                             withAnimation { showAllModels = true }
                         } label: {
                             HStack {
                                 Spacer()
                                 Label("Expand \(allModels.count) models", systemImage: "chevron.down")
                                     .font(.footnote.weight(.medium))
                                     .foregroundColor(.accentColor)
                                 Spacer()
                             }
                         }
                         .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                         .listRowSeparator(.hidden)
                      }

                 } header: { /* Using custom header above */ EmptyView() }
                 .listRowSpacing(0) // Remove spacing between header and rows if needed

                 // --- Datasets Section ---
                 Section {
                     // Header for Datasets
                      ListHeaderView(title: "Datasets", count: allDatasets.count)

                      ForEach(allDatasets) { dataset in
                           NavigationLink { Text("Dataset Detail: \(dataset.id)") } label: {
                               DatasetCardView(dataset: dataset)
                           }
                           .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                           .listRowSeparator(.hidden)
                       }
                 } header: { /* Using custom header above */ EmptyView() }
                 .listRowSpacing(0)
             }
            .listStyle(.grouped) // Use grouped style for headers and background separation
            .navigationTitle("DeepSeek") // Shorter title
             .navigationBarTitleDisplayMode(.inline) // Smaller nav bar
            .toolbar {
                // --- Search Button (Placeholder) ---
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {} label: { Label("Search", systemImage: "magnifyingglass") }
                }
                // --- Sort Button (Placeholder) ---
                 ToolbarItem(placement: .navigationBarTrailing) {
                      Menu {
                          Button("Recently Updated") {}
                          Button("Most Downloads") {}
                          Button("Most Likes") {}
                     } label: {
                         Label("Sort", systemImage: "arrow.up.arrow.down")
                             .font(.caption) // Smaller sort icon
                      }
                 }
            }
            .overlay { // Loading and Error Overlay
                if isLoading && allModels.isEmpty && allDatasets.isEmpty {
                     ProgressView("Loading DeepSeek Content...").frame(maxWidth: .infinity, maxHeight: .infinity).background(.ultraThinMaterial).zIndex(1)
                } else if let errorMessage = errorMessage, allModels.isEmpty && allDatasets.isEmpty {
                      ErrorStateView(message: errorMessage) {
                          attemptLoadContent()
                     } .zIndex(1)
                }
             }
            .task {
                // Load only if data is empty
                if allModels.isEmpty && allDatasets.isEmpty {
                     attemptLoadContent()
                }
             }
            .refreshable {
                 await loadContentAsync()
            }
        }
        .tint(.purple) // Global tint consistent with previous versions
    }

    // --- Helper Functions ---
    private func attemptLoadContent() {
        // Reset state before loading
        modelErrorMessage = nil
        datasetErrorMessage = nil
        showAllModels = false // Reset expand state on refresh
        Task { await loadContentAsync() }
    }

    @MainActor
    private func loadContentAsync() async {
        // Use TaskGroup for concurrent loading
        isLoadingModels = true
        isLoadingDatasets = true

        print("🔄 Loading DeepSeek models and datasets...")
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let fetchedModels = try await apiService.fetchModels()
                    self.allModels = fetchedModels
                    self.modelErrorMessage = nil
                    print("✅ Loaded \(fetchedModels.count) models.")
                } catch {
                     let localizedError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                     print("❌ Error loading models: \(localizedError)")
                     self.modelErrorMessage = localizedError
                     self.allModels = []
                }
                self.isLoadingModels = false
            }

           group.addTask {
                do {
                    let fetchedDatasets = try await apiService.fetchDatasets()
                    self.allDatasets = fetchedDatasets
                    self.datasetErrorMessage = nil
                    print("✅ Loaded \(fetchedDatasets.count) datasets.")
                } catch {
                     let localizedError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                     print("❌ Error loading datasets: \(localizedError)")
                     self.datasetErrorMessage = localizedError
                     self.allDatasets = []
                }
                self.isLoadingDatasets = false
            }
        }
         print("🏁 Loading finished.")
    }
}

// --- Simple Error Overlay View ---
struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40)
                .foregroundColor(.orange) // Changed color
            Text("Error Loading")
                .font(.headline)
                .padding(.top, 5)
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry", action: retryAction)
                .buttonStyle(.bordered)
                .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial) // Use material background
    }
}

// --- Custom List Header ---
struct ListHeaderView: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: title == "Models" ? "cpu.fill" : "cylinder.split.1x2.fill") // Icon based on title
                .font(.headline)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Text("\(count)")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
             // Placeholder Search Button (could be made functional)
             Button {} label: { Image(systemName: "magnifyingglass") }.foregroundColor(.secondary)
        }
        .padding(.vertical, 8) // Add some vertical padding
        .padding(.horizontal) // Padding for inset
        .listRowInsets(EdgeInsets()) // Remove default List Insets for header
    }
}

// --- Placeholder Detail View ---
struct ModelDetailView: View {
    let model: DeepSeekModel
    var body: some View {
        Text("Details for \(model.id)")
            .navigationTitle(model.displayName)
    }
}

// --- Placeholder Dataset Detail View ---
struct DatasetDetailView: View {
    let dataset: DeepSeekDataset
    var body: some View {
        Text("Details for \(dataset.id)")
             .navigationTitle(dataset.id.split(separator: "/").last ?? "Dataset")
    }
}

// MARK: - Previews

#Preview("DeepSeek Flat List") {
    DeepSeekModelsListView()
         .preferredColorScheme(.dark) // Set preview to dark mode
}
