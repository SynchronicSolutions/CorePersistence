//
//  StoreManager.swift
//  Persistence
//
//  Created on on 12/21/18.
//  Copyright © 2018 Human Dx, Ltd. All rights reserved.
//

import CoreData

public class StoreManager {

    /// `NSPersistentContainer` which should be injected,
    /// and used for CRUD operations with `Parsable` and `Persistable` objects
    private var persistantContainer: NSPersistentContainer
    
    public static let `default` = StoreManager()

    /// Initializer for `StoreManager`
    ///
    /// - Parameter container: `NSpersistantContainer` to inject, if none is defined, the one from
    ///                         `Persistence` initialize will be used.
    public init(container: NSPersistentContainer = CorePersistence.instance.mainContainer) {
        self.persistantContainer = container
    }

    /// View context of an injected `NSPersistentContainer`
    public var mainContext: NSManagedObjectContext {
        return persistantContainer.viewContext
    }

    public var newBackgroundContext: NSManagedObjectContext {
        return persistantContainer.newBackgroundContext()
    }

    /// Performs a `closure` on a background queue, creating a background context and passing it in `closure`
    ///
    /// - Parameter closure: Closure which will be executed on background context
    func performBackgroundTask(closure: @escaping (NSManagedObjectContext) -> Void) {
        persistantContainer.performBackgroundTask(closure)
    }
}

public struct DeleteOptions {
    var sourceContext: NSManagedObjectContext
    var offset: Int?
    var predicate: NSPredicate
    var sortDescriptors: [NSSortDescriptor]?

    public init(sourceContext: NSManagedObjectContext = StoreManager.default.newBackgroundContext,
                predicate: NSPredicate = .true,
                sortDescriptors: [NSSortDescriptor]? = nil,
                offset: Int? = nil) {
        self.sourceContext = sourceContext
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.offset = offset
    }
}
