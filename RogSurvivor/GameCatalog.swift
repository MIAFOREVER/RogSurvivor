import Foundation
import SpriteKit

enum WeaponPattern {
    case aimed
    case radial
    case burst
    case orbit
    case deployable
    case beam
    case mortar
}

enum WeaponType: String, CaseIterable, Codable {
    case pulseCannon
    case scattergun
    case rivetRepeater
    case phaseCarbine
    case railLance
    case prismNeedle
    case meteorTube
    case gravityMortar
    case clusterPod
    case arcCoil
    case ionSplitter
    case gravityLens
    case emberSprayer
    case magmaOrb
    case coronaEmitter
    case starBlades
    case quantumBoomerang
    case cuttingHalo
    case droneSwarm
    case sentryCapsule
    case repairBot
    case sporeInjector
    case leechHose
    case miningLaser

    var title: String {
        return switch self {
        case .pulseCannon: "脉冲手炮"
        case .scattergun: "废土霰射器"
        case .rivetRepeater: "铆钉连发器"
        case .phaseCarbine: "三相卡宾枪"
        case .railLance: "磁轨长枪"
        case .prismNeedle: "棱镜针"
        case .meteorTube: "流星火箭筒"
        case .gravityMortar: "引力迫击炮"
        case .clusterPod: "蜂巢集束弹"
        case .arcCoil: "电弧线圈"
        case .ionSplitter: "离子分流器"
        case .gravityLens: "重力透镜"
        case .emberSprayer: "余烬喷射器"
        case .magmaOrb: "熔岩孢球"
        case .coronaEmitter: "日冕放射器"
        case .starBlades: "星环飞刃"
        case .quantumBoomerang: "量子回旋镖"
        case .cuttingHalo: "切割光环"
        case .droneSwarm: "蜂群无人机"
        case .sentryCapsule: "哨戒胶囊"
        case .repairBot: "维修机器人"
        case .sporeInjector: "孢子注射器"
        case .leechHose: "吸能软管"
        case .miningLaser: "采矿激光"
        }
    }

    var detail: String {
        return switch self {
        case .pulseCannon: "稳定单发；高品质获得贯穿和强化弹"
        case .scattergun: "近距离多弹丸爆发"
        case .rivetRepeater: "高频射击，拾取会让它加速"
        case .phaseCarbine: "三连点射，末发擅长暴击"
        case .railLance: "超长射程并贯穿整列敌人"
        case .prismNeedle: "标记目标并向邻近敌人折射"
        case .meteorTube: "重型范围爆炸并留下灼烧"
        case .gravityMortar: "预判落点并牵引敌群"
        case .clusterPod: "爆炸后释放追踪子弹"
        case .arcCoil: "电流在多个目标间跳跃"
        case .ionSplitter: "交叉发射两道能量弹"
        case .gravityLens: "环绕角色并周期发射脉冲"
        case .emberSprayer: "短程高频火焰并施加灼烧"
        case .magmaOrb: "缓慢飞行并沿途留下熔池"
        case .coronaEmitter: "对近身敌人持续放射"
        case .starBlades: "向全方向发射短程飞刃"
        case .quantumBoomerang: "往返命中，返回时更致命"
        case .cuttingHalo: "持续环绕角色的近身光刃"
        case .droneSwarm: "多架无人机发射追踪弹"
        case .sentryCapsule: "每波部署固定炮塔"
        case .repairBot: "环绕射击并周期治疗"
        case .sporeInjector: "施加腐蚀和孢化"
        case .leechHose: "近程持续吸取生命"
        case .miningLaser: "击杀可能额外产出星屑"
        }
    }

    var symbol: String {
        switch self {
        case .pulseCannon: "➤"
        case .scattergun: "∴"
        case .rivetRepeater: "≋"
        case .phaseCarbine: "≡"
        case .railLance: "━"
        case .prismNeedle: "◇"
        case .meteorTube: "◉"
        case .gravityMortar: "⌒"
        case .clusterPod: "✣"
        case .arcCoil: "ϟ"
        case .ionSplitter: "×"
        case .gravityLens: "◎"
        case .emberSprayer: "♨"
        case .magmaOrb: "●"
        case .coronaEmitter: "☀"
        case .starBlades: "✣"
        case .quantumBoomerang: "◒"
        case .cuttingHalo: "◌"
        case .droneSwarm: "⬢"
        case .sentryCapsule: "⌬"
        case .repairBot: "⚙"
        case .sporeInjector: "☣"
        case .leechHose: "♦"
        case .miningLaser: "◆"
        }
    }

    var color: SKColor {
        switch primaryTag {
        case .ballistic: .gameBlue
        case .precision: .gameYellow
        case .explosive: .gameCoral
        case .resonance: .gameCyan
        case .burning: SKColor(red: 1, green: 0.52, blue: 0.16, alpha: 1)
        case .orbit: .gamePurple
        case .engineering: .gameGreen
        case .biotech: .gamePink
        case .recycling: .gameYellow
        case .primal: .gameCream
        }
    }

