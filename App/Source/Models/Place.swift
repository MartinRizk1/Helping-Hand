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

enum PlaceCategory: String, CaseIterable, Codable {
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

// Extension to help with converting from string categories
extension PlaceCategory {
    static func from(_ categoryString: String) -> PlaceCategory {
        let lowercased = categoryString.lowercased()
        
        if lowercased.contains("restaurant") || lowercased.contains("dining") || 
           lowercased.contains("food") || lowercased.contains("cuisine") {
            return .food
        } else if lowercased.contains("coffee") || lowercased.contains("cafe") || 
                  lowercased.contains("bakery") {
            return .coffee
        } else if lowercased.contains("shop") || lowercased.contains("store") || 
                  lowercased.contains("mall") || lowercased.contains("retail") {
            return .shopping
        } else if lowercased.contains("electronic") || lowercased.contains("tech") || 
                  lowercased.contains("apple store") || lowercased.contains("computer") {
            return .electronics
        } else if lowercased.contains("grocery") || lowercased.contains("supermarket") || 
                  lowercased.contains("market") || lowercased.contains("food store") {
            return .grocery
        } else if lowercased.contains("health") || lowercased.contains("hospital") || 
                  lowercased.contains("clinic") || lowercased.contains("doctor") || 
                  lowercased.contains("pharmacy") {
            return .health
        } else if lowercased.contains("service") || lowercased.contains("repair") || 
                  lowercased.contains("bank") || lowercased.contains("salon") {
            return .services
        } else if lowercased.contains("entertainment") || lowercased.contains("theater") || 
                  lowercased.contains("cinema") || lowercased.contains("venue") {
            return .entertainment
        } else if lowercased.contains("transport") || lowercased.contains("transit") || 
                  lowercased.contains("station") || lowercased.contains("airport") {
            return .transportation
        }
        
        // Default category if no match
        return .services
    }
}
