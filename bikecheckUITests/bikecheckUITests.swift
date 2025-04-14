//
//  bikecheckUITests.swift
//  bikecheckUITests
//
//  Created by clutchcoder on 1/2/24.
//

import XCTest
@testable import bikecheck

final class bikecheckUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
//    func test1_LoggedOut() throws {
//        // UI tests must launch the application that they test.
//        app = XCUIApplication()
//        app.launch()
//                
//        XCTAssertTrue(app.buttons["Sign in with Strava"].waitForExistence(timeout: 5))
//        XCTAssertTrue(app.buttons["Insert Test Data"].waitForExistence(timeout: 5))
//
//    }
    
    func test2_LoggedIn() throws {
        // UI tests must launch the application that they test.
        app = XCUIApplication()
        app.launch()
        
        app.buttons["Insert Test Data"].tap()
        
        XCTAssertTrue(app.tabBars["Tab Bar"].buttons["Service Intervals"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars["Tab Bar"].buttons["Bikes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars["Tab Bar"].buttons["Activities"].waitForExistence(timeout: 5))
        //sleep(5)
        app.tabBars["Tab Bar"].buttons["Service Intervals"].tap()
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 5))
        //sleep(5)
        app.tabBars["Tab Bar"].buttons["Bikes"].tap()
        XCTAssertTrue(app.navigationBars["Bikes"].waitForExistence(timeout: 5))
        //sleep(5)
        app.tabBars["Tab Bar"].buttons["Activities"].tap()
        XCTAssertTrue(app.navigationBars["Activities"].waitForExistence(timeout: 5))
        //sleep(5)
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
