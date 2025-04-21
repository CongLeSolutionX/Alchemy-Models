//
//  OpenAIChatAPIDemoView_Vietnamize_Version_V4.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

import SwiftUI
import Combine
import Speech
import AVFoundation

// MARK: ­– Models

enum ChatRole: String, Codable {
    case system, user, assistant
}

struct Message: Identifiable, Codable, Hashable {
  let id: UUID
  let role: ChatRole
  let content: String
  let timestamp: Date

  init(role: ChatRole, content: String, timestamp: Date = .now, id: UUID = UUID()) {
    self.id = id; self.role = role; self.content = content; self.timestamp = timestamp
  }

  static func system(_ text: String)    -> Message { .init(role: .system,    content: text) }
  static func user(_ text: String)      -> Message { .init(role: .user,      content: text) }
  static func assistant(_ text: String) -> Message { .init(role: .assistant, content: text) }
}

struct Conversation: Identifiable, Codable, Hashable {
  let id: UUID
  var title: String
  var messages: [Message]
  var createdAt: Date

  init(id: UUID = .init(),
       title: String = "",
       messages: [Message] = [],
       createdAt: Date = .now)
  {
    self.id = id
    self.messages = messages
    self.createdAt = createdAt
    if title.isEmpty {
      // first user message or fallback
      let firstUser = messages.first(where: { $0.role == .user })?.content ?? "Chat"
      self.title = String(firstUser.prefix(32))
    } else {
      self.title = title
    }
  }
}

// MARK: ­– Backend Protocols

protocol ChatBackend {
  func streamChat(
    messages: [Message],
    systemPrompt: String,
    completion: @escaping (Result<String, Error>) -> Void
  )
}

struct MockChatBackend: ChatBackend {
  let replies = [
    "Chắc chắn rồi!",
    "Để tôi suy nghĩ…",
    "Bạn có thể nói rõ hơn?",
    "Đây là gợi ý của tôi.",
    "Hoàn toàn được!",
    "Tôi đang xem lại…"
  ]

  func streamChat(
    messages: [Message],
    systemPrompt: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      let reply = replies.randomElement()!
      completion(.success(reply))
    }
  }
}

final class RealOpenAIBackend: ChatBackend {
  let apiKey: String, model: String, temperature: Double, maxTokens: Int

  init(apiKey: String,
       model: String,
       temperature: Double,
       maxTokens: Int)
  {
    self.apiKey = apiKey
    self.model = model
    self.temperature = temperature
    self.maxTokens = maxTokens
  }

  func streamChat(
    messages: [Message],
    systemPrompt: String,
    completion: @escaping (Result<String, Error>) -> Void)
  {
    var all = messages
    if !systemPrompt.isEmpty {
      all.insert(.system(systemPrompt), at: 0)
    }
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
      return completion(.failure(NSError(domain: "InvalidURL", code: 0)))
    }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    struct Payload: Encodable {
      let model: String
      let messages: [[String:String]]
      let temperature: Double
      let max_tokens: Int
    }

    let body = Payload(
      model:     model,
      messages:  all.map { ["role": $0.role.rawValue, "content": $0.content] },
      temperature: temperature,
      max_tokens:  maxTokens
    )

    do {
      req.httpBody = try JSONEncoder().encode(body)
    } catch {
      return completion(.failure(error))
    }

    URLSession.shared.dataTask(with: req) { data, _, error in
      if let e = error {
        return completion(.failure(e))
      }
      guard let d = data else {
        return completion(.failure(NSError(domain: "NoData", code: 1)))
      }
      do {
        struct Resp: Decodable {
          struct Choice: Decodable {
            struct Msg: Decodable { let content: String }
            let message: Msg
          }
          let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(Resp.self, from: d)
        let text = decoded.choices.first?.message.content ?? "Không có phản hồi."
        DispatchQueue.main.async { completion(.success(text)) }
      } catch {
        DispatchQueue.main.async { completion(.failure(error)) }
      }
    }
    .resume()
  }
}

// MARK: ­– Speech Recognizer (Vietnamese)

final class SpeechRecognizer: NSObject, ObservableObject {
  @Published var transcript = ""
  @Published var isRecording = false
  @Published var errorMessage: String?

  var onFinalTranscription: ((String) -> Void)?

  private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
  private let audioEngine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private let silenceTimeout: TimeInterval = 1.5
  private var silenceWork: DispatchWorkItem?