    var tags: [WeaponTag] {
        switch self {
        case .pulseCannon: [.ballistic, .primal]
        case .scattergun: [.ballistic, .explosive]
        case .rivetRepeater: [.ballistic, .recycling]
        case .phaseCarbine: [.ballistic, .precision]
        case .railLance: [.precision, .resonance]
        case .prismNeedle: [.precision, .resonance]
        case .meteorTube: [.explosive, .burning]
        case .gravityMortar: [.explosive, .engineering]
        case .clusterPod: [.explosive, .engineering]
        case .arcCoil: [.resonance, .engineering]
        case .ionSplitter: [.resonance, .ballistic]
        case .gravityLens: [.resonance, .primal]
        case .emberSprayer: [.burning, .biotech]
        case .magmaOrb: [.burning, .explosive]
        case .coronaEmitter: [.burning, .resonance]
        case .starBlades: [.orbit, .primal]
        case .quantumBoomerang: [.orbit, .precision]
        case .cuttingHalo: [.orbit, .engineering]
        case .droneSwarm: [.engineering, .ballistic]
        case .sentryCapsule: [.engineering, .recycling]
        case .repairBot: [.engineering, .biotech]
        case .sporeInjector: [.biotech, .precision]
        case .leechHose: [.biotech, .primal]
        case .miningLaser: [.recycling, .resonance]
        }
    }

    var primaryTag: WeaponTag { tags[0] }

    var pattern: WeaponPattern {
        switch self {
        case .starBlades, .coronaEmitter: .radial
        case .gravityLens, .cuttingHalo: .orbit
        case .sentryCapsule, .repairBot: .deployable
        case .leechHose, .miningLaser: .beam
        case .gravityMortar: .mortar
        case .phaseCarbine: .burst
        default: .aimed
        }
    }

    var baseDamage: CGFloat {
        switch self {
        case .pulseCannon: 12
        case .scattergun: 6
        case .rivetRepeater: 5
        case .phaseCarbine: 9
        case .railLance: 38
        case .prismNeedle: 16
        case .meteorTube: 42
        case .gravityMortar: 32
        case .clusterPod: 24
        case .arcCoil: 15
        case .ionSplitter: 10
        case .gravityLens: 8
        case .emberSprayer: 3
        case .magmaOrb: 21
        case .coronaEmitter: 7
        case .starBlades: 9
        case .quantumBoomerang: 18
        case .cuttingHalo: 5
        case .droneSwarm: 6
        case .sentryCapsule: 11
        case .repairBot: 4
        case .sporeInjector: 13
        case .leechHose: 7
        case .miningLaser: 10
        }
    }

    var weaponCoefficient: CGFloat {
        switch self {
        case .pulseCannon: 0.65
        case .scattergun: 0.22
        case .rivetRepeater: 0.28
        case .phaseCarbine: 0.36
        case .railLance: 1.40
        case .prismNeedle: 0.45
        case .meteorTube: 0.85
        case .gravityMortar: 0.55
        case .ionSplitter: 0.30
        case .starBlades: 0.30
        case .quantumBoomerang: 0.65
        case .cuttingHalo: 0.25
        case .sporeInjector: 0.35
        default: 0
        }
    }

    var engineeringCoefficient: CGFloat {
        switch self {
        case .gravityMortar: 0.45
        case .clusterPod: 0.75
        case .arcCoil: 0.40
        case .cuttingHalo: 0.20
        case .droneSwarm: 0.55
        case .sentryCapsule: 0.70
        case .repairBot: 0.40
        case .miningLaser: 0.30
        default: 0
        }
    }

    var erosionCoefficient: CGFloat {
        switch self {
        case .prismNeedle: 0.35
        case .arcCoil: 0.40
        case .ionSplitter: 0.20
        case .gravityLens: 0.55
        case .emberSprayer: 0.20
        case .magmaOrb: 0.75
        case .coronaEmitter: 0.32
        case .sporeInjector: 0.55
        case .leechHose: 0.35
        case .miningLaser: 0.25
        default: 0
        }
    }

    var baseInterval: TimeInterval {
        switch self {
        case .pulseCannon: 0.48
        case .scattergun: 1.02
        case .rivetRepeater: 0.20
        case .phaseCarbine: 0.82
        case .railLance: 1.35
        case .prismNeedle: 0.72
        case .meteorTube: 1.70
        case .gravityMortar: 1.55
        case .clusterPod: 1.30
        case .arcCoil: 0.86
        case .ionSplitter: 0.58
        case .gravityLens: 0.30
        case .emberSprayer: 0.22
        case .magmaOrb: 1.05
        case .coronaEmitter: 0.18
        case .starBlades: 1.42
        case .quantumBoomerang: 0.90
        case .cuttingHalo: 0.16
        case .droneSwarm: 0.32
        case .sentryCapsule: 0.62
        case .repairBot: 0.48
        case .sporeInjector: 0.76
        case .leechHose: 0.25
        case .miningLaser: 0.50
        }
    }

