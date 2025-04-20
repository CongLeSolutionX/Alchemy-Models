////
////  OpenAIChatAPIDocExplorer.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
//// MARK: - API Docs: OpenAI Chat Completion Explorer UI
//
//import SwiftUI
//
//// --- MARK: CORE MODELS (SIMPLIFIED FOR THE DOC UI) ---
//
//enum HTTPMethod: String, CaseIterable { case get = "GET", post = "POST", delete = "DELETE" }
//
//struct APIParameter: Identifiable, Hashable {
//    let id = UUID()
//    let name: String
//    let type: String
//    let required: Bool
//    let description: String
//    let deprecated: Bool
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
//// MARK: - MOCK DATA
//
//let chatCompletionsDocs: [APIEndpointDoc] = [
//    .init(
//        title: "Create Chat Completion",
//        method: .post,
//        path: "/v1/chat/completions",
//        summary: "Creates a model response for the given chat conversation.",
//        parameters: [
//            .init(name: "model", type: "string", required: true, description: "ID of model, e.g. 'gpt-4o', 'gpt-4-1'.", deprecated: false),
//            .init(name: "messages", type: "array", required: true, description: "A list of messages; each message has a role and content (and optional tool calls).", deprecated: false),
//            .init(name: "tools", type: "array", required: false, description: "Specifies available tools (functions) for tool calling.", deprecated: false),
//            .init(name: "tool_choice", type: "string/object", required: false, description: "Controls which tool(s) the model can call.", deprecated: false),
//            .init(name: "temperature", type: "number or null", required: false, description: "Sampling temperature (0-2), default 1.", deprecated: false),
//            .init(name: "top_p", type: "number or null", required: false, description: "Nucleus sampling parameter (0-1), default 1.", deprecated: false),
//            .init(name: "max_completion_tokens", type: "integer or null", required: false, description: "Maximum output tokens in completion. Replaces 'max_tokens'.", deprecated: false),
//            .init(name: "max_tokens", type: "integer or null", required: false, description: "Deprecated in favor of 'max_completion_tokens'.", deprecated: true),
//            .init(name: "presence_penalty", type: "number or null", required: false, description: "Penalizes new tokens based on whether they appear in prior text.", deprecated: false),
//            .init(name: "frequency_penalty", type: "number or null", required: false, description: "Penalizes tokens based on frequency to reduce repetition.", deprecated: false),
//            .init(name: "seed", type: "integer or null", required: false, description: "If set, attempt deterministic responses for the same input.", deprecated: false),
//            .init(name: "store", type: "boolean or null", required: false, description: "If true, persists the completion object for retrieval or deletion.", deprecated: false),
//            .init(name: "stream", type: "boolean or null", required: false, description: "If true, response is streamed as server-sent events.", deprecated: false),
//            .init(name: "metadata", type: "map", required: false, description: "Map for structured custom metadata.", deprecated: false),
//            .init(name: "modalities", type: "array or null", required: false, description: "Output types (e.g. text, audio); default is [\"text\"].", deprecated: false),
//            .init(name: "audio", type: "object or null", required: false, description: "Audio output parameters (if modalities contains audio).", deprecated: false),
//            .init(name: "logprobs", type: "boolean or null", required: false, description: "Whether to return log probabilities of output tokens.", deprecated: false)
//        ],
//        sampleRequest: """
//        POST https://api.openai.com/v1/chat/completions
//        {
//          "model": "gpt-4o",
//          "messages": [
//            { "role": "system", "content": "You are a helpful assistant." },
//            { "role": "user", "content": "Write a haiku about AI." }
//          ],
//          "temperature": 0.7,
//          "max_completion_tokens": 64,
//          "stream": false
//        }
//        """,
//        sampleResponse: """
//        {
//          "id": "chatcmpl-xyz123",
//          "object": "chat.completion",
//          "created": 1741570000,
//          "model": "gpt-4o-2024-08-06",
//          "choices": [ {
//            "index": 0,
//            "message": {
//              "role": "assistant",
//              "content": "Mind of circuits hum,\\nLearning patterns in silence—\\nFuture's quiet spark."
//            },
//            "finish_reason": "stop"
//          } ],
//          "usage": {
//            "prompt_tokens": 19,
//            "completion_tokens": 10,
//            "total_tokens": 29
//          },
//          "service_tier": "default"
//        }
//        """
//    )
//    // You could add subsequent endpoints: get completion, list completions, update, delete, etc.
//]
//
//// MARK: - UI COMPONENTS
//
//struct APIDocEndpointHeader: View {
//    let doc: APIEndpointDoc
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack(spacing: 14) {
//                Text(doc.method.rawValue)
//                    .font(.caption).bold()
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 10).padding(.vertical, 4)
//                    .background(doc.method == .post ? Color.purple : Color.blue)
//                    .cornerRadius(6)
//                Text(doc.path)
//                    .font(.callout.monospaced()).foregroundColor(.primary)
//            }
//            Text(doc.title).font(.title2.weight(.medium))
//            Text(doc.summary).font(.body).foregroundColor(.secondary)
//        }
//    }
//}
//
//struct APIDocParameterRow: View {
//    let param: APIParameter
//    @State private var showDetail = false
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 1) {
//                HStack {
//                    Text(param.name).font(.system(.body, design: .monospaced)).bold()
//                        .foregroundColor(param.deprecated ? .gray : .primary)
//                    if param.required { Text("Required").font(.caption2).bold().foregroundColor(.red).padding(.horizontal, 6).background(Color.red.opacity(0.13)).cornerRadius(4) }
//                    if param.deprecated { Text("Deprecated").font(.caption2).bold().foregroundColor(.gray).padding(.horizontal, 6).background(Color.gray.opacity(0.14)).cornerRadius(4) }
//                }
//                Text(param.type).font(.caption).foregroundColor(.gray)
//            }
//            Spacer()
//            Button(action: { showDetail.toggle() }) {
//                Image(systemName: "info.circle").foregroundColor(.accentColor).imageScale(.medium)
//            }
//            .help("Show parameter description")
//        }
//        .sheet(isPresented: $showDetail) {
//            NavigationStack {
//                VStack(alignment: .leading, spacing: 12) {
//                    Text(param.name).font(.title3.bold())
//                    Text("Type: \(param.type)").monospaced().foregroundColor(.secondary)
//                    Text(param.description).font(.body)
//                        .padding(.top, 8)
//                }
//                .padding().navigationTitle(param.name).toolbar { Button("Close") { showDetail = false } }
//            }
//        }
//    }
//}
//
//struct APIDocExpandableSection<Content: View>: View {
//    let title: String
//    @ViewBuilder let content: () -> Content
//    @State private var isOpen = true
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            Button(action: { withAnimation { isOpen.toggle() } }) {
//                HStack {
//                    Image(systemName: isOpen ? "chevron.down" : "chevron.right")
//                        .foregroundColor(.secondary)
//                    Text(title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    Spacer()
//                }
//                .padding(.vertical, 6)
//            }
//            if isOpen {
//                content()
//                    .padding(.bottom, 8)
//            }
//            Divider()
//        }
//        .padding(.vertical, 2)
//    }
//}
//
//struct APIDocMonospaceBlock: View {
//    let title: String?
//    let code: String
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            if let title {
//                Text(title).font(.footnote.weight(.semibold)).foregroundColor(.secondary)
//            }
//            ScrollView(.horizontal, showsIndicators: false) {
//                Text(code)
//                    .font(.system(.body, design: .monospaced))
//                    .lineSpacing(3)
//                    .padding()
//                    .background(Color(.secondarySystemBackground))
//                    .cornerRadius(8)
//                    .padding(.vertical, 2)
//            }
//        }
//    }
//}
//
//// MARK: - MAIN VIEW
//
//struct OpenAIChatAPIDocExplorer: View {
//    @State private var selectedSection: Int = 0
//    let endpointDocs = chatCompletionsDocs
//
//    var body: some View {
//        NavigationStack {
//            List {
//                // -- Overview and Useful Links --
//                Section {
//                    VStack(alignment: .leading, spacing: 12) {
//                        Label("Chat Completions API", systemImage: "bubble.left.and.bubble.right")
//                            .font(.title2.bold())
//                        Text("Interact with OpenAI chat and reasoning models using the flexible and powerful Chat Completions API. Supports text, image, and audio inputs plus a rich set of features for function- and tool-calling.")
//                            .font(.body)
//                        HStack(spacing: 15) {
//                            Link("Official Docs", destination: URL(string: "https://platform.openai.com/docs/api-reference/chat")!)
//                            Link("Models List", destination: URL(string: "https://platform.openai.com/docs/models")!)
//                            Link("Reasoning Guide", destination: URL(string: "https://platform.openai.com/docs/guides/reasoning")!)
//                        }
//                        .font(.subheadline)
//                        .foregroundColor(.accentColor)
//                    }.padding(.vertical, 8)
//                }
//
//                // -- ENDPOINTS --
//                ForEach(endpointDocs) { doc in
//                    Section {
//                        APIDocEndpointHeader(doc: doc)
//                            .padding(.bottom, 4)
//
//                        APIDocExpandableSection(title: "Parameters") {
//                            VStack(alignment: .leading, spacing: 8) {
//                                ForEach(doc.parameters) { param in
//                                    APIDocParameterRow(param: param)
//                                }
//                            }
//                        }
//                        APIDocExpandableSection(title: "Sample Request") {
//                            APIDocMonospaceBlock(title: "Example Request", code: doc.sampleRequest)
//                        }
//                        APIDocExpandableSection(title: "Sample Response") {
//                            APIDocMonospaceBlock(title: "Example Response", code: doc.sampleResponse)
//                        }
//                    }
//                }
//
//                // Further endpoints (GET, UPDATE, DELETE) can be appended with the same structure
//
//                Section {
//                    HStack { Spacer()
//                        Link(destination: URL(string: "https://platform.openai.com/docs/api-reference/chat")!) {
//                            Label("Read Full Documentation at OpenAI", systemImage: "link")
//                        }
//                        .padding(.vertical, 10)
//                        Spacer()
//                    }
//                }
//            }
//            .navigationTitle("OpenAI Chat API Docs")
//        }
//    }
//}
//
//// -- PREVIEW --
//
//struct OpenAIChatAPIDocExplorer_Previews: PreviewProvider {
//    static var previews: some View {
//        OpenAIChatAPIDocExplorer()
//    }
//}
