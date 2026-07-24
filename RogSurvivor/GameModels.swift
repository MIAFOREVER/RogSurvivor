import CoreGraphics
import SpriteKit

enum GamePhase: Equatable {
    case title
    case heroSelect
    case arenaSelect
    case playing
    case shop
    case hangar
    case archives
    case paused
    case gameOver
    case victory
}

struct PlayerStats {
    var maxHealth: CGFloat = 100
    var health: CGFloat = 100
    var movementSpeed: CGFloat = 190
    var damage: CGFloat = 18
    var fireInterval: TimeInterval = 0.48
    var projectileSpeed: CGFloat = 560
    var projectileCount = 1
    var armor: CGFloat = 0
    var pickupRange: CGFloat = 70
    var critChance: CGFloat = 0.06
    var critMultiplier: CGFloat = 1.8
    var lifeSteal: CGFloat = 0
    var dodgeChance: CGFloat = 0
    var luck: CGFloat = 0
    var regeneration: CGFloat = 0
    var currencyMultiplier: CGFloat = 1
    var projectileSize: CGFloat = 1
    var thorns: CGFloat = 0
    var knockback: CGFloat = 1

    mutating func reset() {
        self = PlayerStats()
    }

    mutating func receiveDamage(_ rawDamage: CGFloat) -> CGFloat {
        if CGFloat.random(in: 0...1) < dodgeChance {
            return 0
        }
        let reduction = min(0.65, armor * 0.06)
        let actualDamage = max(1, rawDamage * (1 - reduction))
        health = max(0, health - actualDamage)
        return actualDamage
    }

    mutating func heal(_ amount: CGFloat) {
        health = min(maxHealth, health + amount)
    }
}

enum Upgrade: CaseIterable, Hashable {
    case damage
    case fireRate
    case maxHealth
    case movement
    case multishot
    case armor
    case magnet
    case repair
    case critical
    case lifeSteal
    case dodge
    case regeneration
    case fortune
    case velocity
    case projectileSize
    case thorns
    case overdrive
    case greed

    var title: String {
        switch self {
        case .damage: "高能弹头"
        case .fireRate: "超频扳机"
        case .maxHealth: "厚实外皮"
        case .movement: "涡轮靴"
        case .multishot: "分裂枪管"
        case .armor: "合金护板"
        case .magnet: "引力线圈"
        case .repair: "紧急修复"
        case .critical: "精密瞄具"
        case .lifeSteal: "血能导管"
        case .dodge: "相位电容"
        case .regeneration: "再生菌群"
        case .fortune: "幸运芯片"
        case .velocity: "加速膛线"
        case .projectileSize: "膨胀弹药"
        case .thorns: "反应尖刺"
        case .overdrive: "危险超载"
        case .greed: "回收执照"
        }
    }

    var detail: String {
        switch self {
        case .damage: "伤害 +25%"
        case .fireRate: "攻击速度 +18%"
        case .maxHealth: "最大生命 +25，并回复 25"
        case .movement: "移动速度 +12%"
        case .multishot: "每次额外发射 1 枚子弹"
        case .armor: "护甲 +2"
        case .magnet: "拾取范围 +45"
        case .repair: "回复 45 点生命"
        case .critical: "暴击率 +10%"
        case .lifeSteal: "生命偷取 +3%"
        case .dodge: "闪避率 +6%"
        case .regeneration: "每秒回复 +1.2"
        case .fortune: "幸运 +15%"
        case .velocity: "弹速 +22%"
        case .projectileSize: "弹体尺寸 +18%"
        case .thorns: "受到接触攻击时反伤 8"
        case .overdrive: "伤害 +35%，最大生命 -12"
        case .greed: "碎片收益 +18%"
        }
    }

    var symbol: String {
        switch self {
        case .damage: "✦"
        case .fireRate: "⌁"
        case .maxHealth: "♥"
        case .movement: "➤"
        case .multishot: "≋"
        case .armor: "⬡"
        case .magnet: "◎"
        case .repair: "+"
        case .critical: "⊕"
        case .lifeSteal: "♦"
        case .dodge: "◌"
        case .regeneration: "♧"
        case .fortune: "♢"
        case .velocity: "»"
        case .projectileSize: "●"
        case .thorns: "✣"
        case .overdrive: "!"
        case .greed: "◆"
        }
    }

    var color: SKColor {
        switch self {
        case .damage: .gameCoral
        case .fireRate: .gameYellow
        case .maxHealth, .repair: .gameGreen
        case .movement: .gameCyan
        case .multishot: .gamePurple
        case .armor: .gameBlue
        case .magnet: .gamePink
        case .critical: .gameYellow
        case .lifeSteal: .gameCoral
        case .dodge: .gameCyan
        case .regeneration: .gameGreen
        case .fortune, .greed: .gameYellow
        case .velocity: .gameBlue
        case .projectileSize: .gamePurple
        case .thorns: .gamePink
        case .overdrive: .gameCoral
        }
    }

    func apply(to stats: inout PlayerStats) {
        switch self {
        case .damage:
            stats.damage *= 1.25
        case .fireRate:
            stats.fireInterval = max(0.14, stats.fireInterval * 0.82)
        case .maxHealth:
            stats.maxHealth += 25
            stats.health = min(stats.maxHealth, stats.health + 25)
        case .movement:
            stats.movementSpeed *= 1.12
        case .multishot:
            stats.projectileCount = min(5, stats.projectileCount + 1)
        case .armor:
            stats.armor += 2
        case .magnet:
            stats.pickupRange += 45
        case .repair:
            stats.heal(45)
        case .critical:
            stats.critChance = min(0.75, stats.critChance + 0.1)
        case .lifeSteal:
            stats.lifeSteal = min(0.25, stats.lifeSteal + 0.03)
        case .dodge:
            stats.dodgeChance = min(0.45, stats.dodgeChance + 0.06)
        case .regeneration:
            stats.regeneration += 1.2
        case .fortune:
            stats.luck += 0.15
        case .velocity:
            stats.projectileSpeed *= 1.22
        case .projectileSize:
            stats.projectileSize *= 1.18
        case .thorns:
            stats.thorns += 8
        case .overdrive:
            stats.damage *= 1.35
            stats.maxHealth = max(35, stats.maxHealth - 12)
            stats.health = min(stats.health, stats.maxHealth)
        case .greed:
            stats.currencyMultiplier += 0.18
        }
    }
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
