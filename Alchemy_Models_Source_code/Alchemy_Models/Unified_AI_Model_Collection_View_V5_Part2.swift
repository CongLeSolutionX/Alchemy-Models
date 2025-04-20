//
//  Unified_AI_Model_Collection_View_V5.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  Unified_AI_Model_Collection_View_V3_Enhanced.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
// Enhanced by AI Assistant on [Current Date]
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers // Needed for UIPasteboard

// MARK: - Unified Enums and Protocols (Mostly Unchanged)

enum ModelProvider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case gemini = "Gemini"
    case deepseek = "DeepSeek"
    case llama = "Llama"
    var id: String { rawValue }

    var logo: Image {
        switch self {
        case .openai: return Image(systemName: "circle.hexagonpath.fill") // Use filled for picker maybe
        case .gemini: return Image(systemName: "diamond.lefthalf.filled")
        case .deepseek: return Image(systemName: "cube.transparent.fill") // Use filled
        case .llama: return Image(systemName: "hare.fill")
        }
    }

    var palette: Color {
        switch self {
        case .openai: return .indigo
        case .gemini: return .cyan
        case .deepseek: return .purple
        case .llama: return .green
        }
    }
}

enum ModelCapability: String, CaseIterable, Hashable, Identifiable { // Added Identifiable
    case text = "Text"
    case image = "Image"
    case audio = "Audio"
    case video = "Video"
    case code = "Code"
    case embedding = "Embedding"
    case multiModal = "Multi-Modal"
    case vision = "Vision"
    case other = "Other"

    var id: String { rawValue } // Conformance to Identifiable

    var icon: String {
        switch self {
        case .text: return "doc.text.fill"
        case .image: return "photo.fill" // Use filled
        case .audio: return "waveform.path.ecg" // Different icon
        case .video: return "video.fill" // Use filled
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .embedding: return "arrow.down.right.and.arrow.up.left.circle.fill" // Use filled
        case .multiModal: return "circle.hexagongrid.fill"
        case .vision: return "eye.fill" // Use filled
        case .other: return "questionmark.circle.fill" // Use filled
        }
    }
}

// Unified AI Model protocol (Unchanged)
protocol UnifiedAIModel: Identifiable, Hashable, CustomStringConvertible {
    var id: String { get }
    var provider: ModelProvider { get }
    var displayName: String { get }
    var family: String? { get }
    var version: String? { get }
    var owner: String? { get }
    var releaseDate: Date? { get }
    var isPreview: Bool { get }
    var isExperimental: Bool { get }
    var isLive: Bool { get }
    var shortDescription: String? { get }
    var detailedDescription: String? { get }
    var inputCapabilities: [ModelCapability] { get }
    var outputCapabilities: [ModelCapability] { get }
    var tags: [String] { get }
    var popularity: Double? { get }     // E.g. 0.0 to 1.0 scale
    var stats: [String: String] { get } // Other dynamic "metrics"
    var navigationIcon: String { get }
    var displayColor: Color { get }
}

// MARK: - Model Implementations (Unchanged Structs)

struct OpenAIModelUnified: UnifiedAIModel {
    let id: String; let provider: ModelProvider = .openai; let displayName: String
    let family: String?; let version: String?; let owner: String?; let releaseDate: Date?
    let isPreview: Bool; let isExperimental: Bool; let isLive: Bool
    let shortDescription: String?; let detailedDescription: String?
    let inputCapabilities: [ModelCapability]; let outputCapabilities: [ModelCapability]
    let tags: [String]; let popularity: Double?; let stats: [String: String]
    let navigationIcon: String; let displayColor: Color
    var description: String { displayName }
}

struct GeminiModelUnified: UnifiedAIModel {
    let id: String; let provider: ModelProvider = .gemini; let displayName: String
    let family: String?; let version: String?; let owner: String?; let releaseDate: Date?
    let isPreview: Bool; let isExperimental: Bool; let isLive: Bool
    let shortDescription: String?; let detailedDescription: String?
    let inputCapabilities: [ModelCapability]; let outputCapabilities: [ModelCapability]
    let tags: [String]; let popularity: Double?; let stats: [String: String]
    let navigationIcon: String; let displayColor: Color
    var description: String { displayName }
}

struct DeepSeekModelUnified: UnifiedAIModel {
    let id: String; let provider: ModelProvider = .deepseek; let displayName: String
    let family: String?; let version: String?; let owner: String?; let releaseDate: Date?
    let isPreview: Bool; let isExperimental: Bool; let isLive: Bool
    let shortDescription: String?; let detailedDescription: String?
    let inputCapabilities: [ModelCapability]; let outputCapabilities: [ModelCapability]
    let tags: [String]; let popularity: Double?; let stats: [String: String]
    let navigationIcon: String; let displayColor: Color
    var description: String { displayName }
}

struct LlamaModelUnified: UnifiedAIModel {
    let id: String; let provider: ModelProvider = .llama; let displayName: String
    let family: String?; let version: String?; let owner: String?; let releaseDate: Date?
    let isPreview: Bool; let isExperimental: Bool; let isLive: Bool
    let shortDescription: String?; let detailedDescription: String?
    let inputCapabilities: [ModelCapability]; let outputCapabilities: [ModelCapability]
    let tags: [String]; let popularity: Double?; let stats: [String: String]
    let navigationIcon: String; let displayColor: Color
    var description: String { displayName }
}

// MARK: - Mock Data Providers (Expanded)

// Helper for creating dates easily
func daysAgo(_ days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -days, to: Date())!
}

protocol UnifiedModelService {
    func fetchModels() async throws -> [any UnifiedAIModel]
}

