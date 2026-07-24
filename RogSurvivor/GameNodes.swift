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

enum EnemyArchetype: CaseIterable {
    case crawler
    case runner
    case brute
    case spitter
    case splitter
    case juggernaut
    case charger
    case breeder
    case shielder
    case sniper
    case phaser
    case parasite
    case mortar
    case absorber
    case mimic
    case bomber
    case boss

    var isRanged: Bool {
        switch self {
        case .spitter, .sniper, .mortar, .boss: true
        default: false
        }
    }

    var isBoss: Bool {
        self == .boss
    }

    var title: String {
        switch self {
        case .crawler: "爬行体"
        case .runner: "疾行体"
        case .brute: "蛮力体"
        case .spitter: "喷吐体"
        case .splitter: "分裂体"
        case .juggernaut: "镇压体"
        case .charger: "冲锋体"
        case .breeder: "培育体"
        case .shielder: "护盾体"
        case .sniper: "狙击体"
        case .phaser: "相位体"
        case .parasite: "寄生体"
        case .mortar: "轰击体"
        case .absorber: "吸附体"
        case .mimic: "伪装箱"
        case .bomber: "自爆体"
        case .boss: "霉潮首领"
        }
    }

    var threatCost: CGFloat {
        switch self {
        case .crawler, .runner: 1
        case .spitter, .mimic, .bomber: 2
        case .brute, .splitter, .charger, .parasite: 3
        case .juggernaut, .sniper, .phaser, .absorber: 4
        case .breeder, .shielder, .mortar: 5
        case .boss: 20
        }
    }

    var unlockWave: Int {
        switch self {
        case .crawler: 1
        case .runner: 2
        case .splitter: 3
        case .spitter: 4
        case .brute: 2
        case .juggernaut: 6
        case .charger: 7
        case .breeder: 8
        case .shielder: 11
        case .sniper: 12
        case .phaser: 13
        case .parasite: 11
        case .mortar: 14
        case .absorber: 9
        case .mimic: 4
        case .bomber: 7
        case .boss: 5
        }
    }
}

enum EliteAffix: String, CaseIterable {
    case frenzy
    case shell
    case vampiric
    case swift
    case proliferating
    case volatile
    case jammer
    case commander

    var symbol: String {
        switch self {
        case .frenzy: "!"
        case .shell: "⬡"
        case .vampiric: "♦"
        case .swift: "➤"
        case .proliferating: "Ⅱ"
        case .volatile: "◉"
        case .jammer: "⌁"
        case .commander: "♛"
        }
    }

    var color: SKColor {
        switch self {
        case .frenzy, .vampiric: .gameCoral
        case .shell: .gameBlue
        case .swift: .gameCyan
        case .proliferating, .jammer: .gamePurple
        case .volatile: .gameYellow
        case .commander: .gameGreen
        }
    }
}

enum StatusKind: Hashable {
    case burning
    case shocked
    case corrosion
    case chilled
    case marked
    case spored
}

private struct StatusRuntime {
    var stacks: Int
    var remaining: TimeInterval
    var potency: CGFloat
}

final class EnemyNode: SKNode {
    let archetype: EnemyArchetype
    let eliteAffix: EliteAffix?
    let movementSpeed: CGFloat
    let contactDamage: CGFloat
    let reward: Int
    let radius: CGFloat
    var attackCooldown = TimeInterval.random(in: 0.6...1.4)
    var behaviorCooldown = TimeInterval.random(in: 1.2...2.8)
    var isPhased = false
    private var frozenRemaining: TimeInterval = 0

    private(set) var health: CGFloat
    private let maxHealth: CGFloat
    private var baseArmor: CGFloat
    private var statuses: [StatusKind: StatusRuntime] = [:]
    private let bodyNode: SKShapeNode
    private let healthFill: SKSpriteNode

    var healthRatio: CGFloat {
        max(0, health / maxHealth)
    }

    var isElite: Bool { eliteAffix != nil }

