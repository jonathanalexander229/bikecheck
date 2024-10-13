//
//  BikeViewDetail.swift
//  bikecheck
//
//  Created by clutchcoder on 1/7/24.
//

import SwiftUI

struct BikeDetailView: View {
    @ObservedObject var bike: Bike
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingConfirmationDialog = false

//    var serviceIntervals: FetchRequest<ServiceInterval> {
//        FetchRequest<ServiceInterval>(
//            entity: ServiceInterval.entity(),
//            sortDescriptors: [NSSortDescriptor(keyPath: \ServiceInterval.startTime, ascending: true)],
//            predicate: NSPredicate(format: "bike.id == %d", bike.id)
//        )
//    }


    var body: some View {
        VStack {
            List {
                Text(bike.name)
                Text("\((bike.distance) * 0.000621371, specifier: "%.2f") miles")
                Text("\(Double(bike.activities(context: viewContext).reduce(0) { $0 + $1.movingTime }) / 3600, specifier: "%.2f") hrs")
                Text("\(bike.activities(context: viewContext).count) activities")
                
                
                HStack {
                    Spacer()
                    Button(action: {
                        showingConfirmationDialog = true
                    }) {
                        Text("Delete")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showingConfirmationDialog) {
                        Alert(
                            title: Text("Confirm Deletion"),
                            message: Text("Are you sure you want to delete this bike? (if its a strava bike, it will be re-imported on the next sync)"),
                            primaryButton: .destructive(Text("Delete")) {
                                viewContext.delete(bike)
                                
                                do {
                                    try viewContext.save()
                                } catch {
                                    // Handle the error appropriately
                                    print("Failed to delete bike: \(error)")
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    Spacer()
                }
            }

//            List(serviceIntervals.wrappedValue, id: \.self) { serviceInterval in
//                    Text("Part: \(serviceInterval.part)")
//                    Text("Start Time: \(serviceInterval.startTime)")
//                    Text("Interval Time: \(serviceInterval.intervalTime)")
//                    Text("Notify: \(serviceInterval.notify ? "Yes" : "No")")
//            }
        }
    }
}

//#Preview {
//    BikeViewDetail()
//}
