import SwiftUI
import BackgroundTasks
import os.log

@main
struct bikecheckApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var stravaService = StravaService.shared
    
    // ViewModels as StateObjects at app level to maintain consistent state
    @StateObject var bikesViewModel = BikesViewModel()
    @StateObject var activitiesViewModel = ActivitiesViewModel()
    @StateObject var serviceViewModel = ServiceViewModel()
    @StateObject var loginViewModel = LoginViewModel()
    
    private let logger = Logger(subsystem: "com.bikecheck", category: "AppLifecycle")
    
    init(){
        // Configure background tasks during app initialization
        configureBackgroundTasks()
        
        // this is still needed for some reason, stravaService doesnt init without it
    }
    
    private func configureBackgroundTasks() {
        // Initialize task tracking
        BackgroundTaskManager.shared.initializeTasks()
        
        // Register tasks with the system
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "checkServiceInterval", using: nil) { task in
            self.handleServiceIntervalTask(task)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "fetchActivities", using: nil) { task in
            self.handleFetchActivitiesTask(task)
        }
        
        // Schedule initial tasks
        BackgroundTaskManager.shared.scheduleAllBackgroundTasks()
        
        logger.info("Background tasks configured")
    }
    
    private func handleServiceIntervalTask(_ task: BGTask) {
        Task {
            if await stravaService.isSignedIn ?? false {
                logger.info("Background task checkServiceInterval executed")
                await stravaService.checkServiceIntervals()
                logger.info("Service interval check completed")
            } else {
                logger.info("Skipping checkServiceInterval task - user not signed in")
            }
            
            // Reschedule the task for future execution
            BackgroundTaskManager.shared.scheduleBackgroundTask(identifier: .checkServiceInterval)
            
            // Mark task as completed
            task.setTaskCompleted(success: true)
        }
    }
    
    private func handleFetchActivitiesTask(_ task: BGTask) {
        Task {
            logger.info("Background task fetchActivities executed")
            
            await stravaService.fetchActivities { result in
                switch result {
                case .success:
                    logger.info("Activity fetch completed successfully")
                case .failure(let error):
                    logger.error("Activity fetch failed: \(error.localizedDescription)")
                }
            }
            
            // Reschedule the task for future execution
            BackgroundTaskManager.shared.scheduleBackgroundTask(identifier: .fetchActivities)
            
            // Mark task as completed
            task.setTaskCompleted(success: true)
        }
    }

    
    var body: some Scene {
        WindowGroup {
            Group {
                if stravaService.isSignedIn ?? false {
                    HomeView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(stravaService)
                        .environmentObject(bikesViewModel)
                        .environmentObject(activitiesViewModel)
                        .environmentObject(serviceViewModel)
                } else {
                    LoginView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(stravaService)
                        .environmentObject(loginViewModel)
                }
            }
            .onAppear {
                // Check for UI testing mode and auto-load test data
                if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                    stravaService.insertTestData()
                }
            }
        }
//        .backgroundTask(.appRefresh("checkServiceInterval")) { _ in
//            // Check if the user is signed in before proceeding with the background task
//            if await stravaService.isSignedIn ?? false {
//                logger.info("Background task checkServiceInterval executed")
//                await stravaService.checkServiceIntervals()
//                logger.info("Service interval check completed")
//            } else {
//                logger.info("Skipping checkServiceInterval task - user not signed in")
//            }
//            
//            // Reschedule the task for future execution
//            BackgroundTaskManager.shared.scheduleBackgroundTask(identifier: .checkServiceInterval)
//        }
//        .backgroundTask(.appRefresh("fetchActivities")) { _ in
//            logger.info("Background task fetchActivities executed")
//            
//            await stravaService.fetchActivities { result in
//                switch result {
//                case .success:
//                    logger.info("Activity fetch completed successfully")
//                case .failure(let error):
//                    logger.error("Activity fetch failed: \(error.localizedDescription)")
//                }
//            }
//            
//            // Reschedule the task for future execution
//            BackgroundTaskManager.shared.scheduleBackgroundTask(identifier: .fetchActivities)
//        }
    }
}
