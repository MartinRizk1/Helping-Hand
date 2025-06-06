import Foundation
import CoreLocation
import MapKit

struct LocationResult: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String
    private let latitude: Double
    private let longitude: Double
    let category: String
    let phoneNumber: String?
    private let websiteString: String?
    let rating: Double?
    let distance: Double?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var website: URL? {
        if let urlString = websiteString {
            return URL(string: urlString)
        }
        return nil
    }
    
    init(name: String, address: String, coordinate: CLLocationCoordinate2D, category: String, 
         phoneNumber: String? = nil, website: URL? = nil, rating: Double? = nil, distance: CLLocationDistance? = nil) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.category = category
        self.phoneNumber = phoneNumber
        self.websiteString = website?.absoluteString
        self.rating = rating
        self.distance = distance
    }
    
    // For creating from stored data
    init(id: UUID, name: String, address: String, latitude: Double, longitude: Double, category: String,
         phoneNumber: String? = nil, websiteString: String? = nil, rating: Double? = nil, distance: Double? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.phoneNumber = phoneNumber
        self.websiteString = websiteString
        self.rating = rating
        self.distance = distance
    }
}
