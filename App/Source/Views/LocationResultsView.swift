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
        VStack(alignment: .leading, spacing: 8) {
            Text("Found \(results.count) locations nearby")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(visibleResults) { result in
                LocationResultRow(result: result)
                    .onTapGesture {
                        selectedLocation = result
                    }
                
                if visibleResults.last?.id != result.id {
                    Divider()
                }
            }
            
            if results.count > 3 && !showingAllResults {
                Button(action: { showingAllResults = true }) {
                    Text("Show \(results.count - 3) more results")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .sheet(item: $selectedLocation) { location in
            LocationDetailView(location: location)
        }
    }
}

struct LocationResultRow: View {
    let result: LocationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.name)
                .font(.headline)
            
            Text(result.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                if let distance = result.distance {
                    Label(
                        String(format: "%.1f km", distance / 1000),
                        systemImage: "location.fill"
                    )
                }
                
                if let rating = result.rating {
                    Label(
                        String(format: "%.1f", rating),
                        systemImage: "star.fill"
                    )
                    .foregroundColor(.yellow)
                }
            }
            .font(.caption)
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
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
