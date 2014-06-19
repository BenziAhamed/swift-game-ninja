//
//  EntityFactory.swift
//  gameninja
//
//  Created by Benzi on 19/06/14.
//  Copyright (c) 2014 Benzi Ahamed. All rights reserved.
//

import Foundation
import SpriteKit


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
        self.entityManager.addComponent(monster, c: renderComponent)
        
        var motionComponent = MotionComponent(destination: sprite.position.xAxis(), speed: 200)
        self.entityManager.addComponent(monster, c: motionComponent)
        
        
        let health = HealthComponent(currentHealth: 10, maxHealth: 10)
        self.entityManager.addComponent(monster, c: health)
        
        let collideWithPlayerRule = CollisionRule(hitCategory: PhysicsCategory.Player, damageGiven: 10, damageSustained:10)
        self.entityManager.addComponent(monster, c: CollisionComponent(collisionRules: [collideWithPlayerRule]))
        
        let deathDrama = DramaticDeath() {
            renderComponent.node.removeAllActions()
            renderComponent.node.physicsBody = nil
            renderComponent.node.runAction(self.scene.actionLibrary.death)
        }
        self.entityManager.addComponent(monster, c: deathDrama)
        
        self.entityManager.addComponent(monster, c: RenderHealthBarComponent())
        
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

        let collideWithMonsterRule = CollisionRule(hitCategory:PhysicsCategory.Monster, damageGiven:0, damageSustained:10)
        self.entityManager.addComponent(player, c: CollisionComponent(collisionRules: [collideWithMonsterRule]))

        
        self.entityManager.addComponent(player, c: renderComponent)
        self.entityManager.addComponent(player, c: health)
        self.entityManager.addComponent(player, c: RenderHealthBarComponent())
        return player
    }
    
    func createFire() -> Entity {
        
        let sprite = SKSpriteNode(imageNamed: "fire")
        scene.addChild(sprite)
        
        // physics
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody.dynamic = true
        sprite.physicsBody.categoryBitMask = PhysicsCategory.Projectile
        sprite.physicsBody.collisionBitMask = PhysicsCategory.None
        sprite.physicsBody.contactTestBitMask = PhysicsCategory.Monster
        
        let fire = self.entityManager.createEntity()
        let render = RenderComponent(node: sprite)
        let collideWithMonsterRule = CollisionRule(hitCategory: PhysicsCategory.Monster, damageGiven:5, damageSustained:1.0)
        let collision = CollisionComponent(collisionRules: [collideWithMonsterRule])
        
        let health = HealthComponent(currentHealth: 1.0, maxHealth: 1.0)
        let decay = HealthDecayComponent(factor: 0.1)
        let motion = MotionComponent(destination: render.node.position, speed:250)
        
        self.entityManager.addComponent(fire, c: render)
        self.entityManager.addComponent(fire, c: collision)
        self.entityManager.addComponent(fire, c: health)
        self.entityManager.addComponent(fire, c: decay)
        self.entityManager.addComponent(fire, c: motion)
        
        return fire
    }
}