  func requestAuthorization(_ completion: @escaping (Bool)->Void) {
    SFSpeechRecognizer.requestAuthorization { status in
      let ok = status == .authorized
      DispatchQueue.main.async {
        if !ok { self.errorMessage = "Cần quyền truy cập mic." }
        completion(ok)
      }
    }
  }

  func startRecording() throws {
    errorMessage = nil
    transcript = ""
    isRecording = true

    // cancel old tasks
    task?.cancel(); task=nil
    request?.endAudio(); request=nil
    silenceWork?.cancel()

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
    try session.setActive(true)

    let req = SFSpeechAudioBufferRecognitionRequest()
    req.shouldReportPartialResults = true
    req.taskHint = .dictation
    request = req

    guard let rec = recognizer, rec.isAvailable else {
      errorMessage="Speech recognizer unavailable."
      isRecording=false
      return
    }

    task = rec.recognitionTask(with: req) { [weak self] result, err in
      guard let self = self else { return }
      if let r = result {
        DispatchQueue.main.async {
          self.transcript = r.bestTranscription.formattedString
        }
        if r.isFinal {
          self.finish(self.transcript)
        } else {
          self.scheduleSilence()
        }
      }
      if let e = err {
        DispatchQueue.main.async {
          self.errorMessage = e.localizedDescription
          self.stopRecording()
        }
      }
    }

    let input = audioEngine.inputNode
    let fmt = input.outputFormat(forBus: 0)
    input.removeTap(onBus: 0)
    input.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in
      req.append(buf)
    }

    audioEngine.prepare()
    try audioEngine.start()
  }

  private func scheduleSilence() {
    silenceWork?.cancel()
    let wi = DispatchWorkItem { [weak self] in
      guard let self = self, self.isRecording else { return }
      self.finish(self.transcript)
    }
    silenceWork = wi
    DispatchQueue.main.asyncAfter(deadline: .now() + silenceTimeout, execute: wi)
  }

  private func finish(_ text: String) {
    onFinalTranscription?(text)
    stopRecording()
  }

  func stopRecording() {
    if audioEngine.isRunning {
      audioEngine.inputNode.removeTap(onBus: 0)
      audioEngine.stop()
    }
    request?.endAudio()
    task?.cancel()
    isRecording=false
    silenceWork?.cancel()
    request=nil; task=nil
    try? AVAudioSession.sharedInstance().setActive(false)
  }
}

// MARK: ­– ViewModel

@MainActor
final class ChatStore: ObservableObject {
  // persisted under “ChatHistory”
  @Published var conversations: [Conversation] = [] {
    didSet { saveToDisk() }
  }

  @Published var current: Conversation = Conversation(messages: [
    .system("Bạn là trợ lý thông minh, trả lời ngắn gọn bằng tiếng Việt.")
  ])

  @Published var input = ""
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var systemPrompt: String = "Bạn là trợ lý thông minh..."
  @Published var useMock = true
  @Published var ttsEnabled = false
  @Published var ttsRate: Float = 0.5
  @Published var ttsVoice: String = "vi-VN"

  private(set) var backend: ChatBackend = MockChatBackend()
  private let ttsSynth = AVSpeechSynthesizer()

  @AppStorage("openai_api_key") private var apiKey = ""

  init() {
    self.loadFromDisk()
  }

  func setBackend(_ b: ChatBackend, mock: Bool) {
    backend = b; useMock = mock
  }

  func resetChat() {
    ttsSynth.stopSpeaking(at: .immediate)
    current = Conversation(messages: [.system(systemPrompt)])
    input = ""
  }

  func sendMessage(_ text: String) {
    let txt = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !txt.isEmpty else { return }
    ttsSynth.stopSpeaking(at: .word)
    let userMsg = Message.user(txt)
    current.messages.append(userMsg)
    input = ""
    isLoading = true

    backend.streamChat(messages: current.messages,
                       systemPrompt: systemPrompt)
    { [weak self] res in
      guard let self = self else { return }
      self.isLoading = false
      switch res {
      case .success(let reply):
        let msg = Message.assistant(reply)
        self.current.messages.append(msg)
        self.upsertConversation()
        if self.ttsEnabled {
          self.speak(reply)
        }
      case .failure(let err):
        self.errorMessage = err.localizedDescription
      }
    }
  }

  func speak(_ text: String) {
    do {
      let s = AVAudioSession.sharedInstance()
      try s.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
      try s.setActive(true)
    } catch {
      print("AudioSession error:", error)
    }
    let u = AVSpeechUtterance(string: text)
    u.rate = ttsRate
    u.voice = AVSpeechSynthesisVoice(language: ttsVoice)
    ttsSynth.speak(u)
  }