struct OpenAIMockProvider: UnifiedModelService {
    func fetchModels() async throws -> [any UnifiedAIModel] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000))
        return [
            OpenAIModelUnified(id: "gpt-4o", displayName: "GPT-4o",
                family: "GPT-4", version: "Omni", owner: "OpenAI", releaseDate: daysAgo(60),
                isPreview: false, isExperimental: false, isLive: true,
                shortDescription: "Fastest, most capable multi-modal model.",
                detailedDescription: "GPT-4o (“o” for “omni”) is our latest flagship model. It can process and generate text, audio, and image inputs and outputs, making it truly multimodal. It matches GPT-4 Turbo performance on text in English and code, with significant improvement on text in non-English languages, while also being much faster and 50% cheaper in the API.",
                inputCapabilities: [.text, .image, .audio, .vision], outputCapabilities: [.text, .image, .audio], tags: ["multimodal", "fast", "flagship", "vision"],
                popularity: 0.98, stats: ["API Price (Input/Output)": "$5/$15 per 1M tokens", "Context Window": "128k tokens"],
                navigationIcon: "bolt.fill", displayColor: .indigo),
            OpenAIModelUnified(id: "gpt-4-turbo", displayName: "GPT-4 Turbo",
                family: "GPT-4", version: "Turbo", owner: "OpenAI", releaseDate: daysAgo(180),
                isPreview: false, isExperimental: false, isLive: true,
                shortDescription: "High-performance model with vision.",
                detailedDescription: "GPT-4 Turbo with Vision is available for developers. It can analyze image inputs provided via the API.",
                inputCapabilities: [.text, .image, .vision], outputCapabilities: [.text], tags: ["vision", "powerful"],
                popularity: 0.92, stats: ["API Price (Input/Output)": "$10/$30 per 1M tokens", "Knowledge Cutoff": "Dec 2023"],
                navigationIcon: "camera.metering.center.weighted", displayColor: .indigo.opacity(0.8)),
            OpenAIModelUnified(id: "dall-e-3", displayName: "DALL·E 3",
                family: "DALL·E", version: "3", owner: "OpenAI", releaseDate: daysAgo(210),
                isPreview: false, isExperimental: false, isLive: true,
                shortDescription: "Advanced image generation model.",
                detailedDescription: "Creates highly detailed and contextually relevant images from text descriptions. Integrates with ChatGPT.",
                inputCapabilities: [.text], outputCapabilities: [.image], tags: ["image generation", "creative"],
                popularity: 0.85, stats: ["Resolution": "Up to 1792x1024", "Styles": "Vivid, Natural"],
                navigationIcon: "paintbrush.fill", displayColor: .teal)
        ]
    }
}

struct GeminiMockProvider: UnifiedModelService {
    func fetchModels() async throws -> [any UnifiedAIModel] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000))
        return [
            GeminiModelUnified(id: "gemini-1.5-pro", displayName: "Gemini 1.5 Pro",
                family: "Gemini", version: "1.5 Pro", owner: "Google", releaseDate: daysAgo(90),
                isPreview: false, isExperimental: false, isLive: true,
                shortDescription: "Enhanced reasoning, long context.",
                detailedDescription: "Mid-size multimodal model optimized for scaling across a wide-range of tasks. Features a breakthrough 1 million token context window.",
                inputCapabilities: [.text, .image, .audio, .video, .code], outputCapabilities: [.text, .code], tags: ["multimodal", "long context", "reasoning"],
                popularity: 0.95, stats: ["Context Window": "1M tokens (Std), 2M (alpha)", "Performance": "Comparable to 1.0 Ultra"],
                navigationIcon: "star.fill", displayColor: .cyan),
            GeminiModelUnified(id: "gemini-1.5-flash", displayName: "Gemini 1.5 Flash",
                family: "Gemini", version: "1.5 Flash", owner: "Google", releaseDate: daysAgo(45),
                isPreview: true, isExperimental: false, isLive: true,
                shortDescription: "Fast, lightweight model for speed.",
                detailedDescription: "A lighter-weight variant of Gemini 1.5 Pro, designed for speed and efficiency while retaining multimodal reasoning and long context.",
                inputCapabilities: [.text, .image, .audio, .video], outputCapabilities: [.text], tags: ["fast", "lightweight", "multimodal"],
                popularity: 0.88, stats: ["Context Window": "1M tokens", "Speed": "Optimized for latency"],
                navigationIcon: "bolt.horizontal.fill", displayColor: .cyan.opacity(0.8)),
              GeminiModelUnified(id: "gemini-1.0-pro", displayName: "Gemini 1.0 Pro",
                    family: "Gemini", version: "1.0 Pro", owner: "Google", releaseDate: daysAgo(240),
                    isPreview: false, isExperimental: false, isLive: true,
                    shortDescription: "Balanced model for general tasks.",
                    detailedDescription: "Google's foundational Gemini model, offering a balance of performance and capability for various tasks.",
                    inputCapabilities: [.text], outputCapabilities: [.text], tags: ["foundational", "general purpose"],
                    popularity: 0.80, stats: ["Availability": "Widely available", "Use Cases": "Chatbots, Summarization"],
                    navigationIcon: "circle.grid.3x3.fill", displayColor: .blue)
        ]
    }
}

