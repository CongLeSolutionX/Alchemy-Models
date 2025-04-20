//
//  Unified_AI_Model_Collection_View_V6.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  UnifiedModelExplorerFullFunction.swift
//  Demo
//
//  Created by AI Assistant, 2024.

import SwiftUI
import UniformTypeIdentifiers // For copy-to-clipboard

// -- MARK: Data Model Definitions (as previously defined; see earlier for full protocol/enum structure)

enum ModelProvider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case gemini = "Gemini"
    case deepseek = "DeepSeek"
    case llama = "Llama"
    var id: String { rawValue }
    var logo: String {
        switch self {
        case .openai:   return "circle.hexagonpath.fill"
        case .gemini:   return "diamond.lefthalf.filled"
        case .deepseek: return "cube.transparent.fill"
        case .llama:    return "hare.fill"
        }
    }
    var color: Color {
        switch self {
        case .openai:   return .indigo
        case .gemini:   return .cyan
        case .deepseek: return .purple
        case .llama:    return .green
        }
    }
}
enum ModelCapability: String, CaseIterable, Identifiable, Hashable {
    case text = "Text", image = "Image", audio = "Audio", video = "Video", code = "Code", vision = "Vision", embedding = "Embedding", multiModal = "Multi-Modal"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .audio: return "waveform.path.ecg"
        case .video: return "video"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .embedding: return "externaldrive.fill"
        case .vision: return "eye"
        case .multiModal: return "circle.hexagongrid"
        }
    }
}
protocol UnifiedAIModel: Identifiable, Hashable {
    var id: String { get }
    var provider: ModelProvider { get }
    var displayName: String { get }
    var shortDescription: String? { get }
    var inputCapabilities: [ModelCapability] { get }
    var outputCapabilities: [ModelCapability] { get }
    var popularity: Double? { get }
    var isLive: Bool { get }
    var isPreview: Bool { get }
}
struct AIModel: UnifiedAIModel {
    var id: String, provider: ModelProvider, displayName: String
    var shortDescription: String?
    var inputCapabilities: [ModelCapability]
    var outputCapabilities: [ModelCapability]
    var popularity: Double?
    var isLive: Bool
    var isPreview: Bool
    // Expandable with other metadata fields as desired
}
extension AIModel {
    static func mockAll() -> [AIModel] {
        [
            // Give each provider at least 2 models for demo
            AIModel(id: "gpt-4o", provider: .openai, displayName: "GPT-4o", shortDescription: "OpenAI's best omni-modal model.", inputCapabilities: [.text, .image, .audio], outputCapabilities: [.text, .image, .audio], popularity: 0.98, isLive: true, isPreview: false),
            AIModel(id: "gpt-4-turbo", provider: .openai, displayName: "GPT-4 Turbo", shortDescription: "Efficient, high-context GPT-4.", inputCapabilities: [.text, .image], outputCapabilities: [.text], popularity: 0.91, isLive: true, isPreview: true),
            AIModel(id: "gemini-1.5-pro", provider: .gemini, displayName: "Gemini 1.5 Pro", shortDescription: "Google's flagship multimodal.", inputCapabilities: [.text, .image, .code, .audio, .video], outputCapabilities: [.text, .code], popularity: 0.96, isLive: true, isPreview: false),
            AIModel(id: "gemini-1.5-flash", provider: .gemini, displayName: "Gemini 1.5 Flash", shortDescription: "Lightweight, fast inference Gemini.", inputCapabilities: [.text, .image], outputCapabilities: [.text], popularity: 0.89, isLive: true, isPreview: true),
            AIModel(id: "deepseek-llm-67b", provider: .deepseek, displayName: "DeepSeek LLM 67B", shortDescription: "LLM with leading multilingual skills.", inputCapabilities: [.text], outputCapabilities: [.text], popularity: 0.85, isLive: true, isPreview: false),
            AIModel(id: "deepseek-coder-33b", provider: .deepseek, displayName: "DeepSeek Coder 33B", shortDescription: "SOTA code reasoning model.", inputCapabilities: [.code, .text], outputCapabilities: [.code], popularity: 0.82, isLive: false, isPreview: true),
            AIModel(id: "llama-3.1-405B", provider: .llama, displayName: "Llama 3.1 405B", shortDescription: "Meta's most powerful Llama.", inputCapabilities: [.text, .code], outputCapabilities: [.text, .code], popularity: 0.91, isLive: false, isPreview: true),
            AIModel(id: "llama-3.1-8B", provider: .llama, displayName: "Llama 3.1 8B", shortDescription: "Lightweight and deployable Llama.", inputCapabilities: [.text], outputCapabilities: [.text], popularity: 0.79, isLive: true, isPreview: false),
        ]
    }
}