  func deleteConversation(id: UUID) {
    conversations.removeAll { $0.id == id }
  }

  func selectConversation(_ c: Conversation) {
    ttsSynth.stopSpeaking(at: .immediate)
    current = c
  }

  func renameConversation(_ c: Conversation, to newTitle: String) {
    if let idx = conversations.firstIndex(where: { $0.id == c.id }) {
      var copy = conversations[idx]
      copy.title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
      conversations[idx] = copy
      if current.id == copy.id {
        current.title = copy.title
      }
    }
  }

  func clearHistory() {
    conversations.removeAll()
  }

  // MARK: Persistence

  private func loadFromDisk() {
    guard
      let data = UserDefaults.standard.data(forKey: "ChatHistory"),
      let list = try? JSONDecoder().decode([Conversation].self, from: data)
    else { return }
    self.conversations = list
  }

  private func saveToDisk() {
    guard let data = try? JSONEncoder().encode(conversations) else { return }
    UserDefaults.standard.set(data, forKey: "ChatHistory")
  }

  private func upsertConversation() {
    if let idx = conversations.firstIndex(where: { $0.id == current.id }) {
      conversations[idx] = current
    } else if current.messages.count > 1 {
      conversations.insert(current, at: 0)
    }
  }

  // Voice commands (English) for demo
  func attachRecognizer(_ sr: SpeechRecognizer) {
    sr.onFinalTranscription = { [weak self] text in
      self?.handleVoiceCommand(text.lowercased())
    }
  }
  private func handleVoiceCommand(_ cmd: String) {
    switch cmd {
    case _ where cmd.contains("new chat"):
      resetChat()
    case _ where cmd.contains("tts on"):
      ttsEnabled = true
    case _ where cmd.contains("tts off"):
      ttsEnabled = false
    case _ where cmd.contains("use real"):
      guard !apiKey.isEmpty else { return }
      let real = RealOpenAIBackend(
        apiKey: apiKey,
        model: systemPrompt,
        temperature: 0.7,
        maxTokens: 384
      )
      setBackend(real, mock: false)
    case _ where cmd.contains("use mock"):
      setBackend(MockChatBackend(), mock: true)
    default:
      sendMessage(cmd)
    }
  }
}

// MARK: ­– Subviews

struct MessageBubble: View {
  let msg: Message
  var isOwn: Bool { msg.role == .user }

  var bubbleColor: Color { isOwn ? .blue.opacity(0.2) : .gray.opacity(0.1) }
  var textColor:   Color { isOwn ? .blue : .primary }

  var body: some View {
    HStack {
      if isOwn { Spacer(minLength: 20) }
      VStack(alignment: isOwn ? .trailing : .leading, spacing: 4) {
        Text(msg.timestamp, style: .time)
          .font(.caption2).foregroundColor(.secondary)
        Text(msg.content)
          .padding(10)
          .background(bubbleColor)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .foregroundColor(textColor)
      }
      if !isOwn { Spacer(minLength: 20) }
    }
    .contextMenu {
      Button("Copy") { UIPasteboard.general.string = msg.content }
      Button("Đọc to") { /* inject speak in parent */ }
      ShareLink(item: msg.content)
    }
  }
}

struct ChatInputBar: View {
  @Binding var text: String
  @ObservedObject var store: ChatStore
  @ObservedObject var speech: SpeechRecognizer
  @FocusState var isFocused: Bool
  @GestureState private var pressing = false

  var body: some View {
    HStack(spacing: 8) {
      TextField("Gõ hoặc giữ để nói…",
                text: $text,
                axis: .vertical)
      .focused($isFocused)
      .lineLimit(1...4)
      .padding(8)
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3)))
      .disabled(store.isLoading)

      micButton
      sendButton
    }
    .padding(.horizontal)
    .padding(.vertical, 6)
    .background(.thinMaterial)
    .animation(.easeInOut, value: pressing)
  }

  private var micButton: some View {
    let longPress = LongPressGesture(minimumDuration: 0.2)
      .updating($pressing) { v, s, _ in s = v }
      .onEnded { _ in
        speech.stopRecording()
        if !speech.transcript.isEmpty {
          store.sendMessage(speech.transcript)
        }
      }

    return Image(systemName: speech.isRecording ? "mic.fill" : "mic.circle")
      .font(.system(size: 24))
      .foregroundColor(speech.isRecording ? .red : .blue)
      .gesture(
        longPress.onChanged { _ in
          guard !speech.isRecording else { return }
          isFocused = false
          speech.requestAuthorization { ok in
            if ok {
              try? speech.startRecording()
            }
          }
        }
      )
      .accessibilityLabel(speech.isRecording ? "Thả để gửi" : "Giữ để nói")
  }

  private var sendButton: some View {
    Button {
      store.sendMessage(text)
      text = ""
    } label: {
      Image(systemName: "paperplane.fill")
        .font(.system(size: 24))
        .rotationEffect(.degrees(45))
        .foregroundColor(text.trimmingCharacters(in: .whitespaces).isEmpty
                         ? .gray.opacity(0.5) : .blue)
    }
    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty
              || store.isLoading)
  }
}

