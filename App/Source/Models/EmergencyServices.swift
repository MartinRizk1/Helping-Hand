import Foundation
import CoreLocation
import MapKit
import Combine

// Public type for service categories
public struct EmergencyServiceType: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let query: String
    public let icon: String
    
    public init(id: UUID = UUID(), name: String, query: String, icon: String) {
        self.id = id
        self.name = name
        self.query = query
        self.icon = icon
    }
}

// Public type for emergency services
public struct EmergencyService: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let type: String
    public let icon: String
    public let address: String
    private let latitude: Double
    private let longitude: Double
    public let phoneNumber: String?
    public let distance: CLLocationDistance?
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public var formattedDistance: String? {
        guard let distance = distance else { return nil }
        
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    public init(id: UUID = UUID(), name: String, type: String, icon: String, address: String, coordinate: CLLocationCoordinate2D, phoneNumber: String? = nil, distance: CLLocationDistance? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.phoneNumber = phoneNumber
        self.distance = distance
    }
}

// EmergencyContact implementation with proper access control
public struct EmergencyContact: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let phoneNumber: String
    public let address: String?
    public let email: String?
    public let relationship: String?
    public let isEmergencyContact: Bool
    
    // Computed properties for UI compatibility
    public var number: String {
        return phoneNumber
    }
    
    public var icon: String {
        // Return appropriate SF Symbol based on contact type
        if name.lowercased().contains("police") {
            return "shield.lefthalf.filled"
        } else if name.lowercased().contains("fire") {
            return "flame.fill"
        } else if name.lowercased().contains("ambulance") || name.lowercased().contains("medical") {
            return "cross.case.fill"
        } else if name.lowercased().contains("emergency") {
            return "exclamationmark.triangle.fill"
        } else {
            return "phone.fill"
        }
    }
    
    public init(id: UUID = UUID(), 
                name: String, 
                phoneNumber: String, 
                address: String? = nil, 
                email: String? = nil, 
                relationship: String? = nil, 
                isEmergencyContact: Bool = true) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.address = address
        self.email = email
        self.relationship = relationship
        self.isEmergencyContact = isEmergencyContact
    }
}

public class EmergencyServices: ObservableObject {
    @Published public var nearbyServices: [EmergencyService] = []
    @Published public var emergencyContacts: [EmergencyContact] = []
    private let locationService: LocationService
    private let queue = DispatchQueue(label: "com.helpinghand.emergency-services", qos: .userInitiated)
    
    public init(locationService: LocationService) {
        self.locationService = locationService
        queue.async { [weak self] in
            self?.loadEmergencyContacts()
            self?.updateNearbyServices()
        }
    }
    
    // Factory method to create emergency contacts
    public static func createContact(name: String, phoneNumber: String, relationship: String? = nil, address: String? = nil, email: String? = nil) -> EmergencyContact {
        return EmergencyContact(name: name, phoneNumber: phoneNumber, address: address, email: email, relationship: relationship)
    }
    
    // MARK: - Emergency Contacts Management
    
    private func loadEmergencyContacts() {
        // TODO: Load from persistent storage in a future update
        // For now, we'll just initialize with empty array
        emergencyContacts = []
    }
    
    public func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveEmergencyContacts()
    }
    
    public func updateEmergencyContact(_ contact: EmergencyContact) {
        if let index = emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
            emergencyContacts[index] = contact
            saveEmergencyContacts()
        }
    }
    
    public func removeEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        saveEmergencyContacts()
    }
    
    private func saveEmergencyContacts() {
        // TODO: Implement persistent storage in a future update
    }
    
    // MARK: - Nearby Services Management
    
    public func updateNearbyServices() {
        guard let location = locationService.currentLocation else {
            Logger.error("Location not available for emergency services search")
            return
        }
        
        // Enhanced location validation
        let locationAge = abs(location.timestamp.timeIntervalSinceNow)
        let accuracy = location.horizontalAccuracy
        
        // Quality-based validation
        if accuracy <= 50 && locationAge <= 30 {
            Logger.location("Using high-quality location data (±\(Int(accuracy))m, \(Int(locationAge))s old)")
        } else if accuracy <= 100 && locationAge <= 60 {
            Logger.location("Using acceptable location data (±\(Int(accuracy))m, \(Int(locationAge))s old)")
        } else {
            Logger.warning("Location data may be inaccurate (±\(Int(accuracy))m, \(Int(locationAge))s old)")
        }

        let searchTypes = [
            EmergencyServiceType(name: "Hospital", query: "hospital", icon: "cross.case.fill"),
            EmergencyServiceType(name: "Police", query: "police", icon: "shield.lefthalf.filled"),
            EmergencyServiceType(name: "Fire Station", query: "fire station", icon: "flame.fill")
        ]
        
        for serviceType in searchTypes {
            searchNearbyService(location: location, serviceType: serviceType)
        }
    }
    
    public func searchNearbyService(location: CLLocation, serviceType: EmergencyServiceType) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = serviceType.query
        
        // Use dynamic search radius based on location quality
        let searchRadius = location.horizontalAccuracy <= 50 ? 5000.0 : // 5km for accurate location
                          location.horizontalAccuracy <= 100 ? 8000.0 : // 8km for good location
                          10000.0 // 10km for less accurate location
        
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: searchRadius,
            longitudinalMeters: searchRadius
        )
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.error("Failed to search for \(serviceType.name): \(error.localizedDescription)")
                return
            }
            
            guard let response = response else {
                Logger.error("No response for \(serviceType.name) search")
                return
            }
            
            let services = response.mapItems.prefix(3).map { item -> EmergencyService in
                let distance = item.placemark.location?.distance(from: location)
                return EmergencyService(
                    id: UUID(),
                    name: item.name ?? "Unknown",
                    type: serviceType.name,
                    icon: serviceType.icon,
                    address: self.formatAddress(from: item.placemark),
                    coordinate: item.placemark.coordinate,
                    phoneNumber: item.phoneNumber,
                    distance: distance
                )
            }
            
            // Process updates in a thread-safe way
            self.queue.async {
                // Create a new array with updated services
                var updatedServices = self.nearbyServices.filter { service in
                    !services.contains { $0.type == service.type }
                }
                updatedServices.append(contentsOf: services)
                
                // Sort by distance if available
                updatedServices.sort { (s1, s2) in
                    guard let d1 = s1.distance, let d2 = s2.distance else { return false }
                    return d1 < d2
                }
                
                // Update on main thread with complete array
                DispatchQueue.main.async {
                    self.nearbyServices = updatedServices
                }
            }
        }
    }
    
    public func formatAddress(from placemark: MKPlacemark) -> String {
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode
        ].compactMap { $0 }
        
        return components.joined(separator: ", ")
    }
}
