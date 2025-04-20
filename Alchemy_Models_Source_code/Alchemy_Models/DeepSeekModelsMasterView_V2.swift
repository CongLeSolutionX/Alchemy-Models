////
////  DeepSeekModelsMasterView_V2.swift
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
////  Date: 4/20/25 (Based on screenshots, previous examples, and error fix)
////  Version: 1.1
////  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
////  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
////
//
//import SwiftUI
//import Foundation // Needed for URL?
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
//    let isFeatured: Bool = false
//    let featureTitle: String? = nil // e.g., "Chat with DeepseekVL2-small"
//    let featureMetric: String? = nil // e.g., "465 ❤️" or "1.95k 👍"
//    let featureDescription: String? = nil // e.g., "Generate responses using images and text input"
//
//    // For Paper links within sections
//    let associatedPaper: PaperInfo? = nil
//
//    // Helper to sort models within sections (optional)
//    var sortPriority: Int {
//        if isFeatured { return 0 }
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
//    // --- Define Paper Info constants for reuse ---
//    // (Moved outside generateMockModels for clarity, could also be static)
//    let v3Paper = PaperInfo(title: "DeepSeekV3 Technical Report", date: "Published Dec 26, 2024", link: URL(string:"https://arxiv.org/abs/2412.19437"), reads: "58")
//    let proverPaper = PaperInfo(title: "DeepSeek-ProverV1.5: Harnessing Proof...", date: "Updated Aug 29, 2024", link: nil, reads: nil) // Shortened title
//    let moePaper = PaperInfo(title: "DeepSeekMoE: Towards Ultimate Expert...", date: "Published Jan 11, 2024", link: URL(string:"https://arxiv.org/abs/2401.06066"), reads: "55") // Shortened title
//    let mathPaper = PaperInfo(title: "DeepSeekMath: Pushing the Limits...", date: "Updated Feb 5, 2024", link: nil, reads: nil) // Shortened title
//
//    // --- Generate Mock Models Based on Screenshots ---
//    private func generateMockModels() -> [DeepSeekModel] {
//        // Define subtitles directly where needed or pass them in if structure becomes complex
//        let deepseekR1Subtitle = "DeepSeek R1 series models."
//        let deepseekVL2Subtitle = "Vision-Language models."
//        let deepseekV3Subtitle = "DeepSeek V3 series."
//        let janusSubtitle = "Janus is a novel autoregressive framework..."
//        let deepseekV2Subtitle = "DeepSeek V2 series models."
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
//        // --- Removed unused local paper variables ---
//        // The paper info is now assigned directly in the model initializers below using the constants defined above the function.
//
//        return [
//            // --- DeepSeek-R1 Section ---
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "1.73M", likes: "12k", sectionTitle: "DeepSeek-R1", sectionSubtitle: deepseekR1Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Zero", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "5.7k", likes: "899", sectionTitle: "DeepSeek-R1", sectionSubtitle: deepseekR1Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Distill-Llama-70B", category: "Text Generation", lastUpdated: "Updated Feb 23", downloads: "269k", likes: "664", sectionTitle: "DeepSeek-R1", sectionSubtitle: deepseekR1Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: nil, likes: nil, sectionTitle: "DeepSeek-R1", sectionSubtitle: deepseekR1Subtitle),
//
//            // --- DeepSeek-VL2 Section ---
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-VL2-small-chat", category: "Image-Text Chat", lastUpdated: "N/A", downloads: nil, likes: nil, sectionTitle: "DeepSeek-VL2", sectionSubtitle: deepseekVL2Subtitle, isFeatured: true, featureTitle: "Chat with DeepseekVL2-small ✨", featureMetric: "465 ❤️", featureDescription: "Generate responses using images and text input"),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-VL2-small-chat", category: "Image-Text Chat", lastUpdated: "N/A", downloads: nil, likes: nil, sectionTitle: "DeepSeek-VL2", sectionSubtitle: deepseekVL2Subtitle),
//            
//            DeepSeekModel(id: "deepseek-ai/deepseek-vl2-tiny", category: "Image-Text-to-Text", lastUpdated: "Updated Dec 18, 2024", downloads: "92.9k", likes: "179", sectionTitle: "DeepSeek-VL2", sectionSubtitle: deepseekVL2Subtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-vl2-small", category: "Image-Text-to-Text", lastUpdated: "Updated Dec 18, 2024", downloads: "135k", likes: "155", sectionTitle: "DeepSeek-VL2", sectionSubtitle: deepseekVL2Subtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-vl2", category: "Vision Language", lastUpdated: "Updated Dec 18, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-VL2", sectionSubtitle: deepseekVL2Subtitle),
//
//             // --- DeepSeek-Prover Section ---
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Prover-V1.5-Base", category: "Text Generation", lastUpdated: "Updated Aug 29, 2024", downloads: "1.06k", likes: "13", sectionTitle: "DeepSeek-Prover", sectionSubtitle: deepseekProverSubtitle, associatedPaper: proverPaper),
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Prover-V1.5-SFT", category: "Text Generation", lastUpdated: "Updated Aug 29, 2024", downloads: "21.5k", likes: "10", sectionTitle: "DeepSeek-Prover", sectionSubtitle: deepseekProverSubtitle, associatedPaper: proverPaper),
////             DeepSeekModel(id: "deepseek-ai/DeepSeek-Prover-V1.5-RL", category: "Text Generation", lastUpdated: "Updated Aug 29, 2024", downloads: "3.62k", likes: "57", sectionTitle: "DeepSeek-Prover", sectionSubtitle: deepseekProverSubtitle, associatedPaper: proverPaper),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-Prover-V1.5-Base", category: "Text Generation", lastUpdated: "Updated Aug 29, 2024", downloads: "1.06k", likes: "13", sectionTitle: "DeepSeek-Prover", sectionSubtitle: deepseekProverSubtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-Prover-V1.5-SFT", category: "Text Generation", lastUpdated: "Updated Aug 29, 2024", downloads: "21.5k", likes: "10", sectionTitle: "DeepSeek-Prover", sectionSubtitle: deepseekProverSubtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-Prover-V1.5-RL", category: "Text Generation", lastUpdated: "Updated Aug 29, 2024", downloads: "3.62k", likes: "57", sectionTitle: "DeepSeek-Prover", sectionSubtitle: deepseekProverSubtitle),
//
//            // --- DeepSeek-V3 Section ---
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V3-Base", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "8.75k", likes: "1.63k", sectionTitle: "DeepSeek-V3", sectionSubtitle: deepseekV3Subtitle, associatedPaper: v3Paper),
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V3", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "749k", likes: "• 3.81k", sectionTitle: "DeepSeek-V3", sectionSubtitle: deepseekV3Subtitle, associatedPaper: v3Paper),
////            DeepSeekModel(id: "deepseek-ai/DeepSeek-V3-0324", category: "Text Generation", lastUpdated: "Updated Mar 24, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-V3", sectionSubtitle: deepseekV3Subtitle, associatedPaper: v3Paper),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-V3-Base", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "8.75k", likes: "1.63k", sectionTitle: "DeepSeek-V3", sectionSubtitle: deepseekV3Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-V3", category: "Text Generation", lastUpdated: "Updated 24 days ago", downloads: "749k", likes: "• 3.81k", sectionTitle: "DeepSeek-V3", sectionSubtitle: deepseekV3Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-V3-0324", category: "Text Generation", lastUpdated: "Updated Mar 24, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-V3", sectionSubtitle: deepseekV3Subtitle),
//
//            // --- Janus Section ---
////            DeepSeekModel(id: "deepseek-ai/Janus-Pro-7B-chat", category: "Any-to-Any Chat", lastUpdated: "N/A", downloads: nil, likes: nil, sectionTitle: "Janus", sectionSubtitle: janusSubtitle, isFeatured: true, featureTitle: "Chat With Janus-Pro 7B ✨", featureMetric: "1.95k 👍", featureDescription: "A unified multimodal understanding and generation model."),
//            DeepSeekModel(id: "deepseek-ai/Janus-Pro-7B-chat", category: "Any-to-Any Chat", lastUpdated: "N/A", downloads: nil, likes: nil, sectionTitle: "Janus", sectionSubtitle: janusSubtitle),
//            DeepSeekModel(id: "deepseek-ai/Janus-Pro-7B", category: "Any-to-Any", lastUpdated: "Updated Feb 1", downloads: "239k", likes: "3.34k", sectionTitle: "Janus", sectionSubtitle: janusSubtitle),
//            DeepSeekModel(id: "deepseek-ai/Janus-Pro-1B", category: "Any-to-Any", lastUpdated: "Updated Feb 1", downloads: "33.1k", likes: "428", sectionTitle: "Janus", sectionSubtitle: janusSubtitle),
//            DeepSeekModel(id: "deepseek-ai/Janus-1.3B", category: "Any-to-Any", lastUpdated: "Updated Jul 18, 2024", downloads: nil, likes: nil, sectionTitle: "Janus", sectionSubtitle: janusSubtitle),
//
//            // --- DeepSeek-V2 Section ---
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2-Chat-0628", category: "Text Generation", lastUpdated: "Updated Jun 28, 2024", downloads: "185", likes: "175", sectionTitle: "DeepSeek-V2", sectionSubtitle: deepseekV2Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2-Chat", category: "Text Generation", lastUpdated: "Updated Jun 8, 2024", downloads: "1.37k", likes: "460", sectionTitle: "DeepSeek-V2", sectionSubtitle: deepseekV2Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2", category: "Text Generation", lastUpdated: "Updated Jun 8, 2024", downloads: "124k", likes: "316", sectionTitle: "DeepSeek-V2", sectionSubtitle: deepseekV2Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2-Lite", category: "Text Generation", lastUpdated: "Updated Jun 8, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-V2", sectionSubtitle: deepseekV2Subtitle),
//
//             // --- DeepSeek-Coder-V2 Section ---
//             DeepSeekModel(id: "deepseek-ai/DeepSeek-Coder-V2-Instruct", category: "Text Generation", lastUpdated: "Updated Aug 20, 2024", downloads: "19.2k", likes: "613", sectionTitle: "DeepSeek-Coder-V2", sectionSubtitle: deepseekCoderV2Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-Coder-V2-Base", category: "Text Generation", lastUpdated: "Updated Jul 2, 2024", downloads: "230", likes: "68", sectionTitle: "DeepSeek-Coder-V2", sectionSubtitle: deepseekCoderV2Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-Coder-V2-Lite-Base", category: "Text Generation", lastUpdated: "Updated Jul 2, 2024", downloads: "9.67k", likes: "80", sectionTitle: "DeepSeek-Coder-V2", sectionSubtitle: deepseekCoderV2Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-Coder-V2-Lite-Instruct", category: "Text Generation", lastUpdated: "Updated Jul 2, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-Coder-V2", sectionSubtitle: deepseekCoderV2Subtitle),
//
//             // --- ESFT Section ---
//             DeepSeekModel(id: "deepseek-ai/ESFT-vanilla-lite", category: "Text Generation", lastUpdated: "Updated Jul 22, 2024", downloads: "1.13k", likes: "11", sectionTitle: "ESFT", sectionSubtitle: esftSubtitle),
//            DeepSeekModel(id: "deepseek-ai/ESFT-token-1aw-lite", category: "Text Generation", lastUpdated: "Updated Jul 4, 2024", downloads: "99", likes: "4", sectionTitle: "ESFT", sectionSubtitle: esftSubtitle),
//            DeepSeekModel(id: "deepseek-ai/ESFT-token-summary-lite", category: "Text Generation", lastUpdated: "Updated Jul 4, 2024", downloads: "61", likes: "3", sectionTitle: "ESFT", sectionSubtitle: esftSubtitle),
//            DeepSeekModel(id: "deepseek-ai/ESFT-token-code-lite", category: "Text Generation", lastUpdated: "Updated Jul 4, 2024", downloads: nil, likes: nil, sectionTitle: "ESFT", sectionSubtitle: esftSubtitle),
//
//             // --- DeepSeek-Coder Section ---
//             DeepSeekModel(id: "deepseek-ai/deepseek-coder-33b-instruct", category: "Text Generation", lastUpdated: "Updated Mar 7, 2024", downloads: "8.33k", likes: "507", sectionTitle: "DeepSeek-Coder", sectionSubtitle: deepseekCoderSubtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-coder-6.7b-instruct", category: "Text Generation", lastUpdated: "Updated Feb 1, 2024", downloads: "46.8k", likes: "399", sectionTitle: "DeepSeek-Coder", sectionSubtitle: deepseekCoderSubtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-coder-7b-instruct-v1.5", category: "Text Generation", lastUpdated: "Updated Feb 4, 2024", downloads: "5.44k", likes: "133", sectionTitle: "DeepSeek-Coder", sectionSubtitle: deepseekCoderSubtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-coder-1.3b-instruct", category: "Text Generation", lastUpdated: "Updated Feb 4, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-Coder", sectionSubtitle: deepseekCoderSubtitle),
//
//             // --- DeepSeek-MoE Section ---
////             DeepSeekModel(id: "deepseek-ai/deepseek-moe-16b-base", category: "Text Generation", lastUpdated: "Updated Jan 11, 2024", downloads: "12.4k", likes: "114", sectionTitle: "DeepSeek-MoE", sectionSubtitle: deepseekMoESubtitle, associatedPaper: moePaper),
////            DeepSeekModel(id: "deepseek-ai/deepseek-moe-16b-chat", category: "Text Generation", lastUpdated: "Updated Feb 5, 2024", downloads: "33.5k", likes: "136", sectionTitle: "DeepSeek-MoE", sectionSubtitle: deepseekMoESubtitle, associatedPaper: moePaper),
//            DeepSeekModel(id: "deepseek-ai/deepseek-moe-16b-base", category: "Text Generation", lastUpdated: "Updated Jan 11, 2024", downloads: "12.4k", likes: "114", sectionTitle: "DeepSeek-MoE", sectionSubtitle: deepseekMoESubtitle),
//           DeepSeekModel(id: "deepseek-ai/deepseek-moe-16b-chat", category: "Text Generation", lastUpdated: "Updated Feb 5, 2024", downloads: "33.5k", likes: "136", sectionTitle: "DeepSeek-MoE", sectionSubtitle: deepseekMoESubtitle),
//
//             // --- DeepSeek-Math Section ---
////             DeepSeekModel(id: "deepseek-ai/deepseek-math-7b-instruct", category: "Text Generation", lastUpdated: "Updated Feb 6, 2024", downloads: "59.3k", likes: "123", sectionTitle: "DeepSeek-Math", sectionSubtitle: deepseekMathSubtitle, associatedPaper: mathPaper),
////            DeepSeekModel(id: "deepseek-ai/deepseek-math-7b-rl", category: "Text Generation", lastUpdated: "Updated Mar 18, 2024", downloads: "1.6k", likes: "81", sectionTitle: "DeepSeek-Math", sectionSubtitle: deepseekMathSubtitle, associatedPaper: mathPaper),
////            DeepSeekModel(id: "deepseek-ai/deepseek-math-7b-base", category: "Text Generation", lastUpdated: "Updated Feb 6, 2024", downloads: "8.83k", likes: "69", sectionTitle: "DeepSeek-Math", sectionSubtitle: deepseekMathSubtitle, associatedPaper: mathPaper),
//            DeepSeekModel(id: "deepseek-ai/deepseek-math-7b-instruct", category: "Text Generation", lastUpdated: "Updated Feb 6, 2024", downloads: "59.3k", likes: "123", sectionTitle: "DeepSeek-Math", sectionSubtitle: deepseekMathSubtitle),
//           DeepSeekModel(id: "deepseek-ai/deepseek-math-7b-rl", category: "Text Generation", lastUpdated: "Updated Mar 18, 2024", downloads: "1.6k", likes: "81", sectionTitle: "DeepSeek-Math", sectionSubtitle: deepseekMathSubtitle),
//           DeepSeekModel(id: "deepseek-ai/deepseek-math-7b-base", category: "Text Generation", lastUpdated: "Updated Feb 6, 2024", downloads: "8.83k", likes: "69", sectionTitle: "DeepSeek-Math", sectionSubtitle: deepseekMathSubtitle),
//
//             // --- DeepSeek-VL Section ---
//             DeepSeekModel(id: "deepseek-ai/deepseek-vl-7b-chat", category: "Image-Text-to-Text", lastUpdated: "Updated Mar 15, 2024", downloads: "17.1k", likes: "253", sectionTitle: "DeepSeek-VL", sectionSubtitle: deepseekVLSubtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-vl-1.3b-base", category: "Image-Text-to-Text", lastUpdated: "Updated Mar 15, 2024", downloads: "2.12k", likes: "52", sectionTitle: "DeepSeek-VL", sectionSubtitle: deepseekVLSubtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-vl-7b-base", category: "Image-Text-to-Text", lastUpdated: "Updated Mar 15, 2024", downloads: "1.33k", likes: "38", sectionTitle: "DeepSeek-VL", sectionSubtitle: deepseekVLSubtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-vl-1.3b-chat", category: "Image-Text-to-Text", lastUpdated: "Updated Mar 15, 2024", downloads: nil, likes: nil, sectionTitle: "DeepSeek-VL", sectionSubtitle: deepseekVLSubtitle),
//
//             // --- DeepSeek-LLM Section ---
//             DeepSeekModel(id: "deepseek-ai/deepseek-llm-67b-chat", category: "Text Generation", lastUpdated: "Updated Nov 29, 2023", downloads: "4.17k", likes: "200", sectionTitle: "DeepSeek-LLM", sectionSubtitle: deepseekLLMSubtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-llm-7b-chat", category: "Text Generation", lastUpdated: "Updated Nov 29, 2023", downloads: "157k", likes: "165", sectionTitle: "DeepSeek-LLM", sectionSubtitle: deepseekLLMSubtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-llm-67b-base", category: "Text Generation", lastUpdated: "Updated Nov 29, 2023", downloads: "1.7k", likes: "121", sectionTitle: "DeepSeek-LLM", sectionSubtitle: deepseekLLMSubtitle),
//            DeepSeekModel(id: "deepseek-ai/deepseek-llm-7b-base", category: "Text Generation", lastUpdated: "Updated Nov 29, 2023", downloads: nil, likes: nil, sectionTitle: "DeepSeek-LLM", sectionSubtitle: deepseekLLMSubtitle),
//
//            // --- DeepSeek-V2.5 Section ---
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2.5", category: "Text Generation", lastUpdated: "Updated Dec 11, 2024", downloads: "1.99k", likes: "704", sectionTitle: "DeepSeek-V2.5", sectionSubtitle: deepseekV25Subtitle),
//            DeepSeekModel(id: "deepseek-ai/DeepSeek-V2.5-1210", category: "Text Generation", lastUpdated: "Updated Dec 11, 2024", downloads: "673", likes: "253", sectionTitle: "DeepSeek-V2.5", sectionSubtitle: deepseekV25Subtitle),
//        ]
//    }
//
//    func fetchModels() async throws -> [DeepSeekModel] {
//        try? await Task.sleep(for: .seconds(mockNetworkDelaySeconds))
//        return generateMockModels()
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
//                        .lineLimit(2)
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
//        .contentShape(Rectangle())
//    }
//}
//
//// --- Paper Info View ---
//struct PaperInfoView: View {
//    let paper: PaperInfo
//
//    var body: some View {
//        HStack(spacing: 10) {
//            Image(systemName: "doc.text.fill")
//                .foregroundColor(.secondary)
//                .font(.callout)
//            VStack(alignment: .leading, spacing: 2) {
//                Text(paper.title)
//                    .font(.footnote.weight(.medium))
//                    .lineLimit(1)
//                HStack(spacing: 6) {
//                    Text("Paper")
//                        .font(.caption2)
//                        .padding(.horizontal, 5).padding(.vertical, 2)
//                        .background(Color.gray.opacity(0.2))
//                        .clipShape(Capsule())
//
//                    Text(paper.date)
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//
//                    if let reads = paper.reads, !reads.isEmpty { // Check if reads is not empty
//                         Text("• \(reads) reads")
//                            .font(.caption2)
//                            .foregroundColor(.secondary)
//                    }
//                }
//            }
//            Spacer()
//            if paper.link != nil {
//                 Image(systemName: "arrow.up.right.square")
//                     .foregroundColor(.blue)
//                     .font(.caption.weight(.bold)) // Make link icon bolder
//            }
//        }
//        .padding(.vertical, 6)
//        .padding(.horizontal, 8)
//        .background(.quaternary.opacity(0.5))
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//        // Wrap with Link if URL exists
//        .if(paper.link != nil) { view in
//            Link(destination: paper.link!) { view }
//        }
//    }
//}
//
//// --- Standard Model Row ---
//struct StandardModelRow: View {
//    let model: DeepSeekModel
//
//    var body: some View {
//        HStack(spacing: 12) {
//             Image(systemName: iconName(for: model.category))
//                 .foregroundColor(.accentColor.opacity(0.8)) // Slightly muted icon
//                 .frame(width: 20, alignment: .center) // Ensure icon alignment
//
//             VStack(alignment: .leading, spacing: 3) {
//                 Text(model.id) // Display full ID
//                     .font(.footnote.weight(.medium)) // Slightly smaller font
//                     .lineLimit(1)
//
//                 HStack(spacing: 8) {
//                     Text(model.category) // Use capsule for category
//                           .font(.caption2.weight(.medium))
//                           .foregroundColor(.primary.opacity(0.8))
//                           .padding(.horizontal, 6).padding(.vertical, 2)
//                           .background(Color.gray.opacity(0.15))
//                           .clipShape(Capsule())
//
//                     Text(model.lastUpdated)
//                         .font(.caption2)
//                         .foregroundColor(.secondary)
//                         .lineLimit(1)
//
//                     Spacer() // Push metrics to the right forcefully
//
//                    HStack(spacing: 6) { // Group metrics
//                        if let downloads = model.downloads, !downloads.isEmpty {
//                            Label(downloads, systemImage: "arrow.down.circle")
//                                .labelStyle(.titleAndIcon)
//                                .font(.caption2)
//                                .foregroundColor(.secondary)
//                        }
//                        if let likes = model.likes, !likes.isEmpty {
//                            Label(likes.replacingOccurrences(of: "• ", with: ""), systemImage: "heart") // Clean up likes string
//                                .labelStyle(.titleAndIcon)
//                                .font(.caption2)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                 }
//             }
//             Spacer(minLength: 0) // Allow spacer to have zero minimal length
//        }
//        .padding(.vertical, 6) // Reduced vertical padding
//        .contentShape(Rectangle())
//    }
//
//     private func iconName(for category: String) -> String {
//         let lowerCategory = category.lowercased()
//         if lowerCategory.contains("text generation") { return "text.bubble.fill" }
//         if lowerCategory.contains("image") || lowerCategory.contains("vision") || lowerCategory.contains("-vl") { return "photo.on.rectangle.angled" }
//         if lowerCategory.contains("any-to-any") { return "arrow.triangle.2.circlepath.circle.fill" }
//         if lowerCategory.contains("code") { return "chevron.left.forwardslash.chevron.right" }
//         if lowerCategory.contains("math") { return "function" }
//         if lowerCategory.contains("moe") { return "square.grid.3x3.fill" }
//         if lowerCategory.contains("prover") || lowerCategory.contains("rl") { return "checkmark.shield.fill" } // Added RL mapping
//          if lowerCategory.contains("esft") { return "paperplane.fill" } // Example for ESFT
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
//                Text(model.featureTitle ?? model.displayName)
//                    .font(.subheadline.weight(.semibold)) // Slightly smaller featured title
//                Spacer()
//                if let metric = model.featureMetric {
//                     // Normalize metric display (remove extra chars, use consistent icon)
//                     let (value, icon) = normalizeMetric(metric)
//                     Label(value, systemImage: icon ?? "star.fill")
//                        .labelStyle(.titleAndIcon)
//                        .font(.caption.weight(.semibold))
//                         .foregroundColor(.pink)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 3)
//                        .background(Color.pink.opacity(0.15))
//                        .clipShape(Capsule())
//                }
//            }
//            if let description = model.featureDescription {
//                Text(description)
//                    .font(.caption) // Slightly smaller description
//                    .foregroundColor(.secondary)
//                    .lineLimit(2)
//            }
//        }
//        .padding(12) // Slightly smaller padding
//        .background(
//             LinearGradient(
//                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.15)]), // Subtle gradient
//                 startPoint: .topLeading,
//                 endPoint: .bottomTrailing
//             )
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 10)) // Slightly smaller corner radius
//        .overlay(
//            RoundedRectangle(cornerRadius: 10)
//                .stroke(Color.purple.opacity(0.3), lineWidth: 0.5) // More subtle border
//        )
//        .contentShape(Rectangle())
//    }
//
//     // Helper to normalize metrics like "465 ❤️" or "1.95k 👍"
//     private func normalizeMetric(_ metric: String) -> (value: String, icon: String?) {
//         var value = metric
//         var icon: String? = nil
//
//         if metric.contains("❤️") {
//             value = metric.replacingOccurrences(of: " ❤️", with: "")
//             icon = "heart.fill"
//         } else if metric.contains("👍") {
//             value = metric.replacingOccurrences(of: " 👍", with: "")
//             icon = "hand.thumbsup.fill"
//         }
//         // Add more rules if needed
//         return (value.trimmingCharacters(in: .whitespacesAndNewlines), icon)
//     }
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
//    @State private var sectionOrder: [String] = []
//
//    // --- API Service ---
//    private let apiService: DeepSeekAPIServiceProtocol = MockDeepSeekService()
//
//    // --- Static constant for desired order (Fixes Compiler Error) ---
//    static let desiredSectionOrder: [String] = [
//        "DeepSeek-R1", "DeepSeek-VL2", "DeepSeek-Prover",
//        "DeepSeek-V3", "Janus", "DeepSeek-V2",
//        "DeepSeek-Coder-V2", "ESFT", "DeepSeek-Coder", "DeepSeek-MoE",
//        "DeepSeek-Math", "DeepSeek-VL", "DeepSeek-LLM", "DeepSeek-V2.5"
//    ]
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                if isLoading && allModels.isEmpty {
//                     ProgressView("Loading DeepSeek Models...").frame(maxWidth: .infinity, maxHeight: .infinity).background(.regularMaterial).zIndex(1)
//                } else if let errorMessage = errorMessage, allModels.isEmpty {
//                     VStack { // Simple Error View
//                         Image(systemName: "exclamationmark.triangle.fill").resizable().scaledToFit().frame(width: 50).foregroundColor(.red)
//                         Text("Error Loading Models").font(.headline).padding(.top)
//                         Text(errorMessage).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center).padding()
//                         Button("Retry") { attemptLoadModels() }.buttonStyle(.borderedProminent)
//                     }.padding().frame(maxWidth: .infinity, maxHeight: .infinity).background(.regularMaterial).zIndex(1)
//                } else {
//                    ScrollView {
//                         LazyVStack(alignment: .leading, spacing: 0) { // Reduced spacing
//                             ForEach(sectionOrder, id: \.self) { sectionTitle in
//                                 if let modelsInSection = groupedModels[sectionTitle], !modelsInSection.isEmpty {
//                                      let representativeModel = modelsInSection.first!
//
//                                     // Section Container with background and padding removed (applied inside)
//                                     VStack(alignment: .leading, spacing: 0) { // No spacing here
//                                          NavigationLink { Text("Detail for \(sectionTitle)") } label: {
//                                              SectionHeader(title: sectionTitle, subtitle: representativeModel.sectionSubtitle)
//                                          }
//                                          .buttonStyle(.plain).padding([.horizontal, .top]) // Add padding here
//
//                                          if let paper = representativeModel.associatedPaper {
//                                               PaperInfoView(paper: paper).padding(.horizontal)
//                                                Divider().padding(.top, 8) // Add divider after paper
//                                          }
//
//                                          ForEach(modelsInSection.sorted(by: { $0.sortPriority < $1.sortPriority })) { model in
//                                               NavigationLink { Text("Detail for Model: \(model.displayName)") } label: {
//                                                   if model.isFeatured {
//                                                         FeaturedModelRow(model: model).padding([.horizontal, .top]) // Padding for featured row
//                                                   } else {
//                                                       VStack(spacing: 0) { // Group row and divider
//                                                          StandardModelRow(model: model)
//                                                               .padding(.horizontal) // Padding for standard row
//                                                               .padding(.vertical, 4) // Extra vertical padding for spacing
//                                                          Divider().padding(.leading, 30) // Indented divider
//                                                      }
//                                                   }
//                                              }
//                                              .buttonStyle(.plain)
//                                          }
//                                     }
//                                     .padding(.bottom, 15) // Space below the entire section content
//
//                                     // Add thick divider between groups if not the last one
//                                     if sectionTitle != sectionOrder.last {
//                                        Rectangle()
//                                            .fill(Color(.separator).opacity(0.6))
//                                            .frame(height: 5)
//                                            .padding(.vertical, 5) // Space around the thick divider
//                                    }
//                                 }
//                             }
//                         }
//                    }
//                    .background(Color(.systemGroupedBackground))
//                    .contentMargins(.top, 0, for: .scrollContent) // Remove top margin if needed
//                }
//            }
//            .navigationTitle("DeepSeek Models")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                 ToolbarItem(placement: .navigationBarTrailing) {
//                    Button { attemptLoadModels() } label: {
//                         Label("Refresh", systemImage: "arrow.clockwise")
//                     }
//                     .disabled(isLoading)
//                     .overlay { if isLoading { ProgressView().controlSize(.small) } } // Show progress over button
//                 }
//             }
//            .task { if allModels.isEmpty { attemptLoadModels() } }
//            .refreshable { await loadModelsAsync() }
//        }
//        .tint(.purple) // Global tint
//    }
//
//    // --- Helper Functions ---
//    private func attemptLoadModels() {
//         guard !isLoading else { return }
//         isLoading = true
//         Task { await loadModelsAsync() }
//    }
//
//    @MainActor
//    private func loadModelsAsync() async {
//         if !isLoading { isLoading = true }
//         print("🔄 Loading DeepSeek models using \(type(of: apiService))...")
//         do {
//             let fetchedModels = try await apiService.fetchModels()
//              let grouped = Dictionary(grouping: fetchedModels, by: { $0.sectionTitle })
//              let order = determineSectionOrder(from: fetchedModels)
//
//              self.allModels = fetchedModels
//              self.groupedModels = grouped
//              self.sectionOrder = order
//             self.errorMessage = nil
//             print("✅ Successfully loaded \(fetchedModels.count) models into \(grouped.keys.count) sections.")
//         } catch { // Catch all errors
//             let localizedError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
//             print("❌ Error loading models: \(localizedError)")
//             self.errorMessage = localizedError
//             self.allModels = []; self.groupedModels = [:]; self.sectionOrder = []
//         }
//         isLoading = false
//    }
//
//    private func determineSectionOrder(from models: [DeepSeekModel]) -> [String] {
//        // Use the static desired order defined above the struct
//        let desiredOrder = Self.desiredSectionOrder
//
//        var uniqueTitlesInOrder: [String] = []
//        var seenTitles = Set<String>()
//        for model in models {
//           if !seenTitles.contains(model.sectionTitle) {
//                uniqueTitlesInOrder.append(model.sectionTitle)
//                seenTitles.insert(model.sectionTitle)
//           }
//        }
//
//        // Sort based on the desiredOrder constant
//        uniqueTitlesInOrder.sort { first, second in
//            guard let firstIndex = desiredOrder.firstIndex(of: first),
//                  let secondIndex = desiredOrder.firstIndex(of: second) else {
//                 print("⚠️ Warning: Section title '\(first)' or '\(second)' not found in desiredOrder. Placing at end.")
//                 return desiredOrder.firstIndex(of: second) == nil // Place unknown sections at the end
//            }
//            return firstIndex < secondIndex
//        }
//        return uniqueTitlesInOrder
//    }
//}
//
//// MARK: - Helper Extensions
//
//extension View {
//    @ViewBuilder
//    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
//        if condition { transform(self) } else { self }
//    }
//}
//
//// MARK: - Previews
//
//#Preview("DeepSeek Models List") {
//    DeepSeekModelsMasterView()
//        // .preferredColorScheme(.dark)
//}
