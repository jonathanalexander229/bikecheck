//
//  HomeView.swift
//  bikecheck
//
//  Created by clutchcoder on 4/30/24.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @State private var showingAddServiceIntervalView = false
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaHelper: StravaHelper
    @State private var title = "Service"
    @State private var uiImage: UIImage? = nil
    @State private var selectedTab = 0
    @State private var isChildViewPresented = false
    let notificationDelegate = NotificationDelegate()
    
    @FetchRequest(
        entity: Athlete.entity(), sortDescriptors: [],
        animation: .default)
    private var athlete: FetchedResults<Athlete>
    
    @FetchRequest(
        entity: TokenInfo.entity(), sortDescriptors: [],
        animation: .default)
    private var tokenInfo: FetchedResults<TokenInfo>
    
    @FetchRequest(
        entity: ServiceInterval.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceInterval.startTime, ascending: true)]
    ) var serviceIntervals: FetchedResults<ServiceInterval>

    var body: some View {
                
            TabView(selection: $selectedTab) {
                ServiceView(uiImage: $uiImage)
                    .tabItem {
                        VStack {
                            Image(systemName: "timer")
                            Text("Service Intervals")
                        }
                    }
                    .tag(0)
                BikesView(uiImage: $uiImage)
                    .tabItem {
                        VStack {
                            Image(systemName: "bicycle")
                            Text("Bikes")
                        }
                    }
                    .tag(1)
                ActivitiesView(uiImage: $uiImage)
                    .tabItem {
                        VStack {
                            Image(systemName: "waveform.path.ecg")
                            Text("Activities")
                        }
                    }
                    .tag(2)
        }.onAppear {
            requestNotificationPermission()
            stravaHelper.checkServiceIntervals()
            stravaHelper.getAthlete()  { _ in }
            stravaHelper.fetchActivities { _ in }
            if let urlString = athlete.first?.profile, let url = URL(string: urlString) {
                loadImage(from: url)
            }
    
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    var profileImage: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            }
        }
    }

    var backButton: some View {
        Button(action: {
            self.isChildViewPresented = false
        }) {
            Image(systemName: "arrow.backward")
                .foregroundColor(.blue)
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
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Handle the result
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
