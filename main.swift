import AppKit
import SceneKit
import SpriteKit

// MARK: - Vector Math
extension SCNVector3 {
    static func + (a: SCNVector3, b: SCNVector3) -> SCNVector3 { SCNVector3(a.x+b.x, a.y+b.y, a.z+b.z) }
    static func - (a: SCNVector3, b: SCNVector3) -> SCNVector3 { SCNVector3(a.x-b.x, a.y-b.y, a.z-b.z) }
    static func * (v: SCNVector3, s: CGFloat) -> SCNVector3 { SCNVector3(v.x*s, v.y*s, v.z*s) }
    var len: CGFloat { sqrt(x*x + y*y + z*z) }
    var norm: SCNVector3 { let l = len; guard l > 0.001 else { return SCNVector3(0,0,-1) }; return SCNVector3(x/l, y/l, z/l) }
}
func lp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b-a)*t }
func rF(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { CGFloat.random(in: lo...hi) }
func rI(_ lo: Int, _ hi: Int) -> Int { Int.random(in: lo...hi) }

// MARK: - Constants
let WIN_W: CGFloat = 1280
let WIN_H: CGFloat = 720
let FWD_SPEED: CGFloat = 90
let LAT_SPEED: CGFloat = 38
let BOUND_X: CGFloat = 16
let BOUND_Y: CGFloat = 10
let SHOOT_CD: CGFloat = 0.11
let LASER_SPD: CGFloat = 300
let ELASER_SPD: CGFloat = 150
let SPAWN_DIST: CGFloat = 380
let REMOVE_DIST: CGFloat = 60

// MARK: - Colors
let cCyan    = NSColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1)
let cMagenta = NSColor(red: 1.0, green: 0.1, blue: 0.6, alpha: 1)
let cRed     = NSColor(red: 1.0, green: 0.15, blue: 0.1, alpha: 1)
let cOrange  = NSColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1)
let cGreen   = NSColor(red: 0.1, green: 1.0, blue: 0.3, alpha: 1)
let cPurple  = NSColor(red: 0.6, green: 0.1, blue: 1.0, alpha: 1)
let cGold    = NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1)
let cGunmetal = NSColor(red: 0.22, green: 0.24, blue: 0.28, alpha: 1)
let cDarkGrey = NSColor(red: 0.15, green: 0.16, blue: 0.2, alpha: 1)

func mm(_ c: NSColor, emit: NSColor? = nil, con: Bool = false) -> SCNMaterial {
    let m = SCNMaterial(); m.diffuse.contents = c
    if let e = emit { m.emission.contents = e }
    if con { m.lightingModel = .constant }; return m
}

// MARK: - Geometry Builders
func buildAsteroid(radius: CGFloat) -> SCNNode {
    let geo = SCNSphere(radius: radius); geo.segmentCount = 8
    geo.materials = [mm(NSColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1))]
    let n = SCNNode(geometry: geo)
    n.scale = SCNVector3(rF(0.7,1.3), rF(0.6,1.2), rF(0.7,1.3))
    n.runAction(SCNAction.repeatForever(SCNAction.rotateBy(
        x: rF(-1,1), y: rF(-1,1), z: rF(-1,1), duration: Double(rF(2,6)))))
    return n
}

func buildEnemy(type: Int) -> SCNNode {
    let root = SCNNode()
    switch type {
    case 0: // Drone
        let body = SCNNode(geometry: SCNSphere(radius: 0.7))
        body.geometry!.materials = [mm(cDarkGrey, emit: NSColor(red: 0.5, green: 0.05, blue: 0, alpha: 1))]
        root.addChildNode(body)
        let core = SCNNode(geometry: SCNSphere(radius: 0.35))
        core.geometry!.materials = [mm(cOrange, emit: cOrange, con: true)]
        root.addChildNode(core)
        for i in 0..<4 {
            let fin = SCNNode(geometry: SCNBox(width: 0.08, height: 0.55, length: 0.45, chamferRadius: 0.02))
            fin.geometry!.materials = [mm(cRed, emit: NSColor(red: 0.4, green: 0, blue: 0, alpha: 1))]
            let a = CGFloat(i) * CGFloat.pi / 2
            fin.position = SCNVector3(cos(a)*0.55, sin(a)*0.55, 0); fin.eulerAngles.z = a
            root.addChildNode(fin)
        }
    case 1: // Fighter
        let body = SCNNode(geometry: SCNCone(topRadius: 0.08, bottomRadius: 0.55, height: 2.4))
        body.geometry!.materials = [mm(cDarkGrey, emit: NSColor(red: 0.2, green: 0, blue: 0.15, alpha: 1))]
        body.eulerAngles.x = CGFloat.pi / 2; root.addChildNode(body)
        for s: CGFloat in [-1,1] {
            let w = SCNNode(geometry: SCNBox(width: 2.0, height: 0.04, length: 0.9, chamferRadius: 0.02))
            w.geometry!.materials = [mm(cMagenta, emit: NSColor(red: 0.4, green: 0, blue: 0.2, alpha: 1))]
            w.position = SCNVector3(s*1.0, 0, 0.3); root.addChildNode(w)
        }
        let eng = SCNNode(geometry: SCNSphere(radius: 0.2))
        eng.geometry!.materials = [mm(cMagenta, emit: cMagenta, con: true)]
        eng.position = SCNVector3(0, 0, 1.2); root.addChildNode(eng)
    default: // Cruiser
        let body = SCNNode(geometry: SCNBox(width: 2.5, height: 1.2, length: 4.0, chamferRadius: 0.1))
        body.geometry!.materials = [mm(NSColor(red: 0.18, green: 0.15, blue: 0.22, alpha: 1),
                                       emit: NSColor(red: 0.1, green: 0, blue: 0.15, alpha: 1))]
        root.addChildNode(body)
        let br = SCNNode(geometry: SCNBox(width: 0.9, height: 0.7, length: 1.1, chamferRadius: 0.05))
        br.geometry!.materials = [mm(cDarkGrey)]; br.position = SCNVector3(0, 0.8, -0.5)
        root.addChildNode(br)
        for s: CGFloat in [-1,1] {
            let t = SCNNode(geometry: SCNCylinder(radius: 0.22, height: 0.45))
            t.geometry!.materials = [mm(cPurple, emit: cPurple)]
            t.position = SCNVector3(s*0.9, 0.65, 0.6); root.addChildNode(t)
            let e = SCNNode(geometry: SCNSphere(radius: 0.32))
            e.geometry!.materials = [mm(cPurple, emit: cPurple, con: true)]
            e.position = SCNVector3(s*0.8, -0.1, 2.0); root.addChildNode(e)
        }
    }
    return root
}

func buildLaser(color: NSColor) -> SCNNode {
    let geo = SCNBox(width: 0.08, height: 0.08, length: 2.0, chamferRadius: 0.04)
    geo.materials = [mm(color, emit: color, con: true)]
    return SCNNode(geometry: geo)
}

