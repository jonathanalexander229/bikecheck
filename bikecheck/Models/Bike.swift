//
//  Bike.swift
//  bikeCheck
//
//  Created by clutchcoder on 12/25/23.
//

import Foundation
import Combine
import CoreData

@objc(Bike)
public class Bike: NSManagedObject, Codable, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var distance: Double
   // @NSManaged public var activities: Set<Activity>
    @NSManaged public var athlete: Athlete
    //@NSManaged public var serviceIntervals: Set<ServiceInterval>?
    
    public func activities (context: NSManagedObjectContext) -> [Activity] {
        let fetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest() as! NSFetchRequest<Activity>
        fetchRequest.predicate = NSPredicate(format: "gearId == %@", id)

        do {
            let activities = try context.fetch(fetchRequest)
            return activities
        } catch {
            print("Failed to fetch activities for bike with id \(id): \(error)")
            return []
        }
    }

    public func rideTime(context: NSManagedObjectContext) -> Double {
        let activities = self.activities(context: context)
        let totalRideTime = activities.reduce(0) { $0 + Double($1.movingTime) }
        return totalRideTime / 3600
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case distance
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Managed object context is missing"))
        }
        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        distance = try container.decode(Double.self, forKey: .distance)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(distance, forKey: .distance)
    }

    override public var description: String {
        return "Bike(id: \(id), name: \(name), distance: \(distance))"
    }
}

extension Bike {

    
    static func findOrCreateBike(id: String, name: String, distance: Double, context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) -> Bike? {
        let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest() as! NSFetchRequest<Bike>
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let matchingBikes = try context.fetch(fetchRequest)
            if let existingBike = matchingBikes.first {
                // If a Bike with the same id already exists, return that
                return existingBike
            } else {
                // If no Bike with the same id exists, create a new one
                let newBike = Bike(context: context)
                newBike.id = id
                newBike.name = name
                newBike.distance = distance
                return newBike
            }
        } catch {
            print("Failed to fetch bikes: \(error)")
            return nil
        }
    }
}
