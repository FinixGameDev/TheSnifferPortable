//
//  SpriteKitHelper.swift
//  sniffdrop
//
//  Created by Diogo Rocha on 03/06/2023.
//

import Foundation
import SpriteKit

enum Layer : CGFloat {
    case background
    case foreground
    case player
    case collectible
    case ui
}

enum PhysicsCategory{
    static let none:        UInt32 = 0
    static let player:      UInt32 = 0b1
    static let collectible: UInt32 = 0b10
    static let foreground:  UInt32 = 0b100
}

extension SKNode {
    func setupScrollingView(imageNamed name: String, layer: Layer, blocks: Int, speed: TimeInterval){
        
        for i in 0..<blocks {
            let spriteNode = SKSpriteNode(imageNamed: name)
            
            spriteNode.anchorPoint = CGPoint.zero
            spriteNode.position = CGPoint(x: CGFloat(i) * spriteNode.size.width, y: 55)
            spriteNode.alpha = 0.225
            spriteNode.zPosition = layer.rawValue
            spriteNode.name = name
            spriteNode.endlessScroll(speed: speed)
            
            addChild(spriteNode)
        }
    }
}

extension SKSpriteNode
{
    func endlessScroll(speed: TimeInterval) {
        let moveAction = SKAction.move(by: CGVector(dx: -self.size.width, dy: 0), duration: speed)
        
        let resetAction = SKAction.move(by: CGVector(dx:self.size.width, dy: 0.0), duration: 0.0)
        
        let sequenceAction = SKAction.sequence([moveAction, resetAction])
        
        let repeatAction = SKAction.repeatForever(sequenceAction)
        
        self.run(repeatAction)
            
    }
    
    func loadTextures(atlas: String, prefix: String,
                      startsAt: Int, stopsAt: Int) -> [SKTexture] {
        var textureArray = [SKTexture] ()
        let textureAtlas = SKTextureAtlas(named: atlas)
        for i in startsAt...stopsAt {
            let textureName = "\(prefix)\(i)"
            let temp = textureAtlas.textureNamed(textureName)
            textureArray.append(temp)
        }
        
        return textureArray
    }
    
    func startAnimation(textures: [SKTexture], speed: Double, name: String,
                        count: Int, resize: Bool, restore: Bool) {
        if(action(forKey: name) == nil){
            let animation = SKAction.animate(with: textures, timePerFrame: speed,
                                            resize: resize, restore: restore)
            
            if count == 0 {
                let repeatAction = SKAction.repeatForever(animation)
                run(repeatAction, withKey: name)
            }
            else if count == 1 {
                run(animation, withKey: name)
            } else{
                let repeatAction = SKAction.repeat(animation, count: count)
                run(repeatAction, withKey: name)
            }
        }
    }
}

extension SKScene {
    func viewTop() -> CGFloat {
        return convertPoint(fromView: CGPoint(x: 0.0, y: 0)).y
    }
    
    func viewBottom() -> CGFloat {
        guard let view = view else {return 0.0}
        return convertPoint(fromView: CGPoint(x: 0.0,
                                            y: view.bounds.size.height)).y
    }
}
