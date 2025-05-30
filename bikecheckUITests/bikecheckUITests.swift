//
//  bikecheckUITests.swift
//  bikecheckUITests
//
//  Created by clutchcoder on 1/2/24.
//

import XCTest
@testable import bikecheck

final class bikecheckUITests: BikeCheckUITestCase {
    
    // app is inherited from BikeCheckUITestCase
    
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
        // Test data already loaded by base class
        
        XCTAssertTrue(app.tabBars["Tab Bar"].buttons["Service Intervals"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars["Tab Bar"].buttons["Bikes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars["Tab Bar"].buttons["Activities"].waitForExistence(timeout: 5))
        navigateToTab("Service Intervals")
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))
        
        navigateToTab("Bikes")
        XCTAssertTrue(verifyNavigationBar("Bikes"))
        
        navigateToTab("Activities")
        XCTAssertTrue(verifyNavigationBar("Activities"))
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func test3_ServiceIntervalView() throws {
        // Navigate to Service Intervals tab
        navigateToTab("Service Intervals")
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))
        
        // Check if service intervals exist in the list
        let serviceIntervalCells = app.cells
        if serviceIntervalCells.count > 0 {
            // Tap on the first service interval to view/edit it
            let firstServiceInterval = serviceIntervalCells.firstMatch
            XCTAssertTrue(firstServiceInterval.waitForExistence(timeout: 3))
            firstServiceInterval.tap()
            
            // Verify we're in the service interval detail/edit form by validating form fields
            XCTAssertTrue(app.textFields["Part"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.textFields["Interval Time (hrs)"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.switches["Notify"].waitForExistence(timeout: 3))
            
            // Verify action buttons for existing intervals
            XCTAssertTrue(app.buttons["Reset Interval"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3))
            
            // Navigate back to service intervals list
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        // Verify we're back at the service intervals list
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))
    }
    