struct DeepSeekMockProvider: UnifiedModelService {
     func fetchModels() async throws -> [any UnifiedAIModel] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000))
        return [
            DeepSeekModelUnified(id: "deepseek-llm-67b-chat", displayName: "DeepSeek LLM 67B Chat",
                family: "DeepSeek LLM", version: "67B Chat", owner: "DeepSeek AI", releaseDate: daysAgo(150),
                isPreview: false, isExperimental: false, isLive: true,
                shortDescription: "Large language model for chat.",
                detailedDescription: "A powerful chat model trained from scratch on extensive data, excelling in reasoning and conversation.",
                inputCapabilities: [.text], outputCapabilities: [.text], tags: ["chat", "reasoning", "chinese", "english"],
                popularity: 0.89, stats: ["Training Data": "2T tokens", "Parameters": "67 Billion"],
                navigationIcon: "bubble.left.and.bubble.right.fill", displayColor: .purple),
            DeepSeekModelUnified(id: "deepseek-coder-33b-instruct", displayName: "DeepSeek Coder 33B Instruct",
                family: "DeepSeek Coder", version: "33B Instruct", owner: "DeepSeek AI", releaseDate: daysAgo(120),
                isPreview: false, isExperimental: false, isLive: true,
                shortDescription: "Specialized model for coding tasks.",
                detailedDescription: "Instruction-tuned coding model capable of complex code generation and understanding across multiple programming languages.",
                inputCapabilities: [.text, .code], outputCapabilities: [.code, .text], tags: ["coding", "instruct", "developer tool"],
                popularity: 0.91, stats: ["Supported Languages": "80+", "Training Data": "Project-level code corpus"],
                navigationIcon: "hammer.fill", displayColor: .orange)
        ]
    }
}

struct LlamaMockProvider: UnifiedModelService {
     func fetchModels() async throws -> [any UnifiedAIModel] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000))
        return [
            LlamaModelUnified(id: "meta-llama/Llama-3.1-405B-Instruct", displayName: "Llama 3.1 405B Instruct",
                family: "Llama 3.1", version: "405B Instruct", owner: "Meta", releaseDate: daysAgo(20),
                isPreview: true, isExperimental: false, isLive: true,
                shortDescription: "Most powerful instruction-tuned Llama.",
                detailedDescription: "The largest and most capable model in the Llama 3.1 series, fine-tuned for complex instruction following and reasoning.",
                inputCapabilities: [.text, .code], outputCapabilities: [.text, .code], tags: ["instruct", "large", "state-of-the-art", "reasoning"],
                popularity: 0.96, stats: ["Parameters": "405 Billion", "Context Length": "128K"],
                navigationIcon: "brain.head.profile", displayColor: .green),
            LlamaModelUnified(id: "meta-llama/Llama-3.1-70B-Instruct", displayName: "Llama 3.1 70B Instruct",
                family: "Llama 3.1", version: "70B Instruct", owner: "Meta", releaseDate: daysAgo(25),
                isPreview: false, isExperimental: false, isLive: true,
                shortDescription: "Powerful instruction-tuned model.",
                detailedDescription: "Llama 3.1 with 70B parameters, tuned for following instructions accurately and efficiently.",
                inputCapabilities: [.text], outputCapabilities: [.text], tags: ["instruct", "large", "efficient"],
                popularity: 0.87, stats: ["Performance": "Strong general capabilities", "Availability": "Widely accessible"],
                navigationIcon: "hare.fill", displayColor: .green.opacity(0.8)),
            LlamaModelUnified(id: "meta-llama/Llama-3-8b-Instruct", displayName: "Llama 3 8B Instruct",
                 family: "Llama 3", version: "8B Instruct", owner: "Meta", releaseDate: daysAgo(100),
                 isPreview: false, isExperimental: false, isLive: true,
                 shortDescription: "Fast and capable small model.",
                 detailedDescription: "The smaller, efficient Llama 3 model, great for faster responses and on-device scenarios.",
                 inputCapabilities: [.text], outputCapabilities: [.text], tags: ["instruct", "small", "fast", "mobile"],
                 popularity: 0.82, stats: ["Use Case": "On-device deployment", "Speed": "High throughput"],
                 navigationIcon: "paperplane.fill", displayColor: .lime) // Assuming .lime is defined or use .green.opacity(0.6)
        ]
    }
}

// MARK: - Factory (Unchanged)
struct UnifiedProviderFactory {
    static func provider(for source: ModelProvider) -> UnifiedModelService {
        switch source {
        case .openai: return OpenAIMockProvider()
        case .gemini: return GeminiMockProvider()
        case .deepseek: return DeepSeekMockProvider()
        case .llama: return LlamaMockProvider()
        }
    }
}

// MARK: - Unified ViewModel (Enhanced)

@MainActor
final class UnifiedModelExplorerVM: ObservableObject {

    // --- State Properties ---
    @Published var selection: ModelProvider = .openai // Default provider
    @Published var allModels: [any UnifiedAIModel] = [] // Holds all fetched models for the selected provider
    @Published var search: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var sortOption: SortOption = .popularity // Default sort
    @Published var selectedCapabilities: Set<ModelCapability> = [] // Active capability filters

