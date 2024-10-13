//
//  Activity.swift
//  BikeCheck
//
//  Created by clutchcoder on 12/25/23.
//

import Foundation
import CoreData

public class Activity: NSManagedObject, Codable {
    @NSManaged public var id: Int64
    @NSManaged public var gearId: String?
    @NSManaged public var name: String
    @NSManaged public var type: String
    @NSManaged public var movingTime: Int64
    @NSManaged public var startDate: Date
    @NSManaged public var distance: Double
    @NSManaged public var averageSpeed: Double
    @NSManaged public var processed: Bool
  //  @NSManaged public var bike: Bike?

    var context: NSManagedObjectContext!

    enum CodingKeys: String, CodingKey {
        case id
        case gearId = "gear_id"
        case name
        case type
        case movingTime = "moving_time"
        case startDate = "start_date"
        case distance
        case averageSpeed = "average_speed"
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Managed object context is missing"))
        }
        self.init(context: context)
        self.context = context

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.gearId = try container.decodeIfPresent(String.self, forKey: .gearId) ?? "defaultGearId"
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(String.self, forKey: .type)
        self.movingTime = try container.decode(Int64.self, forKey: .movingTime)
        
        let startDateString = try container.decode(String.self, forKey: .startDate)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // adjust this format to match your date string
            if let date = dateFormatter.date(from: startDateString) {
                self.startDate = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .startDate, in: container, debugDescription: "Date string does not match format expected by formatter.")
            }


        self.distance = try container.decode(Double.self, forKey: .distance)
        self.averageSpeed = try container.decode(Double.self, forKey: .averageSpeed)
        
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(gearId, forKey: .gearId)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(movingTime, forKey: .movingTime)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(distance, forKey: .distance)
        try container.encode(averageSpeed, forKey: .averageSpeed)
    }
}
