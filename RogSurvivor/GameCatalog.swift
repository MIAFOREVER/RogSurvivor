import Foundation
import SpriteKit

enum WeaponType: String, CaseIterable, Codable {
    case pulseCannon
    case scattergun
    case railLance
    case meteorTube
    case arcCoil
    case starBlades
    case emberSprayer
    case droneSwarm

    var title: String {
        switch self {
        case .pulseCannon: "脉冲手炮"
        case .scattergun: "废土霰射器"
        case .railLance: "磁轨长枪"
        case .meteorTube: "流星火箭筒"
        case .arcCoil: "电弧线圈"
        case .starBlades: "星环飞刃"
        case .emberSprayer: "余烬喷射器"
        case .droneSwarm: "蜂群无人机"
        }
    }

    var detail: String {
        switch self {
        case .pulseCannon: "稳定、均衡的自动武器"
        case .scattergun: "一次发射多枚近程弹丸"
        case .railLance: "慢速重击，可贯穿多个敌人"
        case .meteorTube: "爆炸会伤害一大片敌人"
        case .arcCoil: "电流能连续穿透目标"
        case .starBlades: "向四周发射短程旋转飞刃"
        case .emberSprayer: "高频喷出扇形火焰"
        case .droneSwarm: "高速追踪弹幕，单发伤害较低"
        }
    }

    var symbol: String {
        switch self {
        case .pulseCannon: "➤"
        case .scattergun: "∴"
        case .railLance: "━"
        case .meteorTube: "◉"
        case .arcCoil: "ϟ"
        case .starBlades: "✣"
        case .emberSprayer: "♨"
        case .droneSwarm: "⬢"
        }
    }

    var color: SKColor {
        switch self {
        case .pulseCannon: .gameYellow
        case .scattergun: .gameCoral
        case .railLance: .gameBlue
        case .meteorTube: .gamePink
        case .arcCoil: .gameCyan
        case .starBlades: .gamePurple
        case .emberSprayer: SKColor(red: 1, green: 0.52, blue: 0.16, alpha: 1)
        case .droneSwarm: .gameGreen
        }
    }

    var baseInterval: TimeInterval {
        switch self {
        case .pulseCannon: 0.48
        case .scattergun: 1.02
        case .railLance: 1.35
        case .meteorTube: 1.7
        case .arcCoil: 0.86
        case .starBlades: 1.42
        case .emberSprayer: 0.22
        case .droneSwarm: 0.32
        }
    }

    var damageMultiplier: CGFloat {
        switch self {
        case .pulseCannon: 1
        case .scattergun: 0.55
        case .railLance: 2.55
        case .meteorTube: 2.8
        case .arcCoil: 0.92
        case .starBlades: 0.82
        case .emberSprayer: 0.34
        case .droneSwarm: 0.48
        }
    }

    var projectileSpeed: CGFloat {
        switch self {
        case .pulseCannon: 560
        case .scattergun: 490
        case .railLance: 820
        case .meteorTube: 300
        case .arcCoil: 700
        case .starBlades: 380
        case .emberSprayer: 350
        case .droneSwarm: 680
        }
    }

    var baseVolley: Int {
        switch self {
        case .scattergun: 5
        case .starBlades: 8
        case .emberSprayer: 3
        default: 1
        }
    }

    var spread: CGFloat {
        switch self {
        case .scattergun: 0.7
        case .emberSprayer: 0.4
        default: 0
        }
    }

    var pierce: Int {
        switch self {
        case .railLance: 4
        case .arcCoil: 3
        case .starBlades: 2
        default: 1
        }
    }

    var splashRadius: CGFloat {
        self == .meteorTube ? 78 : 0
    }

    var projectileLifetime: TimeInterval {
        switch self {
        case .starBlades, .emberSprayer: 0.58
        default: 1.7
        }
    }
}

struct WeaponRuntime {
    let type: WeaponType
    var level: Int
    var cooldown: TimeInterval = 0

    var damageScale: CGFloat {
        1 + CGFloat(level - 1) * 0.3
    }

