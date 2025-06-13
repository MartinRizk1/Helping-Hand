import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @State private var userName: String = ""
    @State private var userInterests: Set<PlaceCategory> = []
    @State private var currentStep = 0
    @StateObject private var locationService = LocationService()
    @State private var isCompleted = false
    let onComplete: (String, Set<PlaceCategory>) -> Void
    
    var body: some View {
        ZStack {
            // Dark Lamborghini-inspired background
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
            
            VStack(spacing: 30) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.yellow : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Content based on current step
                Group {
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        nameStep
                    case 2:
                        interestsStep
                    default:
                        locationStep
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(25)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 3 ? "Get Started" : "Continue") {
                        if currentStep == 3 {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .disabled(shouldDisableContinue)
                    .opacity(shouldDisableContinue ? 0.5 : 1.0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.yellow.opacity(0.5), radius: 20)
                
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.black)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to HelpingHand")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your AI-powered location assistant to find places nearby")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var nameStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            VStack(spacing: 16) {
                Text("What's your name?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll personalize your experience")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            TextField("Enter your name", text: $userName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 30)
        }
    }
    
    private var interestsStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            VStack(spacing: 16) {
                Text("What interests you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select categories you'd like to find nearby")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    Button(action: {
                        if userInterests.contains(category) {
                            userInterests.remove(category)
                        } else {
                            userInterests.insert(category)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: category.systemIcon)
                                .font(.system(size: 20, weight: .bold))
                            
                            Text(category.rawValue)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(userInterests.contains(category) ? .black : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(
                            userInterests.contains(category) ?
                            LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 30)
        }
    }
    
    private var locationStep: some View {
        VStack(spacing: 24) {
            Image(systemName: locationService.authorizationStatus == .authorizedWhenInUse ? "location.circle.fill" : "location.slash.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(locationService.authorizationStatus == .authorizedWhenInUse ? .green : .yellow)
            
            VStack(spacing: 16) {
                Text("Enable Location Access")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We need your location to find places nearby and provide personalized recommendations")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            if locationService.authorizationStatus == .denied {
                VStack(spacing: 12) {
                    Text("Location access is currently denied")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                    
                    Button("Open Settings") {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(15)
                }
            } else if locationService.authorizationStatus == .notDetermined {
                Button("Allow Location Access") {
                    locationService.requestLocationPermission()
                }
                .foregroundColor(.black)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
        }
    }
    
    private var shouldDisableContinue: Bool {
        switch currentStep {
        case 1:
            return userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return userInterests.isEmpty
        default:
            return false
        }
    }
    
    private func completeOnboarding() {
        onComplete(userName, userInterests)
        isCompleted = true
    }
}

#Preview {
    OnboardingView { name, interests in
        print("Onboarding completed: \(name), \(interests)")
    }
}
