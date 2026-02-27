// === ChatViewModel.swift ===

import Foundation
import Observation

@Observable
final class ChatViewModel {

    var messages:     [Message] = []
    var inputText:    String    = ""
    var isLoading:    Bool      = false
    var errorMessage: String?

    let engine = InferenceEngine()

    @MainActor
    func onAppear() async {
        await engine.loadModelIfNeeded()
    }

    @MainActor
    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, engine.modelState.isReady else { return }

        messages.append(Message(role: .user, content: trimmed))
        inputText    = ""
        isLoading    = true
        errorMessage = nil

        var assistant = Message(role: .assistant, content: "", isStreaming: true)
        messages.append(assistant)
        let index = messages.count - 1

        let history = messages.filter { $0.id != assistant.id && !$0.isStreaming }

        do {
            for try await token in engine.generate(messages: history) {
                assistant.content += token
                messages[index]    = assistant
            }
            assistant.isStreaming = false
            messages[index]       = assistant
        } catch {
            messages.removeLast()
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearChat() {
        messages     = []
        errorMessage = nil
    }

    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isLoading
            && engine.modelState.isReady
    }
}