    // --- Sorting Enum ---
    enum SortOption: String, CaseIterable, Identifiable {
        case popularity = "Popularity"
        case name = "Name (A-Z)"
        case date = "Release Date (Newest)"
        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .popularity: "flame.fill"
            case .name: "textformat.abc"
            case .date: "calendar"
            }
        }
    }

    // --- Loading Logic ---
    func loadModels(clearExisting: Bool = true) {
        if clearExisting {
            allModels = [] // Clear previous models immediately for better UX
        }
        isLoading = true
        error = nil
        Task {
            // Add a small delay if not clearing to let UI update
            if !clearExisting { try? await Task.sleep(nanoseconds: 50_000_000) }
            do {
                let fetched = try await UnifiedProviderFactory.provider(for: selection).fetchModels()
                // No sorting here, sorting happens in computed property
                self.allModels = fetched
            } catch let fetchError {
                self.error = "Failed to load models: \(fetchError.localizedDescription)"
            }
            isLoading = false
        }
    }

    // --- Computed Filtered & Sorted Models ---
    var filteredAndSortedModels: [any UnifiedAIModel] {
        var workingModels = allModels

        // 1. Apply Capability Filters
        if !selectedCapabilities.isEmpty {
            workingModels = workingModels.filter { model in
                // Model must have ALL selected input capabilities
                selectedCapabilities.isSubset(of: Set(model.inputCapabilities))
            }
        }

        // 2. Apply Search Filter
        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            let lowercasedQuery = trimmedSearch.lowercased()
            workingModels = workingModels.filter { model in
                model.displayName.lowercased().contains(lowercasedQuery) ||
                (model.family?.lowercased().contains(lowercasedQuery) ?? false) ||
                model.tags.contains { $0.lowercased().contains(lowercasedQuery) } ||
                model.inputCapabilities.contains { $0.rawValue.lowercased().contains(lowercasedQuery) } ||
                model.outputCapabilities.contains { $0.rawValue.lowercased().contains(lowercasedQuery) }
            }
        }

        // 3. Apply Sorting
        switch sortOption {
        case .popularity:
            workingModels.sort { ($0.popularity ?? 0.0) > ($1.popularity ?? 0.0) }
        case .name:
            workingModels.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .date:
            workingModels.sort { ($0.releaseDate ?? .distantPast) > ($1.releaseDate ?? .distantPast) }
        }

        return workingModels
    }

    // --- Helper for Capability Filtering ---
    func toggleCapabilityFilter(_ capability: ModelCapability) {
        if selectedCapabilities.contains(capability) {
            selectedCapabilities.remove(capability)
        } else {
            selectedCapabilities.insert(capability)
        }
        // No need to reload, computed property handles it
    }

    func isCapabilitySelected(_ capability: ModelCapability) -> Bool {
        selectedCapabilities.contains(capability)
    }

    func clearFilters() {
        selectedCapabilities.removeAll()
        search = ""
        // Reset sort? Optional, maybe keep user's sort preference.
        // sortOption = .popularity
    }

     // --- Get unique capabilities available in the current model list ---
    var availableInputCapabilities: [ModelCapability] {
        let allCaps = allModels.flatMap { $0.inputCapabilities }
        // Maintain order roughly based on ModelCapability definition
        return ModelCapability.allCases.filter { cap in
            allCaps.contains(cap)
        }
    }
}

// Define Color extension if needed (e.g., for .lime)
extension Color {
    static let lime = Color(red: 0.7, green: 1.0, blue: 0.3)
}

// MARK: - Modern SwiftUI Interface (Enhanced)
struct UnifiedModelExplorerView: View {
    @StateObject var vm = UnifiedModelExplorerVM()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                providerPickerBar(vm: vm)
                    .padding(.bottom, 5) // Add some space below picker

                searchAndFilterBar(vm: vm)
                    .padding(.bottom, 10) // More space below search/filter

                contentBody(vm: vm)
            }
            .background(backgroundGradient) // Use computed property
            .navigationTitle("AI Model Explorer")
            .toolbar { toolbarContent } // Use computed property
            .onAppear { vm.loadModels() } // Load on initial appear
            // Use the new onChange signature for iOS 17+ or keep the old one
             .onChange(of: vm.selection) { _, _ in vm.loadModels() } // Reload when provider changes
            // Implicitly updates view via @Published changes for sort/filter/search
        }
    }

    // --- Computed Properties for View Structure ---

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                vm.selection.palette.opacity(colorScheme == .dark ? 0.25 : 0.12), // Adjusted opacity
                colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.8), // Slightly less opaque base
                colorScheme == .dark ? .black : .white // Solid base at bottom
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea(edges: .bottom) // Extend gradient slightly
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if vm.isLoading {
                 ProgressView()
                    .controlSize(.small) // Smaller progress view
                    .padding(.trailing, 5)
            }

             Menu {
                 // Sorting Options
                 Picker("Sort By", selection: $vm.sortOption) {
                     ForEach(UnifiedModelExplorerVM.SortOption.allCases) { option in
                         Label(option.rawValue, systemImage: option.systemImage).tag(option)
                     }
                 }

                 Divider()

                // Filter Options (only show if capabilities exist)
                 if !vm.availableInputCapabilities.isEmpty {
                    Text("Filter by Input Capability") // Section header
                     ForEach(vm.availableInputCapabilities) { capability in
                         Toggle(isOn: Binding( // Custom binding to toggle
                             get: { vm.isCapabilitySelected(capability) },
                             set: { _ in vm.toggleCapabilityFilter(capability) }
                         )) {
                             Label(capability.rawValue, systemImage: capability.icon)
                        }
                     }
                     if !vm.selectedCapabilities.isEmpty {
                        Divider()
                        Button(role: .destructive) {
                            withAnimation { vm.clearFilters() }
                        } label: {
                             Label("Clear All Filters", systemImage: "xmark.circle.fill")
                        }
                    }
                 } else if !vm.search.isEmpty {
                     // Offer clear search if only search is active
                     Button(role: .destructive) {
                         withAnimation { vm.clearFilters() }
                     } label: {
                          Label("Clear Search", systemImage: "xmark.circle.fill")
                     }
                 }

            } label: {
                Label("Filter & Sort", systemImage: "line.3.horizontal.decrease.circle")
                    .imageScale(.large)
                    .symbolRenderingMode(.palette) // Make it colorful potentially
                    .foregroundStyle(Color.accentColor, vm.selectedCapabilities.isEmpty ? Color.secondary.opacity(0.8) : Color.orange) // Indicate active filter
            }
        }
    }

    // --- Subviews ---

    @ViewBuilder
    private func providerPickerBar(vm: UnifiedModelExplorerVM) -> some View {
        // Use standard Label for better accessibility and icon display
        Picker("Provider", selection: $vm.selection) {
            ForEach(ModelProvider.allCases) { provider in
                 Label {
                     Text(provider.rawValue).font(.caption) // Slightly smaller text
                 } icon: {
                     provider.logo
                 }
                 .tag(provider)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        // Add background/padding if needed for visual separation
         .background(Material.thin)
         .padding(.top, 5) // Give it some space from the nav bar
    }

    @ViewBuilder
    private func searchAndFilterBar(vm: UnifiedModelExplorerVM) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search models, tags, capabilities...", text: $vm.search)
                .textFieldStyle(.plain) // Remove default border/bg
                .submitLabel(.search) // Indicate search action on keyboard
            if !vm.search.isEmpty {
                 Button {
                     withAnimation { vm.search = "" } // Clear search smoothly
                 } label: {
                     Image(systemName: "xmark.circle.fill")
                         .foregroundColor(.secondary)
                 }
                 .buttonStyle(.plain) // Remove button styling
            }
        }
        .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)) // Use continuous corner radius
        .padding(.horizontal)
    }

    @ViewBuilder
    private func contentBody(vm: UnifiedModelExplorerVM) -> some View {
        // Use the computed property directly
        let modelsToShow = vm.filteredAndSortedModels

        Group { // Use Group to switch content
            if let err = vm.error {
                ErrorBanner(message: err) { vm.loadModels() }
                    .padding(.top)
                Spacer() // Push error banner up if list is empty
            } else if vm.isLoading && modelsToShow.isEmpty {
                 // Show loading indicator only if the list is currently empty during load
                ProgressView("Loading Models...")
                     .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if modelsToShow.isEmpty && !vm.isLoading {
                 // Handle empty state based on whether filters/search are active
                let title = vm.search.isEmpty && vm.selectedCapabilities.isEmpty
                    ? "No models available for \(vm.selection.rawValue)"
                    : "No models match your criteria"
                 let systemImage = vm.search.isEmpty && vm.selectedCapabilities.isEmpty
                    ? "tray.fill" : "magnifyingglass"

                 ContentUnavailableView {
                     Label(title, systemImage: systemImage)
                 } description: {
                     if !(vm.search.isEmpty && vm.selectedCapabilities.isEmpty) {
                         Text("Try adjusting your search or filters.")
                         Button("Clear Search & Filters") {
                             withAnimation { vm.clearFilters()}
                         }
                         .padding(.top, 5)
                         .buttonStyle(.bordered)
                     } else {
                        Text("There might be no models listed for this provider yet, or check your connection.")
                     }
                 }
                 .frame(maxWidth: .infinity, maxHeight: .infinity)

             } else {
                modelScrollList(models: modelsToShow) // Pass models directly
            }
        }
    }

    @ViewBuilder
    private func modelScrollList(models: [any UnifiedAIModel]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 15) {
                ForEach(models, id: \.id) { model in
                    NavigationLink(value: model) { // Use NavigationLink(value:) for typed navigation
                        ModelCardUnifiedView(model: model)
                    }
                    .buttonStyle(.plain) // Keep content look native
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10) // Consistent vertical padding
        }
        // Define the navigation destination for the UnifiedAIModel type
        .navigationDestination(for: UnifiedAIModel.self) { model in
             ModelDetailUnifiedView(model: model) // Navigate to detail view
        }
        .refreshable { // Allow pull-to-refresh
             print("Refreshing models for \(vm.selection.rawValue)...")
             await vm.loadModels(clearExisting: false) // Use async version
        }
    }
}

