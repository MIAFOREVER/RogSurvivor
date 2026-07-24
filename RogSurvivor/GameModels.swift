import CoreGraphics
import SpriteKit

enum GamePhase: Equatable {
    case title
    case heroSelect
    case arenaSelect
    case threatSelect
    case contractSelect
    case playing
    case levelUp
    case shop
    case hangar
    case archives
    case compendium
    case settings
    case paused
    case gameOver
    case victory
}

struct PlayerStats {
    var maxHealth: CGFloat = 100
    var health: CGFloat = 100
    var shield: CGFloat = 0
    var shieldPerWave: CGFloat = 0
    var movementSpeed: CGFloat = 190
    var globalDamage: CGFloat = 0
    var attackSpeed: CGFloat = 0
    var weaponPower: CGFloat = 0
    var engineering: CGFloat = 0
    var erosion: CGFloat = 0
    var projectileSpeed: CGFloat = 560
    var projectileCount = 1
    var armor: CGFloat = 0
    var pickupRange: CGFloat = 70
    var critChance: CGFloat = 0.05
    var critMultiplier: CGFloat = 1.75
    var lifeSteal: CGFloat = 0
    var dodgeChance: CGFloat = 0
    var luck: CGFloat = 0
    var regeneration: CGFloat = 0
    var currencyMultiplier: CGFloat = 1
    var projectileSize: CGFloat = 1
    var thorns: CGFloat = 0
    var knockback: CGFloat = 1
    var rangeMultiplier: CGFloat = 1
    var explosionDamage: CGFloat = 1
    var bossDamage: CGFloat = 1
    var eliteDamage: CGFloat = 1
    var healingEfficiency: CGFloat = 1
    var shopDiscount: CGFloat = 0
    var rerollDiscount: CGFloat = 0
    var recycleRefund: CGFloat = 0.55
    var harvesting: Int = 0
    var corruption: CGFloat = 0
    var contactInvulnerability: TimeInterval = 0.45

    var damage: CGFloat {
        get { 18 * (1 + globalDamage) }
        set { globalDamage = max(-0.8, newValue / 18 - 1) }
    }

    var fireInterval: TimeInterval {
        get { 0.48 / Double(max(0.4, 1 + attackSpeed)) }
        set { attackSpeed = max(-0.6, CGFloat(0.48 / newValue) - 1) }
    }

    var corruptionStage: Int {
        switch corruption {
        case ..<25: 0
        case ..<50: 1
        case ..<75: 2
        case ..<100: 3
        default: 4
        }
    }

    var corruptionRewardMultiplier: CGFloat {
        switch corruptionStage {
        case 1: 1.05
        case 2: 1.12
        case 3, 4: 1.22
        default: 1
        }
    }

    mutating func reset() {
        self = PlayerStats()
    }

    mutating func receiveDamage(_ rawDamage: CGFloat) -> CGFloat {
        if CGFloat.random(in: 0...1) < dodgeChance {
            return 0
        }
        let armorMultiplier: CGFloat
        if armor >= 0 {
            let reduction = min(0.75, armor / (armor + 15))
            armorMultiplier = 1 - reduction
        } else {
            armorMultiplier = 1 + abs(armor) * 0.05
        }
        let actualDamage = max(1, rawDamage * armorMultiplier)
        let absorbed = min(shield, actualDamage)
        shield -= absorbed
        health = max(0, health - (actualDamage - absorbed))
        return actualDamage
    }

    @discardableResult
    mutating func heal(_ amount: CGFloat) -> CGFloat {
        let adjusted = max(0, amount * healingEfficiency)
        let oldHealth = health
        health = min(maxHealth, health + adjusted)
        return health - oldHealth
    }

    mutating func beginWave() {
        shield = min(maxHealth * 0.6, max(0, shieldPerWave))
    }

    mutating func clamp() {
        maxHealth = max(1, maxHealth)
        health = min(maxHealth, max(0, health))
        dodgeChance = min(0.6, max(0, dodgeChance))
        critChance = min(0.8, max(0, critChance))
        lifeSteal = min(0.25, max(0, lifeSteal))
        healingEfficiency = max(0, healingEfficiency)
        shopDiscount = min(0.4, max(-0.5, shopDiscount))
        rerollDiscount = min(0.75, max(0, rerollDiscount))
        recycleRefund = min(0.9, max(0, recycleRefund))
        rangeMultiplier = min(2.5, max(0.4, rangeMultiplier))
        projectileSpeed = min(1680, max(224, projectileSpeed))
        projectileSize = min(2.5, max(0.5, projectileSize))
        movementSpeed = min(418, max(95, movementSpeed))
    }
}