    var intervalScale: CGFloat {
        max(0.6, 1 - CGFloat(level - 1) * 0.08)
    }
}

enum HeroType: String, CaseIterable, Codable {
    case pioneer
    case gunslinger
    case bulwark
    case engineer
    case stormcaller
    case harvester

    var title: String {
        switch self {
        case .pioneer: "拓荒薯"
        case .gunslinger: "快枪薯"
        case .bulwark: "堡垒薯"
        case .engineer: "机巧薯"
        case .stormcaller: "唤雷薯"
        case .harvester: "收割薯"
        }
    }

    var subtitle: String {
        switch self {
        case .pioneer: "均衡可靠，适合任何构筑"
        case .gunslinger: "弹幕更密，但身板脆弱"
        case .bulwark: "厚重装甲，以伤换伤"
        case .engineer: "掌控无人机与资源经济"
        case .stormcaller: "电弧贯穿成群敌人"
        case .harvester: "越接近死亡，火力越凶猛"
        }
    }

    var lore: String {
        switch self {
        case .pioneer: "第七码头最后一位巡逻员，在霉潮降临时独自守住了撤离通道。"
        case .gunslinger: "地下竞速场的冠军。她把引擎拆成枪械，只为了跑得比危险更快。"
        case .bulwark: "旧联邦的移动城墙。护甲上的每一道划痕，都来自一次没有后退的战斗。"
        case .engineer: "相信任何废料都还有第二次生命——包括失控的军用无人机。"
        case .stormcaller: "在水晶矿脉中醒来，体内回响着星球深处的雷声。"
        case .harvester: "被霉潮侵蚀却保留理智的猎手，以敌人的能量压制体内的孢子。"
        }
    }

    var symbol: String {
        switch self {
        case .pioneer: "★"
        case .gunslinger: "ϟ"
        case .bulwark: "⬡"
        case .engineer: "⚙"
        case .stormcaller: "⌁"
        case .harvester: "☾"
        }
    }

    var color: SKColor {
        switch self {
        case .pioneer: .gameYellow
        case .gunslinger: .gameCoral
        case .bulwark: .gameBlue
        case .engineer: .gameGreen
        case .stormcaller: .gameCyan
        case .harvester: .gamePurple
        }
    }

    var startingWeapon: WeaponType {
        switch self {
        case .pioneer: .pulseCannon
        case .gunslinger: .scattergun
        case .bulwark: .railLance
        case .engineer: .droneSwarm
        case .stormcaller: .arcCoil
        case .harvester: .starBlades
        }
    }

    func isUnlocked(in save: GameSaveData) -> Bool {
        switch self {
        case .pioneer: true
        case .gunslinger: save.runs >= 1 || save.totalCores >= 12
        case .bulwark: save.highWave >= 4 || save.totalCores >= 25
        case .engineer: save.totalCores >= 40
        case .stormcaller: save.highWave >= 8 || save.totalCores >= 60
        case .harvester: save.highWave >= 12 || save.totalCores >= 95
        }
    }

    func unlockText(in save: GameSaveData) -> String {
        if isUnlocked(in: save) { return "已解锁" }
        switch self {
        case .pioneer: return "已解锁"
        case .gunslinger: return "完成 1 局"
        case .bulwark: return "抵达第 4 波"
        case .engineer: return "累计获得 40 核心"
        case .stormcaller: return "抵达第 8 波"
        case .harvester: return "抵达第 12 波"
        }
    }

    func apply(to stats: inout PlayerStats) {
        switch self {
        case .pioneer:
            stats.damage *= 1.1
            stats.maxHealth += 10
            stats.health = stats.maxHealth
        case .gunslinger:
            stats.maxHealth -= 20
            stats.health = stats.maxHealth
            stats.fireInterval *= 0.76
            stats.movementSpeed *= 1.12
        case .bulwark:
            stats.maxHealth += 55
            stats.health = stats.maxHealth
            stats.armor += 4
            stats.movementSpeed *= 0.84
            stats.thorns += 8
        case .engineer:
            stats.pickupRange += 55
            stats.luck += 0.22
            stats.currencyMultiplier += 0.22
            stats.damage *= 0.9
        case .stormcaller:
            stats.damage *= 1.16
            stats.critChance += 0.08
            stats.maxHealth -= 10
            stats.health = stats.maxHealth
        case .harvester:
            stats.lifeSteal += 0.06
            stats.dodgeChance += 0.08
            stats.damage *= 1.08
        }
    }
}

