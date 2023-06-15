//
//  GameViewController.swift
//  sniffdrop
//
//  Created by Diogo Rocha on 27/02/2023.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Create the view
        if let view = self.view as! SKView?
        {
            //Crete the scene
            let scene = GameScene(size: view.bounds.size)
            
            //Set the scale mode to scale to fill the view window
            scene.scaleMode = .aspectFill
            
            //Set the background color
            scene.backgroundColor = UIColor(red: 105/255,
                                            green: 157/255,
                                            blue: 181/255,
                                            alpha: 1.0)
            
            //Present the scene
            view.presentScene(scene)
            
            //Set view options
            view.ignoresSiblingOrder = false
            view.showsPhysics = false
            view.showsFPS = false
            view.showsNodeCount = false
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
}
