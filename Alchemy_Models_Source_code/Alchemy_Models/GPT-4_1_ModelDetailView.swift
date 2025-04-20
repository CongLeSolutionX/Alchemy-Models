//
//  OpenAIModelsMasterView_GPT-4_1_detail.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//
//  GPT41DetailView.swift
//  Single File GPT-4.1 Detail Implementation
//
//  Created: Cong Le
//  Date: 4/13/25 (Based on previous iterations & screenshots)
//  Version: 1.0 (GPT-4.1 Specific Detail View)
//  License(s): MIT (Code), CC BY 4.0 (Non-Code Content)
//  Copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
//
//  Disclaimer: This file contains personal educational notes derived
//  from public documentation and cited sources. It uses hardcoded data
//  based on the provided screenshots for demonstration purposes.
//

import SwiftUI
import Foundation // Used for Date formatting, URL potentially

// MARK: - Data Model: GPT-4.1 Specific Details

// Represents the detailed data specifically for GPT-4.1, derived from screenshots
struct GPT41ModelData: Identifiable {
    let id = "gpt-4.1"
    let displayName = "GPT-4.1"
    let tagline = "Flagship GPT model for complex tasks"
    let isDefault = true
    let description = "GPT-4.1 is our flagship model for complex tasks. It is well suited for problem solving across domains."

    // Stats
    let intelligenceRating = 4 // out of 4
    let speedRating = 3 // out of 4
    let priceRange = "$2 • $8" // Simplified from screenshot
    let priceDescription = "Input • Output" // Simplified
    let supportedInputs: [InputOutputCapability] = [.text, .image]
    let supportedOutputs: [InputOutputCapability] = [.text]

    // Features Row
    let contextWindowTokens = 1_047_576
    let maxOutputTokens = 32_768
    let knowledgeCutoff = "May 31, 2024"

    // Pricing
    let pricingLink = "https://openai.com/pricing" // Example URL
    let pricingPerMillionTokens: PricingDetail = .init(input: 2.00, cachedInput: 0.50, output: 8.00)
    let quickComparison: [QuickComparisonItem] = [
        .init(modelName: "GPT-4o", inputPrice: 2.50), // Example, adjust based on actual logic if needed
        .init(modelName: "GPT-4.1", inputPrice: 2.00),
        .init(modelName: "o3-mini", inputPrice: 1.10)
    ]

    // Modalities
    let modalities: [ModalityDetail] = [
        .init(type: .text, support: .inputOutput),
        .init(type: .image, support: .inputOnly),
        .init(type: .audio, support: .notSupported)
    ]

    // Endpoints
    let endpoints: [EndpointSupport] = [
        .init(name: "Chat Completions", path: "v1/chat/completions", supported: true, icon: "message"),
        .init(name: "Responses", path: "v1/responses", supported: true, icon: "arrowshape.turn.up.left.fill"), // Assuming icon
        .init(name: "Assistants", path: "v1/assistants", supported: true, icon: "person.crop.circle.badge.questionmark"), // Assuming icon
        .init(name: "Realtime", path: nil, supported: false, icon: "timer"),
        .init(name: "Batch", path: "v1/batch", supported: true, icon: "list.bullet.rectangle.portrait"),
        .init(name: "Fine-tuning", path: "v1/fine-tuning", supported: true, icon: "slider.horizontal.3"), // Assuming icon
        .init(name: "Embeddings", path: nil, supported: false, icon: "arrow.down.right.and.arrow.up.left.circle.fill"),
        .init(name: "Image generation", path: nil, supported: false, icon: "photo"),
        .init(name: "Speech generation", path: nil, supported: false, icon: "speaker.wave.2.fill"),
        .init(name: "Transcription", path: nil, supported: false, icon: "waveform"),
        .init(name: "Translation", path: nil, supported: false, icon: "character.book.closed"), // Assuming icon
        .init(name: "Moderation", path: nil, supported: false, icon: "exclamationmark.shield.fill"),
        .init(name: "Completions (legacy)", path: nil, supported: false, icon: "terminal") // Assuming icon
    ]

