//
//  ComparisonClause.swift
//  CorePersistence
//
//  Created by Milos Babic on 12/18/19.
//

import Foundation

public struct ComparisonClause {
    let sortDescriptor: NSSortDescriptor
    public static func ascending<EntityType: PersistableManagedObject, PropertyType>(_ keyPath: KeyPath<EntityType, PropertyType>) -> ComparisonClause {
        return ComparisonClause(sortDescriptor: NSSortDescriptor(keyPath: keyPath, ascending: true))
    }
    
    public static func descending<EntityType: PersistableManagedObject, PropertyType>(_ keyPath: KeyPath<EntityType, PropertyType>) -> ComparisonClause {
        return ComparisonClause(sortDescriptor: NSSortDescriptor(keyPath: keyPath, ascending: false))
    }
}
