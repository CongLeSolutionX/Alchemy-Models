//
//  O1ModelDetailView_Preview.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  OpenAI_O1_Model.swift
//  Alchemy_Models_Combined
//  (Single File Representation for o1 Model)
//
//  Created: Cong Le
//  Date: 4/13/25 (Based on screenshots provided 2025-04-13)
//  Version: 1.0 (o1 Specific)
//  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
//  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
//
//  Disclaimer: This file synthesizes information from the provided screenshots
//  for the 'o1' model into a Swift structure. It includes nested structures
//  and enums to represent the detailed specifications. Default values or assumptions
//  are made where information is not explicitly stated (e.g., 'object' type).
//

import SwiftUI
import Foundation

// MARK: - Core Data Model for OpenAI Model

struct OpenAIModel: Codable, Identifiable, Hashable {
    let id: String // e.g., "o1"
    let object: String // Typically "model"
    let created: Int // Unix timestamp (Using knowledge cutoff as proxy: Sep 30, 2023)
    let ownedBy: String // e.g., "openai"

    // --- Basic Info ---
    var displayName: String // User-friendly name, e.g., "o1"
    var shortDescription: String // e.g., "Previous full o-series reasoning model"
    var longDescription: String // Detailed explanation from screenshot

    // --- Performance / Capabilities ---
    var reasoningScore: Int // 1-4 scale (based on bulbs)
    var speedScore: Int // 1-4 scale (based on bolts)
    var contextWindow: Int // e.g., 200000
    var maxOutputTokens: Int // e.g., 100000
    var knowledgeCutoff: String // e.g., "Sep 30, 2023"
    var supportsReasoningTokens: Bool

    // --- Pricing ---
    var pricing: ModelPricing

    // --- Modalities ---
    var modalities: ModalityDetails

    // --- Endpoints Support ---
    var endpoints: EndpointSupport

    // --- Features ---
    var features: FeatureSupport

    // --- Snapshots ---
    var snapshots: [ModelSnapshot]

    // --- Rate Limits ---
    var rateLimits: RateLimitInfo

    // --- Codable Conformance (Example - Adapt if JSON structure is different) ---
    enum CodingKeys: String, CodingKey {
        case id, object, created, ownedBy = "owned_by" // Standard keys
        // Add custom keys if JSON differs significantly or flatten nested structs
        // For direct instantiation, CodingKeys might not be strictly necessary unless parsing
         case displayName, shortDescription, longDescription, reasoningScore, speedScore
         case contextWindow, maxOutputTokens, knowledgeCutoff, supportsReasoningTokens
         case pricing, modalities, endpoints, features, snapshots, rateLimits
    }

    // --- Computed Properties & Hashable ---
    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: OpenAIModel, rhs: OpenAIModel) -> Bool { lhs.id == rhs.id }
}

// MARK: - Nested Structures for Detailed Specifications

struct ModelPricing: Codable, Hashable {
    struct PricePerMillionTokens: Codable, Hashable {
        let input: Double
        let cachedInput: Double? // Optional as not always present
        let output: Double
    }
    let textTokens: PricePerMillionTokens
    let batchAPIFeeNote: String? // Note about tool-specific fees
    // Add image pricing if applicable and detailed
}

struct ModalityDetails: Codable, Hashable {
    struct ModalitySupport: Codable, Hashable {
        let supported: Bool
        let input: Bool
        let output: Bool
         let note: String? // e.g., "Input only", "Not supported"
    }
    let text: ModalitySupport
    let image: ModalitySupport
    let audio: ModalitySupport
}

struct EndpointSupport: Codable, Hashable {
    struct EndpointFeatureSupport: Codable, Hashable {
        let path: String
        let supported: Bool
        let realtime: Bool?
        let batch: Bool?
        let embeddings: Bool?
        let speechGeneration: Bool?
        let translation: Bool?
        let completionsLegacy: Bool?
        let assistants: Bool?
        let fineTuning: Bool?
        let imageGeneration: Bool?
        let transcription: Bool?
        let moderation: Bool?
         let note: String? // General notes if needed
    }
    let chatCompletions: EndpointFeatureSupport
    let responses: EndpointFeatureSupport // Assuming '/v1/responses' covers Assistants etc.
    // Add other distinct endpoints if necessary
}

