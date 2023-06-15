//
//  GameScene.swift
//  sniffdrop
//
//  Created by Diogo Rocha on 27/02/2023.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {
    
    let player = Player()
    let playerSpeed : CGFloat = 1.5
    
    var movingPlayer = false
    var lastPosition: CGPoint?
    
    var level: Int = 1 {
        didSet {
            levelLabel.text = "Round: \(level)"
        }
    }
    var score: Int = 0 {
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var numberOfDrops: Int = 10
    
    var dropSpeed: CGFloat = 1.0
    var minDropSpeed: CGFloat = 0.12
    var maxDropSpeed: CGFloat = 1.0
    
    var dropsExpected = 10
    var dropsCollected = 0
    
    var prevDropLocation: CGFloat = 0.0
    
    var scoreLabel: SKLabelNode = SKLabelNode()
    var levelLabel: SKLabelNode = SKLabelNode()
    
    var musicAudioNode = SKAudioNode(fileNamed: "normal.wav")
    
    let ambientNoise = SKAudioNode(fileNamed: "ambientNoise.wav")
    
    var gameInProgress = false
    
    override func didMove(to view: SKView) {
        
        audioEngine.mainMixerNode.outputVolume = 0.0
        
        musicAudioNode.autoplayLooped = true
        musicAudioNode.isPositional = false
        
        addChild(musicAudioNode)
        
        musicAudioNode.run(SKAction.changeVolume(to: 0.0, duration: 0.0))
        
        run(SKAction.wait(forDuration: 1.0), completion: {[unowned self] in
            self.audioEngine.mainMixerNode.outputVolume = 1.0
            self.musicAudioNode.run(SKAction.changeVolume(to: 0.75, duration: 2.0))
        })
        
        run(SKAction.wait(forDuration: 1.5), completion: {[unowned self] in
            self.ambientNoise.autoplayLooped = true
            self.ambientNoise.run(SKAction.changeVolume(to: 0.3, duration: 0.0))
            self.addChild(self.ambientNoise)
        })
        
        physicsWorld.contactDelegate = self
        
        let background = SKSpriteNode(imageNamed: "Sky")
        background.position = .zero
        background.anchorPoint = .zero
        background.size = view.bounds.size
        addChild(background)
        background.zPosition = Layer.background.rawValue
        background.name = "background"
    
        
        let foreground = SKSpriteNode(color: UIColor.white, size: CGSize(width: view.bounds.size.width, height: view.bounds.size.height * 0.15) )
        foreground.anchorPoint = .zero
        foreground.position = .zero
        foreground.physicsBody = SKPhysicsBody(edgeLoopFrom: foreground.frame)
        foreground.physicsBody?.affectedByGravity = false
        addChild(foreground)
        foreground.zPosition = Layer.foreground.rawValue
        foreground.physicsBody?.categoryBitMask = PhysicsCategory.foreground
        foreground.physicsBody?.contactTestBitMask = PhysicsCategory.collectible
        foreground.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        setupSkyScroll()
        
        let banner = SKLabelNode()
        banner.text = "TheSniffer"
        banner.fontName = "ComicNeue-Bold"
        banner.fontSize = 50
        banner.zPosition = Layer.ui.rawValue
        banner.position = CGPoint(x: frame.midX, y: viewTop() - 50)
        addChild(banner)
        
        player.position = CGPoint(x: size.width/2, y: foreground.frame.maxY)
        addChild(player)
        player.setupConstraints(floor: foreground.frame.maxY)
        
        setupLabels()
        showMessage("Tap to start game")
    }

    
    func setupLabels() {
        /*SCORE LABELS*/
        scoreLabel.name = "score"
        scoreLabel.fontName = "Roboto-Regular"
        scoreLabel.fontColor = .white
        scoreLabel.fontSize = 35.0
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = Layer.ui.rawValue
        scoreLabel.position = CGPoint(x: frame.maxX - 50, y: viewTop() - 50)
        
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
        
        levelLabel.name = "level"
        levelLabel.fontName = "Roboto-Regular"
        levelLabel.fontSize = 35.0
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.verticalAlignmentMode = .center
        levelLabel.zPosition = Layer.ui.rawValue
        levelLabel.position = CGPoint(x: frame.minY + 50, y: viewTop() - 50)
        
        levelLabel.text = "Round: \(level)"
        addChild(levelLabel)
    }
    
    func showMessage(_ message: String){
        let messageLabel = SKLabelNode()
        messageLabel.name = "message"
        messageLabel.position = CGPoint(x: frame.midX, y: player.frame.maxY + 50)
        messageLabel.zPosition = Layer.ui.rawValue
        
        messageLabel.numberOfLines = 2
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor:   SKColor.white,
            .backgroundColor: UIColor.clear,
            .font: UIFont(name: "ComicNeue-Bold", size: 45.0)!,
            .paragraphStyle: paragraph
        ]
        
        messageLabel.attributedText = NSAttributedString(string: message,
                                                         attributes: attributes)
        
        messageLabel.run(SKAction.fadeIn(withDuration: 0.25))
        addChild(messageLabel)
    }
    
    func hideMessage(){
        if let messageLabel = childNode(withName: "//message") as? SKLabelNode {
            messageLabel.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.25), SKAction.removeFromParent()]))
        }
    }
    
    //MARK: - TOUCH HANDLING
    
    func touchDown(atPoint pos: CGPoint){
        
        if gameInProgress == false {
            spawnMultipleBuckets()
            return
        }
        
        removeAction(forKey: "move")
        
        let touchedNode = atPoint(pos)
        if touchedNode.name == "player" {
            movingPlayer = true
        }else{
            let distance = hypot(pos.x-player.position.x, pos.y-player.position.y)
            let calculatedSpeed = TimeInterval(distance / playerSpeed) / 255
            
            if  pos.x < player.position.x {
                player.moveToPosition(pos: pos, direction: "L", speed: calculatedSpeed)
            } else {
                player.moveToPosition(pos: pos, direction: "R", speed: calculatedSpeed)
            }
        }
    }
    
    func touchMoved(toPoint pos: CGPoint){
        if movingPlayer == true{
            removeAction(forKey: "move")
            let newPos = CGPoint(x: pos.x, y: player.position.y)
            player.position = newPos
            
            let rotate: SKAction
            let rotatef: SKAction
            
            let recordedPosition = lastPosition ?? player.position
            if recordedPosition.x > newPos.x{
                rotate = SKAction.rotate(toAngle: -1/3.333, duration: 0.1)
                rotatef = SKAction.rotate(toAngle: 1/3.333, duration: 0.1)
            } else {
                rotate = SKAction.rotate(toAngle: 1/3.333, duration: 0.1)
                rotatef = SKAction.rotate(toAngle: -1/3.333, duration: 0.1)
            }
            
            player.run(rotate)
            player.face!.run(rotatef)
            
            lastPosition = newPos
        }
    }
    
    func touchUp(atPoint pos: CGPoint){
        if movingPlayer == true {
            player.idle()}
        
        movingPlayer = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchDown(atPoint: t.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchMoved(toPoint: t.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {self.touchUp(atPoint: t.location(in: self))}
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {self.touchUp(atPoint: t.location(in: self))}
    }
    //MARK: - GAME FUNCTIONS
    
    func setupSkyScroll() {
        let skyScroll = SKNode()
        skyScroll.name = "skyScroll"
        skyScroll.zPosition = Layer.background.rawValue
        skyScroll.position = CGPoint(x: 0.0, y: -60)
        
        skyScroll.setupScrollingView(imageNamed: "sky", layer: Layer.background, blocks: 4, speed: 75.0)
        
        addChild(skyScroll)
    }
    
    func spawnBucket() {
        let typeRange = 0...4
        let collectible = Collectible(collectibleType: CollectibleType(rawValue: Int.random(in: typeRange))!)
        
        let margin = collectible.size.width * 2
        let dropRange = SKRange(lowerLimit: frame.minX + margin, upperLimit: frame.maxX - margin)
        
        var randomX = CGFloat.random(in: dropRange.lowerLimit...dropRange.upperLimit)
        
        let randomModifier = SKRange(lowerLimit: 50 + CGFloat(level),
                                     upperLimit: 60 * CGFloat(level))
        
        var modifier = CGFloat.random(in:
                                        randomModifier.lowerLimit...randomModifier.upperLimit)
        if modifier > 400 {modifier = 400}
        
        if prevDropLocation == 0.0 {
            prevDropLocation = randomX
        }
        
        if prevDropLocation < randomX {
            randomX = prevDropLocation + modifier
        } else {
            randomX = prevDropLocation - modifier
        }
        
        if randomX <= (frame.minX + margin) {
            randomX = frame.minX + margin
        } else if randomX >= (frame.maxX - margin){
            randomX = frame.maxX - margin
        }
        
        prevDropLocation = randomX
        
        let xLabel = SKLabelNode()
        xLabel.name = "dropNumber"
        xLabel.fontName = "ComicNeue-Bold"
        xLabel.fontColor = UIColor.white
        xLabel.fontSize = 100.0
        xLabel.text = "\(numberOfDrops)"
        xLabel.position = CGPoint(x: 0, y: 25)
        xLabel.zPosition = Layer.ui.rawValue
        collectible.addChild(xLabel)
        numberOfDrops -= 1
        
        collectible.position = CGPoint(x: randomX,
                                       y: player.position.y * 7)
        
        addChild(collectible)
        
        collectible.drop(dropSpeed: TimeInterval(1.0), floorLevel: player.frame.minY)
    }
    
    func checkForRemainingBuckets(){
        if dropsCollected == dropsExpected{
            nextLevel()
        }
    }
    
    func nextLevel(){
        showMessage("GET READY!")
        
        let wait = SKAction.wait(forDuration: 2.25)
        run(wait, completion: {[unowned self] in self.level+=1
            self.spawnMultipleBuckets()
        })
    }
    
    func spawnMultipleBuckets() {
        
        if gameInProgress == false {
            score = 0
            level = 1
            
            player.face?.texture = player.faceTextures?[1]
        }
        
        switch level{
        case 1...5:
            numberOfDrops = level * 10
        case 6:
            numberOfDrops = 75
        case 7:
            numberOfDrops = 100
        case 8:
            numberOfDrops = 150
        default:
            numberOfDrops = 150
        }
        
        dropsCollected = 0
        dropsExpected = numberOfDrops
        
        dropSpeed = 1 / (CGFloat(level) + (CGFloat(level) / CGFloat(numberOfDrops)))
        
        if dropSpeed < minDropSpeed {
            dropSpeed = minDropSpeed
        } else if dropSpeed > maxDropSpeed {
            dropSpeed = maxDropSpeed
        }
                         
        
        let wait = SKAction.wait(forDuration: TimeInterval(dropSpeed))
        let spawn = SKAction.run {
            [unowned self] in self.spawnBucket()
        }
        let sequence = SKAction.sequence([wait, spawn])
        let repeatAction = SKAction.repeat(sequence, count: numberOfDrops)
        
        run(repeatAction, withKey: "buckets")
        gameInProgress = true
        hideMessage()
    }
    
    func gameOver() {
        
        showMessage("GAME OVER\nTap to try again")
        
        player.die()
        resetPlayerPosition()
        popRemainingBuckets()
        
        removeAction(forKey: "buckets")
        
        enumerateChildNodes(withName: "//co_*") {
            (node, stop) in
            
            node.removeAction(forKey: "drop")
            node.physicsBody = nil
        }
        
        gameInProgress = false
        
    }
    
    func resetPlayerPosition() {
        let resetPoint = CGPoint(x: frame.midX, y: player.position.y)
        let distance = hypot(resetPoint.x - player.position.x, 0)
        let calculatedSpeed = TimeInterval(distance / (playerSpeed * 2)) / 255
        
        if player.position.x > frame.midX {
            player.moveToPosition(pos: resetPoint, direction: "L", speed: calculatedSpeed)
        }else {
            player.moveToPosition(pos: resetPoint, direction: "R", speed: calculatedSpeed)
        }
    }
    
    func popRemainingBuckets() {
        var i = 0
        enumerateChildNodes(withName: "//co_*"){
            (node, stop) in
            
            let initialWait = SKAction.wait(forDuration: 1.0)
            let wait = SKAction.wait(forDuration: TimeInterval(0.15 * CGFloat(i)))
            
            let removeFromParent = SKAction.removeFromParent()
            let actionSequence = SKAction.sequence([initialWait, wait, removeFromParent])
            
            node.run(actionSequence)
            i += 1
        }
    }
}

//MARK: - COLLISION DETECTION
extension GameScene: SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact){
        let collision = contact.bodyA.categoryBitMask |
                        contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.player | PhysicsCategory.collectible{
            print("player hit collectible")
            
            let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ? contact.bodyA.node: contact.bodyB.node
            
            if let sprite = body as? Collectible{
                sprite.collected()
                score += level
                dropsCollected += 1
                
                //Set Sniffing animation
                player.texture = SKTexture(imageNamed: "DrogadoSniffing")
                player.face?.colorBlendFactor = 1.0
                player.face?.color = .clear
                
                run(SKAction.wait(forDuration: 0.2), completion: {
                    self.player.texture = SKTexture(imageNamed: "DrogadoBase")
                    self.player.face?.colorBlendFactor = 0.0
                    self.player.face?.color = .white
                })
                
                checkForRemainingBuckets()
                
                let sniff = SKLabelNode(fontNamed: "Roboto-Regular")
                sniff.name = "sniff"
                sniff.alpha = 0.0
                sniff.fontSize = 22.0
                sniff.text = "sniff"
                sniff.horizontalAlignmentMode = .center
                sniff.verticalAlignmentMode = .bottom
                sniff.position = CGPoint(x: player.position.x, y: player.frame.maxY + 25)
                sniff.zRotation = CGFloat.random(in: -0.15...0.15)
                addChild(sniff)
                
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
                let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.45)
                let moveUp = SKAction.move(by: CGVector(dx: 0.0, dy: 45), duration: 0.45)
                let groupAction = SKAction.group([fadeOut, moveUp])
                let removeFromParent = SKAction.removeFromParent()
                let sniffAction = SKAction.sequence([fadeIn, groupAction, removeFromParent])
                sniff.run(sniffAction)
            }
        }
        
        if collision == PhysicsCategory.foreground | PhysicsCategory.collectible{
            print("collectible hit ground")
            
            let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ? contact.bodyA.node: contact.bodyB.node
            
            if let sprite = body as? Collectible{
                sprite.missed()
                
                let splash = SKEmitterNode(fileNamed: "PaintSplash.sks")
                splash?.name = "splash"
                splash?.position = CGPoint(x: sprite.position.x, y: sprite.position.y - 50)
                splash?.particleColorSequence = nil
                splash?.particleColorBlendFactor = 0.7
                splash?.particleColor = sprite.paint!.color
                splash?.zPosition = Layer.collectible.rawValue
                
                addChild(splash!)
                
                run(SKAction.wait(forDuration: 0.5), completion: {splash!.removeFromParent()})
                
                
                gameOver()
            }
        }
        
        
        }
    }