    var projectileSpeed: CGFloat {
        switch self {
        case .railLance, .prismNeedle: 820
        case .arcCoil, .ionSplitter, .miningLaser: 700
        case .droneSwarm, .clusterPod: 680
        case .meteorTube, .gravityMortar, .magmaOrb: 300
        case .starBlades, .cuttingHalo, .coronaEmitter: 380
        case .emberSprayer, .leechHose: 350
        default: 560
        }
    }

    var baseVolley: Int {
        switch self {
        case .scattergun: 5
        case .phaseCarbine: 3
        case .ionSplitter: 2
        case .starBlades: 6
        case .emberSprayer: 3
        case .coronaEmitter: 4
        case .droneSwarm: 2
        case .clusterPod: 4
        default: 1
        }
    }

    var spread: CGFloat {
        switch self {
        case .scattergun: 0.70
        case .emberSprayer: 0.40
        case .clusterPod: 0.30
        case .ionSplitter: 0.22
        default: 0
        }
    }

    var pierce: Int {
        switch self {
        case .railLance: 4
        case .arcCoil: 3
        case .starBlades, .prismNeedle: 2
        default: 1
        }
    }

    var splashRadius: CGFloat {
        switch self {
        case .meteorTube: 90
        case .gravityMortar: 82
        case .clusterPod: 64
        case .magmaOrb: 58
        default: 0
        }
    }

    var projectileLifetime: TimeInterval {
        switch self {
        case .starBlades, .emberSprayer, .coronaEmitter, .cuttingHalo: 0.62
        case .leechHose: 0.32
        default: 1.7
        }
    }

    var basePrice: Int {
        switch self {
        case .pulseCannon: 22
        case .scattergun: 26
        case .rivetRepeater: 24
        case .phaseCarbine: 29
        case .railLance: 34
        case .prismNeedle: 30
        case .meteorTube: 38
        case .gravityMortar: 36
        case .clusterPod: 39
        case .arcCoil: 31
        case .ionSplitter: 33
        case .gravityLens: 35
        case .emberSprayer: 28
        case .magmaOrb: 35
        case .coronaEmitter: 42
        case .starBlades: 28
        case .quantumBoomerang: 33
        case .cuttingHalo: 37
        case .droneSwarm: 30
        case .sentryCapsule: 34
        case .repairBot: 36
        case .sporeInjector: 32
        case .leechHose: 35
        case .miningLaser: 40
        }
    }
}

struct WeaponRuntime {
    let type: WeaponType
    var level: Int
    var cooldown: TimeInterval = 0

    var tier: Int {
        get { level }
        set { level = min(4, max(1, newValue)) }
    }

    var damageScale: CGFloat {
        [1.0, 1.32, 1.72, 2.25][min(4, max(1, level)) - 1]
    }

    var intervalScale: CGFloat {
        [1.0, 0.96, 0.91, 0.85][min(4, max(1, level)) - 1]
    }

    var qualitySymbol: String {
        String(repeating: "◆", count: min(4, max(1, level)))
    }
}

enum HeroType: String, CaseIterable, Codable {
    case pioneer
    case gunslinger
    case bulwark
    case engineer
    case stormcaller
    case harvester
    case ashen
    case demolitionist
    case broker
    case gambler
    case oneArmed
    case replicator
    case purifier
    case pacifist
    case archivist
    case matriarch

    var title: String {
        switch self {
        case .pioneer: "拓荒薯"
        case .gunslinger: "快枪薯"
        case .bulwark: "堡垒薯"
        case .engineer: "机巧薯"
        case .stormcaller: "唤雷薯"
        case .harvester: "收割薯"
        case .ashen: "灰烬薯"
        case .demolitionist: "爆破薯"
        case .broker: "经纪薯"
        case .gambler: "赌徒薯"
        case .oneArmed: "独臂薯"
        case .replicator: "复制薯"
        case .purifier: "净化薯"
        case .pacifist: "和平薯"
        case .archivist: "档案薯"
        case .matriarch: "母体薯"
        }
    }

    var subtitle: String {
        switch self {
        case .pioneer: "不同武器标签越多，火力越高"
        case .gunslinger: "高速弹幕，牺牲生命与射程"
        case .bulwark: "静止蓄力，以护甲正面换伤"
        case .engineer: "部署物、无人机与资源回收"
        case .stormcaller: "感电能够暴击并连锁"
        case .harvester: "生命越低，伤害越高"
        case .ashen: "将整片战场点燃"
        case .demolitionist: "扩大每一次爆炸"
        case .broker: "囤积星屑赚取复利"
        case .gambler: "用高幸运操纵商店"
        case .oneArmed: "仅一把武器，但强化到极致"
        case .replicator: "限制武器种类，奖励重复装备"
        case .purifier: "控制霉化并从净化中成长"
        case .pacifist: "靠击退和存活获取收益"
        case .archivist: "每五波获得随机角色特性"
        case .matriarch: "完全拥抱霉潮的高风险形态"
        }
    }

