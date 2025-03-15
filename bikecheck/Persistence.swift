//
//  Persistence.swift
//  BikeCheck
//
//  Created by clutchcoder on 12/29/23.
//

import CoreData

struct PersistenceController {
    static let shared: PersistenceController = {
            // Use an environment variable to determine if the store should be in-memory
            guard let useInMemoryStore = Bool(ProcessInfo.processInfo.environment["USE_IN_MEMORY_STORE"] ?? "false") else {
                return PersistenceController(inMemory: false)
            }
            return PersistenceController(inMemory: useInMemoryStore)
        }()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newTokenInfo = TokenInfo(context: viewContext)
            newTokenInfo.accessToken = "testAccessToken"
            newTokenInfo.refreshToken = "testRefreshToken"
            // Set other properties of newTokenInfo...
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "bikecheck")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
           
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
         // Set the merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        if inMemory {
            if (Bool(ProcessInfo.processInfo.environment["LOGGED_IN"] ?? "false")!){
                insertTestData()
            }
        }
    }
    
    func insertTestData() {
        let viewContext = container.viewContext
        
        // for _ in 0..<10 {
        let newTokenInfo = TokenInfo(context: viewContext)
        newTokenInfo.accessToken = "953ff94ea69feea5cc5521e2d44abeea242dd3ae"
        newTokenInfo.refreshToken = "447b364e34d996523d72370f509973f51934f5c5"
        newTokenInfo.expiresAt = 9999999999
        let newAthlete = Athlete(context: viewContext)
        newAthlete.firstname = "Jonathan"
        newAthlete.id = 26493868
        newTokenInfo.athlete = newAthlete
        // Set other properties of newTokenInfo...
        // }
        
        do {
            try viewContext.save()
        } catch {
            fatalError("Unresolved error \(error), \(error)")
        }
    }
}
