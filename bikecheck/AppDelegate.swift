//
//  AppDelegate.swift
//  bikecheck
//
//  Created by clutchcoder on 1/31/24.
//

import SwiftUI
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        NotificationCenter.default.addObserver(self, selector: #selector(saveContext), name: UIApplication.willResignActiveNotification, object: nil)
        // Register your background tasks here
        UNUserNotificationCenter.current().delegate = self
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bikecheck.fetchAthlete", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bikecheck.fetchActivities", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bikecheck.checkServiceInterval", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        scheduleAppRefresh()
        print("didFinishLaunchingWithOptions called")
        return true
    }

    // This method will be called when the app goes to the background
    @objc func saveContext() {
        print("saveContext called")
       // scheduleAppRefresh()
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        print("handleAppRefresh called")
        let context = PersistenceController.shared.container.newBackgroundContext()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        let stravaHelper = StravaHelper(context: context)
       // let notificationManager = NotificationManager()

        if task.identifier == "com.bikecheck.fetchAthlete" {
            stravaHelper.getAthlete() { _ in
                task.setTaskCompleted(success: true)
            }
        } else if task.identifier == "com.bikecheck.fetchActivities" {
            stravaHelper.fetchActivities() { _ in
                task.setTaskCompleted(success: true)
            }
        } else
        if task.identifier == "com.bikecheck.checkServiceInterval" {
            // Fetch your ServiceInterval objects and check each one
          //  notificationManager.sendNotification()
//            let serviceIntervals = stravaHelper.fetchServiceIntervals()
//            for servInt in serviceIntervals {
//                //let timeUntilService = stravaHelper.calculateTimeUntilService(for: servInt)
//                //if timeUntilService <= 0 {
//                    
//               //     notificationManager.sendNotification(for: servInt)
//               // }
 //           }
            task.setTaskCompleted(success: true)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground called")
        scheduleAppRefresh()
    }

    func scheduleAppRefresh() {
        print("scheduleAppRefresh called")
        let fetchAthleteTask = BGAppRefreshTaskRequest(identifier: "com.bikecheck.fetchAthlete")
        fetchAthleteTask.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 300) // Fetch after 1 minute

        let fetchActivitiesTask = BGAppRefreshTaskRequest(identifier: "com.bikecheck.fetchActivities")
        fetchActivitiesTask.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 300) // Fetch after 1 minute

        let checkServiceIntervalTask = BGAppRefreshTaskRequest(identifier: "com.bikecheck.checkServiceInterval")
        checkServiceIntervalTask.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 30) // Check after 1 minute

        do {
            try BGTaskScheduler.shared.submit(fetchAthleteTask)
            try BGTaskScheduler.shared.submit(fetchActivitiesTask)
            try BGTaskScheduler.shared.submit(checkServiceIntervalTask)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Display the notification alert and play the notification sound even if the app is in the foreground
        print("willPresent called")
        completionHandler([.alert, .sound])
    }
}
