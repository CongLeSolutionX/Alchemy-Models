////
////  Unified_AI_Model_Collection_View_V2.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////   AIMultiProviderExplorer.swift
////   All-in-One version for AI Model Catalog
////   Created by Cong Le with strategic synthesis and trend-forward UI
////   License: MIT (code), CC BY 4.0 (content)
////
//
//import SwiftUI
//
//// MARK: - Providers Definition
//
//enum AIProvider: String, CaseIterable, Identifiable {
//    case openai = "OpenAI"
//    case gemini = "Gemini (Google)"
//    case deepseek = "DeepSeek"
//    case meta = "Meta Llama"
//    var id: String { rawValue }
//    var color: Color {
//        switch self {
//        case .openai: return .purple
//        case .gemini: return .blue
//        case .deepseek: return .green
//        case .meta: return .orange
//        }
//    }
//    var icon: String {
//        switch self {
//        case .openai: return "sparkles"
//        case .gemini: return "globe"
//        case .deepseek: return "chart.bar.doc.horizontal"
//        case .meta: return "brain.head.profile"
//        }
//    }
//}
//
//// MARK: - Unified Protocol
//
//protocol AIModelProtocol: Identifiable, Hashable {
//    var id: String { get }
//    var name: String { get }
//    var provider: AIProvider { get }
//    var isFeatured: Bool { get }
//    var tags: [String] { get }
//    var description: String { get }
//    var details: String { get }
//    var inputTypes: [String] { get }
//    var outputTypes: [String] { get }
//    var version: String { get }
//    var date: Date { get }
//    var icon: String { get }
//    var gradient: LinearGradient { get }
//}
//
//// MARK: - Providers' Model Types Adopting Protocol
//
//// --- OpenAI ---
//struct OpenAIModel: AIModelProtocol {
//    let id, name, description, details: String
//    let isFeatured: Bool
//    let tags: [String]
//    let inputTypes, outputTypes: [String]
//    let version: String
//    let date: Date
//    // UI
//    var provider: AIProvider { .openai }
//    var icon: String { "sparkles" }
//    var gradient: LinearGradient {
//        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
//    }
//}
//
//// --- Gemini ---
//struct GeminiModel: AIModelProtocol {
//    let id, name, description, details: String
//    let isFeatured: Bool
//    let tags: [String]
//    let inputTypes, outputTypes: [String]
//    let version: String
//    let date: Date
//    // UI
//    var provider: AIProvider { .gemini }
//    var icon: String { "globe" }
//    var gradient: LinearGradient {
//        LinearGradient(colors: [.blue, .mint, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
//    }
//}
//
//// --- DeepSeek ---
//struct DeepSeekModel: AIModelProtocol {
//    let id, name, description, details: String
//    let isFeatured: Bool
//    let tags: [String]
//    let inputTypes, outputTypes: [String]
//    let version: String
//    let date: Date
//    // UI
//    var provider: AIProvider { .deepseek }
//    var icon: String { "chart.bar.doc.horizontal" }
//    var gradient: LinearGradient {
//        LinearGradient(colors: [.green, .teal, .blue], startPoint: .topTrailing, endPoint: .bottomLeading)
//    }
//}
//
//// --- Meta Llama ---
//struct LlamaModel: AIModelProtocol {
//    let id, name, description, details: String
//    let isFeatured: Bool
//    let tags: [String]
//    let inputTypes, outputTypes: [String]
//    let version: String
//    let date: Date
//    // UI
//    var provider: AIProvider { .meta }
//    var icon: String { "brain.head.profile" }
//    var gradient: LinearGradient {
//        LinearGradient(colors: [.orange, .yellow, .pink], startPoint: .top, endPoint: .bottom)
//    }
//}
//
//// MARK: - MOCK DATA SERVICES
//
//protocol AIModelDataService {
//    func fetchModels() async -> [any AIModelProtocol]
//}
//
//struct MockOpenAIService: AIModelDataService {
//    func fetchModels() async -> [any AIModelProtocol] {
//        [
//            OpenAIModel(
//                id: "gpt-4-turbo", name: "GPT-4 Turbo",
//                description: "Most advanced language model.",
//                details: "Long context, high reasoning, low cost.",
//                isFeatured: true, tags: ["turbo", "text", "reasoning"],
//                inputTypes: ["text"], outputTypes: ["text"], version: "4",
//                date: Date()
//            ),
//            OpenAIModel(
//                id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo",
//                description: "Fast, versatile engine.",
//                details: "Supporting a wide range of use cases.",
//                isFeatured: false, tags: ["fast", "cost-effective"],
//                inputTypes: ["text"], outputTypes: ["text"], version: "3.5", date: Date().addingTimeInterval(-86400 * 130)
//            )
//        ]
//    }
//}
//struct MockGeminiService: AIModelDataService {
//    func fetchModels() async -> [any AIModelProtocol] {
//        [
//            GeminiModel(
//                id: "gemini-2.5-pro", name: "Gemini 2.5 Pro",
//                description: "Enhanced multitask and multimodal reasoning.",
//                details: "Audio, video, image and text input; text output.",
//                isFeatured: true, tags: ["multimodal", "pro", "preview"],
//                inputTypes: ["audio", "images", "videos", "text"], outputTypes: ["text"], version: "2.5", date: Date()
//            ),
//            GeminiModel(
//                id: "gemini-1.5-flash", name: "Gemini 1.5 Flash",
//                description: "Fast, cost-efficient generative model.",
//                details: "Real-time streaming ideal for chatbots.",
//                isFeatured: false, tags: ["flash", "fast"],
//                inputTypes: ["text", "image"], outputTypes: ["text"],
//                version: "1.5", date: Date().addingTimeInterval(-86400 * 15)
//            )
//        ]
//    }
//}
//struct MockDeepSeekService: AIModelDataService {
//    func fetchModels() async -> [any AIModelProtocol] {
//        [
//            DeepSeekModel(
//                id: "deepseek-r1", name: "DeepSeek R1", description: "General text generation", details: "High performance LLM", isFeatured: true, tags: ["r1", "text"], inputTypes: ["text"], outputTypes: ["text"], version: "R1", date: Date().addingTimeInterval(-86400 * 21)
//            ),
//            DeepSeekModel(
//                id: "deepseek-vl2", name: "DeepSeek VL2", description: "Vision-Language model", details: "Handles image and text input", isFeatured: false, tags: ["vision", "multimodal"], inputTypes: ["image", "text"], outputTypes: ["text"], version: "VL2", date: Date().addingTimeInterval(-86400 * 30)
//            )
//        ]
//    }
//}
//struct MockMetaLlamaService: AIModelDataService {
//    func fetchModels() async -> [any AIModelProtocol] {
//        [
//            LlamaModel(id: "llama-3-70b", name: "Llama 3 70B", description: "State-of-the-art Llama model", details: "Best for complex reasoning and long context", isFeatured: true, tags: ["3", "70B"], inputTypes: ["text"], outputTypes: ["text"], version: "3", date: Date().addingTimeInterval(-86400 * 12)),
//            LlamaModel(id: "llama-guard-3", name: "Llama Guard 3", description: "Safety classifier", details: "Prompt/response safety filtering", isFeatured: false, tags: ["guard", "safety"], inputTypes: ["text"], outputTypes: ["label"], version: "3", date: Date().addingTimeInterval(-86400 * 8))
//        ]
//    }
//}
//
//// MARK: - DATA PROVIDER MAP
//let dataServices: [AIProvider: any AIModelDataService] = [
//    .openai: MockOpenAIService(),
//    .gemini: MockGeminiService(),
//    .deepseek: MockDeepSeekService(),
//    .meta: MockMetaLlamaService()
//]
//
//// MARK: - MAIN VIEW
//
//struct AIMultiProviderExplorerView: View {
//    @State private var selectedProvider: AIProvider = .openai
//    @State private var allModels: [any AIModelProtocol] = []
//    @State private var isLoading = false
//
//    var featuredModels: [any AIModelProtocol] { allModels.filter { $0.isFeatured } }
//    var otherModels: [any AIModelProtocol] { allModels.filter { !$0.isFeatured } }
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                LinearGradient(colors: [selectedProvider.color.opacity(0.15), .white], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
//                VStack(spacing: 0) {
//                    // Picker
//                    HStack {
//                        Image(systemName: selectedProvider.icon).foregroundColor(selectedProvider.color).font(.title2)
//                        Picker("Provider", selection: $selectedProvider) {
//                            ForEach(AIProvider.allCases) { provider in
//                                Label(provider.rawValue, systemImage: provider.icon).tag(provider)
//                            }
//                        }
//                        .pickerStyle(.segmented)
//                    }
//                    .padding()
//
//                    // Featured Cards
//                    if !featuredModels.isEmpty {
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 20) {
//                                ForEach(featuredModels, id: \.id) { model in
//                                    AIModelFeaturedCard(model: model)
//                                        .frame(width: 310)
//                                        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 5)
//                                        .padding(.top, 12)
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                        .frame(minHeight: 240)
//                    }
//                    // Main List
//                    List {
//                        Section {
//                            ForEach(otherModels, id: \.id) { model in
//                                AIModelListRow(model: model)
//                            }
//                        } header: {
//                            Text("All \(selectedProvider.rawValue) Models")
//                                .font(.title3)
//                                .foregroundColor(selectedProvider.color)
//                        }
//                    }
//                    .listStyle(.plain)
//                    .background(Color.clear)
//                    .opacity(isLoading ? 0.2 : 1)
//                }
//                if isLoading {
//                    ProgressView("Loading \(selectedProvider.rawValue) Models...").progressViewStyle(CircularProgressViewStyle(tint: selectedProvider.color)).scaleEffect(1.7)
//                }
//            }
//            .navigationTitle("AI Model Explorer")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button {
//                        loadModels()
//                    } label: {
//                        Label("Refresh", systemImage: "arrow.clockwise")
//                    }
//                }
//            }
//            .task {
//                loadModels()
//            }
//            .onChange(of: selectedProvider) { _ in
//                loadModels()
//            }
//        }
//    }
//
//    /// Loads models for the currently selected provider
//    private func loadModels() {
//        isLoading = true
//        Task {
//            if let service = dataServices[selectedProvider] {
//                let models = await service.fetchModels()
//                await MainActor.run {
//                    self.allModels = models
//                    self.isLoading = false
//                }
//            } else {
//                await MainActor.run {
//                    self.allModels = []
//                    self.isLoading = false
//                }
//            }
//        }
//    }
//}
//
//// MARK: - CARD Row and Detail Design
//
//struct AIModelFeaturedCard: View {
//    let model: any AIModelProtocol
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack(alignment: .center, spacing: 12) {
//                Image(systemName: model.icon)
//                    .font(.largeTitle.bold())
//                    .padding(14)
//                    .background(.ultraThinMaterial)
//                    .clipShape(Circle())
//                    .overlay(Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 2))
//                VStack(alignment: .leading) {
//                    Text(model.name)
//                        .font(.title2.weight(.bold))
//                        .foregroundStyle(.white)
//                    Text(model.provider.rawValue)
//                        .font(.subheadline)
//                        .foregroundStyle(.white.opacity(0.67))
//                }
//                Spacer()
//            }
//            Text(model.description)
//                .font(.body)
//                .foregroundStyle(.white)
//                .padding(.bottom, 12)
//            HStack {
//                ForEach(model.tags.prefix(3), id: \.self) {
//                    tag in
//                    Text(tag.capitalized)
//                        .font(.caption2)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 4)
//                        .background(Color.white.opacity(0.2))
//                        .clipShape(Capsule())
//                        .foregroundColor(.white)
//                }
//                Spacer()
//            }
//        }
//        .padding()
//        .background(model.gradient)
//        .cornerRadius(18)
//    }
//}
//
//struct AIModelListRow: View {
//    let model: any AIModelProtocol
//    var body: some View {
//        HStack(spacing: 15) {
//            ZStack {
//                Circle()
//                    .fill(model.gradient)
//                    .frame(width: 38, height: 38)
//                Image(systemName: model.icon)
//                    .font(.system(size: 20, weight: .semibold))
//                    .foregroundColor(.white)
//            }
//            VStack(alignment: .leading, spacing: 2) {
//                Text(model.name)
//                    .font(.headline)
//                Text(model.description)
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//                    .lineLimit(1)
//            }
//            Spacer()
//            HStack(spacing: 2) {
//                ForEach(model.inputTypes.prefix(2), id: \.self) { itype in
//                    Text(itype.capitalized)
//                        .font(.caption2)
//                        .padding(.horizontal, 5)
//                        .padding(.vertical, 2)
//                        .background(Color.gray.opacity(0.12))
//                        .clipShape(Capsule())
//                        .foregroundColor(.secondary)
//                }
//            }
//        }
//        .padding(.vertical, 6)
//    }
//}
//
//// MARK: - PREVIEW
//
//struct AIMultiProviderExplorerView_Previews: PreviewProvider {
//    static var previews: some View {
//        AIMultiProviderExplorerView()
//    }
//}
