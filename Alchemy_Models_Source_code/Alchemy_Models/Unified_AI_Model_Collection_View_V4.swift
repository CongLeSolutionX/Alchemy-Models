//
//  Unified_AI_Model_Collection_View_V3.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  UnifiedModelExplorer.swift
//  AIModelExplorer
//
//  Created by Synthesized by Cong Le AI on 2025-04-13.
//  License(s): MIT (Code), CC BY 4.0 (Docs/Non-Code)
//  Copyright (c) 2025 Cong Le. All Rights Reserved.
//
//  This file provides a comprehensive, extensible, Swifty, and testable
//  unified viewing experience for multiple AI model providers.
//  Providers: OpenAI, Gemini, DeepSeek, LlamaFamily (Meta).
//  Includes: Protocols, Unification, Mock Data, Routing, and Modern SwiftUI.
//

import SwiftUI
import Foundation

// MARK: - Unified Enums and Protocols

enum ModelProvider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case gemini = "Gemini"
    case deepseek = "DeepSeek"
    case llama = "Llama"
    var id: String { rawValue }
    
    var logo: Image {
        switch self {
        case .openai: return Image(systemName: "circle.hexagonpath")
        case .gemini: return Image(systemName: "diamond.lefthalf.filled")
        case .deepseek: return Image(systemName: "cube.transparent")
        case .llama: return Image(systemName: "hare")
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

enum ModelCapability: String, CaseIterable, Hashable {
    case text = "Text"
    case image = "Image"
    case audio = "Audio"
    case video = "Video"
    case code = "Code"
    case embedding = "Embedding"
    case multiModal = "Multi-Modal"
    case vision = "Vision"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .text: return "doc.text.fill"
        case .image: return "photo"
        case .audio: return "waveform"
        case .video: return "video"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .embedding: return "arrow.down.right.and.arrow.up.left.circle"
        case .multiModal: return "circle.hexagongrid.fill"
        case .vision: return "eye"
        case .other: return "questionmark"
        }
    }
}

// Unified AI Model protocol
protocol UnifiedAIModel: Identifiable, Hashable, CustomStringConvertible {
    var id: String { get }                       // Unique
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
    var popularity: Double? { get }     // E.g. based on likes/downloads
    var stats: [String: String] { get } // Other dynamic "metrics"
    var navigationIcon: String { get }
    var displayColor: Color { get }
}

// MARK: - Model Implementations (Mock datasets, Easy Extensions)

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

// MARK: - Mock Data Providers

