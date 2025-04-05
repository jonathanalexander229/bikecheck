import Foundation
import Combine
import CoreData

class ServiceViewModel: ObservableObject {
    @Published var serviceIntervals: [ServiceInterval] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadServiceIntervals()
    }
    
    func loadServiceIntervals() {
        isLoading = true
        
        let fetchRequest: NSFetchRequest<ServiceInterval> = ServiceInterval.fetchRequest() as! NSFetchRequest<ServiceInterval>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceInterval.startTime, ascending: true)]
        
        do {
            serviceIntervals = try context.fetch(fetchRequest)
            isLoading = false
        } catch {
            print("Failed to fetch service intervals: \(error)")
            self.error = error
            isLoading = false
        }
    }
    
    func calculateTimeUntilService(for serviceInterval: ServiceInterval) -> Double {
        let totalRideTime = serviceInterval.bike.rideTime(context: context)
        let startTime = serviceInterval.startTime
        let intervalTime = serviceInterval.intervalTime
        
        let currentIntervalTime = totalRideTime - startTime
        return intervalTime - currentIntervalTime
    }
    
    func getTimeUntilServiceText(for serviceInterval: ServiceInterval) -> String {
        let timeUntilService = calculateTimeUntilService(for: serviceInterval)
        return String(format: "%.2f", timeUntilService)
    }
    
    func deleteInterval(serviceInterval: ServiceInterval) {
        context.delete(serviceInterval)
        saveContext()
        loadServiceIntervals()
    }
    
    func resetInterval(serviceInterval: ServiceInterval) {
        serviceInterval.startTime = serviceInterval.bike.rideTime(context: context)
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