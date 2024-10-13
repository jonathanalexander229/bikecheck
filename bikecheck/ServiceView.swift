//
//  ServiceView.swift
//  bikecheck
//
//  Created by clutchcoder on 4/30/24.
//

import SwiftUI
import CoreData
import UserNotifications
import BackgroundTasks

struct ServiceView: View {

    @State private var showingServiceIntervalView = false

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
//                Button(action: {
//                    showingAddServiceIntervalView = true
//                }) {
//                    HStack {
//                        Image(systemName: "plus.circle.fill")
//                        Text("Add New Service Interval")
//                    }
//                    .foregroundColor(.blue)
//                }
//                .sheet(isPresented: $showingAddServiceIntervalView) {
//                    ServiceIntervalView()
//                }
                ForEach(Array(serviceIntervals), id: \.self) { servInt in
                    NavigationLink(destination: AddServiceIntervalView(serviceInterval: servInt)
                       // .navigationBarItems(trailing: editButton)
                    ) {
                        VStack(alignment: .leading) {
                            Text(servInt.bike.name )
                                .font(.subheadline)
                            let totalRideTime = servInt.bike.rideTime(context: viewContext)
                            let startTime = servInt.startTime
                            let intervalTime = servInt.intervalTime

                            let currentIntervalTime = totalRideTime - startTime
                            let timeUntilService = intervalTime - currentIntervalTime

                            
                            HStack {
                                Text("service \(servInt.part.lowercased())").font(.subheadline).italic()
                                Spacer()
                                Text("in \(String(format: "%.2f", timeUntilService)) hrs")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Service Intervals")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: profileImage,
                trailing: addButton
            ).sheet(isPresented: $showingServiceIntervalView) {
                    AddServiceIntervalView()
            }
        }
        
    }
    
    var editButton: some View {
        Button(action: {
            // Add your edit action here
        }) {
            Text("Edit")
        }
    }

    var addButton: some View {
        Button(action: {
            showingServiceIntervalView = true
        }) {
            Image(systemName: "plus")
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