struct FeatureSupport: Codable, Hashable {
    let streaming: Bool
    let functionCalling: Bool
    let structuredOutputs: Bool
    let fineTuning: Bool // Note: This seems contradictory to endpoint info, check source
    let distillation: Bool
    let predictedOutputs: Bool
}

struct ModelSnapshot: Codable, Hashable, Identifiable {
    var id: String { alias } // Use alias as ID
    let alias: String // e.g., "o1", "o1-preview"
    let versionDate: String // e.g., "2024-12-17"
     let isDefault: Bool
}

struct RateLimitInfo: Codable, Hashable {
    struct TierLimit: Codable, Hashable {
        let tierName: String // e.g., "Free", "Tier 1"
        let supported: Bool
        let rpm: Int? // Requests Per Minute
        let rpd: Int? // Requests Per Day (Seems missing for o1)
        let tpm: Int? // Tokens Per Minute
        let batchQueueLimit: Int?
    }
    let free: TierLimit
    let tier1: TierLimit
    let tier2: TierLimit
    let tier3: TierLimit
}

// MARK: - Instance Definition for 'o1' Model

let o1ModelData = OpenAIModel(
    id: "o1",
    object: "model",
    created: 1696032000, // Approx. Sep 30, 2023
    ownedBy: "openai",

    displayName: "o1",
    shortDescription: "Previous full o-series reasoning model",
    longDescription: "The o1 series of models are trained with reinforcement learning to perform complex reasoning. o1 models think before they answer, producing a long internal chain of thought before responding to the user.",

    reasoningScore: 3, // Based on icon
    speedScore: 1, // Based on icon
    contextWindow: 200_000,
    maxOutputTokens: 100_000,
    knowledgeCutoff: "Sep 30, 2023",
    supportsReasoningTokens: true,

    pricing: ModelPricing(
        textTokens: ModelPricing.PricePerMillionTokens(
            input: 15.00,
            cachedInput: 7.50,
            output: 60.00
        ),
        batchAPIFeeNote: "Pricing is based on the number of tokens used. For tool-specific models, like search and computer use, there's a fee per tool call. See details in the pricing page."
    ),

    modalities: ModalityDetails(
        text: ModalityDetails.ModalitySupport(supported: true, input: true, output: true, note: "Input and output"),
        image: ModalityDetails.ModalitySupport(supported: true, input: true, output: false, note: "Input only"),
        audio: ModalityDetails.ModalitySupport(supported: false, input: false, output: false, note: "Not supported")
    ),

    endpoints: EndpointSupport(
        chatCompletions: EndpointSupport.EndpointFeatureSupport(
            path: "/v1/chat/completions",
            supported: true,
            realtime: false,
            batch: false, // Explicitly "Not supported" for Batch endpoint
            embeddings: false,
            speechGeneration: false,
            translation: false,
            completionsLegacy: false,
            assistants: nil, // N/A for this endpoint path
            fineTuning: nil, // N/A
            imageGeneration: nil, // N/A
            transcription: nil, // N/A
            moderation: nil,
            note: nil // N/A
        ),
        responses: EndpointSupport.EndpointFeatureSupport(
             path: "/v1/responses", // Path assumed for grouping Assistants etc.
            supported: true, // Supported via Assistants
            realtime: nil, // N/A
            batch: nil, // N/A
            embeddings: nil, // N/A
            speechGeneration: nil, // N/A
            translation: nil, // N/A
            completionsLegacy: nil, // N/A
            assistants: true, // Explicitly supported
            fineTuning: false,
            imageGeneration: false,
            transcription: false,
             moderation: false,
             note: nil
        )
    ),

    features: FeatureSupport(
        streaming: true,
        functionCalling: true,
        structuredOutputs: true,
        fineTuning: false, // Feature itself not supported
        distillation: false,
        predictedOutputs: false
    ),

    snapshots: [
        ModelSnapshot(alias: "o1", versionDate: "2024-12-17", isDefault: true),
        ModelSnapshot(alias: "o1-preview", versionDate: "2024-09-12", isDefault: false)
    ],

    rateLimits: RateLimitInfo(
        free: RateLimitInfo.TierLimit(tierName: "Free", supported: false, rpm: nil, rpd: nil, tpm: nil, batchQueueLimit: nil),
        tier1: RateLimitInfo.TierLimit(tierName: "Tier 1", supported: true, rpm: 500, rpd: nil, tpm: 30_000, batchQueueLimit: 90_000),
        tier2: RateLimitInfo.TierLimit(tierName: "Tier 2", supported: true, rpm: 5_000, rpd: nil, tpm: 450_000, batchQueueLimit: 1_350_000),
        tier3: RateLimitInfo.TierLimit(tierName: "Tier 3", supported: true, rpm: 5_000, rpd: nil, tpm: 1_350_000, batchQueueLimit: 50_000_000)
    )
)

