//
//  Entity.swift
//  gameninja
//
//  Created by Benzi on 19/06/14.
//  Copyright (c) 2014 Benzi Ahamed. All rights reserved.
//

import Foundation
import SpriteKit


// MARK: Entity ------------------------------------------

class Entity {
    var id:UInt
    
    init(id:UInt){
        self.id = id
    }
}




// MARK: EntityManager ------------------------------------------

class EntityManager {

    struct EntityId{
        static var lowestIdCreated:UInt = 0
    }
    
    var entites:NSMutableArray
    var componentsByType:Dictionary<ComponentType,NSMutableDictionary>
    
    init(){
        entites = NSMutableArray()
        componentsByType = Dictionary<ComponentType,NSMutableDictionary>()
    }
    
    func createEntityId() -> UInt {
        if EntityId.lowestIdCreated < UInt.max {
            return EntityId.lowestIdCreated++
        } else {
            for i in 1..UInt.max {
                if !self.entites.containsObject(i) {
                    return i
                }
            }
        }
        return 0
    }
    
    func createEntity() -> Entity {
        let e = Entity(id: createEntityId())
        entites.addObject(e.id)
        return e
    }
    
    func removeEntity(e:Entity) {
        for components in componentsByType.values {
            if components[e.id] != nil {
                components.removeObjectForKey(e.id)
            }
        }
        entites.removeObject(e.id)
    }
    
    func addComponent(e:Entity, c:Component){
        if componentsByType[c.type] == nil {
            componentsByType[c.type] = NSMutableDictionary()
        }
        let componentMap = componentsByType[c.type]!
        componentMap[e.id] = c
    }
    
    func getComponent(e:Entity, type:ComponentType) -> Component? {
        if let componentSet = componentsByType[type] as? NSMutableDictionary {
            return componentSet[e.id] as? Component
        }
        return nil
    }
    
    func getEntitiesWithComponent(type:ComponentType) -> Entity[] {
        var matches = Entity[]()
        if let components = componentsByType[type] as? NSMutableDictionary {
            for eid : AnyObject in components.allKeys {
                matches.append(Entity(id: eid as UInt))
            }
        }
        return matches
    }
    
}


