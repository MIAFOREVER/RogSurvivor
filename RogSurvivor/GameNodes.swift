import SpriteKit

final class PlayerNode: SKNode {
    private let bodyNode: SKShapeNode
    private let damageFlash = SKShapeNode(circleOfRadius: 27)

    override init() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -19, y: -23))
        path.addCurve(
            to: CGPoint(x: 18, y: -22),
            control1: CGPoint(x: -7, y: -30),
            control2: CGPoint(x: 10, y: -27)
        )
        path.addCurve(
            to: CGPoint(x: 24, y: 13),
            control1: CGPoint(x: 27, y: -11),
            control2: CGPoint(x: 29, y: 4)
        )
        path.addCurve(
            to: CGPoint(x: -9, y: 26),
            control1: CGPoint(x: 12, y: 26),
            control2: CGPoint(x: -1, y: 29)
        )
        path.addCurve(
            to: CGPoint(x: -19, y: -23),
            control1: CGPoint(x: -25, y: 20),
            control2: CGPoint(x: -30, y: -8)
        )

        bodyNode = SKShapeNode(path: path)
        bodyNode.fillColor = SKColor(red: 0.78, green: 0.52, blue: 0.27, alpha: 1)
        bodyNode.strokeColor = SKColor(red: 0.28, green: 0.18, blue: 0.12, alpha: 1)
        bodyNode.lineWidth = 3

        super.init()

        zPosition = 20
        addChild(bodyNode)

        let leftEye = SKShapeNode(circleOfRadius: 3)
        leftEye.fillColor = .gameCream
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: -8, y: 6)
        bodyNode.addChild(leftEye)

        let rightEye = leftEye.copy() as! SKShapeNode
        rightEye.position.x = 9
        bodyNode.addChild(rightEye)

        let leftPupil = SKShapeNode(circleOfRadius: 1.4)
        leftPupil.fillColor = .gameBackground
        leftPupil.strokeColor = .clear
        leftEye.addChild(leftPupil)

        let rightPupil = leftPupil.copy() as! SKShapeNode
        rightEye.addChild(rightPupil)

        let mouth = SKShapeNode()
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -5, y: -7))
        mouthPath.addQuadCurve(
            to: CGPoint(x: 6, y: -6),
            control: CGPoint(x: 1, y: -12)
        )
        mouth.path = mouthPath
        mouth.strokeColor = SKColor(red: 0.28, green: 0.18, blue: 0.12, alpha: 1)
        mouth.lineWidth = 2
        mouth.lineCap = .round
        bodyNode.addChild(mouth)

        for position in [
            CGPoint(x: -15, y: 12),
            CGPoint(x: 15, y: -2),
            CGPoint(x: -8, y: -15)
        ] {
            let spot = SKShapeNode(circleOfRadius: 2.6)
            spot.fillColor = SKColor(red: 0.58, green: 0.36, blue: 0.18, alpha: 0.65)
            spot.strokeColor = .clear
            spot.position = position
            bodyNode.addChild(spot)
        }

        damageFlash.fillColor = .gameCoral
        damageFlash.strokeColor = .clear
        damageFlash.alpha = 0
        damageFlash.zPosition = 4
        addChild(damageFlash)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func face(direction: CGVector) {
        guard direction.length > 0.1 else { return }
        bodyNode.xScale = direction.dx < -0.05 ? -1 : 1
        zRotation = max(-0.12, min(0.12, -direction.dx * 0.12))
    }

    func showDamage() {
        damageFlash.removeAllActions()
        damageFlash.alpha = 0.55
        damageFlash.run(.fadeOut(withDuration: 0.18))
        run(.sequence([
            .scale(to: 1.14, duration: 0.05),
            .scale(to: 1, duration: 0.09)
        ]))
    }
}

enum EnemyArchetype {
    case crawler
    case runner
    case brute
    case spitter
    case splitter
    case juggernaut
    case boss