// MARK: - Example Usage (SwiftUI Preview)

struct O1ModelDetailView_Preview: View {
    let model = o1ModelData

    var body: some View {
        // Example: Displaying some details in a SwiftUI List
        List {
            Section("Overview") {
                TextPair(label: "ID", value: model.id)
                TextPair(label: "Description", value: model.shortDescription)
                TextPair(label: "Knowledge Cutoff", value: model.knowledgeCutoff)
                TextPair(label: "Context Window", value: "\(model.contextWindow / 1000)k tokens")
            }

            Section("Pricing (Text Tokens / 1M)") {
                 TextPair(label: "Input", value: String(format: "$%.2f", model.pricing.textTokens.input))
                 if let cached = model.pricing.textTokens.cachedInput {
                     TextPair(label: "Cached Input", value: String(format: "$%.2f", cached))
                 }
                 TextPair(label: "Output", value: String(format: "$%.2f", model.pricing.textTokens.output))
            }

            Section("Modalities") {
                ModalityRow(modality: "Text", support: model.modalities.text)
                ModalityRow(modality: "Image", support: model.modalities.image)
                ModalityRow(modality: "Audio", support: model.modalities.audio)
            }

            Section("Features") {
                FeatureRow(label: "Streaming", supported: model.features.streaming)
                FeatureRow(label: "Function Calling", supported: model.features.functionCalling)
                FeatureRow(label: "Structured Outputs", supported: model.features.structuredOutputs)
                 FeatureRow(label: "Fine-tuning", supported: model.features.fineTuning)
            }

             Section("Snapshots") {
                 ForEach(model.snapshots) { snapshot in
                     HStack {
                         Text(snapshot.alias)
                         if snapshot.isDefault {
                             Text("(Default)").font(.caption).foregroundColor(.secondary)
                         }
                         Spacer()
                         Text(snapshot.versionDate).font(.caption).foregroundColor(.secondary)
                     }
                 }
             }
        }
        .navigationTitle(model.displayName)
    }

    // Helper view for text pairs
    @ViewBuilder func TextPair(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
    }

    // Helper view for modality rows
     @ViewBuilder func ModalityRow(modality: String, support: ModalityDetails.ModalitySupport) -> some View {
         HStack {
             Text(modality)
             Spacer()
             Text(support.note ?? (support.supported ? "Supported" : "Not Supported"))
                 .font(.caption)
                 .foregroundColor(support.supported ? .green : .red)
             Image(systemName: support.supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                 .foregroundColor(support.supported ? .green : .red)
         }
     }

    // Helper view for feature rows
    @ViewBuilder func FeatureRow(label: String, supported: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(supported ? .green : .red)
        }
    }
}

// MARK: - SwiftUI Preview Provider

#Preview {
    NavigationView {
        O1ModelDetailView_Preview()
    }
}
