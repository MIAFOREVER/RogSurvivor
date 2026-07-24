import Foundation
import SpriteKit

enum ThreatLevel: Int, CaseIterable, Codable {
    case calm = 0
    case alert
    case severe
    case critical
    case nightmare
    case extinction

    var title: String { "威胁 \(rawValue)" }

    var subtitle: String {
        switch self {
        case .calm: "标准突围"
        case .alert: "高级敌人更早出现"
        case .severe: "商店涨价，首领招式强化"
        case .critical: "小型首领获得精英词缀"
        case .nightmare: "双词缀精英与强化危险区"
        case .extinction: "霉潮完全苏醒"
        }
    }

    var enemyHealthMultiplier: CGFloat {
        [1, 1.12, 1.25, 1.42, 1.62, 1.85][rawValue]
    }

    var enemyDamageMultiplier: CGFloat {
        [1, 1.10, 1.18, 1.28, 1.40, 1.55][rawValue]
    }

    var enemySpeedMultiplier: CGFloat {
        [1, 1.02, 1.04, 1.07, 1.10, 1.14][rawValue]
    }

    var spawnBudgetMultiplier: CGFloat {
        [1, 1.05, 1.10, 1.18, 1.26, 1.35][rawValue]
    }

    var eliteChance: CGFloat {
        [0.04, 0.07, 0.10, 0.14, 0.18, 0.22][rawValue]
    }

    var shopPriceMultiplier: CGFloat {
        [1, 1, 1.05, 1.08, 1.12, 1.15][rawValue]
    }

    var coreMultiplier: CGFloat {
        [1, 1.12, 1.28, 1.48, 1.72, 2.0][rawValue]
    }

    var color: SKColor {
        [.gameGreen, .gameCyan, .gameBlue, .gameYellow, .gameCoral, .gamePurple][rawValue]
    }
}

enum WeaponTag: String, CaseIterable, Codable {
    case ballistic
    case precision
    case explosive
    case resonance
    case burning
    case orbit
    case engineering
    case biotech
    case recycling
    case primal

    var title: String {
        switch self {
        case .ballistic: "弹道"
        case .precision: "精准"
        case .explosive: "爆破"
        case .resonance: "共振"
        case .burning: "灼热"
        case .orbit: "环刃"
        case .engineering: "工程"
        case .biotech: "生化"
        case .recycling: "回收"
        case .primal: "原生"
        }
    }

