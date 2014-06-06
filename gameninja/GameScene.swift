//
//  GameScene.swift
//  gameninja
//
//  Created by Benzi on 05/06/14.
//  Copyright (c) 2014 Benzi Ahamed. All rights reserved.
//

import SpriteKit
import Darwin



struct PhysicsCategory {
    static let None           = (0)        as UInt32
    static let Player         = (1 << 0)   as UInt32
    static let Monster        = (1 << 1)   as UInt32
    static let Projectile     = (1 << 2)   as UInt32
    static let Robot          = (1 << 3)   as UInt32
}

protocol RandomNumberGenerator {
    func random() -> Double
}

class ArcRandom : RandomNumberGenerator{
    func random() -> Double {
        let r = arc4random() % 100
        return Double(Double(r)/100.0)
    }
}


class ActionLibrary {
    
    let weaponSound = SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false)
    
    let moveBack = SKAction.moveByX(150, y: 0, duration: 0.3)
    let rotate = SKAction.rotateByAngle(-M_PI_2, duration: 0.3)
    let redtint = SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 0.5, duration: 0.3)
    
    let fadeout = SKAction.fadeAlphaTo(0, duration: 1.0)
    let scale = SKAction.scaleBy(0.1, duration: 1.0)
    
    let remove = SKAction.removeFromParent()
    
    var rotate_tint: SKAction!
    var fade_scale: SKAction!
    var death: SKAction!
    
    // setup our hero
    var ninja1 = SKTexture(imageNamed: "ninja_throw")
    var ninja2 = SKTexture(imageNamed: "ninja")
    var ninjaThrow: SKAction!
    

    init(){
        rotate_tint = SKAction.group([moveBack, rotate, redtint])
        fade_scale = SKAction.group([fadeout, scale])
        death = SKAction.sequence([rotate_tint, fade_scale, remove])
        ninjaThrow = SKAction.animateWithTextures([ninja1, ninja2], timePerFrame: 0.2)
    }
}

extension SKPhysicsBody{
    func ofCategory(category:UInt32) -> Bool {
        return (self.categoryBitMask & category != 0)
    }
}

extension CGPoint{
    func translate(x: CGFloat, _ y: CGFloat) -> CGPoint {
        return CGPointMake(self.x + x, self.y + y)
    }
    func translateX(x: CGFloat) -> CGPoint {
        return CGPointMake(self.x + x, self.y)
    }
    func translateY(y: CGFloat) -> CGPoint {
        return CGPointMake(self.x, self.y + y)
    }
    func addTo(a: CGPoint) -> CGPoint{
        return CGPointMake(self.x+a.x, self.y+a.y)
    }
    func deltaTo(a: CGPoint) -> CGPoint{
        return CGPointMake(self.x-a.x, self.y-a.y)
    }
    func multiplyBy(value:CGFloat) -> CGPoint{
        return CGPointMake(self.x*value, self.y*value)
    }
    func length() -> CGFloat {
        return CGFloat(sqrt(CDouble(
                self.x*self.x + self.y*self.y
            )))
    }
    func normalize() -> CGPoint {
        let l = self.length()
        return CGPointMake(self.x / l, self.y / l)
    }
}

extension CGSize {
    func reduceBy(amount:CGFloat) -> CGSize {
        return CGSizeMake(self.width * amount, self.height * amount)
    }
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let generator = ArcRandom()
    let actionLibrary = ActionLibrary()
    var lastSpawnTimeInterval:CFTimeInterval = 0
    var lastUpdateTimeInterval:CFTimeInterval = 0
    var player:SKSpriteNode? = nil
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        self.backgroundColor = UIColor.whiteColor()

        // add the player
        let player = SKSpriteNode(imageNamed: "ninja")
        player.size = CGSizeMake(128,128)
        player.xScale = -1
        player.position = CGPointMake(player.size.width, self.frame.height/2)
        
