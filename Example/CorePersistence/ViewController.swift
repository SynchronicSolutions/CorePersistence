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
        
        User.parse(jsonArray: users) { parsedUsers in
            _ = parsedUsers.first?.uuid
            print(parsedUsers)
        }
        
        let user = User.get(entityID: uuid)
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
        
        results = Results<User>(predicate: .true) { (changes, newResults) in
            print(changes)
        }
        
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
    }
}

