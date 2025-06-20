import XCTest

class BikeCheckUITestCase: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        
        // Handle onboarding if it appears
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        if onboardingOverlay.element.waitForExistence(timeout: 3) {
            // Skip onboarding to get to login screen
            app.buttons["Skip Tour"].tap()
        }
        
        // Use Insert Test Data button to load test data and sign in
        if app.buttons["Insert Test Data"].waitForExistence(timeout: 3) {
            app.buttons["Insert Test Data"].tap()
            
            // Wait for main app to be visible
            _ = app.tabBars["Tab Bar"].waitForExistence(timeout: 10)
        }
    }
    
    override func tearDown() {
        // Reset app state after each test to ensure clean slate for next test
        app.launchEnvironment = ["RESET_APP_STATE": "true"]
        app.launch()
        app.terminate()
        super.tearDown()
    }
    
    // Helper methods for common UI test operations
    func navigateToTab(_ tabName: String) {
        let tabButton = app.tabBars["Tab Bar"].buttons[tabName]
        XCTAssertTrue(tabButton.waitForExistence(timeout: 5))
        tabButton.tap()
    }
    
    func verifyNavigationBar(_ title: String) -> Bool {
        return app.navigationBars[title].waitForExistence(timeout: 5)
    }
}