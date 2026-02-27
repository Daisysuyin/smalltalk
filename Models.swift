// === Models.swift ===

import Foundation

enum MessageRole: String, Codable {
    case user      = "user"
    case assistant = "assistant"
    case system    = "system"
}

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    var role: MessageRole
    var content: String
    let timestamp: Date
    var isStreaming: Bool

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id          = id
        self.role        = role
        self.content     = content
        self.timestamp   = timestamp
        self.isStreaming = isStreaming
    }
}

enum ModelState: Equatable {
    case idle
    case loading
    case ready
    case failed(String)

    var statusText: String {
        switch self {
        case .idle:             return "Not connected"
        case .loading:          return "Connecting to Ollama…"
        case .ready:            return "Llama 3.2 · Ollama"
        case .failed(let msg):  return msg
        }
    }

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}
