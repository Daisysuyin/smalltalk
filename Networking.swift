// === Networking.swift ===
// Connects to Ollama running locally on the Mac
// Ollama must be running: https://ollama.com/download
// Model must be pulled: ollama pull llama3.2
//
// Ollama runs on http://localhost:11434
// The iOS Simulator shares the Mac's localhost — no special config needed

import Foundation

@Observable
final class InferenceEngine {

    // MARK: - State

    var modelState: ModelState = .idle

    private let baseURL  = "http://localhost:11434"
    private let model    = "llama3.2"

    // MARK: - Load
    // Checks if Ollama is running and the model is available

    @MainActor
    func loadModelIfNeeded() async {
        guard !modelState.isReady else { return }
        modelState = .loading

        do {
            // Ping Ollama's tags endpoint to check it's running and model exists
            guard let url = URL(string: "\(baseURL)/api/tags") else {
                modelState = .failed("Invalid Ollama URL")
                return
            }

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else {
                modelState = .failed("Ollama is not running. Start it with: ollama serve")
                return
            }

            // Check model is available
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let models = json?["models"] as? [[String: Any]] ?? []
            let available = models.compactMap { $0["name"] as? String }
            let hasModel = available.contains(where: { $0.hasPrefix("llama3.2") })

            if !hasModel {
                modelState = .failed("Run: ollama pull llama3.2")
                return
            }

            modelState = .ready
            print("✅ Ollama ready with \(model)")

        } catch {
            modelState = .failed("Ollama not running. Open Terminal and run: ollama serve")
        }
    }

    // MARK: - Generate (streaming)
    // Uses Ollama's /api/chat endpoint with stream: true

    @MainActor
    func generate(messages: [Message]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(self.baseURL)/api/chat") else {
                        continuation.finish(throwing: InferenceError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    // Build message array for Ollama
                    let ollamaMessages = messages.map { msg in
                        ["role": msg.role.rawValue, "content": msg.content]
                    }

                    let body: [String: Any] = [
                        "model": self.model,
                        "messages": ollamaMessages,
                        "stream": true
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let http = response as? HTTPURLResponse,
                          (200...299).contains(http.statusCode) else {
                        throw InferenceError.badResponse
                    }

                    // Parse streaming NDJSON from Ollama
                    // Each line is a JSON object: {"message":{"content":"token"},"done":false}
                    for try await line in asyncBytes.lines {
                        guard !line.isEmpty,
                              let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else { continue }

                        if let message = json["message"] as? [String: Any],
                           let content = message["content"] as? String,
                           !content.isEmpty {
                            continuation.yield(content)
                        }

                        if let done = json["done"] as? Bool, done {
                            break
                        }
                    }

                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Errors

enum InferenceError: LocalizedError {
    case modelNotLoaded
    case invalidURL
    case badResponse

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "Model is not loaded yet."
        case .invalidURL:     return "Invalid Ollama URL."
        case .badResponse:    return "Bad response from Ollama."
        }
    }
}
