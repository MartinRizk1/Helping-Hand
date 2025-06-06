import SwiftUI
import Combine

struct ChatView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var locationViewModel: LocationViewModel
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool
    @StateObject private var speechService = SpeechRecognitionService.shared
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            // Messages list
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                                .onTapGesture {
                                    if message.locationResults != nil {
                                        chatViewModel.selectedMessage = message
                                    }
                                }
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
            
            // Typing indicator
            if chatViewModel.isTyping {
                HStack {
                    Text("Helper is typing")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Animated dots
                    TypingIndicator()
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
            }
            
            // Input area
            HStack {
                // Voice input button
                Button(action: startVoiceInput) {
                    Image(systemName: speechService.isRecording ? "waveform.circle.fill" : "mic.fill")
                        .font(.system(size: 20))
                        .padding(8)
                        .foregroundColor(speechService.isRecording ? .red : Color("AccentColor"))
                        .background(
                            Circle()
                                .fill(Color("BackgroundColor").opacity(0.3))
                        )
                        .animation(.spring(), value: speechService.isRecording)
                }
                
                TextField("Ask me anything...", text: $messageText)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color("BackgroundColor").opacity(0.2))
                    )
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                    .overlay(
                        // Show recognized speech text as overlay
                        Group {
                            if speechService.isRecording && !speechService.recognizedText.isEmpty {
                                Text(speechService.recognizedText)
                                    .padding(.leading, 8)
                                    .foregroundColor(.gray)
                            }
                        }
                    )
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                        Color("AccentColor").opacity(0.3) : 
                                        Color("AccentColor"))
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .onAppear {
            setupSpeechRecognition()
        }
    }
    
    private func setupSpeechRecognition() {
        // Request authorization when the view appears
        speechService.requestAuthorization()
        
        // Subscribe to recognized text
        speechService.recognizedTextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recognizedText in
                guard let self = self, !recognizedText.isEmpty else { return }
                self.messageText = recognizedText
                
                // Auto-send the message after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.sendMessage()
                }
            }
            .store(in: &cancellables)
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        chatViewModel.sendMessage(trimmedMessage)
        messageText = ""
        isInputFocused = false
    }
    
    private func startVoiceInput() {
        // Toggle recording state
        speechService.startRecording()
        
        // Clear the text field when starting recording
        if speechService.isRecording {
            messageText = ""
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @State private var showTime = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
                
                // Timestamp for user message (right side)
                if showTime {
                    Text(formattedTime)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                // Character icon for assistant messages
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color("AccentColor"))
                    )
                    .frame(width: 30, height: 30)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 5) {
                // Message bubble
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        // Custom bubble shape
                        BubbleShape(isUser: message.isUser)
                            .fill(message.isUser ? Color("AccentColor") : Color("BubbleColor"))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .foregroundColor(message.isUser ? .white : .black)
                
                // Location results if available
                if let locations = message.locationResults, !locations.isEmpty {
                    LocationResultsView(results: locations)
                }
            }
            .padding(.horizontal, 4)
            
            if !message.isUser {
                Spacer()
                
                // Timestamp for assistant message (right side)
                if showTime {
                    Text(formattedTime)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Make the entire row tappable
        .onTapGesture {
            withAnimation(.spring()) {
                showTime.toggle()
            }
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}

// Custom bubble shape with tail
struct BubbleShape: Shape {
    var isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 10
        
        var path = Path()
        
        if isUser {
            // User bubble with tail on right
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
            
            // Add tail on right side
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius - tailSize))
            path.addLine(to: CGPoint(x: rect.maxX + tailSize, y: rect.maxY - radius))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                        radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                        radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.closeSubpath()
        } else {
            // Assistant bubble with tail on left
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            
            // Add tail on left side
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
            path.addLine(to: CGPoint(x: rect.minX - tailSize, y: rect.maxY - radius))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius - tailSize))
            
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                        radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                        radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.closeSubpath()
        }
        
        return path
    }
}

struct TypingIndicator: View {
    @State private var showFirstDot = false
    @State private var showSecondDot = false
    @State private var showThirdDot = false
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .frame(width: 5, height: 5)
                .scaleEffect(showFirstDot ? 1 : 0.5)
                .opacity(showFirstDot ? 1 : 0.5)
            Circle()
                .frame(width: 5, height: 5)
                .scaleEffect(showSecondDot ? 1 : 0.5)
                .opacity(showSecondDot ? 1 : 0.5)
            Circle()
                .frame(width: 5, height: 5)
                .scaleEffect(showThirdDot ? 1 : 0.5)
                .opacity(showThirdDot ? 1 : 0.5)
        }
        .foregroundColor(.gray)
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        // First dot
        withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            showFirstDot = true
        }
        
        // Second dot (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                showSecondDot = true
            }
        }
        
        // Third dot (delayed more)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                showThirdDot = true
            }
        }
    }
}
