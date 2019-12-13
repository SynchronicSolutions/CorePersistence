//
//  PersistenceController.swift
//  Persistence
//
//  Created on 6/20/18.
//  Copyright © 2018 Human Dx, Ltd. All rights reserved.
//

import Foundation
import CoreData

/**
 * `PersistenceController` class is used to initialize CoreData stack
 */
public class CorePersistence {

    /// Singleton for `PersistenceController`
    public static let instance = CorePersistence()

    /// Name of the .xcdatamodeld passed in the initializeStack method
    var modelName: String!

    private var _mainContainer: NSPersistentContainer?

    /// Default `NSPersistentContainer`
    public var mainContainer: NSPersistentContainer {
        if _mainContainer == nil {
            _mainContainer = NSPersistentContainer(name: modelName, bundle: Bundle(for: CorePersistence.self))

            _mainContainer?.loadPersistentStores { (_, error) in
                if let error = error {
                    Log.error("Failed to load store with error:\n\(error)")
                }
            }

            _mainContainer?.viewContext.automaticallyMergesChangesFromParent = true
        }

        return _mainContainer!
    }

    /// Before any use of Persistence, this method should be called.
    ///
    /// - Parameter modelName: Name of `.xcdatamodeld` in use
    public func initializeStack(with modelName: String, handleMigration: (() -> Void)? = nil) {
        self.modelName = modelName

        migrateIfNeeded(for: modelName, handleMigration: handleMigration)
    }

    func migrateIfNeeded(for modelName: String, handleMigration: (() -> Void)?) {
        guard let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory,
                                                                in: .userDomainMask).last else {
                                                                    Log.error("Failed to get documents directories")
                                                                    return
        }

        let storeURL = documentsDirectory.appendingPathComponent(modelName + ".sqlite")

        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            Log.error("Can't find model URL. Check if the modelName:\(modelName) is the same as .xcdatamodeld filename")
            return
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            Log.error("Failed to create NSManagedObjectModel")
            return
        }

        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            Log.warning("Sqlite file doesn't exist on path, possible first app run: \(storeURL.path)")
            return
        }

        if !isModel(model, compatibleWithStoreAt: storeURL) {
            do {
                try _mainContainer?.persistentStoreCoordinator.persistentStores.forEach { (store) in
                    try _mainContainer?.persistentStoreCoordinator.remove(store)
                }
                try FileManager.default.removeItem(at: storeURL)
                handleMigration?()
                Log.verbose("Database performed migration.")
            } catch {
                Log.error("File manager failed to remove sql file:\n\(error)")
            }
        } else {
            Log.verbose("CorePersistence stack initialized")
        }
    }

    func isModel(_ model: NSManagedObjectModel, compatibleWithStoreAt url: URL) -> Bool {

        var isCompatible: Bool = false
        do {
            let storeMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                            at: url,
                                                                                            options: nil)
            isCompatible = model.isConfiguration(withName: nil, compatibleWithStoreMetadata: storeMetadata)
        } catch {
            Log.error("Failed to get metadata for persistent store at \(url).\n\(error)")
        }
        return isCompatible
    }

    public func removeDatabase() {
        guard let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory,
                                                                in: .userDomainMask).last else {
                                                                    Log.error("Failed to get documents directories")
                                                                    return
        }

        let storeURL = documentsDirectory.appendingPathComponent(modelName + ".sqlite")

        do {
            try _mainContainer?.persistentStoreCoordinator.persistentStores.forEach { (store) in
                try _mainContainer?.persistentStoreCoordinator.remove(store)
            }
            try FileManager.default.removeItem(at: storeURL)
            _mainContainer = nil

        } catch {
            Log.error("File manager failed to remove sql file:\n\(error)")
        }
    }
}

extension NSPersistentContainer {
    convenience init(name: String, bundle: Bundle) {

        guard let modelURL = bundle.url(forResource: name, withExtension: "momd"),
            let mom = NSManagedObjectModel.init(contentsOf: modelURL) else {
                self.init(name: name)

                return
        }

        self.init(name: name, managedObjectModel: mom)
    }
}
