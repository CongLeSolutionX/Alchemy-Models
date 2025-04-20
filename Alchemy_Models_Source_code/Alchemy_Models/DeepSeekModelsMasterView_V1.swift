////
////  DeepSeekModelsMasterView.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  DeepSeekModelsMasterView.swift
////  DeepSeek_Models_Viewer
////  (Single File Implementation)
////
////  Created: Cong Le
////  Date: 4/13/25 (Based on previous OpenAI examples and new screenshots)
////  Version: 1.0
////  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
////  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
////
//
//import SwiftUI
//import Foundation // Needed for URL?
//
//// MARK: - Enums (Optional - could be used for Categories later)
//
//// Example:
//// enum ModelCategory: String, Codable, CaseIterable {
////     case textGeneration = "Text Generation"
////     case imageTextToText = "Image-Text-to-Text"
////     // ... add others
//// }
//
//// MARK: - API Service Protocol
//
//protocol DeepSeekAPIServiceProtocol {
//    func fetchModels() async throws -> [DeepSeekModel]
//}
//
//// MARK: - Data Models
//
//struct PaperInfo: Codable, Hashable, Identifiable {
//    var id: String { title } // Use title as ID for simplicity
//    let title: String
//    let date: String // e.g., "Published Dec 26, 2024"
//    let link: URL? // Example: "https://arxiv.org/abs/2412.19437"
//    let reads: String? // e.g., "58"
//}
//
//struct DeepSeekModel: Codable, Identifiable, Hashable {
//    let id: String // Full model path, e.g., deepseek-ai/DeepSeek-R1
//    var displayName: String { // Attempt to create a cleaner display name
//        let parts = id.split(separator: "/")
//        return parts.count > 1 ? String(parts[1]) : id
//    }
//    let category: String // e.g., "Text Generation", "Image-Text-to-Text"
//    let lastUpdated: String // e.g., "Updated 24 days ago", "Updated Feb 6, 2024"
//    let downloads: String? // e.g., "1.73M", "92.9k"
//    let likes: String? // e.g., "12k", "179"
//    let sectionTitle: String // To group models, e.g., "DeepSeek-R1"
//    let sectionSubtitle: String? // Optional subtitle for the section header
//
//    // For featured cards
//    let isFeatured: Bool?
//    let featureTitle: String? // e.g., "Chat with DeepseekVL2-small"
//    let featureMetric: String? // e.g., "465 ❤️" or "1.95k 👍"
//    let featureDescription: String? // e.g., "Generate responses using images and text input"
//
//    // For Paper links within sections
//    // Note: This is associated with the *section* in the UI,
//    // but storing it in the model helps group data during mock creation.
//    // A better structure might have a Section object containing models and paper info.
//    let associatedPaper: PaperInfo?
//
//    // Helper to sort models within sections (optional)
//    var sortPriority: Int {
//        if isFeatured ?? false { return 0 }
//        // Add more rules if needed, e.g., prioritize .base over distill
//        if id.lowercased().contains("base") { return 1 }
//        return 10 // Default
//    }
//
//    // --- Simple Hashable Conformance ---
//    func hash(into hasher: inout Hasher) { hasher.combine(id) }
//    static func == (lhs: DeepSeekModel, rhs: DeepSeekModel) -> Bool { lhs.id == rhs.id }
//}
//
//// MARK: - API Service Implementations
//
//// --- Mock Data Service ---
//class MockDeepSeekService: DeepSeekAPIServiceProtocol {
//    private let mockNetworkDelaySeconds: Double = 0.5
//
//    // --- Generate Mock Models Based on Screenshots ---
//    private func generateMockModels() -> [DeepSeekModel] {
//        let deepseekR1Subtitle = "DeepSeek R1 series models." // Example subtitle
//        let deepseekVL2Subtitle = "Vision-Language models." // Example subtitle
//        let deepseekV3Subtitle = "DeepSeek V3 series." // Example subtitle
//        let janusSubtitle = "Janus is a novel autoregressive framework..." // Example subtitle
//        let deepseekV2Subtitle = "DeepSeek V2 series models." // Example subtitle
//        let deepseekProverSubtitle = "DeepSeekV1-and-V1.5-Series"
//        let deepseekCoderV2Subtitle = "DeepSeek Coder V2 models."
//        let esftSubtitle = "Models for paper expert-specialized fine-tuning"
//        let deepseekCoderSubtitle = "DeepSeek Coder series"
//        let deepseekMoESubtitle = "DeepSeek MoE series"
//        let deepseekMathSubtitle = "DeepSeek Math series"
//        let deepseekVLSubtitle = "DeepSeek-VL model series"
//        let deepseekLLMSubtitle = "DeepSeek LLM series"
//        let deepseekV25Subtitle = "DeepSeek V2.5 models"
//
//        // Paper Info
//        let v3Paper = PaperInfo(title: "DeepSeekV3 Technical Report", date: "Published Dec 26, 2024", link: URL(string:"https://arxiv.org/abs/2412.19437"), reads: "58") // Assuming link / date for V3
//        let proverPaper = PaperInfo(title: "DeepSeek-ProverV1.5: Harnessing Proof Assistant Feedback for Reasoning...", date: "Updated Aug 29, 2024", link: nil, reads: nil) // Link TBD
//        let moePaper = PaperInfo(title: "DeepSeekMoE: Towards Ultimate Expert Specialization in Mixture-of-Experts", date: "Published Jan 11, 2024", link: URL(string:"https://arxiv.org/abs/2401.06066"), reads: "55")
//         let mathPaper = PaperInfo(title: "DeepSeekMath: Pushing the Limits of Mathematical Reasoning in Open Language Models", date: "Updated Feb 5, 2024", link: nil, reads: nil) // Link TBD
//
//        return [
//            // --- DeepSeek-R1 Section ---
//            
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "1.73M", likes: "12k", sectionTitle: "DeepSeek-R1", sectionSubtitle: deepseekR1Subtitle,isFeatured: false,featureTitle: nil,featureMetric: nil, featureDescription: nil, associatedPaper: nil),
//            
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Zero", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "5.7k", likes: "899", sectionTitle: "DeepSeek-R1", sectionSubtitle: deepseekR1Subtitle, associatedPaper: nil),
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Distill-Llama-70B", category: "Text Generation", lastUpdated: "Updated Feb 23", downloads: "269k", likes: "664", sectionTitle: "DeepSeek-R1", sectionSubtitle: deepseekR1Subtitle, associatedPaper: nil),
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: nil, likes: nil, sectionTitle: "DeepSeek-R1", sectionSubtitle: deepseekR1Subtitle, associatedPaper: nil), // Likes/Downloads missing
////
////            // --- DeepSeek-VL2 Section ---
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-VL2-small-chat", category: "Image-Text Chat", lastUpdated: "N/A", downloads: nil, likes: nil, sectionTitle: "DeepSeek-VL2", sectionSubtitle: deepseekVL2Subtitle, isFeatured: true, featureTitle: "Chat with DeepseekVL2-small ✨", featureMetric: "465 ❤️", associatedPaper: nil, featureDescription: "Generate responses using images and text input"),
////            DeepSeekModel(id: "deepseek-ai/deepseek-vl2-tiny", category: "Image-Text-to-Text", lastUpdated: "Updated Dec 18, 2024", downloads: "92.9k", likes: "179", sectionTitle: "DeepSeek-VL2", sectionSubtitle: deepseekVL2Subtitle),
////            DeepSeekModel(id: "deepseek-ai/deepseek-vl2-small", category: "Image-Text-to-Text", lastUpdated: "Updated Dec 18, 2024", downloads: "135k", likes: "155", sectionTitle: "DeepSeek-VL2", sectionSubtitle: deepseekVL2Subtitle),
////            DeepSeekModel(id: "deepseek-ai/deepseek-vl2", category: "Vision Language", lastUpdated: "Updated Dec 18, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-VL2", sectionSubtitle: deepseekVL2Subtitle), // Assuming category based on 'VL'
////
////             // --- DeepSeek-Prover Section ---
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Prover-V1.5-Base", category: "Text Generation", lastUpdated: "Updated Aug 29, 2024", downloads: "1.06k", likes: "13", sectionTitle: "DeepSeek-Prover", sectionSubtitle: deepseekProverSubtitle, associatedPaper: proverPaper),
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Prover-V1.5-SFT", category: "Text Generation", lastUpdated: "Updated Aug 29, 2024", downloads: "21.5k", likes: "10", sectionTitle: "DeepSeek-Prover", sectionSubtitle: deepseekProverSubtitle, associatedPaper: proverPaper),
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Prover-V1.5-RL", category: "Text Generation", lastUpdated: "Updated Aug 29, 2024", downloads: "3.62k", likes: "57", sectionTitle: "DeepSeek-Prover", sectionSubtitle: deepseekProverSubtitle, associatedPaper: proverPaper),
////
////            // --- DeepSeek-V3 Section ---
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V3-Base", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "8.75k", likes: "1.63k", sectionTitle: "DeepSeek-V3", sectionSubtitle: deepseekV3Subtitle, associatedPaper: v3Paper),
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V3", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "749k", likes: "• 3.81k", sectionTitle: "DeepSeek-V3", sectionSubtitle: deepseekV3Subtitle, associatedPaper: v3Paper), // Likes format slightly different
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V3-0324", category: "Text Generation", lastUpdated: "Updated Mar 24, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-V3", sectionSubtitle: deepseekV3Subtitle, associatedPaper: v3Paper), // Assuming date based on ID
////
////            // --- Janus Section ---
////            DeepSeekModel(id: "deepseek-ai/Janus-Pro-7B-chat", category: "Any-to-Any Chat", lastUpdated: "N/A", downloads: nil, likes: nil, sectionTitle: "Janus", sectionSubtitle: janusSubtitle, isFeatured: true, featureTitle: "Chat With Janus-Pro 7B ✨", featureMetric: "1.95k 👍", featureDescription: "A unified multimodal understanding and generation model."),
////            DeepSeekModel(id: "deepseek-ai/Janus-Pro-7B", category: "Any-to-Any", lastUpdated: "Updated Feb 1", downloads: "239k", likes: "3.34k", sectionTitle: "Janus", sectionSubtitle: janusSubtitle),
////            DeepSeekModel(id: "deepseek-ai/Janus-Pro-1B", category: "Any-to-Any", lastUpdated: "Updated Feb 1", downloads: "33.1k", likes: "428", sectionTitle: "Janus", sectionSubtitle: janusSubtitle),
////            DeepSeekModel(id: "deepseek-ai/Janus-1.3B", category: "Any-to-Any", lastUpdated: "Updated Jul 18, 2024", downloads: nil, likes: nil, sectionTitle: "Janus", sectionSubtitle: janusSubtitle), // Assuming date
////
////            // --- DeepSeek-V2 Section ---
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2-Chat-0628", category: "Text Generation", lastUpdated: "Updated Jun 28, 2024", downloads: "185", likes: "175", sectionTitle: "DeepSeek-V2", sectionSubtitle: deepseekV2Subtitle),
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2-Chat", category: "Text Generation", lastUpdated: "Updated Jun 8, 2024", downloads: "1.37k", likes: "460", sectionTitle: "DeepSeek-V2", sectionSubtitle: deepseekV2Subtitle),
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2", category: "Text Generation", lastUpdated: "Updated Jun 8, 2024", downloads: "124k", likes: "316", sectionTitle: "DeepSeek-V2", sectionSubtitle: deepseekV2Subtitle),
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2-Lite", category: "Text Generation", lastUpdated: "Updated Jun 8, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-V2", sectionSubtitle: deepseekV2Subtitle), // Assuming date
////
////             // --- DeepSeek-Coder-V2 Section ---
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Coder-V2-Instruct", category: "Text Generation", lastUpdated: "Updated Aug 20, 2024", downloads: "19.2k", likes: "613", sectionTitle: "DeepSeek-Coder-V2", sectionSubtitle: deepseekCoderV2Subtitle),
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Coder-V2-Base", category: "Text Generation", lastUpdated: "Updated Jul 2, 2024", downloads: "230", likes: "68", sectionTitle: "DeepSeek-Coder-V2", sectionSubtitle: deepseekCoderV2Subtitle),
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Coder-V2-Lite-Base", category: "Text Generation", lastUpdated: "Updated Jul 2, 2024", downloads: "9.67k", likes: "80", sectionTitle: "DeepSeek-Coder-V2", sectionSubtitle: deepseekCoderV2Subtitle),
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Coder-V2-Lite-Instruct", category: "Text Generation", lastUpdated: "Updated Jul 2, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-Coder-V2", sectionSubtitle: deepseekCoderV2Subtitle), // Assuming date
////
////             // --- ESFT Section ---
////             DeepSeekModel(id: "deepseek-ai/ESFT-vanilla-lite", category: "Text Generation", lastUpdated: "Updated Jul 22, 2024", downloads: "1.13k", likes: "11", sectionTitle: "ESFT", sectionSubtitle: esftSubtitle),
////             DeepSeekModel(id: "deepseek-ai/ESFT-token-1aw-lite", category: "Text Generation", lastUpdated: "Updated Jul 4, 2024", downloads: "99", likes: "4", sectionTitle: "ESFT", sectionSubtitle: esftSubtitle),
////             DeepSeekModel(id: "deepseek-ai/ESFT-token-summary-lite", category: "Text Generation", lastUpdated: "Updated Jul 4, 2024", downloads: "61", likes: "3", sectionTitle: "ESFT", sectionSubtitle: esftSubtitle),
////             DeepSeekModel(id: "deepseek-ai/ESFT-token-code-lite", category: "Text Generation", lastUpdated: "Updated Jul 4, 2024", downloads: nil, likes: nil, sectionTitle: "ESFT", sectionSubtitle: esftSubtitle), // Assuming date
////
////             // --- DeepSeek-Coder Section ---
////             DeepSeekModel(id: "deepseek-ai/deepseek-coder-33b-instruct", category: "Text Generation", lastUpdated: "Updated Mar 7, 2024", downloads: "8.33k", likes: "507", sectionTitle: "DeepSeek-Coder", sectionSubtitle: deepseekCoderSubtitle),
////             DeepSeekModel(id: "deepseek-ai/deepseek-coder-6.7b-instruct", category: "Text Generation", lastUpdated: "Updated Feb 1, 2024", downloads: "46.8k", likes: "399", sectionTitle: "DeepSeek-Coder", sectionSubtitle: deepseekCoderSubtitle),
////             DeepSeekModel(id: "deepseek-ai/deepseek-coder-7b-instruct-v1.5", category: "Text Generation", lastUpdated: "Updated Feb 4, 2024", downloads: "5.44k", likes: "133", sectionTitle: "DeepSeek-Coder", sectionSubtitle: deepseekCoderSubtitle),
////             DeepSeekModel(id: "deepseek-ai/deepseek-coder-1.3b-instruct", category: "Text Generation", lastUpdated: "Updated Feb 4, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-Coder", sectionSubtitle: deepseekCoderSubtitle), // Assuming date
////
////             // --- DeepSeek-MoE Section ---
////             DeepSeekModel(id: "deepseek-ai/deepseek-moe-16b-base", category: "Text Generation", lastUpdated: "Updated Jan 11, 2024", downloads: "12.4k", likes: "114", sectionTitle: "DeepSeek-MoE", sectionSubtitle: deepseekMoESubtitle, associatedPaper: moePaper),
////             DeepSeekModel(id: "deepseek-ai/deepseek-moe-16b-chat", category: "Text Generation", lastUpdated: "Updated Feb 5, 2024", downloads: "33.5k", likes: "136", sectionTitle: "DeepSeek-MoE", sectionSubtitle: deepseekMoESubtitle, associatedPaper: moePaper),
////
////             // --- DeepSeek-Math Section ---
////             DeepSeekModel(id: "deepseek-ai/deepseek-math-7b-instruct", category: "Text Generation", lastUpdated: "Updated Feb 6, 2024", downloads: "59.3k", likes: "123", sectionTitle: "DeepSeek-Math", sectionSubtitle: deepseekMathSubtitle, associatedPaper: mathPaper),
////             DeepSeekModel(id: "deepseek-ai/deepseek-math-7b-rl", category: "Text Generation", lastUpdated: "Updated Mar 18, 2024", downloads: "1.6k", likes: "81", sectionTitle: "DeepSeek-Math", sectionSubtitle: deepseekMathSubtitle, associatedPaper: mathPaper),
////             DeepSeekModel(id: "deepseek-ai/deepseek-math-7b-base", category: "Text Generation", lastUpdated: "Updated Feb 6, 2024", downloads: "8.83k", likes: "69", sectionTitle: "DeepSeek-Math", sectionSubtitle: deepseekMathSubtitle, associatedPaper: mathPaper),
////
////             // --- DeepSeek-VL Section ---
////             DeepSeekModel(id: "deepseek-ai/deepseek-vl-7b-chat", category: "Image-Text-to-Text", lastUpdated: "Updated Mar 15, 2024", downloads: "17.1k", likes: "253", sectionTitle: "DeepSeek-VL", sectionSubtitle: deepseekVLSubtitle),
////             DeepSeekModel(id: "deepseek-ai/deepseek-vl-1.3b-base", category: "Image-Text-to-Text", lastUpdated: "Updated Mar 15, 2024", downloads: "2.12k", likes: "52", sectionTitle: "DeepSeek-VL", sectionSubtitle: deepseekVLSubtitle),
////             DeepSeekModel(id: "deepseek-ai/deepseek-vl-7b-base", category: "Image-Text-to-Text", lastUpdated: "Updated Mar 15, 2024", downloads: "1.33k", likes: "38", sectionTitle: "DeepSeek-VL", sectionSubtitle: deepseekVLSubtitle),
////             DeepSeekModel(id: "deepseek-ai/deepseek-vl-1.3b-chat", category: "Image-Text-to-Text", lastUpdated: "Updated Mar 15, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-VL", sectionSubtitle: deepseekVLSubtitle), // Assuming date
////
////             // --- DeepSeek-LLM Section ---
////             DeepSeekModel(id: "deepseek-ai/deepseek-llm-67b-chat", category: "Text Generation", lastUpdated: "Updated Nov 29, 2023", downloads: "4.17k", likes: "200", sectionTitle: "DeepSeek-LLM", sectionSubtitle: deepseekLLMSubtitle),
////             DeepSeekModel(id: "deepseek-ai/deepseek-llm-7b-chat", category: "Text Generation", lastUpdated: "Updated Nov 29, 2023", downloads: "157k", likes: "165", sectionTitle: "DeepSeek-LLM", sectionSubtitle: deepseekLLMSubtitle),
////             DeepSeekModel(id: "deepseek-ai/deepseek-llm-67b-base", category: "Text Generation", lastUpdated: "Updated Nov 29, 2023", downloads: "1.7k", likes: "121", sectionTitle: "DeepSeek-LLM", sectionSubtitle: deepseekLLMSubtitle),
////             DeepSeekModel(id: "deepseek-ai/deepseek-llm-7b-base", category: "Text Generation", lastUpdated: "Updated Nov 29, 2023", downloads: nil, likes: nil, sectionTitle: "DeepSeek-LLM", sectionSubtitle: deepseekLLMSubtitle), // Assuming date
////
////            // --- DeepSeek-V2.5 Section ---
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2.5", category: "Text Generation", lastUpdated: "Updated Dec 11, 2024", downloads: "1.99k", likes: "704", sectionTitle: "DeepSeek-V2.5", sectionSubtitle: deepseekV25Subtitle),
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2.5-1210", category: "Text Generation", lastUpdated: "Updated Dec 11, 2024", downloads: "673", likes: "253", sectionTitle: "DeepSeek-V2.5", sectionSubtitle: deepseekV25Subtitle), // Assuming date based on ID
//
//        ]
//    }
//
//    func fetchModels() async throws -> [DeepSeekModel] {
//        try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
//        return generateMockModels()
//        // In a real scenario, fetch from an API endpoint
//        // throw NSError(domain: "MockService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated fetch error"]) // Uncomment to test error
//    }
//}
//
//// MARK: - Reusable SwiftUI Helper Views
//
//// --- Reusable Section Header ---
//struct SectionHeader: View {
//    let title: String
//    let subtitle: String?
//    let showArrow: Bool = true
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 2) {
//                Text(title)
//                    .font(.title2.weight(.semibold))
//                if let subtitle = subtitle, !subtitle.isEmpty {
//                    Text(subtitle)
//                        .font(.footnote)
//                        .foregroundColor(.secondary)
//                        .lineLimit(2) // Allow subtitle wrapping slightly
//                }
//            }
//            Spacer()
//            if showArrow {
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.secondary)
//                    .font(.callout.weight(.semibold))
//            }
//        }
//        .padding(.vertical, 8)
//        .contentShape(Rectangle()) // Make entire HStack tappable if used in Button/Link
//    }
//}
//
//// --- Paper Info View ---
//struct PaperInfoView: View {
//    let paper: PaperInfo
//
//    var body: some View {
//        Text("PaperInfoView")
//            .font(.caption2)
//            .padding(.horizontal, 5).padding(.vertical, 2)
//            .background(Color.gray.opacity(0.2))
//            .clipShape(Capsule())
//    }
//    
////    var body: some View {
////        HStack(spacing: 10) {
////            Image(systemName: "doc.text.fill")
////                .foregroundColor(.secondary)
////                .font(.callout)
////            VStack(alignment: .leading, spacing: 2) {
////                Text(paper.title)
////                    .font(.footnote.weight(.medium))
////                    .lineLimit(1)
////                HStack(spacing: 6) {
////                    Text("Paper")
////                        .font(.caption2)
////                        .padding(.horizontal, 5).padding(.vertical, 2)
////                        .background(Color.gray.opacity(0.2))
////                        .clipShape(Capsule())
////
////                    Text(paper.date)
////                        .font(.caption2)
////                        .foregroundColor(.secondary)
////
////                    if let reads = paper.reads {
////                         Text("• \(reads) reads") // Assuming format - might need adjustment
////                            .font(.caption2)
////                             .foregroundColor(.secondary)
////                    }
////                }
////            }
////            Spacer()
////            if paper.link != nil {
////                 Image(systemName: "arrow.up.right.square")
////                     .foregroundColor(.blue)
////                     .font(.caption.weight(.semibold)) // Make link icon clearer
////            }
////        }
////        .padding(.vertical, 6)
////        .padding(.horizontal, 8)
////        .background(.quaternary.opacity(0.5)) // Subtle background
////        .clipShape(RoundedRectangle(cornerRadius: 8))
////        // Wrap with Link if URL exists
////        .if(paper.link != nil) { view in
////            Link(destination: paper.link!) { view }
////        }
////    }
//}
//
//// --- Standard Model Row ---
//struct StandardModelRow: View {
//    let model: DeepSeekModel
//
//    var body: some View {
//        HStack(spacing: 12) {
//             // Icon Logic (simple mapping for now)
//             Image(systemName: iconName(for: model.category))
//                 .foregroundColor(.accentColor) // Use accent color for consistency
//                 .frame(width: 20, height: 20) // Fixed small icon size
//
//             VStack(alignment: .leading, spacing: 3) {
//                 Text(model.id) // Display full ID
//                     .font(.subheadline.weight(.medium))
//                     .lineLimit(1)
//
//                 HStack(spacing: 8) {
//                     // Category Capsule
//                     Text(model.category)
//                         .font(.caption2)
//                         .foregroundColor(.primary.opacity(0.8))
//                         .padding(.horizontal, 6).padding(.vertical, 2)
//                         .background(Color.gray.opacity(0.15))
//                         .clipShape(Capsule())
//
//                     // Last Updated
//                     Text(model.lastUpdated)
//                         .font(.caption2)
//                         .foregroundColor(.secondary)
//
//                     Spacer() // Push metrics to the right if needed
//
//                     // Downloads
//                     if let downloads = model.downloads {
//                         Label(downloads, systemImage: "arrow.down.circle")
//                             .labelStyle(.titleAndIcon)
//                             .font(.caption2)
//                             .foregroundColor(.secondary)
//                     }
//                     // Likes
//                     if let likes = model.likes {
//                         Label(likes, systemImage: "heart") // Using heart for likes
//                              .labelStyle(.titleAndIcon)
//                             .font(.caption2)
//                             .foregroundColor(.secondary)
//                     }
//                 }
//             }
//            Spacer()
//        }
//        .padding(.vertical, 8) // Standard vertical padding
//        .contentShape(Rectangle())
//    }
//
//     // Helper for icon mapping
//     private func iconName(for category: String) -> String {
//         let lowerCategory = category.lowercased()
//         if lowerCategory.contains("text generation") { return "text.bubble.fill" }
//         if lowerCategory.contains("image") || lowerCategory.contains("vision") { return "photo.fill" }
//         if lowerCategory.contains("any-to-any") { return "arrow.triangle.2.circlepath.circle.fill" }
//         if lowerCategory.contains("code") { return "chevron.left.forwardslash.chevron.right" }
//         if lowerCategory.contains("math") { return "function" }
//         if lowerCategory.contains("moe") { return "square.grid.3x3.fill" }
//         if lowerCategory.contains("prover") { return "checkmark.shield.fill" }
//         return "cpu.fill" // Default
//     }
//}
//
//// --- Featured Model Row (Chat style) ---
//struct FeaturedModelRow: View {
//    let model: DeepSeekModel
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text(model.featureTitle ?? model.displayName) // Use special title or fallback
//                    .font(.headline)
//                Spacer()
//                if let metric = model.featureMetric {
//                     Text(metric)
//                         .font(.caption.weight(.semibold))
//                         .foregroundColor(.pink) // Use a highlight color
//                         .padding(.horizontal, 8)
//                         .padding(.vertical, 3)
//                         .background(Color.pink.opacity(0.15))
//                         .clipShape(Capsule())
//                }
//            }
//            if let description = model.featureDescription {
//                Text(description)
//                    .font(.footnote)
//                    .foregroundColor(.secondary)
//                    .lineLimit(2)
//            }
//        }
//        .padding()
//        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)) // Example gradient
//        //.background(.quinary) // Subtle distinct background
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//        .overlay(
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1) // Subtle border
//        )
//        .contentShape(Rectangle())
//    }
//}
//
//// MARK: - Main Content View
//
//struct DeepSeekModelsMasterView: View {
//    // --- State Variables ---
//    @State private var allModels: [DeepSeekModel] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String? = nil
//    @State private var groupedModels: [String: [DeepSeekModel]] = [:]
//    @State private var sectionOrder: [String] = [] // To maintain screenshot order
//
//    // --- API Service Instance ---
//    // Using Mock service directly for this implementation
//    private let apiService: DeepSeekAPIServiceProtocol = MockDeepSeekService()
//
//    var body: some View {
//        Text("DeepSeekModelsMasterView").padding()
//    }
//    
////    var body: some View {
////        NavigationStack {
////            ZStack {
////                if isLoading && allModels.isEmpty {
////                     ProgressView("Loading DeepSeek Models...")
////                         .frame(maxWidth: .infinity, maxHeight: .infinity)
////                        .background(.regularMaterial) // Use material background for loading
////                         .zIndex(1)
////                } else if let errorMessage = errorMessage, allModels.isEmpty {
////                    // Basic Error View (replace with sophisticated one if needed)
////                     VStack {
////                         Image(systemName: "exclamationmark.triangle.fill")
////                             .resizable().scaledToFit().frame(width: 50).foregroundColor(.red)
////                         Text("Error Loading Models").font(.headline).padding(.top)
////                         Text(errorMessage).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center).padding()
////                         Button("Retry") { attemptLoadModels() }.buttonStyle(.borderedProminent)
////                     }
////                     .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
////                     .background(.regularMaterial)
////                     .zIndex(1)
////                } else {
////                    // --- Main Scrollable List ---
////                    ScrollView {
////                         LazyVStack(alignment: .leading, spacing: 15, pinnedViews: []) { // Unpin headers for simpler layout
////                             ForEach(sectionOrder, id: \.self) { sectionTitle in
////                                 if let modelsInSection = groupedModels[sectionTitle], !modelsInSection.isEmpty {
////                                      // Find the first model to get section subtitle and paper info (if applicable)
////                                      let representativeModel = modelsInSection.first!
////
////                                     Section {
////                                          // NavigationLink to Section Detail (Placeholder)
////                                          NavigationLink { Text("Detail for \(sectionTitle)") } label: {
////                                              SectionHeader(
////                                                  title: sectionTitle,
////                                                  subtitle: representativeModel.sectionSubtitle
////                                              )
////                                          }
////                                          .buttonStyle(.plain) // Remove default button styling
////                                          .padding(.horizontal)
////
////                                          // Display Paper Info if present
////                                          if let paper = representativeModel.associatedPaper {
////                                               PaperInfoView(paper: paper)
////                                                    .padding(.horizontal)
////                                                Divider().padding(.top, 5) // Add divider after paper
////                                          }
////
////                                          // List models within the section
////                                          ForEach(modelsInSection.sorted(by: { $0.sortPriority < $1.sortPriority })) { model in
////                                               // NavigationLink for each model row
////                                               NavigationLink { Text("Detail for Model: \(model.displayName)") } label: {
////                                                   if model.isFeatured {
////                                                         FeaturedModelRow(model: model)
////                                                             .padding(.horizontal)
////                                                   } else {
////                                                       StandardModelRow(model: model)
////                                                              .padding(.horizontal)
////                                                            Divider().padding(.leading, 50) // Indented divider
////                                                   }
////                                              }
////                                              .buttonStyle(.plain) // Remove default button styling
////                                          }
////                                     } // End Section
////
////                                     // Add a thicker divider between major sections
////                                     if sectionTitle != sectionOrder.last {
////                                        Rectangle()
////                                            .fill(Color(.separator).opacity(0.5))
////                                            .frame(height: 6) // Thicker divider
////                                            .padding(.vertical, 10)
////                                    }
////                                 }
////                             }
////                         }
////                          .padding(.top) // Padding at the very top of the scroll view
////                    } // End ScrollView
////                    .background(Color(.systemGroupedBackground)) // Match typical grouped list background
////                }
////            } // End ZStack
////            .navigationTitle("DeepSeek Models")
////            .navigationBarTitleDisplayMode(.large) // Use large title for iOS
////            .toolbar {
////                 ToolbarItem(placement: .navigationBarTrailing) {
////                     if isLoading { ProgressView().controlSize(.small) }
////                     else {
////                         Button { attemptLoadModels() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
////                         .disabled(isLoading)
////                     }
////                 }
////             }
////            .task {
////                 if allModels.isEmpty { attemptLoadModels() }
////            }
////            .refreshable { await loadModelsAsync() } // Pull to refresh
////        } // End NavigationStack
////        .tint(.purple) // Apply a tint consistent with DeepSeek's theme (adjust as needed)
////    }
//
//    // --- Helper Functions for Loading & Grouping ---
//    private func attemptLoadModels() {
//         guard !isLoading else { return }
//         isLoading = true
//         Task { await loadModelsAsync() }
//    }
//
//    @MainActor
//    private func loadModelsAsync() async {
//         if !isLoading { isLoading = true } // Ensure flag is set if called from refreshable
//         print("🔄 Loading DeepSeek models using \(type(of: apiService))...")
//         do {
//             let fetchedModels = try await apiService.fetchModels()
//
//              // Group models and preserve order
//              let grouped = Dictionary(grouping: fetchedModels, by: { $0.sectionTitle })
//              let order = determineSectionOrder(from: fetchedModels) // Determine order based on mock data
//
//              self.allModels = fetchedModels
//              self.groupedModels = grouped
//              self.sectionOrder = order
//             self.errorMessage = nil
//             print("✅ Successfully loaded and grouped \(fetchedModels.count) models into \(grouped.keys.count) sections.")
//         } catch let error as LocalizedError {
//             print("❌ Error loading models: \(error.localizedDescription)")
//             self.errorMessage = error.localizedDescription
//             self.allModels = [] // Clear data on error
//              self.groupedModels = [:]
//              self.sectionOrder = []
//         } catch { // Catch non-localized errors
//             print("❌ Unexpected error loading models: \(error)")
//             self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
//             self.allModels = []
//              self.groupedModels = [:]
//              self.sectionOrder = []
//         }
//         isLoading = false
//    }
//
//    // Helper to maintain the visual order from screenshots
//    private func determineSectionOrder(from models: [DeepSeekModel]) -> [String] {
//         // Define the desired order based on visual inspection of screenshots
////         let desiredOrder = [
////            "DeepSeek-R1", "DeepSeek-VL2", "DeepSeek-Prover",
////            "DeepSeek-V3", "Janus", "DeepSeek-V2",
////            "DeepSeek-Coder-V2", "ESFT", "DeepSeek-Coder", "DeepSeek-MoE",
////            "DeepSeek-Math", "DeepSeek-VL", "DeepSeek-LLM", "DeepSeek-V2.5"
////         ]
//
//        let desiredOrder = [
//            "DeepSeek-R1", "DeepSeek-VL2", "DeepSeek-Prover"
//            ]
//         // Get unique section titles present in the fetched data, maintaining their first appearance order
//         var uniqueTitlesInOrder: [String] = []
//         var seenTitles = Set<String>()
//         for model in models {
//            if !seenTitles.contains(model.sectionTitle) {
//                 uniqueTitlesInOrder.append(model.sectionTitle)
//                 seenTitles.insert(model.sectionTitle)
//            }
//         }
//
//         // Sort the unique titles based on the desiredOrder array
//         uniqueTitlesInOrder.sort { first, second in
//             guard let firstIndex = desiredOrder.firstIndex(of: first),
//                   let secondIndex = desiredOrder.firstIndex(of: second) else {
//                  // Handle cases where a title might not be in desiredOrder (place at end or handle error)
//                  return false // Or some default sorting if needed
//             }
//             return firstIndex < secondIndex
//         }
//         return uniqueTitlesInOrder
//    }
//}
//
//// MARK: - Helper Extensions
//
//// Modifier for conditional view wrapping (e.g., for Link)
//extension View {
//    @ViewBuilder
//    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
//        if condition {
//            transform(self)
//        } else {
//            self
//        }
//    }
//}
//
//// MARK: - Previews
//
//#Preview("DeepSeek Models List") {
//    DeepSeekModelsMasterView()
//        // .preferredColorScheme(.dark) // Uncomment to preview in dark mode
//}