struct ErrorBanner: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        HStack(spacing: 10) { // Increased spacing
            Image(systemName: "exclamationmark.triangle.fill") // Changed icon
                .foregroundColor(.red)
                .imageScale(.large)
            Text(message)
                .font(.callout) // Slightly larger font
                .lineLimit(2) // Allow wrapping
            Spacer()
            Button {
                retry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise") // Changed icon
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
            }
            .buttonStyle(.bordered) // Give button some visual distinctness
            .tint(.secondary)
        }
        .padding() // More padding
        .background(.ultraThinMaterial) // Changed material slightly
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)) // Nicer corners
        .padding(.horizontal)
    }
}

// MARK: - Card UI (Minor adjustments)

struct ModelCardUnifiedView: View {
    let model: any UnifiedAIModel
    var body: some View {
        HStack(alignment: .top, spacing: 15) { // Slightly less spacing
            model.provider.logo // Use provider logo directly
                 .font(.system(size: 28, weight: .medium)) // Slightly smaller, less bold
                 .foregroundColor(model.displayColor)
                 .frame(width: 45, height: 45)
                 .background(model.displayColor.opacity(0.1)) // Add subtle background
                .clipShape(Circle()) // Clip as circle

            VStack(alignment: .leading, spacing: 5) { // Increased spacing
                HStack(alignment: .firstTextBaseline) { // Align text better
                    Text(model.displayName)
                        .font(.headline)
                        .lineLimit(1) // Ensure single line
                    Spacer() // Push flags right
                     // Flags - slightly smaller
                    if model.isPreview { flag("Preview", .orange, size: .caption2) }
                    if model.isExperimental { flag("Exp", .pink, size: .caption2) }
                    if model.isLive { flag("Live", .green, size: .caption2) }
                }

                 // Description
                if let desc = model.shortDescription {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true) // Ensure wrapping works correctly
                } else {
                    // Placeholder if no description
                    Text("No description available.")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.6))
                        .italic()
                }

                // Capabilities & Popularity - use WrappingHStack for capabilities
                 WrappingHStack(items: model.inputCapabilities, viewForItem: capabilityBadge)
                    .padding(.top, 3) // Space before capabilities

                 // Conditionally show popularity
                 if let pop = model.popularity, pop > 0 { // Only show if meaningful
                    HStack {
                        Spacer() // Push popularity to the right
                        popularityView(pop)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding()
        .background(.thickMaterial.opacity(0.4)) // Slightly more opaque material
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Slightly larger radius
         .overlay( // Add subtle border
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(model.displayColor.opacity(0.2), lineWidth: 1)
         )
    }

     @ViewBuilder
    private func capabilityBadge(_ capability: ModelCapability) -> some View {
         Label(capability.rawValue, systemImage: capability.icon)
            .font(.caption) // Consistent size
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(model.displayColor.opacity(0.12)) // Slightly stronger bg
            .foregroundStyle(model.displayColor) // Use foregroundStyle
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func popularityView(_ pop: Double) -> some View {
        HStack(spacing: 3) {
             Image(systemName: "flame.fill")
             Text("\(Int(pop * 100))%") // Show as percentage
        }
        .font(.caption.weight(.medium)) // Medium weight
        .foregroundColor(.orange) // Use orange for popularity/flame
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.15))
        .clipShape(Capsule())
    }

