import SwiftUI
import BackgroundTasks

@main
struct bikecheckApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var stravaService = StravaService.shared
    
    // ViewModels as StateObjects at app level to maintain consistent state
    @StateObject var bikesViewModel = BikesViewModel()
    @StateObject var activitiesViewModel = ActivitiesViewModel()
    @StateObject var serviceViewModel = ServiceViewModel()
    @StateObject var loginViewModel = LoginViewModel()
    
    init(){
        // this is still needed for some reason, stravaService doesnt init without it
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
        }
        .backgroundTask(.appRefresh("checkServiceInterval")) { task in
            // Check if the user is signed in before proceeding with the background task
            if await stravaService.isSignedIn ?? false {
                print("Background task checkServiceInterval executed.")
                await stravaService.checkServiceIntervals()
            }
        }
        .backgroundTask(.appRefresh("fetchActivities")) { task in
            print("Background task fetchActivities executed.")
            await stravaService.fetchActivities { _ in }
        }
    }
}
