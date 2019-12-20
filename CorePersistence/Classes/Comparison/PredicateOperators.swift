//
//  PredicateOperators.swift
//  CorePersistence
//
//  Created by Milos Babic on 6/24/19.
//  Copyright © 2019 Personal. All rights reserved.
//

import Foundation

public func ==<RootType, EquatableType: Equatable, KeyPathType: KeyPath<RootType, EquatableType>>(
    left: KeyPathType, right: EquatableType
) -> ComparisonPredicate<RootType> {

    return left.predicate(op: .equalTo, value: right)
}

public func !=<RootType, EquatableType: Equatable>(
    left: KeyPath<RootType, EquatableType>, right: EquatableType
) -> ComparisonPredicate<RootType> {

    return left.predicate(op: .notEqualTo, value: right)
}

public func ><RootType, EquatableType: Equatable>(
    left: KeyPath<RootType, EquatableType>, right: EquatableType
) -> ComparisonPredicate<RootType> {

    return left.predicate(op: .greaterThan, value: right)
}

public func <<RootType, EquatableType: Equatable>(
    left: KeyPath<RootType, EquatableType>, right: EquatableType
) -> ComparisonPredicate<RootType> {

    return left.predicate(op: .lessThan, value: right)
}

public func >=<RootType, EquatableType: Equatable>(
    left: KeyPath<RootType, EquatableType>, right: EquatableType
) -> ComparisonPredicate<RootType> {

    return left.predicate(op: .greaterThanOrEqualTo, value: right)
}

public func <=<RootType, EquatableType: Equatable>(
    left: KeyPath<RootType, EquatableType>, right: EquatableType
) -> ComparisonPredicate<RootType> {

    return left.predicate(op: .lessThanOrEqualTo, value: right)
}

public func ===<RootType, SequenceType: Sequence>(
    left: KeyPath<RootType, SequenceType.Element>, right: SequenceType
) -> ComparisonPredicate<RootType> where SequenceType.Element: Equatable {

    return left.predicate(op: .in, value: right)
}
