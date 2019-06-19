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
}
