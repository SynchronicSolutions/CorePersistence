//
//  Operators.swift
//  Persistence
//
//  Created on 5/28/19.
//  Copyright © 2019 Human Dx, Ltd. All rights reserved.
//

import Foundation
import CoreData

public typealias MapValueTouple<TransformType: Transformable>
    = (mapingValues: MappingValues, customTransform: (Any?) -> TransformType?)

infix operator <-

// MARK: BASIC TYPES
public func <- <TransformType: BasicTransformable>(left: inout TransformType, right: BasicTransformable) {
    if let transformedValue = TransformType.transform(value: right) {
        left = transformedValue
    }
}

public func <- <TransformType: BasicTransformable>(left: inout TransformType?, right: BasicTransformable) {
    left = TransformType.transform(value: right)
}

public func <- <TransformType: BasicTransformable>(left: inout TransformType, right: MapValueTouple<TransformType>) {
    if let customTransformedValue = right.customTransform(right.mapingValues.currentValue) {
        left = customTransformedValue

    } else {
        left <- right.mapingValues
    }
}

// MARK: COMPLEX TYPES

public func <- <TransformType: Transformable>(left: inout TransformType, right: MappingValues) {
    if let transformedValue = TransformType.transform(object: right) {
        left = transformedValue
    }
}

public func <- <TransformType: Transformable>(left: inout TransformType?, right: MappingValues) {
    guard right.isKeyPresent else { return }
    left = TransformType.transform(object: right)
}

public func <- <TransformType: Transformable>(left: inout TransformType, right: MapValueTouple<TransformType>) {
    if let customTransformedValue = right.customTransform(right.mapingValues.currentValue) {
        left = customTransformedValue

    } else {
        left <- right.mapingValues
    }
}

// MARK: Single relationships

public func <- <RelationshipEntity: Parsable>(left: inout RelationshipEntity, right: MappingValues) {
    guard right.isKeyPresent else { return }

    var temporaryLeft: RelationshipEntity?
    temporaryLeft <- right
    if let temporaryLeft = temporaryLeft {
        left = temporaryLeft
    }
}

public func <- <RelationshipEntity: Parsable>(left: inout RelationshipEntity?, right: MappingValues) {
    guard right.isKeyPresent else { return }

    var jsonToParse: JSONObject?
    if let innerJSON = right.currentValue as? JSONObject {
        jsonToParse = innerJSON

    } else if let innerJSONArray = right.currentValue as? [JSONObject], let firstJSON = innerJSONArray.first {
        jsonToParse = firstJSON

    } else if let innerJSONId = right.currentValue as? BasicTransformable {
        jsonToParse = [RelationshipEntity.jsonKey: innerJSONId]

    } else if let innerJSONIds = right.currentValue as? [BasicTransformable], let first = innerJSONIds.first {
        jsonToParse = [RelationshipEntity.jsonKey: first]

    } else {
        left = nil
    }

    if let json = jsonToParse {
        left = RelationshipEntity.fillEntity(with: json, context: right.managedObjectContext)
    }
}

// MARK: Many to many or to one relationships

public func <- <RelationshipEntity: Parsable>(left: inout Set<RelationshipEntity>?, right: MappingValues) {
    guard right.isKeyPresent else { return }

    var temporaryLeft: Set<RelationshipEntity> = Set()
    temporaryLeft <- right
    left = temporaryLeft
}

public func <- <RelationshipEntity: Parsable>(left: inout Set<RelationshipEntity>, right: MappingValues) {
    guard right.isKeyPresent else { return }

    if let json = right.currentValue as? [JSONObject] {
        left = Set(RelationshipEntity.fillEntity(with: json, context: right.managedObjectContext))

    } else if let json = right.currentValue as? JSONObject,
        let entity = RelationshipEntity.fillEntity(with: json, context: right.managedObjectContext) {
        left = Set([entity])

    } else if let entityIDs = right.currentValue as? [BasicTransformable] {
        let idDictionaries: [JSONObject] = entityIDs.compactMap { (basicTransformableValue) in
            let transformableEntityID = RelationshipEntity.EntityID.self
            if let entityID = transformableEntityID.transform(value: basicTransformableValue) {
                return [RelationshipEntity.jsonKey: entityID]
            }
            return nil
        }
        left = Set(RelationshipEntity.fillEntity(with: idDictionaries, context: right.managedObjectContext))

    } else if let entityID = right.currentValue as? BasicTransformable,
        let entity = RelationshipEntity.fillEntity(with: [RelationshipEntity.jsonKey: entityID],
                                                   context: right.managedObjectContext) {
        left = Set([entity])

    } else {
        left = Set<RelationshipEntity>()
    }
}
