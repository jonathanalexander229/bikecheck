import XCTest
import CoreData
@testable import bikecheck

class DataServiceTests: XCTestCase {
    
    var mockPersistenceController: MockPersistenceController!
    var sut: DataService!
    var originalController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        
        // Store the original shared instance
        originalController = PersistenceController.shared
        
        // Create our mock controller
        mockPersistenceController = MockPersistenceController()
        
        // Inject our mock as the shared instance
        // This is the key step - replace the shared instance with our mock
        let mirror = Mirror(reflecting: PersistenceController.self)
        for child in mirror.children {
            if child.label == "shared" {
                if let sharedProperty = child.value as? PersistenceController {
                    // We found the shared instance, but can't replace it directly
                    // Instead we'll use method swizzling or similar techniques
                    // For now, we'll just ensure our tests work with what we have
                }
            }
        }
        
        // Create the data service with our mock's context
        sut = DataService(context: mockPersistenceController.container.viewContext)
    }
    
    override func tearDown() {
        sut = nil
        mockPersistenceController = nil
        // Restore original shared instance if needed
        super.tearDown()
    }
    
    // A simpler test that just verifies basic CRUD operations
    func testBasicOperations() {
        // Given
        let context = mockPersistenceController.container.viewContext
        
        // When - Create a bike
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 500.0
        
        // Then - Can save it
        XCTAssertNoThrow(try context.save())
        
        // When - Fetch bikes
        let bikes = sut.fetchBikes()
        
        // Then - We can retrieve it
        XCTAssertEqual(bikes.count, 1)
        XCTAssertEqual(bikes.first?.id, "test-bike")
        XCTAssertEqual(bikes.first?.name, "Test Bike")
    }
    
    func testFetchActivities() {
        // Given
        mockPersistenceController.createTestData()
        
        // When
        let activities = sut.fetchActivities()
        
        // Then
        XCTAssertEqual(activities.count, 2)
        let ids = activities.map { $0.id }.sorted()
        XCTAssertEqual(ids, [1001, 1002])
    }
    
    func testFetchServiceIntervals() {
        // Given
        mockPersistenceController.createTestData()
        
        // When
        let intervals = sut.fetchServiceIntervals()
        
        // Then
        XCTAssertEqual(intervals.count, 1)
        XCTAssertEqual(intervals.first?.part, "Chain")
    }
    
    func testCreateDefaultServiceIntervals() {
        // Given
        let context = mockPersistenceController.container.viewContext
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0
        try? context.save()
        
        // When
        sut.createDefaultServiceIntervals(for: bike)
        
        // Then
        let fetchRequest: NSFetchRequest<ServiceInterval> = NSFetchRequest<ServiceInterval>(entityName: "ServiceInterval")
        fetchRequest.predicate = NSPredicate(format: "bike.id == %@", "test-bike")
        
        do {
            let intervals = try context.fetch(fetchRequest)
            XCTAssertEqual(intervals.count, 3, "Should create 3 service intervals")
            
            // Check each interval has required properties
            let parts = intervals.map { $0.part }
            XCTAssertTrue(parts.contains("chain"), "Should create a chain service interval")
            XCTAssertTrue(parts.contains("Fork Lowers"), "Should create a fork lowers service interval")
            XCTAssertTrue(parts.contains("Shock"), "Should create a shock service interval")
        } catch {
            XCTFail("Failed to fetch service intervals: \(error)")
        }
    }
    
    func testDeleteBike() {
        // Given
        let context = mockPersistenceController.container.viewContext
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "delete-test-bike"
        bike.name = "Delete Test Bike"
        bike.distance = 300.0
        try? context.save()
        
        // Verify bike exists
        var fetchRequest: NSFetchRequest<Bike> = NSFetchRequest<Bike>(entityName: "Bike")
        fetchRequest.predicate = NSPredicate(format: "id == %@", "delete-test-bike")
        XCTAssertEqual(try! context.fetch(fetchRequest).count, 1, "Bike should exist before deletion")
        
        // When
        sut.deleteBike(bike)
        
        // Then
        fetchRequest = NSFetchRequest<Bike>(entityName: "Bike")
        fetchRequest.predicate = NSPredicate(format: "id == %@", "delete-test-bike")
        XCTAssertEqual(try! context.fetch(fetchRequest).count, 0, "Bike should be deleted")
    }
}