    // Features (Bottom Section)
    let features: [FeatureSupport] = [
        .init(name: "Streaming", supported: true, icon: "bolt.horizontal.fill"),
        .init(name: "Function calling", supported: true, icon: "hammer.fill"),
        .init(name: "Structured outputs", supported: true, icon: "curlybraces.square.fill"),
        .init(name: "Fine-tuning", supported: true, icon: "slider.horizontal.3"), // Repeated, but common
        .init(name: "Distillation", supported: true, icon: "drop.fill"), // Assuming icon
        .init(name: "Predicted outputs", supported: true, icon: "checkmark.circle.fill")
    ]

    // Snapshots
    let snapshots: [SnapshotInfo] = [
        .init(alias: "gpt-4.1", version: "gpt-4.1-2025-04-14", isCurrent: true), // Assuming date
        .init(alias: "gpt-4.1-2025-04-14", version: nil, isCurrent: false) // Assuming date
    ]

    // Rate Limits (Simplified representation)
    let rateLimits: [RateLimitTier] = [
        .init(tier: "Free", rpm: nil, rpd: nil, tpmStandard: nil, tpmLong: nil, batchLimitStandard: nil, batchLimitLong: nil, notes: "Not supported"),
        .init(tier: "Tier 1", rpm: 500, rpd: nil, tpmStandard: 30_000, tpmLong: 30_000, batchLimitStandard: 90_000, batchLimitLong: 90_000),
        .init(tier: "Tier 2", rpm: 5_000, rpd: nil, tpmStandard: 450_000, tpmLong: 450_000, batchLimitStandard: 1_350_000, batchLimitLong: 1_350_000),
        .init(tier: "Tier 3", rpm: 5_000, rpd: nil, tpmStandard: 800_000, tpmLong: 800_000, batchLimitStandard: 50_000_000, batchLimitLong: 50_000_000),
        .init(tier: "Tier 4", rpm: 10_000, rpd: nil, tpmStandard: 2_000_000, tpmLong: 2_000_000, batchLimitStandard: 50_000_000, batchLimitLong: 50_000_000),
        .init(tier: "Tier 5", rpm: 10_000, rpd: nil, tpmStandard: 30_000_000, tpmLong: 30_000_000, batchLimitStandard: 50_000_000, batchLimitLong: 50_000_000)

    ]

    // --- Structures for nested data ---
    struct PricingDetail { let input, cachedInput, output: Double }
    struct QuickComparisonItem: Identifiable { let id = UUID(); let modelName: String; let inputPrice: Double }
    struct ModalityDetail: Identifiable { let id = UUID(); let type: InputOutputCapability; let support: SupportLevel }
    struct EndpointSupport: Identifiable { let id = UUID(); let name: String; let path: String?; let supported: Bool; let icon: String }
    struct FeatureSupport: Identifiable { let id = UUID(); let name: String; let supported: Bool; let icon: String }
    struct SnapshotInfo: Identifiable { let id = UUID(); let alias: String; let version: String?; let isCurrent: Bool }
    struct RateLimitTier: Identifiable {
        let id = UUID()
        let tier: String
        let rpm: Int?
        let rpd: Int? // Typically null from screenshot
        let tpmStandard: Int?
        let tpmLong: Int? // Same as standard in this case
        let batchLimitStandard: Int?
        let batchLimitLong: Int? // Same as standard
        var notes: String? = nil
    }

    enum InputOutputCapability: String { case text = "Text"; case image = "Image"; case audio = "Audio" }
    enum SupportLevel { case inputOutput, inputOnly, outputOnly, notSupported }
    enum PriceComponent { case input, cachedInput, output } // For quick comparison visual

    // Static mock data for easy previewing
    static let sample = GPT41ModelData()
}

// MARK: - Reusable Helper SwiftUI Views

// --- Section Header ---
struct SectionHeaderView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title2.weight(.semibold))
            .padding(.bottom, 5)
    }
}

