import SwiftUI

struct LocationResultsView: View {
    let results: [LocationResult]
    @State private var showingAllResults = false
    @State private var selectedResult: LocationResult?
    
    var visibleResults: [LocationResult] {
        if showingAllResults || results.count <= 3 {
            return results
        } else {
            return Array(results.prefix(3))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Found \(results.count) locations")
                    .font(.headline)
                    .padding(.top, 5)
                
                Spacer()
                
                Button(action: {
                    // Share location results
                    // In a real app, this would share via the native share sheet
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color("AccentColor"))
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            ForEach(visibleResults) { result in
                LocationResultRow(result: result)
                    .onTapGesture {
                        selectedResult = result
                    }
                    .contentShape(Rectangle())
                
                if visibleResults.last?.id != result.id {
                    Divider()
                        .padding(.vertical, 2)
                }
            }
            
            if results.count > 3 && !showingAllResults {
                Button(action: { 
                    withAnimation(.spring()) {
                        showingAllResults = true 
                    }
                }) {
                    HStack {
                        Text("Show all \(results.count) results")
                            .font(.caption)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("AccentColor"), lineWidth: 1)
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("BackgroundColor").opacity(0.2))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
        .sheet(item: $selectedResult) { location in
            LocationDetailView(location: location)
        }
    }
}

struct LocationResultRow: View {
    let result: LocationResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon(for: result.category))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .padding(6)
                .background(
                    Circle()
                        .fill(Color("AccentColor"))
                        .shadow(color: Color("AccentColor").opacity(0.3), radius: 2, x: 0, y: 1)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(result.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(result.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let distance = result.distance {
                        Label(
                            title: { Text(formatDistance(distance)).font(.caption2) },
                            icon: { Image(systemName: "location.fill").font(.system(size: 9)) }
                        )
                        .foregroundColor(.secondary)
                    }
                    
                    if let rating = result.rating {
                        Label(
                            title: { Text(String(format: "%.1f", rating)).font(.caption2) },
                            icon: { Image(systemName: "star.fill").font(.system(size: 9)) }
                        )
                        .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 6) {
                if result.phoneNumber != nil {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color("AccentColor"))
                        .font(.caption)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
        .padding(.vertical, 8)
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
