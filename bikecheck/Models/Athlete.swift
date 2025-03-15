//
//  Athlete.swift
//  bikeCheck
//
//  Created by clutchcoder on 12/25/23.
//

import Foundation
import CoreData

public class Athlete: NSManagedObject, Codable {
    @NSManaged public var id: Int64
    @NSManaged public var firstname: String
    @NSManaged public var profile: String!
    @NSManaged public var bikes: Set<Bike>

    enum CodingKeys: String, CodingKey {
        case id
        case firstname
        case profile
        case bikes
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Managed object context is missing"))
        }
        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        firstname = try container.decode(String.self, forKey: .firstname)
        profile = try container.decode(String.self, forKey: .profile)
        bikes = try container.decodeIfPresent(Set<Bike>.self, forKey: .bikes) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(firstname, forKey: .firstname)
        try container.encode(profile, forKey: .profile)
        try container.encodeIfPresent(bikes, forKey: .bikes)
    }
}
