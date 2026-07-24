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

    private var phase: GamePhase = .title
    private var stats = PlayerStats()
    private var selectedHero: HeroType = .pioneer
    private var selectedArena: ArenaType = .scrapOrbit
    private var contract: RunContract = .collector
    private var weapons: [WeaponRuntime] = []
    private var shopOffers: [ShopOffer?] = []

    private var wave = 1
    private var scrap = 0
    private var runScore = 0
    private var defeatedEnemies = 0
    private var defeatedBosses = 0
    private var flawlessWaves = 0
    private var rerollsThisShop = 0
    private var waveRemaining: TimeInterval = 0
    private var spawnCountdown: TimeInterval = 0
    private var damageCooldown: TimeInterval = 0
    private var hazardDamageCooldown: TimeInterval = 0
    private var regenerationAccumulator: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var activeTouch: UITouch?
    private var overlay: SKNode?
    private var runEnded = false
    private var tookDamageThisWave = false
    private var isConfigured = false

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

    private func configureDebugRouteIfNeeded() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let marker = arguments.firstIndex(of: "-DebugRoute"),
              arguments.indices.contains(marker + 1) else { return }
        let route = arguments[marker + 1]

        run(.sequence([
            .wait(forDuration: 0.25),
            .run { [weak self] in
                guard let self else { return }
                switch route {
                case "heroes":
                    self.presentHeroSelection()
                case "arenas":
                    self.selectedHero = .pioneer
                    self.presentArenaSelection()
                case "hangar":
                    self.presentHangar()
                case "archives":
                    self.presentArchives()
                case "combat":
                    self.selectedHero = .pioneer
                    self.selectedArena = .scrapOrbit
                    self.startNewRun()
                case "shop":
                    self.selectedHero = .engineer
                    self.selectedArena = .crystalHollows
                    self.startNewRun()
                    self.wave = 4
                    self.scrap = 140
                    self.runScore = 220
                    self.clearCombatants()
                    self.presentShop()
                case "boss":
                    self.selectedHero = .stormcaller
                    self.selectedArena = .emberFoundry
                    self.startNewRun()
                    self.wave = 5
                    self.clearCombatants()
                    self.startWave()
                case "stress":
                    self.selectedHero = .engineer
                    self.selectedArena = .emberFoundry
                    self.startNewRun()
                    self.wave = 15
                    self.stats.damage *= 3.4
                    self.stats.fireInterval *= 0.68
                    self.stats.projectileCount = 2
                    self.weapons = Array(WeaponType.allCases.prefix(6)).map {
                        WeaponRuntime(type: $0, level: 3)
                    }
                    self.clearCombatants()
                    self.startWave()
                case "victory":
                    self.selectedHero = .pioneer
                    self.selectedArena = .scrapOrbit
                    self.startNewRun()
                    self.wave = 20
                    self.defeatedEnemies = 438
                    self.defeatedBosses = 4
                    self.flawlessWaves = 5
                    self.runScore = 860
                    self.scrap = 126
                    self.endRun(victory: true)
                default:
                    break
                }
            }
        ]))
        #endif
    }

    private func clearCombatants() {
        worldLayer.children
            .filter {
                $0 is EnemyNode
                    || $0 is ProjectileNode
                    || $0 is HostileProjectileNode
                    || $0 is PickupNode
            }
            .forEach { $0.removeFromParent() }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard isConfigured else { return }
        drawBackground()
        layoutInterface()
    }

    private func layoutInterface() {
        hud.layout(for: size)
    }

    private func drawBackground() {
        backgroundLayer.removeAllChildren()

        let arena = selectedArena
        let backdropColor: SKColor
        switch arena {
        case .scrapOrbit:
            backdropColor = .gameBackground
        case .crystalHollows:
            backdropColor = SKColor(red: 0.035, green: 0.09, blue: 0.135, alpha: 1)
        case .emberFoundry:
            backdropColor = SKColor(red: 0.12, green: 0.05, blue: 0.055, alpha: 1)
        }

        let backdrop = SKSpriteNode(color: backdropColor, size: size)
        backdrop.anchorPoint = .zero
        backgroundLayer.addChild(backdrop)

        let gridPath = CGMutablePath()
        let spacing: CGFloat = 52
        var x: CGFloat = 0
        while x <= size.width {
            gridPath.move(to: CGPoint(x: x, y: 0))
            gridPath.addLine(to: CGPoint(x: x, y: size.height))
            x += spacing
        }
        var y: CGFloat = 0
        while y <= size.height {
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }

        let grid = SKShapeNode(path: gridPath)
        grid.strokeColor = arena.color.withAlphaComponent(0.11)
        grid.lineWidth = 1
        backgroundLayer.addChild(grid)

        for index in 0..<26 {
            let decoration: SKShapeNode
            let radius = index.isMultiple(of: 5) ? CGFloat(2) : CGFloat(1.2)

            if arena == .crystalHollows, index.isMultiple(of: 4) {
                let diamond = CGMutablePath()
                diamond.move(to: CGPoint(x: 0, y: radius * 4))
                diamond.addLine(to: CGPoint(x: radius * 2.5, y: 0))
                diamond.addLine(to: CGPoint(x: 0, y: -radius * 4))
                diamond.addLine(to: CGPoint(x: -radius * 2.5, y: 0))
                diamond.closeSubpath()
                decoration = SKShapeNode(path: diamond)
            } else {
                decoration = SKShapeNode(circleOfRadius: radius)
            }

            decoration.fillColor = arena.color.withAlphaComponent(
                index.isMultiple(of: 4) ? 0.3 : 0.13
            )
            decoration.strokeColor = .clear
            let xSeed = CGFloat((index * 83 + 29) % 101) / 101
            let ySeed = CGFloat((index * 47 + 17) % 103) / 103
            decoration.position = CGPoint(x: xSeed * size.width, y: ySeed * size.height)
            decoration.zPosition = 1
            backgroundLayer.addChild(decoration)
        }

        if arena == .emberFoundry {
            for index in 0..<5 {
                let vent = SKShapeNode(
                    rectOf: CGSize(width: 42, height: 4),
                    cornerRadius: 2
                )
                vent.fillColor = .gameCoral.withAlphaComponent(0.18)
                vent.strokeColor = .clear
                vent.position = CGPoint(
                    x: CGFloat((index * 97 + 58) % 330) + 28,
                    y: CGFloat((index * 139 + 80) % 650) + 70
                )
                vent.zRotation = CGFloat(index) * 0.37
                backgroundLayer.addChild(vent)
            }
        }

        let vignette = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        vignette.fillColor = .clear
        vignette.strokeColor = SKColor.black.withAlphaComponent(0.34)
        vignette.lineWidth = 32
        vignette.zPosition = 3
        backgroundLayer.addChild(vignette)
    }

    // MARK: - Frontend

    private func presentTitle() {
        phase = .title
        clearOverlay()
        hud.isHidden = true
        joystick.alpha = 0
        activeTouch = nil
        clearWorldEntities()
        selectedArena = .scrapOrbit
        drawBackground()
        player.isHidden = false

        player.removeAllActions()
        player.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        player.setScale(1.42)
        player.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 7, duration: 0.8),
            .moveBy(x: 0, y: -7, duration: 0.8)
        ])), withKey: "titleFloat")

        let menu = SKNode()
        menu.zPosition = 200
        interfaceLayer.addChild(menu)
        overlay = menu

        let eyebrow = makeLabel(
            "薯星历 417 年 · 最后的轨道防线",
            size: 12,
            color: .gameCyan,
            font: "AvenirNext-DemiBold"
        )
        eyebrow.position = CGPoint(x: size.width / 2, y: size.height * 0.84)
        menu.addChild(eyebrow)

        let title = makeLabel("薯星幸存者", size: 38, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.775)
        menu.addChild(title)

        let subtitle = makeLabel(
            "收集星核，重启轨道炮",
            size: 15,
            color: .white.withAlphaComponent(0.58),
            font: "AvenirNext-Medium"
        )
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.73)
        menu.addChild(subtitle)

        let save = saveStore.data
        let recordPanel = SKShapeNode(
            rectOf: CGSize(width: min(318, size.width - 54), height: 55),
            cornerRadius: 15
        )
        recordPanel.fillColor = .gamePanel.withAlphaComponent(0.82)
        recordPanel.strokeColor = .gameBorder
        recordPanel.position = CGPoint(x: size.width / 2, y: size.height * 0.43)
        menu.addChild(recordPanel)

        let record = makeLabel(
            "◈ 星核 \(save.totalCores)   ·   最高波次 \(save.highWave)   ·   突围 \(save.runs) 次",
            size: 12,
            color: .gameCream,
            font: "AvenirNext-DemiBold"
        )
        recordPanel.addChild(record)

        let start = MenuButtonNode(
            title: "选择战士",
            name: "startButton",
            width: min(286, size.width - 66)
        )
        start.position = CGPoint(x: size.width / 2, y: size.height * 0.325)
        menu.addChild(start)

        let hangar = MenuButtonNode(
            title: "基地强化",
            name: "hangarButton",
            width: min(136, (size.width - 80) / 2),
            color: .gameCyan
        )
        hangar.position = CGPoint(x: size.width / 2 - 74, y: size.height * 0.23)
        hangar.setScale(0.88)
        menu.addChild(hangar)

        let archives = MenuButtonNode(
            title: "世界档案",
            name: "archivesButton",
            width: min(136, (size.width - 80) / 2),
            color: .gamePurple
        )
        archives.position = CGPoint(x: size.width / 2 + 74, y: size.height * 0.23)
        archives.setScale(0.88)
        menu.addChild(archives)

        let footer = makeLabel(
            "20 波战役 · 6 名角色 · 8 类武器",
            size: 10,
            color: .white.withAlphaComponent(0.28),
            font: "AvenirNext-DemiBold"
        )
        footer.position = CGPoint(x: size.width / 2, y: 26)
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
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.88)
        panel.addChild(title)

        let subtitle = makeLabel(
            "每名战士拥有独特初始武器与被动",
            size: 12,
            color: .white.withAlphaComponent(0.56),
            font: "AvenirNext-Medium"
        )
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.835)
        panel.addChild(subtitle)

        let cardWidth = (size.width - 38) / 2
        let cardSize = CGSize(width: cardWidth, height: 112)
        let startY = size.height * 0.71
        let rowSpacing: CGFloat = 126

        for (index, hero) in HeroType.allCases.enumerated() {
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

        let back = makeTextButton("返回基地", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 68)
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
        heroTag.position = CGPoint(x: size.width / 2, y: size.height * 0.9)
        panel.addChild(heroTag)

        let title = makeLabel("选择战区", size: 30, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.84)
        panel.addChild(title)

        let cardWidth = min(344, size.width - 38)
        let cardSize = CGSize(width: cardWidth, height: 128)
        let startY = size.height * 0.66

        for (index, arena) in ArenaType.allCases.enumerated() {
            let unlocked = arena.isUnlocked(in: saveStore.data)
            let card = SelectionCardNode(
                title: arena.title,
                subtitle: arena.subtitle,
                symbol: arena == .scrapOrbit ? "⌬" : (arena == .crystalHollows ? "◇" : "♨"),
                color: arena.color,
                name: "arena_\(arena.rawValue)",
                size: cardSize,
                isLocked: !unlocked,
                footer: arena.unlockText(in: saveStore.data)
            )
            card.position = CGPoint(
                x: size.width / 2,
                y: startY - CGFloat(index) * 146
            )
            panel.addChild(card)
        }

        let back = makeTextButton("重新选择战士", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 70)
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
        eyebrow.position = CGPoint(x: size.width / 2, y: size.height * 0.9)
        panel.addChild(eyebrow)

        let title = makeLabel("基地强化", size: 31, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.84)
        panel.addChild(title)

        let cores = makeLabel(
            "◈ 可用星核 \(saveStore.data.totalCores)",
            size: 16,
            color: .gameYellow,
            font: "AvenirNext-Bold"
        )
        cores.position = CGPoint(x: size.width / 2, y: size.height * 0.77)
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
                isLocked: false,
                footer: rank >= 10 ? "已满级" : "Lv.\(rank)  ·  ◈ \(cost)"
            )
            card.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.62 - CGFloat(index) * 138
            )
            panel.addChild(card)
        }

        let hint = makeParagraph(
            "星核会在每局结束时结算。永久强化作用于所有角色，最高 10 级。",
            size: 12,
            color: .white.withAlphaComponent(0.48),
            width: min(310, size.width - 60)
        )
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        panel.addChild(hint)

        let back = makeTextButton("返回基地", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 68)
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
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.9)
        panel.addChild(title)

        let subtitle = makeLabel(
            "在一次次突围中拼出这颗星球的真相",
            size: 11,
            color: .white.withAlphaComponent(0.5),
            font: "AvenirNext-Medium"
        )
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.855)
        panel.addChild(subtitle)

        let cardWidth = min(342, size.width - 42)
        for (index, entry) in LoreEntry.all.enumerated() {
            let unlocked = index == 0
                || saveStore.data.highWave >= index * 5
                || saveStore.data.totalCores >= index * 25
            let card = SKShapeNode(
                rectOf: CGSize(width: cardWidth, height: 132),
                cornerRadius: 17
            )
            card.fillColor = .gamePanel
            card.strokeColor = unlocked ? entry.color : .gameBorder
            card.alpha = unlocked ? 1 : 0.55
            card.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.72 - CGFloat(index) * 143
            )
            panel.addChild(card)

            let tag = makeLabel(
                unlocked ? entry.subtitle : "档案加密",
                size: 10,
                color: unlocked ? entry.color : .gameCoral,
                font: "AvenirNext-DemiBold"
            )
            tag.horizontalAlignmentMode = .left
            tag.position = CGPoint(x: -cardWidth / 2 + 17, y: 43)
            card.addChild(tag)

            let entryTitle = makeLabel(
                unlocked ? entry.title : "？？？",
                size: 17,
                color: .gameCream
            )
            entryTitle.horizontalAlignmentMode = .left
            entryTitle.position = CGPoint(x: -cardWidth / 2 + 17, y: 18)
            card.addChild(entryTitle)

            let body = makeParagraph(
                unlocked ? entry.body : "继续深入战区，解密这段记录。",
                size: 11,
                color: .white.withAlphaComponent(0.58),
                width: cardWidth - 34
            )
            body.horizontalAlignmentMode = .left
            body.position = CGPoint(x: -cardWidth / 2 + 17, y: -23)
            card.addChild(body)
        }

        let back = makeTextButton("返回基地", name: "backButton")
        back.position = CGPoint(x: size.width / 2, y: 66)
        panel.addChild(back)
    }

    // MARK: - Run setup

    private func startNewRun() {
        phase = .playing
        clearOverlay()
        clearWorldEntities()
        drawBackground()

        stats.reset()
        selectedHero.apply(to: &stats)
        var saveCopy = saveStore.data
        saveCopy.applyPermanentBonuses(to: &stats)

        weapons = [WeaponRuntime(type: selectedHero.startingWeapon, level: 1)]
        wave = 1
        scrap = 12
        runScore = 0
        defeatedEnemies = 0
        defeatedBosses = 0
        flawlessWaves = 0
        contract = RunContract.allCases.randomElement() ?? .collector
        lastUpdateTime = 0
        damageCooldown = 0
        hazardDamageCooldown = 0
        runEnded = false

        player.removeAllActions()
        player.isHidden = false
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        player.zRotation = 0
        player.setScale(1)
        hud.isHidden = false

        setupArena()
        startWave()
    }

    private func setupArena() {
        guard selectedArena == .emberFoundry else { return }
        let hazardPositions = [
            CGPoint(x: size.width * 0.23, y: size.height * 0.3),
            CGPoint(x: size.width * 0.74, y: size.height * 0.48),
            CGPoint(x: size.width * 0.35, y: size.height * 0.73)
        ]
        for (index, position) in hazardPositions.enumerated() {
            let hazard = HazardNode(radius: index == 1 ? 50 : 42, color: .gameCoral)
            hazard.position = position
            worldLayer.addChild(hazard)
        }
    }

    private func startWave() {
        phase = .playing
        hud.isHidden = false
        waveRemaining = min(32, 20 + TimeInterval(wave) * 1.15)
        spawnCountdown = 0.1
        lastUpdateTime = 0
        regenerationAccumulator = 0
        damageCooldown = 0
        tookDamageThisWave = false

        for index in weapons.indices {
            weapons[index].cooldown = Double.random(in: 0...0.25)
        }

        if wave.isMultiple(of: 5) {
            spawnBoss()
        }

        updateHUD()

        interfaceLayer.childNode(withName: "waveBanner")?.removeFromParent()
        let banner = makeLabel(
            wave.isMultiple(of: 5) ? "警告：巨型脉冲" : "第 \(wave) 波",
            size: wave.isMultiple(of: 5) ? 23 : 30,
            color: wave.isMultiple(of: 5) ? .gameCoral : .gameCream
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
        regenerationAccumulator += deltaTime

        if regenerationAccumulator >= 0.25, stats.regeneration > 0 {
            stats.heal(stats.regeneration * CGFloat(regenerationAccumulator))
            regenerationAccumulator = 0
        }

        updateWave(deltaTime)
        movePlayer(deltaTime)
        moveEnemies(deltaTime)
        moveProjectiles(deltaTime)
        moveHostileProjectiles(deltaTime)
        updatePickups(deltaTime)
        updateHazards()
        handleProjectileHits()
        fireWeapons(deltaTime)
        updateHUD()

        if stats.health <= 0 {
            endRun(victory: false)
        }
    }

    private func updateWave(_ deltaTime: TimeInterval) {
        if waveRemaining > 0 {
            waveRemaining = max(0, waveRemaining - deltaTime)
            spawnCountdown -= deltaTime

            if spawnCountdown <= 0 {
                if enemies.count < 135 {
                    spawnEnemy()
                }
                var baseInterval = max(0.22, 0.88 - Double(wave) * 0.038)
                if wave.isMultiple(of: 5) {
                    baseInterval *= 1.28
                }
                spawnCountdown += baseInterval * Double.random(in: 0.72...1.2)
            }
        } else if enemies.isEmpty {
            presentShop()
        }
    }

    private func movePlayer(_ deltaTime: TimeInterval) {
        let movement = joystick.vector * (stats.movementSpeed * CGFloat(deltaTime))
        player.position = player.position + movement
        player.face(direction: joystick.vector)

        let horizontalMargin: CGFloat = 28
        let bottomMargin: CGFloat = 30
        let topMargin: CGFloat = 92
        player.position.x = min(
            size.width - horizontalMargin,
            max(horizontalMargin, player.position.x)
        )
        player.position.y = min(
            size.height - topMargin,
            max(bottomMargin, player.position.y)
        )
    }

    private func moveEnemies(_ deltaTime: TimeInterval) {
        for enemy in enemies where enemy.parent != nil {
            let offset = player.position - enemy.position
            let distance = offset.length
            let direction = offset.normalized
            let arenaSpeed = selectedArena.enemySpeedMultiplier

            if enemy.archetype.isRanged, !enemy.archetype.isBoss, distance < 230 {
                let tangent = CGVector(dx: -direction.dy, dy: direction.dx)
                enemy.position = enemy.position
                    + tangent * (enemy.movementSpeed * arenaSpeed * CGFloat(deltaTime) * 0.42)
            } else {
                enemy.position = enemy.position
                    + direction * (enemy.movementSpeed * arenaSpeed * CGFloat(deltaTime))
            }

            if enemy.archetype.isRanged {
                enemy.attackCooldown -= deltaTime
                if enemy.attackCooldown <= 0 {
                    fireHostileProjectile(from: enemy, direction: direction)
                    enemy.attackCooldown = enemy.archetype.isBoss
                        ? Double.random(in: 0.9...1.3)
                        : Double.random(in: 1.65...2.3)
                }
            }

            if distance < enemy.radius + 23, damageCooldown <= 0 {
                let damage = stats.receiveDamage(enemy.contactDamage)
                damageCooldown = 0.46

                if damage > 0 {
                    tookDamageThisWave = true
                    player.showDamage()
                    showDamageNumber(damage, at: player.position, color: .gameCoral)
                    SoundManager.shared.play(.hit)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                    if stats.thorns > 0, enemy.takeDamage(stats.thorns) {
                        defeat(enemy)
                    }
                } else {
                    showFloatingText("闪避", at: player.position, color: .gameCyan)
                }

                enemy.position = enemy.position + direction * -28
            }
        }
    }

    private func moveProjectiles(_ deltaTime: TimeInterval) {
        let paddedBounds = CGRect(
            x: -50,
            y: -50,
            width: size.width + 100,
            height: size.height + 100
        )
        for projectile in projectiles {
            projectile.position = projectile.position
                + projectile.velocity * CGFloat(deltaTime)
            projectile.lifetime -= deltaTime

            if projectile.lifetime <= 0 || !paddedBounds.contains(projectile.position) {
                projectile.removeFromParent()
            }
        }
    }

    private func moveHostileProjectiles(_ deltaTime: TimeInterval) {
        let paddedBounds = CGRect(
            x: -60,
            y: -60,
            width: size.width + 120,
            height: size.height + 120
        )
        for projectile in hostileProjectiles {
            projectile.position = projectile.position
                + projectile.velocity * CGFloat(deltaTime)
            projectile.lifetime -= deltaTime

            let distance = (player.position - projectile.position).length
            if distance < projectile.hitRadius + 22 {
                let damage = stats.receiveDamage(projectile.damage)
                projectile.removeFromParent()
                if damage > 0 {
                    tookDamageThisWave = true
                    player.showDamage()
                    showDamageNumber(damage, at: player.position, color: .gameCoral)
                    SoundManager.shared.play(.hit)
                } else {
                    showFloatingText("闪避", at: player.position, color: .gameCyan)
                }
            } else if projectile.lifetime <= 0 || !paddedBounds.contains(projectile.position) {
                projectile.removeFromParent()
            }
        }
    }

    private func updatePickups(_ deltaTime: TimeInterval) {
        for pickup in pickups {
            let offset = player.position - pickup.position
            let distance = offset.length

            if distance < stats.pickupRange {
                let attraction = max(140, 500 - distance)
                pickup.position = pickup.position
                    + offset.normalized * (attraction * CGFloat(deltaTime))
            }

            if distance < 27 {
                collect(pickup)
            }
        }
    }

    private func updateHazards() {
        guard selectedArena == .emberFoundry, hazardDamageCooldown <= 0 else { return }

        for hazard in hazards where hazard.isHot {
            let distance = (player.position - hazard.position).length
            if distance < hazard.hazardRadius + 17 {
                let damage = stats.receiveDamage(8 + CGFloat(wave) * 0.65)
                hazardDamageCooldown = 0.7
                if damage > 0 {
                    tookDamageThisWave = true
                    player.showDamage()
                    showDamageNumber(damage, at: player.position, color: .gameCoral)
                }
                break
            }
        }
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
                let wasDefeated = enemy.takeDamage(projectile.damage)
                showDamageNumber(
                    projectile.damage,
                    at: enemy.position,
                    color: projectile.isCritical ? .white : projectile.weaponType.color,
                    isCritical: projectile.isCritical
                )

                if stats.lifeSteal > 0 {
                    stats.heal(min(4, projectile.damage * stats.lifeSteal))
                }

                let knockDirection = (enemy.position - player.position).normalized
                enemy.position = enemy.position
                    + knockDirection * (7 * stats.knockback)

                if wasDefeated {
                    defeat(enemy)
                }

                projectile.pierceRemaining -= 1
                if projectile.pierceRemaining <= 0 {
                    projectile.removeFromParent()
                    break
                }
            }
        }
    }

    private func explode(_ projectile: ProjectileNode, at position: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: projectile.splashRadius)
        ring.fillColor = projectile.weaponType.color.withAlphaComponent(0.2)
        ring.strokeColor = projectile.weaponType.color
        ring.lineWidth = 3
        ring.glowWidth = 7
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

        for enemy in enemies where enemy.parent != nil {
            let distance = (enemy.position - position).length
            guard distance <= projectile.splashRadius + enemy.radius else { continue }
            let falloff = max(0.45, 1 - distance / (projectile.splashRadius * 1.7))
            let damage = projectile.damage * falloff
            if enemy.takeDamage(damage) {
                defeat(enemy)
            }
            showDamageNumber(damage, at: enemy.position, color: projectile.weaponType.color)
        }
    }

    // MARK: - Weapons and enemies

    private func fireWeapons(_ deltaTime: TimeInterval) {
        guard let target = nearestEnemy() else { return }

        for index in weapons.indices {
            weapons[index].cooldown -= deltaTime
            guard weapons[index].cooldown <= 0 else { continue }

            let runtime = weapons[index]
            fire(runtime, toward: target)
            let globalIntervalScale = stats.fireInterval / 0.48
            weapons[index].cooldown += runtime.type.baseInterval
                * Double(runtime.intervalScale)
                * globalIntervalScale
        }
    }

    private func fire(_ runtime: WeaponRuntime, toward target: EnemyNode) {
        let type = runtime.type
        let baseDirection = (target.position - player.position).normalized
        let lowHealthBoost: CGFloat
        if selectedHero == .harvester {
            lowHealthBoost = 1 + (1 - stats.health / stats.maxHealth) * 0.75
        } else {
            lowHealthBoost = 1
        }

        let globalBonusShots = max(0, stats.projectileCount - 1)
        let volley: Int
        if type == .starBlades {
            volley = type.baseVolley + globalBonusShots * 2
        } else {
            volley = type.baseVolley + globalBonusShots
        }

        for shot in 0..<volley {
            let direction: CGVector
            if type == .starBlades {
                let angle = CGFloat(shot) / CGFloat(volley) * .pi * 2
                direction = CGVector(dx: cos(angle), dy: sin(angle))
            } else if volley == 1 {
                direction = baseDirection
            } else {
                let effectiveSpread = type.spread > 0
                    ? type.spread
                    : min(0.34, CGFloat(volley - 1) * 0.1)
                let angle = -effectiveSpread / 2
                    + effectiveSpread * CGFloat(shot) / CGFloat(volley - 1)
                direction = baseDirection.rotated(by: angle)
            }

            let isCritical = CGFloat.random(in: 0...1) < stats.critChance
            var damage = stats.damage
                * type.damageMultiplier
                * runtime.damageScale
                * lowHealthBoost
            if isCritical {
                damage *= stats.critMultiplier
            }

            let speedMultiplier = stats.projectileSpeed / 560
            let projectile = ProjectileNode(
                damage: damage,
                velocity: direction * (type.projectileSpeed * speedMultiplier),
                weaponType: type,
                pierce: type.pierce + max(0, runtime.level - 3),
                splashRadius: type.splashRadius * (1 + CGFloat(runtime.level - 1) * 0.07),
                lifetime: type.projectileLifetime,
                sizeScale: stats.projectileSize * (1 + CGFloat(runtime.level - 1) * 0.03),
                isCritical: isCritical
            )
            projectile.position = player.position + direction * 31
            worldLayer.addChild(projectile)
        }

        player.run(.sequence([
            .scale(to: 0.95, duration: 0.03),
            .scale(to: 1, duration: 0.065)
        ]))
        SoundManager.shared.play(.shoot)
    }

    private func fireHostileProjectile(from enemy: EnemyNode, direction: CGVector) {
        if enemy.archetype.isBoss {
            let count = wave >= 15 ? 12 : 8
            for index in 0..<count {
                let angle = CGFloat(index) / CGFloat(count) * .pi * 2
                let radial = CGVector(dx: cos(angle), dy: sin(angle))
                let shot = HostileProjectileNode(
                    damage: 9 + CGFloat(wave) * 0.7,
                    velocity: radial * 155,
                    isBossShot: true
                )
                shot.position = enemy.position + radial * (enemy.radius + 8)
                worldLayer.addChild(shot)
            }
        } else {
            let shot = HostileProjectileNode(
                damage: 7 + CGFloat(wave) * 0.55,
                velocity: direction * 190
            )
            shot.position = enemy.position + direction * (enemy.radius + 6)
            worldLayer.addChild(shot)
        }
    }

    private func spawnEnemy(
        archetype: EnemyArchetype? = nil,
        near position: CGPoint? = nil
    ) {
        var chosen = archetype
        if chosen == nil,
           selectedArena == .emberFoundry,
           wave >= 3,
           CGFloat.random(in: 0...1) < 0.1 {
            chosen = .juggernaut
        }

        let enemy = EnemyNode(wave: wave, archetype: chosen)
        if let position {
            enemy.position = CGPoint(
                x: position.x + CGFloat.random(in: -22...22),
                y: position.y + CGFloat.random(in: -22...22)
            )
        } else {
            enemy.position = randomSpawnPosition(radius: enemy.radius)
        }
        worldLayer.addChild(enemy)
    }

    private func spawnBoss() {
        let boss = EnemyNode(wave: wave, archetype: .boss)
        boss.position = CGPoint(x: size.width / 2, y: size.height + boss.radius + 20)
        boss.setScale(0.2)
        worldLayer.addChild(boss)
        boss.run(.sequence([
            .scale(to: 1.15, duration: 0.24),
            .scale(to: 1, duration: 0.12)
        ]))
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

    private func defeat(_ enemy: EnemyNode) {
        guard enemy.parent != nil else { return }
        defeatedEnemies += 1

        if enemy.archetype.isBoss {
            defeatedBosses += 1
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            SoundManager.shared.play(.boss)
        }

        let rewardValue = max(
            1,
            Int(CGFloat(enemy.reward) * selectedArena.rewardMultiplier)
        )
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
        burst(
            at: deathPosition,
            color: enemyColor(enemy),
            count: enemy.archetype.isBoss ? 18 : 7
        )
        enemy.removeFromParent()

        if archetype == .splitter, waveRemaining > 0 {
            spawnEnemy(archetype: .runner, near: deathPosition)
            spawnEnemy(archetype: .runner, near: deathPosition)
        }
    }

    private func collect(_ pickup: PickupNode) {
        let gained = max(
            1,
            Int(CGFloat(pickup.value) * stats.currencyMultiplier)
        )
        scrap += gained
        runScore += gained
        pickup.removeFromParent()
        animatePickup(at: player.position)
        SoundManager.shared.play(.pickup)
    }

    private func nearestEnemy() -> EnemyNode? {
        enemies.min {
            ($0.position - player.position).length
                < ($1.position - player.position).length
        }
    }

    private func enemyColor(_ enemy: EnemyNode) -> SKColor {
        switch enemy.archetype {
        case .crawler: .gamePurple
        case .runner: .gameGreen
        case .brute: .gameCoral
        case .spitter: .gameCyan
        case .splitter: .gamePink
        case .juggernaut: .gameBlue
        case .boss: .gameYellow
        }
    }

    // MARK: - Shop and progression

    private func presentShop() {
        guard phase == .playing else { return }

        if wave >= 20 {
            endRun(victory: true)
            return
        }

        phase = .shop
        activeTouch = nil
        joystick.end()
        hud.isHidden = true

        for pickup in pickups {
            collect(pickup)
        }
        projectiles.forEach { $0.removeFromParent() }
        hostileProjectiles.forEach { $0.removeFromParent() }

        if !tookDamageThisWave {
            scrap += 4 + wave
            runScore += 4 + wave
            flawlessWaves += 1
        }

        rerollsThisShop = 0
        generateShopOffers()
        renderShop()
    }

    private func generateShopOffers() {
        let basePrice = 10 + wave * 3
        let weaponCandidates = WeaponType.allCases.filter { weapon in
            if let runtime = weapons.first(where: { $0.type == weapon }) {
                return runtime.level < 5
            }
            return weapons.count < 6
        }

        var generated: [ShopOffer?] = []
        var usedWeapons: Set<WeaponType> = []
        var usedUpgrades: Set<Upgrade> = []
        for index in 0..<3 {
            let weaponChance = min(0.58, 0.36 + stats.luck * 0.2)
            let unusedWeapons = weaponCandidates.filter { !usedWeapons.contains($0) }
            if !unusedWeapons.isEmpty,
               CGFloat.random(in: 0...1) < weaponChance,
               let weapon = unusedWeapons.randomElement() {
                let alreadyOwned = weapons.contains { $0.type == weapon }
                let price = basePrice + (alreadyOwned ? 5 : 11) + index * 2
                generated.append(ShopOffer(kind: .weapon(weapon), price: price))
                usedWeapons.insert(weapon)
            } else if let upgrade = Upgrade.allCases
                .filter({
                    !($0 == .multishot && stats.projectileCount >= 5)
                        && !usedUpgrades.contains($0)
                })
                .randomElement() {
                let price = basePrice + index * 2
                generated.append(ShopOffer(kind: .upgrade(upgrade), price: price))
                usedUpgrades.insert(upgrade)
            }
        }
        while generated.count < 3 {
            generated.append(
                ShopOffer(kind: .upgrade(.damage), price: basePrice)
            )
        }
        shopOffers = generated
    }

    private func renderShop() {
        clearOverlay()
        let panel = makeOverlayPanel()
        overlay = panel

        let completion = makeLabel(
            "第 \(wave) 波完成\(tookDamageThisWave ? "" : " · 无伤奖励")",
            size: 12,
            color: tookDamageThisWave ? .gameCyan : .gameYellow,
            font: "AvenirNext-DemiBold"
        )
        completion.position = CGPoint(x: size.width / 2, y: size.height * 0.9)
        panel.addChild(completion)

        let title = makeLabel("废料商店", size: 30, color: .gameCream)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.84)
        panel.addChild(title)

        let wallet = makeLabel(
            "◆ \(scrap)    ·    武器 \(weapons.count)/6",
            size: 15,
            color: .gameCyan,
            font: "AvenirNext-Bold"
        )
        wallet.position = CGPoint(x: size.width / 2, y: size.height * 0.785)
        panel.addChild(wallet)

        let arsenalText = weapons.map { "\($0.type.symbol)\($0.level)" }.joined(separator: "  ")
        let arsenal = makeLabel(
            arsenalText,
            size: 12,
            color: .white.withAlphaComponent(0.52),
            font: "AvenirNext-DemiBold"
        )
        arsenal.position = CGPoint(x: size.width / 2, y: size.height * 0.745)
        panel.addChild(arsenal)

        let currentContractProgress = contract.progress(
            kills: defeatedEnemies,
            score: runScore,
            bosses: defeatedBosses,
            flawlessWaves: flawlessWaves
        )
        let contractStatus = makeLabel(
            "契约 · \(contract.title)  \(currentContractProgress)",
            size: 10,
            color: .gameYellow.withAlphaComponent(0.8),
            font: "AvenirNext-DemiBold"
        )
        contractStatus.position = CGPoint(x: size.width / 2, y: size.height * 0.705)
        panel.addChild(contractStatus)

        let cardWidth = min(344, size.width - 40)
        for index in shopOffers.indices {
            guard let offer = shopOffers[index] else { continue }
            let card = ShopCardNode(
                offer: offer,
                index: index,
                width: cardWidth,
                canAfford: scrap >= offer.price
            )
            card.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.61 - CGFloat(index) * 107
            )
            panel.addChild(card)
        }

        let rerollCost = currentRerollCost
        let reroll = MenuButtonNode(
            title: "刷新商品  ◆ \(rerollCost)",
            name: "rerollButton",
            width: min(220, size.width - 120),
            color: scrap >= rerollCost ? .gameCream : .gameBorder
        )
        reroll.position = CGPoint(x: size.width / 2, y: size.height * 0.205)
        reroll.setScale(0.82)
        panel.addChild(reroll)

        let next = MenuButtonNode(
            title: "进入第 \(wave + 1) 波",
            name: "nextWaveButton",
            width: min(286, size.width - 66),
            color: .gameYellow
        )
        next.position = CGPoint(x: size.width / 2, y: size.height * 0.105)
        panel.addChild(next)
    }

    private var currentRerollCost: Int {
        5 + wave + rerollsThisShop * 4
    }

    private func buyShopOffer(at index: Int) {
        guard shopOffers.indices.contains(index),
              let offer = shopOffers[index] else { return }
        guard scrap >= offer.price else {
            showToast("碎片不足", color: .gameCoral)
            return
        }

        switch offer.kind {
        case .weapon(let weapon):
            if let existing = weapons.firstIndex(where: { $0.type == weapon }) {
                guard weapons[existing].level < 5 else {
                    showToast("武器已满级", color: .gameCyan)
                    return
                }
                weapons[existing].level += 1
                showToast("\(weapon.title) 升至 Lv.\(weapons[existing].level)", color: weapon.color)
            } else {
                guard weapons.count < 6 else {
                    showToast("武器槽已满", color: .gameCoral)
                    return
                }
                weapons.append(WeaponRuntime(type: weapon, level: 1))
                showToast("获得 \(weapon.title)", color: weapon.color)
            }
        case .upgrade(let upgrade):
            upgrade.apply(to: &stats)
            showToast("获得 \(upgrade.title)", color: upgrade.color)
        }

        scrap -= offer.price
        shopOffers[index] = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        SoundManager.shared.play(.purchase)
        renderShop()
    }

    private func rerollShop() {
        let cost = currentRerollCost
        guard scrap >= cost else {
            showToast("碎片不足", color: .gameCoral)
            return
        }
        scrap -= cost
        rerollsThisShop += 1
        generateShopOffers()
        renderShop()
    }

    private func continueFromShop() {
        clearOverlay()
        wave += 1
        startWave()
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
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        panel.addChild(title)

        let summary = makeLabel(
            "\(selectedHero.title) · \(selectedArena.title) · 第 \(wave) 波",
            size: 13,
            color: selectedHero.color,
            font: "AvenirNext-DemiBold"
        )
        summary.position = CGPoint(x: size.width / 2, y: size.height * 0.66)
        panel.addChild(summary)

        let pauseContractProgress = contract.progress(
            kills: defeatedEnemies,
            score: runScore,
            bosses: defeatedBosses,
            flawlessWaves: flawlessWaves
        )
        let statLines = [
            "伤害 \(Int(stats.damage))   攻速 +\(Int((1 - stats.fireInterval / 0.48) * 100))%",
            "护甲 \(Int(stats.armor))   暴击 \(Int(stats.critChance * 100))%",
            "吸血 \(Int(stats.lifeSteal * 100))%   闪避 \(Int(stats.dodgeChance * 100))%",
            "武器 " + weapons.map { "\($0.type.symbol) Lv.\($0.level)" }.joined(separator: "  "),
            "契约 \(contract.title) · \(pauseContractProgress)"
        ]
        for (index, line) in statLines.enumerated() {
            let label = makeLabel(
                line,
                size: index >= 3 ? 11 : 13,
                color: .white.withAlphaComponent(index >= 3 ? 0.52 : 0.68),
                font: "AvenirNext-Medium"
            )
            label.position = CGPoint(
                x: size.width / 2,
                y: size.height * 0.58 - CGFloat(index) * 31
            )
            panel.addChild(label)
        }

        let resume = MenuButtonNode(
            title: "继续战斗",
            name: "resumeButton",
            width: min(280, size.width - 70),
            color: .gameCyan
        )
        resume.position = CGPoint(x: size.width / 2, y: size.height * 0.35)
        panel.addChild(resume)

        let restart = makeTextButton("放弃并重新选择", name: "restartButton")
        restart.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
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
        var earnedCores = max(
            3,
            reachedWave + defeatedEnemies / 24 + defeatedBosses * 6 + runScore / 90
        )
        let contractCompleted = contract.isCompleted(
            kills: defeatedEnemies,
            score: runScore,
            bosses: defeatedBosses,
            flawlessWaves: flawlessWaves
        )
        if contractCompleted {
            earnedCores += contract.reward
        }
        if victory {
            earnedCores += 28
        }

        saveStore.mutate { save in
            save.totalCores += earnedCores
            save.lifetimeKills += defeatedEnemies
            save.highWave = max(save.highWave, reachedWave)
            save.highScore = max(save.highScore, runScore)
            save.runs += 1
            if victory {
                save.victories += 1
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
        eyebrow.position = CGPoint(x: size.width / 2, y: size.height * 0.79)
        panel.addChild(eyebrow)

        let title = makeLabel(
            victory ? "轨道防线重启" : "本次突围结束",
            size: victory ? 31 : 35,
            color: .gameCream
        )
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        panel.addChild(title)

        let resultPanel = SKShapeNode(
            rectOf: CGSize(width: min(316, size.width - 54), height: 176),
            cornerRadius: 19
        )
        resultPanel.fillColor = .gamePanel
        resultPanel.strokeColor = victory ? .gameCyan : .gameBorder
        resultPanel.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        panel.addChild(resultPanel)

        let results = [
            ("抵达波次", "\(reachedWave)", SKColor.gameYellow),
            ("击败敌人", "\(defeatedEnemies)", SKColor.gameCoral),
            ("累计碎片", "\(runScore)", SKColor.gameCyan),
            ("获得星核", "+\(earnedCores)", SKColor.gameGreen)
        ]
        for (index, result) in results.enumerated() {
            let column = index % 2
            let row = index / 2
            let x = CGFloat(column == 0 ? -74 : 74)
            let y = CGFloat(row == 0 ? 43 : -43)

            let label = makeLabel(
                result.0,
                size: 10,
                color: .white.withAlphaComponent(0.48),
                font: "AvenirNext-Medium"
            )
            label.position = CGPoint(x: x, y: y + 18)
            resultPanel.addChild(label)

            let value = makeLabel(result.1, size: 24, color: result.2)
            value.position = CGPoint(x: x, y: y - 10)
            resultPanel.addChild(value)
        }

        var progressMessages: [String] = []
        if contractCompleted {
            progressMessages.append("契约完成：\(contract.title) +\(contract.reward) 星核")
        }
        if !newUnlocks.isEmpty {
            progressMessages.append("新解锁：\(newUnlocks.joined(separator: "、"))")
        }
        if !progressMessages.isEmpty {
            let unlock = makeParagraph(
                progressMessages.joined(separator: "   "),
                size: 12,
                color: .gameYellow,
                width: min(310, size.width - 60)
            )
            unlock.position = CGPoint(x: size.width / 2, y: size.height * 0.405)
            panel.addChild(unlock)
        }

        let retry = MenuButtonNode(
            title: "再次突围",
            name: "retryButton",
            width: min(282, size.width - 70)
        )
        retry.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        panel.addChild(retry)

        let home = makeTextButton("返回基地", name: "homeButton")
        home.position = CGPoint(x: size.width / 2, y: size.height * 0.205)
        panel.addChild(home)

        UIImpactFeedbackGenerator(style: victory ? .heavy : .medium).impactOccurred()
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

    private func makeOverlayPanel() -> SKNode {
        clearOverlay()
        let panel = SKNode()
        panel.zPosition = 200
        interfaceLayer.addChild(panel)

        let shade = SKSpriteNode(
            color: .gameBackground.withAlphaComponent(0.95),
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

    private func updateHUD() {
        let bossHealth = enemies.first(where: { $0.archetype.isBoss })?.healthRatio
        hud.update(
            health: stats.health,
            maxHealth: stats.maxHealth,
            wave: wave,
            remainingTime: waveRemaining,
            score: scrap,
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

    private func showToast(_ text: String, color: SKColor) {
        interfaceLayer.childNode(withName: "toast")?.removeFromParent()

        let toast = SKShapeNode(
            rectOf: CGSize(width: min(290, size.width - 70), height: 42),
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
            size: 13,
            color: color,
            font: "AvenirNext-DemiBold"
        )
        toast.addChild(label)
        toast.run(.sequence([
            .wait(forDuration: 0.75),
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
        for index in 0..<count {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 30
            worldLayer.addChild(particle)

            let angle = CGFloat(index) / CGFloat(count) * .pi * 2
                + CGFloat.random(in: -0.18...0.18)
            let distance = CGFloat.random(in: 20...(count > 10 ? 76 : 44))
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

    private func actionName(at location: CGPoint) -> String? {
        for node in nodes(at: location) {
            var candidate: SKNode? = node
            while let current = candidate, current !== self {
                if let name = current.name {
                    let prefixes = [
                        "character_", "arena_", "permanent_", "shopOffer_"
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
            if action == "startButton" {
                presentHeroSelection()
            } else if action == "hangarButton" {
                presentHangar()
            } else if action == "archivesButton" {
                presentArchives()
            }

        case .heroSelect:
            if action == "backButton" {
                presentTitle()
            } else if let action,
                      action.hasPrefix("character_"),
                      let hero = HeroType(
                        rawValue: action.replacingOccurrences(of: "character_", with: "")
                      ),
                      hero.isUnlocked(in: saveStore.data) {
                selectedHero = hero
                presentArenaSelection()
            }

        case .arenaSelect:
            if action == "backButton" {
                presentHeroSelection()
            } else if let action,
                      action.hasPrefix("arena_"),
                      let arena = ArenaType(
                        rawValue: action.replacingOccurrences(of: "arena_", with: "")
                      ),
                      arena.isUnlocked(in: saveStore.data) {
                selectedArena = arena
                startNewRun()
            }

        case .playing:
            if action == "pauseButton" {
                presentPause()
                return
            }
            activeTouch = touch
            joystick.begin(at: location)

        case .shop:
            if action == "rerollButton" {
                rerollShop()
            } else if action == "nextWaveButton" {
                continueFromShop()
            } else if let action,
                      action.hasPrefix("shopOffer_"),
                      let index = Int(
                        action.replacingOccurrences(of: "shopOffer_", with: "")
                      ) {
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
}
