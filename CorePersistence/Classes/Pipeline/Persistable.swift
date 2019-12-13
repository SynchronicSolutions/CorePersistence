//
//  Base.swift
//  Persistence
//
//  Created on 6/20/18.
//  Copyright © 2018 Human Dx, Ltd. All rights reserved.
//

import Foundation
import CoreData

public typealias JSONObject = [String: Any]

/// Any object that needs to get through the `Persistence` CoreData stack needs to conform to `Persistable` protocol
/// It takes care of basic CRUD operations, where all reads are done defaultly on the main context, if none other
/// is specified.
///
/// Each method is using the default `NSPersistantStoreContainer` defined in the `Persistence` class, but if a new one
/// is needed, it can be passed to any of the methods.
public protocol Persistable {

    /// Entity ID type which has to be the same type in the API and in the CoreData
    associatedtype EntityID: CVarArg & Equatable & BasicTransformable

    static var idKeyPath: WritableKeyPath<Self, EntityID> { get }
    
    /// Retrieves a single entity from a `StoreManager` instance defined with `store` parameter, defaultly from a
    /// main context on the `store`, but a different one can be passed with `sourceContext` parameter.
    ///
    /// - Parameters:
    ///   - entityID: Unique ID which every entity must have, and only one entity must have this particular one
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `Persistance`.
    ///   - sourceContext: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`.
    ///   - shouldCreate: If the entity doesn't exist in this context,
    ///     the flag should define if the method should create the entity.
    /// - Returns: Existing object with `entityID`, or a new one if `shouldCreate` flag is set to `true`.
    static func get(entityID: EntityID,
                    from store: StoreManager,
                    sourceContext: NSManagedObjectContext,
                    shouldCreate: Bool) -> Self?

    /// Retrives multiple entities from a `StoreManager` instance defined with `store` parameter, defaultly from a
    /// main context on the `store`, but different one can be passed with `sourceContext` parameter.
    ///
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `Persistance`.
    ///   - predicate: Query predicate used to fetch the entities.
    ///   - sortDescriptors: Array of `NSSortDescriptor` instances.
    ///   - sourceContext: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`.
    /// - Returns: Objects from `sourceContext` which conform to `predicate` and sorted in regards to `sortDescriptors`
    static func get(from store: StoreManager,
                    using predicate: NSPredicate,
                    sortDescriptors: [NSSortDescriptor]?,
                    sourceContext: NSManagedObjectContext) -> [Self]

    /// Retrieves all entities from a `StoreManager` instance defined with `store` parameter, defaultly from a
    /// main context on the `store`, but a different one can be passed with `sourceContext` parameter.
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `Persistance`.
    ///   - sourceContext: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`.
    /// - Returns: All existing objects
    static func getAll(from store: StoreManager,
                       sortDescriptors: [NSSortDescriptor]?,
                       sourceContext: NSManagedObjectContext) -> [Self]

    /// Creates a `Persistable` entity on a background context on a `NSPersistentStore` defined with `store` parameter
    /// `updateClosure` is triggered on a background thread, passing a newly created object, or if it already exists,
    /// object to be updated.
    ///
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `Persistance`.
    ///   - updateClosure: Triggered when a new entity is created or, existing entity fetched.
    ///   - completeClosure: After saving backgrond context, the complete block is dispatched asynchronously on the
    ///                      main thread, with a fresh object refetched from main context.
    static func create(in store: StoreManager,
                       updateClosure: @escaping (Self, NSManagedObjectContext) -> Void,
                       completeClosure: ((Self) -> Void)?)

    /// Create a temporary object which will be destroyed after the exection
    /// of `updateClosure` closure
    ///
    /// - Parameters:
    ///     - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `Persistance`.
    ///     - updateClosure: Closure with new temporary object for editing
    static func createTemporary(in store: StoreManager,
                                updateClosure: @escaping (Self, NSManagedObjectContext) -> Void)

    /// Update an object in an update closure
    ///
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `Persistance`.
    ///   - updateClosure: Closure with object for editing
    ///   - completeClosure: Closure with saved object on main thread
    func update(in store: StoreManager,
                updateClosure: @escaping (Self, NSManagedObjectContext) -> Void,
                completeClosure: ((Self) -> Void)?)

    /// Deletes an entity from a NSManagedObjectContext specified by `context` parameter
    ///
    /// - Parameters:
    ///     - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `Persistance`.
    ///     - context: Source `NSManagedObjectContext`. Default is Main Context
    ///     - completeClosure: Closure which is triggered after context save
    func delete(from store: StoreManager, sourceContext: NSManagedObjectContext, completeClosure: (() -> Void)?)

    /// Deletes a collection of entity results fetched by `predicate` condition
    ///
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `Persistance`.
    ///   - predicate: `NSPredicate` which specified which entities to delete
    ///   - context: Source `NSManagedObjectContext`. Default is Main Context
    ///   - offsetPage: Delete from `offsetPage`, page size is 10
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
                    sourceContext: NSManagedObjectContext = StoreManager.default.mainContext,
                    shouldCreate: Bool = false) -> Self? {

        let fetchRequest = NSFetchRequest<Self>(entityName: "\(Self.self)")
        fetchRequest.predicate = idKeyPath == entityID

        do {
            if let result = try sourceContext.fetch(fetchRequest).first {
                return result

            } else if shouldCreate {
                guard sourceContext != store.mainContext else {
                    Log.error("\n\nTrying to fetch non existing entity with `shouldCreate` flag on mainContext. Entity creation must be done on background context, or left with default\n\n")
                    return nil
                }
                return Self(entity: entity(), insertInto: sourceContext)
            }

        } catch {
            Log.error("Failed fetching entity of type: \(Self.self)")
        }

        return nil
    }

    static func get(from store: StoreManager = StoreManager.default,
                    using predicate: NSPredicate,
                    sortDescriptors: [NSSortDescriptor]? = nil,
                    sourceContext: NSManagedObjectContext = StoreManager.default.mainContext) -> [Self] {

        let fetchRequest = NSFetchRequest<Self>(entityName: "\(Self.self)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors

        do {
            return try sourceContext.fetch(fetchRequest)

        } catch {
            Log.error("Failed fetching entity of type: \(Self.self)")
        }

        return []
    }

    static func getAll(from store: StoreManager = StoreManager.default,
                       sortDescriptors: [NSSortDescriptor]? = nil,
                       sourceContext: NSManagedObjectContext = StoreManager.default.mainContext) -> [Self] {
        return get(from: store,
                   using: .true,
                   sortDescriptors: sortDescriptors,
                   sourceContext: sourceContext)
    }

    static func create(in store: StoreManager = StoreManager.default,
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
                let entitiesToDelete = get(from: store,
                                           using: idKeyPath == entityID,
                                           sourceContext: context)
                    .filter { $0.objectID != temporaryEntity.objectID }
                
                if !entitiesToDelete.isEmpty {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "\(Self.self)")
                    fetchRequest.predicate = NSPredicate(format: "self in %@", entitiesToDelete)
                    let deleteRequest = NSBatchDeleteRequest( fetchRequest: fetchRequest)
                    do {
                        try context.execute(deleteRequest)
                    } catch {
                        Log.error("Failed to remove a duplicate entity of type \(Self.self) with id: \(entityID), aborting.")
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
                fetchRequest.sortDescriptors = options.sortDescriptors

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
