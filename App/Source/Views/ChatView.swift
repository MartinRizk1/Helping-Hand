import SwiftUI
import Combine
import MapKit

struct ChatView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showMapView = false
    @State private var showLocationAlert = false
    @State private var animateTyping = false
    
    var body: some View {
        ZStack {
            // Professional gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.25),
                    Color(red: 0.15, green: 0.2, blue: 0.3),
                    Color.black.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced Professional Navigation Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer()
                    
                    // Enhanced AI Status Indicator
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .scaleEffect(animateTyping ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animateTyping)
                            
                            Text("AI Assistant")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.cyan.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: chatViewModel.locationServiceInstance.isUsingFallbackLocation ? "location.circle" : "location.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(chatViewModel.locationServiceInstance.isUsingFallbackLocation ? .orange : .green)
                            
                            Text(chatViewModel.locationServiceInstance.isUsingFallbackLocation ? "Dallas Area" : "Live Location")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Enhanced Controls
                    HStack(spacing: 12) {
                        // Map view toggle button
                        if chatViewModel.selectedMessage?.locationResults != nil {
                            Button(action: { showMapView = true }) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.cyan)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        
                        // Enhanced location permission button
                        Button(action: {
                            if chatViewModel.locationServiceInstance.authorizationStatus == .notDetermined {
                                chatViewModel.locationServiceInstance.requestLocationPermission()
                            } else if chatViewModel.locationServiceInstance.authorizationStatus == .denied {
                                showLocationAlert = true
                            } else {
                                chatViewModel.forceLocationRefresh()
                            }
                        }) {
                            Image(systemName: getLocationButtonIcon())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(getLocationButtonColor())
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(getLocationButtonColor().opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
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
                    
                    if #available(iOS 16.0, *) {
                        EnhancedInputArea(
                            messageText: $messageText,
                            isInputFocused: $isInputFocused,
                            sendAction: sendMessage,
                            isTyping: chatViewModel.isTyping
                        )
                    } else {
                        EnhancedInputArea_iOS15(
                            messageText: $messageText,
                            isInputFocused: $isInputFocused,
                            sendAction: sendMessage,
                            isTyping: chatViewModel.isTyping
                        )
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showMapView) {
            NavigationView {
                EnhancedMapView(
                    locationResults: chatViewModel.selectedMessage?.locationResults ?? [],
                    userLocation: chatViewModel.locationServiceInstance.currentLocation
                )
                .navigationTitle("Nearby Places")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showMapView = false
                        }
                        .foregroundColor(.yellow)
                    }
                }
            }
        }
        .alert("Location Access Required", isPresented: $showLocationAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To provide personalized recommendations based on your current location, please enable location access in Settings. The app currently uses Dallas, TX as the search area.")
        }
        .onAppear {
            // Request location permission when chat opens if not determined
            if chatViewModel.locationServiceInstance.authorizationStatus == .notDetermined {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    chatViewModel.locationServiceInstance.requestLocationPermission()
                }
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
    
    private func refreshLocation() {
        chatViewModel.locationServiceInstance.requestLocationPermission()
    }
    
    private func getLocationButtonIcon() -> String {
        switch chatViewModel.locationServiceInstance.authorizationStatus {
        case .notDetermined:
            return "location.circle"
        case .denied, .restricted:
            return "location.slash.circle"
        case .authorizedWhenInUse, .authorizedAlways:
            return chatViewModel.locationServiceInstance.isUsingFallbackLocation ? "location.circle.fill" : "location.fill.viewfinder"
        @unknown default:
            return "location.circle"
        }
    }
    
    private func getLocationButtonColor() -> Color {
        switch chatViewModel.locationServiceInstance.authorizationStatus {
        case .notDetermined:
            return .orange
        case .denied, .restricted:
            return .red
        case .authorizedWhenInUse, .authorizedAlways:
            return chatViewModel.locationServiceInstance.isUsingFallbackLocation ? .orange : .green
        @unknown default:
            return .gray
        }
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
    @State private var animateEntry = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.isUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(message.content)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.cyan,
                                            Color.cyan.opacity(0.8),
                                            Color.blue.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.trailing, 4)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        // AI Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Check if this is likely a longer information response
                            if message.content.count > 200 && !containsLocationReferences(message.content) {
                                // Information-style formatting
                                informationStyleText(message.content)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 24)
                                                    .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                            } else {
                                // Regular message formatting
                                Text(message.content)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 24)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                            
                            if let results = message.locationResults, !results.isEmpty {
                                LocationResultsView(results: results)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    HStack {
                        Text("AI Assistant")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.cyan)
                        
                        Text(formatTimestamp(message.timestamp))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.leading, 44)
                }
                
                Spacer(minLength: 60)
            }
        }
        .scaleEffect(animateEntry ? 1.0 : 0.8)
        .opacity(animateEntry ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                animateEntry = true
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // Helper function to check if text contains location references
    private func containsLocationReferences(_ text: String) -> Bool {
        let locationKeywords = ["nearby", "distance", "location", "around here", "close by", "within", "miles", 
                               "walking distance", "restaurants", "stores", "shops", "places"]
        
        let lowercasedText = text.lowercased()
        return locationKeywords.contains { lowercasedText.contains($0.lowercased()) }
    }
    
    // Creates styled text for information responses
    @ViewBuilder
    private func informationStyleText(_ content: String) -> some View {
        if #available(iOS 15.0, *) {
            // Enhanced text with markdown styling
            Text(try! AttributedString(markdown: content))
                .font(.system(size: 16, weight: .medium, design: .rounded))
        } else {
            // Plain text for older iOS versions
            Text(content)
                .font(.system(size: 16, weight: .medium, design: .rounded))
        }
    }

// MARK: - Enhanced Input Area
@available(iOS 16.0, *)
struct EnhancedInputArea: View {
    @Binding var messageText: String
    @FocusState.Binding var isInputFocused: Bool
    let sendAction: () -> Void
    let isTyping: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Message Input
            HStack(spacing: 12) {
                TextField("Ask me anything...", text: $messageText, axis: .vertical)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .focused($isInputFocused)
                    .disabled(isTyping)
                    .lineLimit(1...4)
                
                if !messageText.isEmpty {
                    Button(action: {
                        messageText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Send Button
            Button(action: sendAction) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: messageText.trimmingCharacters(in: .whitespaces).isEmpty ? 
                                [Color.gray, Color.gray.opacity(0.6)] :
                                [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.8 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: messageText.isEmpty)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}

// MARK: - Enhanced Input Area for iOS 15 and below
struct EnhancedInputArea_iOS15: View {
    @Binding var messageText: String
    @FocusState.Binding var isInputFocused: Bool
    let sendAction: () -> Void
    let isTyping: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Message Input
            HStack(spacing: 12) {
                TextField("Ask me anything...", text: $messageText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .focused($isInputFocused)
                    .disabled(isTyping)
                
                if !messageText.isEmpty {
                    Button(action: {
                        messageText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .animation(.easeInOut, value: messageText.isEmpty)
            
            // Enhanced Send Button
            Button(action: sendAction) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: messageText.trimmingCharacters(in: .whitespaces).isEmpty ? 
                                [Color.gray, Color.gray.opacity(0.6)] :
                                [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.8 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: messageText.isEmpty)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}
