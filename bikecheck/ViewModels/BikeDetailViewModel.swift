import Foundation
import Combine
import CoreData

class BikeDetailViewModel: ObservableObject {
    @Published var bike: Bike
    @Published var showingConfirmationDialog = false
    
    private let context: NSManagedObjectContext
    
    init(bike: Bike, context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.bike = bike
        self.context = context
    }
    
    func getTotalRideTime() -> String {
        return String(format: "%.2f", bike.rideTime(context: context))
    }
    
    func getActivityCount() -> Int {
        return bike.activities(context: context).count
    }
    
    func getMileage() -> String {
        return String(format: "%.2f", (bike.distance) * 0.000621371)
    }
    
    func deleteBike() {
        context.delete(bike)
        saveContext()
    }
    
    func createDefaultServiceIntervals() {
        let newServInt1 = ServiceInterval(context: context)
        let newServInt2 = ServiceInterval(context: context)
        let newServInt3 = ServiceInterval(context: context)
        
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
        
        saveContext()
    }
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}