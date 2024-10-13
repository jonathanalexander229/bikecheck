//
//  ContentView.swift
//  bikecheck
//
//  Created by clutchcoder on 1/2/24.
//

import SwiftUI
import CoreData
import UserNotifications
import BackgroundTasks

struct ActivitiesView: View {

    @State private var showingAddServiceIntervalView = false

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaHelper: StravaHelper
    //@State private var bikesViewModel: BikesViewModel? = nil
    @Binding var uiImage: UIImage?
    
    @FetchRequest(
        entity: TokenInfo.entity(), sortDescriptors: [],
        animation: .default)
    private var tokenInfo: FetchedResults<TokenInfo>
    
    @FetchRequest(
        entity: Athlete.entity(), sortDescriptors: [],
        animation: .default)
    private var athlete: FetchedResults<Athlete>
    
    @FetchRequest(
        entity: Bike.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Bike.name, ascending: false)],
        animation: .default)
    private var bikes: FetchedResults<Bike>
    
    @FetchRequest(
        entity: Activity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.startDate, ascending: false)],
        predicate: NSPredicate(format: "type == %@", "Ride"),
        animation: .default)
    private var activities: FetchedResults<Activity>
    
    @FetchRequest(
        entity: ServiceInterval.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceInterval.startTime, ascending: true)]
    ) var serviceIntervals: FetchedResults<ServiceInterval>
    
    var body: some View {
        NavigationView {
            List {
                
                ForEach(Array(activities), id: \.self) { activity in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(activity.name)
                            Spacer()
                        }
                        HStack {
                            Text("\(String(format: "%.2f", Double(activity.movingTime) / 3600)) hours")
                            Spacer()
                            Text("\(String(format: "%.2f", activity.distance / 1000)) km")
                        }
                        HStack {
                            Text("\(bikes.first(where: { $0.id == activity.gearId })?.name ?? "none")")
                            Spacer()
                            Text("\(DateFormatter.localizedString(from: activity.startDate, dateStyle: .medium, timeStyle: .none))")
                        }
                    }
                }
            }
            .navigationTitle("Activites")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: profileImage)
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
                EmptyView()
            }
        }
    }
}
