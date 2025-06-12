import Foundation
import CoreLocation

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out inaccurate locations for real-time precision
        let locationAge = abs(location.timestamp.timeIntervalSinceNow)
        let horizontalAccuracy = location.horizontalAccuracy
        
        // Only accept recent, accurate locations
        if locationAge < 15.0 && horizontalAccuracy < 100 && horizontalAccuracy > 0 {
            print("📍 Valid location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("📍 Accuracy: \(horizontalAccuracy)m, Age: \(locationAge)s")
            onLocationUpdate?(location)
        } else {
            print("⚠️ Filtered out inaccurate location: accuracy=\(horizontalAccuracy)m, age=\(locationAge)s")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error.localizedDescription)")
        onError?(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔐 Location authorization status changed to: \(status.rawValue)")
        onAuthorizationChange?(status)
    }
    
    // For iOS 14+ precision authorization changes
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("🔐 Location authorization changed - Status: \(manager.authorizationStatus.rawValue)")
        print("🔐 Accuracy authorization: \(manager.accuracyAuthorization.rawValue)")
        onAuthorizationChange?(manager.authorizationStatus)
    }
}
