import SwiftUI
import Combine

class GameEngine: ObservableObject {
    let arena: ArenaLevel
    // 地圖邏輯尺寸
    let mapWidth: CGFloat = 360
    let mapHeight: CGFloat = 540
    
    // 橋樑與河流座標 (Y: 250...290 為水域)
    let riverYRange: ClosedRange<CGFloat> = 250...290
    var leftBridge: CGPoint
    var rightBridge: CGPoint
    var leftBridgeXRange: ClosedRange<CGFloat>
    var rightBridgeXRange: ClosedRange<CGFloat>
    
    // 遊戲狀態
    @Published var gameStatus: GameStatus = .idle
    @Published var playerElixir: Double = 5.0
    @Published var aiElixir: Double = 5.0
    @Published var units: [GameUnit] = []
    @Published var towers: [Tower] = []
    @Published var damageEffects: [DamageEffect] = []
    @Published var spellExplosions: [SpellExplosionEffect] = []
    @Published var towerHitEffects: [TowerHitEffect] = []
    @Published var projectiles: [Projectile] = [] // 飛行的火球、萬箭齊發、塔箭、砲彈！
    
    // 8 張牌庫輪抽系統
    @Published var playerDeck: [CardType] = []
    @Published var playerHand: [CardType] = []
    @Published var nextCard: CardType? = nil
    
    @Published var aiDeck: [CardType] = []
    @Published var aiHand: [CardType] = []
    
    @Published var selectedCard: CardType? = nil
    @Published var remainingTime: Int = 180
    @Published var playerCrowns: Int = 0
    @Published var aiCrowns: Int = 0
    @Published var statusMessage: String = "點擊「開始對戰」！"
    @Published var elixirMultiplier: Double = 1
    @Published var isElixirAnnouncementVisible = false
    @Published var elixirAnnouncementTitle = ""
    @Published var elixirAnnouncementDetail = ""
    @Published var isOvertime = false
    
    enum GameStatus {
        case idle
        case playing
        case victory
        case defeat
    }
    
    private var timer: AnyCancellable?
    private var lastUpdateTime: Date = Date()
    private var aiNextSpawnTime: Date = Date()
    private var timeCountdownCounter: Double = 0
    private var overtimeDamageEffectCounter: Double = 0
    
    init(level: Int = 1) {
        let currentArena = ArenaLevel.level(level)
        arena = currentArena
        
        let lbX = (currentArena.playerLeftPrincessPos.x + currentArena.aiLeftPrincessPos.x) / 2
        let rbX = (currentArena.playerRightPrincessPos.x + currentArena.aiRightPrincessPos.x) / 2
        leftBridge = CGPoint(x: lbX, y: 270)
        rightBridge = CGPoint(x: rbX, y: 270)
        leftBridgeXRange = (lbX - 25)...(lbX + 25)
        rightBridgeXRange = (rbX - 25)...(rbX + 25)
        
        resetGame()
    }
    
    func resetGame() {
        units.removeAll()
        damageEffects.removeAll()
        spellExplosions.removeAll()
        towerHitEffects.removeAll()
        projectiles.removeAll()
        playerElixir = 5.0
        aiElixir = 5.0
        remainingTime = 180
        playerCrowns = 0
        aiCrowns = 0
        selectedCard = nil
        elixirMultiplier = 1
        isElixirAnnouncementVisible = false
        elixirAnnouncementTitle = ""
        elixirAnnouncementDetail = ""
        isOvertime = false
        overtimeDamageEffectCounter = 0
        gameStatus = .idle
        statusMessage = "準備好了嗎？點擊「開始對戰」"
        
        setupDecks()
        
        let aiTowerHealth = 3052 * arena.aiHealthMultiplier
        let aiKingHealth = 4824 * arena.aiHealthMultiplier
        let aiTowerDamage = 109 * arena.aiDamageMultiplier

        // 六座塔精確安置在圖片上的三個大正方形（兩邊共六個）
        towers = [
            // 玩家方防禦塔 (藍方)
            Tower(faction: .player, isKingTower: false, name: "左側公主塔", position: arena.playerLeftPrincessPos, hp: 3052, maxHp: 3052, atk: 109, range: 140, attackInterval: 0.8, isActivated: true),
            Tower(faction: .player, isKingTower: false, name: "右側公主塔", position: arena.playerRightPrincessPos, hp: 3052, maxHp: 3052, atk: 109, range: 140, attackInterval: 0.8, isActivated: true),
            Tower(faction: .player, isKingTower: true, name: "國王主塔", position: arena.playerKingTowerPos, hp: 4824, maxHp: 4824, atk: 109, range: 155, attackInterval: 1.0, isActivated: false),
            
            // AI方防禦塔 (紅方)
            Tower(faction: .ai, isKingTower: false, name: "左側公主塔", position: arena.aiLeftPrincessPos, hp: aiTowerHealth, maxHp: aiTowerHealth, atk: aiTowerDamage, range: 140, attackInterval: 0.8, isActivated: true),
            Tower(faction: .ai, isKingTower: false, name: "右側公主塔", position: arena.aiRightPrincessPos, hp: aiTowerHealth, maxHp: aiTowerHealth, atk: aiTowerDamage, range: 140, attackInterval: 0.8, isActivated: true),
            Tower(faction: .ai, isKingTower: true, name: "國王主塔", position: arena.aiKingTowerPos, hp: aiKingHealth, maxHp: aiKingHealth, atk: aiTowerDamage, range: 155, attackInterval: 1.0, isActivated: false)
        ]
    }
    