// -- MARK: ViewModel
final class UnifiedModelExplorerVM: ObservableObject {
    @Published var selection: ModelProvider = .openai
    @Published var search: String = ""
    @Published var filters: Set<ModelCapability> = []
    @Published var sort: SortBy = .popularity
    @Published var models: [AIModel] = AIModel.mockAll()
    @Published var isRefreshing: Bool = false
    @Published var favorites: Set<String> = UserDefaults.standard.object(forKey: "favoriteIDs") as? Set<String> ?? []
    @Published var error: String?
    enum SortBy: String, CaseIterable, Identifiable {
        case popularity, name, capabilityCount
        var id: String { rawValue }
    }
    var filtered: [AIModel] {
        models.filter { $0.provider == selection }
            .filter { model in
                search.isEmpty ||
                model.displayName.lowercased().contains(search.lowercased()) ||
                (model.shortDescription?.lowercased().contains(search.lowercased()) ?? false)
            }
            .filter { model in
                filters.isEmpty || !filters.subtracting(model.inputCapabilities).isEmpty == false }
            .sorted {
                switch sort {
                    case .popularity:
                        return ($0.popularity ?? 0) > ($1.popularity ?? 0)
                    case .name:
                        return $0.displayName.lowercased() < $1.displayName.lowercased()
                    case .capabilityCount:
                        return $0.inputCapabilities.count > $1.inputCapabilities.count
                }
            }
    }
    func toggleFavorite(_ model: AIModel) {
        if favorites.contains(model.id) { favorites.remove(model.id) }
        else { favorites.insert(model.id) }
        UserDefaults.standard.set(Array(favorites), forKey: "favoriteIDs")
    }
    func isFavorite(_ model: AIModel) -> Bool {
        favorites.contains(model.id)
    }
    func refresh() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 900_000_000) // mock delay
        // Example: simulate error on "deepseek"
        if selection == .deepseek, .random(in: 1...5) == 1 { error = "Network error"; isRefreshing = false; return }
        isRefreshing = false
        models = AIModel.mockAll().shuffled() // simulate shuffling data
    }
}

// -- MARK: Main View

