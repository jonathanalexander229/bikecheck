import SwiftUI

struct HomeView: View {
    @State private var showingAddServiceIntervalView = false
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var bikesViewModel: BikesViewModel
    @EnvironmentObject var activitiesViewModel: ActivitiesViewModel
    @EnvironmentObject var serviceViewModel: ServiceViewModel
    @State var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ServiceView()
                .tabItem {
                    VStack {
                        Image(systemName: "timer")
                        Text("Service Intervals")
                    }
                }
                .tag(0)
            
            BikesView(selectedTab: $selectedTab)
                .tabItem {
                    VStack {
                        Image(systemName: "bicycle")
                        Text("Bikes")
                    }
                }
                .tag(1)
            
            ActivitiesView()
                .tabItem {
                    VStack {
                        Image(systemName: "waveform.path.ecg")
                        Text("Activities")
                    }
                }
                .tag(2)
        }.onAppear {
            requestNotificationPermission()
            fetchStravaData()
        }
    }

    private func fetchStravaData() {
        stravaService.checkServiceIntervals()
        stravaService.getAthlete { _ in }
        stravaService.fetchActivities { _ in }
        
        // Refresh ViewModels after data fetch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            bikesViewModel.loadBikes()
            activitiesViewModel.loadActivities()
            serviceViewModel.loadServiceIntervals()
        }
    }

    private func requestNotificationPermission() {
        NotificationService.shared.requestAuthorization { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            } else if !granted {
                print("Notification permissions not granted")
            } else {
                print("Notification permissions granted")
            }
        }
    }
}