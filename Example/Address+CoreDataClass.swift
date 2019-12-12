//
//  Address+CoreDataClass.swift
//  CorePersistence_Example
//
//  Created by Milos Babic on 12/12/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//
//

import Foundation
import CorePersistence

@objc(Address)
final public class Address: ParsableManagedObject {
    public static var idKeyPath: WritableKeyPath<Address, String> {
        return \Self.uuid
    }
    
    public func mapValues(from map: MappingValues) {
    }
}
