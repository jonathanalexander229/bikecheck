import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "bikecheck")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func resetAllData() {
        let context = container.viewContext
        
        // Create fetch requests for all entities
        let bikeRequest: NSFetchRequest<NSFetchRequestResult> = Bike.fetchRequest()
        let activityRequest: NSFetchRequest<NSFetchRequestResult> = Activity.fetchRequest()
        let serviceIntervalRequest: NSFetchRequest<NSFetchRequestResult> = ServiceInterval.fetchRequest()
        let athleteRequest: NSFetchRequest<NSFetchRequestResult> = Athlete.fetchRequest()
        let tokenRequest: NSFetchRequest<NSFetchRequestResult> = TokenInfo.fetchRequest()
        
        // Create batch delete requests
        let bikesDelete = NSBatchDeleteRequest(fetchRequest: bikeRequest)
        let activitiesDelete = NSBatchDeleteRequest(fetchRequest: activityRequest)
        let serviceIntervalsDelete = NSBatchDeleteRequest(fetchRequest: serviceIntervalRequest)
        let athleteDelete = NSBatchDeleteRequest(fetchRequest: athleteRequest)
        let tokenDelete = NSBatchDeleteRequest(fetchRequest: tokenRequest)
        
        do {
            // Execute batch deletes
            try context.execute(serviceIntervalsDelete)
            try context.execute(activitiesDelete)
            try context.execute(bikesDelete)
            try context.execute(athleteDelete)
            try context.execute(tokenDelete)
            
            // Save context
            try context.save()
            
            // Reset UserDefaults
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            
            // Reset StravaService state on main queue
            DispatchQueue.main.async {
                let stravaService = StravaService.shared
                stravaService.isSignedIn = false
                stravaService.tokenInfo = nil
                stravaService.athlete = nil
                stravaService.bikes = nil
                stravaService.activities = nil
                stravaService.profileImage = nil
            }
            
            print("Successfully reset all app data")
            
        } catch {
            print("Failed to reset app data: \(error)")
        }
    }
}