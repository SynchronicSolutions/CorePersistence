//
//  Dictionary+KeyPath.swift
//  Persistence
//
//  Created on 6/3/19.
//  Copyright © 2019 Milos Babic, Ltd. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any {

    subscript(keyPath key: Key) -> Any? {
        let stringParts: [String] = key.split(separator: ".").map { "\($0)" }

        if stringParts.count == 1 {
            return self[key]

        } else {

            var remainderDictionary = self

            for index in 0..<stringParts.count {
                let key = stringParts[index]
                if index == (stringParts.count - 1) {
                    return remainderDictionary[key]

                } else if let subDictionary = remainderDictionary[key] as? [Key: Value] {
                    remainderDictionary = subDictionary
                }
            }
        }

        return nil
    }
}
