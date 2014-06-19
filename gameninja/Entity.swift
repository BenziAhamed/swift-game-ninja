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
    var id:Int
    
    init(id:Int){
        self.id = id
    }
}


// MARK: Components ------------------------------------------

enum ComponentType {
    case Render
    case Health
    case Motion
}

class Component {
    var type:ComponentType
    init(type:ComponentType) { self.type = type }
}


class RenderComponent : Component {
    var node:SKSpriteNode
    
    init(node:SKSpriteNode){
        self.node = node
        super.init(type: ComponentType.Render)
    }
}

class MotionComponent : Component {
    
    var frame:CGRect
    var targetPosition:CGPoint
    var inMotion = false
    
    init(targetPosition:CGPoint, frame:CGRect) {
        self.targetPosition = targetPosition
        self.frame = frame
        super.init(type: ComponentType.Motion)
    }
    
}

class HealthComponent : Component {

    var isAlive:Bool
    var currentHealth:Double
    var maxHealth:Double
    
    init(currentHealth:Double, maxHealth:Double){
        self.currentHealth = currentHealth
        self.maxHealth = maxHealth
        self.isAlive = true
        super.init(type: ComponentType.Health)
    }
}

// MARK: EntityManager ------------------------------------------

class EntityManager {

    struct EntityId{
        static var nextId = 0
    }
    
    var entites:NSMutableArray
    var componentsByType:Dictionary<ComponentType,NSMutableDictionary>
    
    init(){
        entites = NSMutableArray()
        componentsByType = Dictionary<ComponentType,NSMutableDictionary>()
    }
    
    func createEntity() -> Entity {
        let e = Entity(id: EntityId.nextId++)
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
    
    func addComponentToEntity(e:Entity, c:Component){
        if componentsByType[c.type] == nil {
            componentsByType[c.type] = NSMutableDictionary()
        }
        let componentMap = componentsByType[c.type]!
        componentMap[e.id] = c
    }
    
    func getComponentForEntity(e:Entity, type:ComponentType) -> Component? {
        return (componentsByType[type]!)[e.id] as? Component
    }
    
    func getEntitiesHavingComponent(type:ComponentType) -> Entity[] {
        var matches = Entity[]()
        if let components = componentsByType[type] as? NSMutableDictionary {
            for eid : AnyObject in components.allKeys {
                matches.append(Entity(id: eid as Int))
            }
        }
        return matches
    }
    
}


// MARK: Systems ------------------------------------------

class System : NSObject {
    var entityManager:EntityManager
    
    init(entityManager:EntityManager) {
        self.entityManager = entityManager
    }
    
    func update(dt:Double) {}
}


class MotionSystem : System {
    override func update(dt: Double) {
        for e in self.entityManager.getEntitiesHavingComponent(ComponentType.Motion){
            let motion = self.entityManager.getComponentForEntity(e, type: ComponentType.Motion) as MotionComponent
            
            if !motion.inMotion {
                
                motion.inMotion = true
                
                // animate to target location and then remove
                let render = self.entityManager.getComponentForEntity(e, type: ComponentType.Render) as RenderComponent
                
                let move = SKAction.moveTo(
                    motion.targetPosition,
                    duration: (motion.frame.width / 480.0)
                )
                
                render.node.runAction(move)
            }
        }
    }
}



class PhysicsSystem : System, SKPhysicsContactDelegate {
    
    func didBeginContact(contact: SKPhysicsContact!) {
        // what to do?
        // remove the monster that hit the player
        
        var monsterNode: SKNode!
        switch (contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask) {
            case let(a,b) where (a==PhysicsCategory.Monster && b==PhysicsCategory.Player):
                monsterNode = contact.bodyA.node
            case let (a,b) where  (a==PhysicsCategory.Player && b==PhysicsCategory.Monster):
                monsterNode = contact.bodyB.node
            default:
                break
        }
        
        if monsterNode {
            for entity in self.entityManager.getEntitiesHavingComponent(ComponentType.Render){
                let monster = self.entityManager.getComponentForEntity(entity, type: ComponentType.Render) as RenderComponent
                
                if monster.node == monsterNode {
                    let health = self.entityManager.getComponentForEntity(entity, type: ComponentType.Health) as HealthComponent
                    
                    // if we hit, we die
                    health.currentHealth = 0
                    break
                }
                
            }
        }
    }
    
}

class HealthSystem : System {
    override func update(dt: Double) {
        // for all entites that have 0 health we remove them and kill them
        let entities = self.entityManager.getEntitiesHavingComponent(ComponentType.Health)
        for e in entities {
            let health = self.entityManager.getComponentForEntity(e, type: ComponentType.Health) as HealthComponent
            if (health.isAlive && health.currentHealth <= 0.0){
                health.isAlive = false
                if let render = self.entityManager.getComponentForEntity(e, type: ComponentType.Render) as? RenderComponent {
                    render.node.runAction(SKAction.removeFromParent())
                }
            }
        }
    }
}


// MARK: EntityFactory ------------------------------------------

class EntityFactory {
    var entityManager:EntityManager
    var scene:GameScene
    
    init(entityManager:EntityManager, scene:GameScene){
        self.entityManager = entityManager
        self.scene = scene
    }
    
    func createMonster() -> Entity {

        let monster = self.entityManager.createEntity()
        
        let (w,h) = (Double(scene.frame.width), Double(scene.frame.height))
        let (x,y) = (w + 256,Double(arc4random()) % h)
        let sprite = SKSpriteNode(imageNamed: "monster")
        sprite.size = CGSizeMake(128,128)
        sprite.position = CGPointMake(CGFloat(x), CGFloat(y))
        scene.addChild(sprite)
        
        // physics
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody.dynamic = true
        sprite.physicsBody.categoryBitMask = PhysicsCategory.Monster
        sprite.physicsBody.collisionBitMask = PhysicsCategory.None
        sprite.physicsBody.contactTestBitMask = PhysicsCategory.Projectile | PhysicsCategory.Player
        
        let renderComponent = RenderComponent(node: sprite)
        self.entityManager.addComponentToEntity(monster, c: renderComponent)
        
        var motionComponent = MotionComponent(targetPosition: sprite.position.xAxis(), frame: scene.frame)
        self.entityManager.addComponentToEntity(monster, c: motionComponent)

        
        let health = HealthComponent(currentHealth: 10, maxHealth: 10)
        self.entityManager.addComponentToEntity(monster, c: health)

        return monster
    }
    
    func createPlayer() -> Entity {
        let sprite = SKSpriteNode(imageNamed: "ninja")
        sprite.size = CGSizeMake(128,128)
        sprite.xScale = -1
        sprite.position = CGPointMake(sprite.size.width, scene.frame.height/2)
        scene.addChild(sprite)
        
        // physics
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody.dynamic = true
        sprite.physicsBody.categoryBitMask = PhysicsCategory.Player
        sprite.physicsBody.collisionBitMask = PhysicsCategory.None
        sprite.physicsBody.contactTestBitMask = PhysicsCategory.Monster
        
        let player = self.entityManager.createEntity()
        let renderComponent = RenderComponent(node: sprite)
        let health = HealthComponent(currentHealth: 100, maxHealth: 100)
        
        self.entityManager.addComponentToEntity(player, c: renderComponent)
        self.entityManager.addComponentToEntity(player, c: health)
        return player
    }
}

