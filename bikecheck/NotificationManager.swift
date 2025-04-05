//
//  NotificationService.swift
//  bikecheck
//
//  Created by clutchcoder on 3/2/24.
//
import UserNotifications
import BackgroundTasks

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    let center = UNUserNotificationCenter.current()

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                // Handle the error here.
                print("Error: \(error)")
            }
            // Handle the case where the user does not grant permission.
        }
    }

    func sendNotification(for interval: ServiceInterval) {
        if interval.notify {    
            print("Sending notification")
            let content = UNMutableNotificationContent()
            content.title = "\(interval.bike.name) Service Reminder"
            content.body = "It's time to service your \(interval.part)."
            content.sound = UNNotificationSound.default

        // Add a deep link to the notification
        //  let url = URL(string: "bikecheck://serviceInterval/\(interval.id)")!
        //  content.userInfo = ["targetURL": url.absoluteString]
                
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            
            center.add(request) { (error) in
                if let error = error {
                    print("Error adding notification request: \(error.localizedDescription)")
                } else {
                    print("Notification request added successfully")
                }
            }
        }
    }
    func scheduleBackgroundTask() {
        //sendNotification()
        print("scheduling serviceInt Notification background task")
        let request = BGAppRefreshTaskRequest(identifier: "checkServiceInterval")
        request.earliestBeginDate = Calendar.current.date(byAdding: .minute, value: 6, to: Date())// 6 hours from now
        print(request)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
}