import SwiftUI
import Combine

struct ChatView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Dark Lamborghini-inspired background
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.1, blue: 0.1),
                    Color(red: 0.15, green: 0.15, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Premium Navigation Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("AI Assistant")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.yellow)
                            Text("Powered by ChatGPT")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        chatViewModel.locationServiceInstance.requestLocationPermission()
                    }) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.yellow)
                            .shadow(color: Color.yellow.opacity(0.5), radius: 4)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                // Chat Messages with premium styling
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 16) {
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
                        .padding(.horizontal, 20)
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
                
                // Premium message input area
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                    
                    HStack(alignment: .bottom, spacing: 16) {
                        if #available(iOS 16.0, *) {
                            TextField("Ask about restaurants, hotels, services...", text: $messageText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .focused($isInputFocused)
                                .disabled(chatViewModel.isTyping)
                        } else {
                            TextEditor(text: $messageText)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(height: min(100, max(50, CGFloat(messageText.count / 35) * 20)))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .focused($isInputFocused)
                                .disabled(chatViewModel.isTyping)
                        }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(messageText.isEmpty ? .gray : .yellow)
                                .shadow(color: messageText.isEmpty ? .clear : Color.yellow.opacity(0.5), radius: 8)
                        }
                        .disabled(messageText.isEmpty || chatViewModel.isTyping)
                        .scaleEffect(messageText.isEmpty ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        chatViewModel.sendMessage(trimmedMessage)
        messageText = ""
        isInputFocused = false
    }
    
    private func refreshLocation() {
        chatViewModel.locationServiceInstance.requestLocationPermission()
    }
}

struct DotView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.yellow.opacity(0.8))
            .frame(width: 8, height: 8)
            .offset(y: isAnimating ? -8 : 0)
            .animation(
                Animation.easeInOut(duration: 0.6)
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
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 12) {
            HStack {
                if message.isUser {
                    Spacer(minLength: 60)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.content)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: message.isUser ? 
                                    [Color.yellow, Color.orange] : 
                                    [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(message.isUser ? .black : .white)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    message.isUser ? 
                                        Color.clear : 
                                        Color.white.opacity(0.2), 
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: message.isUser ? 
                                Color.yellow.opacity(0.3) : 
                                Color.black.opacity(0.2), 
                            radius: 8, 
                            x: 0, 
                            y: 4
                        )
                    
                    if let results = message.locationResults {
                        LocationResultsView(results: results)
                            .padding(.top, 8)
                    }
                }
                
                if !message.isUser {
                    Spacer(minLength: 60)
                }
            }
        }
    }
}
