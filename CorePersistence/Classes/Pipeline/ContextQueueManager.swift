//
//  ContextManager.swift
//  Persistence
//
//  Created on 6/25/18.
//  Copyright © 2018 Human Dx, Ltd. All rights reserved.
//

import Foundation
import CoreData

/// `ContextQueueManager` is used to synchronize incoming parsing, a global queue is made and
/// every parse is must go through the queue to be saved in the `NSPersistantStore`.
/// This way we avoid an entity being parsed without the knowledge of all the `NSManagedContexts` which already contain
/// that entity, and will result in a conflict on save.
class ContextQueueManager {

    static let instance: ContextQueueManager = ContextQueueManager()

    /// `OperationQueue` which guarantees that context are going to save one by one
    lazy private var executionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    /// Method which adds a `NSManagedContext` to the queue. Closures are used to make changes to the context, and
    /// to notify that the context has finished saving.
    ///
    /// - Parameters:
    ///   - context: `NSManagedContext` to add to the queue.
    ///   - dataModificationClosure: Closure which will contain changes to the context.
    ///   - dataPersistedCompleteClosure: Closure which will be used to notify that the context has saved.
    func push(context: NSManagedObjectContext,
              dataModificationClosure: @escaping () -> Void,
              dataPersistedCompleteClosure: @escaping () -> Void) {

        executionQueue.addOperation {
            context.refreshAllObjects()
            dataModificationClosure()

            if context.hasChanges {
                do {
                    try context.save()

                } catch {
                    print("\n\n\nCONTEXT SAVING FAILED\n\(error)\n\n")
                }
            }

            dataPersistedCompleteClosure()
        }
    }
}
