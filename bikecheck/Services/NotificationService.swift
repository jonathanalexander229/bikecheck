import UserNotifications
import BackgroundTasks

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    let center = UNUserNotificationCenter.current()
    
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
            let content = UNMutableNotificationContent()
            content.title = "\(interval.bike.name) Service Reminder"
            content.body = "It's time to service your \(interval.part)."
            content.sound = UNNotificationSound.default
            
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
        print("scheduling serviceInt Notification background task")
        let request = BGAppRefreshTaskRequest(identifier: "checkServiceInterval")
        request.earliestBeginDate = Calendar.current.date(byAdding: .minute, value: 6, to: Date())
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Received notification while in the foreground")
        completionHandler([.banner, .sound])
    }
}