    private func setupDecks() {
        let allCards = CardType.allCases.shuffled()
        playerHand = Array(allCards.prefix(4))
        playerDeck = Array(allCards.suffix(from: 4))
        nextCard = playerDeck.first
        
        let aiAllCards = CardType.allCases.shuffled()
        aiHand = Array(aiAllCards.prefix(4))
        aiDeck = Array(aiAllCards.suffix(from: 4))
    }
    
    func startGame() {
        resetGame()
        gameStatus = .playing
        statusMessage = "對戰開始！選中卡牌點擊出戰"
        lastUpdateTime = Date()
        aiNextSpawnTime = Date().addingTimeInterval(2.2)
        
        timer?.cancel()
        timer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.gameLoop()
            }
    }
    
    // 玩家放置卡牌
    func placeCard(_ card: CardType, at position: CGPoint) -> Bool {
        guard gameStatus == .playing else { return false }
        
        if card.category != .spell && position.y < 260 {
            statusMessage = "⚠️ 部隊只能在己方藍色半場放置！"
            return false
        }
        
        if card.movementType == .ground && riverYRange.contains(position.y) {
            let isOnBridge = leftBridgeXRange.contains(position.x) || rightBridgeXRange.contains(position.x)
            if !isOnBridge {
                statusMessage = "⚠️ 地面部隊無法在水面上直接召喚！"
                return false
            }
        }
        
        guard playerElixir >= Double(card.elixirCost) else {
            statusMessage = "⚡️ 聖水不足！需要 \(card.elixirCost) 點聖水"
            return false
        }
        
        playerElixir -= Double(card.elixirCost)
        
        if card.category == .spell {
            launchSpellProjectile(card: card, faction: .player, targetPos: position)
        } else {
            spawnCardUnits(card: card, faction: .player, basePosition: position)
        }
        
        cyclePlayerCard(playedCard: card)
        selectedCard = nil
        statusMessage = "施放了 \(card.name)！"
        return true
    }
    
    private func cyclePlayerCard(playedCard: CardType) {
        if let index = playerHand.firstIndex(of: playedCard) {
            playerHand.remove(at: index)
            if !playerDeck.isEmpty {
                let drawnCard = playerDeck.removeFirst()
                playerHand.append(drawnCard)
                playerDeck.append(playedCard)
                nextCard = playerDeck.first
            }
        }
    }
    
    // 發射法術飛行投射物 (火球術、萬箭齊發)
    private func launchSpellProjectile(card: CardType, faction: Faction, targetPos: CGPoint) {
        // 發射起點：國王塔位置
        let startPos = (faction == .player) ? arena.playerKingTowerPos : arena.aiKingTowerPos
        let dist = hypot(targetPos.x - startPos.x, targetPos.y - startPos.y)
        let pType: ProjectileType = (card == .fireball) ? .fireball : .arrows
        
        // 飛行速度 (像素/秒)
        let flightSpeed: CGFloat = (card == .fireball) ? 420.0 : 480.0
        
        let proj = Projectile(
            type: pType,
            faction: faction,
            startPosition: startPos,
            targetPosition: targetPos,
            currentPosition: startPos,
            speed: flightSpeed,
            radius: card.aoeRadius,
            damage: card.atk,
            totalDistance: max(1, dist),
            progress: 0.0
        )
        projectiles.append(proj)
    }
    
    // 防禦塔射出投射物 (前面兩座公主塔射弓箭，中間國王塔射小顆砲彈)
    private func launchTowerProjectile(from tower: Tower, to enemy: GameUnit) {
        let pType: ProjectileType = tower.isKingTower ? .towerCannonball : .towerArrow
        let flightSpeed: CGFloat = tower.isKingTower ? 480.0 : 560.0
        let dist = hypot(enemy.position.x - tower.position.x, enemy.position.y - tower.position.y)
        
        let proj = Projectile(
            type: pType,
            faction: tower.faction,
            startPosition: tower.position,
            targetPosition: enemy.position,
            currentPosition: tower.position,
            speed: flightSpeed,
            radius: tower.isKingTower ? 24.0 : 12.0,
            damage: tower.atk,
            totalDistance: max(1, dist),
            progress: 0.0,
            targetUnitId: enemy.id
        )
        projectiles.append(proj)
    }
    
    // 法術著陸爆炸結算
    private func detonateSpell(projectile: Projectile) {
        let targetPos = projectile.targetPosition
        let explosion = SpellExplosionEffect(
            type: projectile.type,
            position: targetPos,
            radius: CGFloat(projectile.radius)
        )
        spellExplosions.append(explosion)
        
        let spellDmg = projectile.damage
        let towerDmg = projectile.damage * 0.3
        let radius = projectile.radius
        
        // 傷害敵方單位
        for i in units.indices {
            if units[i].faction != projectile.faction {
                let dist = hypot(units[i].position.x - targetPos.x, units[i].position.y - targetPos.y)
                if dist <= radius {
                    units[i].hp -= spellDmg
                    addDamageEffect(damage: Int(spellDmg), position: units[i].position, isSpell: true)
                }
            }
        }
        
        // 傷害敵方防禦塔
        for i in towers.indices {
            if towers[i].faction != projectile.faction && !towers[i].isDestroyed {
                let dist = hypot(towers[i].position.x - targetPos.x, towers[i].position.y - targetPos.y)
                if dist <= (radius + 20) {
                    towers[i].hp -= towerDmg
                    addDamageEffect(damage: Int(towerDmg), position: towers[i].position, isSpell: true)
                    if towers[i].isKingTower {
                        towers[i].isActivated = true
                    }
                }
            }
        }
    }
    
    // 防禦塔投射物命中結算 (弓箭 / 砲彈)
    private func detonateTowerProjectile(projectile: Projectile) {
        let targetPos = projectile.targetPosition
        
        // 生成擊中特效
        let hitEffect = TowerHitEffect(
            type: projectile.type,
            position: targetPos
        )
        towerHitEffects.append(hitEffect)
        
        // 如果是砲彈，產生微型爆炸震波特效
        if projectile.type == .towerCannonball {
            let miniExplosion = SpellExplosionEffect(
                type: .fireball,
                position: targetPos,
                radius: 26,
                scale: 0.35,
                opacity: 0.95
            )
            spellExplosions.append(miniExplosion)
        }
        
        // 優先命中鎖定的目標單位 (不播放點擊音效)
        if let targetId = projectile.targetUnitId,
           let unitIdx = units.firstIndex(where: { $0.id == targetId && $0.hp > 0 }) {
            units[unitIdx].hp -= projectile.damage
            addDamageEffect(damage: Int(projectile.damage), position: units[unitIdx].position)
        } else {
            // 若原目標剛好被消滅，命中範圍內最近之敵軍
            if let nearbyIdx = units.firstIndex(where: {
                $0.faction != projectile.faction &&
                $0.hp > 0 &&
                hypot($0.position.x - targetPos.x, $0.position.y - targetPos.y) <= 35
            }) {
                units[nearbyIdx].hp -= projectile.damage
                addDamageEffect(damage: Int(projectile.damage), position: units[nearbyIdx].position)
            }
        }
    }
    
    private func spawnCardUnits(card: CardType, faction: Faction, basePosition: CGPoint) {
        let count = card.spawnCount
        
        let offsets: [(CGFloat, CGFloat)]
        switch count {
        case 4: // 哥布林 4 隻
            offsets = [(-14, -10), (14, -10), (-14, 10), (14, 10)]
        case 2: // 弓箭手 2 隻
            offsets = [(-16, 0), (16, 0)]
        default:
            offsets = [(0, 0)]
        }
        
        for i in 0..<count {
            let offset = offsets[i % offsets.count]
            let pos = CGPoint(
                x: max(20, min(mapWidth - 20, basePosition.x + offset.0)),
                y: max(20, min(mapHeight - 20, basePosition.y + offset.1))
            )
            
            let unit = GameUnit(
                faction: faction,
                cardType: card,
                position: pos,
                hp: card.maxHp * (faction == .ai ? arena.aiHealthMultiplier : 1),
                maxHp: card.maxHp * (faction == .ai ? arena.aiHealthMultiplier : 1),
                atk: card.atk * (faction == .ai ? arena.aiDamageMultiplier : 1),
                range: card.attackRange,
                speed: card.moveSpeed,
                attackInterval: card.attackInterval,
                targetPriority: card.targetPriority,
                movementType: card.movementType,
                canTargetFlyingUnits: card.canTargetFlyingUnits,
                lockedTowerID: nil
            )
            units.append(unit)
        }
    }
    
    private func gameLoop() {
        guard gameStatus == .playing else { return }
        
        let now = Date()
        let deltaTime = min(0.1, now.timeIntervalSince(lastUpdateTime))
        lastUpdateTime = now
        
        // 1. 聖水回復：倒數兩分鐘加倍，最後一分鐘三倍。
        playerElixir = min(10.0, playerElixir + deltaTime * 0.7 * elixirMultiplier)
        aiElixir = min(10.0, aiElixir + deltaTime * arena.aiElixirRate * elixirMultiplier)
        
        // 2. 倒數計時
        timeCountdownCounter += deltaTime
        if timeCountdownCounter >= 1.0 {
            timeCountdownCounter = 0
            if remainingTime > 0 && !isOvertime {
                remainingTime -= 1
                updateElixirPhaseIfNeeded()
                if remainingTime == 0 {
                    endGameByTimeLimit()
                }
            } else if !isOvertime {
                endGameByTimeLimit()
            }
        }
        
        // 3. AI 邏輯
        updateAI(now: now)
        
        // 4. 飛行投射物更新 (火球、萬箭齊發、防禦塔弓箭與砲彈飛越戰場)
        updateProjectiles(deltaTime: deltaTime)
        
        // 5. 單位尋敵、橋樑完整渡河導航與持續戰鬥 (超過本身攻擊範圍的敵人不主動去找)
        updateUnits(deltaTime: deltaTime, now: now)
        
        // 6. 三座防禦塔攻擊邏輯 (前面兩座射弓箭，中間國王塔受傷或公主塔爆裂後射砲彈，帶特效)
        updateTowers(now: now)

        if isOvertime {
            updateOvertimeTowerDrain(deltaTime: deltaTime)
        }
        
        // 7. 清理與勝負檢查
        cleanUpAndCheckVictory()
        
        // 8. 傷害特效與爆炸波
        updateDamageEffects(deltaTime: deltaTime)
        updateSpellExplosions(deltaTime: deltaTime)
        updateTowerHitEffects(deltaTime: deltaTime)
    }

    private func updateElixirPhaseIfNeeded() {
        let newMultiplier: Double
        let title: String
        let detail: String

        if remainingTime <= 60 {
            newMultiplier = 3
            title = "⚡️ 三倍聖水 ⚡️"
            detail = "最後一分鐘，聖水回復速度三倍！"
        } else if remainingTime <= 120 {
            newMultiplier = 2
            title = "⚡️ 雙倍聖水 ⚡️"
            detail = "倒數兩分鐘，聖水回復速度加倍！"
        } else {
            return
        }

        guard newMultiplier > elixirMultiplier else { return }
        elixirMultiplier = newMultiplier
        elixirAnnouncementTitle = title
        elixirAnnouncementDetail = detail
        isElixirAnnouncementVisible = true
        statusMessage = detail

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.isElixirAnnouncementVisible = false
        }
    }

    private func updateOvertimeTowerDrain(deltaTime: Double) {
        let enemyDrainPerSecond = 650.0
        let playerDrainPerSecond = 300.0
        overtimeDamageEffectCounter += deltaTime

        for index in towers.indices where !towers[index].isDestroyed {
            let drain = (towers[index].faction == .ai ? enemyDrainPerSecond : playerDrainPerSecond) * deltaTime
            withAnimation(.linear(duration: 0.1)) {
                towers[index].hp = max(0, towers[index].hp - drain)
            }
        }

        if overtimeDamageEffectCounter >= 0.35 {
            overtimeDamageEffectCounter = 0
            for tower in towers where !tower.isDestroyed {
                let damage = tower.faction == .ai ? Int(enemyDrainPerSecond * 0.35) : Int(playerDrainPerSecond * 0.35)
                addDamageEffect(damage: damage, position: tower.position)
            }
        }
    }
    
    // 更新飛行物飛行軌跡
    private func updateProjectiles(deltaTime: Double) {
        for i in projectiles.indices.reversed() {
            // 如果追蹤的目標還活著，動態微調目標位置，確保精準擊中
            if let targetId = projectiles[i].targetUnitId,
               let targetUnit = units.first(where: { $0.id == targetId && $0.hp > 0 }) {
                projectiles[i] = Projectile(
                    type: projectiles[i].type,
                    faction: projectiles[i].faction,
                    startPosition: projectiles[i].startPosition,
                    targetPosition: targetUnit.position,
                    currentPosition: projectiles[i].currentPosition,
                    speed: projectiles[i].speed,
                    radius: projectiles[i].radius,
                    damage: projectiles[i].damage,
                    totalDistance: projectiles[i].totalDistance,
                    progress: projectiles[i].progress,
                    targetUnitId: targetId
                )
            }
            
            let step = projectiles[i].speed * CGFloat(deltaTime)
            let progressStep = step / projectiles[i].totalDistance
            projectiles[i].progress += progressStep
            
            if projectiles[i].progress >= 1.0 {
                // 到達目標地點，觸發結算
                let proj = projectiles.remove(at: i)
                if proj.type == .fireball || proj.type == .arrows {
                    detonateSpell(projectile: proj)
                } else {
                    detonateTowerProjectile(projectile: proj)
                }
            } else {
                let p = projectiles[i].progress
                let start = projectiles[i].startPosition
                let target = projectiles[i].targetPosition
                projectiles[i].currentPosition = CGPoint(
                    x: start.x + (target.x - start.x) * p,
                    y: start.y + (target.y - start.y) * p
                )
            }
        }
    }
    
    private func updateAI(now: Date) {
        guard now >= aiNextSpawnTime else { return }
        
        let availableCards = aiHand.filter { Double($0.elixirCost) <= aiElixir }
        if let cardToPlay = availableCards.randomElement() {
            aiElixir -= Double(cardToPlay.elixirCost)
            
            if cardToPlay.category == .spell {
                let targetTower = towers.filter { $0.faction == .player && !$0.isDestroyed }.randomElement()
                let targetPos = targetTower?.position ?? arena.playerKingTowerPos
                launchSpellProjectile(card: cardToPlay, faction: .ai, targetPos: targetPos)
            } else {
                let spawnX = CGFloat.random(in: 40...(mapWidth - 40))
                let spawnY = CGFloat.random(in: 60...210)
                spawnCardUnits(card: cardToPlay, faction: .ai, basePosition: CGPoint(x: spawnX, y: spawnY))
            }
            
            if let idx = aiHand.firstIndex(of: cardToPlay) {
                aiHand.remove(at: idx)
                if !aiDeck.isEmpty {
                    let drawn = aiDeck.removeFirst()
                    aiHand.append(drawn)
                    aiDeck.append(cardToPlay)
                }
            }
            
            aiNextSpawnTime = now.addingTimeInterval(Double.random(in: arena.aiSpawnInterval))
        } else {
            aiNextSpawnTime = now.addingTimeInterval(0.8)
        }
    }
    
    // 單位邏輯：過河必須全程走過橋樑，抵達後遇到敵人持續攻擊；超過本身攻擊範圍的敵人不主動去找
    private func updateUnits(deltaTime: Double, now: Date) {
        for i in units.indices {
            guard units[i].hp > 0 else { continue }
            let unit = units[i]
            
            // 尋找最佳目標（超過自身攻擊範圍的敵方部隊不尋找，繼續向敵方防禦塔推進）
            guard let target = findBestTarget(for: unit) else {
                units[i].isAttacking = false
                continue
            }

            if unit.targetPriority == .building && target.isTower && units[i].lockedTowerID == nil {
                units[i].lockedTowerID = target.id
            }
            
            let dist = hypot(target.position.x - unit.position.x, target.position.y - unit.position.y)
            
            // 隔河判定：若是地面單位，且單位本身「尚未跨越河流進入對岸（仍在原岸或仍在橋面上）」，且目標在河流另一岸
            let unitY = unit.position.y
            let targetY = target.position.y
            let isUnitOnPlayerBank = unitY > riverYRange.upperBound
            let isTargetOnPlayerBank = targetY > riverYRange.upperBound
            let isUnitOnAIBank = unitY < riverYRange.lowerBound
            let isTargetOnAIBank = targetY < riverYRange.lowerBound
            
            let isSeparatedByRiver = (unit.movementType == .ground) && (
                (isUnitOnPlayerBank && isTargetOnAIBank) ||
                (isUnitOnAIBank && isTargetOnPlayerBank)
            )
            
            // 攻擊條件：在射程內，且沒有被河流隔開
            if dist <= unit.range && !isSeparatedByRiver {
                units[i].isAttacking = true
                if now.timeIntervalSince(unit.lastAttackTime) >= unit.attackInterval {
                    units[i].lastAttackTime = now
                    applyDamage(from: unit, to: target)
                }
            } else {
                // 移動導航：向路徑節點前進
                units[i].isAttacking = false
                let nextDestination = getNextWaypoint(for: unit, targetPos: target.position)
                let dx = nextDestination.x - unit.position.x
                let dy = nextDestination.y - unit.position.y
                let distanceToWaypoint = hypot(dx, dy)
                
                if distanceToWaypoint > 0 {
                    let moveDist = unit.speed * deltaTime
                    let step = min(moveDist, distanceToWaypoint)
                    units[i].position.x += (dx / distanceToWaypoint) * step
                    units[i].position.y += (dy / distanceToWaypoint) * step
                }
            }
        }
    }
    
    // 嚴格且流暢的過橋路徑導航
    private func getNextWaypoint(for unit: GameUnit, targetPos: CGPoint) -> CGPoint {
        // 飛行單位直接直線前往
        if unit.movementType == .flying {
            return targetPos
        }
        
        let unitY = unit.position.y
        let isPlayerSide = unitY > riverYRange.upperBound
        let isAISide = unitY < riverYRange.lowerBound
        let isTargetPlayerSide = targetPos.y > riverYRange.upperBound
        let isTargetAISide = targetPos.y < riverYRange.lowerBound
        
        // 雙方處於不同岸（需要渡河）
        let isTargetOnBridge = riverYRange.contains(targetPos.y)
        if (isPlayerSide && isTargetAISide) || (isAISide && isTargetPlayerSide) || riverYRange.contains(unitY) || isTargetOnBridge {
            // 選擇較近的橋樑
            let distLeft = hypot(leftBridge.x - unit.position.x, leftBridge.y - unit.position.y)
            let distRight = hypot(rightBridge.x - unit.position.x, rightBridge.y - unit.position.y)
            let targetBridge: CGPoint
            if isTargetOnBridge {
                targetBridge = abs(targetPos.x - leftBridge.x) < abs(targetPos.x - rightBridge.x) ? leftBridge : rightBridge
            } else {
                targetBridge = distLeft < distRight ? leftBridge : rightBridge
            }
            
            if isPlayerSide {
                if abs(unit.position.x - targetBridge.x) > 1 {
                    return CGPoint(x: targetBridge.x, y: unitY)
                }
                return CGPoint(x: targetBridge.x, y: riverYRange.lowerBound - 2)
            }

            if isAISide {
                if abs(unit.position.x - targetBridge.x) > 1 {
                    return CGPoint(x: targetBridge.x, y: unitY)
                }
                return CGPoint(x: targetBridge.x, y: riverYRange.upperBound + 2)
            }

            // 已在橋面時，繼續走到目標所在一岸的出口
            return CGPoint(
                x: targetBridge.x,
                y: isTargetPlayerSide ? riverYRange.upperBound + 2 : riverYRange.lowerBound - 2
            )
        }
        
        // 已經成功走過橋樑抵達對岸，或雙方本來就在同一側，直接鎖定目標
        return targetPos
    }
    
    // 防禦塔邏輯：
    // 前面兩座公主塔射出弓箭
    // 中間國王塔受到攻擊 or 前面兩座其中一座爆掉，才開始攻擊，攻擊方式是射出小顆砲彈
    // 均具備射擊與擊中特效
    private func updateTowers(now: Date) {
        for i in towers.indices {
            guard !towers[i].isDestroyed else { continue }
            let tower = towers[i]
            
            // 國王塔啟動檢查：
            // 若為國王主塔，必須在受到攻擊(hp < maxHp) 或 己方任一座公主塔被擊毀時才啟動
            if tower.isKingTower {
                let friendlyPrincessTowers = towers.filter { $0.faction == tower.faction && !$0.isKingTower }
                let anyPrincessDestroyed = friendlyPrincessTowers.contains(where: { $0.isDestroyed })
                let isDamaged = tower.hp < tower.maxHp
                
                if isDamaged || anyPrincessDestroyed {
                    towers[i].isActivated = true
                }
                
                // 未啟動前不進行任何攻擊
                if !towers[i].isActivated {
                    towers[i].isAttacking = false
                    continue
                }
            }
            
            let enemyUnits = units.filter { $0.faction != tower.faction && $0.hp > 0 }
            if let closestEnemy = enemyUnits.min(by: {
                hypot($0.position.x - tower.position.x, $0.position.y - tower.position.y) <
                hypot($1.position.x - tower.position.x, $1.position.y - tower.position.y)
            }) {
                let dist = hypot(closestEnemy.position.x - tower.position.x, closestEnemy.position.y - tower.position.y)
                if dist <= tower.range {
                    towers[i].isAttacking = true
                    if now.timeIntervalSince(tower.lastAttackTime) >= tower.attackInterval {
                        towers[i].lastAttackTime = now
                        towers[i].lastShotTime = now
                        launchTowerProjectile(from: towers[i], to: closestEnemy)
                    }
                } else {
                    towers[i].isAttacking = false
                }
            } else {
                towers[i].isAttacking = false
            }
        }
    }
    
    private struct TargetInfo {
        let id: UUID
        let isTower: Bool
        let position: CGPoint
    }
    
    // 尋找最佳目標：超過本身攻擊範圍的敵人，就不要去找他！
    private func findBestTarget(for unit: GameUnit) -> TargetInfo? {
        if let lockedTowerID = unit.lockedTowerID,
           let tower = towers.first(where: { $0.id == lockedTowerID && !$0.isDestroyed }) {
            return TargetInfo(id: tower.id, isTower: true, position: tower.position)
        }

        var candidates: [TargetInfo] = []
        
        // 敵方防禦塔始終為部隊向前推進的戰略目標
        let enemyTowers = towers.filter { $0.faction != unit.faction && !$0.isDestroyed }
        for tower in enemyTowers {
            candidates.append(TargetInfo(id: tower.id, isTower: true, position: tower.position))
        }
        
        // 敵方部隊：僅當敵人位於自身「攻擊範圍 (unit.range)」內時，才加入鎖定候選！
        // 超過攻擊範圍的敵軍，部隊不主動離開路線或跨線追逐，而是專注向前推進。
        if unit.targetPriority == .any {
            let enemyUnits = units.filter {
                $0.faction != unit.faction &&
                $0.hp > 0 &&
                (unit.canTargetFlyingUnits || $0.movementType == .ground) &&
                hypot($0.position.x - unit.position.x, $0.position.y - unit.position.y) <= unit.range
            }
            for u in enemyUnits {
                candidates.append(TargetInfo(id: u.id, isTower: false, position: u.position))
            }
        }
        
        return candidates.min(by: {
            hypot($0.position.x - unit.position.x, $0.position.y - unit.position.y) <
            hypot($1.position.x - unit.position.x, $1.position.y - unit.position.y)
        })
    }
    
    private func applyDamage(from attacker: GameUnit, to target: TargetInfo) {
        // 依使用者需求，完全移除攻擊時的點擊音效
        let dmg = attacker.atk
        
        if attacker.cardType.isAoe {
            let aoeRadius = attacker.cardType.aoeRadius
            for i in units.indices {
                if units[i].faction != attacker.faction {
                    let d = hypot(units[i].position.x - target.position.x, units[i].position.y - target.position.y)
                    if d <= aoeRadius {
                        units[i].hp -= dmg
                        addDamageEffect(damage: Int(dmg), position: units[i].position)
                    }
                }
            }
            if target.isTower {
                if let index = towers.firstIndex(where: { $0.id == target.id }) {
                    towers[index].hp -= dmg
                    addDamageEffect(damage: Int(dmg), position: target.position)
                    if towers[index].isKingTower {
                        towers[index].isActivated = true
                    }
                }
            }
        } else {
            if target.isTower {
                if let index = towers.firstIndex(where: { $0.id == target.id }) {
                    towers[index].hp -= dmg
                    addDamageEffect(damage: Int(dmg), position: target.position)
                    if towers[index].isKingTower {
                        towers[index].isActivated = true
                    }
                }
            } else {
                if let index = units.firstIndex(where: { $0.id == target.id }) {
                    units[index].hp -= dmg
                    addDamageEffect(damage: Int(dmg), position: target.position)
                }
            }
        }
    }
    
    private func addDamageEffect(damage: Int, position: CGPoint, isSpell: Bool = false) {
        let effect = DamageEffect(damage: damage, position: position, isSpell: isSpell)
        damageEffects.append(effect)
    }
    
    private func updateDamageEffects(deltaTime: Double) {
        for i in damageEffects.indices.reversed() {
            damageEffects[i].opacity -= deltaTime * 1.5
            damageEffects[i].offsetY -= CGFloat(deltaTime * 25.0)
            if damageEffects[i].opacity <= 0 {
                damageEffects.remove(at: i)
            }
        }
    }
    
    private func updateSpellExplosions(deltaTime: Double) {
        for i in spellExplosions.indices.reversed() {
            spellExplosions[i].scale += CGFloat(deltaTime * 2.8)
            spellExplosions[i].opacity -= deltaTime * 2.2
            if spellExplosions[i].opacity <= 0 {
                spellExplosions.remove(at: i)
            }
        }
    }
    
    private func updateTowerHitEffects(deltaTime: Double) {
        for i in towerHitEffects.indices.reversed() {
            towerHitEffects[i].scale += CGFloat(deltaTime * 3.5)
            towerHitEffects[i].opacity -= deltaTime * 3.0
            if towerHitEffects[i].opacity <= 0 {
                towerHitEffects.remove(at: i)
            }
        }
    }

    private func cleanUpAndCheckVictory() {
        units.removeAll(where: { $0.hp <= 0 })

        let aiTowersDestroyed = towers.filter { $0.faction == .ai && $0.isDestroyed }.count
        let playerTowersDestroyed = towers.filter { $0.faction == .player && $0.isDestroyed }.count

        playerCrowns = aiTowersDestroyed
        aiCrowns = playerTowersDestroyed

        if isOvertime {
            if aiTowersDestroyed > 0 {
                endGame(victory: true, reason: "加時決勝中，敵方塔先被摧毀！")
            } else if playerTowersDestroyed > 0 {
                endGame(victory: false, reason: "加時決勝中，我方塔先被摧毀！")
            }
        } else if aiTowersDestroyed == 3 {
            playerCrowns = 3
            endGame(victory: true, reason: "摧毀了敵方三座塔！")
        } else if playerTowersDestroyed == 3 {
            aiCrowns = 3
            endGame(victory: false, reason: "我方三座塔皆被摧毀！")
        }
    }

    private func endGameByTimeLimit() {
        let playerTowersRemaining = towers.filter { $0.faction == .player && !$0.isDestroyed }.count
        let aiTowersRemaining = towers.filter { $0.faction == .ai && !$0.isDestroyed }.count

        if aiTowersRemaining < playerTowersRemaining {
            endGame(victory: true, reason: "時間到！敵方剩餘塔數較少。")
        } else if aiTowersRemaining > playerTowersRemaining {
            endGame(victory: false, reason: "時間到！我方剩餘塔數較少。")
        } else {
            isOvertime = true
            statusMessage = "⚔️ 加時決勝！雙方所有塔開始扣血！"
        }
    }

    private func endGame(victory: Bool, reason: String) {
        timer?.cancel()
        gameStatus = victory ? .victory : .defeat
        statusMessage = victory ? "🏆 勝利！\(reason)" : "💀 戰敗！\(reason)"
        selectedCard = nil
    }
}