protocol UnifiedModelService {
    func fetchModels() async throws -> [any UnifiedAIModel]
}
struct OpenAIMockProvider: UnifiedModelService {
    func fetchModels() async throws -> [any UnifiedAIModel] {
        [OpenAIModelUnified(id: "gpt-4o", displayName: "GPT-4o",
            family: "GPT", version: "4o", owner: "OpenAI", releaseDate: Date(timeIntervalSinceNow: -86400*60),
            isPreview: true, isExperimental: false, isLive: true,
            shortDescription: "Fastest, most capable GPT-4 model", detailedDescription: "Handles text, image (vision), supports streaming.",
            inputCapabilities: [.text, .image], outputCapabilities: [.text, .image], tags: ["multimodal", "fast"],
            popularity: 0.98, stats: ["likes": "999K", "downloads": "3M"],
            navigationIcon: "bolt.fill", displayColor: .indigo)] // Add more...
    }
}
struct GeminiMockProvider: UnifiedModelService {
    func fetchModels() async throws -> [any UnifiedAIModel] {
        [GeminiModelUnified(id: "gemini-2.5-pro", displayName: "Gemini 2.5 Pro",
            family: "Gemini", version: "2.5", owner: "Google", releaseDate: Date(timeIntervalSinceNow: -86400*20),
            isPreview: false, isExperimental: false, isLive: false,
            shortDescription: "Enhanced reasoning and multimodal", detailedDescription: "Newest Gemini Pro model for advanced tasks.",
            inputCapabilities: [.text, .image, .audio], outputCapabilities: [.text], tags: ["flagship", "reasoning", "multimodal"],
            popularity: 0.91, stats: ["users": "2M"],
            navigationIcon: "star.fill", displayColor: .cyan)] // Add more...
    }
}
struct DeepSeekMockProvider: UnifiedModelService {
    func fetchModels() async throws -> [any UnifiedAIModel] {
        [DeepSeekModelUnified(id: "deepseek-ai/DeepSeek-V3", displayName: "DeepSeek V3",
            family: "DeepSeek", version: "V3", owner: "DeepSeek", releaseDate: Date(timeIntervalSinceNow: -86400*15),
            isPreview: false, isExperimental: false, isLive: false,
            shortDescription: "Vision and language, high quality", detailedDescription: "Advanced vision-language model supporting multimodal inputs.",
            inputCapabilities: [.text, .image], outputCapabilities: [.text], tags: ["vision", "language"],
            popularity: 0.89, stats: ["downloads": "423K"],
            navigationIcon: "photo.on.rectangle.angled", displayColor: .purple)] // Add more...
    }
}
struct LlamaMockProvider: UnifiedModelService {
    func fetchModels() async throws -> [any UnifiedAIModel] {
        [LlamaModelUnified(id: "meta-llama/Llama-3.1-70B-Instruct", displayName: "Llama 3.1 70B Instruct",
            family: "Llama", version: "3.1", owner: "Meta", releaseDate: Date(timeIntervalSinceNow: -86400*25),
            isPreview: false, isExperimental: false, isLive: false,
            shortDescription: "Powerful instruction-tuned model", detailedDescription: "Llama 3.1 with 70B params, tuned for following instructions.",
            inputCapabilities: [.text], outputCapabilities: [.text], tags: ["instruct", "large"],
            popularity: 0.87, stats: ["likes": "40K"],
            navigationIcon: "hare.fill", displayColor: .green)] // Add more...
    }
}

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

// MARK: - Unified ViewModel

@MainActor
final class UnifiedModelExplorerVM: ObservableObject {
    @Published var selection: ModelProvider = .gemini
    @Published var models: [any UnifiedAIModel] = []
    @Published var search: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    func loadModels() {
        isLoading = true
        error = nil
        Task {
            do {
                let fetched = try await UnifiedProviderFactory.provider(for: selection).fetchModels()
                self.models = fetched.sorted(by: { $0.popularity ?? 0 > $1.popularity ?? 0 })
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    var filteredModels: [any UnifiedAIModel] {
        if search.trimmingCharacters(in: .whitespaces).isEmpty { return models }
        let q = search.lowercased()
        return models.filter { $0.displayName.lowercased().contains(q) || $0.tags.contains(where: { $0.lowercased().contains(q) }) }
    }
}

// MARK: - Modern SwiftUI Interface
struct UnifiedModelExplorerView: View {
    @StateObject var vm = UnifiedModelExplorerVM()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                providerPickerBar(vm: vm)
                searchBar(vm: vm)
                contentBody(vm: vm)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        vm.selection.palette.opacity(0.09),
                        colorScheme == .dark ? .black : .white
                    ]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .navigationTitle("AI Model Explorer")
            .onAppear(perform: vm.loadModels)
            .onChange(of: vm.selection, vm.loadModels)
        }
    }

