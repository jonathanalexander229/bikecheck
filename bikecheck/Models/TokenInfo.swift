//
//  TokenInfo.swift
//  BikeCheck
//
//  Created by clutchcoder on 12/25/23.
//

import Foundation
import CoreData

@objc(TokenInfo)
public class TokenInfo: NSManagedObject, Codable {
    @NSManaged public var accessToken: String
    @NSManaged public var refreshToken: String
    @NSManaged public var expiresAt: Int
    @NSManaged public var athlete: Athlete?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case athlete
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Managed object context is missing"))
        }
        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.refreshToken = try container.decode(String.self, forKey: .refreshToken)
        self.expiresAt = try container.decode(Int.self, forKey: .expiresAt)
        self.athlete = try container.decodeIfPresent(Athlete.self, forKey: .athlete)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(athlete, forKey: .athlete)
    }
}

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}
