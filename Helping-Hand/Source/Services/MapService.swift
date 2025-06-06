import Foundation
import MapKit
import Combine

class MapService {
    func getDirections(to destination: CLLocationCoordinate2D, from source: CLLocationCoordinate2D? = nil) -> AnyPublisher<MKRoute, Error> {
        return Future<MKRoute, Error> { promise in
            let request = MKDirections.Request()
            
            // Set the source location
            if let source = source {
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
            } else {
                // Use current location
                request.source = MKMapItem.forCurrentLocation()
            }
            
            // Set destination
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = .automobile
            
            // Request directions
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                if let route = response?.routes.first {
                    promise(.success(route))
                } else {
                    promise(.failure(NSError(domain: "MapService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No route found"])))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func geocodeAddress(_ address: String) -> AnyPublisher<CLLocationCoordinate2D, Error> {
        return Future<CLLocationCoordinate2D, Error> { promise in
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                if let location = placemarks?.first?.location?.coordinate {
                    promise(.success(location))
                } else {
                    promise(.failure(NSError(domain: "MapService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location not found"])))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func searchPointsOfInterest(query: String, near coordinate: CLLocationCoordinate2D, radius: CLLocationDistance = 5000) -> AnyPublisher<[MKMapItem], Error> {
        return Future<[MKMapItem], Error> { promise in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            
            // Set the search region
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: radius * 2,
                longitudinalMeters: radius * 2
            )
            request.region = region
            
            // Perform local search
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                if let mapItems = response?.mapItems {
                    promise(.success(mapItems))
                } else {
                    promise(.success([]))
                }
            }
        }.eraseToAnyPublisher()
    }
}