    var speedMultiplier: CGFloat {
        if frozenRemaining > 0 {
            return 0
        }
        let chilled = statuses[.chilled]?.stacks ?? 0
        let chillPenalty = min(0.4, CGFloat(chilled) * 0.08)
        let frenzyBonus = eliteAffix == .frenzy && healthRatio < 0.5 ? 0.40 : 0
        return max(0.35, 1 - chillPenalty + frenzyBonus)
    }

    var damageTakenMultiplier: CGFloat {
        statuses[.marked] == nil ? 1 : 1.12
    }

    init(
        wave: Int,
        archetype forcedArchetype: EnemyArchetype? = nil,
        arena: ArenaType = .scrapOrbit,
        threat: ThreatLevel = .calm,
        settings: GameSettings = GameSettings(),
        eliteAffix: EliteAffix? = nil
    ) {
        let roll = CGFloat.random(in: 0...1)
        let healthScale = 1 + CGFloat(wave - 1) * 0.16
        let damageScale = 1 + CGFloat(wave - 1) * 0.08
        let fillColor: SKColor
        self.eliteAffix = eliteAffix

        if let forcedArchetype {
            archetype = forcedArchetype
        } else {
            let candidates = EnemyArchetype.allCases.filter {
                !$0.isBoss && $0.unlockWave <= wave
            }
            let weightedIndex = min(
                candidates.count - 1,
                Int(pow(roll, 1.8) * CGFloat(candidates.count))
            )
            archetype = candidates[max(0, weightedIndex)]
        }

        let healthMultiplier = threat.enemyHealthMultiplier
            * settings.enemyHealthScale
            * (eliteAffix == nil ? 1 : 2.8)
        let damageMultiplier = threat.enemyDamageMultiplier
            * settings.enemyDamageScale
            * (eliteAffix == nil ? 1 : 1.35)
        let speedMultiplier = threat.enemySpeedMultiplier
            * settings.enemySpeedScale
            * arena.enemySpeedMultiplier
            * (eliteAffix == .swift ? 1.35 : 1)
        let rewardMultiplier = eliteAffix == nil ? 1 : 4

        switch archetype {
        case .runner:
            radius = 17
            maxHealth = 18 * healthScale * healthMultiplier
            movementSpeed = (105 + CGFloat(wave) * 1.5) * speedMultiplier
            contactDamage = 8 * damageScale * damageMultiplier
            reward = 1 * rewardMultiplier
            fillColor = .gameGreen
        case .brute:
            radius = 29
            maxHealth = 72 * healthScale * healthMultiplier
            movementSpeed = (48 + CGFloat(wave)) * speedMultiplier
            contactDamage = 18 * damageScale * damageMultiplier
            reward = 3 * rewardMultiplier
            fillColor = .gameCoral
        case .spitter:
            radius = 21
            maxHealth = 42 * healthScale * healthMultiplier
            movementSpeed = (58 + CGFloat(wave)) * speedMultiplier
            contactDamage = 9 * damageScale * damageMultiplier
            reward = 3 * rewardMultiplier
            fillColor = .gameCyan
        case .splitter:
            radius = 24
            maxHealth = 48 * healthScale * healthMultiplier
            movementSpeed = (76 + CGFloat(wave)) * speedMultiplier
            contactDamage = 12 * damageScale * damageMultiplier
            reward = 3 * rewardMultiplier
            fillColor = .gamePink
        case .juggernaut:
            radius = 34
            maxHealth = 135 * healthScale * healthMultiplier
            movementSpeed = (42 + CGFloat(wave) * 0.8) * speedMultiplier
            contactDamage = 24 * damageScale * damageMultiplier
            reward = 6 * rewardMultiplier
            fillColor = .gameBlue
        case .charger:
            radius = 22
            maxHealth = 52 * healthScale * healthMultiplier
            movementSpeed = (74 + CGFloat(wave)) * speedMultiplier
            contactDamage = 20 * damageScale * damageMultiplier
            reward = 3 * rewardMultiplier
            fillColor = .gameYellow
        case .breeder:
            radius = 31
            maxHealth = 105 * healthScale * healthMultiplier
            movementSpeed = (42 + CGFloat(wave) * 0.5) * speedMultiplier
            contactDamage = 12 * damageScale * damageMultiplier
            reward = 6 * rewardMultiplier
            fillColor = .gamePink
        case .shielder:
            radius = 28
            maxHealth = 95 * healthScale * healthMultiplier
            movementSpeed = (48 + CGFloat(wave) * 0.5) * speedMultiplier
            contactDamage = 14 * damageScale * damageMultiplier
            reward = 6 * rewardMultiplier
            fillColor = .gameBlue
        case .sniper:
            radius = 19
            maxHealth = 45 * healthScale * healthMultiplier
            movementSpeed = (56 + CGFloat(wave) * 0.4) * speedMultiplier
            contactDamage = 10 * damageScale * damageMultiplier
            reward = 5 * rewardMultiplier
            fillColor = .gameCyan
        case .phaser:
            radius = 21
            maxHealth = 58 * healthScale * healthMultiplier
            movementSpeed = (78 + CGFloat(wave) * 0.6) * speedMultiplier
            contactDamage = 14 * damageScale * damageMultiplier
            reward = 5 * rewardMultiplier
            fillColor = .gamePurple
        case .parasite:
            radius = 18
            maxHealth = 38 * healthScale * healthMultiplier
            movementSpeed = (92 + CGFloat(wave)) * speedMultiplier
            contactDamage = 9 * damageScale * damageMultiplier
            reward = 4 * rewardMultiplier
            fillColor = .gameGreen
        case .mortar:
            radius = 25
            maxHealth = 74 * healthScale * healthMultiplier
            movementSpeed = (44 + CGFloat(wave) * 0.3) * speedMultiplier
            contactDamage = 12 * damageScale * damageMultiplier
            reward = 6 * rewardMultiplier
            fillColor = .gameCoral
        case .absorber:
            radius = 26
            maxHealth = 82 * healthScale * healthMultiplier
            movementSpeed = (55 + CGFloat(wave) * 0.5) * speedMultiplier
            contactDamage = 15 * damageScale * damageMultiplier
            reward = 5 * rewardMultiplier
            fillColor = .gameYellow
        case .mimic:
            radius = 20
            maxHealth = 36 * healthScale * healthMultiplier
            movementSpeed = (86 + CGFloat(wave)) * speedMultiplier
            contactDamage = 16 * damageScale * damageMultiplier
            reward = 4 * rewardMultiplier
            fillColor = .gameYellow
        case .bomber:
            radius = 20
            maxHealth = 30 * healthScale * healthMultiplier
            movementSpeed = (98 + CGFloat(wave)) * speedMultiplier
            contactDamage = 23 * damageScale * damageMultiplier
            reward = 3 * rewardMultiplier
            fillColor = .gameCoral
        case .boss:
            radius = 52
            maxHealth = 620
                * (1 + CGFloat(wave - 5) * 0.22)
                * threat.enemyHealthMultiplier
                * settings.enemyHealthScale
            movementSpeed = (40 + CGFloat(wave) * 0.5)
                * threat.enemySpeedMultiplier
                * settings.enemySpeedScale
            contactDamage = 30 * damageScale
                * threat.enemyDamageMultiplier
                * settings.enemyDamageScale
            reward = 24
            fillColor = arena.color
        case .crawler:
            radius = 22
            maxHealth = 34 * healthScale * healthMultiplier
            movementSpeed = (70 + CGFloat(wave) * 1.2) * speedMultiplier
            contactDamage = 12 * damageScale * damageMultiplier
            reward = 2 * rewardMultiplier
            fillColor = .gamePurple
        }

        baseArmor = archetype == .juggernaut ? 7 : (eliteAffix == .shell ? 8 : 0)
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

        if let eliteAffix {
            let eliteRing = SKShapeNode(circleOfRadius: radius + 5)
            eliteRing.strokeColor = eliteAffix.color
            eliteRing.fillColor = .clear
            eliteRing.lineWidth = 3
            eliteRing.glowWidth = 5
            eliteRing.zPosition = -1
            bodyNode.addChild(eliteRing)

            let affixLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            affixLabel.text = eliteAffix.symbol
            affixLabel.fontSize = 12
            affixLabel.fontColor = eliteAffix.color
            affixLabel.position = CGPoint(x: 0, y: radius + 15)
            affixLabel.verticalAlignmentMode = .center
            bodyNode.addChild(affixLabel)
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
        guard !isPhased else { return false }
        let corrosion = CGFloat(statuses[.corrosion]?.stacks ?? 0)
        let armor = baseArmor - corrosion
        let armorMultiplier: CGFloat
        if armor > 0 {
            armorMultiplier = 1 - min(0.65, armor / (armor + 15))
        } else {
            armorMultiplier = 1 + abs(armor) * 0.04
        }
        let adjusted = max(1, amount * armorMultiplier * damageTakenMultiplier)
        health = max(0, health - adjusted)
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

    func heal(_ amount: CGFloat) {
        health = min(maxHealth, health + max(0, amount))
        healthFill.xScale = health / maxHealth
    }

    func applyStatus(
        _ kind: StatusKind,
        stacks: Int = 1,
        duration: TimeInterval,
        potency: CGFloat,
        maximumBonus: Int = 0
    ) {
        var runtime = statuses[kind] ?? StatusRuntime(stacks: 0, remaining: 0, potency: 0)
        let maximum: Int
        switch kind {
        case .burning: maximum = 10
        case .shocked, .chilled: maximum = 5
        case .corrosion: maximum = 8
        case .marked, .spored: maximum = 1
        }
        runtime.stacks = min(maximum + maximumBonus, runtime.stacks + stacks)
        runtime.remaining = max(runtime.remaining, duration)
        runtime.potency = max(runtime.potency, potency)
        statuses[kind] = runtime
    }

    func statusStacks(_ kind: StatusKind) -> Int {
        statuses[kind]?.stacks ?? 0
    }

    var hasAnyStatus: Bool {
        !statuses.isEmpty
    }

    func consumeStatus(_ kind: StatusKind) -> (stacks: Int, potency: CGFloat) {
        guard let runtime = statuses.removeValue(forKey: kind) else {
            return (0, 0)
        }
        return (runtime.stacks, runtime.potency)
    }

    func freeze(for duration: TimeInterval) {
        frozenRemaining = max(frozenRemaining, duration)
    }

    func updateStatuses(
        _ deltaTime: TimeInterval,
        burnAmplification: CGFloat = 0
    ) -> CGFloat {
        frozenRemaining = max(0, frozenRemaining - deltaTime)
        var expired: [StatusKind] = []
        for kind in Array(statuses.keys) {
            guard var runtime = statuses[kind] else { continue }
            runtime.remaining -= deltaTime
            if runtime.remaining <= 0 {
                expired.append(kind)
            } else {
                statuses[kind] = runtime
            }
        }
        expired.forEach { statuses.removeValue(forKey: $0) }

        let burn = statuses[.burning]
        let spore = statuses[.spored]
        let burnStacks = CGFloat(burn?.stacks ?? 0)
        let burnDamage = burnStacks
            * (burn?.potency ?? 0)
            * (1 + burnStacks * burnAmplification)
        let sporeDamage = CGFloat(spore?.stacks ?? 0) * (spore?.potency ?? 0)
        return (burnDamage + sporeDamage) * CGFloat(deltaTime)
    }
}

final class ProjectileNode: SKShapeNode {
    var damage: CGFloat
    var velocity: CGVector
    var lifetime: TimeInterval
    let hitRadius: CGFloat
    var pierceRemaining: Int
    var bounceRemaining: Int
    let splashRadius: CGFloat
    let weaponType: WeaponType
    let isCritical: Bool
    let isSummon: Bool
    let sourceTier: Int
    let statusKind: StatusKind?
    let statusChance: CGFloat
    let statusPotency: CGFloat
    var hitEnemies: Set<ObjectIdentifier> = []
    var reflectedProps: Set<ObjectIdentifier> = []

    init(
        damage: CGFloat,
        velocity: CGVector,
        weaponType: WeaponType = .pulseCannon,
        pierce: Int = 1,
        bounce: Int = 0,
        splashRadius: CGFloat = 0,
        lifetime: TimeInterval = 1.7,
        sizeScale: CGFloat = 1,
        isCritical: Bool = false,
        isSummon: Bool = false,
        sourceTier: Int = 1,
        statusKind: StatusKind? = nil,
        statusChance: CGFloat = 0,
        statusPotency: CGFloat = 0
    ) {
        self.damage = damage
        self.velocity = velocity
        self.weaponType = weaponType
        self.pierceRemaining = pierce
        self.bounceRemaining = bounce
        self.splashRadius = splashRadius
        self.lifetime = lifetime
        self.hitRadius = 7 * sizeScale
        self.isCritical = isCritical
        self.isSummon = isSummon
        self.sourceTier = sourceTier
        self.statusKind = statusKind
        self.statusChance = statusChance
        self.statusPotency = statusPotency
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
    let isBossShot: Bool
    var velocity: CGVector
    var lifetime: TimeInterval = 4

    init(damage: CGFloat, velocity: CGVector, isBossShot: Bool = false) {
        self.damage = damage
        self.velocity = velocity
        self.isBossShot = isBossShot
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

enum ArenaPropKind: Equatable {
    case cargo
    case crystal
}

final class ArenaPropNode: SKShapeNode {
    let kind: ArenaPropKind
    let collisionRadius: CGFloat

    init(kind: ArenaPropKind, radius: CGFloat) {
        self.kind = kind
        collisionRadius = radius
        super.init()

        switch kind {
        case .cargo:
            path = CGPath(
                roundedRect: CGRect(
                    x: -radius,
                    y: -radius * 0.72,
                    width: radius * 2,
                    height: radius * 1.44
                ),
                cornerWidth: 7,
                cornerHeight: 7,
                transform: nil
            )
            fillColor = .gamePanel
            strokeColor = .gameYellow.withAlphaComponent(0.65)
            name = "cargoProp"
        case .crystal:
            let crystalPath = CGMutablePath()
            crystalPath.move(to: CGPoint(x: 0, y: radius))
            crystalPath.addLine(to: CGPoint(x: radius * 0.72, y: 0))
            crystalPath.addLine(to: CGPoint(x: 0, y: -radius))
            crystalPath.addLine(to: CGPoint(x: -radius * 0.72, y: 0))
            crystalPath.closeSubpath()
            path = crystalPath
            fillColor = .gameCyan.withAlphaComponent(0.18)
            strokeColor = .gameCyan
            glowWidth = 7
            name = "crystalProp"
        }
        lineWidth = 2
        zPosition = 5
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PurificationFlowerNode: SKShapeNode {
    let cleanseAmount: CGFloat = 8

    override init() {
        super.init()
        let flowerPath = CGMutablePath()
        for index in 0..<8 {
            let angle = CGFloat(index) / 8 * .pi * 2
            let outer = CGPoint(x: cos(angle) * 12, y: sin(angle) * 12)
            let innerAngle = angle + .pi / 8
            let inner = CGPoint(x: cos(innerAngle) * 5, y: sin(innerAngle) * 5)
            if index == 0 {
                flowerPath.move(to: outer)
            } else {
                flowerPath.addLine(to: outer)
            }
            flowerPath.addLine(to: inner)
        }
        flowerPath.closeSubpath()
        path = flowerPath
        fillColor = .gameGreen.withAlphaComponent(0.55)
        strokeColor = .gameCream
        lineWidth = 1.5
        glowWidth = 6
        zPosition = 9
        name = "purificationFlower"
        run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 5)))
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

final class DeployableNode: SKShapeNode {
    let weaponType: WeaponType
    let powerScale: CGFloat
    var cooldown: TimeInterval = 0
    var orbitAngle: CGFloat

    init(
        weaponType: WeaponType,
        index: Int,
        powerScale: CGFloat = 1
    ) {
        self.weaponType = weaponType
        self.powerScale = powerScale
        orbitAngle = CGFloat(index) * 1.9
        super.init()

        let radius: CGFloat = weaponType == .sentryCapsule ? 14 : 11
        path = CGPath(
            roundedRect: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2),
            cornerWidth: 5,
            cornerHeight: 5,
            transform: nil
        )
        fillColor = weaponType.color.withAlphaComponent(0.75)
        strokeColor = .white
        lineWidth = 1.5
        glowWidth = 4
        alpha = powerScale < 1 ? 0.55 : 1
        zPosition = 14
        name = "deployable"

        let symbol = SKLabelNode(fontNamed: "AvenirNext-Bold")
        symbol.text = weaponType.symbol
        symbol.fontSize = 11
        symbol.fontColor = .gameBackground
        symbol.verticalAlignmentMode = .center
        addChild(symbol)
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
    private let healthFill = SKSpriteNode(color: .gameGreen, size: CGSize(width: 126, height: 12))
    private let healthLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let shieldLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let waveLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let timerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let experienceBack = SKSpriteNode(
        color: SKColor.black.withAlphaComponent(0.45),
        size: CGSize(width: 88, height: 5)
    )
    private let experienceFill = SKSpriteNode(color: .gamePurple, size: CGSize(width: 86, height: 3))
    private let corruptionLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
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
            rectOf: CGSize(width: 134, height: 20),
            cornerRadius: 10
        )
        healthBack.fillColor = SKColor.black.withAlphaComponent(0.42)
        healthBack.strokeColor = .gameBorder
        healthBack.lineWidth = 1.5
        healthBack.position = CGPoint(x: 82, y: 0)
        addChild(healthBack)

        healthFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthFill.position = CGPoint(x: 19, y: 0)
        healthFill.zPosition = 1
        addChild(healthFill)

        healthLabel.fontSize = 11
        healthLabel.fontColor = .white
        healthLabel.verticalAlignmentMode = .center
        healthLabel.horizontalAlignmentMode = .center
        healthLabel.position = CGPoint(x: 82, y: 0)
        healthLabel.zPosition = 2
        addChild(healthLabel)

        shieldLabel.fontSize = 10
        shieldLabel.fontColor = .gameCyan
        shieldLabel.verticalAlignmentMode = .center
        shieldLabel.horizontalAlignmentMode = .left
        shieldLabel.position = CGPoint(x: 16, y: -18)
        addChild(shieldLabel)

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

        levelLabel.fontSize = 11
        levelLabel.fontColor = .gamePurple
        levelLabel.horizontalAlignmentMode = .right
        levelLabel.verticalAlignmentMode = .center
        addChild(levelLabel)

        experienceBack.anchorPoint = CGPoint(x: 1, y: 0.5)
        addChild(experienceBack)

        experienceFill.anchorPoint = CGPoint(x: 1, y: 0.5)
        experienceFill.zPosition = 1
        addChild(experienceFill)

        corruptionLabel.fontSize = 9
        corruptionLabel.fontColor = .gamePurple
        corruptionLabel.horizontalAlignmentMode = .right
        corruptionLabel.verticalAlignmentMode = .center
        addChild(corruptionLabel)

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

    func layout(for sceneSize: CGSize, topInset: CGFloat = 0) {
        let topOffset = max(54, topInset + 20)
        position = CGPoint(x: 0, y: sceneSize.height - topOffset)
        waveLabel.position.x = sceneSize.width * 0.5
        timerLabel.position.x = sceneSize.width * 0.5
        bossBack.position.x = sceneSize.width * 0.5
        bossFill.position.x = sceneSize.width * 0.5 - 90
        bossLabel.position.x = sceneSize.width * 0.5
        scoreLabel.position.x = sceneSize.width - 58
        levelLabel.position = CGPoint(x: sceneSize.width - 58, y: -18)
        experienceBack.position = CGPoint(x: sceneSize.width - 58, y: -28)
        experienceFill.position = CGPoint(x: sceneSize.width - 59, y: -28)
        corruptionLabel.position = CGPoint(x: sceneSize.width - 58, y: -39)
        pauseButton.position = CGPoint(x: sceneSize.width - 26, y: 0)
    }

    func update(
        health: CGFloat,
        maxHealth: CGFloat,
        shield: CGFloat,
        wave: Int,
        remainingTime: TimeInterval,
        score: Int,
        level: Int,
        experience: Int,
        nextExperience: Int,
        corruption: CGFloat,
        isClearing: Bool,
        bossHealth: CGFloat? = nil
    ) {
        let ratio = max(0, min(1, health / maxHealth))
        healthFill.xScale = ratio
        healthFill.color = ratio > 0.5 ? .gameGreen : (ratio > 0.25 ? .gameYellow : .gameCoral)
        healthLabel.text = "\(Int(ceil(health))) / \(Int(maxHealth))"
        shieldLabel.text = shield > 0 ? "▰ \(Int(ceil(shield)))" : ""
        waveLabel.text = "第 \(wave) 波"
        timerLabel.text = isClearing ? "清理敌人" : "\(Int(ceil(max(0, remainingTime))))"
        timerLabel.fontSize = isClearing ? 16 : 28
        scoreLabel.text = "◆ \(score)"
        levelLabel.text = "Lv.\(level)"
        let experienceRatio = max(
            0,
            min(1, CGFloat(experience) / CGFloat(max(1, nextExperience)))
        )
        experienceFill.xScale = experienceRatio
        corruptionLabel.text = corruption > 0 ? "☣ \(Int(corruption))" : ""
        corruptionLabel.fontColor = corruption >= 75
            ? .gameCoral
            : (corruption >= 50 ? .gamePurple : .gameCyan)

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
    let choice: UpgradeChoice

    init(choice: UpgradeChoice, index: Int, width: CGFloat) {
        self.choice = choice
        super.init()

        name = "upgrade_\(index)"
        path = CGPath(
            roundedRect: CGRect(x: -width / 2, y: -45, width: width, height: 90),
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )
        fillColor = .gamePanel
        strokeColor = choice.color
        lineWidth = 2
        glowWidth = 1

        let iconBack = SKShapeNode(circleOfRadius: 26)
        iconBack.name = name
        iconBack.fillColor = choice.color.withAlphaComponent(0.18)
        iconBack.strokeColor = choice.color
        iconBack.lineWidth = 1.5
        iconBack.position.x = -width / 2 + 45
        addChild(iconBack)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        icon.name = name
        icon.text = choice.symbol
        icon.fontSize = 25
        icon.fontColor = choice.color
        icon.verticalAlignmentMode = .center
        icon.horizontalAlignmentMode = .center
        iconBack.addChild(icon)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.name = name
        title.text = choice.title
        title.fontSize = 18
        title.fontColor = .gameCream
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: -width / 2 + 84, y: 13)
        addChild(title)

        let detail = SKLabelNode(fontNamed: "AvenirNext-Medium")
        detail.name = name
        detail.text = choice.detail
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

        let rarity = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        rarity.name = name
        rarity.text = offer.kind.rarityTitle
        rarity.fontSize = 9
        rarity.fontColor = offer.kind.color.withAlphaComponent(0.8)
        rarity.horizontalAlignmentMode = .left
        rarity.verticalAlignmentMode = .center
        rarity.position = CGPoint(x: -width / 2 + 78, y: 34)
        addChild(rarity)

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

        let lock = SKShapeNode(circleOfRadius: 15)
        lock.name = "lockOffer_\(index)"
        lock.fillColor = offer.isLocked
            ? offer.kind.color.withAlphaComponent(0.28)
            : SKColor.black.withAlphaComponent(0.24)
        lock.strokeColor = offer.isLocked ? offer.kind.color : .gameBorder
        lock.lineWidth = 1.2
        lock.position = CGPoint(x: width / 2 - 20, y: -21)
        addChild(lock)

        let lockLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lockLabel.name = "lockOffer_\(index)"
        lockLabel.text = offer.isLocked ? "▣" : "▢"
        lockLabel.fontSize = 13
        lockLabel.fontColor = offer.isLocked ? offer.kind.color : .gameCream
        lockLabel.verticalAlignmentMode = .center
        lock.addChild(lockLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