    var lore: String {
        switch self {
        case .pioneer: "第七码头最后一位巡逻员，在霉潮降临时独自守住了撤离通道。"
        case .gunslinger: "地下竞速场的冠军。她把引擎拆成枪械，只为了跑得比危险更快。"
        case .bulwark: "旧联邦的移动城墙，每一道划痕都来自一次没有后退的战斗。"
        case .engineer: "相信任何废料都有第二次生命——包括失控的军用无人机。"
        case .stormcaller: "在水晶矿脉中醒来，体内回响着星球深处的雷声。"
        case .harvester: "被霉潮侵蚀却保留理智，以敌人的能量压制体内孢子。"
        case .ashen: "曾负责铸造厂炉心，如今只听从火焰最诚实的命令。"
        case .demolitionist: "她不相信打不开的门，只相信炸药还不够多。"
        case .broker: "末日不是经济的终点，只是一次价格发现。"
        case .gambler: "从来不问概率高不高，只问下一次重掷要多少钱。"
        case .oneArmed: "失去一条手臂后，他终于决定只把一件事做到完美。"
        case .replicator: "复制舱的事故产物，脑海里永远有另一个自己在扣扳机。"
        case .purifier: "负责焚烧感染样本，却发现霉潮也能成为武器。"
        case .pacifist: "不愿夺走任何生命，但很愿意把怪物推到地图另一边。"
        case .archivist: "她读过每一份战斗记录，也准备亲手验证每一个结论。"
        case .matriarch: "感染与宿主的界线已经消失，只剩下一个共同意志。"
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
        case .ashen: "♨"
        case .demolitionist: "◉"
        case .broker: "◆"
        case .gambler: "♢"
        case .oneArmed: "Ⅰ"
        case .replicator: "Ⅱ"
        case .purifier: "♧"
        case .pacifist: "☮"
        case .archivist: "▤"
        case .matriarch: "♛"
        }
    }

    var color: SKColor {
        switch self {
        case .pioneer, .broker, .gambler: .gameYellow
        case .gunslinger, .demolitionist: .gameCoral
        case .bulwark, .oneArmed: .gameBlue
        case .engineer, .pacifist: .gameGreen
        case .stormcaller, .purifier: .gameCyan
        case .harvester, .archivist, .matriarch: .gamePurple
        case .ashen, .replicator: .gamePink
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
        case .ashen: .emberSprayer
        case .demolitionist: .meteorTube
        case .broker: .miningLaser
        case .gambler: .prismNeedle
        case .oneArmed: .phaseCarbine
        case .replicator: .rivetRepeater
        case .purifier: .sporeInjector
        case .pacifist: .repairBot
        case .archivist: .phaseCarbine
        case .matriarch: .leechHose
        }
    }

    var preferredTags: [WeaponTag] {
        switch self {
        case .pioneer: [.primal, .ballistic]
        case .gunslinger: [.ballistic, .precision]
        case .bulwark: [.primal, .precision]
        case .engineer: [.engineering, .recycling]
        case .stormcaller: [.resonance, .precision]
        case .harvester: [.orbit, .biotech]
        case .ashen: [.burning, .biotech]
        case .demolitionist: [.explosive, .engineering]
        case .broker: [.recycling, .resonance]
        case .gambler: [.precision, .recycling]
        case .oneArmed: [.ballistic]
        case .replicator: [.ballistic, .primal]
        case .purifier: [.biotech, .resonance]
        case .pacifist: [.engineering, .primal]
        case .archivist: WeaponTag.allCases
        case .matriarch: [.biotech, .primal]
        }
    }

    var maxWeaponSlots: Int {
        self == .oneArmed ? 1 : 6
    }

    func isUnlocked(in save: GameSaveData) -> Bool {
        switch self {
        case .pioneer: true
        case .gunslinger: save.runs >= 1 || save.totalCores >= 12
        case .bulwark: save.highWave >= 4 || save.totalCores >= 25
        case .engineer: save.totalCores >= 40
        case .stormcaller: save.highWave >= 8 || save.totalCores >= 60
        case .harvester: save.highWave >= 12 || save.totalCores >= 95
        case .ashen: save.totalBurnStacks >= 500 || save.victories >= 1
        case .demolitionist: save.maxExplosionKills >= 8 || save.victories >= 2
        case .broker: save.maxHeldScrap >= 160 || save.totalCores >= 140
        case .gambler: save.totalRerolls >= 30 || save.totalCores >= 180
        case .oneArmed: save.singleWeaponBossKills >= 1 || save.victories >= 3
        case .replicator: save.sameWeaponVictory || save.victories >= 4
        case .purifier: save.maxCorruption >= 75 || save.victories >= 5
        case .pacifist: save.lowKillWaveCompleted || save.victories >= 6
        case .archivist: save.unlockedHeroCount >= 10
        case .matriarch: save.maxThreatCompleted >= 5
        }
    }

