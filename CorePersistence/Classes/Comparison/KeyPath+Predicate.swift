//
//  KeyPath+Predicate.swift
//  CorePersistence
//
//  Created by Milos Babic on 6/24/19.
//  Copyright © 2019 Personal. All rights reserved.
//

import Foundation

extension KeyPath {
    func predicate(op: NSComparisonPredicate.Operator, value: Any?) -> ComparisonPredicate<Root> {
        return ComparisonPredicate(leftExpression: NSExpression(forKeyPath: self),
                                   rightExpression: NSExpression(forConstantValue: value),
                                   modifier: .direct, type: op)
    }
    
    var stringKeyPath: String {
        return NSExpression(forKeyPath: self).keyPath
    }
}

public extension NSPredicate {
    static var `true`: NSPredicate {
        return NSPredicate(format: "TRUEPREDICATE")
    }
    
    static var `false`: NSPredicate {
        return NSPredicate(format: "FALSEPREDICATE")
    }
}
