//
//  PredicateProtocol.swift
//  CorePersistence
//
//  Created by Milos Babic on 6/24/19.
//  Copyright © 2019 Personal. All rights reserved.
//

import Foundation

public protocol PredicateProtocol: NSPredicate {
    associatedtype Root
}

public class CompoundPredicate<RootType>: NSCompoundPredicate, PredicateProtocol {
    public typealias Root = RootType
}

public class ComparisonPredicate<RootType>: NSComparisonPredicate, PredicateProtocol {
    public typealias Root = RootType
}

public func &&<LeftPredicate: PredicateProtocol, RightPredicate: PredicateProtocol>(
    left: LeftPredicate, right: RightPredicate
) -> CompoundPredicate<LeftPredicate.Root> where LeftPredicate.Root == RightPredicate.Root {

    return CompoundPredicate(type: .and, subpredicates: [left, right])
}

public func ||<LeftPredicate: PredicateProtocol, RightPredicate: PredicateProtocol>(
    left: LeftPredicate, right: RightPredicate
) -> CompoundPredicate<LeftPredicate.Root> where LeftPredicate.Root == RightPredicate.Root {

    return CompoundPredicate(type: .or, subpredicates: [left, right])
}

public prefix func !<Predicate: PredicateProtocol>(operand: Predicate) -> CompoundPredicate<Predicate.Root> {
    return CompoundPredicate(type: .not, subpredicates: [operand])
}