    func unlockText(in save: GameSaveData) -> String {
        if isUnlocked(in: save) { return "已解锁" }
        return switch self {
        case .pioneer: "已解锁"
        case .gunslinger: "完成 1 局"
        case .bulwark: "抵达第 4 波"
        case .engineer: "累计获得 40 星核"
        case .stormcaller: "抵达第 8 波"
        case .harvester: "抵达第 12 波"
        case .ashen: "累计施加 500 层灼烧"
        case .demolitionist: "一次爆炸击败 8 个敌人"
        case .broker: "单局持有 160 星屑"
        case .gambler: "累计重掷 30 次"
        case .oneArmed: "用单武器击败首领"
        case .replicator: "六持同一武器通关"
        case .purifier: "达到 75 霉化"
        case .pacifist: "低击杀完成一波"
        case .archivist: "解锁 10 名角色"
        case .matriarch: "通关威胁 5"
        }
    }

    func apply(to stats: inout PlayerStats) {
        switch self {
        case .pioneer:
            stats.globalDamage += 0.10
            stats.maxHealth += 10
        case .gunslinger:
            stats.maxHealth -= 20
            stats.attackSpeed += 0.30
            stats.movementSpeed *= 1.12
            stats.rangeMultiplier -= 0.10
        case .bulwark:
            stats.maxHealth += 55
            stats.armor += 4
            stats.movementSpeed *= 0.82
            stats.thorns += 10
        case .engineer:
            stats.engineering += 12
            stats.pickupRange += 60
            stats.weaponPower -= 8
            stats.globalDamage -= 0.08
        case .stormcaller:
            stats.erosion += 10
            stats.critChance += 0.08
            stats.maxHealth -= 12
        case .harvester:
            stats.lifeSteal += 0.06
            stats.dodgeChance += 0.08
            stats.healingEfficiency -= 0.20
        case .ashen:
            stats.erosion += 12
            stats.globalDamage -= 0.15
            stats.armor -= 2
        case .demolitionist:
            stats.projectileSize += 0.30
            stats.explosionDamage += 0.20
            stats.attackSpeed -= 0.15
            stats.projectileSpeed *= 0.80
        case .broker:
            stats.globalDamage -= 0.10
            stats.harvesting += 3
            stats.shopDiscount -= 0.08
        case .gambler:
            stats.luck += 50
        case .oneArmed:
            stats.attackSpeed += 1.20
            stats.globalDamage += 1.60
        case .replicator:
            stats.attackSpeed += 0.08
        case .purifier:
            stats.corruption = 25
            stats.healingEfficiency -= 0.10
            stats.erosion += 8
        case .pacifist:
            stats.knockback += 1
            stats.movementSpeed *= 1.15
            stats.globalDamage -= 0.70
            stats.critChance = 0
        case .archivist:
            stats.maxHealth *= 0.95
            stats.globalDamage -= 0.05
            stats.attackSpeed -= 0.05
            stats.movementSpeed *= 0.95
            stats.projectileSpeed *= 0.95
            stats.rangeMultiplier *= 0.95
            stats.healingEfficiency *= 0.95
        case .matriarch:
            stats.corruption = 100
            stats.currencyMultiplier -= 0.15
        }
        stats.health = stats.maxHealth
        stats.clamp()
    }
}

enum ArenaType: String, CaseIterable, Codable {
    case scrapOrbit
    case crystalHollows
    case emberFoundry
    case fungalDepths
    case driftingPrison
    case seventhDock

    var title: String {
        switch self {
        case .scrapOrbit: "废铁轨道"
        case .crystalHollows: "回声晶窟"
        case .emberFoundry: "余烬铸造厂"
        case .fungalDepths: "深层菌圃"
        case .driftingPrison: "漂流监牢"
        case .seventhDock: "第七码头"
        }
    }

    var subtitle: String {
        switch self {
        case .scrapOrbit: "标准规则 · 货箱形成临时掩体"
        case .crystalHollows: "敌人更快 · 水晶折射弹体"
        case .emberFoundry: "周期热浪 · 精英更多"
        case .fungalDepths: "初始霉化 · 可收集净化花"
        case .driftingPrison: "引力偏转 · 击退强化"
        case .seventhDock: "继承其他战区的随机规则"
        }
    }

