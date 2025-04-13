import Foundation
import CoreData
@testable import bikecheck

/// A mock implementation of PersistenceController for testing purposes
class MockPersistenceController {
    static let shared = MockPersistenceController()
    
    let container: NSPersistentContainer
    var saveWasCalled = false
    var shouldThrowOnSave = false
    
    init() {
        // Create an in-memory data store for testing
        let container = NSPersistentContainer(name: "bikecheck")
        
        // Configure the persistent store to be in-memory
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Failed to load in-memory persistent stores: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.container = container
    }
    
    func reset() {
        saveWasCalled = false
        shouldThrowOnSave = false
        
        // Delete all records from the context
        let entities = container.managedObjectModel.entities
        let context = container.viewContext
        
        // Instead of using NSBatchDeleteRequest, manually delete all objects
        for entityName in entities.compactMap({ $0.name }) {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            do {
                let objects = try context.fetch(fetchRequest)
                for object in objects {
                    context.delete(object)
                }
            } catch {
                print("Failed to fetch and delete objects of entity \(entityName): \(error)")
            }
        }
        
        // Save the context to apply deletions
        do {
            try context.save()
        } catch {
            print("Failed to save context after reset: \(error)")
        }
    }
    
    private func clearEntity(_ entity: String) {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity)
        
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                context.delete(object)
            }
            try context.save()
        } catch {
            print("Failed to clear entity \(entity): \(error)")
        }
    }
    
    func saveContext() {
        saveWasCalled = true
        
        if shouldThrowOnSave {
            // Simulates a save error by modifying the context without saving
            return
        }
        
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Mock error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// Helper method to create test data in the in-memory store
    func createTestData() {
        let context = container.viewContext
        
        // Create test athlete
        let athlete = NSEntityDescription.insertNewObject(forEntityName: "Athlete", into: context) as! Athlete
        athlete.id = 123456
        athlete.firstname = "Test User"
        athlete.profile = "https://example.com/profile.jpg"
        
        // Create test bikes
        let bike1 = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike1.id = "bike1"
        bike1.name = "Test Bike 1"
        bike1.distance = 1000.0
        bike1.athlete = athlete
        
        let bike2 = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike2.id = "bike2"
        bike2.name = "Test Bike 2"
        bike2.distance = 2000.0
        bike2.athlete = athlete
        
        // Create test activities
        let activity1 = NSEntityDescription.insertNewObject(forEntityName: "Activity", into: context) as! Activity
        activity1.id = 1001
        activity1.gearId = "bike1"
        activity1.name = "Test Ride 1"
        activity1.type = "Ride"
        activity1.movingTime = 3600
        activity1.startDate = Date()
        activity1.distance = 20000.0
        activity1.averageSpeed = 5.5
        
        let activity2 = NSEntityDescription.insertNewObject(forEntityName: "Activity", into: context) as! Activity
        activity2.id = 1002
        activity2.gearId = "bike1"
        activity2.name = "Test Ride 2"
        activity2.type = "Ride"
        activity2.movingTime = 7200
        activity2.startDate = Date().addingTimeInterval(-86400)
        activity2.distance = 40000.0
        activity2.averageSpeed = 5.5
        
        // Create test service intervals
        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.startTime = 0
        serviceInterval.intervalTime = 10
        serviceInterval.notify = true
        serviceInterval.bike = bike1
        
        // Save the context
        saveContext()
    }
}

// Extension to make the mock compatible with the real PersistenceController API
extension MockPersistenceController: PersistenceControllerProtocol {}

// Protocol to allow dependency injection with either real or mock controller
protocol PersistenceControllerProtocol {
    var container: NSPersistentContainer { get }
    func saveContext()
}

// Make the real PersistenceController conform to the protocol
extension PersistenceController: PersistenceControllerProtocol {}