// --- Stat Item View (Intelligence, Speed, Price, Input, Output) ---
struct StatItemView: View {
    let label: String
    let value: String?
    let iconName: String?
    let rating: Int? // For stars/bolts (0-4)
    let totalRating: Int // Max rating (e.g., 4)
    let ratingSymbolFilled: String // e.g., "star.fill"
    let ratingSymbolEmpty: String // e.g., "star"
    let detail: String?
    let valueAlignment: HorizontalAlignment

    init(label: String, value: String? = nil, iconName: String? = nil, rating: Int? = nil, totalRating: Int = 4, ratingSymbolFilled: String = "circle.fill", ratingSymbolEmpty: String = "circle", detail: String? = nil, valueAlignment: HorizontalAlignment = .leading) {
        self.label = label
        self.value = value
        self.iconName = iconName
        self.rating = rating
        self.totalRating = totalRating
        self.ratingSymbolFilled = ratingSymbolFilled
        self.ratingSymbolEmpty = ratingSymbolEmpty
        self.detail = detail
        self.valueAlignment = valueAlignment
    }

    var body: some View {
        VStack(alignment: valueAlignment, spacing: 5) {
             Text(label.uppercased())
                 .font(.caption.weight(.medium))
                 .foregroundStyle(.secondary)

             if let rating = rating {
                 HStack(spacing: 2) {
                     ForEach(0..<totalRating, id: \.self) { index in
                         Image(systemName: index < rating ? ratingSymbolFilled : ratingSymbolEmpty)
                              .font(.subheadline) // Adjust size
                             .foregroundColor(index < rating ? .primary : .secondary.opacity(0.5))
                     }
                 }
             } else if let value = value {
                 Text(value)
                     .font(.title3.weight(.medium)) // Larger font for price
             } else if let iconName = iconName {
                 Image(systemName: iconName)
                      .font(.title3)
             }

            if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: valueAlignment, vertical: .top))
    }
}

// --- Enhanced StatItem for Input/Output Icons ---
struct InputOutputStatItemView: View {
    let label: String
    let capabilities: [GPT41ModelData.InputOutputCapability]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
             Text(label.uppercased())
                 .font(.caption.weight(.medium))
                 .foregroundStyle(.secondary)
                 .padding(.bottom, 2) // More space below label

             HStack(spacing: 8) {
                 ForEach(capabilities, id: \.rawValue) { cap in
                     VStack {
                         Image(systemName: iconForCapability(cap))
                              .font(.subheadline) // Icons slightly smaller
                         Text(cap.rawValue)
                             .font(.caption2) // Smaller text below icon
                             .foregroundStyle(.secondary)
                     }
                     .padding(5) // Add padding around each icon+text
                      // .background(.quaternary) // Optional subtle background
                      .clipShape(RoundedRectangle(cornerRadius: 4))
                 }
             }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iconForCapability(_ cap: GPT41ModelData.InputOutputCapability) -> String {
        switch cap {
        case .text: return "doc.text.fill"
        case .image: return "photo.fill"
        case .audio: return "speaker.wave.2.fill"
        }
    }
}

// --- Feature Row View (Context, Tokens, Knowledge Cutoff) ---
struct FeatureRowView: View {
    let iconName: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.callout)
                .frame(width: 20, alignment: .center) // Align icons
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.medium))
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer() // Push content left
        }
    }
}

// --- Pricing Box ---
struct PricingBoxView: View {
    let type: String // Input, Cached input, Output
    let price: Double

    var body: some View {
        VStack(spacing: 5) {
            Text(type)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "$%.2f", price))
                .font(.title2.weight(.medium))
        }
        .padding()
        .frame(maxWidth: .infinity) // Take available width
        .background(.quaternary) // Use quaternary for subtle background
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// --- Quick Comparison Bar --- VERY SIMPLIFIED VISUAL
struct QuickComparisonBarView: View {
    let modelName: String
    let price: Double
    let maxPrice: Double // Used for scaling the bar

    var body: some View {
        HStack {
            Text(modelName).font(.caption).frame(width: 60, alignment: .leading)
            GeometryReader { geometry in
                let barWidth = geometry.size.width * (price / maxPrice)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary) // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.secondary) // Actual bar
                        .frame(width: max(5, barWidth)) // Minimum width
                }
            }
            .frame(height: 8) // Bar height

