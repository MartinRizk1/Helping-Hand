import SwiftUI
import Combine

struct ChatView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                                .onTapGesture {
                                    if message.locationResults != nil {
                                        chatViewModel.selectMessage(message)
                                    }
                                }
                        }
                        
                        if chatViewModel.isTyping {
                            HStack(alignment: .bottom, spacing: 2) {
                                DotView()
                                DotView().delay(0.2)
                                DotView().delay(0.4)
                            }
                            .padding(.leading, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .onChange(of: chatViewModel.messages.count) { _ in
                    if let lastMessage = chatViewModel.messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            VStack(spacing: 0) {
                Divider()
                HStack(alignment: .bottom) {
                    if #available(iOS 16.0, *) {
                        TextField("Type a message...", text: $messageText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .focused($isInputFocused)
                            .disabled(chatViewModel.isTyping)
                    } else {
                        TextEditor(text: $messageText)
                            .frame(height: min(100, max(40, CGFloat(messageText.count / 35) * 20)))
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .focused($isInputFocused)
                            .disabled(chatViewModel.isTyping)
                    }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty || chatViewModel.isTyping)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .background(Color(.systemBackground))
            }
        }
        .alert("Error", isPresented: .constant(chatViewModel.error != nil)) {
            Button("OK") {
                chatViewModel.clearError()
            }
        } message: {
            if let error = chatViewModel.error {
                Text(error)
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        chatViewModel.sendMessage(trimmedMessage)
        messageText = ""
        isInputFocused = false
    }
}

struct DotView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.5))
            .frame(width: 6, height: 6)
            .offset(y: isAnimating ? -5 : 0)
            .animation(
                Animation.easeInOut(duration: 0.5)
                    .repeatForever(),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
    
    func delay(_ delay: Double) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                isAnimating = true
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            HStack {
                if message.isUser {
                    Spacer(minLength: 50)
                }
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(20)
                
                if !message.isUser {
                    Spacer(minLength: 50)
                }
            }
            
            if let results = message.locationResults {
                LocationResultsView(results: results)
                    .padding(.top, 4)
            }
        }
    }
}