    @ViewBuilder
    private func providerPickerBar(vm: UnifiedModelExplorerVM) -> some View {
        HStack {
            Picker("Provider", selection: $vm.selection) {
                Text("UnifiedModelExplorerVM.selection")
//                ForEach(ModelProvider.allCases) { src in
//                    Label("src.rawValue, systemImage: src.logo.symbolName")//.tag(src)
//                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            Spacer()
            if vm.isLoading {
                ProgressView().padding(.trailing, 15)
            }
        }
        .padding(.vertical)
    }

    @ViewBuilder
    private func searchBar(vm: UnifiedModelExplorerVM) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search models/tags...", text: $vm.search)
        }
        .padding(10)
        .background(.ultraThickMaterial)
        .cornerRadius(12)
        .padding([.horizontal, .bottom])
    }

    @ViewBuilder
    private func contentBody(vm: UnifiedModelExplorerVM) -> some View {
        if let err = vm.error {
            ErrorBanner(message: err) { vm.loadModels() }
        } else if vm.filteredModels.isEmpty {
            ContentUnavailableView("No models found", systemImage: "exclamationmark.triangle.fill")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            modelScrollList(vm: vm)
        }
    }

    @ViewBuilder
    private func modelScrollList(vm: UnifiedModelExplorerVM) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 15) {
                ForEach(vm.filteredModels, id: \.id) { model in
                    NavigationLink(
                        destination: ModelDetailUnifiedView(model: model)
                    ) {
                        ModelCardUnifiedView(model: model)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
    }
}

//struct UnifiedModelExplorerView: View {
//    @StateObject var vm = UnifiedModelExplorerVM()
//    @Environment(\.colorScheme) var colorScheme
//    
//    var body: some View {
//        Text("UnifiedModelExplorerView")
//    }
//
////    var body: some View {
////        NavigationStack {
////            VStack(spacing: 0) {
////                HStack {
////                    Picker("Provider", selection: $vm.selection) {
////                        ForEach(ModelProvider.allCases) { src in
////                            Label(src.rawValue, systemImage: src.logo.symbolName).tag(src)
////                        }
////                    }
////                    .pickerStyle(.segmented)
////                    .padding(.horizontal)
////                    
////                    Spacer()
////                    if vm.isLoading {
////                        ProgressView().padding(.trailing, 15)
////                    }
////                }
////                .padding(.vertical)
////                
////                HStack {
////                    Image(systemName: "magnifyingglass")
////                    TextField("Search models/tags...", text: $vm.search)
////                }
////                .padding(10).background(.ultraThickMaterial)
////                .cornerRadius(12)
////                .padding([.horizontal, .bottom])
////                
////                if let err = vm.error {
////                    ErrorBanner(message: err) { vm.loadModels() }
////                } else if vm.filteredModels.isEmpty {
////                    ContentUnavailableView("No models found", systemImage: "exclamationmark.triangle.fill")
////                        .frame(maxWidth: .infinity, maxHeight: .infinity)
////                } else {
////                    ScrollView {
////                        LazyVStack(alignment: .leading, spacing: 15) {
////                            ForEach(vm.filteredModels) { model in
////                                NavigationLink(
////                                    destination: ModelDetailUnifiedView(model)
////                                ) {
////                                    ModelCardUnifiedView(model)
////                                }
////                                .buttonStyle(.plain)
////                            }
////                        }
////                        .padding(.horizontal)
////                        .padding(.vertical, 5)
////                    }
////                }
////            }
////            .background(LinearGradient(gradient: Gradient(colors: [vm.selection.palette.opacity(0.09), colorScheme == .dark ? .black : .white]), startPoint: .topLeading, endPoint: .bottomTrailing))
////            .navigationTitle("AI Model Explorer")
////            .onAppear(perform: vm.loadModels)
////            .onChange(of: vm.selection, vm.loadModels)
////        }
////    }
//}

struct ErrorBanner: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        HStack {
            Image(systemName: "xmark.octagon").foregroundColor(.red)
            Text(message).font(.caption)
            Spacer()
            Button(action: retry) { Label("Retry", systemImage: "gobackward") }
                .labelStyle(.iconOnly)
        }
        .padding(10).background(.ultraThinMaterial).cornerRadius(8).padding(.horizontal)
    }
}

// MARK: - Card and Detail UI

