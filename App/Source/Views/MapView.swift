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
                Text(place.name)
                    .font(.caption)
                    .padding(4)
                    .background(Color(.systemBackground))
                    .cornerRadius(4)
                    .padding(.bottom, 4)
            }
            
            Image(systemName: place.category.systemIcon)
                .font(.system(size: isSelected ? 24 : 20))
                .foregroundColor(isSelected ? .blue : .red)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(radius: 2)
                )
        }
    }
}
