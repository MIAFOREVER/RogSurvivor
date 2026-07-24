import SpriteKit
import UIKit

final class GameScene: SKScene {
    private let backgroundLayer = SKNode()
    private let worldLayer = SKNode()
    private let interfaceLayer = SKNode()
    private let player = PlayerNode()
    private let joystick = VirtualJoystickNode()
    private let hud = HUDNode()
    private let saveStore = SaveStore()

    private var settings = GameSettings.load()
    private var phase: GamePhase = .title
    private var stats = PlayerStats()
    private var runEffects = RunEffects()
    private var inventory = RunInventory()

    private var selectedHero: HeroType = .pioneer
    private var selectedArena: ArenaType = .scrapOrbit
    private var selectedThreat: ThreatLevel = .calm
    private var contract: RunContract = .collector
    private var contractChoices: [RunContract] = []
    private var contractRewardGranted = false

    private var weapons: [WeaponRuntime] = []
    private var shopOffers: [ShopOffer?] = []
    private var upgradeChoices: [UpgradeChoice] = []

    private var heroPage = 0
    private var arenaPage = 0
    private var compendiumPage = 0

    private var wave = 1
    private var scrap = 0
    private var runScore = 0
    private var recoveryCache = 0
    private var metrics = RunMetrics()
    private var level = 1
    private var experience = 0
    private var experienceToNextLevel = 10
    private var pendingLevelUps = 0
    private var rerollsThisShop = 0
    private var purchasesThisShop = 0
    private var waveBudgetRemaining: CGFloat = 0
    private var waveRemaining: TimeInterval = 0
    private var spawnCountdown: TimeInterval = 0
    private var damageCooldown: TimeInterval = 0
    private var hazardDamageCooldown: TimeInterval = 0
    private var regenerationAccumulator: TimeInterval = 0
    private var outOfCombatHealAccumulator: TimeInterval = 0
    private var repairAccumulator: TimeInterval = 0
    private var lastDamageTime: TimeInterval = 100
    private var lastUpdateTime: TimeInterval = 0
    private var activeTouch: UITouch?
    private var overlay: SKNode?
    private var runEnded = false
    private var tookDamageThisWave = false
    private var isConfigured = false
    private var waveFinishing = false
    private var anvilAppliedWave = 0
    private var extraLivesUsed = 0
    private var secondHeartUsed = false
    private var dodgeEmpowered = false
    private var lifeStealRamp: CGFloat = 0
    private var hurtSpeedRemaining: TimeInterval = 0
    private var appliedPrimalHealth: CGFloat = 0
    private var appliedCorruptionErosion: CGFloat = 0
    private var waveStartHealth: CGFloat = 0
    private var waveStartKills = 0
    private var waveStartStats = PlayerStats()
    private var waveStartMetrics = RunMetrics()
    private var waveStartScrap = 0
    private var waveStartRunScore = 0
    private var waveStartExperience = 0
    private var waveStartLevel = 1
    private var waveStartPendingLevelUps = 0
    private var insuranceRetryWave: Int?
    private var shopLuckBonus: CGFloat = 0
    private var weaponShotCounters: [WeaponType: Int] = [:]
    private var rivetPickupStacks = 0
    private var cuttingHaloKillBonus: CGFloat = 0
    private var miningPickupProgress = 0
    private var summonOverclockRemaining: TimeInterval = 0
    private var stationaryDuration: TimeInterval = 0
    private var archivistMilestones: Set<Int> = []
    private var appliedCorruptionHealthPenalty: CGFloat = 0
    private var appliedMatriarchHealth: CGFloat = 0
    private var forcedCorruptionElitePending = false
    private var seventhDockModifier: ArenaType = .scrapOrbit

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .gameBackground
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard !isConfigured else { return }
        isConfigured = true

        view.isMultipleTouchEnabled = false
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = true
        SoundManager.shared.prepare()
        CatalogValidator.validate()

        backgroundLayer.zPosition = -100
        addChild(backgroundLayer)

        worldLayer.zPosition = 0
        addChild(worldLayer)
        worldLayer.addChild(player)

        interfaceLayer.zPosition = 100
        addChild(interfaceLayer)
        interfaceLayer.addChild(hud)
        interfaceLayer.addChild(joystick)