func buildRing() -> SCNNode {
    let geo = SCNTorus(ringRadius: 5.0, pipeRadius: 0.2)
    geo.materials = [mm(cGold, emit: cGold, con: true)]
    let n = SCNNode(geometry: geo); n.eulerAngles.x = CGFloat.pi / 2; return n
}

func buildPickup() -> SCNNode {
    let geo = SCNSphere(radius: 0.5); geo.materials = [mm(cGreen, emit: cGreen, con: true)]
    let n = SCNNode(geometry: geo)
    n.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi*2, z: 0, duration: 2)))
    n.runAction(SCNAction.repeatForever(SCNAction.sequence([
        SCNAction.fadeOpacity(to: 0.5, duration: 0.5), SCNAction.fadeOpacity(to: 1.0, duration: 0.5)])))
    return n
}

// MARK: - Cockpit geometry (visible from inside)
func buildCockpitFrame() -> SCNNode {
    let root = SCNNode()
    // Dashboard — wide box at bottom of view
    let dash = SCNNode(geometry: SCNBox(width: 4.0, height: 0.6, length: 1.5, chamferRadius: 0.05))
    dash.geometry!.materials = [mm(NSColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1),
                                   emit: NSColor(red: 0.02, green: 0.02, blue: 0.04, alpha: 1))]
    dash.position = SCNVector3(0, -1.3, -2.0)
    dash.eulerAngles.x = 0.25
    root.addChildNode(dash)
    // Console lights on dashboard
    for i in 0..<6 {
        let light = SCNNode(geometry: SCNBox(width: 0.06, height: 0.03, length: 0.03, chamferRadius: 0.01))
        let col = i < 3 ? cCyan : cGreen
        light.geometry!.materials = [mm(col, emit: col, con: true)]
        light.position = SCNVector3(CGFloat(i - 3) * 0.3 + 0.15, -1.05, -1.35)
        root.addChildNode(light)
    }
    // Left strut
    let ls = SCNNode(geometry: SCNBox(width: 0.08, height: 3.5, length: 0.08, chamferRadius: 0.02))
    ls.geometry!.materials = [mm(NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1))]
    ls.position = SCNVector3(-1.8, 0, -2.5)
    ls.eulerAngles.z = 0.15
    root.addChildNode(ls)
    // Right strut
    let rs = SCNNode(geometry: SCNBox(width: 0.08, height: 3.5, length: 0.08, chamferRadius: 0.02))
    rs.geometry!.materials = [mm(NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1))]
    rs.position = SCNVector3(1.8, 0, -2.5)
    rs.eulerAngles.z = -0.15
    root.addChildNode(rs)
    // Top bar
    let tb = SCNNode(geometry: SCNBox(width: 4.0, height: 0.06, length: 0.06, chamferRadius: 0.02))
    tb.geometry!.materials = [mm(NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1))]
    tb.position = SCNVector3(0, 1.55, -2.5)
    root.addChildNode(tb)
    return root
}

// MARK: - Particles
func makeExplosionPS(color: NSColor, count: CGFloat = 400, size: CGFloat = 0.2, speed: CGFloat = 18) -> SCNParticleSystem {
    let ps = SCNParticleSystem()
    ps.birthRate = count; ps.particleLifeSpan = 0.7; ps.particleLifeSpanVariation = 0.3
    ps.emissionDuration = 0.08; ps.loops = false
    ps.particleSize = size; ps.particleSizeVariation = size * 0.6
    ps.particleColor = color; ps.particleColorVariation = SCNVector4(0.1, 0.3, 0.3, 0)
    ps.blendMode = .additive; ps.emitterShape = SCNSphere(radius: 0.3)
    ps.particleVelocity = speed; ps.particleVelocityVariation = speed * 0.5
    ps.spreadingAngle = 180; ps.isAffectedByGravity = false
    return ps
}

func makeSpeedLines() -> SCNParticleSystem {
    let ps = SCNParticleSystem()
    ps.birthRate = 60; ps.particleLifeSpan = 0.6; ps.particleSize = 0.03
    ps.particleSizeVariation = 0.02; ps.particleColor = NSColor(white: 0.7, alpha: 0.6)
    ps.blendMode = .additive; ps.emitterShape = SCNPlane(width: 50, height: 35)
    ps.particleVelocity = 120; ps.particleVelocityVariation = 40
    ps.spreadingAngle = 3; ps.emittingDirection = SCNVector3(0, 0, 1)
    ps.isAffectedByGravity = false
    return ps
}

// MARK: - Data Types
struct LaserData { let node: SCNNode; var vel: SCNVector3; var life: CGFloat }
struct EnemyData {
    let node: SCNNode; var type: Int; var hp: Int; var radius: CGFloat
    var shootCD: CGFloat; var phase: CGFloat; var speed: CGFloat
}
struct AsteroidData { let node: SCNNode; var radius: CGFloat; var hp: Int }
struct RingData { let node: SCNNode; var collected: Bool }
struct PickupData { let node: SCNNode }

// MARK: - GameView
class GameView: SCNView {
    var heldKeys: Set<UInt16> = []
    var pressedKeys: Set<UInt16> = []
    override var acceptsFirstResponder: Bool { true }
    override func performKeyEquivalent(with event: NSEvent) -> Bool { false }
    override func keyDown(with event: NSEvent) {
        heldKeys.insert(event.keyCode)
        if !event.isARepeat { pressedKeys.insert(event.keyCode) }
    }
    override func keyUp(with event: NSEvent) { heldKeys.remove(event.keyCode) }
    override func mouseDown(with event: NSEvent) { pressedKeys.insert(999) }
    func consume() -> Set<UInt16> { let p = pressedKeys; pressedKeys.removeAll(); return p }
}

// MARK: - GameController
class GameController: NSObject, SCNSceneRendererDelegate {
    let scene = SCNScene()
    var view: GameView!
    var shipNode: SCNNode!     // invisible position tracker
    var cameraNode: SCNNode!
    var cockpitNode: SCNNode!  // moves with camera
    var gameNode: SCNNode!
    var hudScene: SKScene!
    var speedLinesNode: SCNNode!
    var speedPS: SCNParticleSystem!

    // HUD elements
    var scoreLabel: SKLabelNode!
    var healthBG: SKShapeNode!
    var healthBar: SKShapeNode!
    var distLabel: SKLabelNode!
    var speedLabel: SKLabelNode!
    var warningLabel: SKLabelNode!
    var boostLabel: SKLabelNode!
    var menuNode: SKNode?
    var deathNode: SKNode?
    var crosshair: SKNode?
    // Cockpit HUD overlay
    var leftBar: SKShapeNode!
    var rightBar: SKShapeNode!
    var topBar: SKShapeNode!
    var bottomDash: SKShapeNode!
    var radarNode: SKNode!
    var radarDots: [SKShapeNode] = []

    var stars: [SCNNode] = []
    let starGeo = SCNSphere(radius: 0.06)

