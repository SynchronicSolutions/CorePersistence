//
//  Base.swift
//  Persistence
//
//  Created on 6/20/18.
//  Copyright © 2018 Milos Babic, Ltd. All rights reserved.
//

import Foundation
import CoreData

public typealias JSONObject = [String: Any]

/// Any object that needs to get through the `Persistence` CoreData stack needs to conform to `Persistable` protocol
/// It takes care of basic CRUD operations, where all reads are done defaultly on the main context, if none other
/// is specified.
///
/// Each method is using the default `StoreManager` which contains `NSPersistentContainer`, but if a new one
/// is needed, it can be passed to any of the methods.
public protocol Persistable {

    /// Unique ID type which must conform to `BasicTransformable` protocol
    associatedtype EntityID: CVarArg & Equatable & BasicTransformable

    /// Keypath which represents a property which will be used as primary key on entity
    static var idKeyPath: WritableKeyPath<Self, EntityID> { get }
        
    /// Retrieves a single entity from a `StoreManager` instance defined with `store` parameter, defaultly from a
    /// main context from `store`, but a different one can be passed with `sourceContext` parameter.
    ///
    /// - Parameters:
    ///   - entityID: Unique ID which every entity must have, and only one entity must have this particular one
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `CorePersistence`.
    ///   - sourceContext: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`. Default is `mainContext`.
    /// - Returns: Existing object with `entityID`, or nil if one could not be found
    static func get(entityID: EntityID,
                    from store: StoreManager,
                    sourceContext: NSManagedObjectContext) -> Self?

    /// Retrives multiple entities from a `StoreManager` instance defined with `store` parameter, defaultly from a
    /// main context on the `store`, but different one can be passed with `sourceContext` parameter.
    ///
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `CorePersistence`.
    ///   - predicate: Query predicate used to fetch the entities.
    ///   - comparisonClauses: Array of `ComparisonClause` instances.
    ///   - sourceContext: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`. Default is `mainContext`.
    /// - Returns: Objects from `sourceContext` which conform to `predicate` and sorted in regards to `comparisonClauses`
    static func get(from store: StoreManager,
                    using predicate: NSPredicate,
                    comparisonClauses: [ComparisonClause],
                    sourceContext: NSManagedObjectContext) -> [Self]

    /// Retrieves all entities from a `StoreManager` instance defined with `store` parameter, defaultly from a
    /// main context on the `store`, but a different one can be passed with `sourceContext` parameter.
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `CorePersistence`.
    ///   - comparisonClauses: Array of `ComparisonClause` instances.
    ///   - sourceContext: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`. Default is `mainContext`.
    /// - Returns: All existing objects
    static func getAll(from store: StoreManager,
                       comparisonClauses: [ComparisonClause],
                       sourceContext: NSManagedObjectContext) -> [Self]
    
    /// Creates a `Persistable` entity on a background context on a `NSPersistentStore` defined with `store` parameter
    /// `updateClosure` is triggered on a background thread, passing a newly created object, or if it already exists, object to be updated.
    /// - Parameters:
    ///   - store: StoreManager` instance which contains `NSPersistentStore`.
    ///            Default is the one defined in `CorePersistence`.
    ///   - updateIfEntityExists: Flag which defines what the method will do when it finds a duplicate in the database. If set to `true`,
    ///                           it will fetch the existing one and call `updateClosure` one more time to update the existing entity, if set to `false`, update will be omitted.
    ///   - updateClosure: Triggered when a new entity is created or, existing entity fetched.
    ///   - entity: Newly created entity to be updated
    ///   - context: Context on which the creation is executed on. Can be used to create relationship entities
    ///   - completeClosure: After saving backgrond context, the complete block is dispatched asynchronously on the
    ///                      main thread, with a fresh object refetched from main context.
    static func create(in store: StoreManager,
                       updateIfEntityExists: Bool,
                       updateClosure: @escaping (_ entity: Self, _ context: NSManagedObjectContext) -> Void,
                       completeClosure: ((Self) -> Void)?)
    
    
    /// Init exclusively used to initialize relationship entities. Should be used when `create` or `update` is called, and context is available.
    /// - Parameters:
    ///   - entityID: Unique ID which every entity must have, and only one entity must have this particular one
    ///   - store: StoreManager` instance which contains `NSPersistentStore`.
    ///            Default is the one defined in `CorePersistence`.
    ///   - context: Context on which the creation is executed on.
    init(entityID: EntityID, in store: StoreManager, context: NSManagedObjectContext)


    
    /// Create a temporary object which will be destroyed after the exection
    /// of `updateClosure`
    ///
    /// - Parameters:
    ///     - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///              Default parameter is StoreManagers's `default`, which contains default `NSPersistentStore`.
    ///     - updateClosure: Closure with new temporary object for editing
    ///     - entity: Newly created entity to be updated
    ///     - context: Context on which the creation is executed on. Can be used to create relationship entities
    static func createTemporary(in store: StoreManager,
                                updateClosure: @escaping (_ entity: Self, _ context: NSManagedObjectContext) -> Void)

