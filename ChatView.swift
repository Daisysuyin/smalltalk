// === ChatView.swift ===

import SwiftUI

struct ChatView: View {

    @State private var viewModel = ChatViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ModelStatusBanner(
                    state: viewModel.engine.modelState,
                    onRetry: { Task { await viewModel.onAppear() } }
                )
                messageList
                Divider()
                inputBar
            }
            .navigationTitle("Smalltalk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    modelIndicator
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    clearButton
                }
            }
            .task {
                await viewModel.onAppear()
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error).id("error")
                    }
                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            // defaultScrollAnchor starts scroll at bottom
            // Only auto-scroll when user sends a new message
            // This allows free scrolling up through history
            .defaultScrollAnchor(.bottom)
            .onChange(of: viewModel.isLoading) {
                if viewModel.isLoading {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                viewModel.engine.modelState.isReady ? "Message Llama…" : "Waiting for Ollama…",
                text: $viewModel.inputText,
                axis: .vertical
            )
            .lineLimit(1...4)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .focused($inputFocused)
            .onSubmit { sendMessage() }
            .submitLabel(.send)

            Button(action: sendMessage) {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.white).frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 36, height: 36)
                .background(viewModel.canSend ? Color.accentColor : Color.gray.opacity(0.4))
                .clipShape(Circle())
            }
            .disabled(!viewModel.canSend)
            .animation(.easeInOut(duration: 0.15), value: viewModel.canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.background)
    }

    // MARK: - Toolbar

    private var modelIndicator: some View {
        HStack(spacing: 5) {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundStyle(
                    viewModel.engine.modelState.isReady  ? Color.green  :
                    viewModel.engine.modelState.isFailed ? Color.red    : Color.orange
                )
            Text("Llama 3.2")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var clearButton: some View {
        Button(action: viewModel.clearChat) {
            Image(systemName: "trash").foregroundStyle(.red.opacity(0.8))
        }
        .disabled(viewModel.messages.isEmpty)
    }

    private func sendMessage() {
        guard viewModel.canSend else { return }
        inputFocused = false
        Task { await viewModel.sendMessage() }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}

// MARK: - ModelStatusBanner

struct ModelStatusBanner: View {
    let state: ModelState
    let onRetry: () -> Void

    var body: some View {
        if !state.isReady {
            HStack(spacing: 10) {
                switch state {
                case .loading:
                    ProgressView().progressViewStyle(.circular).scaleEffect(0.8)
                case .failed:
                    Button("Retry", action: onRetry)
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                default:
                    EmptyView()
                }
                Text(state.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
        }
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: Message
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            ZStack(alignment: .bottomTrailing) {
                Text(message.content.isEmpty ? " " : message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .textSelection(.enabled)
                if message.isStreaming {
                    TypingCursor().padding([.bottom, .trailing], 8)
                }
            }
            if !isUser { Spacer(minLength: 60) }
        }
        .animation(.easeInOut(duration: 0.1), value: message.content)
    }
}

// MARK: - TypingCursor

struct TypingCursor: View {
    @State private var visible = true
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .frame(width: 3, height: 14)
            .foregroundStyle(.secondary.opacity(0.6))
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                    visible = false
                }
            }
    }
}

// MARK: - ErrorBanner

struct ErrorBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(message).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    ChatView()
}
