import SwiftUI
import MapKit

struct MapView: View {
    let places: [Place]
    @Binding var selectedPlace: Place?
    let userLocation: CLLocation?
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3361, longitude: -122.0375),
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
