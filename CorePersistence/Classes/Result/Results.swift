//
//  Results.swift
//  Persistencec
//
//  Created on 6/26/18.
//  Copyright © 2018 Milos Babic, Ltd. All rights reserved.
//

import CoreData

public typealias PersistableManagedObject = Persistable & NSManagedObject

/// Wrapper around `NSFetchedResultsController` which is used to group changes, and to build helper methods for the
/// `NSFetchedResultsController`. The changes are grouped and passed using `ResultsRefresher`
/// which is used as a `NSFetchedResultsController` delegate, using a closure
/// when a NSFetchedResultsDelegate has triggered `controllerDidChangeContent(_:)`
public class Results<EntityType: PersistableManagedObject> {
    public var fetchedResultsController: NSFetchedResultsController<EntityType>!
    public var refresher: ResultsRefresher<EntityType>?
    
    public var context: NSManagedObjectContext = StoreManager.default.mainContext
    public var predicate: NSPredicate?
    public var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(keyPath: EntityType.idKeyPath, ascending: true)]
    
    public init(context: NSManagedObjectContext = StoreManager.default.mainContext) {
        self.context = context
        refetch()
    }
    
    @discardableResult
    public func filterBy(_ predicate: NSPredicate) -> Self {
        self.predicate = predicate
        refetch()
        return self
    }
    
    @discardableResult
    public func sortBy(_ comparisons: ComparisonClause...) -> Self {
        self.sortDescriptors = comparisons.map { $0.sortDescriptor }
        refetch()
        return self
    }
    
    @discardableResult
    public func registerForChanges(closure: @escaping ([ResultsRefresher<EntityType>.Change]) -> Void) -> Self{
        refresher = ResultsRefresher<EntityType>(results: self, accumulatedChanges: { (changes, _) in
            closure(changes)
        })
        
        fetchedResultsController.delegate = refresher
        return self
    }
    
    public func toArray() -> [EntityType] {
        return fetchedResultsController.fetchedObjects ?? []
    }

    /// Flag which indicates if the collection is empty
    public var isEmpty: Bool {
        return numberOfSections == 0
    }

    /// Number of sections in the fetched results controller. Defaults to zero.
    public var numberOfSections: Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    /// Number of objects in first section
    public var numberOfObjectsInFirstSection: Int {
        return fetchedResultsController.sections?[0].objects?.count ?? 0
    }

    /// Objects in first section of fetched results controller
    public var objectsInFirstSection: [EntityType] {
        return objects(for: 0)
    }

    /// Number of objects for a certain section.
    ///
    /// - Parameter section: Specified which section's count should the function return.
    /// - Returns: Number of objects in a certain section. Defaults to zero.
    public func numberOfObjects(in section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections[section].objects?.count ?? 0
        }
        return 0
    }

    /// Returns an object specified by an `IndexPath`
    ///
    /// - Parameter indexPath: Location in `NSFetchedResultsController` which holds the entity
    /// - Returns: Entity instance on `indexPath`
    public func object(at indexPath: IndexPath) -> EntityType {
        return fetchedResultsController.object(at: indexPath)
    }

    /// Returns an array of object in a certain section
    ///
    /// - Parameter section: Section which defines which objects to return.
    /// - Returns: An array of objects for a `section`. Defaults to an empty array.
    public func objects(for section: Int) -> [EntityType] {
        if let sections = fetchedResultsController.sections, let objects = sections[section].objects as? [EntityType] {
            return objects
        }
        return []
    }
}

private extension Results {
    private func refetch() {
        let fetchRequest = NSFetchRequest<EntityType>(entityName: "\(EntityType.self)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: context,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        do {
            try fetchedResultsController.performFetch()

        } catch {
            Log.error("Results failed to fetch entities of type:\(EntityType.self)")
        }
    }
}


extension NSSortDescriptor {
    static func ascending<EntityType: PersistableManagedObject, T>(_ keyPath: KeyPath<EntityType, T>) -> NSSortDescriptor {
        return NSSortDescriptor(keyPath: keyPath, ascending: true)
    }
}
