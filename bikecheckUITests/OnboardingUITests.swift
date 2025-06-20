import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    override func tearDown() {
        // Reset app state after each test to ensure clean slate for next test
        app.launchEnvironment = ["RESET_APP_STATE": "true"]
        app.launch()
        app.terminate()
        super.tearDown()
    }
    
    func testOnboardingFlow() throws {
        // Verify onboarding overlay appears on first launch
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5), "Onboarding overlay should appear on first launch")
        
        // Verify welcome step content
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        XCTAssertTrue(app.staticTexts["Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started."].exists)
        
        // Verify choice buttons exist
        XCTAssertTrue(app.buttons["Skip Tour"].exists)
        XCTAssertTrue(app.buttons["Take the Tour"].exists)
        
        // Take the tour to complete onboarding and load test data
        app.buttons["Take the Tour"].tap()
        
        // Verify onboarding overlay is dismissed and main content is visible
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5), "Main app should be visible after onboarding completion")
    }
    
    func testOnboardingSkipTour() throws {
        // Verify onboarding overlay appears
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5))
        
        // Verify welcome step content
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        XCTAssertTrue(app.staticTexts["Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started."].exists)
        
        // Verify choice buttons exist
        XCTAssertTrue(app.buttons["Skip Tour"].exists)
        XCTAssertTrue(app.buttons["Take the Tour"].exists)
        
        // Tap Skip Tour to bypass onboarding
        app.buttons["Skip Tour"].tap()
        
        // Verify onboarding overlay is dismissed and user remains on login screen
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Sign in with Strava"].waitForExistence(timeout: 3), "Should remain on login screen after skipping tour")
    }
    
    func testOnboardingButtonInteraction() throws {
        // Verify onboarding overlay appears
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5))
        
        // Verify welcome step content
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        XCTAssertTrue(app.staticTexts["Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started."].exists)
        
        // Verify choice buttons exist
        XCTAssertTrue(app.buttons["Skip Tour"].exists)
        XCTAssertTrue(app.buttons["Take the Tour"].exists)
        
        // Choose "Take the Tour" to complete onboarding
        app.buttons["Take the Tour"].tap()
        
        // Verify onboarding is dismissed
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5))
    }
    
    func testOnboardingPersistence() throws {
        // Complete onboarding flow
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5))
        
        // Verify welcome content exists
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        XCTAssertTrue(app.staticTexts["Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started."].exists)
        
        // Skip onboarding to complete it
        app.buttons["Skip Tour"].tap()
        
        // Verify user remains on login screen
        XCTAssertTrue(app.buttons["Sign in with Strava"].waitForExistence(timeout: 3))
        
        // Terminate and relaunch app to test persistence (without reset flag)
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "RESET_APP_STATE")
        app.launch()
        
        // Verify onboarding does NOT appear on subsequent launches
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Sign in with Strava"].waitForExistence(timeout: 3), "Should show login screen directly on subsequent launches")
    }
}