struct UnifiedModelExplorerView: View {
    @StateObject var vm = UnifiedModelExplorerVM()
    @State private var selectedModel: AIModel?
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pickerBar
                searchBar
                filterBar
                modelList
            }
            .navigationTitle("AI Model Explorer")
            .background(LinearGradient(gradient: Gradient(colors: [vm.selection.color.opacity(0.1), .clear]), startPoint: .topLeading, endPoint: .bottomTrailing))
            .toolbar { toolbar }
            .sheet(item: $selectedModel) { m in
                ModelDetailView(model: m, isFavorite: vm.isFavorite(m),
                                onFavorite: { vm.toggleFavorite(m) })
            }
        }
    }
    // Provider Picker (segmented)
    var pickerBar: some View {
        Picker("", selection: $vm.selection) {
            ForEach(ModelProvider.allCases) { provider in
                Label(provider.rawValue, systemImage: provider.logo).tag(provider)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 5)
    }
    // Search Field
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search name or info...", text: $vm.search)
                .textFieldStyle(.plain)
            if !vm.search.isEmpty {
                Button { vm.search="" } label: {
                    Image(systemName: "xmark.circle.fill").padding(.horizontal, 2)
                }
                .animation(.easeIn, value: vm.search)
            }
        }
        .padding(8)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal)
    }
    // Capability Filter Bar (Horizontal Scroll, tap to select)
    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(ModelCapability.allCases) { cap in
                    Button {
                        if vm.filters.contains(cap) { vm.filters.remove(cap) }
                        else { vm.filters.insert(cap) }
                    } label: {
                        HStack {
                            Image(systemName: cap.icon)
                            Text(cap.rawValue)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(vm.filters.contains(cap) ?
                                    vm.selection.color.opacity(0.13) : .clear)
                        .foregroundStyle(vm.filters.contains(cap) ?
                                         vm.selection.color : .secondary)
                        .clipShape(Capsule())
                    }
                }
                if !vm.filters.isEmpty {
                    Button(role: .destructive) {
                        vm.filters.removeAll()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 2)
    }
    // Model List
    var modelList: some View {
        Group {
            if let err = vm.error {
                VStack(spacing: 12) {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Button("Retry") { Task { await vm.refresh() }; vm.error = nil }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.filtered.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                    Text(vm.search.isEmpty && vm.filters.isEmpty ? "No models for this provider." : "No results. Try clearing filters/search.")
                        .font(.callout)
                    if !vm.filters.isEmpty || !vm.search.isEmpty {
                        Button("Clear") { vm.filters.removeAll(); vm.search = "" }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(vm.filtered, id: \.id) { model in
                            Button {
                                selectedModel = model
                            } label: {
                                ModelCard(model: model, isFavorite: vm.isFavorite(model))
                            }
                            .buttonStyle(.plain)
                        }
                    }.padding(.horizontal, 16).padding(.vertical, 7)
                }
                .refreshable { await vm.refresh() }
            }
        }
        .animation(.default, value: vm.filtered)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    // Toolbar / Sorting
    var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Picker("Sort by", selection: $vm.sort) {
                    ForEach(UnifiedModelExplorerVM.SortBy.allCases) { sort in
                        Label(sort.rawValue.capitalized, systemImage: {
                            switch sort {
                            case .popularity: "flame.fill"
                            case .name: "textformat.size"
                            case .capabilityCount: "puzzlepiece.fill"
                            }
                        }()).tag(sort)
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down.circle")
            }
            Button {
                Task { await vm.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise.circle")
            }
        }
    }
}

// -- MARK: Supporting Model Card View

struct ModelCard: View {
    let model: AIModel
    let isFavorite: Bool
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: model.provider.logo)
                .font(.system(size: 32))
                .frame(width: 44, height: 44).foregroundColor(model.provider.color)
                .background(model.provider.color.opacity(0.18)).clipShape(Circle())
                .accessibility(hidden: true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(model.displayName).lineLimit(1).font(.headline)
                    if isFavorite { Image(systemName:"star.fill").foregroundColor(.yellow) }
                    if model.isPreview { flag("PRE", .orange) }
                    if model.isLive { flag("LIVE", .green) }
                }
                if let desc = model.shortDescription { Text(desc).font(.subheadline).foregroundColor(.secondary) }
                WrappingHStack(model.inputCapabilities, horizontalSpacing: 6) { c in
                    Label("", systemImage: c.icon).frame(width: 20)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                if let pop = model.popularity {
                    HStack(spacing: 2) { Image(systemName:"flame.fill"); Text("\(Int(pop*100))%") }
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal,7).padding(.vertical,2)
                        .background(Color.orange.opacity(0.1)).clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color:.black.opacity(0.05), radius:2, y: 1)
    }
    @ViewBuilder
    private func flag(_ text:String, _ color:Color) -> some View {
        Text(text).font(.caption2).bold()
            .padding(.horizontal, 5)
            .foregroundColor(color)
            .background(color.opacity(0.21))
            .clipShape(Capsule())
    }
}

// -- MARK: Modal Detail View

