import SwiftUI
import CoreLocation
import MapKit

struct LocationResultsView: View {
    let results: [LocationResult]
    @State private var showingAllResults = false
    @State private var selectedLocation: LocationResult?
    @State private var animateResults = false
    
    var visibleResults: [LocationResult] {
        if showingAllResults || results.count <= 3 {
            return results
        } else {
            return Array(results.prefix(3))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.cyan)
                
                Text("Found \(results.count) locations nearby")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                if results.count > 3 {
                    Button(action: { 
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showingAllResults.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(showingAllResults ? "Show less" : "Show all")
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: showingAllResults ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.cyan.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cyan.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.bottom, 8)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(visibleResults.enumerated()), id: \.element.id) { index, result in
                    LocationResultRow(result: result)
                        .scaleEffect(animateResults ? 1.0 : 0.8)
                        .opacity(animateResults ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateResults)
                        .onTapGesture {
                            selectedLocation = result
                        }
                    
                    if visibleResults.last?.id != result.id {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.3), Color.clear, Color.cyan.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animateResults = true
            }
        }
    }
}

struct LocationResultRow: View {
    let result: LocationResult
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.8), categoryColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(result.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.8))
                    
                    Text(result.address)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if let rating = result.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    if let distance = result.distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.cyan.opacity(0.8))
                            
                            Text(formatDistance(distance))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Action button
                    Button(action: {
                        openInMaps()
                    }) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { 
            isPressed = true 
        } onPressingChanged: { pressing in
            if !pressing {
                isPressed = false
            }
        }
    }
    
    private var categoryColor: Color {
        switch result.category.lowercased() {
        case "restaurant", "food": return .orange
        case "hotel", "lodging": return .purple
        case "shopping", "store": return .green
        case "entertainment": return .pink
        case "health", "medical": return .red
        case "gas", "fuel": return .blue
        default: return .cyan
        }
    }
    
    private var categoryIcon: String {
        switch result.category.lowercased() {
        case "restaurant", "food": return "fork.knife"
        case "hotel", "lodging": return "bed.double.fill"
        case "shopping", "store": return "bag.fill"
        case "entertainment": return "gamecontroller.fill"
        case "health", "medical": return "cross.fill"
        case "gas", "fuel": return "fuelpump.fill"
        default: return "mappin.and.ellipse"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        let distanceInMeters = distance
        if distanceInMeters < 1000 {
            return "\(Int(distanceInMeters))m"
        } else {
            return String(format: "%.1fkm", distanceInMeters / 1000)
        }
    }
    
    private func openInMaps() {
        let coordinate = result.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = result.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

struct LocationDetailView: View {
    let location: LocationResult
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    DetailRow(title: "Address", value: location.address, icon: "map.fill")
                    
                    if let phoneNumber = location.phoneNumber {
                        Button(action: {
                            let tel = phoneNumber.replacingOccurrences(of: " ", with: "")
                            if let url = URL(string: "tel://\(tel)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            DetailRow(title: "Phone", value: phoneNumber, icon: "phone.fill")
                        }
                    }
                    
                    if let website = location.website {
                        Link(destination: website) {
                            DetailRow(title: "Website", value: website.host ?? website.absoluteString, icon: "globe")
                        }
                    }
                }
                
                Section {
                    if let distance = location.distance {
                        DetailRow(
                            title: "Distance",
                            value: String(format: "%.1f km", distance / 1000),
                            icon: "location.fill"
                        )
                    }
                    
                    if let rating = location.rating {
                        DetailRow(
                            title: "Rating",
                            value: String(format: "%.1f", rating),
                            icon: "star.fill"
                        )
                    }
                }
                
                Section {
                    Button(action: {
                        let coords = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        if let url = URL(string: "maps://?q=\(coords)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Open in Maps", systemImage: "map.fill")
                    }
                }
            }
            .navigationTitle(location.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
