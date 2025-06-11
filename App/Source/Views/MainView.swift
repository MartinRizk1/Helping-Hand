import SwiftUI

struct MainView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Always show the map, using user location if available
                MapView(locations: locationViewModel.userLocation.map { [LocationResult(name: "Current Location", address: "", coordinate: $0.coordinate, category: "user")] } ?? [])
                    .frame(height: 400)
                    .transition(.opacity)

                Spacer()
            }
            .padding(.horizontal)
        }
        .onAppear {
            locationViewModel.requestLocationPermission()
        }
    }
}
