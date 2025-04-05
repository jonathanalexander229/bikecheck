import SwiftUI
import BackgroundTasks

@main
struct bikecheckApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var stravaHelper = StravaHelper(context: PersistenceController.shared.container.viewContext)
    
    // ViewModels as StateObjects at app level to maintain consistent state
    @StateObject var bikesViewModel = BikesViewModel()
    @StateObject var activitiesViewModel = ActivitiesViewModel()
    @StateObject var serviceViewModel = ServiceViewModel()
    @StateObject var loginViewModel = LoginViewModel(stravaHelper: StravaHelper.shared)
    
    let notificationDelegate = NotificationDelegate()
    
    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        setupBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if stravaHelper.isSignedIn {
                    HomeView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(stravaHelper)
                        .environmentObject(bikesViewModel)
                        .environmentObject(activitiesViewModel)
                        .environmentObject(serviceViewModel)
                } else {
                    LoginView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(stravaHelper)
                        .environmentObject(loginViewModel)
                }
            }
        }
        .backgroundTask(.appRefresh("com.bikecheck.checkServiceInterval")) { task in
            if await stravaHelper.isSignedIn {
                print("Background task checkServiceInterval executed.")
                await stravaHelper.checkServiceIntervals()
            }
        }
        .backgroundTask(.appRefresh("com.bikecheck.fetchActivities")) { task in
            print("Background task fetchActivities executed.")
            await stravaHelper.fetchActivities { _ in }
        }
    }
    
    private func setupBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bikecheck.fetchActivities", using: nil) { task in
            handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bikecheck.checkServiceInterval", using: nil) { task in
            handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        if task.identifier == "com.bikecheck.fetchActivities" {
            stravaHelper.fetchActivities { result in
                switch result {
                case .success:
                    task.setTaskCompleted(success: true)
                case .failure:
                    task.setTaskCompleted(success: false)
                }
            }
        } else if task.identifier == "com.bikecheck.checkServiceInterval" {
            stravaHelper.checkServiceIntervals()
            task.setTaskCompleted(success: true)
        }
    }
}