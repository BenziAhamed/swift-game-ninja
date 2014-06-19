//
//  Categories.swift
//  gameninja
//
//  Created by Benzi on 19/06/14.
//  Copyright (c) 2014 Benzi Ahamed. All rights reserved.
//

import Foundation
import SpriteKit


// MARK: Components ------------------------------------------

enum ComponentType {
    case Render
    case Health
    case Motion
    case Collision
    case SpecialDeath
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


class CollisionRule {
    var hitCategory:UInt32
    var damageGiven:Double
    var damageSustained:Double
    
    init(hitCategory:UInt32, damageGiven:Double, damageSustained:Double){
        self.hitCategory = hitCategory
        self.damageGiven = damageGiven
        self.damageSustained = damageSustained
    }
    
    func appliesTo(category:UInt32) -> Bool {
        return (hitCategory & category) > 0
    }
}

class CollisionComponent : Component {
    
    var rules:CollisionRule[]
    
    init(collisionRules:CollisionRule[]) {
        self.rules = collisionRules
        super.init(type: ComponentType.Collision)
    }
}



class DramaticDeath : Component {

    var action:()->()
    
    init(action:()->()) {
        self.action = action
        super.init(type: ComponentType.SpecialDeath)
    }
}




