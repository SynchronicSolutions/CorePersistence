//
//  User+CoreDataClass.swift
//  CorePersistence_Example
//
//  Created by Milos Babic on 12/12/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//
//

import Foundation
import CorePersistence

@objc(User)
final public class User: ParsableManagedObject {

    public static var idKeyPath: WritableKeyPath<User, String> {
        return \Self.uuid
    }
    
    // If the primary key in json dictionary is not the same as idKeyPath it must be specified with jsonKey
//    public static var jsonKey: String {
//        return "uuid2"
//    }
    
    public var jsonDictionary: JSONObject {
        [
            User.jsonKey: uuid,
            "firstName": firstName ?? "",
            "lastName": lastName ?? "",
            "address": address?.jsonDictionary ?? ""
        ]
    }

    public func mapValues(from map: MappingValues) {
        firstName       <- map["first_name"]
        lastName        <- map["last_name"]
        address         <- map["address"]
        numberOfOrders  <- map["number_of_orders"]
        orders          <- map["orders"]
        birthDate       <- (map["birth_date"], { anyDate in
            return Date.transform(anyDate, dateFormats: ["yyyy-MM-dd"])
        })
        
        type <- map["account_type"]
    }
}
