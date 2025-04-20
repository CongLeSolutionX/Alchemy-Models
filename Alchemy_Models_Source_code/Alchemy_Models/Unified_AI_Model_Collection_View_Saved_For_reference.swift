////
////  Unified_AI_Model_Collection_View.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
//import SwiftUI
//import Foundation
//
//// MARK: - Enums & Protocols
//
//// For OpenAI
//enum OpenAIModelSortOption: String, CaseIterable, Identifiable {
//    case nameAsc = "Name (A-Z)"
//    case nameDesc = "Name (Z-A)"
//    case createdNewest = "Newest"
//    case createdOldest = "Oldest"
//    var id: String { self.rawValue }
//}
//enum OpenAIError: Error, LocalizedError {
//    case network, decoding, unknown
//    var errorDescription: String? {
//        switch self {
//        case .network: return "Network error."
//        case .decoding: return "Failed to decode data."
//        case .unknown: return "Unknown error."
//        }
//    }
//}
//protocol APIServiceProtocol {
//    func fetchModels() async throws -> [OpenAIModel]
//}
//
//// For Google Gemini
//enum GeminiCategory: String, CaseIterable, Comparable {
//    case featured, generative, vision, embedding, experimental, other
//    static func < (lhs: GeminiCategory, rhs: GeminiCategory) -> Bool {
//        // Order emphasis
//        let order: [GeminiCategory] = [.featured, .generative, .vision, .embedding, .experimental, .other]
//        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
//    }
//}
//enum LiveAPIError: Error, LocalizedError {
//    case invalidURL, requestFailed(Int), network(Error), decoding(Error), missingAPIKey
//    var errorDescription: String? { "" }
//}
//protocol GeminiAPIProtocol {
//    func fetchModels() async throws -> [GeminiModel]
//}
//
//// For DeepSeek
//struct PaperInfo: Codable, Hashable { let title: String; let date: String; let link: URL?; let reads: String? }
//enum DeepSeekCategory: String, Codable, CaseIterable, Comparable { // Ordered categories
//    case textGen, imageToText, viewer, codeGen, safety, prompt, other
//    static func < (lhs: DeepSeekCategory, rhs: DeepSeekCategory) -> Bool {
//        let order: [DeepSeekCategory] = [.textGen, .imageToText, .viewer, .codeGen, .safety, .prompt, .other]
//        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
//    }
//}
//struct DeepSeekModel: Identifiable, Hashable, Codable {
//    let id: String
//    let family: String
//    let category: DeepSeekCategory
//    let lastUpdated: String
//    let downloads: String?
//    let likes: String?
//    let sectionTitle: String
//    let sectionSubtitle: String?
//    let associatedPaper: PaperInfo?
//}
//
//// For Llama (Meta)
//enum LlamaTaskType: String, Codable { case textGen = "Text Generation"; var imageText = "Image-To-Text"; var viewer = "Viewer"; var codeGen = "Code Generation"; var safety = "Safety"; var prompt = "Prompt Filtering" }
//struct LlamaModel: Identifiable, Hashable, Codable {
//    let id: String
//    let family: String
//    let taskType: LlamaTaskType
//    let updatedDate: Date
//    let downloads: String?
//    let likes: String?
//    let views: String?
//    let computeUnits: String?
//}
//
//// MARK: - API Service Implementations & Mock Data
//
//// OpenAI Mock
//class MockOpenAIService: APIServiceProtocol {
//    func fetchModels() async throws -> [OpenAIModel] {
//        try await Task.sleep(for: .milliseconds(500))
//        return [
//            OpenAIModel(id: "gpt-4", name: "GPT-4", description: "Advanced", supportedCapabilities: ["chat", "code"]),
//            OpenAIModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", description: "Fast", supportedCapabilities: ["chat", "completion"])
//        ]
//    }
//}
//struct OpenAIModel: Identifiable, Hashable, Codable {
//    let id: String
//    let name: String
//    let description: String
//    let supportedCapabilities: [String]
//}
//
//// Gemini Mock
//class MockGeminiService: GeminiAPIProtocol {
//    func fetchModels() async throws -> [GeminiModel] {
//        try await Task.sleep(for: .milliseconds(500))
//        return [
//            GeminiModel(id: "gemini-2.5-flash-preview-04-17", name: "Gemini 2.5 Flash Preview 04-17", category: .generative, lastUpdated: "2025-04-13", downloads: "10k", likes: "2k", sectionTitle: "Galaxies", sectionSubtitle: "Galaxy models overview"),
//            GeminiModel(id: "gemini-2.0", name: "Gemini 2.0", category: .generative, lastUpdated: "2025-03-10", downloads: "50k", likes: "5k", sectionTitle: "Galaxies")
//        ]
//    }
//}
//
//// DeepSeek Mock
//class MockDeepSeekService: DeepSeekAPIProtocol {
//    func fetchModels() async throws -> [DeepSeekModel] {
//        try await Task.sleep(for: .milliseconds(500))
//        return [
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1", family: "DeepSeek R1", category: .textGen, lastUpdated: "2025-04-10", downloads: "1.2M", likes: "50k", sectionTitle: "DeepSeek R1", sectionSubtitle: "Main series", associatedPaper: nil),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-VL2", family: "DeepSeek VL2", category: .imageToText, lastUpdated: "2025-03-01", downloads: "900k", likes: "30k", sectionTitle: "DeepSeek VL2", sectionSubtitle: "Vision-Language", associatedPaper: nil)
//        ]
//    }
//}
//
//// Llama (Meta) Mock
//class MockLlamaService: LlamaAPIServiceProtocol {
//    func fetchLlamaAssets() async throws -> [LlamaModel] {
//        try await Task.sleep(for: .milliseconds(500))
//        return [
//            LlamaModel(id: "meta-llama/Llama-4-Maverick-17B", family: "Llama 4", taskType: .imageText, updatedDate: Date(), downloads: "10k", likes: "2k", views: nil, computeUnits: "⚡"),
//            LlamaModel(id: "meta-llama/Llama-3.3", family: "Llama 3.3", taskType: .textGen, updatedDate: Date().addingTimeInterval(-86400*100), downloads: "1.2M", likes: "50k", views: nil, computeUnits: nil)
//        ]
//    }
//}
//
//// MARK: - Main Container View
//
//struct AIModelsTabView: View {
//    @State private var modelTypeSelected: String = "OpenAI"
//    @State private var models: [Any] = []
//    
//    var body: some View {
//        // Use SegmentedControl to toggle among models
//        VStack {
//            Picker("Type", selection: $modelTypeSelected) {
//                Text("OpenAI").tag("OpenAI")
//                Text("Gemini").tag("Gemini")
//                Text("DeepSeek").tag("DeepSeek")
//                Text("Llama").tag("Llama")
//            }
//            .pickerStyle(.segmented)
//            .padding()
//
//            if modelTypeSelected == "OpenAI" {
//                OpenAIModelsView()
//            } else if modelTypeSelected == "Gemini" {
//                GeminiModelsView()
//            } else if modelTypeSelected == "DeepSeek" {
//                DeepSeekModelsView()
//            } else if modelTypeSelected == "Llama" {
//                LlamaModelsView()
//            }
//        }
//    }
//}
//
//// MARK: - OpenAI Models View
//struct OpenAIModelsView: View {
//    @State private var models: [OpenAIModel] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String? = nil
//    private let service: APIServiceProtocol = MockOpenAIService()
//    var body: some View {
//        content
//            .task { await loadModels() }
//    }
//    @ViewBuilder
//    private var content: some View {
//        if isLoading && models.isEmpty {
//            ProgressView("Loading OpenAI Models...").padding()
//        } else if let errorMessage = errorMessage, models.isEmpty {
//            Text(errorMessage).foregroundColor(.red).padding()
//        } else {
//            List {
//                ForEach(models) { model in
//                    VStack(alignment: .leading) {
//                        Text(model.name).font(.headline)
//                        Text(model.description).font(.caption).foregroundColor(.secondary)
//                    }
//                }
//            }
//        }
//    }
//    @MainActor
//    private func loadModels() async {
//        isLoading = true
//        do {
//            models = try await service.fetchModels()
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//        isLoading = false
//    }
//}
//
//// MARK: - Gemini Models View
//struct GeminiModelsView: View {
//    @State private var models: [GeminiModel] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String? = nil
//    private let service: GeminiAPIProtocol = MockGeminiService()
//    var body: some View {
//        content
//            .task { await loadModels() }
//    }
//    @ViewBuilder
//    private var content: some View {
//        if isLoading && models.isEmpty {
//            ProgressView("Loading Gemini Models...").padding()
//        } else if let errorMessage = errorMessage, models.isEmpty {
//            Text(errorMessage).foregroundColor(.red).padding()
//        } else {
//            List {
//                ForEach(models) { model in
//                    HStack {
//                        Image(systemName: "sparkles")
//                            .foregroundColor(.blue)
//                        VStack(alignment: .leading) {
//                            Text(model.name).font(.headline)
//                            Text("Category: \(model.category.rawValue)").font(.caption).foregroundColor(.secondary)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    @MainActor
//    private func loadModels() async {
//        isLoading = true
//        do { models = try await service.fetchModels() }
//        catch { errorMessage = error.localizedDescription }
//        isLoading = false
//    }
//}
//
//// MARK: - DeepSeek Models View
//struct DeepSeekModelsView: View {
//    @State private var models: [DeepSeekModel] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String? = nil
//    private let service: DeepSeekAPIProtocol = MockDeepSeekService()
//    var body: some View {
//        content
//            .task { await loadModels() }
//    }
//    @ViewBuilder
//    private var content: some View {
//        if isLoading && models.isEmpty {
//            ProgressView("Loading DeepSeek Models...").padding()
//        } else if let errorMessage = errorMessage, models.isEmpty {
//            Text(errorMessage).foregroundColor(.red).padding()
//        } else {
//            List {
//                ForEach(models) { model in
//                    VStack(alignment: .leading) {
//                        Text(model.family).font(.headline)
//                        Text(model.sectionSubtitle ?? "")
//                            .font(.caption2).foregroundColor(.secondary)
//                        Text("Category: \(model.category.rawValue)").font(.caption)
//                        Text("Updated: \(model.lastUpdated)").font(.caption2).foregroundColor(.gray)
//                        if let reads = model.reads { Text("Reads: \(reads)").font(.caption2).foregroundColor(.secondary) }
//                    }
//                }
//            }
//        }
//    }
//    @MainActor
//    private func loadModels() async {
//        isLoading = true
//        do { models = try await service.fetchModels() }
//        catch { errorMessage = error.localizedDescription }
//        isLoading = false
//    }
//}
//
//// MARK: - Llama Models View
//struct LlamaModelsView: View {
//    @State private var models: [LlamaModel] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String? = nil
//    private let service: MockLlamaService = MockLlamaService()
//    var body: some View {
//        content
//            .task { await loadModels() }
//    }
//    @ViewBuilder
//    private var content: some View {
//        if isLoading && models.isEmpty {
//            ProgressView("Loading Llama Models...").padding()
//        } else if let errorMessage = errorMessage, models.isEmpty {
//            Text(errorMessage).foregroundColor(.red).padding()
//        } else {
//            List {
//                ForEach(models) { model in
//                    VStack(alignment: .leading) {
//                        Text(model.family).font(.headline)
//                        Text("Task: \(model.taskType.rawValue)").font(.caption).foregroundColor(.secondary)
//                        Text("Updated: \(model.updatedDate, formatter: DateFormatter.shortDate)").font(.caption2).foregroundColor(.gray)
//                        if let downloads = model.downloads { Text("Downloads: \(downloads)").font(.caption2) }
//                        if let likes = model.likes { Text("Likes: \(likes)").font(.caption2) }
//                        if let views = model.views { Text("Views: \(views)").font(.caption2) }
//                    }
//                }
//            }
//        }
//    }
//    @MainActor
//    private func loadModels() async {
//        isLoading = true
//        do { models = try await service.fetchLlamaAssets() }
//        catch { errorMessage = error.localizedDescription }
//        isLoading = false
//    }
//}
//
//// MARK: - Main App View
//struct AIModelsContentView: View {
//    var body: some View {
//        TabView {
//            OpenAIModelsView().tabItem { Label("OpenAI", systemImage: "sparkles") }
//            GeminiModelsView().tabItem { Label("Gemini", systemImage: "star.fill") }
//            DeepSeekModelsView().tabItem { Label("DeepSeek", systemImage: "circle.grid.3x3") }
//            LlamaModelsView().tabItem { Label("Llama", systemImage: "ant.fill") }
//        }
//    }
//}
//
//// MARK: - Extensions & Helpers
//extension DateFormatter {
//    static var shortDate: DateFormatter {
//        let df = DateFormatter()
//        df.dateStyle = .short
//        return df
//    }
//}
//
//// MARK: - Preview View
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        AIModelsContentView()
//    }
//}