enum UpgradeRarity: Int, CaseIterable {
    case common = 1
    case refined
    case rare
    case legendary

    var title: String {
        switch self {
        case .common: "普通"
        case .refined: "精良"
        case .rare: "稀有"
        case .legendary: "传奇"
        }
    }

    var color: SKColor {
        switch self {
        case .common: .gameCream
        case .refined: .gameBlue
        case .rare: .gamePurple
        case .legendary: .gameYellow
        }
    }
}

enum Upgrade: String, CaseIterable, Hashable, Codable {
    case maxHealth
    case regeneration
    case lifeSteal
    case armor
    case dodge
    case movement
    case damage
    case attackSpeed
    case critical
    case criticalDamage
    case weaponPower
    case engineering
    case erosion
    case range
    case projectileSpeed
    case areaSize
    case knockback
    case pickupRange
    case luck
    case harvesting

    var title: String {
        switch self {
        case .maxHealth: "生命培育"
        case .regeneration: "再生菌群"
        case .lifeSteal: "血能导管"
        case .armor: "合金护板"
        case .dodge: "相位电容"
        case .movement: "涡轮靴"
        case .damage: "全域增幅"
        case .attackSpeed: "超频扳机"
        case .critical: "精密瞄具"
        case .criticalDamage: "弱点解析"
        case .weaponPower: "武装校准"
        case .engineering: "工程矩阵"
        case .erosion: "侵蚀培养"
        case .range: "远距索敌"
        case .projectileSpeed: "加速膛线"
        case .areaSize: "范围扩容"
        case .knockback: "动能冲击"
        case .pickupRange: "引力线圈"
        case .luck: "幸运芯片"
        case .harvesting: "回收协议"
        }
    }

    func detail(for rarity: UpgradeRarity) -> String {
        let value = values[rarity.rawValue - 1]
        return switch self {
        case .maxHealth: "最大生命 +\(Int(value))，并回复同量生命"
        case .regeneration: "生命再生 +\(formatted(value))/秒"
        case .lifeSteal: "生命偷取 +\(Int(value))%"
        case .armor: "护甲 +\(Int(value))"
        case .dodge: "闪避 +\(Int(value))%"
        case .movement: "移动速度 +\(Int(value))%"
        case .damage: "全局伤害 +\(Int(value))%"
        case .attackSpeed: "攻击速度 +\(Int(value))%"
        case .critical: "暴击率 +\(Int(value))%"
        case .criticalDamage: "暴击伤害 +\(Int(value))%"
        case .weaponPower: "武装 +\(Int(value))"
        case .engineering: "工程 +\(Int(value))"
        case .erosion: "侵蚀 +\(Int(value))"
        case .range: "射程 +\(Int(value))%"
        case .projectileSpeed: "弹速 +\(Int(value))%"
        case .areaSize: "范围尺寸 +\(Int(value))%"
        case .knockback: "击退 +\(Int(value))%"
        case .pickupRange: "拾取范围 +\(Int(value))"
        case .luck: "幸运 +\(Int(value))"
        case .harvesting: "每波回收 +\(Int(value))"
        }
    }

    var symbol: String {
        switch self {
        case .maxHealth: "♥"
        case .regeneration: "♧"
        case .lifeSteal: "♦"
        case .armor: "⬡"
        case .dodge: "◌"
        case .movement: "➤"
        case .damage: "✦"
        case .attackSpeed: "⌁"
        case .critical: "⊕"
        case .criticalDamage: "⌖"
        case .weaponPower: "➤"
        case .engineering: "⚙"
        case .erosion: "☣"
        case .range: "↔"
        case .projectileSpeed: "»"
        case .areaSize: "●"
        case .knockback: "↟"
        case .pickupRange: "◎"
        case .luck: "♢"
        case .harvesting: "◆"
        }
    }

    var color: SKColor {
        switch self {
        case .maxHealth, .regeneration: .gameGreen
        case .lifeSteal, .damage: .gameCoral
        case .armor: .gameBlue
        case .dodge, .movement, .knockback: .gameCyan
        case .attackSpeed, .critical, .criticalDamage, .luck, .harvesting: .gameYellow
        case .weaponPower, .projectileSpeed: .gameBlue
        case .engineering: .gameGreen
        case .erosion, .areaSize: .gamePurple
        case .range, .pickupRange: .gamePink
        }
    }

