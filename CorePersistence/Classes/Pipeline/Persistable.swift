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
                    sourceContext: NSManagedObjectContext?,
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
                    sourceContext: NSManagedObjectContext?) -> [Self]

    /// Retrieves all entities from a `StoreManager` instance defined with `store` parameter, defaultly from a
    /// main context on the `store`, but a different one can be passed with `sourceContext` parameter.
    /// - Parameters:
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///             Default is the one defined in `Persistance`.
    ///   - sourceContext: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`.
    /// - Returns: All existing objects
    static func getAll(from store: StoreManager,
                       sortDescriptors: [NSSortDescriptor]?,
                       sourceContext: NSManagedObjectContext?) -> [Self]

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
    func delete(from store: StoreManager, sourceContext: NSManagedObjectContext?, completeClosure: (() -> Void)?)

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
                    from store: StoreManager = StoreManager(),
                    sourceContext: NSManagedObjectContext? = nil,
                    shouldCreate: Bool = false) -> Self? {

        let context: NSManagedObjectContext
        if let sourceContext = sourceContext {
            context = sourceContext
        } else {
            context = store.mainContext
        }

        let fetchRequest = NSFetchRequest<Self>(entityName: "\(Self.self)")
        fetchRequest.predicate = idKeyPath == entityID

        do {
            if let result = try context.fetch(fetchRequest).first {
                return result

            } else if shouldCreate {
                if context == store.mainContext {
                    print("\n\nATTEMPTING TO FETCH ENTITY OF TYPE: \(Self.self) FROM MAIN THREAD\n\n")
                } else {
                    return Self(entity: Self.entity(), insertInto: context)
                }
            }
        } catch {
            print("\n\nFETCHING OF TYPE: \(Self.self) FAILED\n \(error)\n\n")
        }

        return nil
    }

    static func get(from store: StoreManager = StoreManager(),
                    using predicate: NSPredicate,
                    sortDescriptors: [NSSortDescriptor]? = nil,
                    sourceContext: NSManagedObjectContext? = nil) -> [Self] {

        let context: NSManagedObjectContext
        if let sourceContext = sourceContext {
            context = sourceContext
        } else {
            context = store.mainContext
        }

        let fetchRequest = NSFetchRequest<Self>(entityName: "\(Self.self)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors

        do {
            return try context.fetch(fetchRequest)

        } catch {
            print("\n\nFETCHING OF TYPE: \(Self.self) FAILED\n \(error)\n\n")
        }

        return []
    }

    static func getAll(from store: StoreManager = StoreManager(),
                       sortDescriptors: [NSSortDescriptor]? = nil,
                       sourceContext: NSManagedObjectContext? = nil) -> [Self] {
        return get(from: store,
                   using: .true,
                   sortDescriptors: sortDescriptors,
                   sourceContext: sourceContext)
    }

    static func create(in store: StoreManager = StoreManager(),
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
                let entitiesToDelete = get(from: store, using: idKeyPath == entityID, sourceContext: context).filter { $0.objectID != temporaryEntity.objectID }
                
                if !entitiesToDelete.isEmpty {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "\(Self.self)")
                    fetchRequest.predicate = NSPredicate(format: "self in %@", entitiesToDelete)
                    let deleteRequest = NSBatchDeleteRequest( fetchRequest: fetchRequest)
                    do {
                        try context.execute(deleteRequest)
                    } catch {
                        print("\n\nDuplicate deletion of type: \(Self.self) FAILED\n \(error). There are two entities in database with id \(entityID)\n\n")
                    }
                }
                
            }, dataPersistedCompleteClosure: {
                DispatchQueue.main.async {
                    guard let entityID = entityID, let savedObject = Self.get(entityID: entityID, from: store) else {
                        print("\n\nENTITY OF TYPE \(Self.self) WAS NOT SAVED ON MAIN CONTEXT\n\n")
                        return
                    }
                    completeClosure?(savedObject)
                }
            })
        }
    }

    static func createTemporary(in store: StoreManager = StoreManager(),
                                updateClosure: @escaping (Self, NSManagedObjectContext) -> Void) {

        store.performBackgroundTask { (context) in
            let temporaryEntity = Self(entity: Self.entity(), insertInto: context)
            updateClosure(temporaryEntity, context)
            context.reset()
        }
    }

    func update(in store: StoreManager = StoreManager(),
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
                    print("\n\nFAILED TO FETCH ENTITY \(Self.self) with id: \(uniqueID)\n\n")
                    return
                }

                updateClosure(refetchedEntity, context)

            }, dataPersistedCompleteClosure: {
                DispatchQueue.main.async {
                    let uniqueID = self[keyPath: Self.idKeyPath]
                    if let refetchedEntity = Self.get(entityID: uniqueID, from: store) {
                        completeClosure?(refetchedEntity)

                    } else {
                        print("\n\nFAILED TO FETCH ENTITY \(Self.self) with id: \(uniqueID)\n\n")
                    }
                }
            })
        }
    }

    func delete(from store: StoreManager = StoreManager(),
                sourceContext: NSManagedObjectContext? = nil, completeClosure: (() -> Void)? = nil) {
        let uniqueID = self[keyPath: Self.idKeyPath]
        let deleteOptions = DeleteOptions(sourceContext: sourceContext,
                                          predicate: Self.idKeyPath == uniqueID)
        Self.delete(from: store,
                    with: deleteOptions,
                    completeClosure: completeClosure)
    }

    static func delete(from store: StoreManager = StoreManager(),
                       with options: DeleteOptions = DeleteOptions(),
                       completeClosure: (() -> Void)? = nil) {

        let context: NSManagedObjectContext
        if let sourceContext = options.sourceContext, sourceContext != store.mainContext {
            context = sourceContext
        } else {
            context = store.newBackgroundContext
        }

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
                    if let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult,
                        let entityIDs = result.result as? [NSManagedObjectID] {

                        let changes = [NSDeletedObjectsKey: entityIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [store.mainContext])
                    } else {
                        print("\n\nRESULT OF BATCH DELETE OF \(Self.self) IS NOT OF TYPE `NSBatchDeleteResult`\n\n")
                    }
                } catch {
                    print("\n\nBATCH DELETE OF ENTITY \(Self.self) FAILED\n\(error)\n\n")
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
    func delete(from store: StoreManager = StoreManager(),
                context: NSManagedObjectContext,
                complete: @escaping () -> Void) {
        let ids = map { $0[keyPath: Element.idKeyPath] }

        let deleteOptions = DeleteOptions(sourceContext: context, predicate: Element.idKeyPath === ids)
        Element.delete(from: store,
                       with: deleteOptions,
                       completeClosure: complete)

    }
}