    var isRanged: Bool {
        self == .spitter || self == .boss
    }

    var isBoss: Bool {
        self == .boss
    }
}

final class EnemyNode: SKNode {
    let archetype: EnemyArchetype
    let movementSpeed: CGFloat
    let contactDamage: CGFloat
    let reward: Int
    let radius: CGFloat
    var attackCooldown = TimeInterval.random(in: 0.6...1.4)

    private(set) var health: CGFloat
    private let maxHealth: CGFloat
    private let bodyNode: SKShapeNode
    private let healthFill: SKSpriteNode

    var healthRatio: CGFloat {
        max(0, health / maxHealth)
    }

    init(wave: Int, archetype forcedArchetype: EnemyArchetype? = nil) {
        let roll = CGFloat.random(in: 0...1)
        let healthScale = 1 + CGFloat(wave - 1) * 0.16
        let damageScale = 1 + CGFloat(wave - 1) * 0.08
        let fillColor: SKColor

        if let forcedArchetype {
            archetype = forcedArchetype
        } else if wave >= 6, roll > 0.93 {
            archetype = .juggernaut
        } else if wave >= 4, roll > 0.84 {
            archetype = .spitter
        } else if wave >= 3, roll > 0.74 {
            archetype = .splitter
        } else if roll < min(0.18 + CGFloat(wave) * 0.01, 0.34) {
            archetype = .runner
        } else if roll > 0.78, wave >= 2 {
            archetype = .brute
        } else {
            archetype = .crawler
        }

        switch archetype {
        case .runner:
            radius = 17
            maxHealth = 18 * healthScale
            movementSpeed = 105 + CGFloat(wave) * 1.5
            contactDamage = 8 * damageScale
            reward = 1
            fillColor = .gameGreen
        case .brute:
            radius = 29
            maxHealth = 72 * healthScale
            movementSpeed = 48 + CGFloat(wave)
            contactDamage = 18 * damageScale
            reward = 3
            fillColor = .gameCoral
        case .spitter:
            radius = 21
            maxHealth = 42 * healthScale
            movementSpeed = 58 + CGFloat(wave)
            contactDamage = 9 * damageScale
            reward = 3
            fillColor = .gameCyan
        case .splitter:
            radius = 24
            maxHealth = 48 * healthScale
            movementSpeed = 76 + CGFloat(wave)
            contactDamage = 12 * damageScale
            reward = 3
            fillColor = .gamePink
        case .juggernaut:
            radius = 34
            maxHealth = 135 * healthScale
            movementSpeed = 42 + CGFloat(wave) * 0.8
            contactDamage = 24 * damageScale
            reward = 6
            fillColor = .gameBlue
        case .boss:
            radius = 52
            maxHealth = 620 * (1 + CGFloat(wave - 5) * 0.22)
            movementSpeed = 40 + CGFloat(wave) * 0.5
            contactDamage = 30 * damageScale
            reward = 24
            fillColor = .gameYellow
        case .crawler:
            radius = 22
            maxHealth = 34 * healthScale
            movementSpeed = 70 + CGFloat(wave) * 1.2
            contactDamage = 12 * damageScale
            reward = 2
            fillColor = .gamePurple
        }

        health = maxHealth

        let enemyPath = CGMutablePath()
        enemyPath.move(to: CGPoint(x: -radius * 0.85, y: -radius * 0.52))
        enemyPath.addCurve(
            to: CGPoint(x: radius * 0.82, y: -radius * 0.58),
            control1: CGPoint(x: -radius * 0.42, y: -radius),
            control2: CGPoint(x: radius * 0.46, y: -radius * 0.92)
        )
        enemyPath.addCurve(
            to: CGPoint(x: radius * 0.62, y: radius * 0.72),
            control1: CGPoint(x: radius * 1.08, y: -radius * 0.1),
            control2: CGPoint(x: radius, y: radius * 0.55)
        )
        enemyPath.addCurve(
            to: CGPoint(x: -radius * 0.68, y: radius * 0.68),
            control1: CGPoint(x: radius * 0.1, y: radius * 1.02),
            control2: CGPoint(x: -radius * 0.3, y: radius)
        )
        enemyPath.closeSubpath()

        bodyNode = SKShapeNode(path: enemyPath)
        bodyNode.fillColor = fillColor
        bodyNode.strokeColor = fillColor.withAlphaComponent(0.45)
        bodyNode.glowWidth = 2
        bodyNode.lineWidth = 3

        healthFill = SKSpriteNode(color: .gameGreen, size: CGSize(width: radius * 1.6, height: 3))
        healthFill.anchorPoint = CGPoint(x: 0, y: 0.5)

        super.init()

        name = archetype.isBoss ? "boss" : "enemy"
        zPosition = 12
        addChild(bodyNode)

        let eyeColor = SKColor.gameBackground
        for x in [-radius * 0.3, radius * 0.3] {
            let eye = SKShapeNode(circleOfRadius: max(2.5, radius * 0.13))
            eye.fillColor = eyeColor
            eye.strokeColor = .clear
            eye.position = CGPoint(x: x, y: radius * 0.14)
            bodyNode.addChild(eye)
        }

        if archetype.isRanged {
            let mark = SKLabelNode(fontNamed: "AvenirNext-Bold")
            mark.text = archetype.isBoss ? "☣" : "•"
            mark.fontSize = archetype.isBoss ? 24 : 18
            mark.fontColor = .gameBackground
            mark.verticalAlignmentMode = .center
            mark.position.y = -radius * 0.28
            bodyNode.addChild(mark)
        }

        let healthBack = SKSpriteNode(
            color: SKColor.black.withAlphaComponent(0.45),
            size: CGSize(width: radius * 1.6, height: 3)
        )
        healthBack.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthBack.position = CGPoint(x: -radius * 0.8, y: radius + 7)
        healthBack.zPosition = 2
        addChild(healthBack)

        healthFill.position = healthBack.position
        healthFill.zPosition = 3
        addChild(healthFill)

        run(.repeatForever(.sequence([
            .scaleY(to: 0.94, duration: 0.32),
            .scaleY(to: 1.04, duration: 0.32)
        ])))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult
    func takeDamage(_ amount: CGFloat) -> Bool {
        health = max(0, health - amount)
        healthFill.xScale = health / maxHealth

        bodyNode.removeAction(forKey: "damageFlash")
        let originalColor = bodyNode.fillColor
        bodyNode.run(.sequence([
            .run { [weak bodyNode] in bodyNode?.fillColor = .white },
            .wait(forDuration: 0.035),
            .run { [weak bodyNode] in bodyNode?.fillColor = originalColor }
        ]), withKey: "damageFlash")

        return health <= 0
    }
}

final class ProjectileNode: SKShapeNode {
    let damage: CGFloat
    var velocity: CGVector
    var lifetime: TimeInterval
    let hitRadius: CGFloat
    var pierceRemaining: Int
    let splashRadius: CGFloat
    let weaponType: WeaponType
    let isCritical: Bool
    var hitEnemies: Set<ObjectIdentifier> = []

