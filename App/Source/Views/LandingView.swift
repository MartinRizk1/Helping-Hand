import SwiftUI
import CoreLocation

struct LandingView: View {
    @StateObject private var locationService = LocationService()
    @State private var showChat = false
    @State private var showOnboarding = false
    @State private var nearbyEmergencyPlaces: [EmergencyPlace] = []
    @State private var animateElements = false
    @State private var userName: String = ""
    @State private var userInterests: Set<PlaceCategory> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Lamborghini-inspired dark gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.1, blue: 0.1),
                        Color(red: 0.15, green: 0.15, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle animated background elements
                GeometryReader { geometry in
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 200, height: 200)
                            .position(
                                x: geometry.size.width * (0.2 + Double(index) * 0.3),
                                y: geometry.size.height * (0.3 + Double(index) * 0.2)
                            )
                            .scaleEffect(animateElements ? 1.2 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 3.0 + Double(index))
                                    .repeatForever(autoreverses: true),
                                value: animateElements
                            )
                    }
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 80)
                        
                        // Premium app header with Lamborghini-style aesthetics
                        VStack(spacing: 20) {
                            // Sleek app icon with glow effect
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.yellow, Color.orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Color.yellow.opacity(0.5), radius: 20, x: 0, y: 0)
                                
                                Image(systemName: "location.north.circle.fill")
                                    .font(.system(size: 45))
                                    .foregroundColor(.black)
                            }
                            .scaleEffect(animateElements ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: animateElements
                            )
                            
                            VStack(spacing: 12) {
                                Text("HelpingHand")
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.white, Color.gray.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                                
                                if !userName.isEmpty {
                                    Text("Welcome back, \(userName)!")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.yellow)
                                        .padding(.top, 5)
                                }
                                
                                Text("AI-Powered Premium Location Assistant")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Premium location status card
                        LocationStatusCard(locationService: locationService)
                        
                        // Main premium action button with Lamborghini styling
                        VStack(spacing: 20) {
                            Button(action: {
                                // Request location permission first, then show chat
                                if locationService.authorizationStatus == .notDetermined {
                                    locationService.requestLocationPermission()
                                }
                                showChat = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 24, weight: .bold))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Start AI Assistant")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                        Text("Find places nearby")
                                            .font(.system(size: 12, weight: .medium))
                                            .opacity(0.8)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 24))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .frame(height: 70)
                                .background(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange, Color.yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(35)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 35)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color.yellow.opacity(0.3), radius: 20, x: 0, y: 10)
                            }
                            .scaleEffect(animateElements ? 1.02 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                                value: animateElements
                            )
                            .padding(.horizontal, 30)
                            
                            Text("Ask about restaurants, hotels, shops, and more!")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Premium emergency information section
                        EmergencyInfoCard(nearbyPlaces: $nearbyEmergencyPlaces)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showChat) {
            ChatView()
                .environmentObject(ChatViewModel())
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView { name, interests in
                userName = name
                userInterests = interests
                UserDefaults.standard.set(name, forKey: "userName")
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                showOnboarding = false
            }
        }
        .onAppear {
            // Check if user has completed onboarding
            let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            if !hasCompletedOnboarding {
                showOnboarding = true
            } else {
                userName = UserDefaults.standard.string(forKey: "userName") ?? ""
            }
            
            // Always request location permission on app start
            if locationService.authorizationStatus == .notDetermined {
                locationService.requestLocationPermission()
            }
            loadNearbyEmergencyPlaces()
            withAnimation {
                animateElements = true
            }
        }
    }
    
    private func loadNearbyEmergencyPlaces() {
        // Load comprehensive emergency services and hotlines
        nearbyEmergencyPlaces = [
            EmergencyPlace(name: "Emergency Services", phone: "911", type: .emergency),
            EmergencyPlace(name: "Poison Control Center", phone: "1-800-222-1222", type: .poison),
            EmergencyPlace(name: "Mental Health Crisis", phone: "988", type: .mental),
            EmergencyPlace(name: "National Suicide Prevention", phone: "1-800-273-8255", type: .mental),
            EmergencyPlace(name: "Domestic Violence Hotline", phone: "1-800-799-7233", type: .safety),
            EmergencyPlace(name: "Child Abuse Hotline", phone: "1-800-4-A-CHILD", type: .safety),
            EmergencyPlace(name: "Animal Poison Control", phone: "1-888-426-4435", type: .poison),
            EmergencyPlace(name: "Disaster Distress Helpline", phone: "1-800-985-5990", type: .mental)
        ]
    }
}

