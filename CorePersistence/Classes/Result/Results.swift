//
//  Results.swift
//  Persistencec
//
//  Created on 6/26/18.
//  Copyright © 2018 Human Dx, Ltd. All rights reserved.
//

import CoreData

public typealias PersistableManagedObject = Persistable & NSManagedObject

/// Wrapper around `NSFetchedResultsController` which is used to group changes, and to build helper methods for the
/// `NSFetchedResultsController`. The changes are grouped and passed using `ResultsRefresher`
/// which is used as a `NSFetchedResultsController` delegate, using a closure
/// when a NSFetchedResultsDelegate has triggered `controllerDidChangeContent(_:)`
public class Results<EntityType: PersistableManagedObject> {
    public var fetchedResultsController: NSFetchedResultsController<EntityType>
    public var refresher: ResultsRefresher<EntityType>?

    /// Initializer for Results. Gathers all the information needed for `NSFetchedResultsController`,
    /// and passing a `ResultsRefresher` to be used as a delegate
    ///
    /// - Parameters:
    ///   - predicate: Predicate of the fetch request.
    ///   - sortBy: The sort descriptors of the fetch request.
    ///   - groupBy: An array of objects which define how the data should be groupped.
    ///   - context: Source context for the `NSFetchedResultsController`
    ///   - changesDidHappenClosure: Closure which triggers when some changes occur on context
    public init(predicate: NSPredicate,
                sortBy: [NSSortDescriptor]? = nil,
                groupBy: [String]? = nil,
                context: NSManagedObjectContext? = nil,
                changesDidHappenClosure: (([ResultsRefresher<EntityType>.Change],
                                            Results<EntityType>) -> Void)? = nil) {

        var managedObjectContext: NSManagedObjectContext
        if let context = context {
            managedObjectContext = context
        } else {
            let storeManager = StoreManager()
            managedObjectContext = storeManager.mainContext
        }

        let fetchRequest = NSFetchRequest<EntityType>(entityName: "\(EntityType.self)")
        fetchRequest.predicate = predicate
        fetchRequest.propertiesToGroupBy = groupBy
        fetchRequest.sortDescriptors = sortBy ?? [NSSortDescriptor(key: "id", ascending: true)]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: managedObjectContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)

        if let changesDidHappenClosure = changesDidHappenClosure {
            refresher = ResultsRefresher<EntityType>(results: self) { (changes, newState) in
                changesDidHappenClosure(changes, newState)
            }
        }

        do {
            fetchedResultsController.delegate = refresher
            try fetchedResultsController.performFetch()

        } catch {
            print("\n\nFETCHED RESULTS CONTROLLER FAILED TO FETCH ENTITY OF TYPE \(EntityType.self)\n\n")
        }
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