struct ModelDetailView: View {
    let model: AIModel
    @State var isFavorite: Bool
    var onFavorite: () -> Void
    @State private var showCopy: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack (alignment:.top) {
                        Image(systemName: model.provider.logo)
                            .resizable().scaledToFit()
                            .frame(width:52,height:52)
                            .foregroundColor(model.provider.color)
                            .background(model.provider.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        VStack (alignment:.leading) {
                            Text(model.displayName).font(.title2).bold()
                            HStack { if model.isPreview { flag("PRE",.orange) } ; if model.isLive { flag("LIVE",.green)} }
                        }
                        Spacer()
                        if isFavorite {
                            Image(systemName: "star.fill").foregroundColor(.yellow)
                        }
                    }
                    if let descr = model.shortDescription {
                        Text(descr)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                    }
                }
                Section(header: Text("Capabilities")) {
                    HStack {
                        Label("Input", systemImage: "tray.and.arrow.down.fill")
                        WrappingHStack(model.inputCapabilities) { c in
                            Label(c.rawValue, systemImage: c.icon)
                                .font(.caption)
                                .padding(.horizontal,7).padding(.vertical,2)
                                .background(model.provider.color.opacity(0.13))
                                .clipShape(Capsule())
                        }
                    }
                    HStack {
                        Label("Output", systemImage: "tray.and.arrow.up.fill")
                        WrappingHStack(model.outputCapabilities) { c in
                            Label(c.rawValue, systemImage: c.icon)
                                .font(.caption)
                                .padding(.horizontal,7).padding(.vertical,2)
                                .background(model.provider.color.opacity(0.09))
                                .clipShape(Capsule())
                        }
                    }
                }
                Section(header: Text("Info")) {
                    HStack { Text("Model ID: ").foregroundColor(.secondary); Spacer(); Text(model.id).font(.callout).textSelection(.enabled)
                        Button { UIPasteboard.general.string = model.id; showCopy = true; } label: { Image(systemName: "doc.on.doc") }
                    }
                    if let pop = model.popularity {
                        HStack { Label("Popularity", systemImage:"flame.fill"); Spacer(); Text("\(Int(pop*100))%").bold().foregroundColor(.orange)}
                    }
                }
            }
            .listStyle(.grouped)
            .navigationBarTitle(model.displayName, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isFavorite.toggle()
                        onFavorite()
                    } label: { Image(systemName: isFavorite ? "star.fill" : "star") }
                        .foregroundColor(isFavorite ? .yellow : .primary)
                        .accessibilityLabel(isFavorite ? "Unfavorite" : "Favorite")
                }
                ToolbarItem(placement:.navigationBarTrailing) {
                    ShareLink(item: "\(model.displayName)\n\(model.shortDescription ?? "")", label: {
                        Image(systemName:"square.and.arrow.up")
                    })
                }
            }
            .alert("Copied!", isPresented: $showCopy) { Button("OK", role: .cancel) { } }
        }
    }
    @ViewBuilder
    private func flag(_ text: String, _ color: Color) -> some View {
        Text(text).font(.caption2).bold()
            .padding(.horizontal, 6).background(color.opacity(0.16)).foregroundColor(color)
            .clipShape(Capsule())
    }
}

// --- Modern WrappingHStack (as before) ---

struct WrappingHStack<Item:Hashable, Content:View>: View {
    var items: [Item]
    var horizontalSpacing: CGFloat = 7
    var verticalSpacing: CGFloat = 7
    var content: (Item)->Content
    init(_ items: [Item], horizontalSpacing: CGFloat = 7, @ViewBuilder content: @escaping (Item)->Content) {
        self.items = items; self.horizontalSpacing = horizontalSpacing; self.content = content
    }
    @State private var totalHeight = CGFloat.zero
    var body: some View {
        GeometryReader{g in
            self.generateContent(in: g)
        }.frame(height: totalHeight)
    }
    func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                .padding(.trailing, horizontalSpacing)
                .alignmentGuide(.leading, computeValue: { d in
                    if (abs(width - d.width) > g.size.width) { width = 0; height -= d.height }
                    let result = width
                    if item == items.last { width = 0 }
                    else { width -= d.width }
                    return result
                })
                .alignmentGuide(.top, computeValue: { _ in
                    let result = height
                    if item == items.last { height = 0 }
                    return result
                })
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    func viewHeightReader(_ binding:Binding<CGFloat>) -> some View {
        GeometryReader { geo in
            Color.clear.preference(key: FrameHeightPreferenceKey.self, value: geo.size.height)
        }
        .onPreferenceChange(FrameHeightPreferenceKey.self) { binding.wrappedValue = $0 }
    }
    
    struct FrameHeightPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0.0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

// --- Previews
#Preview {
    UnifiedModelExplorerView().preferredColorScheme(.light)
}