    /// Update an object in an update closure
    ///
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `CorePersistence`.
    ///   - updateClosure: Closure with object for editing
    ///   - entity: Newly created entity to be updated
    ///   - context: Context on which the creation is executed on. Can be used to create relationship entities.
    ///   - completeClosure: Closure with saved object on main thread
    func update(in store: StoreManager,
                updateClosure: @escaping (_ entity: Self, _ context: NSManagedObjectContext) -> Void,
                completeClosure: ((Self) -> Void)?)

    /// Deletes an entity from a NSManagedObjectContext specified by `context` parameter
    ///
    /// - Parameters:
    ///     - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///              Default parameter is StoreManagers's `default`, which contains default `NSPersistentStore`.
    ///     - context: Source `NSManagedObjectContext`. Default is StoreManager's `newBackgroundContext`
    ///     - completeClosure: Closure which is triggered after context save
    func delete(from store: StoreManager, sourceContext: NSManagedObjectContext, completeClosure: (() -> Void)?)

    /// Deletes a collection of entity results fetched by `predicate` condition defined in `DeleteOptions`.
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `CorePersistence`.
    ///   - options: An instance of `DeleteOptions`, which can contain `NSPredicate`,  `ComparisonClause` instances, `offset`, and execution context.
    ///   - completeClosure: Closure which is triggered after context save
    static func delete(from store: StoreManager,
                       with options: DeleteOptions,
                       completeClosure: (() -> Void)?)
}

public extension Persistable where Self: NSManagedObject {

    var uniqueIdValue: EntityID {
        return self[keyPath: Self.idKeyPath]
    }
    
    static func get(entityID: EntityID,
                    from store: StoreManager = StoreManager.default,
                    sourceContext: NSManagedObjectContext = StoreManager.default.mainContext) -> Self? {

        let fetchRequest = NSFetchRequest<Self>(entityName: "\(Self.self)")
        fetchRequest.predicate = idKeyPath == entityID

        do {
            return try sourceContext.fetch(fetchRequest).first

        } catch {
            Log.error("Failed fetching entity of type: \(Self.self)")
        }

        return nil
    }

