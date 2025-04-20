////
////  OpenAIChatAPIDemoView.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//import SwiftUI
//
//enum ChatRole: String, CaseIterable { case system, user, assistant }
//
//struct OpenAIRequest: Encodable {
//    let model: String
//    let messages: [Message]
//    let temperature: Double?
//    let max_tokens: Int?
//    struct Message: Encodable {
//        let role: String
//        let content: String
//    }
//}
//
//struct OpenAICompletionResponse: Decodable {
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
//final class OpenAIChatAPI: ObservableObject {
//    @Published var lastResponse: String?
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//
//    @MainActor
//    func createChatCompletion(
//        apiKey: String,
//        model: String,
//        messages: [(ChatRole, String)],
//        temperature: Double?,
//        maxTokens: Int?
//    ) async {
//        isLoading = true; errorMessage = nil; lastResponse = nil
//        defer { isLoading = false }
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            errorMessage = "Invalid API URL"; return
//        }
//        let req = OpenAIRequest(
//            model: model,
//            messages: messages.map { .init(role: $0.0.rawValue, content: $0.1) },
//            temperature: temperature, max_tokens: maxTokens
//        )
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        do {
//            request.httpBody = try JSONEncoder().encode(req)
//        } catch {
//            errorMessage = "Encoding error: \(error.localizedDescription)"
//            return
//        }
//        do {
//            let (data, resp) = try await URLSession.shared.data(for: request)
//            if let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 401 {
//                errorMessage = "Unauthorized: Check your API key!"; return
//            }
//            guard let decoded = try? JSONDecoder().decode(OpenAICompletionResponse.self, from: data) else {
//                errorMessage = "Could not parse response."; return
//            }
//            if let e = decoded.error?.message { errorMessage = e; return }
//            let text = decoded.choices.first?.message.content ?? ""
//            let usage: String
//                = decoded.usage.map { u in
//                    "\n\nPrompt: \(u.prompt_tokens ?? 0)  Completion: \(u.completion_tokens ?? 0)  Total: \(u.total_tokens ?? 0)"
//                  }
//                  ?? ""
//            self.lastResponse = text + usage
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//    }
//}
//
//struct OpenAIChatAPIDemoView: View {
//    @StateObject private var api = OpenAIChatAPI()
//    @AppStorage("openai_api_key") var apiKey: String = ""
//    @State var model: String = "gpt-4o"
//    @State var prompt: String = "Write a haiku about AI."
//    @State var temperature: Double = 0.7
//    @State var maxTokens = 64
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("OpenAI API Key") {
//                    SecureField("sk-...", text: $apiKey)
//                    Text("Find at https://platform.openai.com/api-keys")
//                        .font(.caption2).foregroundColor(.secondary)
//                }
//                Section("Parameters") {
//                    TextField("Model", text: $model)
//                    TextField("Prompt", text: $prompt, axis: .vertical)
//                    HStack {
//                        Text("Temperature")
//                        Slider(value: $temperature, in: 0...2)
//                        Text(String(format: "%.2f", temperature)).monospaced()
//                    }
//                    Stepper("Max Tokens: \(maxTokens)", value: $maxTokens, in: 8...4096)
//                }
//                Section {
//                    Button(api.isLoading ? "Requesting..." : "Send Request") {
//                        Task {
//                            await api.createChatCompletion(
//                                apiKey: apiKey,
//                                model: model,
//                                messages: [(.system, "You are a helpful assistant."), (.user, prompt)],
//                                temperature: temperature,
//                                maxTokens: maxTokens)
//                        }
//                    }
//                    .disabled(api.isLoading || apiKey.count < 20)
//                }
//                if let response = api.lastResponse {
//                    Section("API Response") {
//                        ScrollView(.horizontal) {
//                            Text(response)
//                                .font(.system(.body, design:.monospaced))
//                        }
//                    }
//                }
//                if let err = api.errorMessage {
//                    Section {
//                        Text(err).foregroundColor(.red)
//                    }
//                }
//            }
//            .navigationTitle("OpenAI Chat Demo")
//        }
//    }
//}
//
//#Preview {
//    OpenAIChatAPIDemoView()
//}
