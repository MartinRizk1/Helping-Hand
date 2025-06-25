import SwiftUI
import MapKit

struct MapView: View {
    let places: [Place]
    @Binding var selectedPlace: Place?
    let userLocation: CLLocation?
    
    // Dallas as default location base
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970), // Dallas coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: true,
            userTrackingMode: .constant(.follow),
            annotationItems: places) { place in
            MapAnnotation(coordinate: place.coordinate) {
                PlaceAnnotation(
                    place: place,
                    isSelected: selectedPlace?.id == place.id
                )
                .onTapGesture {
                    selectedPlace = place
                    withAnimation {
                        region.center = place.coordinate
                    }
                }
            }
        }
        .onChange(of: userLocation) { newLocation in
            if let location = newLocation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
        .onChange(of: selectedPlace) { place in
            if let place = place {
                withAnimation {
                    region.center = place.coordinate
                }
            }
        }
    }
}

struct PlaceAnnotation: View {
    let place: Place
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if isSelected {
                VStack(spacing: 2) {
                    Text(place.name)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                    if let distance = place.formattedDistance {
                        Text(distance)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                        .shadow(radius: 4)
                )
                .padding(.bottom, 4)
            }
            
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.9))
                    .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                    .shadow(radius: isSelected ? 4 : 2)
                
                Image(systemName: place.category.systemIcon)
                    .font(.system(size: isSelected ? 16 : 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var categoryColor: Color {
        switch place.category {
        case .food: return .orange
        case .coffee: return .brown
        case .shopping: return .blue
        case .electronics: return .purple
        case .grocery: return .green
        case .health: return .red
        case .services: return .gray
        case .entertainment: return .pink
        case .transportation: return .cyan
        }
    }
}

// Enhanced Map View for ChatView integration
struct EnhancedMapView: View {
    let locationResults: [LocationResult]
    let userLocation: CLLocation?
    @State private var selectedResult: LocationResult?
    
    // Dallas as base location
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: .constant(.none),
                annotationItems: locationResults) { result in
                MapAnnotation(coordinate: result.coordinate) {
                    LocationAnnotation(
                        result: result,
                        isSelected: selectedResult?.id == result.id
                    )
                    .onTapGesture {
                        selectedResult = result
                        withAnimation {
                            region.center = result.coordinate
                        }
                    }
                }
            }
            .onAppear {
                adjustMapRegion()
            }
            .onChange(of: userLocation) { location in
                if let location = location {
                    withAnimation {
                        region.center = location.coordinate
                    }
                }
            }
            
            // Location status overlay
            VStack {
                HStack {
                    Spacer()
                    LocationStatusOverlay(
                        userLocation: userLocation,
                        resultCount: locationResults.count
                    )
                    .padding()
                }
                Spacer()
            }
        }
        .sheet(item: $selectedResult) { result in
            LocationDetailView(location: result)
        }
    }
    
    private func adjustMapRegion() {
        guard !locationResults.isEmpty else { return }
        
        // Use user location if available, otherwise use Dallas
        let centerLocation = userLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970)
        
        // Calculate region to fit all results
        var minLat = locationResults.map { $0.coordinate.latitude }.min() ?? centerLocation.latitude
        var maxLat = locationResults.map { $0.coordinate.latitude }.max() ?? centerLocation.latitude
        var minLon = locationResults.map { $0.coordinate.longitude }.min() ?? centerLocation.longitude
        var maxLon = locationResults.map { $0.coordinate.longitude }.max() ?? centerLocation.longitude
        
        // Add padding
        let latPadding = (maxLat - minLat) * 0.2
        let lonPadding = (maxLon - minLon) * 0.2
        
        minLat -= latPadding
        maxLat += latPadding
        minLon -= lonPadding
        maxLon += lonPadding
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01),
            longitudeDelta: max(maxLon - minLon, 0.01)
        )
        
        withAnimation {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct LocationAnnotation: View {
    let result: LocationResult
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if isSelected {
                VStack(spacing: 2) {
                    Text(result.name)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if let distance = result.distance {
                        Text(String(format: "%.1fkm", distance / 1000))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                        .shadow(radius: 4)
                )
                .padding(.bottom, 4)
            }
            
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.9))
                    .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                    .shadow(radius: isSelected ? 4 : 2)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: isSelected ? 16 : 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var categoryColor: Color {
        let category = result.category.lowercased()
        if category.contains("food") || category.contains("restaurant") {
            return .orange
        } else if category.contains("coffee") || category.contains("cafe") {
            return .brown
        } else if category.contains("apple store") || category.contains("electronics") {
            return .purple
        } else if category.contains("grocery") || category.contains("supermarket") {
            return .green
        } else if category.contains("health") || category.contains("hospital") {
            return .red
        } else if category.contains("entertainment") {
            return .pink
        } else if category.contains("transport") {
            return .cyan
        } else {
            return .blue
        }
    }
    
    private var categoryIcon: String {
        let category = result.category.lowercased()
        if category.contains("food") || category.contains("restaurant") {
            return "fork.knife"
        } else if category.contains("coffee") || category.contains("cafe") {
            return "cup.and.saucer.fill"
        } else if category.contains("apple store") || category.contains("electronics") {
            return "desktopcomputer"
        } else if category.contains("grocery") || category.contains("supermarket") {
            return "cart.fill"
        } else if category.contains("health") || category.contains("hospital") {
            return "cross.fill"
        } else if category.contains("entertainment") {
            return "theatermasks.fill"
        } else if category.contains("transport") {
            return "car.fill"
        } else {
            return "location.fill"
        }
    }
}

struct LocationStatusOverlay: View {
    let userLocation: CLLocation?
    let resultCount: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: userLocation != nil ? "location.fill" : "location.circle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(userLocation != nil ? .green : .orange)
                
                Text(locationStatus)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial)
            .cornerRadius(20)
            
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("\(resultCount) places found")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial)
            .cornerRadius(20)
        }
    }
    
    private var locationStatus: String {
        if let location = userLocation {
            let age = -location.timestamp.timeIntervalSinceNow
            if age < 30 {
                return "Current location"
            } else {
                return "Recent location"
            }
        } else {
            return "Dallas area"
        }
    }
}
