//
//  Order+CoreDataClass.swift
//  CorePersistence_Example
//
//  Created by Milos Babic on 12/12/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//
//

import Foundation
import CorePersistence

@objc(Order)
final public class Order: ParsableManagedObject {

    public static var idKeyPath: WritableKeyPath<Order, String> {
        return \Self.uuid
    }
    
    public func mapValues(from map: MappingValues) {
        address <- map["address_id"]
    }
}
