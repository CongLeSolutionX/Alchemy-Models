//
//  OpenAIChatAPIDemoView_V4.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//  OpenAIStreamingChatView.swift
//  Real-time live chat (input and response) with voice using OpenAI Chat API
//  - Single file, ready for iOS SwiftUI projects, iOS 16+
//  By Cong Le, 2024

import SwiftUI
import AVFoundation

// MARK: - Chat Models

enum ChatRole: String, Codable, CaseIterable {
    case system, user, assistant
}

struct Message: Identifiable, Codable {
    var id = UUID()
    let role: ChatRole
    let content: String
}

struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [MessagePayload]
    let stream: Bool
    let temperature: Double?
    let max_tokens: Int?
    struct MessagePayload: Encodable {
        let role: String
        let content: String
    }
}

// For streaming
struct OpenAIStreamResponse: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let role: String?
            let content: String?
        }
        let delta: Delta
        let finish_reason: String?
    }
    let choices: [Choice]
}

struct SimpleChatEntry: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
}

// MARK: - OpenAIService for regular and SSE streaming calls

@MainActor
final class OpenAIStreamingChatService: ObservableObject {
    @Published var messages: [Message] = [
        Message(role: .system, content: "You are a helpful assistant.")
    ]
    @Published var input: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var streamingAssistantReply: String = ""
    
    // For voice playback
    let tts = AVSpeechSynthesizer()
    
    var apiKey: String

    let model: String
    let temperature: Double
    let maxTokens: Int

    init(
        apiKey: String,
        model: String = "gpt-4o",
        temperature: Double = 0.7,
        maxTokens: Int = 384
    ) {
        self.apiKey = apiKey
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
    
    func sendUserMessage() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        input = ""
        messages.append(Message(role: .user, content: trimmed))
        streamingAssistantReply = ""
        await streamChatCompletion()
    }
    
    func resetConversation() {
        messages = [Message(role: .system, content: "You are a helpful assistant.")]
        streamingAssistantReply = ""
        errorMessage = nil
        input = ""
    }

    func streamChatCompletion() async {
        isLoading = true
        errorMessage = nil
        streamingAssistantReply = ""

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            errorMessage = "Failed to make API url"; isLoading = false; return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let reqBody = OpenAIChatRequest(
            model: model,
            messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) },
            stream: true,
            temperature: temperature,
            max_tokens: maxTokens
        )
        do {
            request.httpBody = try JSONEncoder().encode(reqBody)
        } catch {
            errorMessage = "Failed to encode body: \(error.localizedDescription)"
            isLoading = false
            return
        }
        // Use async sequence to stream
        streamingAssistantReply = ""
        do {
            let (inputStream, response) = try await URLSession.shared.bytes(for: request)
            guard let httpResp = response as? HTTPURLResponse else {
                errorMessage = "Bad API response"
                isLoading = false
                return
            }

            if httpResp.statusCode != 200 {
                let data = try await inputStream.collect(upTo: 4096)
                if let errStr = String(bytes: data, encoding: .utf8) {
                    errorMessage = "API Error: \(errStr)"
                } else {
                    errorMessage = "API error code: \(httpResp.statusCode)"
                }
                isLoading = false
                return
            }

            var assistantReply = ""
            for try await lineData in inputStream.lines {
                let line = String(decoding: lineData, as: UTF8.self)
                // Each streaming line looks like: data: {...json...}
                guard line.hasPrefix("data: ") else { continue }
                let jsonPart = line.replacingOccurrences(of: "data: ", with: "")
                if jsonPart == "[DONE]" { break }
                guard let d = jsonPart.data(using: .utf8) else { continue }
                if let resp = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: d),
                   let delta = resp.choices.first?.delta {
                    if let token = delta.content {
                        assistantReply.append(token)
                        await MainActor.run { self.streamingAssistantReply = assistantReply }
                    }
                }
            }
            // Finalize message
            messages.append(Message(role: .assistant, content: assistantReply))
            isLoading = false
            // Speak the response
            speakText(assistantReply)
        } catch {
            errorMessage = "Streaming failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func speakText(_ text: String) {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = .init(language: "en-US")
        tts.speak(utterance)
    }
}

