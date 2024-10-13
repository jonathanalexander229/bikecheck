//
//  AddServiceIntervalView.swift
//  bikecheck
//
//  Created by clutchcoder on 2/27/24.
//
import SwiftUI
import CoreData

struct AddServiceIntervalView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @State private var showingConfirmationDialog = false
    @State var serviceIntervalID: UUID?


    @FetchRequest(
        entity: Bike.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Bike.id, ascending: true)]
    ) var bikes: FetchedResults<Bike>

    @State private var part = ""
    @State private var startTime: Double = 0
    @State private var intervalTime = "" // Change this to String
    @State private var notify = false
    @State private var isEditing = false
    @State private var selectedBike: Bike?
    @State var serviceInterval: ServiceInterval?

    var body: some View {
        NavigationView {
            List {
                Picker("Bike", selection: $selectedBike) {
                    ForEach(bikes, id: \.self) { bike in
                        Text(bike.name).tag(bike as Bike?)
                    }
                }
                .onAppear {
                    if selectedBike == nil && !bikes.isEmpty {
                        selectedBike = bikes.first
                    }
                }
                HStack {
                    Text("Part:")
                    Spacer()
                    TextField("Part", text: $part)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Interval Time (hrs)")
                    Spacer()
                    TextField("Interval Time (hrs)", text: $intervalTime).keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                if let serviceInterval = serviceInterval {
                    HStack {
                        Text("Time until service (hrs)")
                        Spacer()
                        Text(String(format: "%.2f", calculateTimeUntilService(serviceInterval: serviceInterval)))
                            .multilineTextAlignment(.trailing)
                    }
                }
                Toggle(isOn: $notify) {
                    Text("Notify")
                }
                Spacer()
                if let serviceInterval = serviceInterval {
                        // Button(action: {
                        //     // Reset the startTime to 0
                        //     serviceInterval.startTime = selectedBike!.rideTime(context: managedObjectContext)
                        //     // Add code to save the context after resetting if necessary
                        // }) {
                        //     Text("Reset Interval").foregroundColor(.blue)
                        // }
                        // .frame(maxWidth: .infinity, alignment: .center)
                        Button(action: {
                            showingConfirmationDialog = true
                        }) {
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .alert(isPresented: $showingConfirmationDialog) {
                            Alert(
                                title: Text("Confirm Removal"),
                                message: Text("Are you sure you want to remove this service interval?"),
                                primaryButton: .destructive(Text("Remove")) {
                                    self.managedObjectContext.delete(serviceInterval)
                                    
                                    do {
                                        try self.managedObjectContext.save()
                                    } catch {
                                        // Handle the error appropriately
                                        print("Failed to delete service interval: \(error)")
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                }
            }.onAppear() {
                if let serviceInterval = serviceInterval {
                    // Populate the fields with the data from the ServiceInterval
                    self.part = serviceInterval.part
                    self.startTime = serviceInterval.startTime
                    self.intervalTime = String(serviceInterval.intervalTime)
                    self.notify = serviceInterval.notify
                    self.selectedBike = serviceInterval.bike
                }
            }
            .onDisappear() {
                // Assuming you have a method to check if there are changes
                if hasChanges() {
                    saveChanges()
                }
                if let serviceInterval = serviceInterval {
                    if serviceInterval.notify {
                        NotificationManager().scheduleBackgroundTask()
                    }
                }
            }.navigationBarItems(trailing: serviceInterval == nil ? saveButton : nil)
         //   .navigationBarTitle(Text("Service Interval"), displayMode: .inline)
            
        }
    }

    private func calculateTimeUntilService(serviceInterval: ServiceInterval) -> Double {
        guard let bike = selectedBike else { return 0 }
        let totalRideTime = bike.rideTime(context: managedObjectContext)
        let startTime = serviceInterval.startTime
        let intervalTime = serviceInterval.intervalTime

        let currentIntervalTime = totalRideTime - startTime
        return intervalTime - currentIntervalTime
    }
    
    var saveButton: some View {
        Button("Save") {
            if serviceInterval == nil {
                let newServiceInterval = serviceInterval ?? ServiceInterval(context: self.managedObjectContext)
                newServiceInterval.part = self.part
                newServiceInterval.intervalTime = Double(self.intervalTime) ?? 0
                newServiceInterval.notify = self.notify
                if let selectedBike = self.selectedBike {
                    newServiceInterval.startTime = selectedBike.rideTime(context: managedObjectContext)
                    newServiceInterval.bike = selectedBike
                } else {
                    // Handle the case where selectedBike is nil
                    print("Error: No bike selected.")
                }
                do {
                    try self.managedObjectContext.save()
                    // Dismiss the view after saving
                } catch {
                    // Handle the error
                }
                self.presentationMode.wrappedValue.dismiss()
            }
            isEditing.toggle()
        }
    }



    func hasChanges() -> Bool {
        guard let serviceInterval = serviceInterval else {
            // If there's no existing serviceInterval, assume changes if any field is not default
            return !(part.isEmpty && intervalTime == "0" && !notify && selectedBike == nil)
        }
        // Compare current state with the serviceInterval's properties to determine if there are changes
        return part != serviceInterval.part ||
            startTime != serviceInterval.startTime ||
            intervalTime != String(serviceInterval.intervalTime) ||
            notify != serviceInterval.notify //||
           // selectedBike != serviceInterval.bike
    }

    func saveChanges() {
        guard let existingServiceInterval = serviceInterval else {
        // If serviceInterval is nil, do nothing
            return
        }

     //   let newOrExistingServiceInterval = serviceInterval ?? ServiceInterval(context: self.managedObjectContext)
        existingServiceInterval.part = self.part
        existingServiceInterval.startTime = self.startTime
        existingServiceInterval.intervalTime = Double(self.intervalTime) ?? 0
        existingServiceInterval.notify = self.notify
        existingServiceInterval.bike = self.selectedBike ?? bikes.first!
        
        do {
            try self.managedObjectContext.save()
        } catch {
            // Handle the error appropriately
            print("Error saving service interval: \(error)")
        }
    }
}