    var lore: String {
        switch self {
        case .scrapOrbit: "环绕薯星的废弃货运站，如今是幸存者回收武器的第一道防线。"
        case .crystalHollows: "星球深处的水晶会记录声音，也会把霉潮低语放大千倍。"
        case .emberFoundry: "旧联邦制造核心的工厂仍在运转，控制熔炉的已不再是工人。"
        case .fungalDepths: "霉潮最早的培育区，每一朵花都可能是解药，也可能是陷阱。"
        case .driftingPrison: "轨道崩坏后，整座监牢在失重与重力潮汐间反复撕裂。"
        case .seventhDock: "所有广播最终都指向这里，轨道炮与母体只隔最后一道门。"
        }
    }

    var symbol: String {
        switch self {
        case .scrapOrbit: "⌬"
        case .crystalHollows: "◇"
        case .emberFoundry: "♨"
        case .fungalDepths: "☣"
        case .driftingPrison: "◎"
        case .seventhDock: "⚿"
        }
    }

    var color: SKColor {
        switch self {
        case .scrapOrbit: .gameBlue
        case .crystalHollows: .gameCyan
        case .emberFoundry: .gameCoral
        case .fungalDepths: .gameGreen
        case .driftingPrison: .gamePurple
        case .seventhDock: .gameYellow
        }
    }

    var rewardMultiplier: CGFloat {
        switch self {
        case .scrapOrbit: 1
        case .crystalHollows: 1.18
        case .emberFoundry: 1.30
        case .fungalDepths: 1.38
        case .driftingPrison: 1.45
        case .seventhDock: 1.60
        }
    }

    var enemySpeedMultiplier: CGFloat {
        switch self {
        case .crystalHollows: 1.10
        case .emberFoundry: 1.05
        case .driftingPrison: 1.04
        default: 1
        }
    }

    var priceMultiplier: CGFloat {
        self == .seventhDock ? 1.08 : 1
    }

    func isUnlocked(in save: GameSaveData) -> Bool {
        switch self {
        case .scrapOrbit: true
        case .crystalHollows: save.highWave >= 5 || save.totalCores >= 35
        case .emberFoundry: save.highWave >= 10 || save.totalCores >= 75
        case .fungalDepths: save.maxCorruption >= 50 || save.victories >= 2
        case .driftingPrison: save.maxThreatCompleted >= 3 || save.victories >= 4
        case .seventhDock: save.completedArenaCount >= 5
        }
    }