struct ModelCardUnifiedView: View {
    let model: any UnifiedAIModel
    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: model.navigationIcon)
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(model.displayColor)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.displayName).font(.headline)
                    if model.isPreview { flag("Preview", .orange) }
                    if model.isExperimental { flag("Exp", .pink) }
                    if model.isLive { flag("Live", .green) }
                    Spacer()
                }
                if let desc = model.shortDescription {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 7) {
                    ForEach(model.inputCapabilities, id: \.self) { cap in
                        Label(cap.rawValue, systemImage: cap.icon)
                            .font(.caption2).foregroundColor(.primary.opacity(0.85))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(model.displayColor.opacity(0.09)).clipShape(Capsule())
                    }
                    if let pop = model.popularity {
                        Text("▲ \(Int(pop * 100))")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 5)
                            .background(Color.green.opacity(0.11))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(.thickMaterial.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    @ViewBuilder
    private func flag(_ value: String, _ color: Color) -> some View {
        Text(value).font(.caption2).bold().padding(.horizontal, 7).padding(.vertical,2)
            .background(color.opacity(0.18)).foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct ModelDetailUnifiedView: View {
    let model: any UnifiedAIModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: model.navigationIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(model.displayColor)
                        .background(model.displayColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.displayName).font(.title2.bold())
                        HStack(spacing: 6) {
                            Text(model.provider.rawValue).font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(model.displayColor.opacity(0.18)).clipShape(Capsule())
                            if let fam = model.family { Text(fam).font(.caption.weight(.regular)) }
                            if model.isPreview { flag("Preview", .orange) }
                            if model.isExperimental { flag("Exp", .pink) }
                            if model.isLive { flag("Live", .green) }
                        }
                    }
                }
                if let desc = model.detailedDescription { Text(desc).fixedSize(horizontal: false, vertical: true) }
                
                SectionView("Input Capabilities", model.inputCapabilities.map { $0.rawValue })
                SectionView("Output Capabilities", model.outputCapabilities.map { $0.rawValue })
                if !model.tags.isEmpty { SectionView("Tags", model.tags) }
                
                Divider()
                VStack(alignment: .leading, spacing: 7) {
                    Text("Metrics & Popularity")
                        .font(.headline.weight(.bold))
                    ForEach(model.stats.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                        HStack {
                            Text("\(k.capitalized):").frame(width: 81, alignment: .trailing)
                            Text(v).bold()
                        }
                        .font(.callout)
                    }
                }
                .padding(.vertical, 8)
                
            }
            .frame(maxWidth: 650)
            .padding()
        }
        .navigationTitle(model.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { /* Future: Add favorite/share/report buttons if needed. */ }
        }
    }
    @ViewBuilder
    private func SectionView(_ label: String, _ vals: [String]) -> some View {
        if !vals.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.subheadline.bold()).foregroundColor(.secondary)
                WrappingHStack(items: vals) { value in
                    Text(value.capitalized)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.06))
                        .clipShape(Capsule())
                        .padding(.bottom,1)
                }
            }
        }
    }
    @ViewBuilder
    private func flag(_ value: String, _ color: Color) -> some View {
        Text(value).font(.caption2).bold().padding(.horizontal,7).padding(.vertical,2)
            .background(color.opacity(0.12)).foregroundColor(color)
            .clipShape(Capsule())
    }
}

// MARK: - WrappingHStack helper

struct WrappingHStack<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    let viewForItem: (Item) -> ItemView
    let horizontalSpacing: CGFloat = 10
    let verticalSpacing: CGFloat = 7
    @State private var totalHeight: CGFloat = .zero
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self._generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    private func _generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero; var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(self.items, id: \.self) { item in
                self.viewForItem(item)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width) { width = 0; height -= d.height + verticalSpacing }
                        let result = width
                        if item == self.items.last { width = 0 }
                        else { width -= d.width + horizontalSpacing }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if item == self.items.last { height = 0 }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async { binding.wrappedValue = geo.size.height }
            return Color.clear
        }
    }
}

// MARK: - Previews

#Preview("AI Model Explorer") { UnifiedModelExplorerView() }