     // Unified flag view builder
    @ViewBuilder
    private func flag(_ value: String, _ color: Color, size: Font = .caption2) -> some View {
        Text(value)
            .font(size).bold()
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// MARK: - Detail View UI (Enhanced with Actions)

struct ModelDetailUnifiedView: View {
    let model: any UnifiedAIModel
    @State private var isFavorite: Bool = false // Mock favorite state
    @State private var showCopiedAlert: Bool = false // Feedback for copy action

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { // Increased spacing
                headerSection
                descriptionSection
                capabilitiesSection
                tagsSection
                metricsSection
                metadataSection // Added for owner, date etc.
            }
            .padding()
            // .frame(maxWidth: 700) // Allow slightly wider on larger screens
        }
        .navigationTitle(model.displayName)
        .navigationBarTitleDisplayMode(.inline) // Keep title inline
        .toolbar { detailToolbar } // Use computed property
        .alert("Model ID Copied", isPresented: $showCopiedAlert) {
             Button("OK", role: .cancel) { }
        } message: {
             Text("'\(model.id)' copied to clipboard.")
        }
        .onAppear {
            // In a real app, load favorite status from persistence
            // isFavorite = PersistenceService.shared.isFavorite(modelId: model.id)
            print("Detail view appeared for \(model.id). Current mock favorite status: \(isFavorite)")
        }
    }