    func test4_ServiceIntervalCreate() throws {
        // Navigate to Service Intervals tab
        navigateToTab("Service Intervals")
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))
        
        // Test adding a new service interval
        let addButton = app.navigationBars["Service Intervals"].buttons["Add"]
        if addButton.exists {
            addButton.tap()
            
            // Verify the add service interval form appeared by validating form fields and navigation
            XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 3))
            
            // Verify form elements for new interval
            XCTAssertTrue(app.textFields["Part"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.textFields["Interval Time (hrs)"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.switches["Notify"].waitForExistence(timeout: 3))
            
            // Test form interaction - enter some data
            app.textFields["Part"].tap()
            app.textFields["Part"].typeText("Chain")
            
            app.textFields["Interval Time (hrs)"].tap()
            app.textFields["Interval Time (hrs)"].typeText("100")
            
            // Toggle notify switch
            app.switches["Notify"].tap()
            
            // Cancel the add operation
            app.buttons["Cancel"].tap()
        }
        
        // Verify we're back at the service intervals list
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))
    }
    
    func test5_ServiceIntervalReset() throws {
        // Navigate to Service Intervals tab
        navigateToTab("Service Intervals")
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))
        
        // Check if service intervals exist in the list
        let serviceIntervalCells = app.cells
        if serviceIntervalCells.count > 0 {
            // Tap on the first service interval to view/edit it
            let firstServiceInterval = serviceIntervalCells.firstMatch
            XCTAssertTrue(firstServiceInterval.waitForExistence(timeout: 3))
            firstServiceInterval.tap()
            
            // Get interval time value before reset
            let intervalTimeField = app.textFields["Interval Time (hrs)"]
            XCTAssertTrue(intervalTimeField.waitForExistence(timeout: 3))
            let intervalTimeValue = intervalTimeField.value as? String ?? ""
            
            // Test reset functionality
            XCTAssertTrue(app.buttons["Reset Interval"].waitForExistence(timeout: 3))
            app.buttons["Reset Interval"].tap()
            
            let resetAlert = app.alerts["Confirm Reset Interval"]
            if resetAlert.waitForExistence(timeout: 3) {
                XCTAssertTrue(resetAlert.buttons["Cancel"].exists)
                XCTAssertTrue(resetAlert.buttons["Reset"].exists)
                resetAlert.buttons["Reset"].tap()
                
                // After reset, verify time until service equals interval time
                // The time until service value should now equal the interval time value
                let timeUntilServiceValue = app.staticTexts[intervalTimeValue]
                XCTAssertTrue(timeUntilServiceValue.waitForExistence(timeout: 3), "Time until service value (\(intervalTimeValue)) should be displayed after reset")
            }
            
            // Navigate back to service intervals list
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        // Verify we're back at the service intervals list
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))
    }
    
    func test6_BikeDetailFlow() throws {
        // Navigate to Bikes tab
        navigateToTab("Bikes")
        XCTAssertTrue(verifyNavigationBar("Bikes"))
        
        // Check if bikes exist in the list
        let bikeCells = app.cells
        if bikeCells.count > 0 {
            // Tap on the first bike
            let firstBike = bikeCells.firstMatch
            XCTAssertTrue(firstBike.waitForExistence(timeout: 3))
            firstBike.tap()
            
            // Verify we navigated to bike detail view
            XCTAssertTrue(verifyNavigationBar("Bike Details"))
            
            // Verify we're in bike detail view by checking action buttons exist
            let createServiceIntervalsButton = app.buttons["Create Default Service Intervals"]
            let deleteButton = app.buttons["Delete"]
            XCTAssertTrue(createServiceIntervalsButton.waitForExistence(timeout: 3))
            XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
            
            // Test create default service intervals flow
            createServiceIntervalsButton.tap()
            
            // Verify alert appears
            let alert = app.alerts["Service Intervals Created"]
            if alert.waitForExistence(timeout: 3) {
                let okButton = alert.buttons["OK"]
                XCTAssertTrue(okButton.exists)
                okButton.tap()
                
                // Should navigate to Service Intervals tab
                XCTAssertTrue(verifyNavigationBar("Service Intervals"))
                
                // Navigate back to bikes to continue testing
                navigateToTab("Bikes")
                XCTAssertTrue(verifyNavigationBar("Bikes"))
                
                // Tap on the first bike again
                firstBike.tap()
                XCTAssertTrue(verifyNavigationBar("Bike Details"))
            }
            
            // Test delete confirmation dialog
            deleteButton.tap()
            
            // Verify confirmation alert appears
            let confirmAlert = app.alerts["Confirm Deletion"]
            if confirmAlert.waitForExistence(timeout: 3) {
                let cancelButton = confirmAlert.buttons["Cancel"]
                XCTAssertTrue(cancelButton.exists)
                cancelButton.tap()
                
                // Should still be on bike details
                XCTAssertTrue(verifyNavigationBar("Bike Details"))
            }
            
            // Navigate back to bikes list
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(verifyNavigationBar("Bikes"))
        }
    }
    
    func test7_CrossTabNavigation() throws {
        // Test navigation between tabs and verify state persistence
        
        // Start at Service Intervals
        navigateToTab("Service Intervals")
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))
        
        // Navigate to Bikes
        navigateToTab("Bikes")
        XCTAssertTrue(verifyNavigationBar("Bikes"))
        
        // If bikes exist, enter bike detail
        let bikeCells = app.cells
        if bikeCells.count > 0 {
            bikeCells.firstMatch.tap()
            XCTAssertTrue(verifyNavigationBar("Bike Details"))
            
            // Navigate back and verify we're still on Bikes tab
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(verifyNavigationBar("Bikes"))
        }
        
        // Navigate to Activities
        navigateToTab("Activities")
        XCTAssertTrue(verifyNavigationBar("Activities"))
        
        // Go back to Service Intervals
        navigateToTab("Service Intervals")
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))
        
        // Test that service interval list is still accessible
        let servicesCells = app.cells
        XCTAssertTrue(servicesCells.firstMatch.waitForExistence(timeout: 3))
    }
}
