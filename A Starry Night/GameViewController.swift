//
//  GameViewController.swift
//  A Starry Night
//
//  Created by Christy Garreau on 10/1/19.
//  Copyright © 2019 Christy Garreau. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

extension SKNode{
    
}

class GameViewController: UIViewController {
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var options: UIButton!
    
    var flashlight = false
    var hoodie = false
    var matches = false
    var axe = false
    var key = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let skView = self.view as!SKView? {
            if let scene = SKScene(fileNamed: "GameScene"){
                scene.scaleMode = .aspectFill
                skView.presentScene(scene)
                
                skView.showsNodeCount = true
                skView.ignoresSiblingOrder = true
                skView.showsFPS = true
            }
        }
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
