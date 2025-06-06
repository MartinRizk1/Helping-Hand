import SwiftUI

struct MainView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var locationViewModel: LocationViewModel
    @State private var showingSettings = false
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(themeService.currentTheme.colorScheme)
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    // Settings button
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                            .foregroundColor(Color("TextColor"))
                            .padding()
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsView(chatViewModel: chatViewModel)
                    }
                }
                
                // Character View
                CharacterView(character: Character.defaultCharacter, 
                              mood: chatViewModel.characterMood)
                    .frame(height: 220)
                    .padding(.top, 5)
                
                // Chat and Map View
                ZStack {
                    // Show map when we have location results
                    if let selectedMessage = chatViewModel.selectedMessage, 
                       let locations = selectedMessage.locationResults, 
                       !locations.isEmpty {
                        MapView(locations: locations)
                            .transition(.opacity)
                    }
                    
                    // Chat is always displayed
                    ChatView()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                                .shadow(radius: 10)
                        )
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            // Request location access when app appears
            locationViewModel.requestLocationPermission()
        }
    }
}
