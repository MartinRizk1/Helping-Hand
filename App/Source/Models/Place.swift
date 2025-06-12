import Foundation
import CoreLocation
import MapKit

struct Place: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: PlaceCategory
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }
    var distance: CLLocationDistance?
    let address: String?
    let phoneNumber: String?
    let rating: Double?
    let isOpen: Bool?
    
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance/1000)
        }
    }
}

enum PlaceCategory: String, CaseIterable {
    case food = "Food"
    case coffee = "Coffee"
    case shopping = "Shopping"
    case health = "Healthcare"
    case services = "Services"
    
    var systemIcon: String {
        switch self {
        case .food: return "fork.knife"
        case .coffee: return "cup.and.saucer.fill"
        case .shopping: return "bag.fill"
        case .health: return "cross.fill"
        case .services: return "building.2.fill"
        }
    }
}

extension Place {
    static func from(_ mapItem: MKMapItem) -> Place {
        Place(
            name: mapItem.name ?? "Unknown Place",
            coordinate: mapItem.placemark.coordinate,
            category: .food, // This would be determined by the place type
            distance: nil, // Would be calculated based on user location
            address: mapItem.placemark.title,
            phoneNumber: mapItem.phoneNumber,
            rating: nil, // Would come from additional API
            isOpen: nil  // Would come from additional API
        )
    }
}
