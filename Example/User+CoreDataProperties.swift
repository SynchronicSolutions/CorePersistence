//
//  User+CoreDataProperties.swift
//  CorePersistence_Example
//
//  Created by Milos Babic on 12/12/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var uuid: String
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var birthDate: Date?
    @NSManaged public var numberOfOrders: Int
    @NSManaged public var address: Address?
    @NSManaged public var orders: Set<Order>
}
