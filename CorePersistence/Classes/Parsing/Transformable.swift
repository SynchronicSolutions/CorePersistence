//
//  Transformable.swift
//  Persistence
//
//  Created on 5/28/19.
//  Copyright (c) 2018 Human Dx, Ltd. All rights reserved.
//

import Foundation

public protocol Transformable {
    static func transform(object: MappingValues) -> Self?
}

public protocol BasicTransformable: Transformable {
    static func transform(value: BasicTransformable) -> Self?
}

extension BasicTransformable {
    public static func transform(object: MappingValues) -> Self? {
        if let value = object.currentValue as? BasicTransformable {
            return transform(value: value)
        }
        return nil
    }
}

extension Int: BasicTransformable {
    public static func transform(value: BasicTransformable) -> Int? {
        if let intValue = value as? Int {
            return intValue

        } else if let stringValue = value as? String, let doubleValue = Double(stringValue) {
            return Int(doubleValue)
        }

        return 0
    }
}

extension Int16: BasicTransformable {
    public static func transform(value: BasicTransformable) -> Int16? {
        if let intValue = value as? Int16 {
            return intValue

        } else if let intValue = value as? Int {
            return Int16(intValue)

        } else if let stringValue = value as? String {
            return Int16(stringValue)
        }

        return 0
    }
}

extension Int32: BasicTransformable {
    public static func transform(value: BasicTransformable) -> Int32? {
        if let intValue = value as? Int32 {
            return intValue

        } else if let intValue = value as? Int {
            return Int32(intValue)

        } else if let stringValue = value as? String {
            return Int32(stringValue)
        }

        return 0
    }
}

extension Double: BasicTransformable {
    public static func transform(value: BasicTransformable) -> Double? {
        if let doubleValue = value as? Double {
            return doubleValue

        } else if let floatValue = value as? Float {
            return Double(floatValue)

        } else if let intValue = value as? Int {
            return Double(intValue)

        } else if let stringValue = value as? String {
            return Double(stringValue)
        }

        return 0
    }
}

extension String: BasicTransformable {
    public static func transform(value: BasicTransformable) -> String? {
        if let stringValue = value as? String {
            return stringValue

        } else if let intValue = value as? Int {
            return "\(intValue)"

        } else if let doubleValue = value as? Double {
            return "\(doubleValue)"
        }

        return ""
    }
}

extension Bool: BasicTransformable {
    public static func transform(value: BasicTransformable) -> Bool? {
        if let value = value as? Bool {
            return value
        } else if let value = value as? String {
            return Bool(value) ?? false
        } else if let value = value as? Int {
            return value != 0
        }
       return false
    }
}

extension Date: Transformable {
    public static func transform(object: MappingValues) -> Date? {
        return object.currentValue as? Date
    }

    public static func transform(_ value: Any?, dateFormats: [String]) -> Date? {
        if let dateString = value as? String {
            let dateFormatter = DateFormatter()
            for dateFormat in dateFormats {
                dateFormatter.dateFormat = dateFormat
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
        }
        return nil
    }
}

extension Optional: Transformable where Wrapped: Transformable {

    public static func transform(object: MappingValues) -> Wrapped?? {
        if let value = transformAndUnwrap(object: object) {
            return value
        }
        return nil
    }

    private static func transformAndUnwrap(object: MappingValues) -> Wrapped? {
        return Wrapped.transform(object: object)
    }
}

extension Array: Transformable where Element: BasicTransformable {
    public static func transform(object: MappingValues) -> [Element]? {
        if let array = object.currentValue as? [BasicTransformable] {
            return array.compactMap { Element.transform(value: $0) }
        }

        return []
    }
}

extension Dictionary: Transformable where Key: BasicTransformable, Value: Transformable {
    public static func transform(object: MappingValues) -> [Key: Value]? {
        var transformedDictionary: [Key: Value] = [:]

        if let currentValue = object.currentValue as? JSONObject {
            let currentMappingValues = MappingValues(json: currentValue, context: object.managedObjectContext)

            currentValue.keys.forEach { (key) in
                let transformedKey = Key.transform(value: key)

                var transformedValue: Value?
                transformedValue <- currentMappingValues[key]

                if let transformedKey = transformedKey {
                    transformedDictionary[transformedKey] = transformedValue
                }
            }
        }

        return transformedDictionary
    }
}

extension Transformable where Self: RawRepresentable, RawValue: BasicTransformable {
    public static func transform(object: MappingValues) -> Self? {
        if let currentValue = object.currentValue as? BasicTransformable,
            let transformedValue = RawValue.transform(value: currentValue) {
            return Self(rawValue: transformedValue)
        }
        return nil
    }
}

extension NSString: BasicTransformable {
    public static func transform(value: BasicTransformable) -> Self? {
        return nil
    }
}

extension NSNumber: BasicTransformable {
    public static func transform(value: BasicTransformable) -> Self? {
        return nil
    }
}
