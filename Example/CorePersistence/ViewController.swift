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
            _ = parsedUsers.first?.uuid
            print(parsedUsers)
        }
    }
}

// MARK: PERSISTABLE

extension ViewController {
    
    func crudDemo() {
        
        // Create a new user, if the user with this unique id already exists, it will overwrite it
        User.create(updateClosure: { (userToUpdate, context) in
            userToUpdate.uuid = "b4c7900b-10f0-45ff-8692-0ff1e5ce2ac4"
            userToUpdate.firstName = "Mark"
            userToUpdate.lastName = "Twain"
            userToUpdate.birthDate = Date()
            
            let address = Address(context: context)
            address.uuid = "a8b6c763-eb10-4e82-b872-5504ee4c762c"
            userToUpdate.address = address
            
        }, completeClosure: { persistedUser in
            print(persistedUser)
        })
        
        // Creates a temporary user, does not exist outside of closure
        User.createTemporary { (temporaryUser, context) in
            temporaryUser.uuid = "b4c7900b-10f0-45ff-8692-0ff1e5ce2ac4"
            temporaryUser.firstName = "Mark"
            temporaryUser.lastName = "Twain"
            temporaryUser.birthDate = Date()
            
            let address = Address(context: context)
            address.uuid = "a8b6c763-eb10-4e82-b872-5504ee4c762c"
            temporaryUser.address = address
        }
        
        // Single user get by it's unique id key marked with idKeyPath
        let user = User.get(entityID: uuid)
        
        // Get all users
        let allUsers = User.getAll()
        
        // Users with the first name Mark sorted by birth date
        let usersWithNameMark = User.get(using: \User.firstName == "Mark" && \User.birthDate <= Date(),
                                         sortDescriptors: [NSSortDescriptor(keyPath: \User.birthDate, ascending: true)])
        
        // Fetch all User objects, store it so that it remains in memory
        results = Results<User>(predicate: \User.address != nil, sortBy: [NSSortDescriptor(keyPath: \User.birthDate, ascending: true)]) { (changes, newResults) in
            // Closure receieves bulk changes, with updated result set
            print(changes)
        }
        
        // Update fetched user with new data
        user?.update(updateClosure: { (user, context) in
            user.birthDate = Date()
            user.numberOfOrders = 50
            
            let newOrder = Order(context: context)
            let newAddress = Address(context: context)
            newAddress.uuid = "669cdb66-58ba-4579-a951-1b0acac7aae5"
            
            newOrder.uuid = "b8b3183d-2ea9-477d-99c5-98f7e7707ef4"
            newOrder.address = newAddress
            
            user.orders.insert(newOrder)
            
        }, completeClosure: { user in
            _ = user.uuid
            print(user)
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Delete a single entity
            user?.delete()
            
            // Delete all users with a certain condition expressed in predicate
            User.delete(with: DeleteOptions(predicate: \User.birthDate < Date())) {
                Log.verbose("Finished deleting")
            }
        }
    }
}


