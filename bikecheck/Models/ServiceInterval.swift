//
//  ServiceInterval.swift
//  bikecheck
//
//  Created by clutchcoder on 1/14/24.
//

import Foundation
import CoreData

public class ServiceInterval: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var part: String
    @NSManaged public var startTime: Double
    @NSManaged public var intervalTime: Double
    @NSManaged public var notify: Bool
    @NSManaged public var bike: Bike

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
}
