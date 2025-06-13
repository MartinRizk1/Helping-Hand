import SwiftUI
import CoreLocation

struct LocationResultsView: View {
    let results: [LocationResult]
    @State private var showingAllResults = false
    @State private var selectedLocation: LocationResult?
    
    var visibleResults: [LocationResult] {
        if showingAllResults || results.count <= 3 {
            return results
        } else {
            return Array(results.prefix(3))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Found \(results.count) locations nearby")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.yellow)
                .padding(.bottom, 8)
            
            ForEach(visibleResults) { result in
                LocationResultRow(result: result)
                    .onTapGesture {
                        selectedLocation = result
                    }
                
                if visibleResults.last?.id != result.id {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 8)
                }
            }
            
            if results.count > 3 && !showingAllResults {
                Button(action: { showingAllResults = true }) {
                    HStack(spacing: 8) {
                        Text("Show \(results.count - 3) more results")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.yellow.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .sheet(item: $selectedLocation) { location in
            LocationDetailView(location: location)
        }
    }
}

struct LocationResultRow: View {
    let result: LocationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(result.address)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
            
            HStack(spacing: 20) {
                if let distance = result.distance {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f km", distance / 1000))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.yellow.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                if let rating = result.rating {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.yellow.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
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