    // --- Computed Properties for View Sections ---

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 15) { // Center alignment
            model.provider.logo // Use provider logo
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64) // Slightly smaller
                .foregroundColor(model.displayColor)
                .padding(10) // Padding inside background
                 .background(model.displayColor.opacity(0.1))
                 .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Consistent radius

            VStack(alignment: .leading, spacing: 6) {
                Text(model.displayName).font(.title.weight(.semibold)) // Semibold Title
                // Provider, Family, Version Row
                HStack(spacing: 8) {
                    providerBadge(model.provider)
                    if let fam = model.family { familyBadge(fam) }
                    if let ver = model.version { versionBadge(ver) }
                }
                // Flags Row
                HStack(spacing: 6) {
                    if model.isPreview { flag("Preview", .orange) }
                    if model.isExperimental { flag("Exp", .pink) }
                    if model.isLive { flag("Live", .green) }
                     // Add popularity here too?
                    if let pop = model.popularity, pop > 0.5 { // Show if somewhat popular
                        popularityBadge(pop)
                    }
                }
            }
            Spacer() // Push content left
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let desc = model.detailedDescription {
            VStack(alignment: .leading) {
                 Text("Description").font(.headline).padding(.bottom, 2)
                Text(desc)
                    .font(.body) // Use body font for readability
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var capabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !model.inputCapabilities.isEmpty {
                 sectionView("Input Capabilities", items: model.inputCapabilities, viewForItem: capabilityDetailBadge)
            }
            if !model.outputCapabilities.isEmpty {
                 sectionView("Output Capabilities", items: model.outputCapabilities, viewForItem: capabilityDetailBadge)
            }
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        if !model.tags.isEmpty {
           sectionView("Tags", items: model.tags, viewForItem: tagBadge)
        }
    }

    @ViewBuilder
    private var metricsSection: some View {
        if !model.stats.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance Metrics") // Better title
                    .font(.headline)
                 Divider().padding(.bottom, 5)
                ForEach(model.stats.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack(alignment: .firstTextBaseline) { // Align text nicely
                        Text("\(key.capitalized):")
                            .font(.caption.weight(.medium)) // Caption for key
                            .foregroundColor(.secondary)
                            .frame(width: 140, alignment: .trailing) // Increased width for keys
                        Text(value)
                            .font(.callout) // Callout for value
                            .bold()
                            .fixedSize(horizontal: false, vertical: true) // Allow value to wrap
                            .textSelection(.enabled) // Allow selecting value
                    }
                }
            }
             .padding(.vertical)
             .background(Color.secondary.opacity(0.05)) // Subtle background for section
             .cornerRadius(10)
        }
    }

     @ViewBuilder
    private var metadataSection: some View {
         VStack(alignment: .leading, spacing: 8) {
             Text("Metadata")
                 .font(.headline)
              Divider().padding(.bottom, 5)

             // Model ID + Copy Button
             HStack {
                metadataRow(label: "Model ID", value: model.id)
                 Spacer()
                 Button { copyToClipboard(model.id) } label: {
                     Image(systemName: "doc.on.doc")
                 }
                 .buttonStyle(.borderless) // Simple copy button
                 .help("Copy Model ID") // Tooltip for macOS/iPadOS
             }

             if let owner = model.owner { metadataRow(label: "Owner", value: owner) }
             if let date = model.releaseDate { metadataRow(label: "Release Date", value: date, formatter: .mediumDate) }
             if let version = model.version, model.family == nil { metadataRow(label: "Version", value: version) } // Show version if no family

         }
         .padding(.top) // Add space above metadata
     }

     // --- Toolbar ---
     @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
         ToolbarItemGroup(placement: .navigationBarTrailing) {
             // Share Button
             ShareLink(item: generateShareableString()) {
                 Label("Share", systemImage: "square.and.arrow.up")
             }

             // Favorite Button
             Button {
                 toggleFavorite()
             } label: {
                 Label("Favorite", systemImage: isFavorite ? "star.fill" : "star")
                     .foregroundColor(isFavorite ? .yellow : .secondary) // Indicate favorite state
             }
         }
     }

    // --- Helper Functions ---

    private func copyToClipboard(_ text: String) {
         UIPasteboard.general.string = text
         showCopiedAlert = true
        // Provide haptic feedback
         #if canImport(UIKit)
         UINotificationFeedbackGenerator().notificationOccurred(.success)
         #endif
     }

    private func toggleFavorite() {
        isFavorite.toggle()
         // In a real app, update persistence
         // PersistenceService.shared.setFavorite(modelId: model.id, isFavorite: isFavorite)
         print("Toggled favorite for \(model.id) to: \(isFavorite)")
         // Optional: Add animation or feedback
     }

     private func generateShareableString() -> String {
         // Create a simple text representation for sharing
         var shareText = "Check out this AI Model:\n"
         shareText += "\nName: \(model.displayName)"
         if let family = model.family { shareText += "\nFamily: \(family)" }
         if let version = model.version { shareText += " (v\(version))" }
         shareText += "\nProvider: \(model.provider.rawValue)"
         if let desc = model.shortDescription { shareText += "\n\n\(desc)" }
         // Maybe add a link to a hypothetical web page later
         return shareText
     }

      // Generic function to display date with formatting
     func metadataRow(label: String, value: Date?, formatter: DateFormatter) -> some View {
         if let value = value {
             metadataRow(label: label, value: formatter.string(from: value))
         } else {
             EmptyView()
         }
     }

     // Generic function for metadata rows
     func metadataRow(label: String, value: String?) -> some View {
         if let value = value, !value.isEmpty {
             HStack(alignment: .firstTextBaseline) {
                 Text("\(label):")
                     .font(.caption.weight(.medium))
                     .foregroundColor(.secondary)
                     .frame(width: 100, alignment: .trailing) // Consistent label width
                 Text(value)
                     .font(.callout)
                     .textSelection(.enabled) // Allow selection
             }
         } else {
             EmptyView()
         }
     }

    // --- Detail-Specific Badge Builders ---

     // Generic wrapper for sections using WrappingHStack
     @ViewBuilder
     private func sectionView<Item: Hashable, ItemView: View>(
         _ title: String,
         items: [Item],
         viewForItem: @escaping (Item) -> ItemView
     ) -> some View {
         VStack(alignment: .leading, spacing: 5) {
             Text(title)
                 .font(.headline)
             WrappingHStack(items: items, viewForItem: viewForItem)
         }
     }

     // Badge for capabilities in detail view
     @ViewBuilder
     private func capabilityDetailBadge(_ capability: ModelCapability) -> some View {
         Label(capability.rawValue, systemImage: capability.icon)
             .font(.callout) // Slightly larger than card
             .padding(.horizontal, 10)
             .padding(.vertical, 5)
             .background(model.displayColor.opacity(0.15))
             .foregroundStyle(model.displayColor)
             .clipShape(Capsule())
     }

     // Badge for tags in detail view
     @ViewBuilder
     private func tagBadge(_ tag: String) -> some View {
         Text(tag.capitalized)
             .font(.caption)
             .padding(.horizontal, 10).padding(.vertical, 5)
             .background(Color.secondary.opacity(0.1)) // Neutral background for tags
             .foregroundColor(.secondary)
             .clipShape(Capsule())
     }

     // Badge for Provider in detail header
     @ViewBuilder
     private func providerBadge(_ provider: ModelProvider) -> some View {
         Label(provider.rawValue, systemImage: provider.logo.symbolName ?? "questionmark.circle") // Fixed: Need a way to get sys name, fallback icon
             .font(.caption.weight(.medium)) // Medium weight caption
             .padding(.horizontal, 8).padding(.vertical, 4)
             .background(provider.palette.opacity(0.18))
             .foregroundColor(provider.palette)
             .clipShape(Capsule())
     }
     // Badge for Family in detail header
     @ViewBuilder
     private func familyBadge(_ family: String) -> some View {
         Text(family)
             .font(.caption)
             .padding(.horizontal, 8).padding(.vertical, 4)
             .background(Color.gray.opacity(0.15))
             .foregroundColor(.secondary)
             .clipShape(Capsule())
     }
     // Badge for Version in detail header
     @ViewBuilder
     private func versionBadge(_ version: String) -> some View {
         Text("v\(version)")
             .font(.caption)
             .padding(.horizontal, 8).padding(.vertical, 4)
             .background(Color.gray.opacity(0.1))
             .foregroundColor(.secondary)
             .clipShape(Capsule())
     }

      @ViewBuilder
     private func popularityBadge(_ pop: Double) -> some View {
         HStack(spacing: 3) {
              Image(systemName: "flame.fill")
              Text("\(Int(pop * 100))%")
         }
         .font(.caption.weight(.medium))
         .foregroundColor(.orange)
         .padding(.horizontal, 7).padding(.vertical, 3)
         .background(Color.orange.opacity(0.15))
         .clipShape(Capsule())
     }

    // Flag view reused from Card View (could be put in a shared location)
    @ViewBuilder
    private func flag(_ value: String, _ color: Color, size: Font = .caption2) -> some View {
         Text(value)
             .font(size).bold()
             .padding(.horizontal, 6).padding(.vertical, 3)
             .background(color.opacity(0.2)) // Slightly more opaque
             .foregroundColor(color)
             .clipShape(Capsule())
     }
}