enum ArenaType: String, CaseIterable, Codable {
    case scrapOrbit
    case crystalHollows
    case emberFoundry

    var title: String {
        switch self {
        case .scrapOrbit: "废铁轨道"
        case .crystalHollows: "回声晶窟"
        case .emberFoundry: "余烬铸造厂"
        }
    }

    var subtitle: String {
        switch self {
        case .scrapOrbit: "标准战场 · 平衡资源"
        case .crystalHollows: "敌人更快 · 拾取与收益提升"
        case .emberFoundry: "周期热浪 · 精英与奖励更多"
        }
    }

    var lore: String {
        switch self {
        case .scrapOrbit: "环绕薯星的废弃货运站，如今是幸存者回收武器的第一道防线。"
        case .crystalHollows: "星球深处的水晶会记录声音，也会把霉潮的低语放大数千倍。"
        case .emberFoundry: "旧联邦制造核心的工厂仍在运转，只是控制熔炉的已不再是工人。"
        }
    }

    var color: SKColor {
        switch self {
        case .scrapOrbit: .gameBlue
        case .crystalHollows: .gameCyan
        case .emberFoundry: .gameCoral
        }
    }

    var rewardMultiplier: CGFloat {
        switch self {
        case .scrapOrbit: 1
        case .crystalHollows: 1.22
        case .emberFoundry: 1.35
        }
    }

    var enemySpeedMultiplier: CGFloat {
        switch self {
        case .scrapOrbit: 1
        case .crystalHollows: 1.12
        case .emberFoundry: 1.05
        }
    }

    func isUnlocked(in save: GameSaveData) -> Bool {
        switch self {
        case .scrapOrbit: true
        case .crystalHollows: save.highWave >= 5 || save.totalCores >= 35
        case .emberFoundry: save.highWave >= 9 || save.totalCores >= 75
        }
    }

    func unlockText(in save: GameSaveData) -> String {
        if isUnlocked(in: save) { return "已解锁" }
        switch self {
        case .scrapOrbit: return "已解锁"
        case .crystalHollows: return "抵达第 5 波"
        case .emberFoundry: return "抵达第 9 波"
        }
    }
}

struct GameSaveData: Codable {
    var totalCores = 0
    var lifetimeKills = 0
    var highWave = 0
    var highScore = 0
    var runs = 0
    var victories = 0
    var permanentPower = 0
    var permanentVitality = 0
    var permanentScavenging = 0

    mutating func applyPermanentBonuses(to stats: inout PlayerStats) {
        stats.damage *= 1 + CGFloat(permanentPower) * 0.04
        stats.maxHealth += CGFloat(permanentVitality) * 7
        stats.health = stats.maxHealth
        stats.currencyMultiplier += CGFloat(permanentScavenging) * 0.045
    }

    func upgradeCost(for track: PermanentTrack) -> Int {
        12 + track.rank(in: self) * 10
    }
}

enum PermanentTrack: String, CaseIterable {
    case power
    case vitality
    case scavenging

    var title: String {
        switch self {
        case .power: "武器校准"
        case .vitality: "生命培育"
        case .scavenging: "回收协议"
        }
    }

    var detail: String {
        switch self {
        case .power: "每级使所有伤害 +4%"
        case .vitality: "每级使初始生命 +7"
        case .scavenging: "每级使碎片收益 +4.5%"
        }
    }

    var symbol: String {
        switch self {
        case .power: "✦"
        case .vitality: "♥"
        case .scavenging: "◆"
        }
    }

    var color: SKColor {
        switch self {
        case .power: .gameCoral
        case .vitality: .gameGreen
        case .scavenging: .gameCyan
        }
    }