    func unlockText(in save: GameSaveData) -> String {
        if isUnlocked(in: save) { return "已解锁" }
        return switch self {
        case .scrapOrbit: "已解锁"
        case .crystalHollows: "抵达第 5 波"
        case .emberFoundry: "抵达第 10 波"
        case .fungalDepths: "达到 50 霉化"
        case .driftingPrison: "通关任意威胁 3"
        case .seventhDock: "通关前五个战区"
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
    var highestThreatByArena: [String: Int] = [:]
    var victoriesByHero: [String: Int] = [:]
    var victoriesByArena: [String: Int] = [:]
    var totalRerolls = 0
    var totalBurnStacks = 0
    var maxExplosionKills = 0
    var maxHeldScrap = 0
    var maxCorruption: CGFloat = 0
    var singleWeaponBossKills = 0
    var sameWeaponVictory = false
    var lowKillWaveCompleted = false

    private enum CodingKeys: String, CodingKey {
        case totalCores, lifetimeKills, highWave, highScore, runs, victories
        case permanentPower, permanentVitality, permanentScavenging
        case highestThreatByArena, victoriesByHero, victoriesByArena
        case totalRerolls, totalBurnStacks, maxExplosionKills, maxHeldScrap
        case maxCorruption, singleWeaponBossKills, sameWeaponVictory
        case lowKillWaveCompleted
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalCores = try container.decodeIfPresent(Int.self, forKey: .totalCores) ?? 0
        lifetimeKills = try container.decodeIfPresent(Int.self, forKey: .lifetimeKills) ?? 0
        highWave = try container.decodeIfPresent(Int.self, forKey: .highWave) ?? 0
        highScore = try container.decodeIfPresent(Int.self, forKey: .highScore) ?? 0
        runs = try container.decodeIfPresent(Int.self, forKey: .runs) ?? 0
        victories = try container.decodeIfPresent(Int.self, forKey: .victories) ?? 0
        permanentPower = try container.decodeIfPresent(Int.self, forKey: .permanentPower) ?? 0
        permanentVitality = try container.decodeIfPresent(Int.self, forKey: .permanentVitality) ?? 0
        permanentScavenging = try container.decodeIfPresent(Int.self, forKey: .permanentScavenging) ?? 0
        highestThreatByArena = try container.decodeIfPresent([String: Int].self, forKey: .highestThreatByArena) ?? [:]
        victoriesByHero = try container.decodeIfPresent([String: Int].self, forKey: .victoriesByHero) ?? [:]
        victoriesByArena = try container.decodeIfPresent([String: Int].self, forKey: .victoriesByArena) ?? [:]
        totalRerolls = try container.decodeIfPresent(Int.self, forKey: .totalRerolls) ?? 0
        totalBurnStacks = try container.decodeIfPresent(Int.self, forKey: .totalBurnStacks) ?? 0
        maxExplosionKills = try container.decodeIfPresent(Int.self, forKey: .maxExplosionKills) ?? 0
        maxHeldScrap = try container.decodeIfPresent(Int.self, forKey: .maxHeldScrap) ?? 0
        maxCorruption = try container.decodeIfPresent(CGFloat.self, forKey: .maxCorruption) ?? 0
        singleWeaponBossKills = try container.decodeIfPresent(Int.self, forKey: .singleWeaponBossKills) ?? 0
        sameWeaponVictory = try container.decodeIfPresent(Bool.self, forKey: .sameWeaponVictory) ?? false
        lowKillWaveCompleted = try container.decodeIfPresent(Bool.self, forKey: .lowKillWaveCompleted) ?? false
    }

    var maxThreatCompleted: Int {
        highestThreatByArena.values.max() ?? 0
    }

    var completedArenaCount: Int {
        victoriesByArena.values.filter { $0 > 0 }.count
    }

    var unlockedHeroCount: Int {
        HeroType.allCases.filter { $0.isUnlockedWithoutCount(in: self) }.count
    }

    func highestThreat(for arena: ArenaType) -> Int {
        highestThreatByArena[arena.rawValue, default: -1]
    }

    func isThreatUnlocked(_ threat: ThreatLevel, for arena: ArenaType) -> Bool {
        threat.rawValue == 0 || highestThreat(for: arena) >= threat.rawValue - 1
    }

    mutating func applyPermanentBonuses(to stats: inout PlayerStats) {
        stats.globalDamage += CGFloat(permanentPower) * 0.01
        stats.maxHealth += CGFloat(permanentVitality) * 1.5
        stats.harvesting += permanentScavenging
        stats.health = stats.maxHealth
    }

    func upgradeCost(for track: PermanentTrack) -> Int {
        12 + track.rank(in: self) * 10
    }
}

private extension HeroType {
    func isUnlockedWithoutCount(in save: GameSaveData) -> Bool {
        if self == .archivist { return save.victories >= 6 }
        return isUnlocked(in: save)
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
        case .power: "每级使初始全伤害 +1%"
        case .vitality: "每级使初始生命 +1.5"
        case .scavenging: "每级使每波回收 +1"
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
    case weapon(WeaponType, tier: Int)
    case item(ItemDefinition)

    var title: String {
        switch self {
        case .weapon(let weapon, let tier):
            "\(weapon.title) \(String(repeating: "◆", count: tier))"
        case .item(let item):
            item.title
        }
    }

    var detail: String {
        switch self {
        case .weapon(let weapon, _): weapon.detail
        case .item(let item): item.detail
        }
    }

    var symbol: String {
        switch self {
        case .weapon(let weapon, _): weapon.symbol
        case .item(let item): item.symbol
        }
    }

    var color: SKColor {
        switch self {
        case .weapon(let weapon, _): weapon.color
        case .item(let item): item.color
        }
    }

    var rarityTitle: String {
        switch self {
        case .weapon(_, let tier): ["I", "II", "III", "IV"][tier - 1]
        case .item(let item): item.rarity.title
        }
    }
}

struct ShopOffer {
    let kind: ShopOfferKind
    var price: Int
    var isLocked = false
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
            body: "来自深空的孢子风暴吞没外环殖民地。它不会立刻杀死宿主，而会把恐惧、贪婪与本能编织成新的生命。",
            color: .gamePurple
        ),
        LoreEntry(
            title: "最后广播",
            subtitle: "第七码头",
            body: "联邦舰队失联前留下唯一指令：收集散落星核，重启轨道炮，为地表幸存者打开离开薯星的航路。",
            color: .gameCyan
        ),
        LoreEntry(
            title: "星核协议",
            subtitle: "基地成长",
            body: "每次突围收集的星核都会强化下一位战士。失败不是结束，而是下一次构筑的燃料。",
            color: .gameYellow
        ),
        LoreEntry(
            title: "共生实验",
            subtitle: "霉化值",
            body: "感染并非只有毁灭。只要在失去自我前停下，霉潮也能提供不可思议的力量。",
            color: .gameGreen
        ),
        LoreEntry(
            title: "漂流监牢",
            subtitle: "零重力事故",
            body: "监牢的引力核心仍在运转，只是它已经忘记哪一个方向才是地面。",
            color: .gameBlue
        ),
        LoreEntry(
            title: "霉潮母体",
            subtitle: "第 20 波之后",
            body: "所有感染体共享同一段脉冲。追踪它穿过二十层封锁，就能找到母体真正的坐标。",
            color: .gameCoral
        )
    ]
}

struct RunMetrics {
    var kills = 0
    var score = 0
    var bosses = 0
    var flawlessWaves = 0
    var lowHealthSeconds: TimeInterval = 0
    var skippedShopPurchases = 0
    var maxCorruption: CGFloat = 0
    var cleansedCorruption: CGFloat = 0
    var dodgedProjectiles = 0
    var recycledOffers = 0
    var maxExplosionKills = 0
    var maxHeldScrap = 0
    var totalBurnStacks = 0
    var maxWeaponCount = 0
    var maxTagCount = 0
}

enum RunContract: String, CaseIterable {
    case exterminator
    case collector
    case titanHunter
    case untouched
    case sixWeapons
    case specialist
    case redline
    case embargo
    case corruptionStudy
    case purification
    case mobility
    case recycling

