import XCTest
import CoreLocation
@testable import HelpingHand

class AIServiceTests: XCTestCase {
    var sut: AIService!
    
    override func setUp() {
        super.setUp()
        sut = AIService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testQueryIntentDetection() {
        // Test different query intents
        
        // Food-related query
        let (foodIntent, foodConfidence, _) = sut.analyzeQueryIntent("Where can I find good pizza nearby?")
        XCTAssertEqual(foodIntent, .findFood)
        XCTAssertGreaterThan(foodConfidence, 0.7)
        
        // Coffee-related query
        let (coffeeIntent, coffeeConfidence, _) = sut.analyzeQueryIntent("I need coffee now")
        XCTAssertEqual(coffeeIntent, .findCoffee)
        XCTAssertGreaterThan(coffeeConfidence, 0.7)
        
        // Shopping-related query
        let (shoppingIntent, shoppingConfidence, _) = sut.analyzeQueryIntent("Where is the nearest mall?")
        XCTAssertEqual(shoppingIntent, .findShopping)
        XCTAssertGreaterThan(shoppingConfidence, 0.6)
        
        // Health-related query
        let (healthIntent, healthConfidence, _) = sut.analyzeQueryIntent("I need to find a pharmacy")
        XCTAssertEqual(healthIntent, .findHealthcare)
        XCTAssertGreaterThan(healthConfidence, 0.7)
        
        // Ambiguous query
        let (ambiguousIntent, ambiguousConfidence, _) = sut.analyzeQueryIntent("Show me places nearby")
        XCTAssertEqual(ambiguousIntent, .generalSearch)
        XCTAssertLessThan(ambiguousConfidence, 0.6) // Lower confidence for ambiguous queries
    }
    
    func testAppleQueryClarification() {
        // Test the special case handling for "apple" queries
        
        // Query that should resolve to Apple Store
        let (appleStoreQuery, appleStoreCategory) = sut.clarifyAppleQuery("Where is the nearest Apple Store?")
        XCTAssertTrue(appleStoreQuery.contains("Apple Store"))
        XCTAssertEqual(appleStoreCategory, "electronics")
        
        // Query that should resolve to grocery apples
        let (groceryQuery, groceryCategory) = sut.clarifyAppleQuery("I want to buy fresh apples")
        XCTAssertTrue(groceryQuery.contains("grocery") || groceryQuery.contains("supermarket"))
        XCTAssertEqual(groceryCategory, "grocery")
        
        // Ambiguous query that should include both options
        let (ambiguousQuery, ambiguousCategory) = sut.clarifyAppleQuery("Show me apple locations")
        XCTAssertTrue(ambiguousQuery.contains("OR") || ambiguousQuery.contains("apple store") && ambiguousQuery.contains("grocery"))
        XCTAssertTrue(ambiguousCategory == "electronics" || ambiguousCategory == "shopping")
    }
    
    func testAIRecommendation() {
        // Test AI recommendation for place categories based on time
        let morningRecommendation = sut.getTimeBasedRecommendation(hour: 8)
        XCTAssertTrue(morningRecommendation.contains("coffee") || morningRecommendation.contains("breakfast"))
        
        let lunchRecommendation = sut.getTimeBasedRecommendation(hour: 12)
        XCTAssertTrue(lunchRecommendation.contains("lunch") || lunchRecommendation.contains("restaurant"))
        
        let eveningRecommendation = sut.getTimeBasedRecommendation(hour: 19)
        XCTAssertTrue(eveningRecommendation.contains("dinner") || eveningRecommendation.contains("restaurant"))
        
        let nightRecommendation = sut.getTimeBasedRecommendation(hour: 23)
        XCTAssertTrue(nightRecommendation.contains("open late") || nightRecommendation.contains("24-hour"))
    }
    
    func testSentimentAnalysis() {
        // Test sentiment analysis capability
        
        // Positive sentiment
        let positiveScore = sut.analyzeSentiment("I love finding great restaurants and coffee shops!")
        XCTAssertGreaterThan(positiveScore, 0.5)
        
        // Negative sentiment
        let negativeScore = sut.analyzeSentiment("I hate waiting in long lines at crowded places.")
        XCTAssertLessThan(negativeScore, 0.0)
        
        // Neutral sentiment
        let neutralScore = sut.analyzeSentiment("Show me locations near me.")
        XCTAssertEqual(neutralScore, 0.0, accuracy: 0.3)
    }
}