    var values: [CGFloat] {
        switch self {
        case .maxHealth: [6, 10, 16, 25]
        case .regeneration: [0.6, 1, 1.7, 2.8]
        case .lifeSteal: [1, 2, 3, 5]
        case .armor: [1, 2, 3, 5]
        case .dodge: [3, 5, 8, 12]
        case .movement: [5, 8, 12, 18]
        case .damage: [5, 8, 12, 18]
        case .attackSpeed: [6, 10, 15, 22]
        case .critical: [3, 5, 8, 12]
        case .criticalDamage: [10, 18, 28, 45]
        case .weaponPower, .engineering, .erosion: [2, 4, 7, 11]
        case .range: [8, 14, 22, 35]
        case .projectileSpeed: [10, 18, 28, 45]
        case .areaSize: [6, 10, 16, 25]
        case .knockback: [12, 20, 32, 50]
        case .pickupRange: [25, 45, 75, 120]
        case .luck: [6, 10, 16, 25]
        case .harvesting: [4, 7, 11, 17]
        }
    }

    func apply(to stats: inout PlayerStats, rarity: UpgradeRarity) {
        let value = values[rarity.rawValue - 1]
        switch self {
        case .maxHealth:
            stats.maxHealth += value
            stats.health += value
        case .regeneration:
            stats.regeneration += value
        case .lifeSteal:
            stats.lifeSteal += value / 100
        case .armor:
            stats.armor += value
        case .dodge:
            stats.dodgeChance += value / 100
        case .movement:
            stats.movementSpeed *= 1 + value / 100
        case .damage:
            stats.globalDamage += value / 100
        case .attackSpeed:
            stats.attackSpeed += value / 100
        case .critical:
            stats.critChance += value / 100
        case .criticalDamage:
            stats.critMultiplier += value / 100
        case .weaponPower:
            stats.weaponPower += value
        case .engineering:
            stats.engineering += value
        case .erosion:
            stats.erosion += value
        case .range:
            stats.rangeMultiplier += value / 100
        case .projectileSpeed:
            stats.projectileSpeed *= 1 + value / 100
        case .areaSize:
            stats.projectileSize += value / 100
        case .knockback:
            stats.knockback += value / 100
        case .pickupRange:
            stats.pickupRange += value
        case .luck:
            stats.luck += value
        case .harvesting:
            stats.harvesting += Int(value)
        }
        stats.clamp()
    }

    private func formatted(_ value: CGFloat) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

struct UpgradeChoice {
    let upgrade: Upgrade
    let rarity: UpgradeRarity

    var title: String { upgrade.title }
    var detail: String { upgrade.detail(for: rarity) }
    var symbol: String { upgrade.symbol }
    var color: SKColor { rarity.color }
}

enum PhysicsCategory {
    static let player: UInt32 = 1 << 0
    static let enemy: UInt32 = 1 << 1
    static let projectile: UInt32 = 1 << 2
    static let pickup: UInt32 = 1 << 3
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }
}

extension CGVector {
    var length: CGFloat {
        sqrt(dx * dx + dy * dy)
    }

    var normalized: CGVector {
        let magnitude = length
        guard magnitude > 0.001 else { return .zero }
        return CGVector(dx: dx / magnitude, dy: dy / magnitude)
    }

    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

    func rotated(by radians: CGFloat) -> CGVector {
        CGVector(
            dx: dx * cos(radians) - dy * sin(radians),
            dy: dx * sin(radians) + dy * cos(radians)
        )
    }
}

extension SKColor {
    static let gameBackground = SKColor(red: 0.055, green: 0.075, blue: 0.12, alpha: 1)
    static let gamePanel = SKColor(red: 0.09, green: 0.12, blue: 0.19, alpha: 0.96)
    static let gameBorder = SKColor(red: 0.19, green: 0.25, blue: 0.36, alpha: 1)
    static let gameCream = SKColor(red: 0.96, green: 0.94, blue: 0.85, alpha: 1)
    static let gameCoral = SKColor(red: 1, green: 0.38, blue: 0.32, alpha: 1)
    static let gameYellow = SKColor(red: 1, green: 0.78, blue: 0.25, alpha: 1)
    static let gameGreen = SKColor(red: 0.36, green: 0.9, blue: 0.54, alpha: 1)
    static let gameCyan = SKColor(red: 0.24, green: 0.84, blue: 0.9, alpha: 1)
    static let gamePurple = SKColor(red: 0.66, green: 0.45, blue: 0.98, alpha: 1)
    static let gameBlue = SKColor(red: 0.31, green: 0.56, blue: 1, alpha: 1)
    static let gamePink = SKColor(red: 1, green: 0.4, blue: 0.7, alpha: 1)
}
