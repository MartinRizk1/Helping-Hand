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
    case electronics = "Electronics"
    case grocery = "Grocery"
    case health = "Healthcare"
    case services = "Services"
    case entertainment = "Entertainment"
    case transportation = "Transportation"
    
    var systemIcon: String {
        switch self {
        case .food: return "fork.knife"
        case .coffee: return "cup.and.saucer.fill"
        case .shopping: return "bag.fill"
        case .electronics: return "desktopcomputer"
        case .grocery: return "cart.fill"
        case .health: return "cross.fill"
        case .services: return "building.2.fill"
        case .entertainment: return "theatermasks.fill"
        case .transportation: return "car.fill"
        }
    }
}

extension Place {
    static func from(_ mapItem: MKMapItem) -> Place {
        let category = determineCategoryFromMapItem(mapItem)
        
        return Place(
            name: mapItem.name ?? "Unknown Place",
            coordinate: mapItem.placemark.coordinate,
            category: category,
            distance: nil, // Would be calculated based on user location
            address: mapItem.placemark.title,
            phoneNumber: mapItem.phoneNumber,
            rating: nil, // Would come from additional API
            isOpen: nil  // Would come from additional API
        )
    }
    
    private static func determineCategoryFromMapItem(_ mapItem: MKMapItem) -> PlaceCategory {
        let name = mapItem.name?.lowercased() ?? ""
        let category = mapItem.pointOfInterestCategory?.rawValue ?? ""
        
        // Check for specific stores first
        if name.contains("apple store") || name.contains("apple") && (name.contains("store") || name.contains("retail")) {
            return .electronics
        }
        
        if name.contains("starbucks") || name.contains("coffee") || category.contains("Cafe") {
            return .coffee
        }
        
        if name.contains("grocery") || name.contains("supermarket") || name.contains("walmart") || 
           name.contains("target") || name.contains("kroger") || category.contains("FoodMarket") {
            return .grocery
        }
        
        // Map by POI category
        switch category {
        case let cat where cat.contains("Restaurant"):
            return .food
        case let cat where cat.contains("Cafe"):
            return .coffee
        case let cat where cat.contains("Store"):
            return .shopping
        case let cat where cat.contains("Hospital") || cat.contains("Pharmacy"):
            return .health
        case let cat where cat.contains("Entertainment"):
            return .entertainment
        case let cat where cat.contains("Transport"):
            return .transportation
        case let cat where cat.contains("FoodMarket"):
            return .grocery
        default:
            return .services
        }
    }
}
