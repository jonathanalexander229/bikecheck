//
//  bikecheckApp.swift
//  bikecheck
//
//  Created by clutchcoder on 1/2/24.
//
import SwiftUI
import BackgroundTasks

@main
struct bikecheckApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var stravaHelper = StravaHelper(context: PersistenceController.shared.container.viewContext)
    let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if stravaHelper.isSignedIn ?? false {
                    HomeView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(stravaHelper)
                } else {
                    LoginView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(stravaHelper)
                }
            }
        }
        .backgroundTask(.appRefresh("checkServiceInterval")) { task in
            // Check if the user is signed in before proceeding with the background task
            if await stravaHelper.isSignedIn ?? false {
                print("Background task checkServiceInterval executed.")
                await stravaHelper.checkServiceIntervals()

                // Schedule the next background task
                // Note: This scheduling should be done carefully to avoid immediate re-triggering
                // Consider using a more appropriate scheduling mechanism or conditions
            }
        }
        .backgroundTask(.appRefresh("fetchActivities")) { task in
            print("Background task fetchActivities executed.")
            await stravaHelper.fetchActivities { _ in }
            // Schedule the next background task
            // Note: Implement scheduling logic here if needed
        }
    }
}