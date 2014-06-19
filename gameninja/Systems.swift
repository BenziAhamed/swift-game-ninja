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
                let move = SKAction.moveTo(motion.destination, duration:1000/motion.speed)
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
    
    var lastDecayTimeInterval:CFTimeInterval = 0
    
    func updateAlive(){
        // for all entites that have 0 health we remove them and kill them
        let entities = self.entityManager.getEntitiesWithComponent(ComponentType.Health)
        for e in entities {
            let health = self.entityManager.getComponent(e, type: ComponentType.Health) as HealthComponent
            if (health.isAlive && health.currentHealth <= 0.0){
                health.isAlive = false
            }
        }
    }
    
    func decayHealth(dt:Double){
        // decay health every 0.5 seconds
        lastDecayTimeInterval += dt
        if lastDecayTimeInterval > 0.5 {
            lastDecayTimeInterval = 0
            let entities = self.entityManager.getEntitiesWithComponent(ComponentType.HealthDecay)
            for e in entities {
                let decay = self.entityManager.getComponent(e, type: ComponentType.HealthDecay) as HealthDecayComponent
                let health = self.entityManager.getComponent(e, type: ComponentType.Health) as HealthComponent
                health.currentHealth -= decay.factor
            }
        }
    }
    
    override func update(dt: Double) {
        decayHealth(dt)
        updateAlive()
    }
}


class RenderSystem : System {
    
    override func update(dt: Double) {
        
        // for all entities that has a health bar component, draw a health bar
        let entities = self.entityManager.getEntitiesWithComponent(ComponentType.HealthBar)
        for e in entities {
            let render = self.entityManager.getComponent(e, type: ComponentType.Render) as RenderComponent
            let health = self.entityManager.getComponent(e, type: ComponentType.Health) as HealthComponent
            
            render.node.removeAllChildren()
            
            let healthBarWidth = render.node.size.width * 0.8
            let healthBarHeight = 10.0
            let widthOfHealth = (healthBarWidth - 2.0) * health.currentHealth / health.maxHealth
            
            let healthBarColor = UIColor(red: 1.0 - health.percent, green: health.percent, blue: 0, alpha: 1.0)
            
            //create the outline for the health bar
            let outlineRectSize = CGSizeMake(healthBarWidth-1.0,healthBarHeight-1.0);
            UIGraphicsBeginImageContextWithOptions(outlineRectSize, false, 0.0)
            let healthBarContext = UIGraphicsGetCurrentContext()
            //Drawing the outline for the health bar
            
            let spriteOutlineRect = CGRectMake(0.0, 0.0, healthBarWidth-1.0, healthBarHeight-1.0)
            CGContextSetStrokeColorWithColor(healthBarContext, UIColor.whiteColor()!.CGColor!)
            CGContextSetLineWidth(healthBarContext, 1.0)
            CGContextAddRect(healthBarContext, spriteOutlineRect)
            CGContextStrokePath(healthBarContext)

            //Fill the health bar with a filled rectangle
            let spriteFillRect = CGRectMake(0.5, 0.5, widthOfHealth, outlineRectSize.height-1.0)
            CGContextSetFillColorWithColor(healthBarContext, healthBarColor.CGColor!)
            CGContextSetStrokeColorWithColor(healthBarContext, UIColor.blackColor()!.CGColor!);
            CGContextSetLineWidth(healthBarContext, 1.0)
            CGContextFillRect(healthBarContext, spriteFillRect)
            
            //Generate a sprite image of the two pieces for display
            let spriteImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let texture = SKTexture(image: spriteImage)
            texture.filteringMode = SKTextureFilteringMode.Linear
            let healthNode = SKSpriteNode(texture: texture)
            healthNode.position = CGPointMake(0, render.node.size.height/2 + 20)
            healthNode.anchorPoint = CGPointMake(0.5, 0.5)
            
            render.node.addChild(healthNode)
        }
        
        
        // for all dead nodes, update the tree
        let entities2 = self.entityManager.getEntitiesWithComponent(ComponentType.Health)
        for e in entities2 {
            let health = self.entityManager.getComponent(e, type: ComponentType.Health) as HealthComponent
            if !health.isAlive {
                // if this entity has a custom dramatic death
                if let death = self.entityManager.getComponent(e, type: ComponentType.SpecialDeath) as? DramaticDeath {
                    death.action()
                } else if let render = self.entityManager.getComponent(e, type: ComponentType.Render) as? RenderComponent {
                    render.node.removeAllActions()
                    render.node.runAction(SKAction.removeFromParent())
                }
                self.entityManager.removeEntity(e)
            }
        }
    }

}