    var color: SKColor {
        switch self {
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
}

enum ItemRarity: Int, CaseIterable, Codable {
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

enum StatKey: String {
    case maxHealth
    case regeneration
    case lifeSteal
    case armor
    case dodge
    case movement
    case damage
    case attackSpeed
    case critChance
    case critDamage
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
    case shieldPerWave
    case shopDiscount
    case rerollDiscount
    case recycleRefund
    case healingEfficiency
    case corruption
    case currencyMultiplier
    case explosionDamage
    case bossDamage
}

enum SpecialEffect: String, Hashable {
    case extraProjectile
    case extraPierce
    case ricochet
    case eliteDamage
    case lowHealthAttackSpeed
    case shockOnCrit
    case chillChance
    case interestCap
    case freeFirstReroll
    case summonAttackSpeed
    case hazardResistance
    case hurtSpeed
    case missingHealthDamage
    case projectileSpeedDamage
    case closeRangeDamage
    case splitOnKill
    case explosionAftershock
    case chainBonus
    case burnAmplification
    case corrosionSpread
    case critHeal
    case criticalHealthDamage
    case outOfCombatHeal
    case armorFromKnockback
    case dodgeCounter
    case overhealShield
    case extraLife
    case purchaseCorruption
    case lockedWeaponWeight
    case luckToCrit
    case pickupEconomy
    case duplicateDeployable
    case summonDeathBurst
    case corruptionToErosion
    case cleanseGrowth
    case occupiedSlotAttackSpeed
    case emptySlotDamage
    case anvil
    case mirrorWeapon
    case resetPierceOnKill
    case singularityExplosion
    case freeShockJump
    case burnDetonation
    case biotechTierBoost
    case enemySpeed
    case waveDuration
    case freezeAtMax
    case lifestealRamp
    case armorSpeedPenalty
    case dodgeEmpower
    case secondHeart
    case orbitalRecovery
    case monopoly
    case rerollLuck
    case loseScrapOnHit
    case summonCritInheritance
    case duplicateUpgrade
    case corruptionCrown
    case zeroAntibody
    case retryWave
    case finalBossKey
}

enum ItemEffect {
    case stat(StatKey, CGFloat)
    case special(SpecialEffect, CGFloat)
    case heal(CGFloat)
}

struct ItemDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let rarity: ItemRarity
    let basePrice: Int
    let limit: Int?
    let tags: [String]
    let effects: [ItemEffect]

    var color: SKColor { rarity.color }
}

struct RunEffects {
    private(set) var values: [SpecialEffect: CGFloat] = [:]

    subscript(effect: SpecialEffect) -> CGFloat {
        values[effect, default: 0]
    }

    mutating func add(_ effect: SpecialEffect, value: CGFloat) {
        values[effect, default: 0] += value
    }

    func has(_ effect: SpecialEffect) -> Bool {
        self[effect] > 0
    }

    mutating func reset() {
        values.removeAll()
    }
}

struct RunInventory {
    private(set) var counts: [String: Int] = [:]

    subscript(id: String) -> Int {
        counts[id, default: 0]
    }

    var totalCount: Int {
        counts.values.reduce(0, +)
    }

    mutating func add(_ item: ItemDefinition) {
        counts[item.id, default: 0] += 1
    }

    func canAdd(_ item: ItemDefinition) -> Bool {
        guard let limit = item.limit else { return true }
        return self[item.id] < limit
    }

    mutating func reset() {
        counts.removeAll()
    }
}

enum ItemCatalog {
    private static func item(
        _ id: String,
        _ title: String,
        _ detail: String,
        _ symbol: String,
        _ rarity: ItemRarity,
        _ price: Int,
        limit: Int? = nil,
        tags: [String],
        effects: [ItemEffect]
    ) -> ItemDefinition {
        ItemDefinition(
            id: id,
            title: title,
            detail: detail,
            symbol: symbol,
            rarity: rarity,
            basePrice: price,
            limit: limit,
            tags: tags,
            effects: effects
        )
    }

    static let all: [ItemDefinition] = common + refined + rare + legendary

    static let common: [ItemDefinition] = [
        item("reinforced_skin", "加固外皮", "最大生命 +8", "♥", .common, 14, tags: ["生命"], effects: [.stat(.maxHealth, 8)]),
        item("repair_gel", "维修凝胶", "再生 +0.8，移速 -2%", "♧", .common, 15, tags: ["治疗", "生命"], effects: [.stat(.regeneration, 0.8), .stat(.movement, -0.02)]),
        item("alloy_shim", "合金垫片", "护甲 +1", "⬡", .common, 13, tags: ["防御"], effects: [.stat(.armor, 1)]),
        item("light_soles", "轻量鞋底", "移速 +6%，护甲 -1", "➤", .common, 12, tags: ["速度"], effects: [.stat(.movement, 0.06), .stat(.armor, -1)]),
        item("calibration_gear", "校准齿轮", "攻速 +6%", "⌁", .common, 14, tags: ["攻速"], effects: [.stat(.attackSpeed, 0.06)]),
        item("energy_core", "高能弹芯", "全伤害 +6%，最大生命 -3", "✦", .common, 15, tags: ["伤害", "风险"], effects: [.stat(.damage, 0.06), .stat(.maxHealth, -3)]),
        item("precision_lens", "精准镜片", "暴击 +4%，射程 -3%", "⊕", .common, 14, tags: ["暴击"], effects: [.stat(.critChance, 0.04), .stat(.range, -0.03)]),
        item("long_rifling", "长膛线", "射程 +15%，攻速 -3%", "↔", .common, 13, tags: ["射程", "弹道"], effects: [.stat(.range, 0.15), .stat(.attackSpeed, -0.03)]),
        item("compressed_powder", "压缩火药", "弹速 +18%，范围 -3%", "»", .common, 12, tags: ["弹速"], effects: [.stat(.projectileSpeed, 0.18), .stat(.areaSize, -0.03)]),
        item("gravity_clasp", "引力扣", "拾取范围 +40", "◎", .common, 12, tags: ["拾取"], effects: [.stat(.pickupRange, 40)]),
        item("salvage_bag", "回收袋", "每波回收 +5", "◆", .common, 16, tags: ["经济"], effects: [.stat(.harvesting, 5)]),
        item("dice_chip", "骰子芯片", "幸运 +8", "♢", .common, 15, tags: ["幸运"], effects: [.stat(.luck, 8)]),
        item("tool_pliers", "工具钳", "工程 +3", "⚙", .common, 14, tags: ["工程"], effects: [.stat(.engineering, 3)]),
        item("conductive_fork", "导电叉", "侵蚀 +3", "ϟ", .common, 14, tags: ["共振"], effects: [.stat(.erosion, 3)]),
        item("weapon_grip", "武器握把", "武装 +3", "➤", .common, 14, tags: ["弹道"], effects: [.stat(.weaponPower, 3)]),
        item("medical_patch", "医疗贴", "最大生命 +3，立即回复 25", "+", .common, 11, tags: ["治疗"], effects: [.stat(.maxHealth, 3), .heal(25)]),
        item("blood_sample", "血液样本", "生命偷取 +1%，最大生命 -2", "♦", .common, 16, tags: ["生化"], effects: [.stat(.lifeSteal, 0.01), .stat(.maxHealth, -2)]),
        item("elastic_bracer", "弹性护腕", "击退 +20%", "↟", .common, 11, tags: ["控制"], effects: [.stat(.knockback, 0.20)]),
        item("small_battery", "小型电池", "每波获得 5 护盾", "▰", .common, 15, limit: 5, tags: ["防御", "工程"], effects: [.stat(.shieldPerWave, 5)]),
        item("coupon", "折价券", "商店折扣 +3%", "%", .common, 18, limit: 6, tags: ["商店"], effects: [.stat(.shopDiscount, 0.03)]),
        item("recycle_label", "回收标签", "回收返还 +5%", "↺", .common, 15, limit: 5, tags: ["商店", "经济"], effects: [.stat(.recycleRefund, 0.05)]),
        item("thermal_lining", "隔热衬里", "危险区伤害 -15%，最大生命 +3", "▧", .common, 12, limit: 3, tags: ["防御"], effects: [.stat(.maxHealth, 3), .special(.hazardResistance, 0.15)]),
        item("sealed_spore", "密封孢子瓶", "侵蚀 +4，霉化 +4", "☣", .common, 13, tags: ["生化", "风险"], effects: [.stat(.erosion, 4), .stat(.corruption, 4)]),
        item("old_ration", "旧联邦口粮", "最大生命 +5，幸运 +3，攻速 -2%", "◈", .common, 13, tags: ["生命", "幸运"], effects: [.stat(.maxHealth, 5), .stat(.luck, 3), .stat(.attackSpeed, -0.02)])
    ]

    static let refined: [ItemDefinition] = [
        item("twin_barrel", "双联枪管", "额外弹丸 +1，全伤害 -12%", "≋", .refined, 34, limit: 2, tags: ["弹道", "风险"], effects: [.special(.extraProjectile, 1), .stat(.damage, -0.12)]),
        item("piercing_sleeve", "穿甲套筒", "所有弹体穿透 +1", "━", .refined, 30, limit: 3, tags: ["弹道"], effects: [.special(.extraPierce, 1)]),
        item("ricochet_crystal", "回跳晶体", "弹射 +1，射程 -10%", "◇", .refined, 33, limit: 2, tags: ["共振"], effects: [.special(.ricochet, 1), .stat(.range, -0.10)]),
        item("blast_mix", "爆燃混合剂", "爆炸范围 +18%，护甲 -1", "◉", .refined, 29, tags: ["爆破"], effects: [.stat(.areaSize, 0.18), .stat(.armor, -1)]),
        item("hunter_dial", "猎手刻度盘", "对精英和首领伤害 +15%", "⌖", .refined, 31, limit: 3, tags: ["精准"], effects: [.stat(.bossDamage, 0.15), .special(.eliteDamage, 0.15)]),
        item("crit_battery", "暴击电池", "暴伤 +30%，攻速 -5%", "✧", .refined, 28, tags: ["暴击"], effects: [.stat(.critDamage, 0.30), .stat(.attackSpeed, -0.05)]),
        item("adrenal_pump", "肾上腺泵", "低于半血时攻速 +22%", "!", .refined, 32, limit: 2, tags: ["生命", "攻速"], effects: [.special(.lowHealthAttackSpeed, 0.22)]),
        item("static_capacitor", "静电电容", "暴击有 20% 概率施加感电", "ϟ", .refined, 35, limit: 3, tags: ["共振", "暴击"], effects: [.special(.shockOnCrit, 0.20)]),
        item("condensing_nozzle", "冷凝喷嘴", "命中有 8% 概率施加冻滞", "❄", .refined, 30, limit: 3, tags: ["控制"], effects: [.special(.chillChance, 0.08)]),
        item("nanofiber", "纳米纤维层", "最大生命 +15，护甲 +1，移速 -5%", "▦", .refined, 33, tags: ["生命", "防御"], effects: [.stat(.maxHealth, 15), .stat(.armor, 1), .stat(.movement, -0.05)]),
        item("reactive_shield", "反应护盾", "每波护盾 +12，闪避 -3%", "▰", .refined, 32, limit: 4, tags: ["防御"], effects: [.stat(.shieldPerWave, 12), .stat(.dodge, -0.03)]),
        item("phase_cloak", "相位披风", "闪避 +8%，护甲 -2", "◌", .refined, 31, tags: ["闪避", "风险"], effects: [.stat(.dodge, 0.08), .stat(.armor, -2)]),
        item("transfusion_pump", "输血泵", "偷取 +3%，最大生命 -10", "♦", .refined, 36, limit: 3, tags: ["生化", "风险"], effects: [.stat(.lifeSteal, 0.03), .stat(.maxHealth, -10)]),
        item("large_magnet", "大型吸附器", "拾取范围 +90，回收 +5", "◎", .refined, 29, tags: ["拾取", "经济"], effects: [.stat(.pickupRange, 90), .stat(.harvesting, 5)]),
        item("compound_interest", "复利协议", "每 30 星屑提供波末利息，上限 6", "◆", .refined, 36, limit: 3, tags: ["经济"], effects: [.special(.interestCap, 6)]),
        item("shop_radar", "商店雷达", "进入商店首个重掷 -50%", "⌁", .refined, 34, limit: 2, tags: ["商店"], effects: [.special(.freeFirstReroll, 0.5)]),
        item("drone_interface", "无人机接口", "工程 +8，召唤物移速 +15%", "⚙", .refined, 35, tags: ["工程"], effects: [.stat(.engineering, 8), .special(.summonAttackSpeed, 0.05)]),
        item("fixed_mount", "固定支架", "部署物攻速 +18%，角色移速 -4%", "⌬", .refined, 31, tags: ["工程", "风险"], effects: [.special(.summonAttackSpeed, 0.18), .stat(.movement, -0.04)]),
        item("fungal_catalyst", "菌群催化剂", "侵蚀 +10，霉化 +8", "☣", .refined, 30, tags: ["生化", "风险"], effects: [.stat(.erosion, 10), .stat(.corruption, 8)]),
        item("cooling_ring", "液氮冷却环", "攻速 +14%，弹速 -10%", "❄", .refined, 30, tags: ["攻速"], effects: [.stat(.attackSpeed, 0.14), .stat(.projectileSpeed, -0.10)]),
        item("emergency_thruster", "应急推进器", "受伤后短暂移速 +35%", "➤", .refined, 28, limit: 2, tags: ["速度", "防御"], effects: [.special(.hurtSpeed, 0.35)]),
        item("grudge_chip", "记仇芯片", "每损失 10% 生命，全伤害 +2%", "!", .refined, 33, limit: 2, tags: ["生命", "风险"], effects: [.special(.missingHealthDamage, 0.02)]),
        item("danger_overclock", "危险超频器", "伤害 +15%，攻速 +15%，最大生命 -12", "⚠", .refined, 37, limit: 3, tags: ["风险", "伤害"], effects: [.stat(.damage, 0.15), .stat(.attackSpeed, 0.15), .stat(.maxHealth, -12)]),
        item("carbon_filter", "活性炭滤芯", "霉化 -12，治疗效率 +8%", "♧", .refined, 27, tags: ["净化", "治疗"], effects: [.stat(.corruption, -12), .stat(.healingEfficiency, 0.08)])
    ]

    static let rare: [ItemDefinition] = [
        item("rail_belt", "磁轨腰带", "高弹速会转化为额外伤害", "»", .rare, 54, limit: 1, tags: ["弹速", "伤害"], effects: [.special(.projectileSpeedDamage, 0.20)]),
        item("close_scope", "近地瞄准器", "低射程会转化为额外伤害", "⌖", .rare, 52, limit: 1, tags: ["射程", "风险"], effects: [.special(.closeRangeDamage, 0.60)]),
        item("diffusion_array", "扩散阵列", "范围 +35%，单体伤害 -10%", "●", .rare, 50, tags: ["爆破", "风险"], effects: [.stat(.areaSize, 0.35), .stat(.damage, -0.10)]),
        item("split_core", "分裂核心", "击杀有 12% 概率发射 3 枚碎片弹", "✣", .rare, 58, limit: 3, tags: ["弹道"], effects: [.special(.splitOnKill, 0.12)]),
        item("aftershock", "余震模块", "爆炸后追加 40% 余震", "◉", .rare, 61, limit: 2, tags: ["爆破"], effects: [.special(.explosionAftershock, 0.40)]),
        item("chain_reactor", "连锁反应器", "感电和弹射次数 +1，首击 -8%", "ϟ", .rare, 59, limit: 2, tags: ["共振"], effects: [.special(.chainBonus, 1), .stat(.damage, -0.08)]),
        item("heat_death", "热寂定律", "灼烧层数提高灼烧伤害", "♨", .rare, 57, limit: 1, tags: ["灼热"], effects: [.special(.burnAmplification, 0.03)]),
        item("corrosion_dish", "腐蚀培养皿", "腐蚀目标死亡时传播层数", "☣", .rare, 55, limit: 1, tags: ["生化"], effects: [.special(.corrosionSpread, 0.5)]),
        item("surgical_blade", "外科锯片", "暴击 +12%，暴击击杀回复 1", "✧", .rare, 53, tags: ["暴击", "治疗"], effects: [.stat(.critChance, 0.12), .special(.critHeal, 1)]),
        item("redline", "红线协议", "低于 30% 生命时伤害 +45%", "!", .rare, 60, limit: 1, tags: ["生命", "风险"], effects: [.stat(.damage, -0.05), .special(.criticalHealthDamage, 0.50)]),
        item("self_repair_armor", "自修复装甲", "5 秒未受伤后持续恢复生命", "⬡", .rare, 62, limit: 1, tags: ["防御", "治疗"], effects: [.special(.outOfCombatHeal, 0.03)]),
        item("kinetic_plate", "动能转换板", "击退可转化为护甲，上限 8", "↟", .rare, 51, limit: 1, tags: ["控制", "防御"], effects: [.special(.armorFromKnockback, 8)]),
        item("mirror_shell", "镜面外壳", "闪避时向攻击者反射弹体", "◇", .rare, 56, limit: 2, tags: ["闪避", "弹道"], effects: [.special(.dodgeCounter, 1)]),
        item("overheal_tank", "过量医疗仓", "50% 过量治疗转为护盾", "▰", .rare, 63, limit: 1, tags: ["治疗", "防御"], effects: [.special(.overhealShield, 0.50)]),
        item("backup_heart", "备用心脏", "每局抵挡一次致命伤", "♥", .rare, 65, limit: 1, tags: ["生命"], effects: [.special(.extraLife, 1)]),
        item("black_market", "黑市终端", "商品 -12%，购买会增加霉化", "%", .rare, 58, limit: 1, tags: ["商店", "风险"], effects: [.stat(.shopDiscount, 0.12), .special(.purchaseCorruption, 1)]),
        item("recycle_compressor", "回收压缩机", "出售返还 +25%", "↺", .rare, 52, limit: 1, tags: ["商店", "经济"], effects: [.stat(.recycleRefund, 0.25)]),
        item("auto_lock", "自动锁定器", "每波可免费锁定 1 件商品", "▣", .rare, 54, limit: 1, tags: ["商店", "武器"], effects: [.special(.lockedWeaponWeight, 0.15)]),
        item("lucky_prism", "幸运棱镜", "20% 幸运转化为暴击率", "♢", .rare, 57, limit: 1, tags: ["幸运", "暴击"], effects: [.special(.luckToCrit, 0.20)]),
        item("scavenger_map", "拾荒者地图", "拾取范围转化为回收和幸运", "◎", .rare, 49, limit: 1, tags: ["拾取", "经济"], effects: [.special(.pickupEconomy, 1)]),
        item("duplicate_port", "复制端口", "每波复制首个部署物", "⚙", .rare, 64, limit: 1, tags: ["工程"], effects: [.special(.duplicateDeployable, 0.50)]),
        item("repair_swarm", "自主维修群", "召唤物消失时治疗并爆炸", "⬢", .rare, 55, limit: 2, tags: ["工程", "生化"], effects: [.special(.summonDeathBurst, 1)]),
        item("symbiote", "霉潮共生体", "霉化 +25，每 10 霉化提供侵蚀", "☣", .rare, 48, limit: 1, tags: ["生化", "风险"], effects: [.stat(.corruption, 25), .special(.corruptionToErosion, 2)]),
        item("purification_reactor", "净化反应堆", "每波净化 3 点霉化并积累生命", "♧", .rare, 60, limit: 1, tags: ["净化", "生命"], effects: [.special(.cleanseGrowth, 3)])
    ]

    static let legendary: [ItemDefinition] = [
        item("neural_bridge", "六联神经桥", "占用槽提高攻速，空槽提高伤害", "⌬", .legendary, 92, limit: 1, tags: ["武器", "构筑"], effects: [.special(.occupiedSlotAttackSpeed, 0.08), .special(.emptySlotDamage, 0.15)]),
        item("prototype_anvil", "原型铁砧", "进入商店时提升一把非 IV 武器", "⚒", .legendary, 105, limit: 1, tags: ["武器", "商店"], effects: [.special(.anvil, 1), .stat(.shopDiscount, -0.10)]),
        item("mirror_arsenal", "镜像兵工厂", "两侧武器有概率同步攻击", "◇", .legendary, 110, limit: 1, tags: ["武器"], effects: [.special(.mirrorWeapon, 0.35)]),
        item("infinite_chain", "无限弹链", "弹体击杀后重置穿透并增伤", "∞", .legendary, 96, limit: 1, tags: ["弹道"], effects: [.special(.resetPierceOnKill, 0.20)]),
        item("singularity_round", "奇点弹头", "爆炸会牵引敌人", "◉", .legendary, 98, limit: 1, tags: ["爆破", "控制"], effects: [.special(.singularityExplosion, 1)]),
        item("eye_of_storm", "风暴眼", "感电跳跃可能不消耗次数", "ϟ", .legendary, 94, limit: 1, tags: ["共振"], effects: [.special(.freeShockJump, 0.20)]),
        item("white_star", "白炽恒星", "10 层灼烧触发爆燃", "☀", .legendary, 101, limit: 1, tags: ["灼热"], effects: [.special(.burnDetonation, 1.80)]),
        item("living_weapon", "活体兵器", "生化武器获得额外品质效果", "☣", .legendary, 88, limit: 1, tags: ["生化", "风险"], effects: [.special(.biotechTierBoost, 1)]),
        item("time_rift", "时间裂隙", "攻速 +35%，敌速 +12%，波长 +5 秒", "⌛", .legendary, 90, limit: 1, tags: ["攻速", "风险"], effects: [.stat(.attackSpeed, 0.35), .special(.enemySpeed, 0.12), .special(.waveDuration, 5)]),
        item("absolute_zero", "绝对零度", "冻滞满层时冻结普通敌人", "❄", .legendary, 93, limit: 1, tags: ["控制"], effects: [.special(.freezeAtMax, 1)]),
        item("crimson_engine", "猩红永动机", "偷取触发后本波攻速成长", "♦", .legendary, 99, limit: 1, tags: ["生化", "攻速"], effects: [.special(.lifestealRamp, 0.01)]),
        item("living_armor", "不灭菌甲", "护甲 +8，正护甲会降低移速", "⬡", .legendary, 91, limit: 1, tags: ["防御", "风险"], effects: [.stat(.armor, 8), .special(.armorSpeedPenalty, 0.01)]),
        item("quantum_afterimage", "量子残影", "闪避后下一次攻击强化", "◌", .legendary, 95, limit: 1, tags: ["闪避", "暴击"], effects: [.special(.dodgeEmpower, 1)]),
        item("second_heart", "第二颗心", "致命伤后恢复半血并永久狂化", "♥", .legendary, 108, limit: 1, tags: ["生命", "风险"], effects: [.special(.secondHeart, 1)]),
        item("orbital_recycler", "轨道回收站", "波末立即回收一半未拾取星屑", "◎", .legendary, 87, limit: 1, tags: ["拾取", "经济"], effects: [.special(.orbitalRecovery, 0.50)]),
        item("monopoly", "垄断协议", "商店仅 2 件商品，但品质提高", "▣", .legendary, 100, limit: 1, tags: ["商店", "构筑"], effects: [.special(.monopoly, 1), .stat(.shopDiscount, 0.15)]),
        item("prophecy_die", "预言骰", "重掷会在当前商店提高幸运", "♢", .legendary, 89, limit: 1, tags: ["幸运", "商店"], effects: [.special(.rerollLuck, 5)]),
        item("core_printer", "星核印钞机", "每波回收 +20，受伤损失星屑", "◆", .legendary, 97, limit: 1, tags: ["经济", "风险"], effects: [.stat(.harvesting, 20), .special(.loseScrapOnHit, 0.03)]),
        item("mothership_blueprint", "母舰施工图", "工程 +25，部署物继承暴击和偷取", "⚙", .legendary, 103, limit: 1, tags: ["工程"], effects: [.stat(.engineering, 25), .special(.summonCritInheritance, 0.30)]),
        item("duplicate_personality", "复制人格", "里程碑等级复制最高属性升级", "Ⅱ", .legendary, 102, limit: 1, tags: ["成长"], effects: [.special(.duplicateUpgrade, 1)]),
        item("mold_crown", "霉潮王冠", "霉化变为 100，完全共鸣额外攻速 +25%", "♛", .legendary, 82, limit: 1, tags: ["霉化", "风险"], effects: [.special(.corruptionCrown, 1)]),
        item("zero_antibody", "零号抗体", "霉化归零并转化为伤害，之后免疫霉化", "♧", .legendary, 98, limit: 1, tags: ["净化"], effects: [.special(.zeroAntibody, 1)]),
        item("causal_insurance", "因果保险", "每波可在失败后重试一次", "↶", .legendary, 112, limit: 1, tags: ["容错"], effects: [.special(.retryWave, 1)]),
        item("dock_key", "第七码头密钥", "最终首领伤害降低，胜利星核提高", "⚿", .legendary, 106, limit: 1, tags: ["首领", "风险"], effects: [.special(.finalBossKey, 0.25)])
    ]

    static func definition(id: String) -> ItemDefinition? {
        all.first { $0.id == id }
    }
}

extension ItemDefinition {
    func apply(to stats: inout PlayerStats, runEffects: inout RunEffects) {
        for effect in effects {
            switch effect {
            case .stat(let key, let value):
                switch key {
                case .maxHealth:
                    stats.maxHealth += value
                    stats.health += max(0, value)
                case .regeneration: stats.regeneration += value
                case .lifeSteal: stats.lifeSteal += value
                case .armor: stats.armor += value
                case .dodge: stats.dodgeChance += value
                case .movement: stats.movementSpeed *= 1 + value
                case .damage: stats.globalDamage += value
                case .attackSpeed: stats.attackSpeed += value
                case .critChance: stats.critChance += value
                case .critDamage: stats.critMultiplier += value
                case .weaponPower: stats.weaponPower += value
                case .engineering: stats.engineering += value
                case .erosion: stats.erosion += value
                case .range: stats.rangeMultiplier += value
                case .projectileSpeed: stats.projectileSpeed *= 1 + value
                case .areaSize: stats.projectileSize += value
                case .knockback: stats.knockback += value
                case .pickupRange: stats.pickupRange += value
                case .luck: stats.luck += value
                case .harvesting: stats.harvesting += Int(value)
                case .shieldPerWave: stats.shieldPerWave += value
                case .shopDiscount: stats.shopDiscount += value
                case .rerollDiscount: stats.rerollDiscount += value
                case .recycleRefund: stats.recycleRefund += value
                case .healingEfficiency: stats.healingEfficiency += value
                case .corruption:
                    if !runEffects.has(.zeroAntibody) {
                        stats.corruption = max(0, stats.corruption + value)
                    }
                case .currencyMultiplier: stats.currencyMultiplier += value
                case .explosionDamage: stats.explosionDamage += value
                case .bossDamage: stats.bossDamage += value
                }
            case .special(let special, let value):
                if special == .corruptionCrown {
                    stats.corruption = 100
                    stats.attackSpeed += 0.25
                } else if special == .zeroAntibody {
                    let removed = stats.corruption
                    stats.corruption = 0
                    stats.globalDamage += floor(removed / 10) * 0.03
                }
                runEffects.add(special, value: value)
            case .heal(let amount):
                stats.heal(amount)
            }
        }
        stats.clamp()
    }
}

enum CatalogValidator {
    static func validate() {
        #if DEBUG
        assert(WeaponType.allCases.count == 24, "武器目录必须包含 24 件武器")
        assert(HeroType.allCases.count == 16, "角色目录必须包含 16 名角色")
        assert(ArenaType.allCases.count == 6, "地图目录必须包含 6 张地图")
        assert(ThreatLevel.allCases.count == 6, "威胁等级必须为 0...5")
        assert(RunContract.allCases.count == 12, "合同目录必须包含 12 份合同")
        assert(EnemyArchetype.allCases.count == 17, "敌人目录必须包含 16 种常规敌人与首领")
        assert(ItemCatalog.common.count == 24, "普通道具必须为 24 件")
        assert(ItemCatalog.refined.count == 24, "精良道具必须为 24 件")
        assert(ItemCatalog.rare.count == 24, "稀有道具必须为 24 件")
        assert(ItemCatalog.legendary.count == 24, "传奇道具必须为 24 件")
        assert(ItemCatalog.all.count == 96, "道具目录必须包含 96 件道具")
        assert(Set(ItemCatalog.all.map(\.id)).count == ItemCatalog.all.count, "道具 ID 必须唯一")
        assert(ItemCatalog.all.allSatisfy { $0.basePrice > 0 }, "道具价格必须为正数")
        assert(ItemCatalog.all.allSatisfy { ($0.limit ?? 1) > 0 }, "道具持有上限必须为正数")
        assert(WeaponType.allCases.allSatisfy { $0.tags.count == 2 }, "每件武器必须有两个标签")
        #endif
    }
}
