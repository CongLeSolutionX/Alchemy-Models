////
////  OpenAIChatAPIDocExplorer_V2.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////  OpenAIChatAPIReferenceView.swift
////  Created for demonstration of a real in-app API doc and executor for OpenAI Chat Completions
////  SwiftUI 5+, iOS 17+ recommended
////  By Cong Le (2024)
//
//import SwiftUI
//
//// MARK: - 1. Supporting Models (API, UI, and Networking)
//
//enum HTTPMethod: String { case get = "GET", post = "POST", delete = "DELETE" }
//
//struct APIParameter: Identifiable, Hashable {
//    let id = UUID()
//    let name: String
//    let type: String
//    let required: Bool
//    let description: String
//    let deprecated: Bool
//    let sample: String?
//    var placeholder: String { sample ?? type }
//}
//
//struct APIEndpointDoc: Identifiable, Hashable {
//    let id = UUID()
//    let title: String
//    let method: HTTPMethod
//    let path: String
//    let summary: String
//    let parameters: [APIParameter]
//    let sampleRequest: String
//    let sampleResponse: String
//}
//
//enum ChatRole: String, Hashable, CaseIterable { case system, user, assistant }
//
//// MARK: - API Docs & Sample Data (keep modular for expansion)
//
//extension APIEndpointDoc {
//    static var chatCompletion: APIEndpointDoc {
//        .init(
//            title: "Create Chat Completion",
//            method: .post,
//            path: "/v1/chat/completions",
//            summary: "Generate model responses in a conversational format. Supports function calling, multiple input modalities, advanced reasoning, streaming, and more.",
//            parameters: [
//                .init(name: "model",   type: "string", required: true,  description: "Model ID (e.g., 'gpt-4o', 'gpt-4-turbo'). Determines behavior, speed, cost, and capabilities.", deprecated: false, sample: "gpt-4o"),
//                .init(name: "messages",type: "array", required: true,  description: "List of conversation turns, e.g. [{\"role\":\"system\",\"content\":\"...\"}, {\"role\":\"user\",\"content\":\"...\"}]", deprecated: false, sample: nil),
//                .init(name: "tools",   type: "array", required: false, description: "Functions/tools available for model to call (see OpenAI tools guide).",                          deprecated: false, sample: nil),
//                .init(name: "tool_choice",type: "string/object", required: false, description: "\"auto\", \"none\", or specify; controls if/what tools can be called.", deprecated: false, sample: nil),
//                .init(name: "temperature",type: "number",required: false, description: "Sampling diversity, 0–2. Default: 1. Sets randomness in response.", deprecated: false, sample: "0.7"),
//                .init(name: "max_completion_tokens", type: "integer", required: false, description: "Limit on output tokens for the completion.", deprecated: false, sample: "128"),
//                .init(name: "stream", type: "boolean", required: false, description: "Return streaming server-sent events for tokens as generated.", deprecated: false, sample: "false")
//            ],
//            sampleRequest: """
//            POST /v1/chat/completions
//            {
//                "model": "gpt-4o",
//                "messages": [
//                    { "role": "system", "content": "You are a helpful assistant." },
//                    { "role": "user", "content": "Write a haiku about AI." }
//                ],
//                "temperature": 0.7
//            }
//            """,
//            sampleResponse: """
//            {
//                "id": "chatcmpl-xyz123",
//                "object": "chat.completion",
//                "created": 1741570000,
//                "model": "gpt-4o-2024-08-06",
//                "choices": [
//                    { "index": 0, "message": { "role": "assistant", "content": "Mind of circuits hum,\\nLearning patterns in silence—\\nFuture's quiet spark." }, "finish_reason": "stop" }
//                ],
//                "usage": { "prompt_tokens": 19, "completion_tokens": 10, "total_tokens": 29 },
//                "service_tier": "default"
//            }
//            """
//        )
//    }
//}
//
//// MARK: - 2. Networking Layer (for demo execution)
//
//struct OpenAIRequest: Encodable {
//    let model: String
//    let messages: [Message]
//    let temperature: Double?
//    let max_completion_tokens: Int?
//    struct Message: Encodable {
//        let role: String
//        let content: String
//    }
//}
//
//struct OpenAIChatCompletionResponse: Decodable {
//    struct Choice: Decodable { let message: Message }
//    struct Message: Decodable { let role: String; let content: String }
//    let choices: [Choice]
//    let usage: Usage?
//    struct Usage: Decodable {
//        let prompt_tokens: Int?
//        let completion_tokens: Int?
//        let total_tokens: Int?
//    }
//    let error: APIError?
//    struct APIError: Decodable { let message: String? }
//}
//
//enum APIErrorKind: Error, CustomStringConvertible {
//    case network(String), server(String), decoding, unauthorized, unknown
//    var description: String {
//        switch self {
//            case .network(let msg): return "Network error: \(msg)"
//            case .server(let msg): return "API error: \(msg)"
//            case .decoding:        return "Could not parse API response."
//            case .unauthorized:    return "Unauthorized: check your API key."
//            case .unknown:         return "Unknown error."
//        }
//    }
//}
//
///// API client for OpenAI chat completions
//final class OpenAIChatAPI: ObservableObject {
//    @Published var lastResponse: String?
//    @Published var isLoading = false
//    @Published var error: APIErrorKind?
//
//    /// Actually hit the API
//    @MainActor
//    func createChatCompletion(
//        apiKey: String,
//        model: String,
//        messages: [(ChatRole, String)],
//        temperature: Double?,
//        maxTokens: Int?
//    ) async {
//        isLoading = true; self.error = nil; self.lastResponse = nil
//        defer { isLoading = false }
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            error = .network("Invalid API URL"); return
//        }
//
//        let req = OpenAIRequest(
//            model: model,
//            messages: messages.map { .init(role: $0.0.rawValue, content: $0.1) },
//            temperature: temperature,
//            max_completion_tokens: maxTokens
//        )
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        do {
//            request.httpBody = try JSONEncoder().encode(req)
//        } catch {
//            self.error = .network("Encoding error: \(error.localizedDescription)")
//            return
//        }
//
//        do {
//            let (data, resp) = try await URLSession.shared.data(for: request)
//            if let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 401 {
//                error = .unauthorized; return
//            }
//            guard let decoded = try? JSONDecoder().decode(OpenAIChatCompletionResponse.self, from: data) else {
//                error = .decoding; return
//            }
//            if let e = decoded.error?.message { error = .server(e); return }
//            let text = decoded.choices.first?.message.content ?? ""
//            var usageString = ""
//            if let u = decoded.usage {
//                usageString = "\n\n---\nPrompt: \(u.prompt_tokens ?? 0), Completion: \(u.completion_tokens ?? 0), Total: \(u.total_tokens ?? 0) tokens."
//            }
//            self.lastResponse = text + usageString
//        } catch {
//            self.error = .network(error.localizedDescription)
//        }
//    }
//}
//
//// MARK: - 3. SwiftUI Main View
//
//struct OpenAIChatAPIReferenceView: View {
//    @StateObject private var api = OpenAIChatAPI()
//    let doc = APIEndpointDoc.chatCompletion
//
//    // State for playground/demonstrator input
//    @AppStorage("openai_api_key") var apiKey: String = ""
//    @State var prompt: String = "Write a haiku about AI."
//    @State var tempModel: String = "gpt-4o"
//    @State var temperature: Double = 0.7
//    @State var maxTokens: Int = 64
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 18) {
//
//                    // Header / summary
//                    Text(doc.title)
//                        .font(.title.bold())
//                    Text(doc.summary)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    HStack(spacing: 18) {
//                        Label("POST", systemImage: "arrow.down.circle.fill")
//                            .font(.caption).foregroundColor(.white)
//                            .padding(.horizontal, 8).padding(.vertical, 3)
//                            .background(Color.purple.gradient).cornerRadius(6)
//                        Text(doc.path).font(.callout.monospaced()).foregroundColor(.primary)
//                    }
//
//                    // Quick links (docs, model list, official)
//                    HStack(spacing: 16) {
//                        Link("OpenAI Docs", destination: URL(string:"https://platform.openai.com/docs/api-reference/chat")!)
//                        Link("Model Guide", destination: URL(string:"https://platform.openai.com/docs/models")!)
//                        Spacer()
//                    }.font(.caption).padding(.vertical, 2)
//
//                    Divider().padding(.vertical, 4)
//
//                    // PARAMETERS
//                    DisclosureGroup("Parameters (\(doc.parameters.count))") {
//                        ForEach(doc.parameters) { param in ParameterRow(param: param) }
//                    }
//                    .bold()
//                    .padding(.vertical, 4)
//
//                    // Playground / Live API demo
//                    GroupBox(label: Label("Try it live", systemImage: "paperplane.fill").foregroundColor(.purple)) {
//                        VStack(alignment: .leading, spacing: 10) {
//                            SecureField("Your OpenAI API Key", text: $apiKey)
//                                .textContentType(.password)
//                                .autocapitalization(.none)
//                                .disableAutocorrection(true)
//                                .font(.caption)
//                                .accessibilityLabel("API Key")
//                                .onAppear { if apiKey.isEmpty { apiKey = "" } }
//                            HStack {
//                                TextField("Model", text: $tempModel)
//                                    .textFieldStyle(.roundedBorder).font(.caption)
//                                Stepper("Max Tokens: \(maxTokens)", value: $maxTokens, in: 8...4096)
//                                    .font(.caption)
//                                Spacer()
//                            }
//                            TextField("Prompt", text: $prompt, axis: .vertical)
//                                .lineLimit(2...4)
//                                .textFieldStyle(.roundedBorder)
//                                .accessibilityLabel("Prompt")
//                            HStack {
//                                Slider(value: $temperature, in: 0...2, step: 0.05) {
//                                    Text("Temperature")
//                                } minimumValueLabel: {
//                                    Text("0")
//                                } maximumValueLabel: {
//                                    Text("2")
//                                }
//                                Text(String(format: "%.2f", temperature)).bold().monospaced()
//                            }
//                            Button {
//                                Task {
//                                    await api.createChatCompletion(apiKey: apiKey, model: tempModel, messages: [(.system,"You are a helpful assistant."),(.user,prompt)], temperature: temperature, maxTokens: maxTokens)
//                                }
//                            } label: {
//                                HStack { Image(systemName: "bolt.fill"); Text(api.isLoading ? "Requesting..." : "Send Request") }
//                            }
//                            .disabled(api.isLoading || apiKey.count < 20)
//                        }
//                        .padding()
//
//                        if api.isLoading {
//                            HStack {
//                                ProgressView()
//                                Text("Contacting OpenAI...")
//                            }.font(.caption).padding(.vertical)
//                        }
//                        if let err = api.error {
//                            Text(err.description)
//                                .foregroundStyle(.red)
//                                .padding(.bottom, 1)
//                        }
//                        if let response = api.lastResponse {
//                            GroupBox(label: Label("Response", systemImage: "bubble.right.fill").foregroundColor(.green)) {
//                                ScrollView(.horizontal) {
//                                    Text(response)
//                                        .font(.system(.body, design:.monospaced))
//                                        .padding()
//                                        .foregroundStyle(.primary)
//                                }
//                            }
//                            .padding(.top, 4)
//                        }
//                    }
//                    .padding(.vertical, 8)
//
//                    Divider().padding(.vertical)
//
//                    // SAMPLE REQUEST/RESPONSE
//                    DisclosureGroup("Sample Request") {
//                        MonospaceBlock(code: doc.sampleRequest)
//                    }
//                    DisclosureGroup("Sample Response") {
//                        MonospaceBlock(code: doc.sampleResponse)
//                    }
//
//                    Spacer()
//                    // Attribution
//                    HStack {
//                        Text("Powered by OpenAI API • Example iOS integration")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        Spacer()
//                        Link("Docs", destination: URL(string: "https://platform.openai.com/docs/api-reference/chat")!)
//                    }
//                }
//                .padding()
//            }
//            .navigationTitle("OpenAI Chat API")
//            .toolbar {
//                Link(destination: URL(string: "https://platform.openai.com/docs/api-reference/chat")!) {
//                    Label("Docs", systemImage: "book")
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Modular UI Components
//
//struct ParameterRow: View {
//    let param: APIParameter
//    @State private var showInfo = false
//    var body: some View {
//        HStack(alignment: .firstTextBaseline) {
//            Text(param.name)
//                .font(.system(.body, design: .monospaced)).bold()
//                .foregroundColor(param.deprecated ? .gray : .primary)
//            if param.required {
//                Text("Required")
//                    .font(.caption2.weight(.semibold))
//                    .foregroundColor(.red)
//                    .padding(.horizontal, 6)
//                    .background(Color.red.opacity(0.14))
//                    .cornerRadius(4)
//            }
//            if param.deprecated {
//                Text("Deprecated")
//                    .font(.caption2).foregroundColor(.gray)
//                    .padding(.horizontal, 6)
//                    .background(Color.gray.opacity(0.12))
//                    .cornerRadius(4)
//            }
//            Spacer()
//            Button(action: { showInfo.toggle() }) {
//                Image(systemName: "info.circle").foregroundColor(.accentColor)
//            }
//            .accessibilityLabel("Show description")
//            .sheet(isPresented: $showInfo) {
//                NavigationStack {
//                    VStack(alignment: .leading, spacing: 20) {
//                        Text(param.name).font(.title2.bold())
//                        Text(param.type).monospaced().foregroundColor(.secondary)
//                        Text(param.description)
//                        if let sample = param.sample {
//                            GroupBox(label: Text("Example")) {
//                                Text(sample).monospaced()
//                            }
//                        }
//                        Spacer()
//                    }
//                    .padding()
//                    .navigationTitle(param.name)
//                    .toolbar { ToolbarItem(placement: .primaryAction) { Button("Close") { showInfo = false } } }
//                }
//            }
//        }
//        .padding(.vertical, 4)
//    }
//}
//
//struct MonospaceBlock: View {
//    let code: String
//    var body: some View {
//        ScrollView(.horizontal) {
//            Text(code)
//                .font(.system(.body, design: .monospaced))
//                .padding()
//                .background(Color(.secondarySystemBackground))
//                .cornerRadius(8)
//        }.padding(.vertical, 1)
//    }
//}
//
//// MARK: - Preview
//
//struct OpenAIChatAPIReferenceView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            OpenAIChatAPIReferenceView()
//        }
//    }
//}
