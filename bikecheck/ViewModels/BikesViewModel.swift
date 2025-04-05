import SwiftUI
import CoreData

class BikesViewModel: ObservableObject {
    @Published var bikes: [Bike] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var uiImage: UIImage?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadBikes()
    }
    
    func loadBikes() {
        isLoading = true
        
        let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest() as! NSFetchRequest<Bike>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Bike.name, ascending: false)]
        
        do {
            bikes = try context.fetch(fetchRequest)
            isLoading = false
        } catch {
            print("Failed to fetch bikes: \(error)")
            self.error = error
            isLoading = false
        }
    }
    
    func getTotalRideTime(for bike: Bike) -> String {
        return String(format: "%.2f hrs", bike.rideTime(context: context))
    }
    
    func deleteBike(_ bike: Bike) {
        context.delete(bike)
        saveContext()
        loadBikes()
    }
    
    func createDefaultServiceIntervals(for bike: Bike) {
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