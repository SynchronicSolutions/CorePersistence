//
//  ViewController.swift
//  CorePersistence
//
//  Created by SynchronicSolutions on 12/12/2019.
//  Copyright (c) 2019 SynchronicSolutions. All rights reserved.
//

import UIKit
import CorePersistence

class ViewController: UIViewController {
    
    let uuid = "8fda9bf4-4631-4290-ac4b-7ce62a3aacd6"
    
    let users: [[String: Any]] = [
        [
            "uuid": "8fda9bf4-4631-4290-ac4b-7ce62a3aacd6",
            "account_type": 1,
            "first_name": "Tom",
            "last_name": "Selleck",
            "number_of_orders": "27.0",
            "birth_date": "1954-03-10",
            "address": [
                "uuid": "71991821-3db2-4549-ae8c-eeafc8b6af36"
            ],
            "orders": [
                ["uuid": "649e5991-c591-4055-8649-d1e6264ee768",
                "address_id": "71991821-3db2-4549-ae8c-eeafc8b6af36"],
                ["uuid": "47acff4a-fd5f-4fb0-8ea2-96b66cdd13e0",
                "address_id": "2603087d-4555-4a54-8992-a1a33ddfb9d8"]
            ]
        ]
    ]
    
    var results: Results<User>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        parseDemo()
        crudDemo()
    }
}

// MARK: PARSABLE

extension ViewController {
    func parseDemo() {
        User.parse(jsonArray: users) { parsedUsers in
            print("Parsed user ids \(parsedUsers.map { $0.uuid })")
        }
    }
}

// MARK: PERSISTABLE

extension ViewController {
    
    func crudDemo() {
        
        // Create a new user, if the user with this unique id already exists, it will overwrite it
        User.create(updateIfEntityExists: false, updateClosure: { (userToUpdate, context) in
            userToUpdate.uuid = "b4c7900b-10f0-45ff-8692-0ff1e5ce2ac4"
            userToUpdate.firstName = "Mark"
            userToUpdate.lastName = "Twain"
            userToUpdate.birthDate = Date()
            userToUpdate.address = Address(entityID: "a8b6c763-eb10-4e82-b872-5504ee4c762c", context: context)

        }, completeClosure: { persistedUser in
            print("ID of created user \(persistedUser.uuid)")
        })

        // Creates a temporary user, does not exist outside of closure
        User.createTemporary { (temporaryUser, context) in
            temporaryUser.uuid = "b4c7900b-10f0-45ff-8692-0ff1e5ce2ac4"
            temporaryUser.firstName = "Mark"
            temporaryUser.lastName = "Twain"
            temporaryUser.birthDate = Date()

            temporaryUser.address = Address(entityID: "a8b6c763-eb10-4e82-b872-5504ee4c762c", context: context)
        }
        
        // Single user get by it's unique id key marked with idKeyPath
        let user = User.get(entityID: uuid)
        
        // Get all users
        let _ = User.getAll()
        
        // Users with the first name Mark sorted by birth date
        let _ = User.get(using: \User.firstName == "Mark" && \User.birthDate <= Date(),
                         comparisonClauses: [.ascending(\User.birthDate)])
        
        // Fetch all User objects, store it so that it remains in memory
        results = Results<User>()
            .filterBy(\User.address != nil)
            .sortBy(.ascending(\User.birthDate), .descending(\User.address))
            .registerForChanges { (changes) in
                print("Changes: \(changes.map { ($0.type, $0.object.uuid) })")
        }
        
        // Update fetched user with new data
        DispatchQueue.main.async {
            user?.update(updateClosure: { (user, context) in
                user.birthDate = Date()
                user.numberOfOrders = 50

                let newOrder = Order(entityID: "b8b3183d-2ea9-477d-99c5-98f7e7707ef4", context: context)
                newOrder.address = Address(entityID: "669cdb66-58ba-4579-a951-1b0acac7aae5", context: context)
                user.orders.insert(newOrder)

            }, completeClosure: { user in
                print("Updated birth date and number of orders: \(user.birthDate!)", "\(user.numberOfOrders)")
            })
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            user?.delete()

            // Delete all users with a certain condition expressed in predicate
            User.delete(with: DeleteOptions(predicate: \User.birthDate < Date())) {
                Log.verbose("Finished deleting")
            }
        }
    }
}


