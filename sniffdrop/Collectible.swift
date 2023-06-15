//
//  Collectible.swift
//  sniffdrop
//
//  Created by Diogo Rocha on 04/06/2023.
//

import Foundation
import SpriteKit

enum CollectibleType: Int {
    case none
    case red
    case blue
    case yellow
    case gray
}

class Collectible: SKSpriteNode{
    //MARK: - PROPERTIES
    var collectibleType: CollectibleType = .none
    var paint: SKSpriteNode?
    
    private let playCollectSound = SKAction.playSoundFileNamed("sniff.wav", waitForCompletion: false)
    
    private let playMissSound = SKAction.playSoundFileNamed("Metalpipe.mp3", waitForCompletion: false)
    
    //MARK: - INIT
    init(collectibleType: CollectibleType) {
        var texture:  SKTexture!
        texture = SKTexture(imageNamed: "Bucket")
        super.init(texture: texture, color: .clear, size: texture.size())
        
        self.name = "co_\(collectibleType)"
        self.setScale(0.175)
        self.anchorPoint = CGPoint(x: 0.5, y: 1)
        self.zPosition = Layer.collectible.rawValue
        self.collectibleType = collectibleType
        
        let color: SKColor

        
        switch self.collectibleType {
        case .red:
            color = .red
        case .blue:
            color = .blue
        case .yellow:
            color = .yellow
        case .gray:
            color = .gray
        case.none:
            color = .white
        }
        
        var paintTexture: SKTexture!
        paintTexture = SKTexture(imageNamed: "BucketPaint")
        paint = SKSpriteNode(texture: paintTexture, color: color, size: texture.size())
        paint?.anchorPoint = self.anchorPoint
        paint?.colorBlendFactor = 0.7
        paint?.zPosition = Layer.collectible.rawValue
        
        addChild(paint!)
        
        let particles = SKEmitterNode(fileNamed: "PaintFlow.sks")
        particles?.name = "particles"
        particles?.position = CGPoint(x: self.position.x, y: self.position.y - 75)
        particles?.particleColorSequence = nil
        particles?.particleColorBlendFactor = 0.7
        particles?.particleColor = color
        particles?.zPosition = Layer.collectible.rawValue
        
        addChild(particles!)
        
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size, center: CGPoint(x: 0.0, y: -self.size.height/2))
        self.physicsBody?.affectedByGravity = false
        
        self.physicsBody?.categoryBitMask = PhysicsCategory.collectible
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.foreground
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
    }

    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not been implemented")
        
    }
    
    //MARK: - FUNCTIONS
    func drop(dropSpeed: TimeInterval, floorLevel: CGFloat){
        let pos = CGPoint(x: position.x, y: floorLevel)
        
        let scaleX = SKAction.scaleX(to: 0.2, duration: 0.25)
        let scaleY = SKAction.scaleY(to: 0.2, duration: 0.25)
        let scale = SKAction.group([scaleX, scaleY])
        
        let appear = SKAction.fadeAlpha(to: 1.0, duration: 0.25)
        let moveAction = SKAction.move(to: pos, duration: dropSpeed)
        let actionSequence = SKAction.sequence([appear, scale, moveAction])
        
        self.scale(to: CGSize(width: 0.25, height: 1.0))
        self.run(actionSequence, withKey: "drop")
    }
    
    //Handle Contacts
    func collected() {
        let removeFromParent = SKAction.removeFromParent()
        let actionGroup = SKAction.group([playCollectSound, removeFromParent])
        self.run(actionGroup)
    }
    
    func missed(){
        let move = SKAction.move(by: CGVector(dx: 0, dy: -size.height/1.75), duration: 0.0)
        let splatX = SKAction.scaleX(to: 1.5 * 0.175, duration: 0.0)
        let splatY = SKAction.scaleY(to: 0.5 * 0.175, duration: 0.0)
        
        let particles = self.childNode(withName: "particles")
        let label = self.childNode(withName: "dropNumber")
        
        particles?.removeFromParent()
        label?.removeFromParent()
        
        let actionGroup = SKAction.group([playMissSound, move, splatX, splatY])
        self.run(actionGroup)
    }
}
