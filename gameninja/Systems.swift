//
//  Systems.swift
//  gameninja
//
//  Created by Benzi on 19/06/14.
//  Copyright (c) 2014 Benzi Ahamed. All rights reserved.
//

import Foundation
import SpriteKit


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
        for e in self.entityManager.getEntitiesWithComponent(ComponentType.Motion){
            let motion = self.entityManager.getComponent(e, type: ComponentType.Motion) as MotionComponent
            
            if !motion.inMotion {
                
                motion.inMotion = true
                
                // animate to target location
                let render = self.entityManager.getComponent(e, type: ComponentType.Render) as RenderComponent
                
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
    
    func findEntityWithNode(node:SKNode) -> Entity? {
        for entity in self.entityManager.getEntitiesWithComponent(ComponentType.Collision){
            if let render = self.entityManager.getComponent(entity, type: ComponentType.Render) as? RenderComponent {
                if render.node == node {
                    return entity
                }
            }
        }
        return nil
    }
    
    func applyCollision(hitter:Entity, hittee:Entity, hitteeCategory:UInt32){
        if let collision = self.entityManager.getComponent(hitter, type: ComponentType.Collision) as? CollisionComponent {
            let hitteeHealth = self.entityManager.getComponent(hittee, type: ComponentType.Health) as? HealthComponent
            let hitterHealth = self.entityManager.getComponent(hitter, type: ComponentType.Health) as? HealthComponent
            for rule in collision.rules {
                if rule.appliesTo(hitteeCategory){
                    if hitteeHealth {
                        hitteeHealth!.currentHealth -= rule.damageGiven
                    }
                    if hitterHealth {
                        hitterHealth!.currentHealth -= rule.damageSustained
                    }
                }
            }
            
        }
        
    }
    
    func didBeginContact(contact: SKPhysicsContact!) {
        
        let a = findEntityWithNode(contact.bodyA.node)
        let b = findEntityWithNode(contact.bodyB.node)
        
        if a && b {
            // a hits b
            applyCollision(a!, hittee: b!, hitteeCategory: contact.bodyB.categoryBitMask)
            // b hits a
            applyCollision(b!, hittee: a!, hitteeCategory: contact.bodyA.categoryBitMask)
        }
    }
}



class HealthSystem : System {
    override func update(dt: Double) {
        // for all entites that have 0 health we remove them and kill them
        let entities = self.entityManager.getEntitiesWithComponent(ComponentType.Health)
        for e in entities {
            let health = self.entityManager.getComponent(e, type: ComponentType.Health) as HealthComponent
            if (health.isAlive && health.currentHealth <= 0.0){
                health.isAlive = false
                
                // if this entity has a custom dramatic death
                if let death = self.entityManager.getComponent(e, type: ComponentType.SpecialDeath) as? DramaticDeath {
                    death.action()
                } else if let render = self.entityManager.getComponent(e, type: ComponentType.Render) as? RenderComponent {
                    render.node.removeAllActions()
                    self.entityManager.removeEntity(e)
                    render.node.runAction(SKAction.removeFromParent())
                }
            }
        }
    }
}