//
//  GameScene.swift
//  gameninja
//
//  Created by Benzi on 05/06/14.
//  Copyright (c) 2014 Benzi Ahamed. All rights reserved.
//

import SpriteKit
import Darwin

class GameScene: SKScene {
    
    let generator = ArcRandom()
    let actionLibrary = ActionLibrary()
    var lastSpawnTimeInterval:CFTimeInterval = 0
    var lastUpdateTimeInterval:CFTimeInterval = 0

    var player:Entity! = nil
    var entityFactory:EntityFactory! = nil
    var entityManager:EntityManager! = nil
    
    var motionSystem:MotionSystem! = nil
    var physicsSystem:PhysicsSystem! = nil
    var healthSystem:HealthSystem! = nil
    var renderSystem:RenderSystem! = nil
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        entityManager = EntityManager()
        
        motionSystem = MotionSystem(entityManager: entityManager)
        physicsSystem = PhysicsSystem(entityManager: entityManager)
        healthSystem = HealthSystem(entityManager: entityManager)
        renderSystem = RenderSystem(entityManager: entityManager)
        
        entityFactory = EntityFactory(entityManager: entityManager, scene: self)


        // add the player
        player = entityFactory.createPlayer()
        
        // setup physics
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = physicsSystem
    
    }
    
    
    func updateLastTimeUpate(time: CFTimeInterval){
        lastSpawnTimeInterval += time
        if lastSpawnTimeInterval > 1 {
            lastSpawnTimeInterval = 0
            spawnMonster()
        }
    }
    
    func spawnMonster() {
        // add a monster every 1 second
        let monster = entityFactory.createMonster()
        
        // modify target location based on players location
        let motion = entityManager.getComponent(monster, type: ComponentType.Motion) as MotionComponent
        let monsterNode = entityManager.getComponent(monster, type: ComponentType.Render) as RenderComponent
        if let playerNode = (entityManager.getComponent(player, type: ComponentType.Render) as? RenderComponent) {
            motion.destination = playerNode.node.position
        } else {
            motion.destination = monsterNode.node.position.xAxis()
        }
    }
    
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        // Handle time delta.
        // If we drop below 60fps, we still want everything to move the same distance.
        var timeSinceLast = currentTime - self.lastUpdateTimeInterval;
        self.lastUpdateTimeInterval = currentTime;
        if (timeSinceLast > 1) { // more than a second since last update
            timeSinceLast = 1.0 / 60.0;
            self.lastUpdateTimeInterval = currentTime;
        }
        updateLastTimeUpate(timeSinceLast)
        
        motionSystem.update(timeSinceLast)
        physicsSystem.update(timeSinceLast)
        healthSystem.update(timeSinceLast)
        renderSystem.update(timeSinceLast)
    }
    
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        let playerNode = self.entityManager.getComponent(player, type: ComponentType.Render) as? RenderComponent
        if playerNode {
            let touch:UITouch = touches.anyObject() as UITouch
            let fire = self.entityFactory.createFire()
            
            let fireNode = self.entityManager.getComponent(fire, type: ComponentType.Render) as RenderComponent
            
            let fireHealth = self.entityManager.getComponent(fire, type: ComponentType.Health) as HealthComponent
            let fireMotion = self.entityManager.getComponent(fire, type: ComponentType.Motion) as MotionComponent
            
            fireNode.node.position = playerNode!.node.position.translate(65, -40)
            let offset = touch.locationInNode(self).deltaTo(fireNode.node.position)
            let destination = fireNode.node.position.addTo( offset.normalize().multiplyBy(1000) )
            fireMotion.destination = destination
            
            playerNode!.node.runAction(actionLibrary.ninjaThrow)
            self.runAction(actionLibrary.weaponSound)
        }
    }
    
    
}
