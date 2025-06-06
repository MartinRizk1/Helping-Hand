import SwiftUI
import MapKit

struct LocationDetailView: View {
    let location: LocationResult
    @Environment(\.presentationMode) var presentationMode
    @State private var region: MKCoordinateRegion
    @State private var showingDirections = false
    
    init(location: LocationResult) {
        self.location = location
        
        // Initialize map region centered on the location
        _region = State(initialValue: MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(location.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    // Share location
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(Color("AccentColor"))
                }
            }
            .padding()
            
            // Map view
            Map(coordinateRegion: $region, annotationItems: [location]) { loc in
                MapAnnotation(coordinate: loc.coordinate) {
                    VStack {
                        Image(systemName: categoryIcon(for: loc.category))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color("AccentColor"))
                                    .shadow(radius: 3)
                            )
                        
                        Text(loc.name)
                            .font(.caption)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .shadow(radius: 1)
                            )
                    }
                }
            }
            .frame(height: 200)
            .disabled(true) // Disable map panning in detail view
            
            // Location details
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location Information")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        DetailRow(icon: "mappin", text: location.address)
                        DetailRow(icon: "tag", text: location.category)
                        
                        if let distance = location.distance {
                            DetailRow(icon: "location.fill", text: formatDistance(distance) + " away")
                        }
                        
                        if let phoneNumber = location.phoneNumber {
                            DetailRow(icon: "phone.fill", text: phoneNumber)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // In a real app, this would make an actual call
                                    if let url = URL(string: "tel:\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                        }
                        
                        if let website = location.website {
                            DetailRow(icon: "globe", text: website.absoluteString)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    UIApplication.shared.open(website)
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Rating
                    if let rating = location.rating {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rating")
                                .font(.headline)
                            
                            HStack {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                        .foregroundColor(.orange)
                                }
                                
                                Text(String(format: "%.1f", rating))
                                    .fontWeight(.medium)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        ActionButton(icon: "phone.fill", label: "Call") {
                            if let phone = location.phoneNumber,
                               let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .disabled(location.phoneNumber == nil)
                        
                        ActionButton(icon: "globe", label: "Website") {
                            if let website = location.website {
                                UIApplication.shared.open(website)
                            }
                        }
                        .disabled(location.website == nil)
                        
                        ActionButton(icon: "map.fill", label: "Directions") {
                            showingDirections = true
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("BackgroundColor").opacity(0.3))
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 10)
            }
            .alert(isPresented: $showingDirections) {
                Alert(
                    title: Text("Open Maps"),
                    message: Text("Would you like to get directions to \(location.name)?"),
                    primaryButton: .default(Text("Get Directions")) {
                        let placemark = MKPlacemark(coordinate: location.coordinate)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = location.name
                        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .navigationBarHidden(true)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .medium
        
        let distanceInMeters = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: distanceInMeters)
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

struct DetailRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 18)
                .foregroundColor(Color("AccentColor"))
            
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(isEnabled ? Color("AccentColor") : .gray)
        }
    }
}