struct SettingsSheet: View {
  @Binding var useMock: Bool
  @Binding var ttsEnabled: Bool
  @Binding var ttsRate: Float
  @Binding var ttsVoice: String

  @AppStorage("model_name") private var modelName = "gpt-4o"
  @AppStorage("temperature") private var temperature = 0.7
  @AppStorage("max_tokens") private var maxTokens = 384
  @AppStorage("openai_api_key") private var apiKey = ""

  let models = ["gpt-4o","gpt-4","gpt-3.5-turbo"]
  let voices = ["vi-VN","vi-VI", "en-US"]

  var onUpdate: (ChatBackend,Bool)->Void
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("Phản hồi âm thanh") {
          Toggle("Bật TTS", isOn: $ttsEnabled)
          HStack {
            Text("Tốc độ: \(ttsRate, specifier: "%.2f")")
            Slider(value: $ttsRate, in: 0.2...1.0)
          }
          Picker("Giọng nói:", selection: $ttsVoice) {
            ForEach(voices, id:\.self) { Text($0) }
          }
        }

        Section("Backend") {
          Toggle("Dùng mock (offline)", isOn: $useMock)
            .onChange(of: useMock) { _, v in updateBackend(mock: v) }
        }

        Section("OpenAI Config") {
          Picker("Model", selection: $modelName) {
            ForEach(models, id:\.self) { Text($0) }
          }
          .onChange(of: modelName) { _, _ in updateBackend() }

          Stepper("Temperature: \(temperature, specifier: "%.2f")",
                  value: $temperature, in: 0...1, step: 0.05)
            .onChange(of: temperature) { _,_ in updateBackend() }

          Stepper("Max Tokens: \(maxTokens)",
                  value: $maxTokens, in: 64...2048, step: 32)
            .onChange(of: maxTokens){_,_ in updateBackend()}

          if !useMock {
            SecureField("API Key", text: $apiKey)
              .autocapitalization(.none)
              .onChange(of: apiKey){_,_ in updateBackend()}
            if apiKey.isEmpty {
              Text("Nhập API key để dùng backend thật")
                .font(.footnote).foregroundColor(.secondary)
            }
          }
        }
      }
      .navigationTitle("Cài đặt")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Xong") { dismiss() }
        }
      }
    }
  }

  private func updateBackend(mock: Bool? = nil) {
    let shouldMock = mock ?? useMock
    if !shouldMock && !apiKey.isEmpty {
      onUpdate(
        RealOpenAIBackend(apiKey: apiKey,
                          model: modelName,
                          temperature: temperature,
                          maxTokens: maxTokens),
        false
      )
    } else {
      onUpdate(MockChatBackend(), true)
    }
  }
}