struct LocationStatusCard: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [locationStatusColor.opacity(0.3), locationStatusColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: locationStatusIcon)
                        .foregroundColor(locationStatusColor)
                        .font(.system(size: 24, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Location Status")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(locationStatusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                Button("Enable Location Access") {
                    // Open Settings
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
    
    private var locationStatusIcon: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "location.fill"
        case .denied, .restricted:
            return "location.slash"
        case .notDetermined:
            return "location"
        @unknown default:
            return "location"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return locationService.isUsingFallbackLocation ? .orange : .green
        case .denied, .restricted:
            return .orange  // Changed from red to orange since we have fallback
        case .notDetermined:
            return .orange
        @unknown default:
            return .orange
        }
    }
    
    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return locationService.isUsingFallbackLocation ? "Using Dallas area for searches" : "Location access enabled"
        case .denied, .restricted:
            return "Location access denied - Using Dallas area"
        case .notDetermined:
            return locationService.isUsingFallbackLocation ? "Location pending - Using Dallas area" : "Location permission pending"
        @unknown default:
            return "Using Dallas area for searches"
        }
    }
}

struct EmergencyInfoCard: View {
    @Binding var nearbyPlaces: [EmergencyPlace]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "cross.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 24, weight: .bold))
                }
                
                Text("Emergency Services")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                ForEach(nearbyPlaces) { place in
                    EmergencyPlaceRow(place: place)
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
}

struct EmergencyPlaceRow: View {
    let place: EmergencyPlace
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: place.type.icon)
                .foregroundColor(place.type.color)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(place.phone)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                makeEmergencyCall(to: place.phone)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Call")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func makeEmergencyCall(to phoneNumber: String) {
        // Clean the phone number by removing any non-numeric characters except + and -
        let cleanedNumber = phoneNumber.components(separatedBy: CharacterSet(charactersIn: "0123456789+-").inverted).joined()
        
        // Create the tel URL
        guard let phoneURL = URL(string: "tel://\(cleanedNumber)") else {
            print("❌ Invalid phone number: \(phoneNumber)")
            return
        }
        
        // Check if the device can make phone calls
        if UIApplication.shared.canOpenURL(phoneURL) {
            print("📞 Initiating emergency call to \(phoneNumber)")
            UIApplication.shared.open(phoneURL, options: [:]) { success in
                if success {
                    print("✅ Emergency call initiated successfully")
                } else {
                    print("❌ Failed to initiate emergency call")
                }
            }
        } else {
            print("❌ Device cannot make phone calls or invalid number: \(phoneNumber)")
            // Fallback: Copy number to clipboard for manual dialing
            UIPasteboard.general.string = cleanedNumber
            print("📋 Phone number copied to clipboard: \(cleanedNumber)")
        }
    }
}

struct EmergencyPlace: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let type: EmergencyType
}

enum EmergencyType {
    case emergency, poison, mental, safety
    
    var icon: String {
        switch self {
        case .emergency: return "cross.circle.fill"
        case .poison: return "exclamationmark.triangle.fill"
        case .mental: return "brain.head.profile"
        case .safety: return "shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .emergency: return .red
        case .poison: return .orange
        case .mental: return .blue
        case .safety: return .purple
        }
    }
}

#Preview {
    LandingView()
}
