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
    case HealthDecay
    case HealthBar
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
    
    var destination:CGPoint
    var speed:Double
    var inMotion = false
    
    init(destination:CGPoint, speed:Double) {
        self.destination = destination
        self.speed = speed
        super.init(type: ComponentType.Motion)
    }
    
}

class HealthComponent : Component {
    
    var isAlive:Bool
    var currentHealth:Double
    var maxHealth:Double
    
    var percent:Double { return currentHealth/maxHealth }
    
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

class HealthDecayComponent : Component {
    var factor:Double
    
    init(factor:Double){
        self.factor = factor
        super.init(type: ComponentType.HealthDecay)
    }
}

class RenderHealthBarComponent : Component {
    init() {
        super.init(type: ComponentType.HealthBar)
    }
}