            Text(String(format: "$%.2f", price))
                .font(.caption.monospacedDigit())
                .frame(width: 45, alignment: .trailing)
        }
    }
}

// --- Modality Item ---
struct ModalityItemView: View {
    let detail: GPT41ModelData.ModalityDetail

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconForCapability(detail.type))
                .font(.title3)
                .frame(width: 30)
                .foregroundStyle(detail.support == .notSupported ? .secondary : .primary)

            VStack(alignment: .leading) {
                Text(detail.type.rawValue)
                    .font(.headline)
                Text(supportText(detail.support))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.quaternary.opacity(0.5)) // Very subtle background
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(detail.support == .notSupported ? 0.6 : 1.0) // Dim if not supported
    }

    private func iconForCapability(_ cap: GPT41ModelData.InputOutputCapability) -> String {
        switch cap {
        case .text: return "doc.text.fill"
        case .image: return "photo.fill"
        case .audio: return "speaker.wave.2.fill"
        }
    }

    private func supportText(_ support: GPT41ModelData.SupportLevel) -> String {
        switch support {
        case .inputOutput: return "Input and output"
        case .inputOnly: return "Input only"
        case .outputOnly: return "Output only"
        case .notSupported: return "Not supported"
        }
    }
}

// --- Endpoint/Feature Item View ---
struct EndpointFeatureItemView: View {
    let name: String
    let detail: String? // Path for endpoints, null for features
    let supported: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .frame(width: 20, alignment: .center)
                .foregroundStyle(supported ? .primary : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                if let detail = detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if !supported {
                Text("Not supported")
                    .font(.caption)
                    .foregroundStyle(.tertiary) // Very subtle
                    .padding(.horizontal, 5)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
        }
        .opacity(supported ? 1.0 : 0.6) // Dim if not supported
    }
}

// --- Snapshot Item View ---
struct SnapshotItemView: View {
    let info: GPT41ModelData.SnapshotInfo