struct HistorySheet: View {
  @Binding var convos: [Conversation]
  var onDelete: (UUID)->Void
  var onSelect: (Conversation)->Void
  var onRename: (Conversation,String)->Void
  var onClear: ()->Void
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      VStack {
        if convos.isEmpty {
          Text("Chưa có chat nào").padding()
        } else {
          List {
            ForEach(convos) { convo in
              HStack {
                VStack(alignment:.leading) {
                  Text(convo.title)
                    .font(.headline)
                  Text(convo.createdAt, style: .date)
                    .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Menu {
                  Button("Mở") { onSelect(convo); dismiss() }
                  Button("Đổi tên") {
                    promptRename(convo)
                  }
                  Button("Chia sẻ") {
                    let txt = convo.messages
                      .map { "\($0.role.rawValue): \($0.content)" }
                      .joined(separator: "\n")
                    UIActivityViewController
                      .present(text: txt)
                  }
                } label: {
                  Image(systemName: "ellipsis.circle")
                }
              }
            }
            .onDelete { idx in
              idx.map { convos[$0].id }.forEach(onDelete)
            }
          }
        }
        Button("Xóa tất cả lịch sử") {
          onClear()
          dismiss()
        }
        .foregroundColor(.red)
        .padding()
      }
      .navigationTitle("Lịch sử Chat")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Đóng") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }

  private func promptRename(_ convo: Conversation) {
    let alert = UIAlertController(title: "Đổi tên",
                                  message: "Nhập tên mới",
                                  preferredStyle: .alert)
    alert.addTextField { tf in tf.text = convo.title }
    alert.addAction(.init(title: "Hủy", style: .cancel))
    alert.addAction(.init(title: "OK", style: .default) { _ in
      if let newTitle = alert.textFields?.first?.text {
        onRename(convo, newTitle)
      }
    })
      UIApplication.topController?.present(alert, animated: true)
  }
}

// MARK: ­– Main View

struct ChatDemoView: View {
  @StateObject var store = ChatStore()
  @StateObject var speech = SpeechRecognizer()
  @FocusState var inputFocused: Bool
  @AppStorage("openai_api_key") private var apiKey = ""

  @State private var showSettings = false
  @State private var showHistory  = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        header
        messagesScroll
        ChatInputBar(text: $store.input,
                     store: store,
                     speech: speech,
                     isFocused: _inputFocused)
      }
      .navigationBarHidden(true)
      .sheet(isPresented: $showSettings) {
        SettingsSheet(useMock: $store.useMock,
                      ttsEnabled: $store.ttsEnabled,
                      ttsRate: $store.ttsRate,
                      ttsVoice: $store.ttsVoice) { b,m in
          store.setBackend(b, mock: m)
        }
      }
      .sheet(isPresented: $showHistory) {
        HistorySheet(convos: $store.conversations,
                     onDelete: store.deleteConversation(id:),
                     onSelect: { c in store.selectConversation(c); showHistory=false },
                     onRename: store.renameConversation(_:to:),
                     onClear: store.clearHistory)
      }
      .alert("Lỗi", isPresented: .constant(store.errorMessage != nil)) {
        Button("OK") { store.errorMessage = nil }
      } message: {
        Text(store.errorMessage ?? "")
      }
      .onAppear {
        // if user already supplied key, switch to real
        if !apiKey.isEmpty && !store.useMock {
          let real = RealOpenAIBackend(
            apiKey: apiKey,
            model: store.systemPrompt,
            temperature: 0.7,
            maxTokens: 384
          )
          store.setBackend(real, mock: false)
        }
        speech.requestAuthorization { _ in }
        store.attachRecognizer(speech)
      }
    }
  }

  var header: some View {
    HStack {
      Text(store.current.title)
        .font(.headline)
        .lineLimit(1)
      Spacer()
      if store.ttsEnabled {
        Image(systemName: "speaker.wave.2.fill")
          .foregroundColor(.secondary)
      }
      Button(action: { showHistory = true }) {
        Image(systemName: "clock.arrow.circlepath")
      }
      .padding(.horizontal, 4)

      Button(action: { showSettings = true }) {
        Image(systemName: "gear")
      }
      .padding(.horizontal, 4)

      Button(action: { store.resetChat() }) {
        Image(systemName: "plus.circle")
      }
    }
    .padding()
    .background(.thinMaterial)
  }

  var messagesScroll: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(store.current.messages.filter { $0.role != .system }) { msg in
            MessageBubble(msg: msg)
              .id(msg.id)
          }
          if store.isLoading {
            ProgressView("Đang xử lý…")
          }
        }
        .padding(.horizontal)
      }
      .background(Color(.systemGroupedBackground))
      .onChange(of: store.current.messages.last?.id) { _, id in
        if let id = id {
          withAnimation {
            proxy.scrollTo(id, anchor: .bottom)
          }
        }
      }
    }
  }
}

// MARK: ­– Helpers

extension UIApplication {
  static var topController: UIViewController? {
    guard let win = shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first else {
      return nil
    }
    var top = win.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}

extension UIActivityViewController {
  static func present(text: String) {
    let act = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    UIApplication.topController?.present(act, animated: true)
  }
}

// MARK: ­– Preview

struct ChatDemoView_Previews: PreviewProvider {
  static var previews: some View {
    ChatDemoView()
      .preferredColorScheme(.light)
    ChatDemoView()
      .preferredColorScheme(.dark)
  }
}