// Add DateFormatter extension for convenience
extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// Add helper to get system image name from Image (Crude - better ways exist)
extension Image {
    var symbolName: String? {
        // THIS IS A HACK AND MIGHT BREAK. SwiftUI images are opaque.
        // A better approach is to store the systemName string in the enum.
        // For now, let's hardcode based on the enum definition.
        if self == Image(systemName: "circle.hexagonpath.fill") { return "circle.hexagonpath.fill" }
        if self == Image(systemName: "diamond.lefthalf.filled") { return "diamond.lefthalf.filled" }
        if self == Image(systemName: "cube.transparent.fill") { return "cube.transparent.fill" }
        if self == Image(systemName: "hare.fill") { return "hare.fill" }
        // Fallback for provider badge usage
        if self == Image(systemName: "circle.hexagonpath") { return "circle.hexagonpath" }
        if self == Image(systemName: "diamond") { return "diamond" } // Approximation
        if self == Image(systemName: "cube.transparent") { return "cube.transparent" }
        if self == Image(systemName: "hare") { return "hare" }
        return nil // Cannot determine
    }
}

// MARK: - WrappingHStack helper (Unchanged but crucial)

struct WrappingHStack<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    let viewForItem: (Item) -> ItemView
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    @State private var totalHeight: CGFloat // Changed to non-optional based on usage

     // Provide default values for spacing
     init(items: [Item],
          horizontalSpacing: CGFloat = 8, // Default horizontal spacing
          verticalSpacing: CGFloat = 5, // Default vertical spacing
          @ViewBuilder viewForItem: @escaping (Item) -> ItemView) {
         self.items = items
         self.viewForItem = viewForItem
         self.horizontalSpacing = horizontalSpacing
         self.verticalSpacing = verticalSpacing
         // Initialize totalHeight based on expectation (usually starts at 0 or a single row height)
         self._totalHeight = State(initialValue: items.isEmpty ? 0 : 40) // Guess initial height
     }

    var body: some View {
        VStack { // Keep VStack wrapper
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight) // Use state variable for height
        .clipped() // Clip content if it somehow exceeds calculated height
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        // Using ZStack with alignment guides for layout
        return ZStack(alignment: .topLeading) {
            ForEach(self.items, id: \.self) { item in
                self.viewForItem(item)
                    .padding(.trailing, horizontalSpacing) // Add spacing to the right of each item
                    .padding(.bottom, verticalSpacing)   // Add spacing below each item
                    .alignmentGuide(.leading, computeValue: { d in
                        let itemWidth = d.width // Width of the item including its horizontal padding
                        // Check if item fits on the current line
                        if abs(width - itemWidth) > g.size.width {
                            width = 0         // Move to next line
                            height -= d.height // Adjust height (d.height includes bottom padding)
                        }
                        let result = width
                        // Last item condition might not be needed if padding handles last space
                        // if item == self.items.last { width = 0 } else { width -= itemWidth }
                        width -= itemWidth // Decrease available width
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        // Last item condition might not be needed?
                        // if item == self.items.last { height = 0 }
                        return result
                    })
            }
        }
         .background(viewHeightReader($totalHeight)) // Use background helper to measure height
    }

    // Helper view to asynchronously read the content height
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
             let newHeight = geometry.size.height
            // Use DispatchQueue.main.async to avoid modifying state during view update
             DispatchQueue.main.async {
                 // Only update if the height has actually changed to prevent unnecessary redraws
                 if binding.wrappedValue != newHeight {
                     binding.wrappedValue = newHeight
                 }
             }
            return Color.clear // Return clear color as it's just for measurement
        }
    }
}

// MARK: - Previews

#Preview("Explorer - Light") {
    UnifiedModelExplorerView()
        .preferredColorScheme(.light)
}

#Preview("Explorer - Dark") {
    UnifiedModelExplorerView()
        .preferredColorScheme(.dark)
}

#Preview("Detail View - GPT-4o") {
     NavigationView { // Wrap in NavigationView for Toolbar preview
         ModelDetailUnifiedView(model: OpenAIMockProvider().mockGPT4o())
             .navigationBarTitleDisplayMode(.inline)
     }
     .preferredColorScheme(.dark)
}

#Preview("Card View - Llama 3 8B") {
    ModelCardUnifiedView(model: LlamaMockProvider().mockLlama3_8B())
         .padding()
         .background(.gray.opacity(0.1))
         .preferredColorScheme(.light)

}

// Helper extensions for previews
extension OpenAIMockProvider {
    func mockGPT4o() -> any UnifiedAIModel {
         OpenAIModelUnified(id: "gpt-4o", displayName: "GPT-4o",
               family: "GPT-4", version: "Omni", owner: "OpenAI", releaseDate: daysAgo(60),
               isPreview: false, isExperimental: false, isLive: true,
               shortDescription: "Fastest, most capable multi-modal model.",
               detailedDescription: "GPT-4o (“o” for “omni”) is our latest flagship model. It can process and generate text, audio, and image inputs and outputs.",
               inputCapabilities: [.text, .image, .audio, .vision], outputCapabilities: [.text, .image, .audio], tags: ["multimodal", "fast", "flagship", "vision"],
               popularity: 0.98, stats: ["API Price (Input/Output)": "$5/$15 per 1M tokens", "Context Window": "128k tokens"],
               navigationIcon: "bolt.fill", displayColor: .indigo)
    }
}
extension LlamaMockProvider {
     func mockLlama3_8B() -> any UnifiedAIModel {
         LlamaModelUnified(id: "meta-llama/Llama-3-8b-Instruct", displayName: "Llama 3 8B Instruct",
                 family: "Llama 3", version: "8B Instruct", owner: "Meta", releaseDate: daysAgo(100),
                 isPreview: false, isExperimental: false, isLive: true,
                 shortDescription: "Fast and capable small model.",
                 detailedDescription: "The smaller, efficient Llama 3 model, great for faster responses.",
                 inputCapabilities: [.text], outputCapabilities: [.text], tags: ["instruct", "small", "fast", "mobile"],
                 popularity: 0.82, stats: ["Use Case": "On-device deployment", "Speed": "High throughput"],
                 navigationIcon: "paperplane.fill", displayColor: .lime)
    }
}