    var state = "menu"
    var score = 0
    var health = 5
    var maxHealth = 5
    var lastTime: TimeInterval = 0
    var shootCD: CGFloat = 0
    var dist: CGFloat = 0
    var difficulty: CGFloat = 1
    var invTimer: CGFloat = 0
    var shakeAmt: CGFloat = 0
    var deathTimer: CGFloat = 0
    var deathHUDShown = false
    var lastWing = false

    var lasers: [LaserData] = []
    var eLasers: [LaserData] = []
    var enemies: [EnemyData] = []
    var asteroids: [AsteroidData] = []
    var rings: [RingData] = []
    var pickups: [PickupData] = []
    var spawnT: CGFloat = 0
    var asteroidT: CGFloat = 0
    var ringT: CGFloat = 0
    var pickupT: CGFloat = 0

    func setup(_ v: GameView) {
        view = v; view.scene = scene; view.delegate = self
        view.isPlaying = true; view.preferredFramesPerSecond = 60
        view.antialiasingMode = .multisampling4X; view.backgroundColor = .black
        scene.background.contents = NSColor(red: 0.005, green: 0.005, blue: 0.02, alpha: 1)
        scene.fogStartDistance = 250; scene.fogEndDistance = 420
        scene.fogColor = NSColor(red: 0.005, green: 0.005, blue: 0.02, alpha: 1)
        setupLighting(); setupCamera(); setupStarfield(); setupHUD()
        showMenu()
    }

    func setupLighting() {
        let amb = SCNNode(); amb.light = SCNLight()
        amb.light!.type = .ambient; amb.light!.color = NSColor(white: 0.12, alpha: 1)
        scene.rootNode.addChildNode(amb)
        let dir = SCNNode(); dir.light = SCNLight()
        dir.light!.type = .directional; dir.light!.color = NSColor(white: 0.45, alpha: 1)
        dir.eulerAngles = SCNVector3(-0.5, 0.4, 0)
        scene.rootNode.addChildNode(dir)
    }

    func setupCamera() {
        cameraNode = SCNNode(); cameraNode.camera = SCNCamera()
        cameraNode.camera!.zFar = 500; cameraNode.camera!.zNear = 0.1
        cameraNode.camera!.fieldOfView = 80
        cameraNode.camera!.wantsHDR = true
        cameraNode.camera!.bloomIntensity = 1.5
        cameraNode.camera!.bloomThreshold = 0.25
        cameraNode.camera!.bloomBlurRadius = 14
        cameraNode.camera!.vignettingIntensity = 1.0
        cameraNode.camera!.vignettingPower = 1.5
        cameraNode.position = SCNVector3(0, 0.5, 0)
        scene.rootNode.addChildNode(cameraNode)

        // Speed lines emitter (attached far ahead of camera)
        speedPS = makeSpeedLines()
        speedPS.birthRate = 0  // off until playing
        speedLinesNode = SCNNode()
        speedLinesNode.position = SCNVector3(0, 0, -300)
        speedLinesNode.addParticleSystem(speedPS)
        cameraNode.addChildNode(speedLinesNode)
    }

    func setupStarfield() {
        starGeo.materials = [mm(.white, emit: .white, con: true)]
        for _ in 0..<300 {
            let s = SCNNode(geometry: starGeo)
            s.position = SCNVector3(rF(-100,100), rF(-60,60), rF(-450,30))
            let sz = rF(0.4, 2.2); s.scale = SCNVector3(sz, sz, sz)
            scene.rootNode.addChildNode(s); stars.append(s)
        }
    }

    func setupHUD() {
        hudScene = SKScene(size: CGSize(width: WIN_W, height: WIN_H))
        hudScene.backgroundColor = NSColor.clear

        // Cockpit frame overlay
        // Bottom dashboard
        let dashPath = CGMutablePath()
        dashPath.move(to: CGPoint(x: 0, y: 0))
        dashPath.addLine(to: CGPoint(x: WIN_W, y: 0))
        dashPath.addLine(to: CGPoint(x: WIN_W - 80, y: 100))
        dashPath.addLine(to: CGPoint(x: 80, y: 100))
        dashPath.closeSubpath()
        bottomDash = SKShapeNode(path: dashPath)
        bottomDash.fillColor = NSColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.85)
        bottomDash.strokeColor = NSColor(red: 0, green: 0.3, blue: 0.5, alpha: 0.4)
        bottomDash.lineWidth = 1; bottomDash.zPosition = 10
        hudScene.addChild(bottomDash)

