import XCTest

class BikeCheckUITestCase: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        
        // Mock services automatically provide test data when UI_TESTING launch argument is present
        // No need to tap any buttons
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