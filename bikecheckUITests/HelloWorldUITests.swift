import XCTest

class HelloWorldUITests: XCTestCase {
    func testExample() {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["Hello, World!"].exists)
    }
}