        drawBackground()
        layoutInterface()
        presentTitle()
        configureDebugRouteIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard isConfigured else { return }
        drawBackground()
        layoutInterface()
    }

    private func configureDebugRouteIfNeeded() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let marker = arguments.firstIndex(of: "-DebugRoute"),
              arguments.indices.contains(marker + 1) else { return }
        let route = arguments[marker + 1]

        run(.sequence([
            .wait(forDuration: 0.2),
            .run { [weak self] in
                guard let self else { return }
                switch route {
                case "heroes":
                    self.presentHeroSelection()
                case "arenas":
                    self.presentArenaSelection()
                case "hangar":
                    self.presentHangar()
                case "archives":
                    self.presentArchives()
                case "compendium":
                    self.presentCompendium()
                case "settings":
                    self.presentSettings()
                case "combat":
                    self.selectedHero = .pioneer
                    self.selectedArena = .scrapOrbit
                    self.selectedThreat = .calm
                    self.contract = .collector
                    self.startNewRun()
                case "crystal":
                    self.selectedHero = .stormcaller
                    self.selectedArena = .crystalHollows
                    self.selectedThreat = .calm
                    self.contract = .collector
                    self.startNewRun()
                case "fungal":
                    self.selectedHero = .purifier
                    self.selectedArena = .fungalDepths
                    self.selectedThreat = .calm
                    self.contract = .purification
                    self.startNewRun()
                case "dock":
                    self.selectedHero = .pioneer
                    self.selectedArena = .seventhDock
                    self.selectedThreat = .calm
                    self.contract = .collector
                    self.startNewRun()
                case "threats":
                    self.selectedHero = .pioneer
                    self.selectedArena = .scrapOrbit
                    self.presentThreatSelection()
                case "contracts":
                    self.selectedHero = .pioneer
                    self.selectedArena = .scrapOrbit
                    self.selectedThreat = .calm
                    self.presentContractSelection()
                case "levelup":
                    self.selectedHero = .pioneer
                    self.selectedArena = .scrapOrbit
                    self.selectedThreat = .calm
                    self.contract = .collector
                    self.startNewRun()
                    self.pendingLevelUps = 1
                    self.clearCombatants()
                    self.presentLevelUp()
                case "shop":
                    self.selectedHero = .engineer
                    self.selectedArena = .crystalHollows
                    self.selectedThreat = .calm
                    self.contract = .collector
                    self.startNewRun()
                    self.wave = 8
                    self.scrap = 280
                    self.finishWave()
                case "boss":
                    self.selectedHero = .stormcaller
                    self.selectedArena = .emberFoundry
                    self.selectedThreat = .severe
                    self.contract = .titanHunter
                    self.startNewRun()
                    self.clearCombatants()
                    self.wave = 20
                    self.startWave()
                case "stress":
                    self.selectedHero = .engineer
                    self.selectedArena = .seventhDock
                    self.selectedThreat = .critical
                    self.contract = .sixWeapons
                    self.startNewRun()
                    self.wave = 16
                    self.stats.globalDamage += 2.2
                    self.stats.attackSpeed += 0.8
                    self.weapons = Array(WeaponType.allCases.prefix(6)).map {
                        WeaponRuntime(type: $0, level: 3)
                    }
                    self.refreshWeaponSynergies()
                    self.clearCombatants()
                    self.startWave()
                default:
                    break
                }
            }
        ]))
        #endif
    }

    // MARK: - Layout and background

    private func layoutInterface() {
        hud.layout(for: size, topInset: view?.safeAreaInsets.top ?? 0)
    }

    private func drawBackground() {
        backgroundLayer.removeAllChildren()

        let background = SKSpriteNode(color: .gameBackground, size: size)
        background.anchorPoint = .zero
        background.position = .zero
        backgroundLayer.addChild(background)

        let accent = selectedArena.color
        let glow = SKShapeNode(circleOfRadius: max(size.width, size.height) * 0.42)
        glow.fillColor = accent.withAlphaComponent(0.055)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: size.width * 0.74, y: size.height * 0.62)
        backgroundLayer.addChild(glow)

        let spacing: CGFloat = 48
        var x: CGFloat = 0
        while x <= size.width {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            line.path = path
            line.strokeColor = accent.withAlphaComponent(0.045)
            line.lineWidth = 1
            backgroundLayer.addChild(line)
            x += spacing
        }

        var y: CGFloat = 0
        while y <= size.height {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            line.path = path
            line.strokeColor = accent.withAlphaComponent(0.04)
            line.lineWidth = 1
            backgroundLayer.addChild(line)
            y += spacing
        }
    }

    // MARK: - Base menus

    private func presentTitle() {
        phase = .title
        clearOverlay()
        clearWorldEntities()
        drawBackground()
        hud.isHidden = true
        player.isHidden = false
        player.position = CGPoint(x: size.width / 2, y: size.height * 0.70)
        player.removeAllActions()
        player.setScale(1.35)
        player.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 8, duration: 1.0),
            .moveBy(x: 0, y: -8, duration: 1.0)
        ])))

        let menu = makeOverlayPanel(opacity: 0.16)
        overlay = menu

        let eyebrow = makeLabel(
            "ORBITAL SURVIVAL PROTOCOL",
            size: 10,
            color: .gameCyan,
            font: "AvenirNext-DemiBold"
        )
        eyebrow.position = CGPoint(x: size.width / 2, y: size.height * 0.91)
        menu.addChild(eyebrow)

        let title = makeLabel("薯星幸存者", size: 39, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.845)
        menu.addChild(title)

        let subtitle = makeLabel(
            "六械同调 · 霉潮构筑 · 二十波突围",
            size: 12,
            color: .white.withAlphaComponent(0.52),
            font: "AvenirNext-Medium"
        )
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.80)
        menu.addChild(subtitle)

        let progress = makeLabel(
            "最高第 \(saveStore.data.highWave) 波   ◈ \(saveStore.data.totalCores)   胜利 \(saveStore.data.victories)",
            size: 11,
            color: .gameYellow,
            font: "AvenirNext-DemiBold"
        )
        progress.position = CGPoint(x: size.width / 2, y: size.height * 0.54)
        menu.addChild(progress)

        let start = MenuButtonNode(
            title: "开始突围",
            name: "startButton",
            width: min(290, size.width - 70),
            color: .gameYellow
        )
        start.position = CGPoint(x: size.width / 2, y: size.height * 0.445)
        menu.addChild(start)

        let buttonWidth = min(142, (size.width - 58) / 2)
        let hangar = MenuButtonNode(
            title: "基地强化",
            name: "hangarButton",
            width: buttonWidth,
            color: .gameCyan
        )
        hangar.position = CGPoint(x: size.width / 2 - buttonWidth * 0.54, y: size.height * 0.34)
        hangar.setScale(0.86)
        menu.addChild(hangar)

        let archives = MenuButtonNode(
            title: "世界档案",
            name: "archivesButton",
            width: buttonWidth,
            color: .gamePurple
        )
        archives.position = CGPoint(x: size.width / 2 + buttonWidth * 0.54, y: size.height * 0.34)
        archives.setScale(0.86)
        menu.addChild(archives)

        let compendium = MenuButtonNode(
            title: "构筑图鉴",
            name: "compendiumButton",
            width: buttonWidth,
            color: .gameGreen
        )
        compendium.position = CGPoint(x: size.width / 2 - buttonWidth * 0.54, y: size.height * 0.25)
        compendium.setScale(0.86)
        menu.addChild(compendium)

        let settingsButton = MenuButtonNode(
            title: "辅助设置",
            name: "settingsButton",
            width: buttonWidth,
            color: .gameCream
        )
        settingsButton.position = CGPoint(x: size.width / 2 + buttonWidth * 0.54, y: size.height * 0.25)
        settingsButton.setScale(0.86)
        menu.addChild(settingsButton)

        let footer = makeLabel(
            "16 名角色 · 24 把武器 · 96 件道具 · 6 个战区",
            size: 9,
            color: .white.withAlphaComponent(0.30),
            font: "AvenirNext-DemiBold"
        )
        footer.position = CGPoint(x: size.width / 2, y: 28)
        menu.addChild(footer)
    }

    private func presentHeroSelection() {
        phase = .heroSelect
        clearOverlay()
        player.removeAllActions()
        player.setScale(1)
        player.isHidden = true

        let panel = makeOverlayPanel()
        overlay = panel

        let title = makeLabel("选择战士", size: 30, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.90)
        panel.addChild(title)

        let subtitle = makeLabel(
            "每名战士会改变整套购买逻辑",
            size: 11,
            color: .white.withAlphaComponent(0.52),
            font: "AvenirNext-Medium"
        )
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.855)
        panel.addChild(subtitle)

        let heroesPerPage = 8
        let pageCount = Int(ceil(Double(HeroType.allCases.count) / Double(heroesPerPage)))
        heroPage = min(max(0, heroPage), pageCount - 1)
        let start = heroPage * heroesPerPage
        let visible = Array(
            HeroType.allCases[start..<min(start + heroesPerPage, HeroType.allCases.count)]
        )

        let cardWidth = (size.width - 38) / 2
        let cardSize = CGSize(width: cardWidth, height: 98)
        let startY = size.height * 0.745
        let rowSpacing: CGFloat = 109

        for (index, hero) in visible.enumerated() {
            let row = index / 2
            let column = index % 2
            let unlocked = hero.isUnlocked(in: saveStore.data)
            let card = SelectionCardNode(
                title: hero.title,
                subtitle: hero.subtitle,
                symbol: hero.symbol,
                color: hero.color,
                name: "character_\(hero.rawValue)",
                size: cardSize,
                isLocked: !unlocked,
                footer: hero.unlockText(in: saveStore.data)
            )
            card.position = CGPoint(
                x: 12 + cardWidth / 2 + CGFloat(column) * (cardWidth + 14),
                y: startY - CGFloat(row) * rowSpacing
            )
            panel.addChild(card)
        }

        addPager(
            to: panel,
            page: heroPage,
            pageCount: pageCount,
            y: size.height * 0.16,
            previousName: "heroPreviousButton",
            nextName: "heroNextButton"
        )

        let back = makeTextButton("返回基地", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 54)
        panel.addChild(back)
    }

    private func presentArenaSelection() {
        phase = .arenaSelect
        clearOverlay()
        player.isHidden = true

        let panel = makeOverlayPanel()
        overlay = panel

        let heroTag = makeLabel(
            "\(selectedHero.symbol) \(selectedHero.title)",
            size: 12,
            color: selectedHero.color,
            font: "AvenirNext-DemiBold"
        )
        heroTag.position = CGPoint(x: size.width / 2, y: size.height * 0.92)
        panel.addChild(heroTag)

        let title = makeLabel("选择战区", size: 30, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.86)
        panel.addChild(title)

        let arenasPerPage = 3
        let pageCount = 2
        arenaPage = min(max(0, arenaPage), pageCount - 1)
        let start = arenaPage * arenasPerPage
        let visible = Array(
            ArenaType.allCases[start..<min(start + arenasPerPage, ArenaType.allCases.count)]
        )
        let cardWidth = min(344, size.width - 38)
        let cardSize = CGSize(width: cardWidth, height: 125)
        let startY = size.height * 0.68

        for (index, arena) in visible.enumerated() {
            let unlocked = arena.isUnlocked(in: saveStore.data)
            let card = SelectionCardNode(
                title: arena.title,
                subtitle: arena.subtitle,
                symbol: arena.symbol,
                color: arena.color,
                name: "arena_\(arena.rawValue)",
                size: cardSize,
                isLocked: !unlocked,
                footer: arena.unlockText(in: saveStore.data)
            )
            card.position = CGPoint(
                x: size.width / 2,
                y: startY - CGFloat(index) * 143
            )
            panel.addChild(card)
        }

        addPager(
            to: panel,
            page: arenaPage,
            pageCount: pageCount,
            y: size.height * 0.16,
            previousName: "arenaPreviousButton",
            nextName: "arenaNextButton"
        )

        let back = makeTextButton("重新选择战士", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 54)
        panel.addChild(back)
    }

    private func presentThreatSelection() {
        phase = .threatSelect
        clearOverlay()

        let panel = makeOverlayPanel()
        overlay = panel

        let context = makeLabel(
            "\(selectedHero.title) · \(selectedArena.title)",
            size: 11,
            color: selectedArena.color,
            font: "AvenirNext-DemiBold"
        )
        context.position = CGPoint(x: size.width / 2, y: size.height * 0.92)
        panel.addChild(context)

        let title = makeLabel("选择威胁等级", size: 29, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.86)
        panel.addChild(title)

        let cardWidth = min(344, size.width - 38)
        let cardSize = CGSize(width: cardWidth, height: 78)
        let startY = size.height * 0.735

        for (index, threat) in ThreatLevel.allCases.enumerated() {
            let unlocked = saveStore.data.isThreatUnlocked(threat, for: selectedArena)
            let footer = unlocked
                ? "星核 ×\(String(format: "%.2f", threat.coreMultiplier))"
                : "先通关威胁 \(threat.rawValue - 1)"
            let card = SelectionCardNode(
                title: threat.title,
                subtitle: threat.subtitle,
                symbol: "\(threat.rawValue)",
                color: threat.color,
                name: "threat_\(threat.rawValue)",
                size: cardSize,
                isLocked: !unlocked,
                footer: footer
            )
            card.position = CGPoint(
                x: size.width / 2,
                y: startY - CGFloat(index) * 84
            )
            panel.addChild(card)
        }

        let back = makeTextButton("重新选择战区", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 48)
        panel.addChild(back)
    }

    private func presentContractSelection() {
        phase = .contractSelect
        clearOverlay()

        if contractChoices.count != 3 {
            contractChoices = Array(RunContract.allCases.shuffled().prefix(3))
        }

        let panel = makeOverlayPanel()
        overlay = panel

        let context = makeLabel(
            "\(selectedArena.title) · \(selectedThreat.title)",
            size: 11,
            color: selectedThreat.color,
            font: "AvenirNext-DemiBold"
        )
        context.position = CGPoint(x: size.width / 2, y: size.height * 0.92)
        panel.addChild(context)

        let title = makeLabel("选择突围合同", size: 29, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        panel.addChild(title)

        let hint = makeLabel(
            "合同没有失败惩罚，完成后立即获得局内强化",
            size: 10,
            color: .white.withAlphaComponent(0.48),
            font: "AvenirNext-Medium"
        )
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.805)
        panel.addChild(hint)

        let cardWidth = min(344, size.width - 38)
        for (index, choice) in contractChoices.enumerated() {
            let card = SelectionCardNode(
                title: choice.title,
                subtitle: choice.detail,
                symbol: contractSymbol(choice),
                color: .gameYellow,
                name: "contract_\(choice.rawValue)",
                size: CGSize(width: cardWidth, height: 128),
                footer: "+\(choice.reward) 星核"
            )
            card.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.65 - CGFloat(index) * 148
            )
            panel.addChild(card)
        }

        let back = makeTextButton("重新选择威胁", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 56)
        panel.addChild(back)
    }

    private func presentHangar() {
        phase = .hangar
        clearOverlay()
        player.removeAllActions()
        player.isHidden = true

        let panel = makeOverlayPanel()
        overlay = panel

        let eyebrow = makeLabel(
            "第七码头 · 星核培育舱",
            size: 12,
            color: .gameCyan,
            font: "AvenirNext-DemiBold"
        )
        eyebrow.position = CGPoint(x: size.width / 2, y: size.height * 0.91)
        panel.addChild(eyebrow)

        let title = makeLabel("基地强化", size: 31, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        panel.addChild(title)

        let cores = makeLabel(
            "◈ 可用星核 \(saveStore.data.totalCores)",
            size: 16,
            color: .gameYellow,
            font: "AvenirNext-Bold"
        )
        cores.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        panel.addChild(cores)

        let cardWidth = min(342, size.width - 42)
        for (index, track) in PermanentTrack.allCases.enumerated() {
            let rank = track.rank(in: saveStore.data)
            let cost = saveStore.data.upgradeCost(for: track)
            let card = SelectionCardNode(
                title: track.title,
                subtitle: track.detail,
                symbol: track.symbol,
                color: track.color,
                name: "permanent_\(track.rawValue)",
                size: CGSize(width: cardWidth, height: 116),
                footer: rank >= 10 ? "已满级" : "Lv.\(rank) · ◈ \(cost)"
            )
            card.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.63 - CGFloat(index) * 138
            )
            panel.addChild(card)
        }

        let hint = makeParagraph(
            "永久成长只提供少量容错。角色、武器、道具和构筑理解才是高威胁通关关键。",
            size: 11,
            color: .white.withAlphaComponent(0.48),
            width: min(310, size.width - 60)
        )
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        panel.addChild(hint)

        let back = makeTextButton("返回基地", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 54)
        panel.addChild(back)
    }

    private func buyPermanent(_ track: PermanentTrack) {
        let rank = track.rank(in: saveStore.data)
        guard rank < 10 else {
            showToast("该强化已满级", color: .gameCyan)
            return
        }
        let cost = saveStore.data.upgradeCost(for: track)
        guard saveStore.data.totalCores >= cost else {
            showToast("星核不足", color: .gameCoral)
            return
        }

        saveStore.mutate { save in
            save.totalCores -= cost
            switch track {
            case .power: save.permanentPower += 1
            case .vitality: save.permanentVitality += 1
            case .scavenging: save.permanentScavenging += 1
            }
        }
        impact(.medium)
        presentHangar()
    }

    private func presentArchives() {
        phase = .archives
        clearOverlay()
        player.removeAllActions()
        player.isHidden = true

        let panel = makeOverlayPanel()
        overlay = panel

        let title = makeLabel("薯星档案", size: 30, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.91)
        panel.addChild(title)

        let subtitle = makeLabel(
            "在一次次突围中拼出这颗星球的真相",
            size: 11,
            color: .white.withAlphaComponent(0.5),
            font: "AvenirNext-Medium"
        )
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.865)
        panel.addChild(subtitle)

        let cardWidth = min(342, size.width - 42)
        for (index, entry) in LoreEntry.all.enumerated() {
            let unlocked = index == 0
                || saveStore.data.highWave >= index * 4
                || saveStore.data.totalCores >= index * 30
            let card = SKShapeNode(
                rectOf: CGSize(width: cardWidth, height: 91),
                cornerRadius: 15
            )
            card.fillColor = .gamePanel
            card.strokeColor = unlocked ? entry.color : .gameBorder
            card.alpha = unlocked ? 1 : 0.55
            card.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.755 - CGFloat(index) * 99
            )
            panel.addChild(card)

            let entryTitle = makeLabel(
                unlocked ? "\(entry.subtitle) · \(entry.title)" : "档案加密 · ？？？",
                size: 13,
                color: unlocked ? entry.color : .gameCoral
            )
            entryTitle.horizontalAlignmentMode = .left
            entryTitle.position = CGPoint(x: -cardWidth / 2 + 15, y: 23)
            card.addChild(entryTitle)

            let body = makeParagraph(
                unlocked ? entry.body : "继续深入战区，解密这段记录。",
                size: 9.5,
                color: .white.withAlphaComponent(0.55),
                width: cardWidth - 30
            )
            body.horizontalAlignmentMode = .left
            body.position = CGPoint(x: -cardWidth / 2 + 15, y: -16)
            card.addChild(body)
        }

        let back = makeTextButton("返回基地", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 45)
        panel.addChild(back)
    }

    private func presentCompendium() {
        phase = .compendium
        clearOverlay()
        player.removeAllActions()
        player.isHidden = true

        let panel = makeOverlayPanel()
        overlay = panel

        let title = makeLabel("构筑图鉴", size: 30, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.91)
        panel.addChild(title)

        let subtitle = makeLabel(
            "24 武器 · 96 道具 · 长按商店卡片可查看联动",
            size: 10,
            color: .gameGreen,
            font: "AvenirNext-DemiBold"
        )
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.865)
        panel.addChild(subtitle)

        let perPage = 6
        let pageCount = Int(ceil(Double(ItemCatalog.all.count) / Double(perPage)))
        compendiumPage = min(max(0, compendiumPage), pageCount - 1)
        let start = compendiumPage * perPage
        let visible = Array(
            ItemCatalog.all[start..<min(start + perPage, ItemCatalog.all.count)]
        )
        let cardWidth = min(344, size.width - 38)
        for (index, item) in visible.enumerated() {
            let card = SelectionCardNode(
                title: item.title,
                subtitle: item.detail,
                symbol: item.symbol,
                color: item.color,
                name: "compendiumItem_\(item.id)",
                size: CGSize(width: cardWidth, height: 79),
                footer: "\(item.rarity.title) · ◆\(item.basePrice)"
            )
            card.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.755 - CGFloat(index) * 86
            )
            panel.addChild(card)
        }

        addPager(
            to: panel,
            page: compendiumPage,
            pageCount: pageCount,
            y: size.height * 0.13,
            previousName: "compendiumPreviousButton",
            nextName: "compendiumNextButton"
        )

        let back = makeTextButton("返回基地", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 40)
        panel.addChild(back)
    }

    private func presentSettings() {
        phase = .settings
        clearOverlay()
        player.removeAllActions()
        player.isHidden = true

        let panel = makeOverlayPanel()
        overlay = panel

        let title = makeLabel("辅助与表现", size: 30, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.90)
        panel.addChild(title)

        let options: [(String, String, String, String, SKColor)] = [
            ("触觉反馈", settings.haptics ? "开启" : "关闭", "setting_haptics", "⌁", .gameCyan),
            ("屏幕震动", settings.screenShake ? "开启" : "关闭", "setting_shake", "≈", .gameYellow),
            ("伤害数字", settings.damageNumbers ? "开启" : "关闭", "setting_numbers", "123", .gameCoral),
            ("降低视觉密度", settings.reducedEffects ? "开启" : "关闭", "setting_effects", "◌", .gamePurple),
            ("敌人生命", "\(Int(settings.enemyHealthScale * 100))%", "setting_health", "♥", .gameGreen),
            ("敌人伤害", "\(Int(settings.enemyDamageScale * 100))%", "setting_damage", "✦", .gameCoral),
            ("敌人速度", "\(Int(settings.enemySpeedScale * 100))%", "setting_speed", "➤", .gameCyan)
        ]

        let cardWidth = min(344, size.width - 38)
        for (index, option) in options.enumerated() {
            let card = SelectionCardNode(
                title: option.0,
                subtitle: "点击切换",
                symbol: option.3,
                color: option.4,
                name: option.2,
                size: CGSize(width: cardWidth, height: 72),
                footer: option.1
            )
            card.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.76 - CGFloat(index) * 78
            )
            panel.addChild(card)
        }

        let note = makeLabel(
            "辅助倍率不会阻止内容解锁，战绩会记录设置",
            size: 9,
            color: .white.withAlphaComponent(0.42),
            font: "AvenirNext-Medium"
        )
        note.position = CGPoint(x: size.width / 2, y: 72)
        panel.addChild(note)

        let back = makeTextButton("保存并返回", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 40)
        panel.addChild(back)
    }

    // MARK: - Run setup

    private func startNewRun() {
        phase = .playing
        clearOverlay()
        clearWorldEntities()
        drawBackground()
        seventhDockModifier = selectedArena == .seventhDock
            ? Array(ArenaType.allCases.dropLast()).randomElement() ?? .scrapOrbit
            : selectedArena

        stats.reset()
        runEffects.reset()
        inventory.reset()
        selectedHero.apply(to: &stats)
        var saveCopy = saveStore.data
        saveCopy.applyPermanentBonuses(to: &stats)

        if mechanicalArena == .fungalDepths {
            stats.corruption += 15
            stats.healingEfficiency -= 0.10
        } else if mechanicalArena == .driftingPrison {
            stats.knockback += 0.40
        }
        if selectedThreat == .extinction {
            stats.healingEfficiency -= 0.10
        }
        stats.clamp()

        weapons = [WeaponRuntime(type: selectedHero.startingWeapon, level: 1)]
        wave = 1
        scrap = selectedHero == .broker ? 42 : 12
        runScore = 0
        recoveryCache = 0
        metrics = RunMetrics()
        metrics.maxWeaponCount = 1
        metrics.maxCorruption = stats.corruption
        metrics.maxHeldScrap = scrap
        level = 1
        experience = 0
        experienceToNextLevel = experienceRequirement(for: 2)
        pendingLevelUps = 0
        contractRewardGranted = false
        lastUpdateTime = 0
        damageCooldown = 0
        hazardDamageCooldown = 0
        runEnded = false
        waveFinishing = false
        anvilAppliedWave = 0
        extraLivesUsed = 0
        secondHeartUsed = false
        dodgeEmpowered = false
        lifeStealRamp = 0
        appliedPrimalHealth = 0
        appliedCorruptionErosion = 0
        insuranceRetryWave = nil
        shopLuckBonus = 0
        weaponShotCounters.removeAll()
        rivetPickupStacks = 0
        cuttingHaloKillBonus = 0
        miningPickupProgress = 0
        summonOverclockRemaining = 0
        stationaryDuration = 0
        archivistMilestones.removeAll()
        appliedCorruptionHealthPenalty = 0
        appliedMatriarchHealth = 0
        forcedCorruptionElitePending = false

        player.removeAllActions()
        player.isHidden = false
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        player.zRotation = 0
        player.setScale(1)
        hud.isHidden = false

        refreshCorruptionDerivedHealth()
        refreshWeaponSynergies()
        setupArena()
        startWave()
        if selectedArena == .seventhDock {
            showToast(
                "码头异常：继承「\(seventhDockModifier.title)」规则",
                color: .gameYellow
            )
        }
    }

    private var mechanicalArena: ArenaType {
        selectedArena == .seventhDock ? seventhDockModifier : selectedArena
    }

    private func setupArena() {
        let hazardConfiguration: [(CGPoint, CGFloat, SKColor)]
        switch mechanicalArena {
        case .emberFoundry:
            hazardConfiguration = [
                (CGPoint(x: size.width * 0.23, y: size.height * 0.30), 42, .gameCoral),
                (CGPoint(x: size.width * 0.74, y: size.height * 0.48), 50, .gameCoral),
                (CGPoint(x: size.width * 0.35, y: size.height * 0.73), 42, .gameCoral)
            ]
        case .fungalDepths:
            hazardConfiguration = [
                (CGPoint(x: size.width * 0.28, y: size.height * 0.42), 46, .gameGreen),
                (CGPoint(x: size.width * 0.72, y: size.height * 0.67), 44, .gamePurple)
            ]
        case .crystalHollows:
            hazardConfiguration = [
                (CGPoint(x: size.width * 0.20, y: size.height * 0.65), 34, .gameCyan),
                (CGPoint(x: size.width * 0.80, y: size.height * 0.33), 34, .gameCyan)
            ]
        case .seventhDock:
            hazardConfiguration = []
        default:
            hazardConfiguration = []
        }

        for configuration in hazardConfiguration {
            let hazard = HazardNode(radius: configuration.1, color: configuration.2)
            hazard.position = configuration.0
            worldLayer.addChild(hazard)
        }
        setupArenaProps()
    }

    private func setupArenaProps() {
        let configurations: [(ArenaPropKind, CGPoint, CGFloat)]
        switch mechanicalArena {
        case .scrapOrbit:
            configurations = [
                (.cargo, CGPoint(x: size.width * 0.22, y: size.height * 0.34), 27),
                (.cargo, CGPoint(x: size.width * 0.73, y: size.height * 0.52), 30),
                (.cargo, CGPoint(x: size.width * 0.42, y: size.height * 0.73), 25)
            ]
        case .crystalHollows:
            configurations = [
                (.crystal, CGPoint(x: size.width * 0.25, y: size.height * 0.40), 24),
                (.crystal, CGPoint(x: size.width * 0.72, y: size.height * 0.64), 28),
                (.crystal, CGPoint(x: size.width * 0.48, y: size.height * 0.79), 21)
            ]
        default:
            configurations = []
        }

        for configuration in configurations {
            let prop = ArenaPropNode(kind: configuration.0, radius: configuration.2)
            prop.position = configuration.1
            worldLayer.addChild(prop)
        }
    }

    private func startWave() {
        phase = .playing
        clearOverlay()
        hud.isHidden = false
        waveFinishing = false
        waveRemaining = WaveCatalog.duration(for: wave) + runEffects[.waveDuration]
        waveBudgetRemaining = WaveCatalog.threatBudget(for: wave)
            * selectedThreat.spawnBudgetMultiplier
        spawnCountdown = 0.12
        lastUpdateTime = 0
        regenerationAccumulator = 0
        outOfCombatHealAccumulator = 0
        repairAccumulator = 0
        damageCooldown = 0
        tookDamageThisWave = false
        waveStartHealth = stats.health
        waveStartKills = metrics.kills
        lifeStealRamp = 0
        rivetPickupStacks = 0
        cuttingHaloKillBonus = 0
        summonOverclockRemaining = 0
        stats.beginWave()

        if runEffects.has(.biotechTierBoost),
           insuranceRetryWave != wave,
           !runEffects.has(.zeroAntibody) {
            stats.corruption = min(100, stats.corruption + 4)
            metrics.maxCorruption = max(metrics.maxCorruption, stats.corruption)
            refreshCorruptionConversion()
        }
        refreshCorruptionDerivedHealth()
        forcedCorruptionElitePending = effectiveCorruptionStage >= 4
        worldLayer.children
            .filter { $0.name == "corruptionHazard" }
            .forEach { $0.removeFromParent() }
        purificationFlowers.forEach { $0.removeFromParent() }
        if mechanicalArena == .fungalDepths, selectedHero != .matriarch {
            for index in 0..<2 {
                let flower = PurificationFlowerNode()
                flower.position = CGPoint(
                    x: size.width * (index == 0 ? 0.20 : 0.80),
                    y: size.height * (index == 0 ? 0.58 : 0.32)
                )
                worldLayer.addChild(flower)
            }
        }
        if effectiveCorruptionStage >= 3 {
            for index in 0..<2 {
                let hazard = HazardNode(radius: 30, color: .gameGreen)
                hazard.name = "corruptionHazard"
                hazard.position = CGPoint(
                    x: size.width * (index == 0 ? 0.28 : 0.72),
                    y: size.height * (index == 0 ? 0.42 : 0.64)
                )
                worldLayer.addChild(hazard)
            }
        }
        grantArchivistMilestoneIfNeeded()
        waveStartStats = stats
        waveStartMetrics = metrics
        waveStartScrap = scrap
        waveStartRunScore = runScore
        waveStartExperience = experience
        waveStartLevel = level
        waveStartPendingLevelUps = pendingLevelUps

        for index in weapons.indices {
            weapons[index].cooldown = Double.random(in: 0...0.25)
        }

        setupDeployables()
        if wave.isMultiple(of: 5) {
            spawnBoss()
        }

        updateHUD()
        showWaveBanner()
    }

    private func setupDeployables() {
        deployables.forEach { $0.removeFromParent() }
        var deployableIndex = 0
        var madeDuplicate = false
        for weapon in weapons where weapon.type.pattern == .deployable {
            let count = (weapon.level >= 2 ? 2 : 1)
                + (selectedHero == .engineer ? 1 : 0)
            for _ in 0..<count {
                let node = DeployableNode(weaponType: weapon.type, index: deployableIndex)
                if weapon.type == .sentryCapsule {
                    let angle = CGFloat(deployableIndex) * 2.3
                    node.position = CGPoint(
                        x: min(size.width - 30, max(30, player.position.x + cos(angle) * 74)),
                        y: min(size.height - 100, max(34, player.position.y + sin(angle) * 74))
                    )
                } else {
                    node.position = player.position
                }
                worldLayer.addChild(node)
                deployableIndex += 1

                if !madeDuplicate,
                   runEffects.has(.duplicateDeployable) || tagCount(.engineering) >= 6 {
                    let duplicateScale = runEffects.has(.duplicateDeployable)
                        ? runEffects[.duplicateDeployable]
                        : 0.5
                    let duplicate = DeployableNode(
                        weaponType: weapon.type,
                        index: deployableIndex,
                        powerScale: duplicateScale
                    )
                    duplicate.position = node.position + CGVector(dx: 28, dy: -18)
                    worldLayer.addChild(duplicate)
                    deployableIndex += 1
                    madeDuplicate = true
                }
            }
        }

        if selectedHero == .matriarch, stats.corruption >= 100 {
            let symbiote = DeployableNode(
                weaponType: .sporeInjector,
                index: deployableIndex,
                powerScale: 0.65
            )
            symbiote.position = player.position + CGVector(dx: 44, dy: 24)
            worldLayer.addChild(symbiote)
        }
    }

    private func showWaveBanner() {
        interfaceLayer.childNode(withName: "waveBanner")?.removeFromParent()
        let isBossWave = wave.isMultiple(of: 5)
        let banner = makeLabel(
            isBossWave ? "警告：\(bossName)" : "第 \(wave) 波",
            size: isBossWave ? 22 : 30,
            color: isBossWave ? .gameCoral : .gameCream
        )
        banner.position = CGPoint(x: size.width / 2, y: size.height * 0.63)
        banner.name = "waveBanner"
        banner.zPosition = 150
        interfaceLayer.addChild(banner)
        banner.run(.sequence([
            .group([
                .moveBy(x: 0, y: 24, duration: 0.75),
                .sequence([
                    .wait(forDuration: 0.35),
                    .fadeOut(withDuration: 0.4)
                ])
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Frame loop

    override func update(_ currentTime: TimeInterval) {
        guard phase == .playing else {
            lastUpdateTime = currentTime
            return
        }

        let deltaTime: TimeInterval
        if lastUpdateTime == 0 {
            deltaTime = 1.0 / 60.0
        } else {
            deltaTime = min(0.05, currentTime - lastUpdateTime)
        }
        lastUpdateTime = currentTime

        damageCooldown = max(0, damageCooldown - deltaTime)
        hazardDamageCooldown = max(0, hazardDamageCooldown - deltaTime)
        hurtSpeedRemaining = max(0, hurtSpeedRemaining - deltaTime)
        summonOverclockRemaining = max(0, summonOverclockRemaining - deltaTime)
        regenerationAccumulator += deltaTime
        outOfCombatHealAccumulator += deltaTime
        repairAccumulator += deltaTime
        lastDamageTime += deltaTime

        if stats.health / stats.maxHealth < 0.35 {
            metrics.lowHealthSeconds += deltaTime
        }

        if regenerationAccumulator >= 0.25, stats.regeneration > 0 {
            applyHealing(stats.regeneration * CGFloat(regenerationAccumulator))
            regenerationAccumulator = 0
        }

        if runEffects.has(.outOfCombatHeal),
           lastDamageTime >= 5,
           outOfCombatHealAccumulator >= 1 {
            applyHealing(stats.maxHealth * runEffects[.outOfCombatHeal])
            outOfCombatHealAccumulator = 0
        }

        updateWave(deltaTime)
        movePlayer(deltaTime)
        moveEnemies(deltaTime)
        moveProjectiles(deltaTime)
        moveHostileProjectiles(deltaTime)
        updateDeployables(deltaTime)
        updatePickups(deltaTime)
        updatePurificationFlowers()
        updateHazards()
        updateEnemyStatuses(deltaTime)
        handleProjectileHits()
        fireWeapons(deltaTime)
        updateHUD()

        if stats.health <= 0 {
            handlePotentialDeath()
        }
    }

    private func updateWave(_ deltaTime: TimeInterval) {
        guard !waveFinishing else { return }

        if waveRemaining > 0 {
            waveRemaining = max(0, waveRemaining - deltaTime)
            spawnCountdown -= deltaTime

            if spawnCountdown <= 0, waveBudgetRemaining > 0 {
                if enemies.count < 160 {
                    let spent = spawnEnemy()
                    waveBudgetRemaining = max(0, waveBudgetRemaining - spent)
                }
                let density = max(0.16, 0.72 - Double(wave) * 0.022)
                spawnCountdown += density * Double.random(in: 0.72...1.18)
            }
        } else {
            if wave == 20, enemies.contains(where: { $0.archetype.isBoss }) {
                return
            }
            finishWave()
        }
    }

    private func movePlayer(_ deltaTime: TimeInterval) {
        var movementVector = joystick.vector
        if movementVector.length < 0.08 {
            stationaryDuration += deltaTime
        } else {
            stationaryDuration = 0
        }
        if mechanicalArena == .driftingPrison {
            let drift = CGVector(
                dx: sin(CGFloat(lastUpdateTime) * 0.55) * 0.13,
                dy: cos(CGFloat(lastUpdateTime) * 0.41) * 0.08
            )
            movementVector = CGVector(
                dx: movementVector.dx + drift.dx,
                dy: movementVector.dy + drift.dy
            )
        }

        var movementSpeed = stats.movementSpeed
        if hurtSpeedRemaining > 0 {
            movementSpeed *= 1 + runEffects[.hurtSpeed]
        }
        if runEffects.has(.armorSpeedPenalty), stats.armor > 0 {
            movementSpeed *= max(0.75, 1 - stats.armor * runEffects[.armorSpeedPenalty])
        }
        if tagCount(.orbit) >= 2 {
            movementSpeed *= 1.06
        }

        let movement = movementVector * (movementSpeed * CGFloat(deltaTime))
        player.position = player.position + movement
        player.face(direction: joystick.vector)

        player.position.x = min(size.width - 28, max(28, player.position.x))
        player.position.y = min(size.height - 92, max(30, player.position.y))
        for prop in arenaProps where prop.kind == .cargo {
            let offset = player.position - prop.position
            let minimumDistance = prop.collisionRadius + 22
            if offset.length < minimumDistance {
                let direction = offset.length > 0.1
                    ? offset.normalized
                    : CGVector(dx: 1, dy: 0)
                player.position = prop.position + direction * minimumDistance
            }
        }
    }

    private func moveEnemies(_ deltaTime: TimeInterval) {
        for enemy in enemies where enemy.parent != nil {
            let offset = player.position - enemy.position
            let distance = offset.length
            let direction = offset.normalized
            enemy.behaviorCooldown -= deltaTime

            if enemy.archetype == .phaser, enemy.behaviorCooldown <= 0 {
                enemy.isPhased.toggle()
                enemy.alpha = enemy.isPhased ? 0.28 : 1
                enemy.behaviorCooldown = enemy.isPhased ? 0.8 : 2.2
            }

            if enemy.archetype == .breeder, enemy.behaviorCooldown <= 0 {
                _ = spawnEnemy(archetype: .crawler, near: enemy.position, countsBudget: false)
                _ = spawnEnemy(archetype: .crawler, near: enemy.position, countsBudget: false)
                enemy.behaviorCooldown = 4
            }

            if enemy.archetype == .absorber {
                for pickup in pickups {
                    let pull = enemy.position - pickup.position
                    if pull.length < 180 {
                        pickup.position = pickup.position
                            + pull.normalized * (55 * CGFloat(deltaTime))
                    }
                }
            }

            var speed = enemy.movementSpeed
                * enemy.speedMultiplier
                * (1 + runEffects[.enemySpeed])
            if enemy.archetype == .charger {
                if enemy.behaviorCooldown <= 0 {
                    enemy.behaviorCooldown = 2.8
                } else if enemy.behaviorCooldown < 0.48 {
                    speed *= 2.6
                }
            }

            if enemy.archetype.isRanged, !enemy.archetype.isBoss, distance < 235 {
                let tangent = CGVector(dx: -direction.dy, dy: direction.dx)
                enemy.position = enemy.position
                    + tangent * (speed * CGFloat(deltaTime) * 0.42)
            } else {
                enemy.position = enemy.position
                    + direction * (speed * CGFloat(deltaTime))
            }

            for prop in arenaProps where prop.kind == .cargo {
                let propOffset = enemy.position - prop.position
                let minimumDistance = prop.collisionRadius + enemy.radius
                if propOffset.length < minimumDistance {
                    let pushDirection = propOffset.length > 0.1
                        ? propOffset.normalized
                        : CGVector(dx: 1, dy: 0)
                    enemy.position = prop.position
                        + pushDirection * minimumDistance
                }
            }

            if enemy.archetype.isRanged {
                enemy.attackCooldown -= deltaTime
                if enemy.attackCooldown <= 0 {
                    fireHostileProjectile(from: enemy, direction: direction)
                    switch enemy.archetype {
                    case .boss:
                        enemy.attackCooldown = Double.random(in: 0.85...1.25)
                    case .sniper:
                        enemy.attackCooldown = Double.random(in: 2.2...2.9)
                    case .mortar:
                        enemy.attackCooldown = Double.random(in: 2.0...2.6)
                    default:
                        enemy.attackCooldown = Double.random(in: 1.65...2.3)
                    }
                }
            }

            if distance < enemy.radius + 23, damageCooldown <= 0 {
                let damage = receivePlayerDamage(enemy.contactDamage, attacker: enemy)
                damageCooldown = stats.contactInvulnerability
                if damage > 0 {
                    if stats.thorns > 0, enemy.takeDamage(stats.thorns) {
                        defeat(enemy, source: nil, wasCritical: false)
                    }
                    if enemy.archetype == .bomber {
                        createEnemyExplosion(at: enemy.position, damage: enemy.contactDamage * 0.8)
                        defeat(enemy, source: nil, wasCritical: false)
                    }
                }
                enemy.position = enemy.position + direction * -28
            }
        }
    }

    private func moveProjectiles(_ deltaTime: TimeInterval) {
        let paddedBounds = CGRect(
            x: -70,
            y: -70,
            width: size.width + 140,
            height: size.height + 140
        )
        for projectile in projectiles {
            if projectile.weaponType == .droneSwarm,
               let target = nearestEnemy(from: projectile.position) {
                let desired = (target.position - projectile.position).normalized
                let speed = projectile.velocity.length
                let current = projectile.velocity.normalized
                projectile.velocity = CGVector(
                    dx: current.dx * 0.82 + desired.dx * 0.18,
                    dy: current.dy * 0.82 + desired.dy * 0.18
                ).normalized * speed
                projectile.zRotation = atan2(projectile.velocity.dy, projectile.velocity.dx)
            }

            projectile.position = projectile.position
                + projectile.velocity * CGFloat(deltaTime)
            projectile.lifetime -= deltaTime

            for prop in arenaProps where prop.kind == .crystal {
                let identity = ObjectIdentifier(prop)
                let offset = projectile.position - prop.position
                guard offset.length < prop.collisionRadius + projectile.hitRadius,
                      !projectile.reflectedProps.contains(identity) else { continue }
                let normal = offset.length > 0.1
                    ? offset.normalized
                    : CGVector(dx: 1, dy: 0)
                let dot = projectile.velocity.dx * normal.dx
                    + projectile.velocity.dy * normal.dy
                projectile.velocity = CGVector(
                    dx: projectile.velocity.dx - 2 * dot * normal.dx,
                    dy: projectile.velocity.dy - 2 * dot * normal.dy
                )
                projectile.zRotation = atan2(
                    projectile.velocity.dy,
                    projectile.velocity.dx
                )
                projectile.reflectedProps.insert(identity)
                projectile.damage *= 1.08
                burst(at: prop.position, color: .gameCyan, count: 4)
            }

            if projectile.lifetime <= 0 || !paddedBounds.contains(projectile.position) {
                projectile.removeFromParent()
            }
        }
    }

    private func moveHostileProjectiles(_ deltaTime: TimeInterval) {
        let paddedBounds = CGRect(
            x: -70,
            y: -70,
            width: size.width + 140,
            height: size.height + 140
        )
        for projectile in hostileProjectiles {
            projectile.position = projectile.position
                + projectile.velocity * CGFloat(deltaTime)
            projectile.lifetime -= deltaTime

            let distance = (player.position - projectile.position).length
            if let cargo = arenaProps.first(where: {
                $0.kind == .cargo
                    && ($0.position - projectile.position).length
                        < $0.collisionRadius + projectile.hitRadius
            }) {
                burst(at: cargo.position, color: .gameYellow, count: 3)
                projectile.removeFromParent()
                continue
            }
            let canCutProjectiles = weapons.contains {
                ($0.type == .gravityLens || $0.type == .cuttingHalo)
                    && $0.level >= 4
            }
            if !projectile.isBossShot, canCutProjectiles, distance < 82 {
                burst(at: projectile.position, color: .gameCyan, count: 4)
                projectile.removeFromParent()
                continue
            }
            if distance < projectile.hitRadius + 22 {
                let adjustedDamage: CGFloat
                if wave == 20,
                   projectile.isBossShot,
                   runEffects.has(.finalBossKey) {
                    adjustedDamage = projectile.damage * 0.85
                } else {
                    adjustedDamage = projectile.damage
                }
                receivePlayerDamage(adjustedDamage, attacker: nil)
                projectile.removeFromParent()
            } else if projectile.lifetime <= 0 || !paddedBounds.contains(projectile.position) {
                if distance < 80 {
                    metrics.dodgedProjectiles += 1
                }
                projectile.removeFromParent()
            }
        }
    }

    private func updateDeployables(_ deltaTime: TimeInterval) {
        for deployable in deployables {
            let ownedRuntime = weapons.first(where: { $0.type == deployable.weaponType })
            let matriarchRuntime: WeaponRuntime? =
                selectedHero == .matriarch
                    && deployable.weaponType == .sporeInjector
                ? WeaponRuntime(type: .sporeInjector, level: 2)
                : nil
            guard let runtime = ownedRuntime ?? matriarchRuntime else {
                deployable.removeFromParent()
                continue
            }

            if deployable.weaponType == .repairBot {
                deployable.orbitAngle += CGFloat(deltaTime) * 1.1
                deployable.position = CGPoint(
                    x: player.position.x + cos(deployable.orbitAngle) * 52,
                    y: player.position.y + sin(deployable.orbitAngle) * 52
                )
                if repairAccumulator >= 4 {
                    let healBonus: CGFloat = runtime.level >= 2 ? 2 : 0
                    let healthBeforeHealing = stats.health
                    applyHealing(2 + healBonus + effectiveEngineering * 0.08)
                    if runtime.level >= 3 {
                        stats.shield = min(
                            stats.maxHealth * 0.6,
                            stats.shield + 4 + CGFloat(runtime.level)
                        )
                    }
                    if runtime.level >= 4,
                       healthBeforeHealing >= stats.maxHealth - 0.5 {
                        summonOverclockRemaining = 4
                        showToast("维修机器人：召唤物过载", color: .gameGreen)
                    }
                    repairAccumulator = 0
                }
            }

            deployable.cooldown -= deltaTime
            guard deployable.cooldown <= 0,
                  let target = nearestEnemy(from: deployable.position) else { continue }
            fire(
                runtime,
                toward: target,
                origin: deployable.position,
                isDeployable: true,
                damageScale: deployable.powerScale
            )
            var summonBonus = runEffects[.summonAttackSpeed]
            if tagCount(.engineering) >= 4 { summonBonus += 0.18 }
            if summonOverclockRemaining > 0 { summonBonus += 0.40 }
            deployable.cooldown += runtime.type.baseInterval
                * Double(runtime.intervalScale)
                * weaponIntervalModifier(runtime)
                / Double(max(0.4, 1 + effectiveAttackSpeed * 0.7 + summonBonus))
        }
    }

    private func updatePickups(_ deltaTime: TimeInterval) {
        for pickup in pickups {
            if weapons.contains(where: {
                $0.type == .sentryCapsule && $0.level >= 4
            }),
               deployables.contains(where: {
                   $0.weaponType == .sentryCapsule
                       && ($0.position - pickup.position).length < 30
               }) {
                collect(pickup)
                summonOverclockRemaining = max(summonOverclockRemaining, 1.5)
                continue
            }
            let offset = player.position - pickup.position
            let distance = offset.length
            let sentryRangeBonus: CGFloat
            if weapons.contains(where: { $0.type == .sentryCapsule && $0.level >= 3 }),
               deployables.contains(where: {
                   $0.weaponType == .sentryCapsule
                       && ($0.position - pickup.position).length < 150
               }) {
                sentryRangeBonus = 100
            } else {
                sentryRangeBonus = 0
            }
            if distance < stats.pickupRange + sentryRangeBonus {
                let attraction = max(140, 500 - distance)
                pickup.position = pickup.position
                    + offset.normalized * (attraction * CGFloat(deltaTime))
            }
            if distance < 27 {
                collect(pickup)
            }
        }
    }

    private func updatePurificationFlowers() {
        for flower in purificationFlowers
        where (flower.position - player.position).length < 30 {
            let oldCorruption = stats.corruption
            stats.corruption = max(0, stats.corruption - flower.cleanseAmount)
            let cleansed = oldCorruption - stats.corruption
            if cleansed > 0 {
                metrics.cleansedCorruption += cleansed
                if selectedHero == .purifier {
                    stats.erosion += 1
                }
                refreshCorruptionConversion()
                refreshCorruptionDerivedHealth()
                showToast(
                    "净化花：霉化 -\(Int(cleansed))",
                    color: .gameGreen
                )
            }
            applyHealing(5)
            burst(at: flower.position, color: .gameGreen, count: 8)
            flower.removeFromParent()
        }
    }

    private func updateHazards() {
        guard hazardDamageCooldown <= 0 else { return }
        if selectedHero == .demolitionist {
            return
        }

        for hazard in hazards where hazard.isHot {
            let distance = (player.position - hazard.position).length
            if distance < hazard.hazardRadius + 17 {
                let resistance = min(0.8, runEffects[.hazardResistance])
                let baseDamage = (8 + CGFloat(wave) * 0.65)
                    * (selectedThreat.rawValue >= 4 ? 1.2 : 1)
                    * (1 - resistance)
                _ = receivePlayerDamage(baseDamage, attacker: nil)
                hazardDamageCooldown = 0.7
                break
            }
        }
    }

    private func updateEnemyStatuses(_ deltaTime: TimeInterval) {
        for enemy in enemies where enemy.parent != nil {
            var damage = enemy.updateStatuses(
                deltaTime,
                burnAmplification: runEffects[.burnAmplification]
            )
            if selectedHero == .stormcaller,
               enemy.statusStacks(.shocked) > 0,
               CGFloat.random(in: 0...1) < stats.critChance {
                damage *= stats.critMultiplier
            }
            if damage > 0, enemy.takeDamage(damage) {
                defeat(enemy, source: nil, wasCritical: false)
            }
        }
    }

    // MARK: - Damage and combat effects

    @discardableResult
    private func receivePlayerDamage(
        _ rawDamage: CGFloat,
        attacker: EnemyNode?
    ) -> CGFloat {
        let tagArmor: CGFloat = tagCount(.primal) >= 4 ? 3 : 0
        let tagDodge: CGFloat = tagCount(.orbit) >= 4 ? 0.08 : 0
        let knockbackArmor: CGFloat
        if runEffects.has(.armorFromKnockback) {
            knockbackArmor = min(
                runEffects[.armorFromKnockback],
                floor(max(0, stats.knockback - 1) / 0.10)
            )
        } else {
            knockbackArmor = 0
        }
        let bulwarkDodgeOverflow = selectedHero == .bulwark
            ? max(0, stats.dodgeChance - 0.20)
            : 0
        stats.armor += tagArmor + knockbackArmor
        stats.dodgeChance += tagDodge - bulwarkDodgeOverflow
        let oldHealth = stats.health
        let bossAdjustedDamage: CGFloat
        if wave == 20,
           attacker?.archetype.isBoss == true,
           runEffects.has(.finalBossKey) {
            bossAdjustedDamage = rawDamage * 0.85
        } else {
            bossAdjustedDamage = rawDamage
        }
        let damage = stats.receiveDamage(bossAdjustedDamage)
        stats.armor -= tagArmor + knockbackArmor
        stats.dodgeChance -= tagDodge - bulwarkDodgeOverflow

        if damage <= 0 {
            metrics.dodgedProjectiles += 1
            dodgeEmpowered = runEffects.has(.dodgeEmpower)
            showFloatingText("闪避", at: player.position, color: .gameCyan)
            if runEffects.has(.dodgeCounter), let attacker {
                if attacker.takeDamage(8 + stats.weaponPower) {
                    defeat(attacker, source: nil, wasCritical: true)
                }
            }
            return 0
        }

        tookDamageThisWave = true
        lastDamageTime = 0
        outOfCombatHealAccumulator = 0
        hurtSpeedRemaining = 2
        player.showDamage()
        showDamageNumber(damage, at: player.position, color: .gameCoral)
        SoundManager.shared.play(.hit)
        impact(.medium)
        if settings.screenShake {
            worldLayer.removeAction(forKey: "damageShake")
            worldLayer.run(.sequence([
                .moveBy(x: 4, y: -3, duration: 0.025),
                .moveBy(x: -7, y: 5, duration: 0.03),
                .move(to: .zero, duration: 0.04)
            ]), withKey: "damageShake")
        }

        if runEffects.has(.loseScrapOnHit) {
            scrap = max(0, scrap - Int(CGFloat(scrap) * runEffects[.loseScrapOnHit]))
        }
        if attacker?.eliteAffix == .vampiric {
            attacker?.heal((attacker?.healthRatio ?? 0) * 8 + 3)
        }

        if oldHealth > 0, stats.health <= 0 {
            let availableExtraLives = Int(runEffects[.extraLife])
            if extraLivesUsed < availableExtraLives {
                extraLivesUsed += 1
                stats.health = 1
                damageCooldown = 2
                showToast("备用心脏启动", color: .gameGreen)
            } else if runEffects.has(.secondHeart), !secondHeartUsed {
                secondHeartUsed = true
                stats.health = stats.maxHealth * 0.5
                stats.globalDamage += 0.25
                stats.armor -= 5
                damageCooldown = 2
                showToast("第二颗心：狂化", color: .gameCoral)
            }
        }
        return damage
    }

    private func applyHealing(_ amount: CGFloat) {
        let missing = max(0, stats.maxHealth - stats.health)
        var tagHealingMultiplier: CGFloat = tagCount(.biotech) >= 4 ? 1.18 : 1
        if effectiveCorruptionStage >= 3 {
            tagHealingMultiplier *= 0.85
        }
        let adjusted = max(
            0,
            amount * stats.healingEfficiency * tagHealingMultiplier
        )
        let overheal = max(0, adjusted - missing)
        stats.heal(amount * tagHealingMultiplier)
        if overheal > 0,
           runEffects.has(.overhealShield) || tagCount(.biotech) >= 6 {
            let cap = stats.maxHealth * 0.20
            let conversion = max(
                runEffects[.overhealShield],
                tagCount(.biotech) >= 6 ? 0.50 : 0
            )
            stats.shield = min(cap, stats.shield + overheal * conversion)
        }
    }

    private func handlePotentialDeath() {
        guard stats.health <= 0 else { return }
        if runEffects.has(.retryWave), insuranceRetryWave != wave {
            retryCurrentWave()
            return
        }
        endRun(victory: false)
    }

    private func retryCurrentWave() {
        insuranceRetryWave = wave
        clearCombatants()
        stats = waveStartStats
        metrics = waveStartMetrics
        scrap = waveStartScrap
        runScore = waveStartRunScore
        experience = waveStartExperience
        level = waveStartLevel
        pendingLevelUps = waveStartPendingLevelUps
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        player.setScale(1)
        player.alpha = 1
        startWave()
        insuranceRetryWave = wave
        showToast("因果保险：本波时间线已重置", color: .gameCyan)
    }

    private func handleProjectileHits() {
        let currentEnemies = enemies

        for projectile in projectiles where projectile.parent != nil {
            for enemy in currentEnemies where enemy.parent != nil {
                let identity = ObjectIdentifier(enemy)
                guard !projectile.hitEnemies.contains(identity) else { continue }
                let distance = (enemy.position - projectile.position).length
                guard distance < enemy.radius + projectile.hitRadius else { continue }

                if projectile.splashRadius > 0 {
                    explode(projectile, at: enemy.position)
                    projectile.removeFromParent()
                    break
                }

                projectile.hitEnemies.insert(identity)
                var damage = projectile.damage
                if enemy.archetype.isBoss {
                    damage *= stats.bossDamage
                    if wave == 20, runEffects.has(.finalBossKey) {
                        damage *= 1.15
                    }
                } else if enemy.isElite {
                    damage *= stats.eliteDamage + runEffects[.eliteDamage]
                }
                if tagCount(.precision) >= 6,
                   enemy.statusStacks(.marked) > 0 {
                    damage *= 1.10
                }
                if tagCount(.resonance) >= 6, enemy.hasAnyStatus {
                    damage *= 1.12
                }
                if tagCount(.orbit) >= 6,
                   (enemy.position - player.position).length < 145 {
                    damage *= 1.20
                }
                if projectile.weaponType == .miningLaser,
                   projectile.sourceTier >= 3,
                   enemy.healthRatio >= 0.99 {
                    damage *= 1.30
                }
                if projectile.weaponType == .leechHose,
                   projectile.sourceTier >= 3 {
                    damage *= 1 + min(
                        0.50,
                        CGFloat(enemy.statusStacks(.corrosion)) * 0.05
                    )
                }
                var wasDefeated = enemy.takeDamage(damage)
                showDamageNumber(
                    damage,
                    at: enemy.position,
                    color: projectile.isCritical ? .white : projectile.weaponType.color,
                    isCritical: projectile.isCritical
                )

                if let statusKind = projectile.statusKind,
                   CGFloat.random(in: 0...1) <= projectile.statusChance {
                    var stacks = projectile.sourceTier >= 3 ? 2 : 1
                    if projectile.weaponType == .emberSprayer,
                       projectile.sourceTier >= 2 {
                        stacks += 1
                    }
                    if projectile.weaponType == .sporeInjector,
                       projectile.sourceTier >= 2,
                       statusKind == .corrosion {
                        stacks += 1
                    }
                    let duration = statusDuration(statusKind)
                        + (projectile.weaponType == .prismNeedle
                            && projectile.sourceTier >= 2 ? 2 : 0)
                    enemy.applyStatus(
                        statusKind,
                        stacks: stacks,
                        duration: duration,
                        potency: projectile.statusPotency,
                        maximumBonus: statusKind == .burning
                            ? (tagCount(.burning) >= 2 ? 2 : 0)
                                + (selectedHero == .ashen ? 5 : 0)
                            : 0
                    )
                    if statusKind == .burning {
                        metrics.totalBurnStacks += stacks
                        let detonationMultiplier: CGFloat
                        if runEffects.has(.burnDetonation) {
                            detonationMultiplier = runEffects[.burnDetonation]
                        } else if projectile.weaponType == .coronaEmitter,
                                  projectile.sourceTier >= 4 {
                            detonationMultiplier = 1.35
                        } else {
                            detonationMultiplier = 0
                        }
                        if detonationMultiplier > 0,
                           enemy.statusStacks(.burning) >= 10 {
                            let consumed = enemy.consumeStatus(.burning)
                            let detonationDamage = CGFloat(consumed.stacks)
                                * consumed.potency
                                * 3
                                * detonationMultiplier
                            showExplosion(
                                at: enemy.position,
                                radius: 48,
                                color: .gameCoral
                            )
                            wasDefeated = enemy.takeDamage(detonationDamage) || wasDefeated
                            showDamageNumber(
                                detonationDamage,
                                at: enemy.position,
                                color: .gameCoral,
                                isCritical: true
                            )
                        }
                    }
                }

                if projectile.isCritical,
                   runEffects.has(.shockOnCrit),
                   CGFloat.random(in: 0...1) < runEffects[.shockOnCrit] {
                    enemy.applyStatus(.shocked, duration: 3, potency: stats.erosion * 0.2 + 2)
                }

                if runEffects.has(.chillChance),
                   CGFloat.random(in: 0...1) < runEffects[.chillChance] {
                    enemy.applyStatus(.chilled, duration: 2, potency: 0)
                }

                let shockStacks = enemy.statusStacks(.shocked)
                if shockStacks > 0 {
                    let excluded = Set([ObjectIdentifier(enemy)])
                    if let chained = nearestEnemy(
                        from: enemy.position,
                        excluding: excluded
                    ), (chained.position - enemy.position).length < 190 {
                        var shockDamage = CGFloat(shockStacks)
                            * (2 + effectiveErosion * 0.20)
                        let shockCritical = selectedHero == .stormcaller
                            && CGFloat.random(in: 0...1) < stats.critChance
                        if shockCritical {
                            shockDamage *= stats.critMultiplier
                        }
                        if chained.takeDamage(shockDamage) {
                            defeat(
                                chained,
                                source: projectile.weaponType,
                                wasCritical: shockCritical
                            )
                        }
                        showDamageNumber(
                            shockDamage,
                            at: chained.position,
                            color: .gameCyan,
                            isCritical: shockCritical
                        )
                    }
                }

                if runEffects.has(.freezeAtMax),
                   enemy.statusStacks(.chilled) >= 5 {
                    _ = enemy.consumeStatus(.chilled)
                    if enemy.archetype.isBoss {
                        enemy.applyStatus(.marked, duration: 4, potency: 0)
                    } else {
                        enemy.freeze(for: 1)
                        showFloatingText("冻结", at: enemy.position, color: .gameCyan)
                    }
                }

                triggerLifeSteal(
                    weapon: projectile.weaponType,
                    tier: projectile.sourceTier,
                    isSummon: projectile.isSummon
                )

                let knockDirection = (enemy.position - player.position).normalized
                enemy.position = enemy.position
                    + knockDirection * (7 * stats.knockback)

                if wasDefeated {
                    defeat(
                        enemy,
                        source: projectile.weaponType,
                        wasCritical: projectile.isCritical
                    )
                    if runEffects.has(.resetPierceOnKill) {
                        projectile.pierceRemaining = max(projectile.pierceRemaining, 1)
                        projectile.damage *= 1 + runEffects[.resetPierceOnKill]
                    }
                }

                if projectile.weaponType == .railLance,
                   projectile.sourceTier >= 3 {
                    projectile.damage *= 1.08
                }

                projectile.pierceRemaining -= 1
                if projectile.pierceRemaining > 0,
                   !(projectile.weaponType == .arcCoil
                        && projectile.sourceTier >= 3) {
                    projectile.damage *= 0.82
                }
                if projectile.pierceRemaining <= 0 {
                    if projectile.bounceRemaining > 0,
                       let target = nearestEnemy(
                        from: projectile.position,
                        excluding: projectile.hitEnemies
                       ) {
                        projectile.bounceRemaining -= 1
                        projectile.pierceRemaining = 1
                        projectile.damage *= 0.75
                        let speed = projectile.velocity.length
                        projectile.velocity = (target.position - projectile.position).normalized * speed
                        projectile.zRotation = atan2(projectile.velocity.dy, projectile.velocity.dx)
                    } else {
                        projectile.removeFromParent()
                    }
                    break
                }
            }
        }
    }

    private func triggerLifeSteal(
        weapon: WeaponType? = nil,
        tier: Int = 1,
        isSummon: Bool = false
    ) {
        var chance = stats.lifeSteal
        if weapon == .leechHose {
            chance += 0.05
        }
        if weapon == .emberSprayer, tier >= 3 {
            chance += 0.03
        }
        if isSummon {
            chance *= runEffects[.summonCritInheritance]
        }
        if tagCount(.biotech) >= 2 {
            chance += 0.02
        }
        guard chance > 0, CGFloat.random(in: 0...1) < chance else { return }
        let wasFullHealth = stats.health >= stats.maxHealth - 0.5
        applyHealing(1)
        if weapon == .leechHose, tier >= 4, wasFullHealth {
            stats.shield = min(stats.maxHealth * 0.20, stats.shield + 1)
        }
        if runEffects.has(.lifestealRamp) {
            lifeStealRamp = min(0.40, lifeStealRamp + runEffects[.lifestealRamp])
        }
    }

    private func explode(_ projectile: ProjectileNode, at position: CGPoint) {
        let explosiveRange: CGFloat = tagCount(.explosive) >= 2 ? 1.10 : 1
        let radius = projectile.splashRadius
            * stats.projectileSize
            * explosiveRange
        showExplosion(at: position, radius: radius, color: projectile.weaponType.color)

        var killed = 0
        for enemy in enemies where enemy.parent != nil {
            let distance = (enemy.position - position).length
            guard distance <= radius + enemy.radius else { continue }
            let falloff = max(0.45, 1 - distance / (radius * 1.7))
            var damage = projectile.damage * falloff * stats.explosionDamage
            if tagCount(.explosive) >= 4 {
                damage *= 1.18
            }
            if enemy.archetype.isBoss {
                damage *= stats.bossDamage
            } else if enemy.isElite {
                damage *= stats.eliteDamage + runEffects[.eliteDamage]
            }
            if enemy.takeDamage(damage) {
                killed += 1
                defeat(enemy, source: projectile.weaponType, wasCritical: projectile.isCritical)
            }
            showDamageNumber(damage, at: enemy.position, color: projectile.weaponType.color)
            if runEffects.has(.singularityExplosion) {
                enemy.position = enemy.position
                    + (position - enemy.position).normalized * 24
            }
            if projectile.weaponType == .gravityMortar {
                let pull: CGFloat = projectile.sourceTier >= 2 ? 38 : 30
                enemy.position = enemy.position
                    + (position - enemy.position).normalized * pull
                if projectile.sourceTier >= 3 {
                    enemy.applyStatus(.chilled, duration: 2.5, potency: 0)
                }
            }
            if let statusKind = projectile.statusKind {
                enemy.applyStatus(
                    statusKind,
                    duration: statusDuration(statusKind),
                    potency: projectile.statusPotency,
                    maximumBonus: statusKind == .burning
                        ? (tagCount(.burning) >= 2 ? 2 : 0)
                            + (selectedHero == .ashen ? 5 : 0)
                        : 0
                )
            }
            if projectile.weaponType == .magmaOrb,
               projectile.sourceTier >= 3 {
                enemy.applyStatus(.corrosion, stacks: 2, duration: 4, potency: 1)
            }
        }

        metrics.maxExplosionKills = max(metrics.maxExplosionKills, killed)
        if projectile.weaponType == .magmaOrb,
           projectile.sourceTier >= 4 {
            aftershock(
                at: position,
                radius: radius * 1.35,
                damage: projectile.damage * 0.65,
                color: .gameCoral
            )
        }
        if projectile.weaponType == .meteorTube,
           projectile.sourceTier >= 3 {
            run(.sequence([
                .wait(forDuration: 0.35),
                .run { [weak self] in
                    guard let self else { return }
                    self.showExplosion(
                        at: position,
                        radius: radius * 0.72,
                        color: .gameCoral
                    )
                    for enemy in self.enemies
                    where (enemy.position - position).length <= radius {
                        enemy.applyStatus(
                            .burning,
                            stacks: 2,
                            duration: 3,
                            potency: 1.2 + self.effectiveErosion * 0.16
                        )
                    }
                }
            ]))
        }
        if projectile.weaponType == .meteorTube,
           projectile.sourceTier >= 4 {
            spawnMicroRockets(
                at: position,
                damage: projectile.damage * 0.32
            )
        }
        if runEffects.has(.explosionAftershock) || tagCount(.explosive) >= 6 {
            let ratio = max(runEffects[.explosionAftershock], tagCount(.explosive) >= 6 ? 0.35 : 0)
            run(.sequence([
                .wait(forDuration: 0.35),
                .run { [weak self] in
                    self?.aftershock(
                        at: position,
                        radius: radius,
                        damage: projectile.damage * ratio,
                        color: projectile.weaponType.color
                    )
                }
            ]))
        }
    }

    private func spawnMicroRockets(at position: CGPoint, damage: CGFloat) {
        for index in 0..<3 {
            let angle = CGFloat(index) / 3 * .pi * 2
            let direction = CGVector(dx: cos(angle), dy: sin(angle))
            let projectile = ProjectileNode(
                damage: damage,
                velocity: direction * 430,
                weaponType: .meteorTube,
                pierce: 1,
                splashRadius: 32,
                lifetime: 0.65,
                sizeScale: 0.65,
                sourceTier: 1,
                statusKind: .burning,
                statusChance: 1,
                statusPotency: 1 + effectiveErosion * 0.10
            )
            projectile.position = position
            worldLayer.addChild(projectile)
        }
    }

    private func aftershock(
        at position: CGPoint,
        radius: CGFloat,
        damage: CGFloat,
        color: SKColor
    ) {
        showExplosion(at: position, radius: radius * 0.82, color: color)
        for enemy in enemies where enemy.parent != nil {
            guard (enemy.position - position).length <= radius + enemy.radius else { continue }
            if enemy.takeDamage(damage) {
                defeat(enemy, source: nil, wasCritical: false)
            }
        }
    }

    private func showExplosion(at position: CGPoint, radius: CGFloat, color: SKColor) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.fillColor = color.withAlphaComponent(settings.reducedEffects ? 0.10 : 0.20)
        ring.strokeColor = color
        ring.lineWidth = 3
        ring.glowWidth = settings.reducedEffects ? 2 : 7
        ring.position = position
        ring.zPosition = 40
        ring.setScale(0.25)
        worldLayer.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 1, duration: 0.18),
                .fadeOut(withDuration: 0.24)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Weapons

    private func fireWeapons(_ deltaTime: TimeInterval) {
        guard let target = nearestEnemy(from: player.position) else { return }

        for index in weapons.indices {
            guard weapons[index].type.pattern != .deployable else { continue }
            weapons[index].cooldown -= deltaTime
            guard weapons[index].cooldown <= 0 else { continue }

            let runtime = weapons[index]
            fire(runtime, toward: target, origin: player.position)
            weapons[index].cooldown += runtime.type.baseInterval
                * Double(runtime.intervalScale)
                * weaponIntervalModifier(runtime)
                / Double(max(0.4, 1 + effectiveAttackSpeed))

            if index == 0,
               runEffects.has(.mirrorWeapon),
               weapons.count > 1,
               CGFloat.random(in: 0...1) < runEffects[.mirrorWeapon] {
                fire(weapons[weapons.count - 1], toward: target, origin: player.position)
            }
        }
    }

    private func fire(
        _ runtime: WeaponRuntime,
        toward target: EnemyNode,
        origin: CGPoint,
        isDeployable: Bool = false,
        damageScale: CGFloat = 1
    ) {
        let type = runtime.type
        let effectiveTier = min(
            4,
            runtime.level
                + (type.tags.contains(.biotech) && runEffects.has(.biotechTierBoost) ? 1 : 0)
        )
        let targetDistance = (target.position - origin).length
        let weaponRangeBonus: CGFloat = type == .leechHose && effectiveTier >= 2 ? 1.20 : 1
        guard targetDistance <= 560 * stats.rangeMultiplier * weaponRangeBonus
                || type.pattern == .radial else { return }

        let baseDirection = (target.position - origin).normalized
        var volley = type.baseVolley + Int(runEffects[.extraProjectile])
        let nextShotCount = weaponShotCounters[type, default: 0] + 1
        weaponShotCounters[type] = nextShotCount
        let pulseEmpowered = type == .pulseCannon
            && effectiveTier >= 3
            && nextShotCount.isMultiple(of: 4)
        if pulseEmpowered, effectiveTier >= 4 { volley += 2 }
        if tagCount(.ballistic) >= 6 { volley += 1 }
        if type == .starBlades, effectiveTier >= 2 { volley += 2 }
        if type == .starBlades, effectiveTier >= 4 { volley *= 2 }
        if type == .scattergun, effectiveTier >= 2 { volley += 1 }
        if type == .droneSwarm, effectiveTier >= 2 { volley += 1 }
        if type == .clusterPod, effectiveTier >= 2 { volley += 2 }
        if type == .gravityMortar, effectiveTier >= 4 { volley += 2 }
        if type == .gravityLens, effectiveTier >= 2 { volley += 1 }
        if type == .quantumBoomerang, effectiveTier >= 3 { volley += 1 }
        if type == .cuttingHalo, effectiveTier >= 2 { volley += 1 }
        if type == .rivetRepeater, effectiveTier >= 4, rivetPickupStacks >= 10 { volley += 1 }
        if type == .phaseCarbine, effectiveTier >= 4 { volley += 3 }
        if type == .coronaEmitter,
           effectiveTier >= 3,
           stats.health / stats.maxHealth < 0.5 {
            volley *= 2
        }
        volley = max(1, volley)

        for shot in 0..<volley {
            let direction: CGVector
            if type.pattern == .radial || type.pattern == .orbit {
                let angle = CGFloat(shot) / CGFloat(volley) * .pi * 2
                    + CGFloat(lastUpdateTime * 0.35)
                direction = CGVector(dx: cos(angle), dy: sin(angle))
            } else if volley == 1 {
                direction = baseDirection
            } else {
                let spread = type.spread > 0
                    ? type.spread
                    : min(0.34, CGFloat(volley - 1) * 0.10)
                let angle = -spread / 2
                    + spread * CGFloat(shot) / CGFloat(max(1, volley - 1))
                direction = baseDirection.rotated(by: angle)
            }

            var criticalChance = isDeployable
                ? stats.critChance * runEffects[.summonCritInheritance]
                : stats.critChance
            if tagCount(.precision) >= 2 { criticalChance += 0.06 }
            if runEffects.has(.luckToCrit) {
                criticalChance += min(
                    0.25,
                    effectiveLuck * runEffects[.luckToCrit] / 100
                )
            }
            var isCritical = dodgeEmpowered
                || CGFloat.random(in: 0...1) < min(0.8, criticalChance)
            if type == .phaseCarbine,
               effectiveTier >= 2,
               shot % max(1, type.baseVolley) == type.baseVolley - 1 {
                isCritical = true
            }
            if type == .quantumBoomerang,
               effectiveTier >= 2,
               shot.isMultiple(of: 2) {
                isCritical = true
            }

            var damage = weaponDamage(runtime) * damageScale
            if pulseEmpowered { damage *= 1.75 }
            if type == .scattergun, effectiveTier >= 3, targetDistance < 165 {
                damage *= 1.25
            }
            if isCritical {
                var multiplier = stats.critMultiplier
                if tagCount(.precision) >= 4 { multiplier += 0.25 }
                damage *= multiplier
            }
            if dodgeEmpowered {
                damage *= 1.35
                dodgeEmpowered = false
            }

            var pierce = type.pierce + Int(runEffects[.extraPierce])
            if type == .pulseCannon, effectiveTier >= 2 { pierce += 1 }
            if type == .railLance, effectiveTier >= 2 { pierce += 2 }
            if tagCount(.ballistic) >= 6 { pierce += 1 }

            var bounce = Int(runEffects[.ricochet])
                + (type == .prismNeedle && effectiveTier >= 3 ? 1 : 0)
                + (tagCount(.resonance) >= 4 ? 1 : 0)
                + Int(runEffects[.chainBonus])
            if type == .arcCoil, effectiveTier >= 2 { bounce += 1 }
            if type == .ionSplitter, effectiveTier >= 2 { bounce += 1 }
            if type == .starBlades, effectiveTier >= 3 { bounce += 1 }
            if type == .quantumBoomerang {
                bounce += effectiveTier >= 4 ? 2 : 1
            }
            if runEffects.has(.freeShockJump),
               CGFloat.random(in: 0...1) < runEffects[.freeShockJump] {
                bounce += 1
            }

            let status = projectileStatus(for: type, tier: effectiveTier)
            let ballisticSpeed: CGFloat = tagCount(.ballistic) >= 2 ? 1.10 : 1
            let speedMultiplier = stats.projectileSpeed / 560 * ballisticSpeed
            var splashRadius = type.splashRadius
            if type == .meteorTube, effectiveTier >= 2 { splashRadius *= 1.18 }
            if type == .ionSplitter, effectiveTier >= 4 { splashRadius = 42 }
            if type == .gravityLens, effectiveTier >= 3 { splashRadius = 38 }
            let projectile = ProjectileNode(
                damage: damage,
                velocity: direction * (type.projectileSpeed * speedMultiplier),
                weaponType: type,
                pierce: pierce,
                bounce: bounce,
                splashRadius: splashRadius,
                lifetime: type.projectileLifetime * Double(stats.rangeMultiplier),
                sizeScale: stats.projectileSize * (1 + CGFloat(effectiveTier - 1) * 0.04),
                isCritical: isCritical,
                isSummon: isDeployable,
                sourceTier: effectiveTier,
                statusKind: status.kind,
                statusChance: status.chance,
                statusPotency: status.potency
            )
            projectile.position = origin + direction * 24
            worldLayer.addChild(projectile)
        }

        if !isDeployable {
            player.run(.sequence([
                .scale(to: 0.96, duration: 0.03),
                .scale(to: 1, duration: 0.06)
            ]))
            SoundManager.shared.play(.shoot)
        }
    }

    private func weaponDamage(_ runtime: WeaponRuntime) -> CGFloat {
        let type = runtime.type
        var base = type.baseDamage
            + type.weaponCoefficient * effectiveWeaponPower
            + type.engineeringCoefficient * effectiveEngineering
            + type.erosionCoefficient * effectiveErosion
        base *= runtime.damageScale

        var bonus = stats.globalDamage
        if selectedHero == .pioneer {
            bonus += CGFloat(uniqueEquippedTagCount) * 0.02
        }
        if selectedHero == .replicator {
            let matching = weapons.filter { $0.type == type }.count
            bonus += CGFloat(max(0, matching - 1)) * 0.09
        }
        if selectedHero == .harvester {
            bonus += (1 - stats.health / stats.maxHealth) * 0.30
        }
        if selectedHero == .matriarch {
            bonus += floor(stats.corruption / 10) * 0.03
        }
        if selectedHero == .bulwark, stationaryDuration >= 1 {
            bonus += 0.25
        }
        if runEffects.has(.missingHealthDamage) {
            bonus += floor((1 - stats.health / stats.maxHealth) * 10)
                * runEffects[.missingHealthDamage]
        }
        if runEffects.has(.criticalHealthDamage), stats.health / stats.maxHealth < 0.30 {
            bonus += runEffects[.criticalHealthDamage]
        }
        if runEffects.has(.projectileSpeedDamage) {
            let excess = max(0, stats.projectileSpeed / 560 - 1.5)
            bonus += floor(excess / 0.10) * 0.02
        }
        if runEffects.has(.closeRangeDamage) {
            let missing = max(0, 1 - stats.rangeMultiplier)
            bonus += floor(missing / 0.10) * 0.06
        }
        if runEffects.has(.emptySlotDamage) {
            bonus += CGFloat(max(0, selectedHero.maxWeaponSlots - weapons.count))
                * runEffects[.emptySlotDamage]
        }
        if effectiveCorruptionStage == 4 {
            bonus += 0.25
        }
        if tagCount(.primal) >= 6, stats.health / stats.maxHealth < 0.40 {
            bonus += 0.22
        }
        if type == .cuttingHalo {
            bonus += cuttingHaloKillBonus
        }
        return max(1, base * max(0.2, 1 + bonus))
    }

    private func weaponIntervalModifier(_ runtime: WeaponRuntime) -> Double {
        var modifier = 1.0
        if runtime.type == .rivetRepeater, runtime.level >= 2 {
            modifier *= 0.88
            modifier /= 1 + Double(rivetPickupStacks) * 0.02
        }
        if runtime.type == .phaseCarbine, runtime.level >= 3 {
            modifier *= 0.80
        }
        return modifier
    }

    private func weaponTier(for type: WeaponType) -> Int {
        weapons
            .filter { $0.type == type }
            .map(\.level)
            .max() ?? 1
    }

    private var effectiveWeaponPower: CGFloat {
        stats.weaponPower + (tagCount(.ballistic) >= 6 ? 10 : 0)
    }

    private var effectiveEngineering: CGFloat {
        stats.engineering + (tagCount(.engineering) >= 2 ? 5 : 0)
    }

    private var effectiveErosion: CGFloat {
        stats.erosion
            + (tagCount(.resonance) >= 2 ? 4 : 0)
            + (tagCount(.burning) >= 4 ? 8 : 0)
    }

    private var effectiveAttackSpeed: CGFloat {
        var value = stats.attackSpeed + lifeStealRamp
        if tagCount(.ballistic) >= 4 { value += 0.10 }
        if stats.health / stats.maxHealth < 0.5 {
            value += runEffects[.lowHealthAttackSpeed]
        }
        if runEffects.has(.occupiedSlotAttackSpeed) {
            value += CGFloat(weapons.count) * runEffects[.occupiedSlotAttackSpeed]
        }
        if selectedHero == .ashen, stats.health / stats.maxHealth < 0.5 {
            value += 0.08
        }
        let jammerNearby = enemies.contains {
            $0.eliteAffix == .jammer && ($0.position - player.position).length < 180
        }
        if jammerNearby { value -= 0.15 }
        return max(-0.6, value)
    }

    private func projectileStatus(
        for weapon: WeaponType,
        tier: Int
    ) -> (kind: StatusKind?, chance: CGFloat, potency: CGFloat) {
        switch weapon {
        case .emberSprayer, .magmaOrb, .coronaEmitter, .meteorTube:
            return (.burning, 1, 1.2 + effectiveErosion * 0.16)
        case .arcCoil, .ionSplitter, .gravityLens:
            return (.shocked, 0.65, 1 + effectiveErosion * 0.12)
        case .sporeInjector:
            return (tier >= 3 ? .spored : .corrosion, 1, 1 + effectiveErosion * 0.14)
        case .leechHose:
            return (.corrosion, 0.45, 1)
        case .prismNeedle:
            return (.marked, 1, 0)
        default:
            return (nil, 0, 0)
        }
    }

    private func statusDuration(_ status: StatusKind) -> TimeInterval {
        switch status {
        case .burning: 3
        case .shocked: 3
        case .corrosion: 4
        case .chilled: 2
        case .marked: 4
        case .spored: 3
        }
    }

    // MARK: - Enemies

    @discardableResult
    private func spawnEnemy(
        archetype: EnemyArchetype? = nil,
        near position: CGPoint? = nil,
        countsBudget: Bool = true
    ) -> CGFloat {
        let chosen: EnemyArchetype
        if let archetype {
            chosen = archetype
        } else {
            let effectiveWave = wave + selectedThreat.rawValue / 2
            let candidates = EnemyArchetype.allCases.filter {
                !$0.isBoss
                    && $0.unlockWave <= effectiveWave
                    && $0.threatCost <= max(1, waveBudgetRemaining)
            }
            chosen = weightedEnemy(from: candidates)
        }

        let eliteChance = min(
            0.45,
            selectedThreat.eliteChance
                + CGFloat(effectiveCorruptionStage) * 0.03
                + (mechanicalArena == .emberFoundry ? 0.05 : 0)
        )
        let isElite = !chosen.isBoss
            && (
                forcedCorruptionElitePending
                    || (wave >= 3 && CGFloat.random(in: 0...1) < eliteChance)
            )
        let affix = isElite ? EliteAffix.allCases.randomElement() : nil
        if isElite {
            forcedCorruptionElitePending = false
        }
        let enemy = EnemyNode(
            wave: wave,
            archetype: chosen,
            arena: mechanicalArena,
            threat: selectedThreat,
            settings: settings,
            eliteAffix: affix
        )
        if let position {
            enemy.position = CGPoint(
                x: position.x + CGFloat.random(in: -24...24),
                y: position.y + CGFloat.random(in: -24...24)
            )
        } else {
            enemy.position = randomSpawnPosition(radius: enemy.radius)
        }
        worldLayer.addChild(enemy)
        return countsBudget ? chosen.threatCost : 0
    }

    private func weightedEnemy(from candidates: [EnemyArchetype]) -> EnemyArchetype {
        guard !candidates.isEmpty else { return .crawler }
        let total = candidates.reduce(CGFloat.zero) { result, enemy in
            result + 1 / max(1, enemy.threatCost)
        }
        var roll = CGFloat.random(in: 0...total)
        for enemy in candidates {
            roll -= 1 / max(1, enemy.threatCost)
            if roll <= 0 { return enemy }
        }
        return candidates[0]
    }

    private func spawnBoss() {
        let boss = EnemyNode(
            wave: wave,
            archetype: .boss,
            arena: mechanicalArena,
            threat: selectedThreat,
            settings: settings
        )
        boss.position = CGPoint(x: size.width / 2, y: size.height + boss.radius + 20)
        boss.setScale(0.2)
        worldLayer.addChild(boss)
        boss.run(.sequence([
            .scale(to: 1.15, duration: 0.24),
            .scale(to: 1, duration: 0.12)
        ]))
    }

    private func fireHostileProjectile(from enemy: EnemyNode, direction: CGVector) {
        if enemy.archetype.isBoss {
            let baseCount = wave >= 15 ? 12 : 8
            let count = selectedThreat.rawValue >= 2 ? baseCount + 4 : baseCount
            for index in 0..<count {
                let angle = CGFloat(index) / CGFloat(count) * .pi * 2
                    + CGFloat(lastUpdateTime * 0.2)
                let radial = CGVector(dx: cos(angle), dy: sin(angle))
                let speed: CGFloat = mechanicalArena == .crystalHollows ? 185 : 155
                let shot = HostileProjectileNode(
                    damage: (9 + CGFloat(wave) * 0.7)
                        * selectedThreat.enemyDamageMultiplier
                        * settings.enemyDamageScale,
                    velocity: radial * speed,
                    isBossShot: true
                )
                shot.position = enemy.position + radial * (enemy.radius + 8)
                worldLayer.addChild(shot)
            }

            if mechanicalArena == .emberFoundry {
                let hazard = HazardNode(radius: 34, color: .gameCoral)
                hazard.position = CGPoint(
                    x: min(size.width - 40, max(40, player.position.x)),
                    y: min(size.height - 110, max(40, player.position.y))
                )
                worldLayer.addChild(hazard)
                hazard.run(.sequence([.wait(forDuration: 7), .removeFromParent()]))
            }
        } else {
            let speed: CGFloat
            switch enemy.archetype {
            case .sniper: speed = 360
            case .mortar: speed = 125
            default: speed = 190
            }
            let shot = HostileProjectileNode(
                damage: (7 + CGFloat(wave) * 0.55)
                    * selectedThreat.enemyDamageMultiplier
                    * settings.enemyDamageScale,
                velocity: direction * speed,
                isBossShot: enemy.archetype == .sniper
            )
            shot.position = enemy.position + direction * (enemy.radius + 6)
            worldLayer.addChild(shot)
        }
    }

    private func defeat(
        _ enemy: EnemyNode,
        source: WeaponType?,
        wasCritical: Bool
    ) {
        guard enemy.parent != nil else { return }
        let corrosionStacks = enemy.statusStacks(.corrosion)
        let burningStacks = enemy.statusStacks(.burning)
        let wasMarked = enemy.statusStacks(.marked) > 0
        metrics.kills += 1

        if enemy.archetype.isBoss {
            metrics.bosses += 1
            if weapons.count == 1 {
                saveStore.mutate { $0.singleWeaponBossKills += 1 }
            }
            impact(.heavy)
            SoundManager.shared.play(.boss)
        }

        let sourceTier = source.map(weaponTier(for:)) ?? 1
        let miningDropChance: CGFloat = sourceTier >= 2 ? 0.16 : 0.12
        if source == .miningLaser,
           CGFloat.random(in: 0...1) < miningDropChance {
            let bonus = PickupNode(value: 1)
            bonus.position = enemy.position + CGVector(dx: 10, dy: 0)
            worldLayer.addChild(bonus)
        }
        if wasCritical, runEffects.has(.critHeal) {
            applyHealing(runEffects[.critHeal])
        }

        if runEffects.has(.splitOnKill),
           CGFloat.random(in: 0...1) < runEffects[.splitOnKill] {
            spawnSplitProjectiles(at: enemy.position, color: source?.color ?? .gameBlue)
        }

        if enemy.statusStacks(.spored) > 0 {
            createFriendlyBurst(
                at: enemy.position,
                damage: 8 + stats.erosion * 0.6,
                radius: 54,
                color: .gamePurple
            )
        }

        if burningStacks > 0,
           tagCount(.burning) >= 6 || selectedHero == .ashen {
            let excluded = Set([ObjectIdentifier(enemy)])
            if let target = nearestEnemy(from: enemy.position, excluding: excluded),
               (target.position - enemy.position).length
                    <= (selectedHero == .ashen ? 190 : 140) {
                target.applyStatus(
                    .burning,
                    stacks: 2,
                    duration: 3,
                    potency: 1.2 + effectiveErosion * 0.16,
                    maximumBonus: (tagCount(.burning) >= 2 ? 2 : 0)
                        + (selectedHero == .ashen ? 5 : 0)
                )
            }
        }

        if corrosionStacks > 0,
           runEffects.has(.corrosionSpread) {
            let excluded = Set([ObjectIdentifier(enemy)])
            if let target = nearestEnemy(from: enemy.position, excluding: excluded) {
                let spreadStacks = max(
                    1,
                    Int(
                        (CGFloat(corrosionStacks) * runEffects[.corrosionSpread])
                            .rounded(.down)
                    )
                )
                target.applyStatus(
                    .corrosion,
                    stacks: spreadStacks,
                    duration: 4,
                    potency: 1
                )
                showFloatingText(
                    "腐蚀传播 \(spreadStacks)",
                    at: target.position,
                    color: .gameGreen
                )
            }
        }

        if enemy.eliteAffix == .volatile || enemy.archetype == .bomber {
            createEnemyExplosion(
                at: enemy.position,
                damage: 7 + CGFloat(wave) * 0.45
            )
        }

        if source == .scattergun, sourceTier >= 4 {
            createFriendlyBurst(
                at: enemy.position,
                damage: 6 + effectiveWeaponPower * 0.18,
                radius: 42,
                color: .gameCoral
            )
        }
        if source == .clusterPod, sourceTier >= 4 {
            createFriendlyBurst(
                at: enemy.position,
                damage: 8 + effectiveEngineering * 0.22,
                radius: 48,
                color: .gameYellow
            )
        }
        if source == .cuttingHalo, sourceTier >= 3 {
            cuttingHaloKillBonus = min(0.50, cuttingHaloKillBonus + 0.01)
        }
        if source == .prismNeedle, sourceTier >= 4, wasMarked {
            for index in weapons.indices where weapons[index].type == .prismNeedle {
                weapons[index].cooldown = 0
            }
        }

        let rewardValue = max(1, enemy.reward)
        let pickup = PickupNode(value: rewardValue)
        pickup.position = enemy.position
        pickup.setScale(0.1)
        worldLayer.addChild(pickup)
        pickup.run(.sequence([
            .scale(to: enemy.archetype.isBoss ? 2 : 1.25, duration: 0.09),
            .scale(to: enemy.archetype.isBoss ? 1.35 : 1, duration: 0.13)
        ]))

        let deathPosition = enemy.position
        let archetype = enemy.archetype
        let affix = enemy.eliteAffix
        burst(
            at: deathPosition,
            color: enemyColor(enemy),
            count: enemy.archetype.isBoss ? 18 : (enemy.isElite ? 12 : 7)
        )
        enemy.removeFromParent()

        if archetype == .splitter, waveRemaining > 0 {
            _ = spawnEnemy(archetype: .runner, near: deathPosition, countsBudget: false)
            _ = spawnEnemy(archetype: .runner, near: deathPosition, countsBudget: false)
        }
        if affix == .proliferating, waveRemaining > 0 {
            _ = spawnEnemy(archetype: archetype, near: deathPosition, countsBudget: false)
            _ = spawnEnemy(archetype: archetype, near: deathPosition, countsBudget: false)
        }

        if wave == 20, archetype.isBoss {
            waveRemaining = 0
        }
    }

    private func spawnSplitProjectiles(at position: CGPoint, color: SKColor) {
        for index in 0..<3 {
            let angle = CGFloat(index) / 3 * .pi * 2
            let direction = CGVector(dx: cos(angle), dy: sin(angle))
            let projectile = ProjectileNode(
                damage: max(1, (8 + stats.weaponPower * 0.3) * 0.30),
                velocity: direction * 520,
                weaponType: .pulseCannon,
                pierce: 1,
                lifetime: 0.9,
                sizeScale: 0.8
            )
            projectile.fillColor = color
            projectile.position = position
            worldLayer.addChild(projectile)
        }
    }

    private func createFriendlyBurst(
        at position: CGPoint,
        damage: CGFloat,
        radius: CGFloat,
        color: SKColor
    ) {
        showExplosion(at: position, radius: radius, color: color)
        for enemy in enemies where enemy.parent != nil {
            guard (enemy.position - position).length <= radius + enemy.radius else { continue }
            if enemy.takeDamage(damage) {
                defeat(enemy, source: nil, wasCritical: false)
            }
        }
    }

    private func createEnemyExplosion(at position: CGPoint, damage: CGFloat) {
        showExplosion(at: position, radius: 58, color: .gameCoral)
        if (player.position - position).length < 78 {
            _ = receivePlayerDamage(damage, attacker: nil)
        }
    }

    private func randomSpawnPosition(radius: CGFloat) -> CGPoint {
        let edge = Int.random(in: 0..<4)
        let padding = radius + 15
        switch edge {
        case 0:
            return CGPoint(x: CGFloat.random(in: 0...size.width), y: -padding)
        case 1:
            return CGPoint(x: size.width + padding, y: CGFloat.random(in: 0...size.height))
        case 2:
            return CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + padding)
        default:
            return CGPoint(x: -padding, y: CGFloat.random(in: 0...size.height))
        }
    }

    private func collect(_ pickup: PickupNode) {
        let base = pickup.value
        let cacheBonus = min(base, recoveryCache)
        recoveryCache -= cacheBonus
        let currencyBase = base + cacheBonus
        let arenaMultiplier = selectedArena.rewardMultiplier
        let corruptionMultiplier = effectiveCorruptionRewardMultiplier
        let gained = max(
            1,
            Int(
                CGFloat(currencyBase)
                    * stats.currencyMultiplier
                    * arenaMultiplier
                    * corruptionMultiplier
            )
        )
        scrap += gained
        runScore += gained
        metrics.score = runScore
        metrics.maxHeldScrap = max(metrics.maxHeldScrap, scrap)
        metrics.maxCorruption = max(metrics.maxCorruption, stats.corruption)
        addExperience(base)
        if weaponTier(for: .rivetRepeater) >= 3 {
            rivetPickupStacks = min(10, rivetPickupStacks + 1)
        }
        if weaponTier(for: .miningLaser) >= 4 {
            miningPickupProgress += base
            while miningPickupProgress >= 20 {
                miningPickupProgress -= 20
                performMiningSweep()
            }
        }
        pickup.removeFromParent()
        animatePickup(at: player.position)
        SoundManager.shared.play(.pickup)
    }

    private func performMiningSweep() {
        let beam = SKShapeNode(
            rectOf: CGSize(width: size.width + 80, height: 8),
            cornerRadius: 4
        )
        beam.fillColor = .gameYellow.withAlphaComponent(0.45)
        beam.strokeColor = .gameCyan
        beam.glowWidth = 8
        beam.position = CGPoint(x: size.width / 2, y: player.position.y)
        beam.zPosition = 28
        worldLayer.addChild(beam)
        beam.run(.sequence([
            .fadeOut(withDuration: 0.22),
            .removeFromParent()
        ]))

        let damage = 18 + effectiveEngineering * 0.45 + effectiveErosion * 0.30
        for enemy in enemies where abs(enemy.position.y - player.position.y) < 44 {
            if enemy.takeDamage(damage) {
                defeat(enemy, source: .miningLaser, wasCritical: false)
            }
        }
        showToast("采矿激光：星屑横扫", color: .gameYellow)
    }

    // MARK: - Experience and upgrades

    private func addExperience(_ amount: Int) {
        experience += max(0, amount)
        while experience >= experienceToNextLevel {
            experience -= experienceToNextLevel
            level += 1
            pendingLevelUps += 1
            experienceToNextLevel = experienceRequirement(for: level + 1)
        }
    }

    private func experienceRequirement(for targetLevel: Int) -> Int {
        let n = CGFloat(max(1, targetLevel - 1))
        let cumulative = 8 * n + 2.2 * n * n
        let previousN = max(0, n - 1)
        let previous = 8 * previousN + 2.2 * previousN * previousN
        return max(8, Int((cumulative - previous).rounded()))
    }

    private func presentLevelUp() {
        phase = .levelUp
        clearOverlay()
        hud.isHidden = true
        generateUpgradeChoices()

        let panel = makeOverlayPanel()
        overlay = panel

        let title = makeLabel("等级提升 · Lv.\(level)", size: 29, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.84)
        panel.addChild(title)

        let subtitle = makeLabel(
            pendingLevelUps > 1 ? "还有 \(pendingLevelUps) 次强化待选择" : "选择一项永久作用于本局的属性",
            size: 11,
            color: .gamePurple,
            font: "AvenirNext-DemiBold"
        )
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.79)
        panel.addChild(subtitle)

        let cardWidth = min(344, size.width - 40)
        for (index, choice) in upgradeChoices.enumerated() {
            let card = UpgradeCardNode(choice: choice, index: index, width: cardWidth)
            card.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.65 - CGFloat(index) * 112
            )
            panel.addChild(card)
        }
    }

    private func generateUpgradeChoices() {
        var used: Set<Upgrade> = []
        upgradeChoices = []
        while upgradeChoices.count < 4 {
            guard let upgrade = Upgrade.allCases.filter({ !used.contains($0) }).randomElement() else {
                break
            }
            used.insert(upgrade)
            upgradeChoices.append(
                UpgradeChoice(upgrade: upgrade, rarity: rollUpgradeRarity())
            )
        }
    }

    private func rollUpgradeRarity() -> UpgradeRarity {
        let guaranteed: UpgradeRarity?
        switch level {
        case 5: guaranteed = .refined
        case 10, 15: guaranteed = .rare
        case 20: guaranteed = .legendary
        default: guaranteed = nil
        }

        let luck = max(-50, min(200, effectiveLuck))
        let shift = luck / 25 * 0.05
        let roll = CGFloat.random(in: 0...1)
        let legendaryChance = min(0.22, 0.01 + shift * 0.25)
        let rareChance = min(0.42, 0.08 + shift * 0.55)
        let refinedChance = min(0.65, 0.30 + shift)
        let rolled: UpgradeRarity
        if roll < legendaryChance {
            rolled = .legendary
        } else if roll < legendaryChance + rareChance {
            rolled = .rare
        } else if roll < legendaryChance + rareChance + refinedChance {
            rolled = .refined
        } else {
            rolled = .common
        }
        guard let guaranteed else { return rolled }
        return rolled.rawValue < guaranteed.rawValue ? guaranteed : rolled
    }

    private func chooseUpgrade(at index: Int) {
        guard upgradeChoices.indices.contains(index) else { return }
        let choice = upgradeChoices[index]
        let appliedRarity: UpgradeRarity
        if selectedHero == .oneArmed {
            appliedRarity = UpgradeRarity(
                rawValue: min(
                    UpgradeRarity.legendary.rawValue,
                    choice.rarity.rawValue + 1
                )
            ) ?? .legendary
        } else {
            appliedRarity = choice.rarity
        }
        choice.upgrade.apply(to: &stats, rarity: appliedRarity)

        if runEffects.has(.duplicateUpgrade),
           [5, 10, 15].contains(level) {
            choice.upgrade.apply(to: &stats, rarity: appliedRarity)
        }

        pendingLevelUps = max(0, pendingLevelUps - 1)
        impact(.medium)
        showToast("\(choice.title) · \(appliedRarity.title)", color: appliedRarity.color)

        if pendingLevelUps > 0 {
            presentLevelUp()
        } else {
            presentShop()
        }
    }

    // MARK: - Wave end and shop

    private func finishWave() {
        guard phase == .playing, !waveFinishing else { return }
        waveFinishing = true
        activeTouch = nil
        joystick.end()
        let survivingEnemyCount = enemies.count

        if runEffects.has(.summonDeathBurst) {
            let effectCount = runEffects[.summonDeathBurst]
            for deployable in deployables {
                applyHealing(2 * effectCount)
                createFriendlyBurst(
                    at: deployable.position,
                    damage: 10 + stats.engineering * 0.35,
                    radius: 52,
                    color: .gameGreen
                )
            }
        }

        let uncollected = pickups.reduce(0) { $0 + $1.value }
        if runEffects.has(.orbitalRecovery) {
            let immediate = Int(CGFloat(uncollected) * runEffects[.orbitalRecovery])
            scrap += immediate
            runScore += immediate
            recoveryCache += (uncollected - immediate) * 2
        } else {
            recoveryCache += uncollected
        }

        pickups.forEach { $0.removeFromParent() }
        enemies.forEach { $0.removeFromParent() }
        projectiles.forEach { $0.removeFromParent() }
        hostileProjectiles.forEach { $0.removeFromParent() }
        deployables.forEach { $0.removeFromParent() }

        if !tookDamageThisWave {
            let bonus = 4 + wave
            scrap += bonus
            runScore += bonus
            metrics.flawlessWaves += 1
        }

        if selectedHero == .broker {
            let interest = min(18, (scrap / 25) * 3)
            scrap += interest
            runScore += interest
        }
        if selectedHero == .pacifist {
            let survivalIncome = min(
                30,
                Int((CGFloat(survivingEnemyCount) * 0.15).rounded(.down))
            )
            scrap += survivalIncome
            runScore += survivalIncome
        }

        let interestCap = Int(runEffects[.interestCap])
        if interestCap > 0 {
            scrap += min(interestCap, scrap / 30)
        }
        scrap += effectiveHarvesting
        runScore += effectiveHarvesting

        if runEffects.has(.cleanseGrowth),
           stats.corruption > 0,
           selectedHero != .matriarch {
            let cleansed = min(stats.corruption, runEffects[.cleanseGrowth])
            stats.corruption -= cleansed
            metrics.cleansedCorruption += cleansed
            if selectedHero == .purifier {
                stats.erosion += 1
            }
            if Int(metrics.cleansedCorruption) / 10
                > Int(metrics.cleansedCorruption - cleansed) / 10 {
                stats.maxHealth += 2
                stats.health += 2
            }
            refreshCorruptionConversion()
            refreshCorruptionDerivedHealth()
        }

        metrics.score = runScore
        metrics.maxHeldScrap = max(metrics.maxHeldScrap, scrap)
        metrics.maxWeaponCount = max(metrics.maxWeaponCount, weapons.count)
        metrics.maxTagCount = max(metrics.maxTagCount, maximumTagCount)
        metrics.maxCorruption = max(metrics.maxCorruption, stats.corruption)
        if metrics.kills - waveStartKills < 5 {
            saveStore.mutate { $0.lowKillWaveCompleted = true }
        }
        checkContractCompletion()

        if wave >= 20 {
            endRun(victory: true)
        } else if pendingLevelUps > 0 {
            presentLevelUp()
        } else {
            presentShop()
        }
    }

    private func checkContractCompletion() {
        guard !contractRewardGranted, contract.isCompleted(metrics: metrics) else { return }
        contractRewardGranted = true
        switch contract {
        case .exterminator:
            stats.globalDamage += 0.08
        case .collector:
            stats.harvesting += 12
        case .titanHunter:
            stats.bossDamage += 0.15
        case .untouched:
            stats.armor += 3
        case .sixWeapons:
            stats.attackSpeed += 0.12
        case .specialist:
            stats.globalDamage += 0.08
        case .redline:
            stats.maxHealth += 15
            stats.health += 15
            stats.globalDamage += 0.10
        case .embargo:
            if let item = ItemCatalog.rare.randomElement() {
                grantItem(item, paid: false)
            }
        case .corruptionStudy:
            stats.erosion += 12
        case .purification:
            stats.healingEfficiency += 0.20
        case .mobility:
            stats.movementSpeed *= 1.10
            stats.dodgeChance += 0.05
        case .recycling:
            stats.shopDiscount += 0.08
        }
        stats.clamp()
        showToast("合同完成：\(contract.title)", color: .gameYellow)
    }

    private func presentShop() {
        phase = .shop
        clearOverlay()
        hud.isHidden = true
        rerollsThisShop = 0
        purchasesThisShop = 0
        shopLuckBonus = 0

        if runEffects.has(.anvil), anvilAppliedWave != wave {
            anvilAppliedWave = wave
            if let index = weapons.indices.filter({ weapons[$0].level < 4 }).randomElement() {
                weapons[index].level += 1
                refreshWeaponSynergies()
                showToast("原型铁砧升级了 \(weapons[index].type.title)", color: .gameYellow)
            }
        }

        generateShopOffers(preservingLocks: true)
        renderShop()
    }

    private func generateShopOffers(preservingLocks: Bool) {
        let slotCount = runEffects.has(.monopoly) ? 2 : 4
        let existing = shopOffers
        var generated: [ShopOffer?] = Array(repeating: nil, count: slotCount)

        if preservingLocks {
            for index in 0..<min(existing.count, slotCount) {
                if let offer = existing[index], offer.isLocked {
                    generated[index] = offer
                }
            }
        }

        let weaponGuarantee: Int
        if wave <= 2 {
            weaponGuarantee = 2
        } else if wave <= 5 {
            weaponGuarantee = 1
        } else {
            weaponGuarantee = 0
        }

        var generatedWeapons = generated.compactMap { offer -> WeaponType? in
            guard case .weapon(let weapon, _) = offer?.kind else { return nil }
            return weapon
        }

        for index in 0..<slotCount where generated[index] == nil {
            let needsWeapon = generatedWeapons.count < weaponGuarantee
                && index < weaponGuarantee
            let makeWeapon = needsWeapon || CGFloat.random(in: 0...1) < 0.30
            if makeWeapon {
                let weapon = rollShopWeapon()
                let tier = rollWeaponTier()
                let price = weaponPrice(weapon, tier: tier)
                generated[index] = ShopOffer(kind: .weapon(weapon, tier: tier), price: price)
                generatedWeapons.append(weapon)
            } else if let item = rollShopItem() {
                let price = itemPrice(item)
                generated[index] = ShopOffer(kind: .item(item), price: price)
            } else {
                let weapon = rollShopWeapon()
                generated[index] = ShopOffer(
                    kind: .weapon(weapon, tier: 1),
                    price: weaponPrice(weapon, tier: 1)
                )
            }
        }
        shopOffers = generated
    }

    private func rollShopWeapon() -> WeaponType {
        let ownedTypes = Set(weapons.map(\.type))
        let roll = CGFloat.random(in: 0...1)

        if runEffects.has(.lockedWeaponWeight),
           CGFloat.random(in: 0...1) < runEffects[.lockedWeaponWeight] {
            let lockedWeapons = shopOffers.compactMap { offer -> WeaponType? in
                guard offer?.isLocked == true,
                      case .weapon(let weapon, _) = offer?.kind else { return nil }
                return weapon
            }
            if let weapon = lockedWeapons.randomElement() {
                return weapon
            }
        }

        if !ownedTypes.isEmpty, roll < 0.25, let weapon = ownedTypes.randomElement() {
            return weapon
        }

        let ownedTags = Set(weapons.flatMap { $0.type.tags })
        let earlyTagBonus: CGFloat = wave <= 5 ? CGFloat(6 - wave) * 0.03 : 0
        if !ownedTags.isEmpty, roll < 0.45 + earlyTagBonus {
            let pool = WeaponType.allCases.filter { !$0.tags.filter(ownedTags.contains).isEmpty }
            if let weapon = pool.randomElement() { return weapon }
        }

        if CGFloat.random(in: 0...1) < 0.15 {
            let preferred = WeaponType.allCases.filter {
                !$0.tags.filter(selectedHero.preferredTags.contains).isEmpty
            }
            if let weapon = preferred.randomElement() { return weapon }
        }
        return WeaponType.allCases.randomElement() ?? .pulseCannon
    }

    private func rollWeaponTier() -> Int {
        let luckBonus = max(0, effectiveLuck) / 200
        let progress = CGFloat(wave) / 20
        let roll = CGFloat.random(in: 0...1)
        let tier: Int
        if wave >= 12, roll < 0.02 + luckBonus * 0.06 + progress * 0.04 {
            tier = 4
        } else if wave >= 6, roll < 0.12 + luckBonus * 0.12 + progress * 0.10 {
            tier = 3
        } else if wave >= 2, roll < 0.35 + luckBonus * 0.18 + progress * 0.12 {
            tier = 2
        } else {
            tier = 1
        }
        return runEffects.has(.monopoly) ? min(4, tier + 1) : tier
    }

    private func rollShopItem() -> ItemDefinition? {
        let rarity = rollItemRarity()
        let eligible = ItemCatalog.all.filter {
            $0.rarity == rarity
                && inventory.canAdd($0)
                && isItemCompatibleWithHero($0)
        }
        if let preferred = eligible.filter({
            !$0.tags.filter { selectedHero.preferredTags.map(\.title).contains($0) }.isEmpty
        }).randomElement(), CGFloat.random(in: 0...1) < 0.08 {
            return preferred
        }
        return eligible.randomElement()
            ?? ItemCatalog.all.filter {
                inventory.canAdd($0) && isItemCompatibleWithHero($0)
            }.randomElement()
    }

    private func rollItemRarity() -> ItemRarity {
        let probabilities: (CGFloat, CGFloat, CGFloat)
        switch wave {
        case 1...3: probabilities = (0.85, 0.15, 0)
        case 4...7: probabilities = (0.60, 0.35, 0.05)
        case 8...11: probabilities = (0.35, 0.45, 0.18)
        case 12...15: probabilities = (0.20, 0.42, 0.30)
        default: probabilities = (0.10, 0.30, 0.40)
        }

        let shift = max(-0.10, min(0.35, effectiveLuck / 25 * 0.05))
        let common = max(0.02, probabilities.0 - shift)
        let refined = max(0.08, probabilities.1 - shift * 0.20)
        let rare = max(0, probabilities.2 + shift * 0.55)
        let roll = CGFloat.random(in: 0...1)
        if roll < common { return .common }
        if roll < common + refined { return .refined }
        if roll < common + refined + rare { return .rare }
        return .legendary
    }

    private func weaponPrice(_ weapon: WeaponType, tier: Int) -> Int {
        let tierMultiplier: [CGFloat] = [1, 1.7, 2.8, 4.5]
        return max(
            1,
            Int(
                (
                    CGFloat(weapon.basePrice)
                        * (1 + 0.035 * CGFloat(wave - 1))
                        * tierMultiplier[tier - 1]
                        * selectedArena.priceMultiplier
                        * selectedThreat.shopPriceMultiplier
                        * heroWeaponPriceMultiplier(weapon)
                        * (1 - effectiveShopDiscount)
                ).rounded()
            )
        )
    }

    private func itemPrice(_ item: ItemDefinition) -> Int {
        max(
            1,
            Int(
                (
                    CGFloat(item.basePrice)
                        * (1 + 0.035 * CGFloat(wave - 1))
                        * selectedArena.priceMultiplier
                        * selectedThreat.shopPriceMultiplier
                        * heroShopVariance
                        * (1 - effectiveShopDiscount)
                ).rounded()
            )
        )
    }

    private var effectiveShopDiscount: CGFloat {
        var discount = stats.shopDiscount
        if tagCount(.recycling) >= 4 { discount += 0.06 }
        return min(0.40, max(-0.50, discount))
    }

    private func heroWeaponPriceMultiplier(_ weapon: WeaponType) -> CGFloat {
        var multiplier = heroShopVariance
        if selectedHero == .gunslinger, weapon.tags.contains(.ballistic) {
            multiplier *= 0.85
        }
        if selectedHero == .replicator {
            let ownedTypes = Set(weapons.map(\.type))
            if !ownedTypes.isEmpty, !ownedTypes.contains(weapon) {
                multiplier *= 1.25
            }
        }
        return multiplier
    }

    private var heroShopVariance: CGFloat {
        selectedHero == .gambler
            ? CGFloat.random(in: 0.80...1.25)
            : 1
    }

    private func renderShop() {
        clearOverlay()
        let panel = makeOverlayPanel()
        overlay = panel

        let completion = makeLabel(
            "第 \(wave) 波完成\(tookDamageThisWave ? "" : " · 无伤奖励")",
            size: 11,
            color: tookDamageThisWave ? .gameCyan : .gameYellow,
            font: "AvenirNext-DemiBold"
        )
        completion.position = CGPoint(x: size.width / 2, y: size.height * 0.925)
        panel.addChild(completion)

        let title = makeLabel("废料商店", size: 27, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.875)
        panel.addChild(title)

        let wallet = makeLabel(
            "◆ \(scrap) · Lv.\(level) · 武器 \(weapons.count)/\(selectedHero.maxWeaponSlots) · ☣\(Int(stats.corruption))",
            size: 12,
            color: .gameCyan,
            font: "AvenirNext-Bold"
        )
        wallet.position = CGPoint(x: size.width / 2, y: size.height * 0.83)
        panel.addChild(wallet)

        let arsenalY = size.height * 0.785
        let spacing = min(48, (size.width - 60) / CGFloat(max(1, selectedHero.maxWeaponSlots)))
        let totalWidth = spacing * CGFloat(max(0, weapons.count - 1))
        for (index, weapon) in weapons.enumerated() {
            let label = makeLabel(
                "\(weapon.type.symbol)\(weapon.level)",
                size: 12,
                color: weapon.type.color,
                font: "AvenirNext-Bold"
            )
            label.name = "sellWeapon_\(index)"
            label.position = CGPoint(
                x: size.width / 2 - totalWidth / 2 + CGFloat(index) * spacing,
                y: arsenalY
            )
            panel.addChild(label)
        }

        let contractStatus = makeLabel(
            "合同 · \(contract.title) \(contract.progress(metrics: metrics))\(contractRewardGranted ? " ✓" : "")",
            size: 9.5,
            color: .gameYellow.withAlphaComponent(0.85),
            font: "AvenirNext-DemiBold"
        )
        contractStatus.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        panel.addChild(contractStatus)

        let cardWidth = min(344, size.width - 40)
        let cardStart = size.height * 0.665
        let cardSpacing: CGFloat = runEffects.has(.monopoly) ? 112 : 96
        for index in shopOffers.indices {
            guard let offer = shopOffers[index] else { continue }
            var displayedOffer = offer
            displayedOffer.price = effectiveOfferPrice(offer)
            let card = ShopCardNode(
                offer: displayedOffer,
                index: index,
                width: cardWidth,
                canAfford: scrap >= displayedOffer.price && canPurchase(offer)
            )
            card.setScale(runEffects.has(.monopoly) ? 1 : 0.92)
            card.position = CGPoint(
                x: size.width / 2,
                y: cardStart - CGFloat(index) * cardSpacing
            )
            panel.addChild(card)
        }

        let reroll = MenuButtonNode(
            title: "重掷商品 ◆ \(currentRerollCost)",
            name: "rerollButton",
            width: min(210, size.width - 130),
            color: scrap >= currentRerollCost ? .gameCream : .gameBorder
        )
        reroll.position = CGPoint(x: size.width / 2, y: size.height * 0.16)
        reroll.setScale(0.78)
        panel.addChild(reroll)

        let next = MenuButtonNode(
            title: "进入第 \(wave + 1) 波",
            name: "nextWaveButton",
            width: min(278, size.width - 70),
            color: .gameYellow
        )
        next.position = CGPoint(x: size.width / 2, y: size.height * 0.075)
        next.setScale(0.88)
        panel.addChild(next)
    }

    private var currentRerollCost: Int {
        if rerollsThisShop == 0,
           saveStore.data.permanentScavenging >= 10 {
            return 0
        }
        let base = 3 + wave / 3
        let growth = pow(1.55, Double(rerollsThisShop))
        var raw = CGFloat(Double(base) * growth)
        if rerollsThisShop == 0 {
            raw *= 1 - min(0.9, runEffects[.freeFirstReroll])
        }
        return max(
            0,
            Int((raw * (1 - stats.rerollDiscount)).rounded(.up))
        )
    }

    private func canPurchase(_ offer: ShopOffer) -> Bool {
        switch offer.kind {
        case .item(let item):
            return inventory.canAdd(item) && isItemCompatibleWithHero(item)
        case .weapon(let weapon, let tier):
            return canAcceptWeapon(weapon, tier: tier)
        }
    }

    private func isItemCompatibleWithHero(_ item: ItemDefinition) -> Bool {
        if selectedHero == .matriarch, item.tags.contains("净化") {
            return false
        }
        return true
    }

    private func canAcceptWeapon(_ weapon: WeaponType, tier: Int) -> Bool {
        if selectedHero == .replicator {
            let types = Set(weapons.map(\.type))
            if types.count >= 2, !types.contains(weapon) { return false }
        }
        if weapons.count < selectedHero.maxWeaponSlots { return true }
        return canCombineAfterAdding(weapon, tier: tier)
    }

    private func canCombineAfterAdding(_ weapon: WeaponType, tier: Int) -> Bool {
        guard tier < 4 else { return false }
        return weapons.contains { $0.type == weapon && $0.level == tier }
    }

    private func buyShopOffer(at index: Int) {
        guard shopOffers.indices.contains(index),
              let offer = shopOffers[index] else { return }
        let price = effectiveOfferPrice(offer)
        guard scrap >= price else {
            showToast("星屑不足", color: .gameCoral)
            return
        }
        guard canPurchase(offer) else {
            showToast("武器槽或持有上限已满", color: .gameCoral)
            return
        }

        switch offer.kind {
        case .weapon(let weapon, let tier):
            purchaseWeapon(weapon, tier: tier)
            showToast("获得 \(weapon.title) \(String(repeating: "◆", count: tier))", color: weapon.color)
        case .item(let item):
            grantItem(item, paid: true)
            showToast("获得 \(item.title)", color: item.color)
        }

        scrap -= price
        purchasesThisShop += 1
        shopOffers[index] = nil
        impact(.light)
        SoundManager.shared.play(.purchase)
        renderShop()
    }

    private func purchaseWeapon(_ weapon: WeaponType, tier: Int) {
        weapons.append(WeaponRuntime(type: weapon, level: tier))
        if weapons.count > selectedHero.maxWeaponSlots {
            combineWeaponsToMakeRoom(type: weapon, preferredTier: tier)
        }
        refreshWeaponSynergies()
    }

    private func combineWeaponsToMakeRoom(type: WeaponType, preferredTier: Int) {
        var tier = preferredTier
        while weapons.count > selectedHero.maxWeaponSlots, tier < 4 {
            let matches = weapons.indices.filter {
                weapons[$0].type == type && weapons[$0].level == tier
            }
            guard matches.count >= 2 else {
                tier += 1
                continue
            }
            let first = matches[0]
            let second = matches[1]
            let cooldown = min(weapons[first].cooldown, weapons[second].cooldown)
            for index in [first, second].sorted(by: >) {
                weapons.remove(at: index)
            }
            weapons.append(WeaponRuntime(type: type, level: tier + 1, cooldown: cooldown))
            tier += 1
        }
    }

    private func grantItem(_ item: ItemDefinition, paid: Bool) {
        guard inventory.canAdd(item) else { return }
        let oldCorruption = stats.corruption
        inventory.add(item)
        item.apply(to: &stats, runEffects: &runEffects)
        if paid, runEffects.has(.purchaseCorruption), !runEffects.has(.zeroAntibody) {
            stats.corruption += runEffects[.purchaseCorruption]
        }
        if selectedHero == .matriarch, stats.corruption < oldCorruption {
            stats.corruption = oldCorruption
        }
        if stats.corruption < oldCorruption {
            metrics.cleansedCorruption += oldCorruption - stats.corruption
            if selectedHero == .purifier {
                stats.erosion += 1
            }
        }
        refreshCorruptionConversion()
        refreshCorruptionDerivedHealth()
        metrics.maxCorruption = max(metrics.maxCorruption, stats.corruption)
        stats.clamp()
    }

    private func toggleShopLock(at index: Int) {
        guard shopOffers.indices.contains(index), shopOffers[index] != nil else { return }
        shopOffers[index]?.isLocked.toggle()
        renderShop()
    }

    private func sellWeapon(at index: Int) {
        guard weapons.indices.contains(index), weapons.count > 1 else {
            showToast("至少保留一把武器", color: .gameCoral)
            return
        }
        let weapon = weapons.remove(at: index)
        let value = Int(
            CGFloat(weapon.type.basePrice)
                * [1, 1.7, 2.8, 4.5][weapon.level - 1]
                * stats.recycleRefund
        )
        scrap += value
        metrics.recycledOffers += 1
        refreshWeaponSynergies()
        showToast("回收 \(weapon.type.title) +\(value)", color: .gameCyan)
        renderShop()
    }

    private func rerollShop() {
        let cost = currentRerollCost
        guard scrap >= cost else {
            showToast("星屑不足", color: .gameCoral)
            return
        }
        let gamblerFree = selectedHero == .gambler
            && CGFloat.random(in: 0...1) < 0.15
        if !gamblerFree {
            scrap -= cost
        } else {
            showToast("赌徒直觉：本次重掷免费", color: .gameYellow)
        }
        rerollsThisShop += 1
        saveStore.mutate { $0.totalRerolls += 1 }
        if runEffects.has(.rerollLuck) {
            shopLuckBonus += runEffects[.rerollLuck]
        }
        generateShopOffers(preservingLocks: true)
        renderShop()
    }

    private func continueFromShop() {
        if purchasesThisShop == 0 {
            metrics.skippedShopPurchases += 1
        } else {
            metrics.skippedShopPurchases = 0
        }
        shopLuckBonus = 0
        clearOverlay()
        wave += 1
        startWave()
    }

    // MARK: - Synergies

    private func tagCount(_ tag: WeaponTag) -> Int {
        weapons.reduce(0) { count, weapon in
            count + (weapon.type.tags.contains(tag) ? 1 : 0)
        }
    }

    private var uniqueEquippedTagCount: Int {
        Set(weapons.flatMap { $0.type.tags }).count
    }

    private var maximumTagCount: Int {
        WeaponTag.allCases.map(tagCount).max() ?? 0
    }

    private var effectiveLuck: CGFloat {
        var value = stats.luck + shopLuckBonus
        if runEffects.has(.pickupEconomy) {
            value += floor(stats.pickupRange / 100) * 3
        }
        return value
    }

    private var effectiveHarvesting: Int {
        var value = stats.harvesting
        if tagCount(.recycling) >= 2 {
            value += 6
        }
        if runEffects.has(.pickupEconomy) {
            value += Int(floor(stats.pickupRange / 100)) * 4
        }
        return value
    }

    private func effectiveOfferPrice(_ offer: ShopOffer) -> Int {
        guard purchasesThisShop == 0, tagCount(.recycling) >= 6 else {
            return offer.price
        }
        return max(1, Int((CGFloat(offer.price) * 0.65).rounded(.up)))
    }

    private func refreshCorruptionConversion() {
        let desired: CGFloat
        if runEffects.has(.corruptionToErosion) {
            desired = floor(stats.corruption / 10)
                * runEffects[.corruptionToErosion]
        } else {
            desired = 0
        }
        stats.erosion += desired - appliedCorruptionErosion
        appliedCorruptionErosion = desired
    }

    private var effectiveCorruptionStage: Int {
        let value = stats.corruption + (selectedHero == .purifier ? 10 : 0)
        return switch value {
        case ..<25: 0
        case ..<50: 1
        case ..<75: 2
        case ..<100: 3
        default: 4
        }
    }

    private var effectiveCorruptionRewardMultiplier: CGFloat {
        switch effectiveCorruptionStage {
        case 1: 1.05
        case 2: 1.12
        case 3, 4: 1.22
        default: 1
        }
    }

    private func refreshCorruptionDerivedHealth() {
        let desiredPenalty: CGFloat = effectiveCorruptionStage >= 4 ? -20 : 0
        let desiredMatriarch: CGFloat = selectedHero == .matriarch
            ? floor(stats.corruption / 10) * 2
            : 0
        let delta = desiredPenalty - appliedCorruptionHealthPenalty
            + desiredMatriarch - appliedMatriarchHealth
        stats.maxHealth += delta
        if delta > 0 {
            stats.health += delta
        }
        appliedCorruptionHealthPenalty = desiredPenalty
        appliedMatriarchHealth = desiredMatriarch
        stats.clamp()
    }

    private func grantArchivistMilestoneIfNeeded() {
        guard selectedHero == .archivist,
              wave.isMultiple(of: 5),
              !archivistMilestones.contains(wave) else { return }
        archivistMilestones.insert(wave)

        let traitName: String
        switch Int.random(in: 0..<6) {
        case 0:
            stats.globalDamage += 0.08
            traitName = "拓荒者火力"
        case 1:
            stats.maxHealth += 12
            stats.health += 12
            traitName = "堡垒体魄"
        case 2:
            stats.engineering += 7
            traitName = "机巧协议"
        case 3:
            stats.critChance += 0.06
            traitName = "赌徒直觉"
        case 4:
            stats.dodgeChance += 0.05
            traitName = "收割步法"
        default:
            stats.harvesting += 8
            traitName = "经纪回收"
        }
        stats.clamp()
        showToast("档案特性：\(traitName)", color: .gamePurple)
    }

    private func refreshWeaponSynergies() {
        let desiredHealth: CGFloat = tagCount(.primal) >= 2 ? 10 : 0
        let delta = desiredHealth - appliedPrimalHealth
        if delta != 0 {
            stats.maxHealth += delta
            stats.health += max(0, delta)
            appliedPrimalHealth = desiredHealth
        }
        if tagCount(.ballistic) >= 6 {
            stats.weaponPower = max(stats.weaponPower, 0)
        }
        metrics.maxWeaponCount = max(metrics.maxWeaponCount, weapons.count)
        metrics.maxTagCount = max(metrics.maxTagCount, maximumTagCount)
        stats.clamp()
    }

    // MARK: - Pause and ending

    private func presentPause() {
        guard phase == .playing else { return }
        phase = .paused
        activeTouch = nil
        joystick.end()

        let panel = makeOverlayPanel()
        overlay = panel

        let title = makeLabel("战术暂停", size: 34, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        panel.addChild(title)

        let summary = makeLabel(
            "\(selectedHero.title) · \(selectedArena.title) · \(selectedThreat.title)",
            size: 12,
            color: selectedHero.color,
            font: "AvenirNext-DemiBold"
        )
        summary.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        panel.addChild(summary)

        let statLines = [
            "生命 \(Int(stats.health))/\(Int(stats.maxHealth))  护盾 \(Int(stats.shield))  护甲 \(Int(stats.armor))",
            "伤害 +\(Int(stats.globalDamage * 100))%  攻速 +\(Int(effectiveAttackSpeed * 100))%  暴击 \(Int(stats.critChance * 100))%",
            "武装 \(Int(stats.weaponPower))  工程 \(Int(stats.engineering))  侵蚀 \(Int(stats.erosion))",
            "偷取 \(Int(stats.lifeSteal * 100))%  闪避 \(Int(stats.dodgeChance * 100))%  幸运 \(Int(effectiveLuck))",
            "霉化 \(Int(stats.corruption))  回收 \(effectiveHarvesting)  缓存 \(recoveryCache)",
            "合同 \(contract.title) · \(contract.progress(metrics: metrics))"
        ]
        for (index, line) in statLines.enumerated() {
            let label = makeLabel(
                line,
                size: 11,
                color: .white.withAlphaComponent(0.66),
                font: "AvenirNext-Medium"
            )
            label.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.64 - CGFloat(index) * 30
            )
            panel.addChild(label)
        }

        let weaponText = weapons.map {
            "\($0.type.symbol)\($0.level)"
        }.joined(separator: "  ")
        let arsenal = makeLabel(
            weaponText,
            size: 13,
            color: .gameYellow,
            font: "AvenirNext-Bold"
        )
        arsenal.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        panel.addChild(arsenal)

        let resume = MenuButtonNode(
            title: "继续战斗",
            name: "resumeButton",
            width: min(280, size.width - 70),
            color: .gameCyan
        )
        resume.position = CGPoint(x: size.width / 2, y: size.height * 0.30)
        panel.addChild(resume)

        let restart = makeTextButton("放弃并重新选择", name: "restartButton")
        restart.position = CGPoint(x: size.width / 2, y: size.height * 0.20)
        panel.addChild(restart)
    }

    private func resumeGame() {
        clearOverlay()
        phase = .playing
        lastUpdateTime = 0
    }

    private func endRun(victory: Bool) {
        guard !runEnded else { return }
        runEnded = true
        phase = victory ? .victory : .gameOver
        activeTouch = nil
        joystick.end()
        hud.isHidden = true
        interfaceLayer.childNode(withName: "waveBanner")?.removeFromParent()

        let oldSave = saveStore.data
        let reachedWave = victory ? 20 : wave
        var earnedCores = CGFloat(reachedWave) * 0.7
            + CGFloat(metrics.kills) * 0.012
            + CGFloat(metrics.bosses) * 3
        if contractRewardGranted {
            earnedCores += CGFloat(contract.reward)
        }
        if victory {
            earnedCores += 18
        }
        earnedCores *= selectedArena.rewardMultiplier * selectedThreat.coreMultiplier
        if victory, runEffects.has(.finalBossKey) {
            earnedCores *= 1.25
        } else if !victory, runEffects.has(.finalBossKey) {
            earnedCores *= 0.80
        }
        let finalCores = max(1, Int(earnedCores.rounded(.down)))

        saveStore.mutate { save in
            save.totalCores += finalCores
            save.lifetimeKills += metrics.kills
            save.highWave = max(save.highWave, reachedWave)
            save.highScore = max(save.highScore, runScore)
            save.runs += 1
            save.maxHeldScrap = max(save.maxHeldScrap, metrics.maxHeldScrap)
            save.maxCorruption = max(save.maxCorruption, metrics.maxCorruption)
            save.maxExplosionKills = max(save.maxExplosionKills, metrics.maxExplosionKills)
            save.totalBurnStacks += metrics.totalBurnStacks
            if victory {
                save.victories += 1
                save.victoriesByHero[selectedHero.rawValue, default: 0] += 1
                save.victoriesByArena[selectedArena.rawValue, default: 0] += 1
                save.highestThreatByArena[selectedArena.rawValue] = max(
                    save.highestThreatByArena[selectedArena.rawValue, default: -1],
                    selectedThreat.rawValue
                )
                if weapons.count >= 6, Set(weapons.map(\.type)).count == 1 {
                    save.sameWeaponVictory = true
                }
            }
        }

        let newUnlocks = unlockedNames(before: oldSave, after: saveStore.data)
        let panel = makeOverlayPanel()
        overlay = panel

        let eyebrow = makeLabel(
            victory ? "ORBITAL CANNON ONLINE" : "SIGNAL LOST",
            size: 11,
            color: victory ? .gameCyan : .gameCoral,
            font: "AvenirNext-DemiBold"
        )
        eyebrow.position = CGPoint(x: size.width / 2, y: size.height * 0.83)
        panel.addChild(eyebrow)

        let title = makeLabel(
            victory ? "轨道防线重启" : "本次突围结束",
            size: victory ? 31 : 35,
            color: .gameCream
        )
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.77)
        panel.addChild(title)

        let resultPanel = SKShapeNode(
            rectOf: CGSize(width: min(326, size.width - 48), height: 220),
            cornerRadius: 19
        )
        resultPanel.fillColor = .gamePanel
        resultPanel.strokeColor = victory ? .gameCyan : .gameBorder
        resultPanel.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        panel.addChild(resultPanel)

        let results = [
            ("抵达波次", "\(reachedWave)", SKColor.gameYellow),
            ("击败敌人", "\(metrics.kills)", SKColor.gameCoral),
            ("累计星屑", "\(runScore)", SKColor.gameCyan),
            ("获得星核", "+\(finalCores)", SKColor.gameGreen),
            ("最终等级", "\(level)", SKColor.gamePurple),
            ("霉化峰值", "\(Int(metrics.maxCorruption))", SKColor.gamePink)
        ]
        for (index, result) in results.enumerated() {
            let column = index % 2
            let row = index / 2
            let x = CGFloat(column == 0 ? -77 : 77)
            let y = CGFloat(70 - row * 70)

            let label = makeLabel(
                result.0,
                size: 9,
                color: .white.withAlphaComponent(0.48),
                font: "AvenirNext-Medium"
            )
            label.position = CGPoint(x: x, y: y + 14)
            resultPanel.addChild(label)

            let value = makeLabel(result.1, size: 22, color: result.2)
            value.position = CGPoint(x: x, y: y - 10)
            resultPanel.addChild(value)
        }

        var progressMessages: [String] = []
        if contractRewardGranted {
            progressMessages.append("合同完成：\(contract.title)")
        }
        if !newUnlocks.isEmpty {
            progressMessages.append("新解锁：\(newUnlocks.joined(separator: "、"))")
        }
        if !progressMessages.isEmpty {
            let unlock = makeParagraph(
                progressMessages.joined(separator: "   "),
                size: 11,
                color: .gameYellow,
                width: min(310, size.width - 60)
            )
            unlock.position = CGPoint(x: size.width / 2, y: size.height * 0.40)
            panel.addChild(unlock)
        }

        let retry = MenuButtonNode(
            title: "同配置再战",
            name: "retryButton",
            width: min(282, size.width - 70)
        )
        retry.position = CGPoint(x: size.width / 2, y: size.height * 0.29)
        panel.addChild(retry)

        let home = makeTextButton("返回基地", name: "homeButton")
        home.position = CGPoint(x: size.width / 2, y: size.height * 0.20)
        panel.addChild(home)

        impact(victory ? .heavy : .medium)
        SoundManager.shared.play(victory ? .victory : .gameOver)
    }

    private func unlockedNames(
        before: GameSaveData,
        after: GameSaveData
    ) -> [String] {
        var names: [String] = []
        for hero in HeroType.allCases
        where !hero.isUnlocked(in: before) && hero.isUnlocked(in: after) {
            names.append(hero.title)
        }
        for arena in ArenaType.allCases
        where !arena.isUnlocked(in: before) && arena.isUnlocked(in: after) {
            names.append(arena.title)
        }
        return names
    }

    // MARK: - UI helpers

    private func makeOverlayPanel(opacity: CGFloat = 0.95) -> SKNode {
        clearOverlay()
        let panel = SKNode()
        panel.zPosition = 200
        interfaceLayer.addChild(panel)

        let shade = SKSpriteNode(
            color: .gameBackground.withAlphaComponent(opacity),
            size: size
        )
        shade.anchorPoint = .zero
        shade.zPosition = -1
        panel.addChild(shade)
        return panel
    }

    private func clearOverlay() {
        overlay?.removeFromParent()
        overlay = nil
    }

    private func clearWorldEntities() {
        worldLayer.children
            .filter { $0 !== player }
            .forEach { $0.removeFromParent() }
    }

    private func clearCombatants() {
        enemies.forEach { $0.removeFromParent() }
        projectiles.forEach { $0.removeFromParent() }
        hostileProjectiles.forEach { $0.removeFromParent() }
        pickups.forEach { $0.removeFromParent() }
        deployables.forEach { $0.removeFromParent() }
    }

    private func updateHUD() {
        let bossHealth = enemies.first(where: { $0.archetype.isBoss })?.healthRatio
        hud.update(
            health: stats.health,
            maxHealth: stats.maxHealth,
            shield: stats.shield,
            wave: wave,
            remainingTime: waveRemaining,
            score: scrap,
            level: level,
            experience: experience,
            nextExperience: experienceToNextLevel,
            corruption: stats.corruption,
            isClearing: waveRemaining <= 0,
            bossHealth: bossHealth
        )
    }

    private var enemies: [EnemyNode] {
        worldLayer.children.compactMap { $0 as? EnemyNode }
    }

    private var projectiles: [ProjectileNode] {
        worldLayer.children.compactMap { $0 as? ProjectileNode }
    }

    private var hostileProjectiles: [HostileProjectileNode] {
        worldLayer.children.compactMap { $0 as? HostileProjectileNode }
    }

    private var pickups: [PickupNode] {
        worldLayer.children.compactMap { $0 as? PickupNode }
    }

    private var hazards: [HazardNode] {
        worldLayer.children.compactMap { $0 as? HazardNode }
    }

    private var arenaProps: [ArenaPropNode] {
        worldLayer.children.compactMap { $0 as? ArenaPropNode }
    }

    private var purificationFlowers: [PurificationFlowerNode] {
        worldLayer.children.compactMap { $0 as? PurificationFlowerNode }
    }

    private var deployables: [DeployableNode] {
        worldLayer.children.compactMap { $0 as? DeployableNode }
    }

    private func nearestEnemy(
        from position: CGPoint,
        excluding identities: Set<ObjectIdentifier> = []
    ) -> EnemyNode? {
        enemies
            .filter { !identities.contains(ObjectIdentifier($0)) && !$0.isPhased }
            .min {
                ($0.position - position).length < ($1.position - position).length
            }
    }

    private func enemyColor(_ enemy: EnemyNode) -> SKColor {
        if let affix = enemy.eliteAffix { return affix.color }
        return switch enemy.archetype {
        case .crawler, .phaser: .gamePurple
        case .runner, .parasite, .breeder: .gameGreen
        case .brute, .bomber, .mortar: .gameCoral
        case .spitter, .sniper: .gameCyan
        case .splitter: .gamePink
        case .juggernaut, .shielder: .gameBlue
        case .charger, .absorber, .mimic, .boss: .gameYellow
        }
    }

    private var bossName: String {
        switch selectedArena {
        case .scrapOrbit: "货运吞噬者"
        case .crystalHollows: "回声晶母"
        case .emberFoundry: "炉心监工"
        case .fungalDepths: "菌床母巢"
        case .driftingPrison: "零重力典狱长"
        case .seventhDock: "霉潮母体"
        }
    }

    private func makeLabel(
        _ text: String,
        size fontSize: CGFloat,
        color: SKColor,
        font: String = "AvenirNext-Bold"
    ) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: font)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }

    private func makeParagraph(
        _ text: String,
        size fontSize: CGFloat,
        color: SKColor,
        width: CGFloat
    ) -> SKLabelNode {
        let label = makeLabel(
            text,
            size: fontSize,
            color: color,
            font: "AvenirNext-Medium"
        )
        label.preferredMaxLayoutWidth = width
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }

    private func makeTextButton(_ text: String, name: String) -> SKLabelNode {
        let label = makeLabel(
            text,
            size: 15,
            color: .white.withAlphaComponent(0.62),
            font: "AvenirNext-DemiBold"
        )
        label.name = name
        return label
    }

    private func addPager(
        to panel: SKNode,
        page: Int,
        pageCount: Int,
        y: CGFloat,
        previousName: String,
        nextName: String
    ) {
        let previous = MenuButtonNode(
            title: "‹",
            name: previousName,
            width: 64,
            color: page > 0 ? .gameCyan : .gameBorder
        )
        previous.position = CGPoint(x: size.width / 2 - 86, y: y)
        previous.setScale(0.68)
        panel.addChild(previous)

        let indicator = makeLabel(
            "\(page + 1) / \(pageCount)",
            size: 12,
            color: .gameCream,
            font: "AvenirNext-DemiBold"
        )
        indicator.position = CGPoint(x: size.width / 2, y: y)
        panel.addChild(indicator)

        let next = MenuButtonNode(
            title: "›",
            name: nextName,
            width: 64,
            color: page < pageCount - 1 ? .gameCyan : .gameBorder
        )
        next.position = CGPoint(x: size.width / 2 + 86, y: y)
        next.setScale(0.68)
        panel.addChild(next)
    }

    private func contractSymbol(_ contract: RunContract) -> String {
        switch contract {
        case .exterminator: "✦"
        case .collector: "◆"
        case .titanHunter: "♛"
        case .untouched: "◌"
        case .sixWeapons: "Ⅵ"
        case .specialist: "⌬"
        case .redline: "!"
        case .embargo: "×"
        case .corruptionStudy: "☣"
        case .purification: "♧"
        case .mobility: "➤"
        case .recycling: "↺"
        }
    }

    private func showToast(_ text: String, color: SKColor) {
        interfaceLayer.childNode(withName: "toast")?.removeFromParent()

        let toast = SKShapeNode(
            rectOf: CGSize(width: min(300, size.width - 64), height: 42),
            cornerRadius: 14
        )
        toast.name = "toast"
        toast.fillColor = .gamePanel
        toast.strokeColor = color
        toast.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        toast.zPosition = 500
        interfaceLayer.addChild(toast)

        let label = makeLabel(
            text,
            size: 12,
            color: color,
            font: "AvenirNext-DemiBold"
        )
        toast.addChild(label)
        toast.run(.sequence([
            .wait(forDuration: 0.85),
            .group([
                .moveBy(x: 0, y: 16, duration: 0.25),
                .fadeOut(withDuration: 0.25)
            ]),
            .removeFromParent()
        ]))
    }

    private func showDamageNumber(
        _ damage: CGFloat,
        at position: CGPoint,
        color: SKColor,
        isCritical: Bool = false
    ) {
        guard settings.damageNumbers else { return }
        let label = makeLabel(
            isCritical ? "✦\(Int(ceil(damage)))" : "\(Int(ceil(damage)))",
            size: isCritical ? 17 : 13,
            color: color,
            font: "AvenirNext-Bold"
        )
        label.position = CGPoint(x: position.x, y: position.y + 26)
        label.zPosition = 80
        worldLayer.addChild(label)
        label.run(.sequence([
            .group([
                .moveBy(x: CGFloat.random(in: -8...8), y: 28, duration: 0.42),
                .fadeOut(withDuration: 0.42)
            ]),
            .removeFromParent()
        ]))
    }

    private func showFloatingText(_ text: String, at position: CGPoint, color: SKColor) {
        let label = makeLabel(text, size: 14, color: color)
        label.position = CGPoint(x: position.x, y: position.y + 32)
        label.zPosition = 80
        worldLayer.addChild(label)
        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 24, duration: 0.38),
                .fadeOut(withDuration: 0.38)
            ]),
            .removeFromParent()
        ]))
    }

    private func burst(at position: CGPoint, color: SKColor, count: Int) {
        let adjustedCount = settings.reducedEffects ? max(3, count / 2) : count
        for index in 0..<adjustedCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 30
            worldLayer.addChild(particle)

            let angle = CGFloat(index) / CGFloat(adjustedCount) * .pi * 2
                + CGFloat.random(in: -0.18...0.18)
            let distance = CGFloat.random(in: 20...(adjustedCount > 10 ? 76 : 44))
            particle.run(.sequence([
                .group([
                    .moveBy(
                        x: cos(angle) * distance,
                        y: sin(angle) * distance,
                        duration: 0.3
                    ),
                    .fadeOut(withDuration: 0.3),
                    .scale(to: 0.2, duration: 0.3)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func animatePickup(at position: CGPoint) {
        guard !settings.reducedEffects else { return }
        let ring = SKShapeNode(circleOfRadius: 7)
        ring.fillColor = .clear
        ring.strokeColor = .gameCyan
        ring.lineWidth = 2
        ring.glowWidth = 4
        ring.position = position
        ring.zPosition = 45
        worldLayer.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 2.6, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ]),
            .removeFromParent()
        ]))
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settings.haptics else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func actionName(at location: CGPoint) -> String? {
        for node in nodes(at: location) {
            var candidate: SKNode? = node
            while let current = candidate, current !== self {
                if let name = current.name {
                    let prefixes = [
                        "character_", "arena_", "threat_", "contract_",
                        "permanent_", "shopOffer_", "lockOffer_", "sellWeapon_",
                        "upgrade_", "setting_", "compendiumItem_"
                    ]
                    if prefixes.contains(where: { name.hasPrefix($0) })
                        || name.hasSuffix("Button") {
                        return name
                    }
                }
                candidate = current.parent
            }
        }
        return nil
    }

    // MARK: - Touch routing

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let action = actionName(at: location)

        switch phase {
        case .title:
            switch action {
            case "startButton": presentHeroSelection()
            case "hangarButton": presentHangar()
            case "archivesButton": presentArchives()
            case "compendiumButton": presentCompendium()
            case "settingsButton": presentSettings()
            default: break
            }

        case .heroSelect:
            if action == "backButton" {
                presentTitle()
            } else if action == "heroPreviousButton", heroPage > 0 {
                heroPage -= 1
                presentHeroSelection()
            } else if action == "heroNextButton", heroPage < 1 {
                heroPage += 1
                presentHeroSelection()
            } else if let action,
                      action.hasPrefix("character_"),
                      let hero = HeroType(
                        rawValue: action.replacingOccurrences(of: "character_", with: "")
                      ),
                      hero.isUnlocked(in: saveStore.data) {
                selectedHero = hero
                arenaPage = 0
                presentArenaSelection()
            }

        case .arenaSelect:
            if action == "backButton" {
                presentHeroSelection()
            } else if action == "arenaPreviousButton", arenaPage > 0 {
                arenaPage -= 1
                presentArenaSelection()
            } else if action == "arenaNextButton", arenaPage < 1 {
                arenaPage += 1
                presentArenaSelection()
            } else if let action,
                      action.hasPrefix("arena_"),
                      let arena = ArenaType(
                        rawValue: action.replacingOccurrences(of: "arena_", with: "")
                      ),
                      arena.isUnlocked(in: saveStore.data) {
                selectedArena = arena
                presentThreatSelection()
            }

        case .threatSelect:
            if action == "backButton" {
                presentArenaSelection()
            } else if let action,
                      action.hasPrefix("threat_"),
                      let value = Int(action.replacingOccurrences(of: "threat_", with: "")),
                      let threat = ThreatLevel(rawValue: value),
                      saveStore.data.isThreatUnlocked(threat, for: selectedArena) {
                selectedThreat = threat
                contractChoices = Array(RunContract.allCases.shuffled().prefix(3))
                presentContractSelection()
            }

        case .contractSelect:
            if action == "backButton" {
                presentThreatSelection()
            } else if let action,
                      action.hasPrefix("contract_"),
                      let selected = RunContract(
                        rawValue: action.replacingOccurrences(of: "contract_", with: "")
                      ) {
                contract = selected
                startNewRun()
            }

        case .playing:
            if action == "pauseButton" {
                presentPause()
                return
            }
            activeTouch = touch
            joystick.begin(at: location)

        case .levelUp:
            if let action,
               action.hasPrefix("upgrade_"),
               let index = Int(action.replacingOccurrences(of: "upgrade_", with: "")) {
                chooseUpgrade(at: index)
            }

        case .shop:
            if action == "rerollButton" {
                rerollShop()
            } else if action == "nextWaveButton" {
                continueFromShop()
            } else if let action,
                      action.hasPrefix("lockOffer_"),
                      let index = Int(action.replacingOccurrences(of: "lockOffer_", with: "")) {
                toggleShopLock(at: index)
            } else if let action,
                      action.hasPrefix("sellWeapon_"),
                      let index = Int(action.replacingOccurrences(of: "sellWeapon_", with: "")) {
                sellWeapon(at: index)
            } else if let action,
                      action.hasPrefix("shopOffer_"),
                      let index = Int(action.replacingOccurrences(of: "shopOffer_", with: "")) {
                buyShopOffer(at: index)
            }

        case .hangar:
            if action == "backButton" {
                presentTitle()
            } else if let action,
                      action.hasPrefix("permanent_"),
                      let track = PermanentTrack(
                        rawValue: action.replacingOccurrences(of: "permanent_", with: "")
                      ) {
                buyPermanent(track)
            }

        case .archives:
            if action == "backButton" {
                presentTitle()
            }

        case .compendium:
            let maxPage = Int(ceil(Double(ItemCatalog.all.count) / 6.0)) - 1
            if action == "backButton" {
                presentTitle()
            } else if action == "compendiumPreviousButton", compendiumPage > 0 {
                compendiumPage -= 1
                presentCompendium()
            } else if action == "compendiumNextButton", compendiumPage < maxPage {
                compendiumPage += 1
                presentCompendium()
            }

        case .settings:
            if action == "backButton" {
                settings.save()
                presentTitle()
            } else {
                changeSetting(action)
            }

        case .paused:
            if action == "resumeButton" {
                resumeGame()
            } else if action == "restartButton" {
                presentHeroSelection()
            }

        case .gameOver, .victory:
            if action == "retryButton" {
                startNewRun()
            } else if action == "homeButton" {
                presentTitle()
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard phase == .playing,
              let touch = touches.first,
              touch === activeTouch else { return }
        joystick.move(to: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch === activeTouch else { return }
        activeTouch = nil
        joystick.end()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouch = nil
        joystick.end()
    }

    private func changeSetting(_ action: String?) {
        switch action {
        case "setting_haptics":
            settings.haptics.toggle()
        case "setting_shake":
            settings.screenShake.toggle()
        case "setting_numbers":
            settings.damageNumbers.toggle()
        case "setting_effects":
            settings.reducedEffects.toggle()
        case "setting_health":
            settings.enemyHealthScale = nextAccessibilityScale(settings.enemyHealthScale)
        case "setting_damage":
            settings.enemyDamageScale = nextAccessibilityScale(settings.enemyDamageScale)
        case "setting_speed":
            settings.enemySpeedScale = nextAccessibilityScale(settings.enemySpeedScale)
        default:
            return
        }
        settings.save()
        presentSettings()
    }

    private func nextAccessibilityScale(_ current: CGFloat) -> CGFloat {
        let values: [CGFloat] = [0.5, 0.75, 1, 1.25, 1.5, 2]
        guard let index = values.firstIndex(where: { abs($0 - current) < 0.01 }) else {
            return 1
        }
        return values[(index + 1) % values.count]
    }
}
