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
    var walking: Bool
    var isChoosingTime: Bool
    var touchLocation: CGPoint
    private var PO1 = SKSpriteNode()
    private var PO1WalkingFrames: [SKTexture] = []
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        buildPO1()
        if walking{
            animatePO1()
        }
    }
    
    func buildPO1(){
        let PO1AnimatedAtlas = SKTextureAtlas(named: "PO1")
        var walkFrames: [SKTexture] = []
        
        let numImages = PO1AnimatedAtlas.textureNames.count
        for i in 1...numImages {
            let PO1TextureName = "PO1-A\(i)-Big"
            walkFrames.append(PO1AnimatedAtlas.textureNamed(PO1TextureName))
        }
        PO1WalkingFrames = walkFrames
        let firstFrameTexture = PO1WalkingFrames[0]
        PO1 = SKSpriteNode(texture: firstFrameTexture)
        PO1.size = CGSize(width:PO1.size.width/3,height:PO1.size.height/3)
        PO1.position = CGPoint(x: frame.midX, y: frame.midY)
        //PO1.decreaseSize(0.5)
        addChild(PO1)
    }
    
    func animatePO1() {
        PO1.run(SKAction.repeatForever(
            SKAction.animate(with: PO1WalkingFrames,timePerFrame: 0.1,resize: false,restore: true)),withKey:"walkingInPlacePO1")
    }
    
    func touchDown(atPoint pos : CGPoint) {
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isChoosingTime{
            for touch in touches{
                touchLocation = touch.location(in: self)
            }
        }
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
