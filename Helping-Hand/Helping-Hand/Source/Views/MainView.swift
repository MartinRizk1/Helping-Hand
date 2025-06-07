import SwiftUI

struct MainView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var locationViewModel: LocationViewModel
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Map View (when we have location results)
                if let selectedMessage = chatViewModel.selectedMessage,
                   let locations = selectedMessage.locationResults,
                   !locations.isEmpty {
                    MapView(locations: locations)
                        .frame(height: 300)
                        .transition(.opacity)
                }
                
                // Chat View
                ChatView()
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .shadow(radius: 10)
                    )
            }
            .padding(.horizontal)
        }
        .onAppear {
            locationViewModel.requestLocationPermission()
        }
    }
}