    var body: some View {
        HStack {
            Image(systemName: "tag.fill").foregroundStyle(.secondary).font(.callout)
            Text(info.alias)
                .font(.subheadline)
            if let version = info.version {
                 Text("→ \(version)")
                     .font(.caption)
                     .foregroundStyle(.secondary)
            }
            Spacer()
            if info.isCurrent {
                Text("Current")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
}

//--- Rate Limit Table Row ---
struct RateLimitRow: View {
    let tier: GPT41ModelData.RateLimitTier
    let isHeader: Bool

    private func formatNumber(_ number: Int?) -> String {
        guard let number = number else { return "-" }
        if number >= 1_000_000 {
            return "\(number / 1_000_000)M"
        } else if number >= 1_000 {
            return "\(number / 1_000)K"
        }
        return "\(number)"
    }

    var body: some View {
         GridRow(alignment: .center) {
             Text(tier.tier)
                 .gridCellAnchor(.leading) // Align Tiers left
             Text(tier.notes ?? formatNumber(tier.rpm))
             Text(tier.notes ?? formatNumber(tier.tpmStandard))
             Text(tier.notes ?? formatNumber(tier.tpmLong)) // Show long context TPM
             Text(tier.notes ?? formatNumber(tier.batchLimitStandard)) // Show standard batch limit
                 .gridCellAnchor(.trailing) // Align Limits right
        }
         .font(isHeader ? .caption.weight(.semibold) : .caption)
         .foregroundStyle(isHeader ? .secondary : .primary)
    }
}

// MARK: - Main Detail View for GPT-4.1

struct GPT41DetailView: View {
    // Using static sample data for demonstration
    @State private var modelData: GPT41ModelData = .sample
    @State private var showBatchAPIPrice = false // Toggle state for pricing

    // Find max comparison price for scaling bars
    private var maxComparisonPrice: Double {
        modelData.quickComparison.map { $0.inputPrice }.max() ?? 5.0 // Default max if no data
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) { // Increased spacing between sections

                // --- Header ---
                 VStack(alignment: .leading, spacing: 8) {
                     HStack {
                         Text(modelData.displayName)
                              .font(.largeTitle.weight(.bold))
                         if modelData.isDefault {
                             Text("Default")
                                 .font(.caption.weight(.medium))
                                 .padding(.horizontal, 8)
                                 .padding(.vertical, 3)
                                 .background(Color.gray.opacity(0.2))
                                 .foregroundStyle(.secondary)
                                 .clipShape(Capsule())
                         }
                         Spacer()
                         Button("Compare") {} // Placeholder action
                             .buttonStyle(.bordered)
                         Button("Try in Playground") {} // Placeholder action
                             .buttonStyle(.borderedProminent)
                     }
                     Text(modelData.tagline)
                         .font(.title3)
                         .foregroundStyle(.secondary)
                 }
                 .padding(.horizontal) // Consistent horizontal padding

                // --- Stats Bar ---
                HStack(alignment: .top, spacing: 15) {
                    StatItemView(label: "Intelligence", rating: modelData.intelligenceRating, ratingSymbolFilled: "star.fill", ratingSymbolEmpty: "star", detail: "Higher", valueAlignment: .leading)
                    StatItemView(label: "Speed", rating: modelData.speedRating, ratingSymbolFilled: "bolt.fill", ratingSymbolEmpty: "bolt", detail: "Medium", valueAlignment: .center) // Center align speed
                    StatItemView(label: "Price", value: modelData.priceRange, detail: modelData.priceDescription, valueAlignment: .center) // Center align price
                    Divider().frame(height: 50)
                    InputOutputStatItemView(label: "Input", capabilities: modelData.supportedInputs)
                    Divider().frame(height: 50)
                    InputOutputStatItemView(label: "Output", capabilities: modelData.supportedOutputs)
                }
                .padding(.horizontal)
                .padding(.vertical)
                .background(.regularMaterial) // Subtle background for the stats bar
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal) // Padding around the material background

                // --- Description ---
                Text(modelData.description)
                    .font(.body)
                    .padding(.horizontal)

                // --- Key Features ---
                HStack(spacing: 20) {
                    FeatureRowView(iconName: "arrow.up.left.and.arrow.down.right.circle.fill", value: formatTokens(modelData.contextWindowTokens), label: "Context window")
                    FeatureRowView(iconName: "arrow.down.left.and.arrow.up.right.circle.fill", value: formatTokens(modelData.maxOutputTokens), label: "Max output tokens")
                    FeatureRowView(iconName: "calendar.badge.clock", value: modelData.knowledgeCutoff, label: "Knowledge cutoff")
                }
                .padding(.horizontal)

                Divider().padding(.horizontal)

                // --- Pricing Section ---
                VStack(alignment: .leading, spacing: 15) {
                    SectionHeaderView(title: "Pricing")
                    Text("Pricing is based on the number of tokens used. For tool-specific models, like search and computer use, there's a fee per tool call. See details in the [pricing page](\(modelData.pricingLink)).")
                        .font(.callout)

                    HStack {
                        Text("Per 1M tokens")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        // Toggle placeholder - actual implementation might differ
                        Toggle("Batch API price", isOn: $showBatchAPIPrice)
                             .labelsHidden()
                             .scaleEffect(0.8) // Make toggle smaller
                        Text("Batch API price")
                             .font(.caption)
                             .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 15) {
                        PricingBoxView(type: "Input", price: modelData.pricingPerMillionTokens.input)
                        PricingBoxView(type: "Cached input", price: modelData.pricingPerMillionTokens.cachedInput)
                        PricingBoxView(type: "Output", price: modelData.pricingPerMillionTokens.output)
                    }
                }
                .padding(.horizontal)

                // --- Quick Comparison --- SIMPLIFIED
                 VStack(alignment: .leading, spacing: 10) {
                     Text("Quick comparison")
                          .font(.subheadline.weight(.medium))
                      // Header row for comparison
                      HStack {
                          Spacer().frame(width: 60) // Align with bars
                           Text("Input").font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
                           // Add "Cached Input" and "Output" if data is available
                           Spacer().frame(width: 45) // Align with prices
                      }.padding(.horizontal, 2) // Small padding

                      ForEach(modelData.quickComparison) { item in
                          QuickComparisonBarView(modelName: item.modelName, price: item.inputPrice, maxPrice: maxComparisonPrice)
                      }
                 }
                 .padding(.horizontal)

                Divider().padding(.horizontal)

                 // --- Modalities ---
                 VStack(alignment: .leading, spacing: 10) {
                      SectionHeaderView(title: "Modalities")
                      // Using a Grid for better alignment
                      Grid(alignment: .leading, horizontalSpacing: 15, verticalSpacing: 10) {
                          ForEach(modelData.modalities) { modality in
                              GridRow {
                                  ModalityItemView(detail: modality)
                              }
                          }
                      }
                 }.padding(.horizontal)

                Divider().padding(.horizontal)

                // --- Endpoints ---
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeaderView(title: "Endpoints")
                     // Two-column grid
                     LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                         ForEach(modelData.endpoints) { endpoint in
                             EndpointFeatureItemView(name: endpoint.name, detail: endpoint.path, supported: endpoint.supported, icon: endpoint.icon)
                         }
                     }
                }.padding(.horizontal)

                Divider().padding(.horizontal)

                // --- Features (Bottom) ---
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeaderView(title: "Features")
                     LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                         ForEach(modelData.features) { feature in
                             EndpointFeatureItemView(name: feature.name, detail: nil, supported: feature.supported, icon: feature.icon)
                         }
                     }
                }.padding(.horizontal)

                Divider().padding(.horizontal)

                // --- Snapshots ---
                VStack(alignment: .leading, spacing: 8) {
                     SectionHeaderView(title: "Snapshots")
                     Text("Snapshots let you lock in a specific version of the model so that performance and behavior remain consistent. Below is a list of all available snapshots and aliases for GPT-4.1:")
                          .font(.callout)
                          .foregroundStyle(.secondary)
                          .padding(.bottom, 5)
                     ForEach(modelData.snapshots) { snapshot in
                         SnapshotItemView(info: snapshot)
                     }
                }.padding(.horizontal)

                Divider().padding(.horizontal)

                // --- Rate Limits Table ---
                VStack(alignment: .leading, spacing: 10) {
                     SectionHeaderView(title: "Rate limits")
                     Text("Rate limits ensure fair and reliable access to the API by placing specific caps on requests or tokens used within a given time period...") // Truncated for brevity
                          .font(.callout)
                          .foregroundStyle(.secondary)

                     Grid(alignment: .center, horizontalSpacing: 15, verticalSpacing: 8) {
                         // Header Row
                          RateLimitRow(tier: .init(tier: "TIER", rpm: nil, rpd: nil, tpmStandard: nil, tpmLong: nil, batchLimitStandard: nil, batchLimitLong: nil, notes: "RPM   TPM(Std)   TPM(Long)   Batch(Std)"), isHeader: true)
                               // Alternative Header with more explicit labels (might wrap)
                                // RateLimitRow(tier: .init(tier: "TIER", rpm: "RPM", rpd: "RPD", tpmStandard: "TPM Std", tpmLong: "TPM Long", batchLimitStandard: "Batch Std", batchLimitLong: "Batch Long"), isHeader: true)

                         // Data Rows
                         ForEach(modelData.rateLimits) { tier in
                             RateLimitRow(tier: tier, isHeader: false)
                         }
                     }
                     .padding(.top, 5)
                }
                .padding(.horizontal)

                Spacer(minLength: 50) // Space at bottom

            } // End Main VStack
            .padding(.top) // Padding at the very top
        } // End ScrollView
        .navigationTitle(modelData.displayName) // Use model name in nav bar
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground)) // Ensure background color
        .edgesIgnoringSafeArea(.bottom)
    }

    // Helper to format large token counts
    private func formatTokens(_ tokens: Int) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0 // No decimal for tokens
            return formatter.string(from: NSNumber(value: tokens)) ?? "\(tokens)"
    }
}

// MARK: - Previews

#Preview("GPT-4.1 Detail View") {
    NavigationView { // Wrap in NavigationView for title display
        GPT41DetailView()
    }
}
