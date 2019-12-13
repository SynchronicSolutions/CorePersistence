# CorePersistence

[![Version](https://img.shields.io/cocoapods/v/CorePersistence.svg?style=flat)](https://cocoapods.org/pods/CorePersistence)
[![Platform](https://img.shields.io/cocoapods/p/CorePersistence.svg?style=flat)](https://cocoapods.org/pods/CorePersistence)

CorePersistence is a pod which does all the CoreData management for you.

- [Features](#features)
- [Usage](#usage)
    - [Integration](#integration)
    - [Persisting](#persisting)
        - [CRUD](#crud)    
            - [Create](#create)
            - [Read](#read)
            - [Update](#update)
            - [Delete](#delete)
    - [Parsing](#parsing)
        - [Methods](#methods)
    - [Predicates](#predicates)
    - [Results](#results)
    - [Loging](#loging)
- [Example](#installation)
- [Requirements](#requirements)
- [Installation](#installation)
- [Author](#author)
- [License](#license)

# Features
- [x] Simple integration
- [x] Out of the box CoreData solution
- [x] Thread safe CRUD operations in sqlite
- [x] Conflict free operations
- [x] Automatic type conversion during parsing
- [x] Easy to work with predicates

# Usage
CorePersistence is an easy to use CocoaPod which is used for a wrapper for CoreData, and easy out-of-the-box JSON parsing. All write operations are done on a background contexts, and synced using OperationsQueue. Entity uniqueness is assured by defining a keypath which is refering to a property which will be used as a unique id constraint. These entities can be automatically parsed by implementing `Parsable` protocol, and implementing a method, and by using `<-` operator all conversions, relationship linking are done automatically.

## Integration
Before using features of `CorePersistence`, it's needed to initialize it first by calling:
```swift 
func initializeStack(with modelName: String, handleMigration: (() -> Void)? = nil)
```
which takes a name of your `.xcdatamodeld`, and a closure which is triggered when a heavyweight conversion occurs. 
__Currently, in case of heavyweight migration, current `.sqlite` is deleted, and recreated with a new model version.__

## Persisting

When creating your models which are intended for persisting you must implement `Persistable` protocol. 
This is what an example entity looks like when implemented:

##### User+CoreDataClass.swift
```swift
@objc(User)
final public class User: ParsableManagedObject {

    public static var idKeyPath: WritableKeyPath<User, String> {
        return \Self.uuid
    }
}
```
##### User+CoreDataProperties.swift
```swift
extension User {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
    @NSManaged public var uuid: String
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
}
```

### CRUD ###
#### Create ####
___
```swift
static func create(in store: StoreManager,
                   updateClosure: @escaping (Self, NSManagedObjectContext) -> Void,
                   completeClosure: ((Self) -> Void)?)
```
Creates a `Persistable` entity on a background context on a `NSPersistentStore` defined with `store` parameter  `updateClosure` is triggered on a background thread, passing a newly created object, or if it already exists,
object to be updated.
###### Parameters:
- _store_: `StoreManager` instance which contains `NSPersistentStore`. Default is the one defined in `Persistance`.
- _updateClosure_: Triggered when a new entity is created or, existing entity fetched.
- _completeClosure_: After saving backgrond context, the complete block is dispatched asynchronously on the main thread, with a fresh object refetched from main context.

###### Example:
```swift
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
```
___

```swift
static func createTemporary(in store: StoreManager,
                            updateClosure: @escaping (Self, NSManagedObjectContext) -> Void)
```
Create a temporary object which will be destroyed after the exection of `updateClosure` closure.
###### Parameters:
- _store_: `StoreManager` instance which contains `NSPersistentStore`. Default is the one defined in `Persistance`.
- _updateClosure_: Closure with new temporary object for editing

###### Example:
```swift
User.createTemporary { (temporaryUser, context) in
    temporaryUser.uuid = "b4c7900b-10f0-45ff-8692-0ff1e5ce2ac4"
    temporaryUser.firstName = "Mark"
    temporaryUser.lastName = "Twain"
}
```
#### Read ####
___

```swift
static func get(entityID: EntityID,
                from store: StoreManager,
                sourceContext: NSManagedObjectContext,
                shouldCreate: Bool) -> Self?
```
Retrieves a single entity from a `StoreManager` instance defined with `store` parameter, defaultly from a main context on the `store`, but a different one can be passed with `sourceContext` parameter.
###### Parameters:
- _entityID_: Unique ID which every entity must have, and only one entity must have this particular one
- _store_: `StoreManager` instance which contains `NSPersistentStore`. Default is the one defined in `Persistence`.
- _sourceContext_: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`.
- _shouldCreate_: If the entity doesn't exist in this context, the flag should define if the method should create the entity.
- _Returns_: Existing object with `entityID`, or a new one if `shouldCreate` flag is set to `true`.

###### Example:
```swift
let user = User.get(entityID: "8fda9bf4-4631-4290-ac4b-7ce62a3aacd6")
```

___

```swift
static func get(from store: StoreManager,
                using predicate: NSPredicate,
                sortDescriptors: [NSSortDescriptor]?,
                sourceContext: NSManagedObjectContext) -> [Self]
```
Retrives multiple entities from a `StoreManager` instance defined with `store` parameter, defaultly from a main context on the `store`, but different one can be passed with `sourceContext` parameter.
###### Parameters:
- _store_: `StoreManager` instance which contains `NSPersistentStore`. Default is the one defined in `Persistance`.
- _predicate_: Query predicate used to fetch the entities.
- _sortDescriptors_: Array of `NSSortDescriptor` instances.
- _sourceContext_: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`.
- _Returns_: Objects from `sourceContext` which conform to `predicate` and sorted in regards to `sortDescriptors`
    
###### Example:
```swift
let usersWithNameMark = User.get(using: \User.firstName == "Mark" && \User.birthDate <= Date(),                      
                                 sortDescriptors: [NSSortDescriptor(keyPath: \User.birthDate, ascending: true)])
```
___

```swift
static func getAll(from store: StoreManager,
                   sortDescriptors: [NSSortDescriptor]?,
                   sourceContext: NSManagedObjectContext) -> [Self]
```
Retrieves all entities from a `StoreManager` instance defined with `store` parameter, defaultly from a main context on the `store`, but a different one can be passed with `sourceContext` parameter.
###### Parameters:
- _store_: `StoreManager` instance which contains `NSPersistentStore`.
- _sortDescriptors_: Array of `NSSortDescriptor` instances.
- _sourceContext_: Instance of `NSManagedObjectContext` in which the method will look for the `entityID`.
- _Returns_: All existing objects

###### Example:
```swift
let allUsers = User.getAll()
```


#### Update ####
___

```swift
func update(in store: StoreManager,
            updateClosure: @escaping (Self, NSManagedObjectContext) -> Void,
            completeClosure: ((Self) -> Void)?)
```
Update an object in an update closure.
###### Parameters:
- _store_: `StoreManager` instance which contains `NSPersistentStore`. Default is the one defined in `Persistence`.
- _updateClosure_: Closure with object for editing
- _completeClosure_: Closure with saved object on main thread

###### Example
```swift
user.update(updateClosure: { (user, context) in
        user.firstName = "New Name"
        let newOrder = Order(context: context)
        newOrder.uuid = "b8b3183d-2ea9-477d-99c5-98f7e7707ef4"
        user.orders.insert(newOrder)
        
    }, completeClosure: { updatedUser in
        print(updatedUser)
    })
```
#### Delete ####
___
```swift
func delete(from store: StoreManager, 
            sourceContext: NSManagedObjectContext, 
            completeClosure: (() -> Void)?)
```
Deletes an entity from a NSManagedObjectContext specified by `context` parameter
###### Parameters:
- _store_: `StoreManager` instance which contains `NSPersistentStore`. Default is the one defined in `Persistance`.
- _context_: Source `NSManagedObjectContext`. Default is Main Context
- _completeClosure_: Closure which is triggered after context save

###### Example:
```swift
user.delete {
    print("Entity deleted")
}
```
___
```swift
static func delete(from store: StoreManager,
                   with options: DeleteOptions,
                   completeClosure: (() -> Void)?)
```
Deletes a collection of entity results fetched by `predicate` condition
###### Parameters:
- _store_: `StoreManager` instance which contains `NSPersistentStore`. Default is the one defined in `Persistance`.
- _predicate_: `NSPredicate` which specified which entities to delete
- _context_: Source `NSManagedObjectContext`. Default is Main Context
- _offsetPage_: Delete from `offsetPage`, page size is 10
- _completeClosure_: Closure which is triggered after context save

###### Example:
```swift
User.delete(with: DeleteOptions(predicate: \User.birthDate < Date())) {
    print("Finished deleting")
}
```

## Parsing

To enable models to be parsed, they must implement `Parsable` protocol. `Parsable` protocol automatically conforms to `Persistable` protocol, so if the entities should be persisted and parsed it's just necessesary to implement `Parsable` protocol. 

There is one method which needs to be implemented: 

```swift
func mapValues(from map: MappingValues)
```
Method which is called during a call from `parse(...)`. In it parsing from `MappingValues` can be defined using custom operator `<-`.
__Warning: This method shouldn't be called manually or from a main thread.__
Also id shouldn't be set manually, i.e. id = 3, because `parse(...)` method is getting the id from JSON dictionary before this, so this can disrupt uniqueness of main key in CoreData.
###### Parameters:
- _map_: Wrapper around `[String: Any]` dictionary, does basic operations a dictionary does, and is `NSManagedObjectContext` aware.

###### Example:
```swift 
final class Entity: ParsableManagedObject {
public func mapValues(from map: MappingValues) {
    title   <- map["title"]
    date    <- (map["date"], { anyDate in
        return Date.transform(anyDate, dateFormats: ["yyyy-MM-dd"])
    })
}
```

Operator `<-` is used to convert and set value from `MappingValues` object to entity's property. It does autoconvertion from Any to `Transformable` type.
###### Transformable types:
- Int, Int16, Int32
- Double
- Date
- Optional
- Array of previous types
- Dictionary of preivous types
- Enums which conform to `Transformable` protocol

###### Features:
- Automatic conversion from incompatible "basic" type (Int, Int16, Int32, Double, String) to an appropriate property type.
- If an entity id is tried to be parsed into any type of relationship, a proper entity will be created and set as relationship or added to a `Set`
- If an array or dictionary with a single element is passed to be parsed to a single entity Relationship, it will parse it as a single entity; it will create a regular `Set` if it's a `One-to-Many` or `Many-to-Many` relationship.
- Values will not be set for properties which doesn't have a  corresponding key set in dictionary.

#### Defining primary key in JSON
Primary key is automatically parsed before `mapValues` is called. This key will be set by default to string value of `idKeyPath` calculcated property. Meaning, the value of the id (primary key) in JSON which is set under value of the key which has the same name like the property which represents primary key in the database, id will be parsed automatically. If these two keys differ, i.e. key in the JSON is `id` and property's name is `uuid`, a computed property `jsonKey` must be implemented so that the parsing methods know which key holds primary key.

###### Example
```swift
{
    "user_id": 123456
}

final class Entity: ParsableManagedObject {
    @NSManaged var id: Int
    
    public static var idKeyPath: WritableKeyPath<User, Int> {
        return \Self.id
    }
    
    // Here we need to implement `jsonKey` because key `user_id` and variable `id` which holds primary key differ
    public static var jsonKey: String {
        return "user_id"
    }
}

final class Entity: ParsableManagedObject {
    @NSManaged var user_id: Int
    
    public static var idKeyPath: WritableKeyPath<User, Int> {
        return \Self.user_id
    }
    
    // In this case it's not needed because they have the same name
    //public static var jsonKey: String {
    //    return "user_id"
    //}
}

```

### Methods

```swift
static func parse(json: JSONObject, in store: StoreManager, completeClosure: ((Self?) -> Void)?)
```
Method which performs parsing on a `Parsable` type. Given a `json` dictionary, an Entity is parsed using `mapValues(:)`, and then, on a background context, persisted to `NSPersistentStore`. If an object already exists in the store, that one will be updated, so that the uniqueness of `entityID` will be kept.

###### Parameters:
- _json_: [String: Any] dictionary which contains data which should be parsed.
- _store_: `StoreManager` instance which contains `NSPersistentStore`. Default is the one defined in `Persistance`.
- _completeClosure_: After the parsing is finished, `completeClosure` is triggered with a fresh entity from `store`'s main context.

###### Example:
```swift
let json: [String: Any] = [
    "uuid": "a8b6c763-eb10-4e82-b872-5504ee4c762c",
    "date": "2000-04-11"
]

User.parse(json: json) { parsedEntity in
    print(parsedEntity)
}
```
___

```swift
static func parse(jsonArray: [JSONObject], in store: StoreManager, completeClosure: (([Self]) -> Void)?)
```
Method which performs parsing on a `Parsable` type. Given a `json` array of dictionaries, entites are being parsed using `mapValues(:)`, and then, on a background context, persisted to `NSPersistentStore`. If any of the objects already exists in the store, those oneswill be updated, so that the uniqueness of `entityID` will be kept.

###### Parameters:
- _jsonArray_: Array of [String: Any] dictionaries which contain data which should be parsed.
- _store_: `StoreManager` instance which contains `NSPersistentStore`. Default is the one defined in `Persistance`.
- _completeClosure_: After the parsing is finished, `completeClosure` is triggered with a fresh array of entities from a `store`'s main context.

###### Example:
```swift
let jsonArray: [[String: Any]] = [
    ["uuid": "a8b6c763-eb10-4e82-b872-5504ee4c762c",
     "date": "2000-04-11"],
    ["uuid": "649e5991-c591-4055-8649-d1e6264ee768",
    "date": "1996-02-08"]
]

User.parse(jsonArray: jsonArray) { parsedEntities in
    print(parsedEntity)
}
```


## Predicates

One of the problems using `NSPredicate` is that there is no auto complete or any check in compile time. In CorePersistence there are some utility operators that create keypaths and conditions into NSPredicates:
```swift
let userID = a8b6c763-eb10-4e82-b872-5504ee4c762c

// Example 1:
NSPredicate(format: "userID == %@ AND numberOfOrders != 0", userID)
// is is the same as:
\User.uuid == userID && \User.numberOfOrders != 0 

// Example 2:
NSPredicate(format: "numberOfOrders >= 0")
// is the same as
\User.numberOfOrders >= 0


let uuids = ["669cdb66-58ba-4579-a951-1b0acac7aae5", "b8b3183d-2ea9-477d-99c5-98f7e7707ef4"]
// Example 3:
NSPredicate(format: "uuid IN %@", uuids)
// is the same as
\User.uuid === uuids
```

## Results

Results object is a wrapper around `NSFetchedResultsController` which encapsulates it's functionallity and switches to closure mechanic to deliver updates on the context instead of multiple delegate methods, and a lot of boilerplate. The main change is that the refresher closure is triggered when *ALL* the changes occur not one by one.

###### Example:
```swift
results = Results<User>(predicate: \User.address != nil, sortBy: [NSSortDescriptor(keyPath: \User.birthDate, ascending: true)]) { (changes, newResults) in
    // Closure receieves bulk changes, with updated result set
    print(changes)
}
```
If the results is defined in current scope, and it's reference isn't kept outside the scope, refreshes won't occur, because the object will get deallocated.

## Loging

There are a couple of utility loging methods which can help log events of different severity:
```swift
🔵🔵🔵 Verbose log 🔵🔵🔵
public static func verbose(_ message: String)

🟠🟠🟠 Warning log 🟠🟠🟠
public static func warning(_ message: String)

🔴🔴🔴 Error log 🔴🔴🔴
public static func error(_ message: String)
```

# Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

# Requirements

- iOS 10.0+
- Xcode 8.3+
- Swift 5+

# Installation

CorePersistence is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CorePersistence'
```

# Author

Milos Babic, miloshbabic88@gmail.com

# License

CorePersistence is available under the MIT license. See the LICENSE file for more info.
