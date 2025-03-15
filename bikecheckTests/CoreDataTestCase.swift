import XCTest
import CoreData
@testable import bikecheck 

class CoreDataTestCase: XCTestCase {
    
    var persistentContainer: NSPersistentContainer!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        persistentContainer = NSPersistentContainer(name: "com.ride.bikecheck", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = true
        
       
        print("Entities in the model: \(managedObjectModel.entities.map { $0.name ?? "Unnamed" })")

        
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        context = persistentContainer.viewContext
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up any created objects here if necessary
    }
    func testBike() throws {
        // Define the JSON string
        let jsonString = """
        {
            "id": "123",
            "name": "Test Bike",
            "distance": 100.5
        }
        """
        
        // Convert the JSON string to Data
        guard let json = jsonString.data(using: .utf8) else {
            XCTFail("Failed to convert JSON string to data")
            return
        }
        
        let decoder = JSONDecoder()
        // Specify a custom managed object context for decoding
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context
    
        do {
            let bike = try decoder.decode(Bike.self, from: json)
            
            XCTAssertNotNil(bike)
            
            XCTAssertEqual(bike.id, "123")
            XCTAssertEqual(bike.name, "Test Bike")
            XCTAssertEqual(bike.distance, 100.5)
        } catch {
            XCTFail("Failed to decode JSON: \(error)")
        }
    }

    func testTokenInfo() throws {
    // Define the JSON string
        let jsonString = """
        {
            "access_token": "testAccessToken",
            "expires_at": 1643723400,
            "refresh_token": "testRefreshToken"
        }
        """
        
        // Convert the JSON string to Data
        guard let json = jsonString.data(using: .utf8) else {
            XCTFail("Failed to convert JSON string to data")
            return
        }
        
        let decoder = JSONDecoder()
        // Specify a custom managed object context for decoding
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context
        
        do {
            let tokenInfo = try decoder.decode(TokenInfo.self, from: json)
            
            XCTAssertNotNil(tokenInfo)
            
            XCTAssertEqual(tokenInfo.accessToken, "testAccessToken")
            XCTAssertEqual(tokenInfo.expiresAt, 1643723400)
            XCTAssertEqual(tokenInfo.refreshToken, "testRefreshToken")
        } catch {
            XCTFail("Failed to decode JSON: \(error)")
        }
    }

}
