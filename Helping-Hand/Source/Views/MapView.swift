import SwiftUI
import MapKit

struct MapView: View {
    let locations: [LocationResult]
    @State private var region: MKCoordinateRegion
    @State private var selectedLocation: LocationResult?
    
    init(locations: [LocationResult]) {
        self.locations = locations
        
        // Calculate the region that encompasses all locations
        if let firstLocation = locations.first {
            let initialRegion = MKCoordinateRegion(
                center: firstLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            _region = State(initialValue: initialRegion)
        } else {
            // Default region if no locations
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(coordinateRegion: $region, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(radius: 3)
                            
                            Image(systemName: categoryIcon(for: location.category))
                                .font(.system(size: 24))
                                .foregroundColor(Color("AccentColor"))
                        }
                        .onTapGesture {
                            selectedLocation = location
                        }
                        
                        if selectedLocation?.id == location.id {
                            Text(location.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                )
                                .offset(y: -5)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Location details card
            if let location = selectedLocation {
                LocationDetailCard(location: location)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: selectedLocation)
                    .padding()
            }
        }
        .onAppear {
            adjustRegion()
        }
    }
    
    private func adjustRegion() {
        guard !locations.isEmpty else { return }
        
        var minLat = locations[0].coordinate.latitude
        var maxLat = locations[0].coordinate.latitude
        var minLon = locations[0].coordinate.longitude
        var maxLon = locations[0].coordinate.longitude
        
        for location in locations {
            minLat = min(minLat, location.coordinate.latitude)
            maxLat = max(maxLat, location.coordinate.latitude)
            minLon = min(minLon, location.coordinate.longitude)
            maxLon = max(maxLon, location.coordinate.longitude)
        }
        
        // Add padding
        let latDelta = (maxLat - minLat) * 1.5
        let lonDelta = (maxLon - minLon) * 1.5
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (maxLat + minLat) / 2,
                longitude: (maxLon + minLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.02),
                longitudeDelta: max(lonDelta, 0.02)
            )
        )
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case _ where category.contains("restaurant"), "food", "chinese", "italian":
            return "fork.knife"
        case "repair", "hardware", "window", "glass":
            return "wrench.and.screwdriver"
        case "hospital", "clinic", "doctor", "emergency":
            return "cross.circle"
        case "hotel", "lodging", "motel":
            return "bed.double"
        default:
            return "mappin"
        }
    }
}

struct LocationDetailCard: View {
    let location: LocationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(location.name)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(location.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let distance = location.distance {
                Text(formatDistance(distance))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let rating = location.rating {
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    Text(String(format: "%.1f", rating))
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                if let phoneNumber = location.phoneNumber {
                    Button(action: { callPhone(phoneNumber) }) {
                        Label("Call", systemImage: "phone.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(Color("AccentColor"))
                }
                
                if let website = location.website {
                    Button(action: { openURL(website) }) {
                        Label("Website", systemImage: "globe")
                    }
                    .buttonStyle(.bordered)
                    .tint(Color("AccentColor"))
                }
                
                Button(action: { openInMaps(location) }) {
                    Label("Directions", systemImage: "map.fill")
                }
                .buttonStyle(.bordered)
                .tint(Color("AccentColor"))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 5)
        )
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .medium
        
        let distanceInMeters = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: distanceInMeters)
    }
    
    private func callPhone(_ phoneNumber: String) {
        if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    private func openInMaps(_ location: LocationResult) {
        let placemark = MKPlacemark(coordinate: location.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: nil)
    }
}
