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
                Button(action: {
                    createDefaultServiceIntervals(bike: bike)
                }) {
                    Text("Create Default Service Intervals")
                        .foregroundColor(.blue)
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
    
    func createDefaultServiceIntervals(bike: Bike) {
        let newServInt1 = ServiceInterval(context: viewContext)
        let newServInt2 = ServiceInterval(context: viewContext)
        let newServInt3 = ServiceInterval(context: viewContext)
        
        newServInt2.intervalTime = 5
        newServInt2.startTime = 0
        newServInt2.bike = bike
        newServInt2.part = "chain"
        newServInt2.notify = true
        
        newServInt3.intervalTime = 10
        newServInt3.startTime = 0
        newServInt3.bike = bike
        newServInt3.part = "Fork Lowers"
        newServInt3.notify = true
        
        newServInt1.intervalTime = 15
        newServInt1.startTime = 0
        newServInt1.bike = bike
        newServInt1.part = "Shock"
        newServInt1.notify = true
        
        do {
            try viewContext.save()
//            DispatchQueue.main.async {
//            }
            
        } catch {
            fatalError("Unresolved error \(error), \(error)")
        }
    
    }

}

//#Preview {
//    BikeViewDetail()
//}