    func rank(in save: GameSaveData) -> Int {
        switch self {
        case .power: save.permanentPower
        case .vitality: save.permanentVitality
        case .scavenging: save.permanentScavenging
        }
    }
}

final class SaveStore {
    private let key = "RogSurvivor.save.v2"
    private(set) var data: GameSaveData

    init() {
        if let encoded = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(GameSaveData.self, from: encoded) {
            data = decoded
        } else {
            data = GameSaveData()
        }
    }

    func mutate(_ mutation: (inout GameSaveData) -> Void) {
        mutation(&data)
        persist()
    }

    private func persist() {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }
}

enum ShopOfferKind {
    case weapon(WeaponType)
    case upgrade(Upgrade)

    var title: String {
        switch self {
        case .weapon(let weapon): weapon.title
        case .upgrade(let upgrade): upgrade.title
        }
    }

    var detail: String {
        switch self {
        case .weapon(let weapon): weapon.detail
        case .upgrade(let upgrade): upgrade.detail
        }
    }

    var symbol: String {
        switch self {
        case .weapon(let weapon): weapon.symbol
        case .upgrade(let upgrade): upgrade.symbol
        }
    }

    var color: SKColor {
        switch self {
        case .weapon(let weapon): weapon.color
        case .upgrade(let upgrade): upgrade.color
        }
    }
}

struct ShopOffer {
    let kind: ShopOfferKind
    let price: Int
}

struct LoreEntry {
    let title: String
    let subtitle: String
    let body: String
    let color: SKColor

    static let all: [LoreEntry] = [
        LoreEntry(
            title: "薯星历 417 年",
            subtitle: "霉潮降临",
            body: "来自深空的孢子风暴吞没外环殖民地。它不会立刻杀死宿主，而是把恐惧、贪婪与本能编织成新的生命。",
            color: .gamePurple
        ),
        LoreEntry(
            title: "最后广播",
            subtitle: "第七码头",
            body: "联邦舰队失联前留下唯一指令：收集散落的星核，重启轨道炮，为地表幸存者打开一条离开薯星的航路。",
            color: .gameCyan
        ),
        LoreEntry(
            title: "星核协议",
            subtitle: "基地成长",
            body: "每一次突围收集的星核都会永久强化下一位战士。失败不是结束，而是下一次构筑的燃料。",
            color: .gameYellow
        ),
        LoreEntry(
            title: "霉潮母体",
            subtitle: "第 20 波之后",
            body: "所有感染体共享同一段脉冲。只要追踪脉冲穿过二十层封锁，就能找到母体真正的坐标。",
            color: .gameCoral
        )
    ]
}

enum RunContract: CaseIterable {
    case exterminator
    case collector
    case titanHunter
    case untouched

    var title: String {
        switch self {
        case .exterminator: "清剿协议"
        case .collector: "紧急回收"
        case .titanHunter: "巨像猎手"
        case .untouched: "完美防线"
        }
    }

    var detail: String {
        switch self {
        case .exterminator: "单局击败 120 个敌人"
        case .collector: "单局累计获得 220 碎片"
        case .titanHunter: "单局击败 2 个 Boss"
        case .untouched: "无伤完成 3 个波次"
        }
    }

    var reward: Int {
        switch self {
        case .exterminator, .collector: 8
        case .titanHunter, .untouched: 10
        }
    }

    func isCompleted(
        kills: Int,
        score: Int,
        bosses: Int,
        flawlessWaves: Int
    ) -> Bool {
        switch self {
        case .exterminator: kills >= 120
        case .collector: score >= 220
        case .titanHunter: bosses >= 2
        case .untouched: flawlessWaves >= 3
        }
    }

    func progress(
        kills: Int,
        score: Int,
        bosses: Int,
        flawlessWaves: Int
    ) -> String {
        switch self {
        case .exterminator: "\(min(kills, 120))/120"
        case .collector: "\(min(score, 220))/220"
        case .titanHunter: "\(min(bosses, 2))/2"
        case .untouched: "\(min(flawlessWaves, 3))/3"
        }
    }
}
