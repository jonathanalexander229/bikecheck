import SwiftUI

struct HomeView: View {
    @EnvironmentObject var stravaHelper: StravaHelper
    @StateObject private var bikesViewModel = BikesViewModel()
    @StateObject private var activitiesViewModel = ActivitiesViewModel()
    @StateObject private var serviceViewModel = ServiceViewModel()
    @State private var uiImage: UIImage? = nil
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ServiceView(uiImage: $uiImage)
                .environmentObject(serviceViewModel)
                .tabItem {
                    VStack {
                        Image(systemName: "timer")
                        Text("Service Intervals")
                    }
                }
                .tag(0)
            
            BikesView(uiImage: $uiImage)
                .environmentObject(bikesViewModel)
                .tabItem {
                    VStack {
                        Image(systemName: "bicycle")
                        Text("Bikes")
                    }
                }
                .tag(1)
            
            ActivitiesView(uiImage: $uiImage)
                .environmentObject(activitiesViewModel)
                .tabItem {
                    VStack {
                        Image(systemName: "waveform.path.ecg")
                        Text("Activities")
                    }
                }
                .tag(2)
        }
        .onAppear {
            requestNotificationPermission()
            stravaHelper.checkServiceIntervals()
            stravaHelper.getAthlete { _ in }
            stravaHelper.fetchActivities { _ in }
            
            if let urlString = stravaHelper.athlete?.profile, let url = URL(string: urlString) {
                loadImage(from: url)
            }
        }
    }
    
    func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
        }.resume()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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