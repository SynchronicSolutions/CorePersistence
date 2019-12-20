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
    
    /// Initializer which fetches all entities of type `EntityType` and sorts them by `idKeyPath`
    /// - Parameter context: source context
    public init(context: NSManagedObjectContext = StoreManager.default.mainContext) {
        self.context = context
        refetch()
    }
    
    /// Filters previously fetched results.
    /// - Parameter predicate: Predicate which defines rules for filtering
    /// - Example:
    /// ```Results().filterBy(\User.birthDate <= Date())```
    /// - Returns: Instance of Results.
    @discardableResult
    public func filterBy(_ predicate: NSPredicate) -> Self {
        self.predicate = predicate
        refetch()
        return self
    }
    
    /// Sorts previously fetched results.
    /// - Parameter comparisons: Instances of `ComparisonClause` which can be either `.ascending` or `.descending`
    /// - Example:
    /// ```Results().sortBy(.ascending(\User.firstName), .descending(\User.lastName))```
    /// - Returns: Instance of Results.
    @discardableResult
    public func sortBy(_ comparisons: ComparisonClause...) -> Self {
        self.sortDescriptors = comparisons.map { $0.sortDescriptor }
        refetch()
        return self
    }
    
    /// Used to register for changes which happen on `NSManagedObjectContext`  which is specified in Results init. When changes occur, `closure` is triggered and accumulated changes are passed.
    /// Changes contain a change `type` (insert, update, move, delete), `newIndexPath` which will be not nil in case of insert and move types, `indexPath` which will not be nil in case of update, move and delete, and object of type `EntityType`.
    /// - Important: If the Results instance is not saved outside of the scope it was instanced in, `ResultsRefresher` closure wil be deallocated with `Results`, and changes won't occur.
    /// - Parameters:
    ///     - closure: Closure which will be triggered when changes on context happen
    ///     - changes: Array of type `Change` defined in `ResultsRefresher` which contain  a change `type` (insert, update, move, delete), `newIndexPath` which will be not nil in case of insert and move types, `indexPath` which will not be nil in case of update, move and delete, and object of type `EntityType`.
    /// - Returns: Instance of Results.
    @discardableResult
    public func registerForChanges(closure: @escaping (_ changes: [ResultsRefresher<EntityType>.Change]) -> Void) -> Self{
        refresher = ResultsRefresher<EntityType>(results: self, accumulatedChanges: { (changes, _) in
            closure(changes)
        })
        
        fetchedResultsController.delegate = refresher
        return self
    }
    
    
    /// Converts results object to an array of `EntityType`
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
