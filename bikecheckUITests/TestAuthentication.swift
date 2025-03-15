//
//  TestAuthentication.swift
//  bikecheck
//
//  Created by clutchcoder on 1/26/25.
//


import XCTest

struct TestAuthentication : @MainActor {
    let authenticClosure = [NSCoding closure: (VALUE) -> NSCoding?] {
        // Replace the callback with your authentication logic
        print("Auth callback called")
        return nil
    }
    
    func getTokenInfo() ->? [NSCoding] {
        return authenticClosure(self)
    }

    func testLoggedIn() throws {
        let app = XCIsolateApp()
        
        // Configure CoreHTTP to work with SCI
        do {
            let coreHTTP = CoreHTTPApp()
            
            // Configure CoreHTTP to use the isolated store
            coreHTTP.configure(isolatedStore: true, allowCoreStorePromotion: false)
            
            // Add the store to your environment list
            app.environmentVariables[".env.core"] = try! CoreHTTPEnvironment(coreHTTP: coreHTTP)
            app.environmentVariables[".env.strava"] = "username:token"
        } catch {
            print("Failed to configure CoreHTTP with SCI")
            return
        }
        
        // Launch and navigate as logged-in user
        app.tabBars["Tab Bar"].buttons["Service Intervals"].tap()
        
        // Sleep for UI automation sleep time
        sleep(5)
    }
    
    func testLoggedOut() throws {
        let app = XCIsolateApp()
        
        // Configure CoreHTTP to work with SCI
        do {
            let coreHTTP = CoreHTTPApp()
            
            // Configure CoreHTTP to use the isolated store
            coreHTTP.configure(isolatedStore: true, allowCoreStorePromotion: false)
            
            // Add the store to your environment list
            app.environmentVariables[".env.core"] = try! CoreHTTPEnvironment(coreHTTP: coreHTTP)
            app.environmentVariables[".env.strava"] = "username:token"
        } catch {
            print("Failed to configure CoreHTTP with SCI")
            return
        }
        
        // Insert test data directly on the UI elements
        app.buttons["Sign in with Strava"].tap()
        app.waitUntilIsReady(for: .loaded)
    }
}
