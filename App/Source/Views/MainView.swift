import SwiftUI
import MapKit

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map View
                MapView(
                    places: viewModel.places,
                    selectedPlace: $viewModel.selectedPlace,
                    userLocation: viewModel.userLocation
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Search Bar
                    searchBar
                        .padding()
                    
                    if !viewModel.places.isEmpty {
                        // Results List
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(viewModel.places) { place in
                                    PlaceCard(place: place)
                                        .onTapGesture {
                                            viewModel.selectedPlace = place
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 150)
                        .background(Color(.systemBackground).opacity(0.9))
                    }
                    
                    Spacer()
                }
                
                // Location Permission Alert
                if !viewModel.isLocationAuthorized {
                    locationPermissionView
                }
                
                // Loading Indicator
                if viewModel.isLoading {
                    loadingView
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search for food, coffee, etc...", text: $viewModel.searchText)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    viewModel.search()
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                    isSearchFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private var locationPermissionView: some View {
        VStack {
            Text("Location Access Required")
                .font(.headline)
            Text("Please enable location services to find places near you")
                .multilineTextAlignment(.center)
                .padding()
            Button("Enable Location") {
                viewModel.requestLocationPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
    
    private var loadingView: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.4))
    }
}

struct PlaceCard: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(place.name)
                .font(.headline)
                .lineLimit(1)
            
            if let address = place.address {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            if let distance = place.formattedDistance {
                Text(distance)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}
