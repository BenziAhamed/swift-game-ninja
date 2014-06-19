//
//  GameOverScene.swift
//  gameninja
//
//  Created by Benzi on 05/06/14.
//  Copyright (c) 2014 Benzi Ahamed. All rights reserved.
//

import SpriteKit

extension CGSize {
    func mid() -> CGPoint {
        return CGPointMake(self.width/2, self.height/2)
    }
}

class GameOverScene: SKScene {
    
    
    init(size: CGSize, won: Bool) {
        super.init(size: size)
        
//        self.backgroundColor = UIColor.blackColor()
//        
//        let message = "winning state \(won)"
//        
//        
//        let label = SKLabelNode(text: message)
//        label.fontSize = 40
//        label.fontColor = UIColor.whiteColor()
//        label.position = self.size.mid()
//        self.addChild(label)
//
//        
//        // display main game scene after 3 seconds
//        let sequence = [
//            SKAction.waitForDuration(3.0),
//            SKAction.runBlock(){
//            let transition = SKTransition.flipHorizontalWithDuration(0.5)
//            let gameScene = GameScene(size: self.size)
//            self.view.presentScene(gameScene, transition: transition)
//            }
//        ]
//        
//        self.runAction(SKAction.sequence(sequence))
    }
}
