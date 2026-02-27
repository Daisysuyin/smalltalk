# Smalltalk

A production-ready iOS chat app that runs a large language model **entirely on-device** via [Ollama](https://ollama.com) — no API keys, no cloud, no per-message cost.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Screenshots

> Chat interface with streaming responses, model status indicator, and conversation history.

---

## Features

- 💬 Real-time streaming responses token-by-token
- 🔒 100% on-device inference — no data leaves your Mac
- 🆓 Zero cost — no API fees, no subscriptions
- 📜 Full conversation history with free scrolling
- 🔄 Auto-reconnect with retry on Ollama connection failure
- 🏗️ Clean MVVM architecture with Swift 5.9 `@Observable`
- 📱 iOS 17+ SwiftUI, works in Simulator (Intel + Apple Silicon)

---

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 15+ |
| iOS | 17+ |
| Swift | 5.9+ |
| [Ollama](https://ollama.com) | Latest |
| macOS | 13+ |

---

## Setup

### 1. Install Ollama

Download and install from [ollama.com/download](https://ollama.com/download).

### 2. Pull the model

```bash
ollama pull llama3.2
```

### 3. Start Ollama

```bash
ollama serve
```

Keep this running while using the app.

### 4. Clone the repo

```bash
git clone https://github.com/Daisysuyin/smalltalk.git
cd smalltalk
```

### 5. Open in Xcode

```bash
open Smalltalk.xcodeproj
```

### 6. Run

Select a Simulator (iPhone 15 or later) and press **Cmd+R**.

---

## Architecture

```
Smalltalk/
├── SmalltalkApp.swift      # App entry point
├── Models.swift            # Data models (Message, ModelState)
├── Networking.swift        # Ollama API client, streaming engine
├── ChatViewModel.swift     # MVVM ViewModel, business logic
└── ChatView.swift          # SwiftUI views and components
```

### Key design decisions

- **MVVM** — `ChatViewModel` owns all state, `ChatView` is purely reactive
- **AsyncThrowingStream** — streaming tokens from Ollama via NDJSON
- **@Observable** — Swift 5.9 observation macro, no `@Published` boilerplate
- **No third-party dependencies** — pure Swift + Foundation + SwiftUI

---

## How It Works

```
User types message
       ↓
ChatViewModel.sendMessage()
       ↓
InferenceEngine.generate()
       ↓
POST http://localhost:11434/api/chat  (Ollama)
       ↓
NDJSON stream → AsyncThrowingStream<String>
       ↓
Tokens appended to assistant message in real time
       ↓
SwiftUI renders each token as it arrives
```

---

## Changing the Model

In `Networking.swift`, update the `model` property:

```swift
private let model = "llama3.2"       // default
private let model = "llama3.2:1b"    // faster, smaller
private let model = "mistral"        // alternative
private let model = "codellama"      // code focused
```

Then pull the new model:

```bash
ollama pull mistral
```

---

## Future Improvements

- [ ] Persist conversation history across app launches
- [ ] Support multiple conversation threads
- [ ] Model selector UI (switch models in-app)
- [ ] Copy message to clipboard
- [ ] Share conversation as text
- [ ] iPad and macOS support
- [ ] System prompt customization

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Acknowledgements

- [Ollama](https://ollama.com) — local LLM runtime
- [Meta Llama 3.2](https://llama.meta.com) — open source language model
