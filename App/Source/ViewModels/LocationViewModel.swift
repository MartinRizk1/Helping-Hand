import Foundation
import CoreLocation
import Combine

class LocationViewModel: ObservableObject {
    @Published var userLocation: CLLocation?
    @Published var locationError: Error?
    @Published var isLocationAccessGranted = false
    
    private let locationManager = CLLocationManager()
    private var locationManagerDelegate: LocationManagerDelegate?
    private var isSetup = false
    
    init() {
        setupLocationManager()
    }
    
    deinit {
        // Clean up location manager when view model is deallocated
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        locationManagerDelegate = nil
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupLocationManager() {
        locationManagerDelegate = LocationManagerDelegate()
        locationManagerDelegate?.onLocationUpdate = { [weak self] location in
            DispatchQueue.main.async {
                self?.userLocation = location
            }
        }
        locationManagerDelegate?.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.locationError = error
            }
        }
        locationManagerDelegate?.onAuthorizationChange = { [weak self] status in
            DispatchQueue.main.async {
                self?.isLocationAccessGranted = status == .authorizedWhenInUse || status == .authorizedAlways
                if self?.isLocationAccessGranted == true {
                    self?.locationManager.startUpdatingLocation()
                }
            }
        }
        
        locationManager.delegate = locationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update every 50 meters
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
}

// Using the LocationManagerDelegate from LocationManagerDelegate.swift
