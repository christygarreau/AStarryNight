//
//  GameScene.swift
//  A Starry Night
//
//  Created by Christy Garreau on 10/1/19.
//  Copyright © 2019 Christy Garreau. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    var flashlight = false
    var hoodie = false
    var matches = false
    var axe = false
    var key = false
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        
    }
    
    func touchDown(atPoint pos : CGPoint) {
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