    static func get(from store: StoreManager = StoreManager.default,
                    using predicate: NSPredicate,
                    comparisonClauses: [ComparisonClause] = [],
                    sourceContext: NSManagedObjectContext = StoreManager.default.mainContext) -> [Self] {

        let fetchRequest = NSFetchRequest<Self>(entityName: "\(Self.self)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = comparisonClauses.map { $0.sortDescriptor }

        do {
            return try sourceContext.fetch(fetchRequest)

        } catch {
            Log.error("Failed fetching entity of type: \(Self.self)")
        }

        return []
    }

    static func getAll(from store: StoreManager = StoreManager.default,
                       comparisonClauses: [ComparisonClause] = [],
                       sourceContext: NSManagedObjectContext = StoreManager.default.mainContext) -> [Self] {
        return get(from: store,
                   using: .true,
                   comparisonClauses: comparisonClauses,
                   sourceContext: sourceContext)
    }

    static func create(in store: StoreManager = StoreManager.default,
                       updateIfEntityExists: Bool = true,
                       updateClosure: @escaping (Self, NSManagedObjectContext) -> Void,
                       completeClosure: ((Self) -> Void)?) {
        store.performBackgroundTask { (context) in
            var entityID: EntityID?
            ContextQueueManager.instance.push(context: context,
            dataModificationClosure: {

                let temporaryEntity = Self(context: context)
                updateClosure(temporaryEntity, context)
                
                entityID = temporaryEntity[keyPath: idKeyPath]
                
                guard let entityID = entityID else { return }
                let duplicateEntities = get(from: store,
                                            using: idKeyPath == entityID && \Self.objectID != temporaryEntity.objectID,
                                            sourceContext: context)
                
                if !duplicateEntities.isEmpty {
                    if updateIfEntityExists {
                        context.delete(temporaryEntity)
                        Log.warning("There is already an entity of type \(Self.self) with id: \(entityID), in database, will trigger `updateClosure` again to populate existing entity.")
                        duplicateEntities.forEach { updateClosure($0, context) }
                        
                    } else {
                        Log.error("Trying to create an entity of type: \(Self.self) with unique id: \(entityID), which already exists in database. If it's meant to be updated set `updateIfEntityExists` flag to `true`. Aborting.")
                        context.reset()
                    }   
                }
                
            }, dataPersistedCompleteClosure: {
                DispatchQueue.main.async {
                    guard let entityID = entityID, let savedObject = Self.get(entityID: entityID, from: store) else {
                        Log.error("Entity of type \(Self.self) failed to save in persistent store.")
                        return
                    }
                    completeClosure?(savedObject)
                }
            })
        }
    }
    
    init(entityID: EntityID, in store: StoreManager = StoreManager.default, context: NSManagedObjectContext) {
        guard context != StoreManager.default.mainContext else {
            Log.error("Trying to create an entity on main context! This init method is only meant to be used when creating relationships. Aborting.")
            assertionFailure("Trying to create an entity on main context! This init method is only meant to be used when creating relationships. Aborting.")
            
            let newBackgroundContext = store.newBackgroundContext
            self = Self(entity: Self.entity(), insertInto: newBackgroundContext)
            newBackgroundContext.reset()
            return
        }
        
        if let existingEntity = Self.get(entityID: entityID, from: store, sourceContext: context) {
            Log.warning("Trying to create relationship of type \(Self.self) with id: \(entityID) which already exists. Using persisted one")
            self = existingEntity
        } else {
            self = Self(entity: Self.entity(), insertInto: context)
            self[keyPath: Self.idKeyPath] = entityID
        }
    }

    static func createTemporary(in store: StoreManager = StoreManager.default,
                                updateClosure: @escaping (Self, NSManagedObjectContext) -> Void) {

        store.performBackgroundTask { (context) in
            let temporaryEntity = Self(entity: entity(), insertInto: context)
            updateClosure(temporaryEntity, context)
            context.reset()
        }
    }

    func update(in store: StoreManager = StoreManager.default,
                updateClosure: @escaping (Self, NSManagedObjectContext) -> Void,
                completeClosure: ((Self) -> Void)? = nil) {

        // Intentionally capturing self so it would survive scope in operation queue
        store.performBackgroundTask { (context) in
            ContextQueueManager.instance.push(context: context,
            dataModificationClosure: {
                let uniqueID = self[keyPath: Self.idKeyPath]
                guard let refetchedEntity = Self.get(entityID: uniqueID,
                                                     from: store,
                                                     sourceContext: context) else {
                                                        Log.error("Failed to fetch entity of type \(Self.self) with id: \(uniqueID)")
                                                        return
                }

                updateClosure(refetchedEntity, context)

            }, dataPersistedCompleteClosure: {
                DispatchQueue.main.async {
                    let uniqueID = self[keyPath: Self.idKeyPath]
                    guard let refetchedEntity = Self.get(entityID: uniqueID, from: store) else {
                        Log.error("Entity of type \(Self.self) failed to save in persistent store.")
                        return
                    }
                    completeClosure?(refetchedEntity)
                }
            })
        }
    }

    func delete(from store: StoreManager = StoreManager.default,
                sourceContext: NSManagedObjectContext = StoreManager.default.newBackgroundContext,
                completeClosure: (() -> Void)? = nil) {
        let uniqueID = self[keyPath: Self.idKeyPath]
        let deleteOptions = DeleteOptions(sourceContext: sourceContext,
                                          predicate: Self.idKeyPath == uniqueID)
        Self.delete(from: store,
                    with: deleteOptions,
                    completeClosure: completeClosure)
    }

    static func delete(from store: StoreManager = StoreManager.default,
                       with options: DeleteOptions = DeleteOptions(),
                       completeClosure: (() -> Void)? = nil) {

        guard options.sourceContext != store.mainContext else {
            Log.error("Trying to perform delete operations on main context. Aborting.")
            return
        }
        let context = options.sourceContext
        
        context.perform {
            ContextQueueManager.instance.push(context: context, dataModificationClosure: {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "\(Self.self)")
                fetchRequest.predicate = options.predicate
                fetchRequest.sortDescriptors = options.comparisonClauses.map { $0.sortDescriptor }

                if let offset = options.offset {
                    fetchRequest.fetchOffset = offset
                }

                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                batchDeleteRequest.resultType = .resultTypeObjectIDs

                do {
                    guard
                        let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult,
                        let entityIDs = result.result as? [NSManagedObjectID] else {
                            Log.error("Batch delete \(Self.self) is not of type `NSBatchDeleteResult`. Aborting.")

                            context.reset()
                            return
                    }

                    let changes = [NSDeletedObjectsKey: entityIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [store.mainContext])

                } catch {
                    Log.error("Delete operation of entity of type: \(Self.self) failed with error:\n\(error)\nAborting.")
                    context.reset()
                }
            }, dataPersistedCompleteClosure: {
                DispatchQueue.main.async {
                    completeClosure?()
                }
            })
        }
    }
}

public extension Collection where Element: PersistableManagedObject {
    func delete(from store: StoreManager = StoreManager.default,
                context: NSManagedObjectContext = StoreManager.default.newBackgroundContext,
                complete: @escaping () -> Void) {
        let ids = map { $0[keyPath: Element.idKeyPath] }

        let deleteOptions = DeleteOptions(sourceContext: context, predicate: Element.idKeyPath === ids)
        Element.delete(from: store,
                       with: deleteOptions,
                       completeClosure: complete)
    }
}
