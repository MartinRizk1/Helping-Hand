import CoreLocation

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onError: ((Error) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let accuracy = location.horizontalAccuracy
        let timestamp = location.timestamp
        let age = abs(timestamp.timeIntervalSinceNow)
        
        print("📍 Real-time Location Update:")
        print("   Coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("   Accuracy: ±\(accuracy)m")
        print("   Age: \(String(format: "%.1f", age))s")
        print("   Speed: \(location.speed >= 0 ? "\(String(format: "%.1f", location.speed))m/s" : "N/A")")
        
        // Enhanced filtering for real-time location tracking
        // Accept locations that are:
        // - Recent (less than 15 seconds old)
        // - Accurate (better than 100 meters for general use, or any positive accuracy)
        // - Valid (accuracy > 0 means valid reading)
        
        let isRecent = age < 15.0
        let isAccurate = accuracy > 0 && accuracy < 100.0
        let isValid = accuracy > 0
        
        if isRecent && isValid && (isAccurate || accuracy < 1000) {
            print("✅ Accepting real-time location update")
            onLocationUpdate?(location)
        } else {
            print("⚠️ Filtering out location - Recent: \(isRecent), Valid: \(isValid), Accurate: \(isAccurate)")
            print("   Accuracy threshold: < 100m preferred, < 1000m acceptable")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error.localizedDescription)")
        onError?(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔐 Authorization status changed to: \(status.rawValue)")
        onAuthorizationChange?(status)
    }
}