        // Top bar
        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: 0, y: WIN_H))
        topPath.addLine(to: CGPoint(x: WIN_W, y: WIN_H))
        topPath.addLine(to: CGPoint(x: WIN_W - 60, y: WIN_H - 55))
        topPath.addLine(to: CGPoint(x: 60, y: WIN_H - 55))
        topPath.closeSubpath()
        topBar = SKShapeNode(path: topPath)
        topBar.fillColor = NSColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.8)
        topBar.strokeColor = NSColor(red: 0, green: 0.3, blue: 0.5, alpha: 0.3)
        topBar.lineWidth = 1; topBar.zPosition = 10
        hudScene.addChild(topBar)

        // Left pillar
        let lpPath = CGMutablePath()
        lpPath.move(to: CGPoint(x: 0, y: 0)); lpPath.addLine(to: CGPoint(x: 0, y: WIN_H))
        lpPath.addLine(to: CGPoint(x: 50, y: WIN_H - 60)); lpPath.addLine(to: CGPoint(x: 35, y: 100))
        lpPath.closeSubpath()
        leftBar = SKShapeNode(path: lpPath)
        leftBar.fillColor = NSColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 0.7)
        leftBar.strokeColor = .clear; leftBar.zPosition = 10
        hudScene.addChild(leftBar)

        // Right pillar
        let rpPath = CGMutablePath()
        rpPath.move(to: CGPoint(x: WIN_W, y: 0)); rpPath.addLine(to: CGPoint(x: WIN_W, y: WIN_H))
        rpPath.addLine(to: CGPoint(x: WIN_W - 50, y: WIN_H - 60))
        rpPath.addLine(to: CGPoint(x: WIN_W - 35, y: 100))
        rpPath.closeSubpath()
        rightBar = SKShapeNode(path: rpPath)
        rightBar.fillColor = NSColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 0.7)
        rightBar.strokeColor = .clear; rightBar.zPosition = 10
        hudScene.addChild(rightBar)

        // Score
        scoreLabel = SKLabelNode(text: "0"); scoreLabel.fontName = "Menlo-Bold"
        scoreLabel.fontSize = 20; scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: WIN_W - 80, y: WIN_H - 40); scoreLabel.zPosition = 20
        hudScene.addChild(scoreLabel)
        let sc = SKLabelNode(text: "SCORE"); sc.fontName = "Menlo"; sc.fontSize = 9
        sc.fontColor = NSColor(white: 0.45, alpha: 1); sc.horizontalAlignmentMode = .right
        sc.position = CGPoint(x: WIN_W - 80, y: WIN_H - 52); sc.zPosition = 20
        hudScene.addChild(sc)

        // Health bar on dashboard
        healthBG = SKShapeNode(rect: CGRect(x: 100, y: 55, width: 250, height: 12), cornerRadius: 2)
        healthBG.fillColor = NSColor(white: 0.1, alpha: 0.8)
        healthBG.strokeColor = NSColor(white: 0.25, alpha: 0.5); healthBG.lineWidth = 1
        healthBG.zPosition = 20; hudScene.addChild(healthBG)
        healthBar = SKShapeNode(rect: CGRect(x: 100, y: 55, width: 250, height: 12), cornerRadius: 2)
        healthBar.fillColor = cCyan; healthBar.strokeColor = .clear
        healthBar.zPosition = 21; hudScene.addChild(healthBar)
        let hc = SKLabelNode(text: "HULL"); hc.fontName = "Menlo"; hc.fontSize = 9
        hc.fontColor = NSColor(white: 0.4, alpha: 1); hc.horizontalAlignmentMode = .left
        hc.position = CGPoint(x: 100, y: 40); hc.zPosition = 20; hudScene.addChild(hc)

        // Distance
        distLabel = SKLabelNode(text: "0m"); distLabel.fontName = "Menlo"; distLabel.fontSize = 14
        distLabel.fontColor = NSColor(white: 0.4, alpha: 1)
        distLabel.position = CGPoint(x: WIN_W / 2, y: WIN_H - 38); distLabel.zPosition = 20
        hudScene.addChild(distLabel)

        // Speed
        speedLabel = SKLabelNode(text: "SPD 0"); speedLabel.fontName = "Menlo"; speedLabel.fontSize = 12
        speedLabel.fontColor = cCyan; speedLabel.horizontalAlignmentMode = .left
        speedLabel.position = CGPoint(x: 100, y: 20); speedLabel.zPosition = 20
        hudScene.addChild(speedLabel)

        // Boost indicator
        boostLabel = SKLabelNode(text: "BOOST"); boostLabel.fontName = "Menlo-Bold"; boostLabel.fontSize = 14
        boostLabel.fontColor = cOrange; boostLabel.alpha = 0
        boostLabel.position = CGPoint(x: WIN_W / 2, y: 70); boostLabel.zPosition = 20
        hudScene.addChild(boostLabel)

        // Warning
        warningLabel = SKLabelNode(text: "!! HULL CRITICAL !!"); warningLabel.fontName = "Menlo-Bold"
        warningLabel.fontSize = 16; warningLabel.fontColor = cRed; warningLabel.alpha = 0
        warningLabel.position = CGPoint(x: WIN_W / 2, y: WIN_H / 2 - 80); warningLabel.zPosition = 30
        hudScene.addChild(warningLabel)

        // Crosshair
        let ch = SKNode(); ch.position = CGPoint(x: WIN_W / 2, y: WIN_H / 2); ch.zPosition = 15
        // Outer ring
        let or1 = SKShapeNode(circleOfRadius: 22)
        or1.strokeColor = NSColor(red: 0, green: 0.7, blue: 1, alpha: 0.25); or1.lineWidth = 1
        or1.fillColor = .clear; ch.addChild(or1)
        // Inner ring
        let ir = SKShapeNode(circleOfRadius: 8)
        ir.strokeColor = NSColor(red: 0, green: 0.8, blue: 1, alpha: 0.4); ir.lineWidth = 1
        ir.fillColor = .clear; ch.addChild(ir)
        // Center dot
        let cd = SKShapeNode(circleOfRadius: 1.5)
        cd.fillColor = NSColor(red: 0, green: 1, blue: 1, alpha: 0.6); cd.strokeColor = .clear
        ch.addChild(cd)
        // Cross lines
        for a in [0, 90, 180, 270] {
            let tick = SKShapeNode(rect: CGRect(x: -0.5, y: 12, width: 1, height: 8))
            tick.fillColor = NSColor(red: 0, green: 0.7, blue: 1, alpha: 0.3); tick.strokeColor = .clear
            tick.zRotation = CGFloat(a) * .pi / 180; ch.addChild(tick)
        }
        // Diagonal ticks
        for a in [45, 135, 225, 315] {
            let tick = SKShapeNode(rect: CGRect(x: -0.5, y: 16, width: 1, height: 5))
            tick.fillColor = NSColor(red: 0, green: 0.6, blue: 0.9, alpha: 0.15); tick.strokeColor = .clear
            tick.zRotation = CGFloat(a) * .pi / 180; ch.addChild(tick)
        }
        crosshair = ch; hudScene.addChild(ch)

        // Mini radar on right side of dashboard
        radarNode = SKNode()
        radarNode.position = CGPoint(x: WIN_W - 180, y: 50); radarNode.zPosition = 20
        let radarBG = SKShapeNode(circleOfRadius: 35)
        radarBG.fillColor = NSColor(red: 0, green: 0.05, blue: 0.1, alpha: 0.7)
        radarBG.strokeColor = NSColor(red: 0, green: 0.3, blue: 0.5, alpha: 0.5); radarBG.lineWidth = 1
        radarNode.addChild(radarBG)
        let radarCenter = SKShapeNode(circleOfRadius: 2)
        radarCenter.fillColor = cCyan; radarCenter.strokeColor = .clear
        radarNode.addChild(radarCenter)
        // Radar range rings
        for r: CGFloat in [15, 30] {
            let ring = SKShapeNode(circleOfRadius: r)
            ring.strokeColor = NSColor(red: 0, green: 0.2, blue: 0.3, alpha: 0.3); ring.lineWidth = 0.5
            ring.fillColor = .clear; radarNode.addChild(ring)
        }
        hudScene.addChild(radarNode)

        view.overlaySKScene = hudScene
    }

    func setCockpitVisible(_ v: Bool) {
        bottomDash.isHidden = !v; topBar.isHidden = !v
        leftBar.isHidden = !v; rightBar.isHidden = !v; radarNode.isHidden = !v
    }

    // MARK: - Menu
    func showMenu() {
        state = "menu"
        deathNode?.removeFromParent(); deathNode = nil
        gameNode?.removeFromParentNode(); gameNode = nil
        cockpitNode?.removeFromParentNode(); cockpitNode = nil
        for c in scene.rootNode.childNodes where c.name == "deco" { c.removeFromParentNode() }
        for _ in 0..<10 {
            let a = buildAsteroid(radius: rF(1.5, 5.0)); a.name = "deco"
            a.position = SCNVector3(rF(-20,20), rF(-10,10), rF(-25,15))
            scene.rootNode.addChildNode(a)
        }
        crosshair?.isHidden = true; scoreLabel.isHidden = true
        healthBG.isHidden = true; healthBar.isHidden = true; distLabel.isHidden = true
        speedLabel.isHidden = true; boostLabel.alpha = 0; warningLabel.alpha = 0
        setCockpitVisible(false)
        speedPS.birthRate = 0

        let mn = SKNode(); mn.zPosition = 50
        let t = SKLabelNode(text: "VOID RUNNER")
        t.fontName = "Menlo-Bold"; t.fontSize = 54; t.fontColor = cCyan
        t.position = CGPoint(x: WIN_W/2, y: WIN_H * 0.63); mn.addChild(t)
        let g = SKLabelNode(text: "VOID RUNNER")
        g.fontName = "Menlo-Bold"; g.fontSize = 54; g.fontColor = cCyan; g.alpha = 0.25
        g.position = CGPoint(x: WIN_W/2 + 2, y: WIN_H * 0.63 - 2); mn.addChild(g)
        let sub = SKLabelNode(text: "FIRST PERSON COCKPIT VIEW")
        sub.fontName = "Menlo"; sub.fontSize = 13
        sub.fontColor = NSColor(white: 0.4, alpha: 1)
        sub.position = CGPoint(x: WIN_W/2, y: WIN_H * 0.56); mn.addChild(sub)
        let s = SKLabelNode(text: "[ PRESS SPACE TO LAUNCH ]")
        s.fontName = "Menlo"; s.fontSize = 16; s.fontColor = NSColor(white: 0.6, alpha: 1)
        s.position = CGPoint(x: WIN_W/2, y: WIN_H * 0.36)
        s.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8), SKAction.fadeAlpha(to: 0.9, duration: 0.8)])))
        mn.addChild(s)
        let c = SKLabelNode(text: "WASD/Arrows: Move   Space/Click: Shoot   Shift: Boost")
        c.fontName = "Menlo"; c.fontSize = 11; c.fontColor = NSColor(white: 0.3, alpha: 1)
        c.position = CGPoint(x: WIN_W/2, y: WIN_H * 0.27); mn.addChild(c)
        hudScene.addChild(mn); menuNode = mn
    }

    // MARK: - Start
    func startGame() {
        menuNode?.removeFromParent(); menuNode = nil
        deathNode?.removeFromParent(); deathNode = nil
        for c in scene.rootNode.childNodes where c.name == "deco" { c.removeFromParentNode() }
        gameNode?.removeFromParentNode()
        gameNode = SCNNode(); scene.rootNode.addChildNode(gameNode)

        // Ship is invisible position tracker
        shipNode = SCNNode(); shipNode.position = SCNVector3(0, 0, 0)
        gameNode.addChildNode(shipNode)

        // Cockpit attached to camera
        cockpitNode?.removeFromParentNode()
        cockpitNode = buildCockpitFrame()
        cameraNode.addChildNode(cockpitNode)

        // Gun flash lights at wing positions (visible in cockpit)
        for s: CGFloat in [-0.8, 0.8] {
            let gunLight = SCNNode(); gunLight.light = SCNLight()
            gunLight.light!.type = .omni; gunLight.light!.color = cCyan
            gunLight.light!.intensity = 0
            gunLight.light!.attenuationStartDistance = 1; gunLight.light!.attenuationEndDistance = 5
            gunLight.position = SCNVector3(s, -0.6, -2.0)
            gunLight.name = "gunLight"
            cameraNode.addChildNode(gunLight)
        }

        lasers = []; eLasers = []; enemies = []; asteroids = []; rings = []; pickups = []
        score = 0; health = maxHealth; dist = 0; difficulty = 1
        invTimer = 0; shakeAmt = 0; shootCD = 0; lastTime = 0
        spawnT = 1.5; asteroidT = 0.5; ringT = 8; pickupT = 12
        deathTimer = 0; deathHUDShown = false

        cameraNode.position = SCNVector3(0, 0.5, 0)
        cameraNode.eulerAngles = SCNVector3(0, 0, 0)
        cameraNode.look(at: SCNVector3(0, 0.5, -100))

        crosshair?.isHidden = false; scoreLabel.isHidden = false
        healthBG.isHidden = false; healthBar.isHidden = false; distLabel.isHidden = false
        speedLabel.isHidden = false
        setCockpitVisible(true)
        speedPS.birthRate = 60
        state = "playing"
    }

    // MARK: - Render Loop
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastTime == 0 { lastTime = time; return }
        let dt = CGFloat(time - lastTime); lastTime = time
        if dt > 0.1 { return }
        let pressed = view.consume()
        recycleStars()

        switch state {
        case "menu":
            let t = CGFloat(time)
            cameraNode.position = SCNVector3(sin(t*0.18)*28, 6+sin(t*0.12)*4, cos(t*0.18)*28)
            cameraNode.look(at: SCNVector3(0, 0, 0))
            if pressed.contains(49) { startGame() }
        case "playing":
            updatePlaying(dt, pressed: pressed)
        case "dead":
            deathTimer += dt
            if !deathHUDShown && deathTimer > 0.8 { showDeathHUD(); deathHUDShown = true }
            cameraNode.position.y += 1.5 * dt
            cameraNode.eulerAngles.y += 0.15 * dt
            if pressed.contains(49) && deathTimer > 1.5 { showMenu() }
        default: break
        }
    }

    // MARK: - Main Update
    func updatePlaying(_ dt: CGFloat, pressed: Set<UInt16>) {
        let keys = view.heldKeys
        let boosting = keys.contains(56) || keys.contains(60)
        let fwd = boosting ? FWD_SPEED * 1.8 : FWD_SPEED

        // Move ship position tracker
        shipNode.position.z -= fwd * dt
        dist += fwd * dt

        var dx: CGFloat = 0, dy: CGFloat = 0
        if keys.contains(0) || keys.contains(123) { dx -= 1 }
        if keys.contains(2) || keys.contains(124) { dx += 1 }
        if keys.contains(13) || keys.contains(126) { dy += 1 }
        if keys.contains(1) || keys.contains(125) { dy -= 1 }
        let lat = boosting ? LAT_SPEED * 0.7 : LAT_SPEED
        shipNode.position.x += dx * lat * dt
        shipNode.position.y += dy * lat * dt
        shipNode.position.x = max(-BOUND_X, min(BOUND_X, shipNode.position.x))
        shipNode.position.y = max(-BOUND_Y+1, min(BOUND_Y, shipNode.position.y))

        // Camera tracks ship position directly (first person)
        let tgt = SCNVector3(shipNode.position.x, shipNode.position.y + 0.5, shipNode.position.z)
        cameraNode.position = SCNVector3(lp(cameraNode.position.x, tgt.x, 0.12),
                                          lp(cameraNode.position.y, tgt.y, 0.12),
                                          lp(cameraNode.position.z, tgt.z, 0.15))

        // Camera roll for immersion (tilt when moving)
        let tgtRoll = -dx * 0.06
        let tgtPitch = dy * 0.03
        cameraNode.eulerAngles.z = lp(cameraNode.eulerAngles.z, tgtRoll, 0.08)
        cameraNode.eulerAngles.x = lp(cameraNode.eulerAngles.x, tgtPitch, 0.08)
        cameraNode.eulerAngles.y = 0 // always look forward

        // FOV for boost
        let tgtFOV: CGFloat = boosting ? 100 : 80
        cameraNode.camera!.fieldOfView += (tgtFOV - cameraNode.camera!.fieldOfView) * 0.05

        // Speed lines intensity
        speedPS.birthRate = boosting ? 250 : 60
        speedPS.particleVelocity = boosting ? 200 : 120

        // Boost label
        boostLabel.alpha = lp(boostLabel.alpha, boosting ? 1.0 : 0.0, 0.1)

        // Screen shake
        if shakeAmt > 0.03 {
            cameraNode.position.x += rF(-shakeAmt, shakeAmt)
            cameraNode.position.y += rF(-shakeAmt, shakeAmt)
            shakeAmt *= 0.85
        } else { shakeAmt = 0 }

        // Shoot
        shootCD -= dt
        if (keys.contains(49) || pressed.contains(999)) && shootCD <= 0 {
            shootLaser(); shootCD = SHOOT_CD
        }

        // Invincibility flash
        if invTimer > 0 {
            invTimer -= dt
            // Flash cockpit overlay red
            let flash = Int(invTimer * 12) % 2 == 0
            bottomDash.fillColor = flash
                ? NSColor(red: 0.2, green: 0.02, blue: 0.02, alpha: 0.85)
                : NSColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.85)
        } else {
            bottomDash.fillColor = NSColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.85)
        }

        // Warning
        if health <= 1 && health > 0 {
            let flash = sin(CGFloat(lastTime) * 8) > 0
            warningLabel.alpha = flash ? 0.8 : 0.2
        } else { warningLabel.alpha = 0 }

        difficulty = 1 + dist / 600

        spawnT -= dt
        if spawnT <= 0 { spawnEnemyWave(); spawnT = max(0.8, 3.5 - difficulty * 0.25) }
        asteroidT -= dt
        if asteroidT <= 0 { spawnAsteroidCluster(); asteroidT = max(0.4, 1.8 - difficulty * 0.12) }
        ringT -= dt
        if ringT <= 0 { spawnRingGate(); ringT = rF(8, 15) }
        pickupT -= dt
        if pickupT <= 0 { spawnHealthPickup(); pickupT = rF(10, 20) }

        updateLasers(dt); updateELasers(dt); updateEnemies(dt)
        checkCollisions(); cleanupObjects(); updateHUD(); updateRadar()
    }

    // MARK: - Shooting (from cockpit sides)
    func shootLaser() {
        lastWing = !lastWing
        let xOff: CGFloat = lastWing ? 0.8 : -0.8
        let n = buildLaser(color: cCyan)
        n.position = SCNVector3(shipNode.position.x + xOff, shipNode.position.y, shipNode.position.z - 3)
        lasers.append(LaserData(node: n, vel: SCNVector3(0, 0, -LASER_SPD), life: 2.0))
        gameNode.addChildNode(n)

        // Flash gun lights briefly
        for child in cameraNode.childNodes where child.name == "gunLight" {
            child.light?.intensity = 800
            child.runAction(SCNAction.customAction(duration: 0.08) { nd, t in
                nd.light?.intensity = CGFloat(800 * (1 - t / 0.08))
            })
        }
    }

    func enemyShoot(from pos: SCNVector3) {
        let dir = (shipNode.position - pos).norm
        let n = buildLaser(color: cRed); n.position = pos; n.look(at: pos + dir)
        eLasers.append(LaserData(node: n, vel: dir * ELASER_SPD, life: 4.0))
        gameNode.addChildNode(n)
    }

    func enemyShootSpread(from pos: SCNVector3) {
        let bd = (shipNode.position - pos).norm
        for off: CGFloat in [-0.15, 0, 0.15] {
            let dir = SCNVector3(bd.x + off, bd.y, bd.z).norm
            let n = buildLaser(color: cPurple); n.position = pos
            eLasers.append(LaserData(node: n, vel: dir * (ELASER_SPD * 0.8), life: 4.0))
            gameNode.addChildNode(n)
        }
    }

    // MARK: - Projectiles
    func updateLasers(_ dt: CGFloat) {
        for i in (0..<lasers.count).reversed() {
            lasers[i].life -= dt
            lasers[i].node.position = lasers[i].node.position + lasers[i].vel * dt
            if lasers[i].life <= 0 { lasers[i].node.removeFromParentNode(); lasers.remove(at: i) }
        }
    }
    func updateELasers(_ dt: CGFloat) {
        for i in (0..<eLasers.count).reversed() {
            eLasers[i].life -= dt
            eLasers[i].node.position = eLasers[i].node.position + eLasers[i].vel * dt
            if eLasers[i].life <= 0 { eLasers[i].node.removeFromParentNode(); eLasers.remove(at: i) }
        }
    }

    // MARK: - Enemy AI
    func updateEnemies(_ dt: CGFloat) {
        let sp = shipNode.position
        for i in 0..<enemies.count {
            enemies[i].shootCD -= dt
            let pos = enemies[i].node.position
            let toShip = sp - pos; let d = toShip.len
            let ph = enemies[i].phase; let time = CGFloat(lastTime)

            switch enemies[i].type {
            case 0:
                let dir = toShip.norm
                enemies[i].node.position = pos + dir * enemies[i].speed * dt
                enemies[i].node.position.x += sin(ph + pos.z * 0.05) * 12 * dt
                enemies[i].node.look(at: sp)
            case 1:
                if d > 30 { enemies[i].node.position = pos + toShip.norm * 25 * dt }
                enemies[i].node.position.x += sin(ph + time * 2.5) * 18 * dt
                enemies[i].node.position.y += cos(ph + time * 1.8) * 10 * dt
                enemies[i].node.look(at: sp)
                if enemies[i].shootCD <= 0 && d < 200 {
                    enemyShoot(from: pos); enemies[i].shootCD = max(0.8, 2.0 - difficulty * 0.1)
                }
            default:
                enemies[i].node.position.z += 12 * dt
                enemies[i].node.look(at: sp)
                if enemies[i].shootCD <= 0 && d < 250 {
                    enemyShootSpread(from: pos); enemies[i].shootCD = max(1.0, 2.5 - difficulty * 0.08)
                }
            }
        }
    }

    // MARK: - Spawning
    func spawnEnemyWave() {
        let sz = shipNode.position.z
        let types: [Int]
        if difficulty < 2 { types = [0,0,0,1] }
        else if difficulty < 4 { types = [0,0,1,1,2] }
        else { types = [0,1,1,2,2] }
        let count = rI(1, min(4, Int(difficulty) + 1))
        for _ in 0..<count {
            let t = types[rI(0, types.count-1)]
            let n = buildEnemy(type: t)
            n.position = SCNVector3(rF(-BOUND_X, BOUND_X), rF(-BOUND_Y+2, BOUND_Y),
                                    sz - SPAWN_DIST + rF(-30, 30))
            gameNode.addChildNode(n)
            let hp = t == 0 ? 1 : (t == 1 ? 2 : 5)
            let r: CGFloat = t == 0 ? 0.7 : (t == 1 ? 1.0 : 2.2)
            let spd: CGFloat = t == 0 ? rF(55, 80) : 0
            enemies.append(EnemyData(node: n, type: t, hp: hp, radius: r,
                                     shootCD: rF(0.5, 2.0), phase: rF(0, CGFloat.pi*2), speed: spd))
        }
    }

    func spawnAsteroidCluster() {
        let sz = shipNode.position.z
        for _ in 0..<rI(1,3) {
            let r = rF(1.0, 3.5); let n = buildAsteroid(radius: r)
            n.position = SCNVector3(rF(-BOUND_X*1.2, BOUND_X*1.2), rF(-BOUND_Y, BOUND_Y),
                                    sz - SPAWN_DIST + rF(-50, 50))
            gameNode.addChildNode(n)
            asteroids.append(AsteroidData(node: n, radius: r, hp: r > 2.5 ? 3 : (r > 1.5 ? 2 : 1)))
        }
    }

    func spawnRingGate() {
        let n = buildRing()
        n.position = SCNVector3(rF(-6,6), rF(-3,3), shipNode.position.z - SPAWN_DIST - 50)
        gameNode.addChildNode(n); rings.append(RingData(node: n, collected: false))
    }

    func spawnHealthPickup() {
        let n = buildPickup()
        n.position = SCNVector3(rF(-BOUND_X, BOUND_X), rF(-BOUND_Y+2, BOUND_Y),
                                shipNode.position.z - SPAWN_DIST)
        gameNode.addChildNode(n); pickups.append(PickupData(node: n))
    }

    // MARK: - Collisions
    func checkCollisions() {
        let sp = shipNode.position; let shipR: CGFloat = 1.0

        // Player lasers vs enemies
        for li in (0..<lasers.count).reversed() {
            let lp = lasers[li].node.position; var hit = false
            for ei in (0..<enemies.count).reversed() {
                let ep = enemies[ei].node.position
                if (lp - ep).len < enemies[ei].radius + 0.5 {
                    enemies[ei].hp -= 1
                    if enemies[ei].hp <= 0 {
                        score += enemies[ei].type == 0 ? 50 : (enemies[ei].type == 1 ? 100 : 250)
                        let c = enemies[ei].type == 0 ? cOrange : (enemies[ei].type == 1 ? cMagenta : cPurple)
                        spawnExplosion(at: ep, color: c)
                        enemies[ei].node.removeFromParentNode(); enemies.remove(at: ei)
                    } else {
                        enemies[ei].node.runAction(SCNAction.sequence([
                            SCNAction.fadeOpacity(to: 0.3, duration: 0.06),
                            SCNAction.fadeOpacity(to: 1.0, duration: 0.06)]))
                    }
                    lasers[li].node.removeFromParentNode(); lasers.remove(at: li)
                    hit = true; break
                }
            }
            if hit { continue }
            for ai in (0..<asteroids.count).reversed() {
                if (lp - asteroids[ai].node.position).len < asteroids[ai].radius + 0.5 {
                    asteroids[ai].hp -= 1
                    if asteroids[ai].hp <= 0 {
                        score += 25
                        spawnExplosion(at: asteroids[ai].node.position, color: cOrange, big: false)
                        asteroids[ai].node.removeFromParentNode(); asteroids.remove(at: ai)
                    }
                    lasers[li].node.removeFromParentNode(); lasers.remove(at: li); break
                }
            }
        }

        if invTimer > 0 { return }

        for ai in (0..<asteroids.count).reversed() {
            if (asteroids[ai].node.position - sp).len < asteroids[ai].radius + shipR {
                takeDamage(1)
                spawnExplosion(at: asteroids[ai].node.position, color: cOrange, big: false)
                asteroids[ai].node.removeFromParentNode(); asteroids.remove(at: ai); break
            }
        }
        for ei in (0..<enemies.count).reversed() {
            if (enemies[ei].node.position - sp).len < enemies[ei].radius + shipR {
                takeDamage(1)
                spawnExplosion(at: enemies[ei].node.position, color: cOrange)
                enemies[ei].node.removeFromParentNode(); enemies.remove(at: ei); break
            }
        }
        for li in (0..<eLasers.count).reversed() {
            if (eLasers[li].node.position - sp).len < shipR + 0.5 {
                takeDamage(1)
                eLasers[li].node.removeFromParentNode(); eLasers.remove(at: li); break
            }
        }
        for ri in (0..<rings.count).reversed() {
            if rings[ri].collected { continue }
            let rp = rings[ri].node.position
            if abs(sp.z - rp.z) < 3 && sqrt(pow(sp.x-rp.x,2)+pow(sp.y-rp.y,2)) < 4.5 {
                rings[ri].collected = true; score += 200
                rings[ri].node.runAction(SCNAction.sequence([
                    SCNAction.fadeOut(duration: 0.3), SCNAction.removeFromParentNode()]))
                let b = SKLabelNode(text: "+200"); b.fontName = "Menlo-Bold"; b.fontSize = 28
                b.fontColor = cGold; b.position = CGPoint(x: WIN_W/2, y: WIN_H/2 + 60); b.zPosition = 30
                hudScene.addChild(b)
                b.run(SKAction.sequence([
                    SKAction.group([SKAction.moveBy(x: 0, y: 40, duration: 0.8), SKAction.fadeOut(withDuration: 0.8)]),
                    SKAction.removeFromParent()]))
            }
        }
        for pi in (0..<pickups.count).reversed() {
            if (pickups[pi].node.position - sp).len < 2.0 {
                health = min(maxHealth, health + 1)
                pickups[pi].node.removeFromParentNode(); pickups.remove(at: pi)
                let b = SKLabelNode(text: "+HULL"); b.fontName = "Menlo-Bold"; b.fontSize = 20
                b.fontColor = cGreen; b.position = CGPoint(x: WIN_W/2, y: WIN_H/2 - 60); b.zPosition = 30
                hudScene.addChild(b)
                b.run(SKAction.sequence([
                    SKAction.group([SKAction.moveBy(x: 0, y: 30, duration: 0.6), SKAction.fadeOut(withDuration: 0.6)]),
                    SKAction.removeFromParent()]))
            }
        }
    }

    // MARK: - Damage
    func takeDamage(_ amt: Int) {
        if invTimer > 0 { return }
        health -= amt; shakeAmt = 2.5; invTimer = 1.2
        // Spawn sparks near camera for impact feel
        let spark = SCNNode()
        spark.position = cameraNode.position + SCNVector3(rF(-1,1), rF(-0.5,0.5), -3)
        spark.addParticleSystem(makeExplosionPS(color: cOrange, count: 80, size: 0.08, speed: 8))
        scene.rootNode.addChildNode(spark)
        spark.runAction(SCNAction.sequence([SCNAction.wait(duration: 1), SCNAction.removeFromParentNode()]))
        if health <= 0 { health = 0; doGameOver() }
    }

    func doGameOver() {
        state = "dead"
        spawnExplosion(at: shipNode.position, color: cOrange, big: true)
        spawnExplosion(at: shipNode.position + SCNVector3(1, 0.5, -1), color: cRed, big: true)
        deathTimer = 0; deathHUDShown = false
        crosshair?.isHidden = true; setCockpitVisible(false)
        speedPS.birthRate = 0
        // Remove cockpit
        cockpitNode?.removeFromParentNode(); cockpitNode = nil
        for child in cameraNode.childNodes where child.name == "gunLight" { child.removeFromParentNode() }
    }

    func showDeathHUD() {
        let dn = SKNode(); dn.zPosition = 50
        let t = SKLabelNode(text: "DESTROYED")
        t.fontName = "Menlo-Bold"; t.fontSize = 46; t.fontColor = cRed
        t.position = CGPoint(x: WIN_W/2, y: WIN_H * 0.62); dn.addChild(t)
        let sc = SKLabelNode(text: "Score: \(score)")
        sc.fontName = "Menlo-Bold"; sc.fontSize = 24; sc.fontColor = .white
        sc.position = CGPoint(x: WIN_W/2, y: WIN_H * 0.50); dn.addChild(sc)
        let ds = SKLabelNode(text: "Distance: \(Int(dist))m")
        ds.fontName = "Menlo"; ds.fontSize = 16; ds.fontColor = NSColor(white: 0.6, alpha: 1)
        ds.position = CGPoint(x: WIN_W/2, y: WIN_H * 0.44); dn.addChild(ds)
        let r = SKLabelNode(text: "[ PRESS SPACE TO RETRY ]")
        r.fontName = "Menlo"; r.fontSize = 16; r.fontColor = NSColor(white: 0.5, alpha: 1)
        r.position = CGPoint(x: WIN_W/2, y: WIN_H * 0.32)
        r.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.7), SKAction.fadeAlpha(to: 0.9, duration: 0.7)])))
        dn.addChild(r)
        dn.alpha = 0; dn.run(SKAction.fadeIn(withDuration: 0.5))
        hudScene.addChild(dn); deathNode = dn
    }

    // MARK: - Explosions
    func spawnExplosion(at pos: SCNVector3, color: NSColor, big: Bool = false) {
        let n = SCNNode(); n.position = pos
        n.addParticleSystem(makeExplosionPS(color: color, count: big ? 800 : 350,
                                            size: big ? 0.35 : 0.18, speed: big ? 25 : 15))
        if big {
            let ln = SCNNode(); ln.light = SCNLight()
            ln.light!.type = .omni; ln.light!.color = color; ln.light!.intensity = 2000
            ln.light!.attenuationStartDistance = 5; ln.light!.attenuationEndDistance = 40
            n.addChildNode(ln)
            ln.runAction(SCNAction.sequence([
                SCNAction.wait(duration: 0.15),
                SCNAction.customAction(duration: 0.4) { nd, t in nd.light?.intensity = CGFloat(2000*(1-t/0.4)) }]))
        }
        scene.rootNode.addChildNode(n)
        n.runAction(SCNAction.sequence([SCNAction.wait(duration: 1.5), SCNAction.removeFromParentNode()]))
    }

    // MARK: - Cleanup
    func cleanupObjects() {
        let cutoff = shipNode.position.z + REMOVE_DIST
        for i in (0..<enemies.count).reversed() {
            if enemies[i].node.position.z > cutoff { enemies[i].node.removeFromParentNode(); enemies.remove(at: i) }
        }
        for i in (0..<asteroids.count).reversed() {
            if asteroids[i].node.position.z > cutoff { asteroids[i].node.removeFromParentNode(); asteroids.remove(at: i) }
        }
        for i in (0..<rings.count).reversed() {
            if rings[i].node.position.z > cutoff { rings[i].node.removeFromParentNode(); rings.remove(at: i) }
        }
        for i in (0..<pickups.count).reversed() {
            if pickups[i].node.position.z > cutoff { pickups[i].node.removeFromParentNode(); pickups.remove(at: i) }
        }
    }

    func recycleStars() {
        let camZ = cameraNode.position.z
        for s in stars {
            if s.position.z > camZ + 30 {
                let refZ = state == "playing" ? shipNode.position.z : camZ
                s.position.z = refZ - rF(200, 400)
                s.position.x = rF(-100, 100); s.position.y = rF(-60, 60)
            }
        }
    }

    // MARK: - HUD
    func updateHUD() {
        scoreLabel.text = "\(score)"
        distLabel.text = "\(Int(dist))m"
        let boosting = view.heldKeys.contains(56) || view.heldKeys.contains(60)
        let spd = Int(boosting ? FWD_SPEED * 1.8 : FWD_SPEED)
        speedLabel.text = "SPD \(spd)"
        speedLabel.fontColor = boosting ? cOrange : cCyan
        let pct = CGFloat(health) / CGFloat(maxHealth)
        healthBar.path = CGPath(roundedRect: CGRect(x: 100, y: 55, width: 250 * pct, height: 12),
                                cornerWidth: 2, cornerHeight: 2, transform: nil)
        healthBar.fillColor = pct > 0.5 ? cCyan : (pct > 0.25 ? cGold : cRed)
    }

    func updateRadar() {
        // Remove old dots
        for d in radarDots { d.removeFromParent() }
        radarDots.removeAll()
        let sp = shipNode.position
        let radarRange: CGFloat = 200
        let radarSize: CGFloat = 30
        // Show enemies
        for e in enemies {
            let relX = (e.node.position.x - sp.x) / radarRange * radarSize
            let relZ = (e.node.position.z - sp.z) / radarRange * radarSize
            if abs(relX) < radarSize && abs(relZ) < radarSize {
                let dot = SKShapeNode(circleOfRadius: 2)
                dot.fillColor = e.type == 0 ? cOrange : (e.type == 1 ? cMagenta : cPurple)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: relX, y: relZ) // z maps to y on radar
                radarNode.addChild(dot)
                radarDots.append(dot)
            }
        }
        // Show asteroids as grey dots
        for a in asteroids {
            let relX = (a.node.position.x - sp.x) / radarRange * radarSize
            let relZ = (a.node.position.z - sp.z) / radarRange * radarSize
            if abs(relX) < radarSize && abs(relZ) < radarSize {
                let dot = SKShapeNode(circleOfRadius: 1.5)
                dot.fillColor = NSColor(white: 0.4, alpha: 0.6); dot.strokeColor = .clear
                dot.position = CGPoint(x: relX, y: relZ)
                radarNode.addChild(dot); radarDots.append(dot)
            }
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let controller = GameController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let scr = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        window = NSWindow(contentRect: NSRect(x: (scr.width-WIN_W)/2, y: (scr.height-WIN_H)/2,
                                              width: WIN_W, height: WIN_H),
                          styleMask: [.titled, .closable, .miniaturizable],
                          backing: .buffered, defer: false)
        window.title = "VOID RUNNER // COCKPIT"
        window.backgroundColor = .black
        let gv = GameView(frame: NSRect(x: 0, y: 0, width: WIN_W, height: WIN_H))
        window.contentView = gv
        window.makeKeyAndOrderFront(nil); window.makeFirstResponder(gv)
        controller.setup(gv)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
