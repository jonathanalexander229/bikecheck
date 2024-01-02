//
//  bikecheckApp.swift
//  bikecheck
//
//  Created by clutchcoder on 1/2/24.
//

import SwiftUI

@main
struct bikecheckApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