    var title: String {
        switch self {
        case .exterminator: "清剿协议"
        case .collector: "紧急回收"
        case .titanHunter: "巨像猎手"
        case .untouched: "完美防线"
        case .sixWeapons: "六械同调"
        case .specialist: "专精测试"
        case .redline: "低血协议"
        case .embargo: "采购禁令"
        case .corruptionStudy: "霉化研究"
        case .purification: "净化行动"
        case .mobility: "极限机动"
        case .recycling: "废物利用"
        }
    }

    var detail: String {
        switch self {
        case .exterminator: "击败 300 个敌人"
        case .collector: "累计拾取 500 星屑"
        case .titanHunter: "击败 3 名小型首领"
        case .untouched: "无伤完成 4 个波次"
        case .sixWeapons: "同时装备 6 把武器"
        case .specialist: "同一武器标签达到 6 件"
        case .redline: "低于 35% 生命累计存活 60 秒"
        case .embargo: "连续 3 个商店不购买道具"
        case .corruptionStudy: "达到 75 霉化并保持"
        case .purification: "单局移除 40 霉化"
        case .mobility: "躲过 40 枚敌方弹体"
        case .recycling: "出售或回收 8 件商品"
        }
    }

    var reward: Int {
        switch self {
        case .titanHunter, .untouched, .redline: 10
        case .corruptionStudy: 11
        case .specialist, .embargo, .purification: 9
        default: 8
        }
    }

    func isCompleted(metrics: RunMetrics) -> Bool {
        switch self {
        case .exterminator: metrics.kills >= 300
        case .collector: metrics.score >= 500
        case .titanHunter: metrics.bosses >= 3
        case .untouched: metrics.flawlessWaves >= 4
        case .sixWeapons: metrics.maxWeaponCount >= 6
        case .specialist: metrics.maxTagCount >= 6
        case .redline: metrics.lowHealthSeconds >= 60
        case .embargo: metrics.skippedShopPurchases >= 3
        case .corruptionStudy: metrics.maxCorruption >= 75
        case .purification: metrics.cleansedCorruption >= 40
        case .mobility: metrics.dodgedProjectiles >= 40
        case .recycling: metrics.recycledOffers >= 8
        }
    }

    func progress(metrics: RunMetrics) -> String {
        switch self {
        case .exterminator: "\(min(metrics.kills, 300))/300"
        case .collector: "\(min(metrics.score, 500))/500"
        case .titanHunter: "\(min(metrics.bosses, 3))/3"
        case .untouched: "\(min(metrics.flawlessWaves, 4))/4"
        case .sixWeapons: "\(min(metrics.maxWeaponCount, 6))/6"
        case .specialist: "\(min(metrics.maxTagCount, 6))/6"
        case .redline: "\(Int(min(metrics.lowHealthSeconds, 60)))/60秒"
        case .embargo: "\(min(metrics.skippedShopPurchases, 3))/3"
        case .corruptionStudy: "\(Int(min(metrics.maxCorruption, 75)))/75"
        case .purification: "\(Int(min(metrics.cleansedCorruption, 40)))/40"
        case .mobility: "\(min(metrics.dodgedProjectiles, 40))/40"
        case .recycling: "\(min(metrics.recycledOffers, 8))/8"
        }
    }
}

enum WaveCatalog {
    static let durations: [TimeInterval] = [
        22, 24, 26, 28, 35,
        30, 32, 34, 36, 42,
        36, 38, 40, 42, 45,
        42, 44, 46, 48, 50
    ]

    static func duration(for wave: Int) -> TimeInterval {
        durations[min(20, max(1, wave)) - 1]
    }

    static func threatBudget(for wave: Int) -> CGFloat {
        let value = CGFloat(wave)
        return 12 + 4.2 * value + 0.32 * value * value
    }
}

struct GameSettings: Codable {
    var haptics = true
    var screenShake = true
    var damageNumbers = true
    var reducedEffects = false
    var enemyHealthScale: CGFloat = 1
    var enemyDamageScale: CGFloat = 1
    var enemySpeedScale: CGFloat = 1

    private static let key = "RogSurvivor.settings.v1"

    static func load() -> GameSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return GameSettings()
        }
        return settings
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
