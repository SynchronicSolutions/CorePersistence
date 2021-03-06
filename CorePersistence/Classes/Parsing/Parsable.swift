//
//  Parsable.swift
//  Persistence
//
//  Created on on 12/21/18.
//  Copyright © 2018 Milos Babic, Ltd. All rights reserved.
//

import CoreData
public typealias ParsableManagedObject = NSManagedObject & Parsable

public protocol Parsable: PersistableManagedObject {

    /// Key in JSON dictionary which will represent a unique `id`. Default to set to string value of `idKeyPath`
    static var jsonKey: String { get }

    /// Variable which represents deserialized `Parsable` object
    var jsonDictionary: JSONObject { get }

    /// Method which performs parsing on a `Parsable` type. Given a `json` dictionary,
    /// an Entity is parsed using `mapValues(:)`, and then, on a background context, persisted to `NSPersistentStore`.
    /// If an object already exists in the store, that one will be updated, so that the uniqueness of `entityID` will
    /// be kept.
    ///
    /// - Parameters:
    ///   - json: [String: Any] dictionary which contains data which should be parsed.
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///            Default is the one defined in `CorePersistence`.
    ///   - completeClosure: After the parsing is finished, `completeClosure` is triggered with a fresh entity from
    ///                      a `store`'s main context.
    static func parse(json: JSONObject, in store: StoreManager, completeClosure: ((Self?) -> Void)?)

    /// Method which performs parsing on a `Parsable` type. Given a `json` array of dictionaries,
    /// entites are being parsed using `mapValues(:)`, and then, on a background context, persisted to `NSPersistentStore`.
    /// If any of the objects already exists in the store, those ones will be updated,
    /// so that the uniqueness of `entityID` will be kept.
    ///
    /// - Parameters:
    ///   - jsonArray: Array of [String: Any] dictionaries which contain data which should be parsed.
    ///   - store: `StoreManager` instance which contains `NSPersistentStore`.
    ///            Default is the one defined in `CorePersistence`.
    ///   - completeClosure: After the parsing is finished, `completeClosure`
    ///                      is triggered with a fresh array of entities from a `store`'s main context.
    static func parse(jsonArray: [JSONObject],
                      in store: StoreManager,
                      completeClosure: (([Self]) -> Void)?)

    /// Method which is called during a call from `parse(...)`.
    /// In it parsing from `MappingValues` can be defined using custom operator `<-`
    /// Warning: This method shouldn't be called manually or from a main thread.
    /// Also id shouldn't be set manually, i.e. id = 3, because `parse(...)` method is getting the id from
    /// JSON dictionary before this, so this can disrupt uniqueness of main key in CoreData.
    /// ```
    /// final class Entity: NSManagedObject, Parsable {
    ///     public func mapValues(from map: MappingValues) {
    ///         id      <- map["id"]
    ///         title   <- map["title"]
    ///         date    <- (map["date"], CustomTransforms.dateTransform)
    ///     }
    /// }
    /// ```
    /// - Parameter map: Wrapper around `[String: Any]` dictionary, does basic operations a dictionary does,
    ///                  and is `NSManagedObjectContext` aware.
    func mapValues(from map: MappingValues)
}

public extension Parsable {

    static var jsonKey: String {
        return NSExpression(forKeyPath: idKeyPath).keyPath
    }

    var jsonDictionary: JSONObject {
        return [:]
    }

    static func parse(json: JSONObject,
                      in store: StoreManager = StoreManager.default,
                      completeClosure: ((Self?) -> Void)? = nil) {
        parse(jsonArray: [json], in: store) { (entities) in
            completeClosure?(entities.first)
        }
    }

    static func parse(jsonArray: [JSONObject],
                      in store: StoreManager = StoreManager.default,
                      completeClosure: (([Self]) -> Void)? = nil) {
        guard !jsonArray.isEmpty else {
            completeClosure?([])
            return
        }

        store.performBackgroundTask { (backgroundContext) in
            var entityIDs: [EntityID] = []

            ContextQueueManager.instance.push(context: backgroundContext,
                                              dataModificationClosure: {
                                                entityIDs = fillEntity(with: jsonArray,
                                                                       context: backgroundContext).map { $0[keyPath: idKeyPath] }
            }, dataPersistedCompleteClosure: {
                DispatchQueue.main.async {
                    let entities = get(from: store, using: idKeyPath === entityIDs, sourceContext: backgroundContext.parent ?? store.mainContext)
                    completeClosure?(entities)
                }
            })
        }
    }

    static func fillEntity(with jsonArray: [JSONObject],
                           storeManager: StoreManager = StoreManager.default,
                           context: NSManagedObjectContext) -> [Self] {
        
        var filledEntites: [Self] = []
        for json in jsonArray {
            guard
                let transformableEntityID = json[keyPath: jsonKey] as? BasicTransformable,
                let entityID = EntityID.transform(value: transformableEntityID) else {
                continue
            }
            
            var entityToFill: Self
            if let entity = get(entityID: entityID, from: storeManager, sourceContext: context) {
                entityToFill = entity
            } else {
                entityToFill = Self.init(entity: entity(), insertInto: context)
            }

            entityToFill[keyPath: idKeyPath] = entityID
            entityToFill.mapValues(from: MappingValues(json: json, context: context))
            filledEntites.append(entityToFill)
        }

        return filledEntites
    }

    static func fillEntity(with json: JSONObject,
                           storeManager: StoreManager = StoreManager.default,
                           context: NSManagedObjectContext) -> Self? {
        return fillEntity(with: [json], storeManager: storeManager, context: context).first
    }
}
