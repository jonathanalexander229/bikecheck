//
//  NotificationDelegate.swift
//  bikecheck
//
//  Created by clutchcoder on 3/4/24.
//

import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Received notification while in the foreground")
        completionHandler([.banner, .sound])
    }
}
