import XCTest
import CoreData
@testable import bikecheck

class PersistenceControllerTests: XCTestCase {
    
    var sut: PersistenceController!
    
    override func setUp() {
        super.setUp()
        // Create a PersistenceController with in-memory store for testing
        sut = PersistenceController(inMemory: true)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialization() {
        // Test that the container is properly initialized
        XCTAssertNotNil(sut.container)
        XCTAssertTrue(sut.container.persistentStoreDescriptions.first?.url?.absoluteString.contains("/dev/null") ?? false)
    }
    
    func testViewContextConfiguration() {
        // Test that the viewContext is properly configured
        let context = sut.container.viewContext
        
        XCTAssertTrue(context.automaticallyMergesChangesFromParent)
        XCTAssertTrue(context.mergePolicy is NSMergePolicy)
    }
    
    func testSaveContext() {
        let context = sut.container.viewContext
        
        // Create a test bike entity with proper initialization in the context
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-id"
        bike.name = "Test Bike"
        bike.distance = 100.0
        
        // Test that saveContext saves the changes
        XCTAssertNoThrow(sut.saveContext())
        
        // Verify the entity was saved
        let fetchRequest: NSFetchRequest<Bike> = NSFetchRequest<Bike>(entityName: "Bike")
        fetchRequest.predicate = NSPredicate(format: "id == %@", "test-id")
        
        do {
            let fetchedBikes = try context.fetch(fetchRequest)
            XCTAssertEqual(fetchedBikes.count, 1)
            XCTAssertEqual(fetchedBikes.first?.name, "Test Bike")
            XCTAssertEqual(fetchedBikes.first?.distance, 100.0)
        } catch {
            XCTFail("Failed to fetch bike: \(error)")
        }
    }
    
    func testSaveContextWithNoChanges() {
        // Test that saveContext doesn't throw when there are no changes
        XCTAssertNoThrow(sut.saveContext())
    }
    
    func testPersistentStoreCoordinator() {
        // Test that the persistent store coordinator is properly configured
        let coordinator = sut.container.persistentStoreCoordinator
        
        XCTAssertEqual(coordinator.persistentStores.count, 1)
        
        // Test entity count by getting actual entities
        let entityNames = sut.container.managedObjectModel.entities.map { $0.name ?? "" }
        XCTAssertTrue(entityNames.contains("Bike"))
        XCTAssertTrue(entityNames.contains("Activity"))
        XCTAssertTrue(entityNames.contains("Athlete"))
        XCTAssertTrue(entityNames.contains("TokenInfo"))
    }
}
