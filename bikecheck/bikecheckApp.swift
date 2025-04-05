import SwiftUI
import BackgroundTasks

@main
struct bikecheckApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var stravaHelper = StravaHelper(context: PersistenceController.shared.container.viewContext)
    
    // ViewModels as StateObjects at app level to maintain consistent state
    @StateObject var bikesViewModel: BikesViewModel
    @StateObject var activitiesViewModel: ActivitiesViewModel
    @StateObject var serviceViewModel: ServiceViewModel
    @StateObject var loginViewModel: LoginViewModel
    
    let notificationDelegate = NotificationDelegate()
    
    init() {
        // Initialize the ViewModels with their dependencies
        let context = PersistenceController.shared.container.viewContext
        
        // Create a shared stravaHelper instance
        let sharedStravaHelper = StravaHelper(context: context)
        _stravaHelper = StateObject(wrappedValue: sharedStravaHelper)
        
        // Initialize ViewModels
        _bikesViewModel = StateObject(wrappedValue: BikesViewModel(context: context))
        _activitiesViewModel = StateObject(wrappedValue: ActivitiesViewModel(context: context))
        _serviceViewModel = StateObject(wrappedValue: ServiceViewModel(context: context))
        _loginViewModel = StateObject(wrappedValue: LoginViewModel(stravaHelper: sharedStravaHelper))
        
        UNUserNotificationCenter.current().delegate = notificationDelegate
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
        .backgroundTask(.appRefresh("checkServiceInterval")) { task in
            // Check if the user is signed in before proceeding with the background task
            if await stravaHelper.isSignedIn {
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