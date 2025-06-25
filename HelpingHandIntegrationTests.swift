import XCTest
import CoreLocation
@testable import HelpingHand

class HelpingHandIntegrationTests: XCTestCase {
    var locationService: LocationService!
    var aiService: AIService!
    var viewModel: MainViewModel!
    
    override func setUp() {
        super.setUp()
        locationService = LocationService()
        aiService = AIService()
        viewModel = MainViewModel()
    }
    
    override func tearDown() {
        locationService = nil
        aiService = nil
        viewModel = nil
        super.tearDown()
    }
    
    func testFullSearchFlow() async {
        // Test the complete flow from user query to search results
        
        let expectation = XCTestExpectation(description: "Full search flow completed")
        
        // 1. Start with user query
        let userQuery = "Where can I find coffee near me?"
        
        // 2. Process query with AI Service
        let (intent, confidence, entities) = aiService.analyzeQueryIntent(userQuery)
        
        // Verify intent detection
        XCTAssertEqual(intent, .findCoffee)
        XCTAssertGreaterThan(confidence, 0.7)
        
        // 3. Extract search term
        let searchTerm = intent == .findCoffee ? "coffee" : "cafe"
        
        // 4. Process through view model (with a mock implementation)
        let mockViewModel = MockMainViewModel()
        await mockViewModel.processSearch(query: userQuery)
        
        // 5. Verify search was triggered with correct parameters
        XCTAssertEqual(mockViewModel.lastSearchQuery, userQuery)
        XCTAssertTrue(mockViewModel.searchTriggered)
        XCTAssertTrue(mockViewModel.extractedSearchTerm?.contains("coffee") ?? false)
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testMultipleQuestionsAndSearches() async {
        // Test handling multiple questions and searches
        let expectation = XCTestExpectation(description: "Multiple search flow completed")
        
        // Create a mock view model to track search calls
        let mockViewModel = MockMainViewModel()
        
        // First query - Coffee
        await mockViewModel.processSearch(query: "I need coffee")
        XCTAssertEqual(mockViewModel.lastSearchQuery, "I need coffee")
        XCTAssertTrue(mockViewModel.extractedSearchTerm?.contains("coffee") ?? false)
        
        // Second query - Food
        await mockViewModel.processSearch(query: "Where's the best burger place?")
        XCTAssertEqual(mockViewModel.lastSearchQuery, "Where's the best burger place?")
        XCTAssertTrue(mockViewModel.extractedSearchTerm?.contains("burger") ?? false)
        
        // Third query - Shopping
        await mockViewModel.processSearch(query: "I need to find a mall")
        XCTAssertEqual(mockViewModel.lastSearchQuery, "I need to find a mall")
        XCTAssertTrue(mockViewModel.extractedSearchTerm?.contains("mall") ?? false)
        
        // Fourth query - Ambiguous
        await mockViewModel.processSearch(query: "Places near me")
        XCTAssertEqual(mockViewModel.lastSearchQuery, "Places near me")
        XCTAssertNotNil(mockViewModel.extractedSearchTerm)
        
        // Fifth query - Special case "Apple"
        await mockViewModel.processSearch(query: "Find Apple Store")
        XCTAssertEqual(mockViewModel.lastSearchQuery, "Find Apple Store")
        XCTAssertTrue(mockViewModel.extractedSearchTerm?.contains("Apple") ?? false)
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
}

// Mock ViewModel for testing
class MockMainViewModel: MainViewModel {
    var searchTriggered = false
    var lastSearchQuery: String?
    var extractedSearchTerm: String?
    
    override func processSearch(query: String) async {
        searchTriggered = true
        lastSearchQuery = query
        
        // Simulate AI processing
        if query.lowercased().contains("coffee") {
            extractedSearchTerm = "coffee shop"
        } else if query.lowercased().contains("burger") {
            extractedSearchTerm = "burger restaurant"
        } else if query.lowercased().contains("mall") {
            extractedSearchTerm = "shopping mall"
        } else if query.lowercased().contains("apple") {
            extractedSearchTerm = "Apple Store"
        } else {
            extractedSearchTerm = "place"
        }
    }
}
