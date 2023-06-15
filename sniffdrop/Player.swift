//
//  Player.swift
//  sniffdrop
//
//  Created by Diogo Rocha on 03/06/2023.
//

import Foundation
import SpriteKit

enum PlayerAnimationType: String {
    case walk
    case die
}

enum PlayerEffectType: String {
    case Neutral
    case Angry
    case Sad
    case Happy
}

class Player : SKSpriteNode
{
    //MARK: - PROPERTIES
    var faceTextures : [SKTexture]?
    var face : SKSpriteNode?

    //MARK: - INIT
    init() {
        let texture = SKTexture(imageNamed: "DrogadoBase")
        
        super.init(texture: texture, color: .clear, size: texture.size())
        
        self.faceTextures = self.loadTextures(atlas: "faceAtlas", prefix: "face_", startsAt: 0, stopsAt: 4)
        
        let neutralFace = faceTextures![1]
        face = SKSpriteNode(texture: neutralFace, color: .clear, size: texture.size())
        self.addChild(face!)
        face!.position = CGPoint(x: self.position.x, y: self.position.y + 200)
        face!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.name = "player"
        self.setScale(0.25)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        self.zPosition = Layer.background.rawValue
        
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size, center: CGPoint(x: 0.0, y: self.size.height/2))
        self.physicsBody?.affectedByGravity = false
        
        self.physicsBody?.categoryBitMask = PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = PhysicsCategory.collectible
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - METHODS
    func setupConstraints(floor: CGFloat) {
        let range = SKRange(lowerLimit: floor, upperLimit: floor)
        let lockToPlatform = SKConstraint.positionY(range)
        
        constraints = [lockToPlatform]
    }
    
    func idle(){
        let rotate = SKAction.rotate(toAngle: 0, duration: 0.1)
        run(rotate)
        self.face!.run(rotate)
    }
    
    func die(){
        guard let faceTextures = faceTextures else {
            preconditionFailure("Could Not Find Textures")
        }
        
        idle()
        
        self.face?.texture = faceTextures[2]
        self.color = .white
    }
    
    func moveToPosition(pos: CGPoint, direction: String, speed: TimeInterval){
        removeAction(forKey: "move")
        
        let rotate : SKAction
        let rotatef: SKAction
        
        switch direction {
        case "L":
            rotate = SKAction.rotate(toAngle: -1/3.333, duration: 0.1)
            rotatef = SKAction.rotate(toAngle: 1/3.333, duration: 0.1)
        default:
            rotate = SKAction.rotate(toAngle: 1/3.333, duration: 0.1)
            rotatef = SKAction.rotate(toAngle: -1/3.333, duration: 0.1)
        }
        
        run(rotate)
        self.face!.run(rotatef)
        
        let moveAction = SKAction.move(to: pos, duration: speed)
        let moveSequence = SKAction.sequence([moveAction, SKAction.run {
            self.idle()}])
        run(moveSequence, withKey: "move")
    }
}