        self.player = player
        self.addChild(player)
        
        
        // setup physics
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = self
    }
    
    
    func addMonster() {
        
        let typeMonster = generator.random()<0.7
        let monster = SKSpriteNode(imageNamed:  typeMonster ? "monster" : "robot")
        monster.size = CGSizeMake(128,128)
        
        // initial position 
        // towards right edge of player
        let (w,h) = (Double(self.frame.width), Double(self.frame.height))
        let (x,y) =
        (
            w + 256,
            Double(arc4random()) % h
        )
        monster.position = CGPointMake(CGFloat(x), CGFloat(y))
        
        let actionMonsterMove = SKAction.moveTo(
            player!.position,
            duration: self.frame.width / (generator.random()*50 + 150)
        )
        let actionRobotMove = SKAction.moveTo(
            monster.position.translateX(-100),
            duration: self.frame.width / (generator.random()*50 + 150)
        )

        let actionLose = SKAction.runBlock(){
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view.presentScene(gameOverScene, transition: reveal)
            }
        
        //monster.runAction(SKAction.sequence([actionMove, actionLose, actionRemove]))
        if typeMonster { monster.runAction(SKAction.sequence([actionMonsterMove, actionLibrary.remove])) }
        else { monster.runAction(SKAction.sequence([actionRobotMove, actionLibrary.remove])) }
        
        // monster physics
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size.reduceBy(0.8))
        monster.physicsBody.dynamic = true
        monster.physicsBody.categoryBitMask = PhysicsCategory.Monster
        monster.physicsBody.contactTestBitMask = PhysicsCategory.Projectile
        monster.physicsBody.collisionBitMask = PhysicsCategory.None
        
        self.addChild(monster)
    }
    
    
    func updateLastTimeUpate(time: CFTimeInterval){
        lastSpawnTimeInterval += time
        if lastSpawnTimeInterval > 1 {
            lastSpawnTimeInterval = 0
            addMonster()
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
    }
    
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        
        self.runAction(actionLibrary.weaponSound)
        player!.runAction(actionLibrary.ninjaThrow)
        
        let touch:UITouch = touches.anyObject() as UITouch
        let projectile = SKSpriteNode(imageNamed: "fire")
        let offset = touch.locationInNode(self).deltaTo(self.player!.position)
        
        projectile.position = self.player!.position.translate(65, -40)
        let destination = projectile.position.addTo( offset.normalize().multiplyBy(2000) )
        let motion = SKAction.moveTo(destination, duration: 1.0)
        
        projectile.physicsBody = SKPhysicsBody(rectangleOfSize: projectile.size)
        projectile.physicsBody.dynamic = true
        projectile.physicsBody.categoryBitMask = PhysicsCategory.Projectile;
        projectile.physicsBody.contactTestBitMask = PhysicsCategory.Monster;
        projectile.physicsBody.collisionBitMask = PhysicsCategory.None;
        projectile.physicsBody.usesPreciseCollisionDetection = true;

        
        self.addChild(projectile)
        projectile.runAction(SKAction.sequence([motion, actionLibrary.remove]))
    }
    
    
    func didBeginContact(contact: SKPhysicsContact!){
        
        var monster: SKNode!
        var projectile: SKNode!
        
        switch (contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask){
        case let(a,b) where (a==PhysicsCategory.Projectile && b==PhysicsCategory.Monster):
            monster = contact.bodyB.node
            projectile = contact.bodyA.node
        case let (a,b) where  (a==PhysicsCategory.Monster && b==PhysicsCategory.Projectile):
            monster = contact.bodyA.node
            projectile = contact.bodyB.node
        default:
                break
        }
        
        projectile.removeFromParent()
        
        monster.removeAllActions()
        monster.physicsBody.categoryBitMask = PhysicsCategory.None
        monster.physicsBody.contactTestBitMask = PhysicsCategory.None
        monster.runAction(actionLibrary.death)
        
    }
}
