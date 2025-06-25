import XCTest
import CoreLocation
@testable import HelpingHand

class LocationServiceTests: XCTestCase {
    var sut: LocationService!
    var mockLocationManagerDelegate: MockLocationManagerDelegate!
    
    override func setUp() {
        super.setUp()
        sut = LocationService()
        mockLocationManagerDelegate = MockLocationManagerDelegate()
        sut.locationManagerDelegate = mockLocationManagerDelegate
    }
    
    override func tearDown() {
        sut = nil
        mockLocationManagerDelegate = nil
        super.tearDown()
    }
    
    func testInitialLocation() {
        // Test that the initial location is Dallas (fallback)
        XCTAssertNotNil(sut.currentLocation, "Initial location should not be nil")
        XCTAssertTrue(sut.isUsingFallbackLocation, "Should be using fallback location initially")
        
        // Check Dallas coordinates
        XCTAssertEqual(sut.currentLocation?.coordinate.latitude, 32.7767, accuracy: 0.0001)
        XCTAssertEqual(sut.currentLocation?.coordinate.longitude, -96.7970, accuracy: 0.0001)
    }
    
    func testLocationUpdate() {
        // Simulate a location update
        let newLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco
        
        let expectation = XCTestExpectation(description: "Location update processed")
        
        // Trigger location update
        mockLocationManagerDelegate.onLocationUpdate?(newLocation)
        
        // Wait for async location update to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Verify location was updated
            XCTAssertEqual(self.sut.currentLocation?.coordinate.latitude, 37.7749, accuracy: 0.0001)
            XCTAssertEqual(self.sut.currentLocation?.coordinate.longitude, -122.4194, accuracy: 0.0001)
            XCTAssertFalse(self.sut.isUsingFallbackLocation, "Should not be using fallback after real location update")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAuthorizationChange() {
        // Test authorization status change
        let expectation = XCTestExpectation(description: "Authorization change processed")
        
        // Initially should be not determined
        XCTAssertEqual(sut.authorizationStatus, .notDetermined)
        
        // Trigger authorization change
        mockLocationManagerDelegate.onAuthorizationChange?(.authorizedWhenInUse)
        
        // Wait for async update to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Verify authorization was updated
            XCTAssertEqual(self.sut.authorizationStatus, .authorizedWhenInUse)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testNearbyPlacesSearch() {
        // Test searching for nearby places
        let expectation = XCTestExpectation(description: "Search completed")
        
        // Override the performHybridSearch method to verify it's called correctly
        class TestLocationService: LocationService {
            var searchQuery: String?
            var userQuery: String?
            var searchLocation: CLLocation?
            
            override func performHybridSearch(for query: String, userQuery: String, searchLocation: CLLocation) {
                self.searchQuery = query
                self.userQuery = userQuery
                self.searchLocation = searchLocation
            }
        }
        
        let testService = TestLocationService()
        testService.currentLocation = CLLocation(latitude: 32.7767, longitude: -96.7970)
        
        // Execute search
        testService.searchNearbyPlaces(for: "Find me coffee", query: "coffee")
        
        // Verify search parameters
        XCTAssertEqual(testService.searchQuery, "coffee")
        XCTAssertEqual(testService.userQuery, "Find me coffee")
        XCTAssertEqual(testService.searchLocation?.coordinate.latitude, 32.7767, accuracy: 0.0001)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
}

// Mock LocationManagerDelegate for testing
class MockLocationManagerDelegate: LocationManagerDelegate {
    // Implement the mock delegate
}