    init(
        damage: CGFloat,
        velocity: CGVector,
        weaponType: WeaponType = .pulseCannon,
        pierce: Int = 1,
        splashRadius: CGFloat = 0,
        lifetime: TimeInterval = 1.7,
        sizeScale: CGFloat = 1,
        isCritical: Bool = false
    ) {
        self.damage = damage
        self.velocity = velocity
        self.weaponType = weaponType
        self.pierceRemaining = pierce
        self.splashRadius = splashRadius
        self.lifetime = lifetime
        self.hitRadius = 7 * sizeScale
        self.isCritical = isCritical
        super.init()

        let projectilePath = CGMutablePath()
        projectilePath.move(to: CGPoint(x: 9, y: 0))
        projectilePath.addLine(to: CGPoint(x: -5, y: 5))
        projectilePath.addLine(to: CGPoint(x: -3, y: 0))
        projectilePath.addLine(to: CGPoint(x: -5, y: -5))
        projectilePath.closeSubpath()
        path = projectilePath
        fillColor = weaponType.color
        strokeColor = .white
        lineWidth = 1
        glowWidth = 3
        setScale(sizeScale)
        zPosition = 16
        name = "projectile"
        zRotation = atan2(velocity.dy, velocity.dx)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HostileProjectileNode: SKShapeNode {
    let damage: CGFloat
    let hitRadius: CGFloat
    var velocity: CGVector
    var lifetime: TimeInterval = 4

    init(damage: CGFloat, velocity: CGVector, isBossShot: Bool = false) {
        self.damage = damage
        self.velocity = velocity
        hitRadius = isBossShot ? 10 : 7
        super.init()

        path = CGPath(
            ellipseIn: CGRect(
                x: -hitRadius,
                y: -hitRadius,
                width: hitRadius * 2,
                height: hitRadius * 2
            ),
            transform: nil
        )
        fillColor = isBossShot ? .gameCoral : .gamePurple
        strokeColor = .white
        lineWidth = 1.5
        glowWidth = isBossShot ? 7 : 4
        zPosition = 15
        name = "hostileProjectile"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HazardNode: SKShapeNode {
    let hazardRadius: CGFloat
    private(set) var isHot = false

    init(radius: CGFloat, color: SKColor) {
        hazardRadius = radius
        super.init()

        path = CGPath(
            ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2),
            transform: nil
        )
        fillColor = color.withAlphaComponent(0.12)
        strokeColor = color.withAlphaComponent(0.42)
        lineWidth = 2
        zPosition = 2
        name = "hazard"

        run(.repeatForever(.sequence([
            .run { [weak self] in
                self?.isHot = false
                self?.fillColor = color.withAlphaComponent(0.1)
                self?.strokeColor = color.withAlphaComponent(0.35)
            },
            .wait(forDuration: 2.2),
            .run { [weak self] in
                self?.fillColor = color.withAlphaComponent(0.28)
                self?.strokeColor = color.withAlphaComponent(0.9)
            },
            .wait(forDuration: 0.7),
            .run { [weak self] in
                self?.isHot = true
                self?.fillColor = color.withAlphaComponent(0.52)
                self?.glowWidth = 8
            },
            .wait(forDuration: 1.15),
            .run { [weak self] in
                self?.isHot = false
                self?.glowWidth = 0
            }
        ])))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PickupNode: SKShapeNode {
    let value: Int
    let pickupRadius: CGFloat = 8

    init(value: Int) {
        self.value = value
        super.init()

        path = CGPath(
            roundedRect: CGRect(x: -6, y: -6, width: 12, height: 12),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        fillColor = .gameCyan
        strokeColor = .white
        lineWidth = 1.5
        glowWidth = 4
        zPosition = 8
        name = "pickup"

        run(.repeatForever(.sequence([
            .rotate(byAngle: .pi / 2, duration: 0.45),
            .rotate(byAngle: .pi / 2, duration: 0.45)
        ])))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class VirtualJoystickNode: SKNode {
    private let base = SKShapeNode(circleOfRadius: 52)
    private let knob = SKShapeNode(circleOfRadius: 23)
    private(set) var vector = CGVector.zero

    override init() {
        super.init()

        base.fillColor = SKColor.white.withAlphaComponent(0.09)
        base.strokeColor = SKColor.white.withAlphaComponent(0.28)
        base.lineWidth = 2
        addChild(base)

        knob.fillColor = SKColor.gameCream.withAlphaComponent(0.38)
        knob.strokeColor = SKColor.white.withAlphaComponent(0.6)
        knob.lineWidth = 2
        addChild(knob)

        zPosition = 90
        alpha = 0
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func begin(at point: CGPoint) {
        position = point
        knob.position = .zero
        vector = .zero
        alpha = 1
    }

    func move(to point: CGPoint) {
        let offset = point - position
        let limitedLength = min(46, offset.length)
        let direction = offset.normalized
        knob.position = CGPoint(
            x: direction.dx * limitedLength,
            y: direction.dy * limitedLength
        )
        vector = direction * min(1, offset.length / 28)
    }

    func end() {
        vector = .zero
        knob.position = .zero
        run(.fadeOut(withDuration: 0.12))
    }
}

final class HUDNode: SKNode {
    private let healthFill = SKSpriteNode(color: .gameGreen, size: CGSize(width: 156, height: 12))
    private let healthLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let waveLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let timerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let pauseButton = SKShapeNode(circleOfRadius: 20)
    private let bossBack = SKSpriteNode(
        color: SKColor.black.withAlphaComponent(0.55),
        size: CGSize(width: 184, height: 7)
    )
    private let bossFill = SKSpriteNode(color: .gameCoral, size: CGSize(width: 180, height: 5))
    private let bossLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")

    override init() {
        super.init()

        zPosition = 100
        name = "hud"

        let healthBack = SKShapeNode(
            rectOf: CGSize(width: 164, height: 20),
            cornerRadius: 10
        )
        healthBack.fillColor = SKColor.black.withAlphaComponent(0.42)
        healthBack.strokeColor = .gameBorder
        healthBack.lineWidth = 1.5
        healthBack.position = CGPoint(x: 100, y: 0)
        addChild(healthBack)

        healthFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthFill.position = CGPoint(x: 18, y: 0)
        healthFill.zPosition = 1
        addChild(healthFill)

        healthLabel.fontSize = 11
        healthLabel.fontColor = .white
        healthLabel.verticalAlignmentMode = .center
        healthLabel.horizontalAlignmentMode = .center
        healthLabel.position = CGPoint(x: 100, y: 0)
        healthLabel.zPosition = 2
        addChild(healthLabel)

        waveLabel.fontSize = 17
        waveLabel.fontColor = .gameCream
        waveLabel.horizontalAlignmentMode = .center
        waveLabel.verticalAlignmentMode = .center
        addChild(waveLabel)

        timerLabel.fontSize = 28
        timerLabel.fontColor = .gameYellow
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .center
        timerLabel.position.y = -27
        addChild(timerLabel)

        scoreLabel.fontSize = 14
        scoreLabel.fontColor = .gameCyan
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        addChild(scoreLabel)

        pauseButton.name = "pauseButton"
        pauseButton.fillColor = .gamePanel
        pauseButton.strokeColor = .gameBorder
        pauseButton.lineWidth = 1.5
        addChild(pauseButton)

        let pauseLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pauseLabel.name = "pauseButton"
        pauseLabel.text = "Ⅱ"
        pauseLabel.fontSize = 15
        pauseLabel.fontColor = .gameCream
        pauseLabel.verticalAlignmentMode = .center
        pauseLabel.horizontalAlignmentMode = .center
        pauseButton.addChild(pauseLabel)

        bossBack.position.y = -53
        bossBack.isHidden = true
        addChild(bossBack)

        bossFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        bossFill.position = CGPoint(x: -90, y: -53)
        bossFill.isHidden = true
        bossFill.zPosition = 1
        addChild(bossFill)

        bossLabel.text = "霉潮巨像"
        bossLabel.fontSize = 9
        bossLabel.fontColor = .gameCoral
        bossLabel.verticalAlignmentMode = .center
        bossLabel.position.y = -65
        bossLabel.isHidden = true
        addChild(bossLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout(for sceneSize: CGSize) {
        position = CGPoint(x: 0, y: sceneSize.height - 54)
        waveLabel.position.x = sceneSize.width * 0.5
        timerLabel.position.x = sceneSize.width * 0.5
        bossBack.position.x = sceneSize.width * 0.5
        bossFill.position.x = sceneSize.width * 0.5 - 90
        bossLabel.position.x = sceneSize.width * 0.5
        scoreLabel.position.x = sceneSize.width - 58
        pauseButton.position = CGPoint(x: sceneSize.width - 26, y: 0)
    }

    func update(
        health: CGFloat,
        maxHealth: CGFloat,
        wave: Int,
        remainingTime: TimeInterval,
        score: Int,
        isClearing: Bool,
        bossHealth: CGFloat? = nil
    ) {
        let ratio = max(0, min(1, health / maxHealth))
        healthFill.xScale = ratio
        healthFill.color = ratio > 0.5 ? .gameGreen : (ratio > 0.25 ? .gameYellow : .gameCoral)
        healthLabel.text = "\(Int(ceil(health))) / \(Int(maxHealth))"
        waveLabel.text = "第 \(wave) 波"
        timerLabel.text = isClearing ? "清理敌人" : "\(Int(ceil(max(0, remainingTime))))"
        timerLabel.fontSize = isClearing ? 16 : 28
        scoreLabel.text = "◆ \(score)"

        let hasBoss = bossHealth != nil
        bossBack.isHidden = !hasBoss
        bossFill.isHidden = !hasBoss
        bossLabel.isHidden = !hasBoss
        bossFill.xScale = max(0, min(1, bossHealth ?? 0))
    }
}

final class MenuButtonNode: SKShapeNode {
    init(title: String, name: String, width: CGFloat, color: SKColor = .gameYellow) {
        super.init()

        self.name = name
        path = CGPath(
            roundedRect: CGRect(x: -width / 2, y: -27, width: width, height: 54),
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )
        fillColor = color
        strokeColor = .white.withAlphaComponent(0.35)
        lineWidth = 2

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = name
        label.text = title
        label.fontSize = 19
        label.fontColor = .gameBackground
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class UpgradeCardNode: SKShapeNode {
    let upgrade: Upgrade

    init(upgrade: Upgrade, index: Int, width: CGFloat) {
        self.upgrade = upgrade
        super.init()

        name = "upgrade_\(index)"
        path = CGPath(
            roundedRect: CGRect(x: -width / 2, y: -45, width: width, height: 90),
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )
        fillColor = .gamePanel
        strokeColor = upgrade.color
        lineWidth = 2
        glowWidth = 1

        let iconBack = SKShapeNode(circleOfRadius: 26)
        iconBack.name = name
        iconBack.fillColor = upgrade.color.withAlphaComponent(0.18)
        iconBack.strokeColor = upgrade.color
        iconBack.lineWidth = 1.5
        iconBack.position.x = -width / 2 + 45
        addChild(iconBack)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        icon.name = name
        icon.text = upgrade.symbol
        icon.fontSize = 25
        icon.fontColor = upgrade.color
        icon.verticalAlignmentMode = .center
        icon.horizontalAlignmentMode = .center
        iconBack.addChild(icon)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.name = name
        title.text = upgrade.title
        title.fontSize = 18
        title.fontColor = .gameCream
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: -width / 2 + 84, y: 13)
        addChild(title)

        let detail = SKLabelNode(fontNamed: "AvenirNext-Medium")
        detail.name = name
        detail.text = upgrade.detail
        detail.fontSize = 14
        detail.fontColor = SKColor.white.withAlphaComponent(0.68)
        detail.horizontalAlignmentMode = .left
        detail.verticalAlignmentMode = .center
        detail.position = CGPoint(x: -width / 2 + 84, y: -15)
        addChild(detail)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SelectionCardNode: SKShapeNode {
    init(
        title: String,
        subtitle: String,
        symbol: String,
        color: SKColor,
        name: String,
        size: CGSize,
        isLocked: Bool = false,
        footer: String? = nil
    ) {
        super.init()

        self.name = name
        path = CGPath(
            roundedRect: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ),
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )
        fillColor = .gamePanel
        strokeColor = isLocked ? .gameBorder : color
        lineWidth = 2
        alpha = isLocked ? 0.58 : 1

        let iconBack = SKShapeNode(circleOfRadius: min(26, size.height * 0.22))
        iconBack.name = name
        iconBack.fillColor = color.withAlphaComponent(isLocked ? 0.08 : 0.18)
        iconBack.strokeColor = isLocked ? .gameBorder : color
        iconBack.position = CGPoint(x: -size.width / 2 + 38, y: 8)
        addChild(iconBack)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        icon.name = name
        icon.text = isLocked ? "×" : symbol
        icon.fontSize = 22
        icon.fontColor = isLocked ? .gameBorder : color
        icon.verticalAlignmentMode = .center
        iconBack.addChild(icon)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.name = name
        titleLabel.text = title
        titleLabel.fontSize = 16
        titleLabel.fontColor = .gameCream
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: -size.width / 2 + 73, y: 18)
        addChild(titleLabel)

        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitleLabel.name = name
        subtitleLabel.text = subtitle
        subtitleLabel.fontSize = 10
        subtitleLabel.fontColor = .white.withAlphaComponent(0.58)
        subtitleLabel.horizontalAlignmentMode = .left
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: -size.width / 2 + 73, y: -8)
        subtitleLabel.preferredMaxLayoutWidth = max(70, size.width - 84)
        subtitleLabel.numberOfLines = 2
        addChild(subtitleLabel)

        if let footer {
            let footerLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            footerLabel.name = name
            footerLabel.text = footer
            footerLabel.fontSize = 9
            footerLabel.fontColor = isLocked ? .gameCoral : color
            footerLabel.horizontalAlignmentMode = .right
            footerLabel.verticalAlignmentMode = .center
            footerLabel.position = CGPoint(x: size.width / 2 - 12, y: -size.height / 2 + 12)
            addChild(footerLabel)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ShopCardNode: SKShapeNode {
    init(offer: ShopOffer, index: Int, width: CGFloat, canAfford: Bool) {
        super.init()

        name = "shopOffer_\(index)"
        path = CGPath(
            roundedRect: CGRect(x: -width / 2, y: -45, width: width, height: 90),
            cornerWidth: 17,
            cornerHeight: 17,
            transform: nil
        )
        fillColor = .gamePanel
        strokeColor = offer.kind.color.withAlphaComponent(canAfford ? 1 : 0.35)
        lineWidth = 2
        alpha = canAfford ? 1 : 0.66

        let iconBack = SKShapeNode(circleOfRadius: 25)
        iconBack.name = name
        iconBack.fillColor = offer.kind.color.withAlphaComponent(0.16)
        iconBack.strokeColor = offer.kind.color
        iconBack.position.x = -width / 2 + 42
        addChild(iconBack)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        icon.name = name
        icon.text = offer.kind.symbol
        icon.fontSize = 23
        icon.fontColor = offer.kind.color
        icon.verticalAlignmentMode = .center
        iconBack.addChild(icon)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.name = name
        title.text = offer.kind.title
        title.fontSize = 17
        title.fontColor = .gameCream
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: -width / 2 + 78, y: 15)
        addChild(title)

        let detail = SKLabelNode(fontNamed: "AvenirNext-Medium")
        detail.name = name
        detail.text = offer.kind.detail
        detail.fontSize = 11
        detail.fontColor = .white.withAlphaComponent(0.58)
        detail.horizontalAlignmentMode = .left
        detail.verticalAlignmentMode = .center
        detail.position = CGPoint(x: -width / 2 + 78, y: -13)
        addChild(detail)

        let price = SKLabelNode(fontNamed: "AvenirNext-Bold")
        price.name = name
        price.text = "◆ \(offer.price)"
        price.fontSize = 15
        price.fontColor = canAfford ? .gameCyan : .gameCoral
        price.horizontalAlignmentMode = .right
        price.verticalAlignmentMode = .center
        price.position = CGPoint(x: width / 2 - 15, y: 15)
        addChild(price)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
