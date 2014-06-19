//
//  Extensions.swift
//  gameninja
//
//  Created by Benzi on 19/06/14.
//  Copyright (c) 2014 Benzi Ahamed. All rights reserved.
//

import Foundation
import SpriteKit

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

extension CGPoint{
    func translate(x: CGFloat, _ y: CGFloat) -> CGPoint {
        return CGPointMake(self.x + x, self.y + y)
    }
    func translateX(x: CGFloat) -> CGPoint {
        return CGPointMake(self.x + x, self.y)
    }
    func xAxis() -> CGPoint {
        return CGPointMake(0, self.y)
    }
    func yAxis() -> CGPoint {
        return CGPointMake(self.x, 0)
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

