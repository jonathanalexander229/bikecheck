import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        // Don't disable onboarding for these tests - we want to test the onboarding flow
        app.launch()
    }
    
    func testOnboardingFlow() throws {
        // Verify onboarding overlay appears on first launch
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5), "Onboarding overlay should appear on first launch")
        
        // Verify welcome step content
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        XCTAssertTrue(app.staticTexts["Track your bike maintenance effortlessly"].exists)
        
        // Verify onboarding controls exist
        XCTAssertTrue(app.buttons["Skip Tour"].exists)
        XCTAssertTrue(app.buttons["Next"].exists)
        
        // Tap Next to proceed to second step
        app.buttons["Next"].tap()
        
        // Verify sign-in step content
        XCTAssertTrue(app.staticTexts["Connect Your Riding Data"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Import your bikes and rides automatically"].exists)
        
        // Tap Next to proceed to third step
        app.buttons["Next"].tap()
        
        // Verify test data step content
        XCTAssertTrue(app.staticTexts["Try Demo Mode"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Explore with sample data first"].exists)
        
        // Tap Next to complete onboarding
        app.buttons["Next"].tap()
        
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
        
        // Tap Skip Tour to bypass onboarding
        app.buttons["Skip Tour"].tap()
        
        // Verify onboarding overlay is dismissed and main content is visible
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5), "Main app should be visible after skipping onboarding")
    }
    
    func testOnboardingTapToAdvance() throws {
        // Verify onboarding overlay appears
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5))
        
        // Verify welcome step content
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        
        // Tap anywhere on the overlay to advance (testing tap gesture)
        onboardingOverlay.element.tap()
        
        // Verify we advanced to sign-in step
        XCTAssertTrue(app.staticTexts["Connect Your Riding Data"].waitForExistence(timeout: 3))
        
        // Tap again to advance
        onboardingOverlay.element.tap()
        
        // Verify we advanced to test data step
        XCTAssertTrue(app.staticTexts["Try Demo Mode"].waitForExistence(timeout: 3))
        
        // Tap again to complete onboarding
        onboardingOverlay.element.tap()
        
        // Verify onboarding is dismissed
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5))
    }
    
    func testOnboardingPersistence() throws {
        // Complete onboarding flow
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5))
        
        // Skip onboarding to complete it
        app.buttons["Skip Tour"].tap()
        
        // Verify main app is visible
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5))
        
        // Terminate and relaunch app to test persistence
        app.terminate()
        app.launch()
        
        // Verify onboarding does NOT appear on subsequent launches
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5), "Main app should appear directly on subsequent launches")
    }
}