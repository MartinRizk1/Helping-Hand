import SwiftUI
import MapKit

struct MapView: View {
    let locations: [LocationResult]
    @State private var region: MKCoordinateRegion
    @State private var selectedLocation: LocationResult?
    
    init(locations: [LocationResult]) {
        self.locations = locations
        
        // Calculate initial region to show all locations
        if let firstLocation = locations.first {
            let coordinates = locations.map { $0.coordinate }
            let minLat = coordinates.map { $0.latitude }.min() ?? firstLocation.coordinate.latitude
            let maxLat = coordinates.map { $0.latitude }.max() ?? firstLocation.coordinate.latitude
            let minLon = coordinates.map { $0.longitude }.min() ?? firstLocation.coordinate.longitude
            let maxLon = coordinates.map { $0.longitude }.max() ?? firstLocation.coordinate.longitude
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) * 1.5,
                longitudeDelta: (maxLon - minLon) * 1.5
            )
            
            _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        } else {
            // Default to San Francisco if no locations
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locations) { location in
            MapAnnotation(coordinate: location.coordinate) {
                VStack(spacing: 0) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                        .background(Circle().fill(.white))
                        .onTapGesture {
                            withAnimation {
                                selectedLocation = location
                            }
                        }
                    
                    if selectedLocation?.id == location.id {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name)
                                .font(.callout)
                                .fontWeight(.bold)
                            
                            if let distance = location.distance {
                                Text(String(format: "%.1f km", distance / 1000))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let phoneNumber = location.phoneNumber {
                                Button(action: {
                                    let tel = phoneNumber.replacingOccurrences(of: " ", with: "")
                                    if let url = URL(string: "tel://\(tel)") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Label(phoneNumber, systemImage: "phone.fill")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(radius: 2)
                        )
                        .offset(y: 4)
                    }
                }
            }
        }
        .onTapGesture {
            selectedLocation = nil
        }
    }
}
