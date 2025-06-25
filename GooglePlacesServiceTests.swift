import XCTest
import CoreLocation
@testable import HelpingHand

class GooglePlacesServiceTests: XCTestCase {
    var sut: GooglePlacesService!
    
    override func setUp() {
        super.setUp()
        sut = GooglePlacesService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // Test with mock URLSession
    func testSearchPlacesValidQuery() async {
        // Create a mock URLSession that returns a valid places response
        let mockURLSession = MockURLSession()
        sut.session = mockURLSession
        
        do {
            let result = try await sut.searchPlaces(
                query: "coffee",
                location: CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970),
                radius: 1000
            )
            
            // Verify the results
            XCTAssertFalse(result.isEmpty, "Search should return results")
            XCTAssertEqual(result.first?.category, .coffee, "First result should be a coffee shop")
        } catch {
            XCTFail("Search should not throw an error: \(error)")
        }
    }
    
    func testSearchPlacesInvalidAPIKey() async {
        // Test with invalid API key
        let originalKey = APIConfig.googlePlacesAPIKey
        APIConfig.googlePlacesAPIKey = "invalid-key"
        
        do {
            _ = try await sut.searchPlaces(
                query: "coffee",
                location: CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970),
                radius: 1000
            )
            XCTFail("Search should throw an error with invalid API key")
        } catch {
            // Expected error
            XCTAssertTrue(error.localizedDescription.contains("API key"), "Error should mention API key")
        }
        
        // Restore original key
        APIConfig.googlePlacesAPIKey = originalKey
    }
    
    func testSearchPlacesNetworkError() async {
        // Create a mock URLSession that simulates a network error
        let mockURLSession = MockURLSession()
        mockURLSession.mockError = NSError(domain: "NetworkError", code: -1, userInfo: nil)
        sut.session = mockURLSession
        
        do {
            _ = try await sut.searchPlaces(
                query: "coffee",
                location: CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970),
                radius: 1000
            )
            XCTFail("Search should throw a network error")
        } catch {
            // Expected error
            XCTAssertEqual((error as NSError).domain, "NetworkError", "Should throw a network error")
        }
    }
}

// Mock URLSession for testing
class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let mockError = mockError {
            throw mockError
        }
        
        let data = mockData ?? createMockPlacesResponse()
        let response = mockResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        return (data, response)
    }
    
    private func createMockPlacesResponse() -> Data {
        // Create a mock Google Places API response
        let json = """
        {
            "results": [
                {
                    "place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
                    "name": "Mock Coffee Shop",
                    "vicinity": "123 Test Street, Dallas, TX",
                    "geometry": {
                        "location": {
                            "lat": 32.7767,
                            "lng": -96.7970
                        }
                    },
                    "rating": 4.5,
                    "types": ["cafe", "food", "point_of_interest", "establishment"]
                }
            ],
            "status": "OK"
        }
        """
        return json.data(using: .utf8)!
    }
}
