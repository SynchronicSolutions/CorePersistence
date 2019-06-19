//
//  MappingValues.swift
//  Persistence
//
//  Created on 5/28/19.
//  Copyright (c) 2018 Human Dx, Ltd. All rights reserved.
//

import Foundation
import CoreData

public class MappingValues {
    public var managedObjectContext: NSManagedObjectContext
    public var jsonObject: JSONObject = [:]

    public var currentKey: String?
    public var currentValue: Any?

    init(json: JSONObject, context: NSManagedObjectContext) {
        jsonObject = json
        managedObjectContext = context
    }

    public subscript(key: String) -> MappingValues {
        currentKey = key
        currentValue = jsonObject[keyPath: key]
        return self
    }

    public func keyExists(block: (MappingValues) -> Void) {
        if isKeyPresent {
            block(self)
        }
    }

    public var isKeyPresent: Bool {
        if let currentKey = currentKey {
            return keyPresent(key: currentKey, for: jsonObject)
        }
        return false
    }

    private func keyPresent(key: String, for dict: JSONObject) -> Bool {
        let stringParts: [String] = key.split(separator: ".").map { "\($0)" }

        if stringParts.count == 1 {
            return dict.index(forKey: stringParts[0]) != nil

        } else if let firstKey = stringParts.first, let innerDict = dict[firstKey] as? JSONObject {
            return keyPresent(key: stringParts[1..<stringParts.count].joined(separator: "."), for: innerDict)
        }

        return false
    }
}
