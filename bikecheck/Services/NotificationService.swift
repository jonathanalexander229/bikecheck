import UserNotifications
import BackgroundTasks
import os.log

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.bikecheck", category: "Notifications")
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            completion(granted, error)
        }
    }
    
    func sendNotification(for interval: ServiceInterval) {
        if interval.notify {
            print("Sending notification")
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "\(interval.bike.name) Service Reminder"
            content.body = "It's time to service your \(interval.part)."
            content.sound = UNNotificationSound.default
            
            // Explicitly set the app icon badge
            content.badge = 1
            
            // Create unique identifier for this notification
            let identifier = "bikecheck-service-\(interval.objectID.uriRepresentation().absoluteString)"
            
            // Create the request with no delay
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            
            // Add the notification request
            center.add(request) { (error) in
                if let error = error {
                    self.logger.error("Error adding notification request: \(error.localizedDescription)")
                    print("Error adding notification request: \(error.localizedDescription)")
                } else {
                    self.logger.info("Notification request added successfully")
                    print("Notification request added successfully")
                }
            }
        }
    }
    
    func scheduleBackgroundTask() {
        print("scheduling serviceInt Notification background task")
        // Delegate scheduling to the BackgroundTaskManager
        BackgroundTaskManager.shared.scheduleBackgroundTask(identifier: .checkServiceInterval)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Received notification while in the foreground")
        completionHandler([.banner, .sound])
    }
}