// MARK: - Main Chat View

struct OpenAIStreamingChatView: View {
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @StateObject private var chatService = OpenAIStreamingChatService(apiKey: "")
    @FocusState private var inputIsFocused: Bool
    @State private var manualAPIKey: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if chatService.messages.count < 2 {
                    Text("👋 Welcome! Start a conversation with GPT-4o.")
                        .padding(.top, 32)
                }
                ScrollViewReader { proxy in
                    ScrollView {
                        // Conversation
                        VStack(spacing: 8) {
                            ForEach(chatService.messages) { msg in
                                MessageBubble(message: msg, own: msg.role == .user)
                            }
                            // Streaming assistant reply (live typing)
                            if chatService.isLoading, !chatService.streamingAssistantReply.isEmpty {
                                MessageBubble(message: Message(role: .assistant, content: chatService.streamingAssistantReply), own: false, isStreaming: true)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.bottom, 6)
                        .onChange(of: chatService.messages.count) {
                            withAnimation { proxy.scrollTo("lastBubble", anchor: .bottom) }
                        }
                    }
                }
                HStack {
                    TextField("Type your message", text: $chatService.input, axis: .vertical)
                        .focused($inputIsFocused)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1...4)
                        .onSubmit { Task { await chatService.sendUserMessage() } }
                        .disabled(chatService.isLoading || chatService.apiKey.isEmpty)
                    if chatService.isLoading {
                        ProgressView()
                    }
                    Button {
                        Task { await chatService.sendUserMessage(); inputIsFocused = true }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(chatService.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .disabled(chatService.isLoading || chatService.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal).padding(.bottom, 10)
            }
            .navigationTitle("Live ChatGPT + Voice")
            .safeAreaInset(edge: .bottom, spacing: 0) { }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        chatService.resetConversation()
                    }
                }
            }
            .alert(isPresented: .constant(chatService.errorMessage != nil)) {
                Alert(title: Text("Error"), message: Text(chatService.errorMessage ?? ""), dismissButton: .default(Text("OK"), action: {
                    chatService.errorMessage = nil
                }))
            }
            .onAppear {
                if !apiKey.isEmpty, chatService.apiKey != apiKey {
                    chatService.apiKey = apiKey
                }
            }
            .sheet(isPresented: .constant(chatService.apiKey.isEmpty)) {
                VStack(spacing: 32) {
                    Text("Enter OpenAI API Key")
                        .font(.title).padding(.top, 32)
                    SecureField("sk-...", text: $manualAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .padding()
                    Button("Save & Start") {
                        if manualAPIKey.starts(with: "sk-") && manualAPIKey.count > 30 {
                            apiKey = manualAPIKey
                            chatService.apiKey = manualAPIKey
                        }
                    }
                    .padding()
                }
                .presentationDetents([.medium])
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let own: Bool
    var isStreaming: Bool = false

    var body: some View {
        HStack(alignment: .bottom) {
            if own { Spacer() }
            VStack(alignment: own ? .trailing : .leading, spacing: 2) {
                Text(message.role.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(message.content)
                    .font(.body)
                    .padding(10)
                    .background(own ? Color.blue.opacity(0.2) : Color.gray.opacity(0.16))
                    .cornerRadius(14)
                    .overlay(
                        isStreaming ? ProgressView().scaleEffect(0.5).padding(.trailing, 4) : nil,
                        alignment: .trailing
                    )
            }
            .padding(.horizontal, 6)
            if !own { Spacer() }
        }
        .id("lastBubble")
        .transition(.move(edge: own ? .trailing : .leading))
    }
}

// MARK: - Preview

struct OpenAIStreamingChatView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAIStreamingChatView()
    }
}
