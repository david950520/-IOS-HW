import SwiftUI

struct BattlefieldView: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / engine.mapWidth
            let scaleY = geometry.size.height / engine.mapHeight
            
            ZStack {
                // 1. 競技場真實背景圖 (圖片本身具備完整的戰場、河流、橋樑與六個塔位大正方形)
                MapBackgroundView(mapWidth: engine.mapWidth, mapHeight: engine.mapHeight, arena: engine.arena)
                
                // 2. 可放置區域提示 (當玩家選中卡牌時)
                if let card = engine.selectedCard {
                    if card.category == .spell {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.85), style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                            .background(Color.orange.opacity(0.12))
                            .overlay(
                                Text("🔥 點擊戰場任意目標！\(card.name) 呼嘯轟炸")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.orange)
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(8),
                                alignment: .top
                            )
                            .padding(8)
                    } else {
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.blue.opacity(0.20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                )
                                .frame(height: geometry.size.height * 0.5)
                        }
                    }
                }
                
                // 3. 六座防禦塔渲染 (精確安置在圖片上的三個大正方形，包含射箭、砲彈射擊特效與休眠/啟動指示)
                ForEach(engine.towers) { tower in
                    TowerRenderView(tower: tower, scaleX: scaleX, scaleY: scaleY)
                }
                
                // 4. 戰場部隊單位渲染
                ForEach(engine.units) { unit in
                    UnitRenderView(unit: unit, scaleX: scaleX, scaleY: scaleY)
                }
                
                // 5. 正在飛行的投射物 (火球術、萬箭齊發、公主塔弓箭、國王塔砲彈)
                ForEach(engine.projectiles) { proj in
                    ProjectileRenderView(proj: proj, scaleX: scaleX, scaleY: scaleY)
                }
                
                // 6. 防禦塔弓箭與砲彈命中火花與爆炸特效
                ForEach(engine.towerHitEffects) { hit in
                    TowerHitRenderView(hit: hit, scaleX: scaleX, scaleY: scaleY)
                }
                
                // 7. 法術著陸爆炸衝擊圈
                ForEach(engine.spellExplosions) { exp in
                    SpellExplosionRenderView(exp: exp, scaleX: scaleX, scaleY: scaleY)
                }
                
                // 8. 傷害效果浮動文字
                ForEach(engine.damageEffects) { damage in
                    Text("-\(damage.damage)")
                        .font(.system(size: damage.isSpell ? 18 : 14, weight: .black, design: .rounded))
                        .foregroundColor(damage.isSpell ? .orange : .yellow)
                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                        .position(x: damage.position.x * scaleX, y: (damage.position.y + damage.offsetY) * scaleY)
                        .opacity(damage.opacity)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        if let card = engine.selectedCard {
                            let mapX = value.location.x / scaleX
                            let mapY = value.location.y / scaleY
                            _ = engine.placeCard(card, at: CGPoint(x: mapX, y: mapY))
                        }
                    }
            )
        }
        .aspectRatio(360 / 540, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.35), lineWidth: 2)
        )
    }
}

// MARK: - 飛行投射物視覺效果 (火球 / 萬箭 / 公主塔弓箭 / 國王塔小砲彈)
struct ProjectileRenderView: View {
    let proj: Projectile
    let scaleX: CGFloat
    let scaleY: CGFloat
    
    var body: some View {
        let posX = proj.currentPosition.x * scaleX
        let posY = proj.currentPosition.y * scaleY
        let angle = atan2(proj.targetPosition.y - proj.startPosition.y, proj.targetPosition.x - proj.startPosition.x)
        
        Group {
            switch proj.type {
            case .fireball:
                // 巨大熾熱火球 + 燃燒拖尾
                ZStack {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .orange.opacity(0.6), .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 44, height: 18)
                        .offset(x: -16)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, .yellow, .orange, .red],
                                center: .center,
                                startRadius: 2,
                                endRadius: 16
                            )
                        )
                        .frame(width: 28, height: 28)
                        .shadow(color: .orange, radius: 8)
                    
                    Text("🔥")
                        .font(.system(size: 16))
                }
                .rotationEffect(.radians(Double(angle)))
                
            case .arrows:
                // 萬箭齊發：整批密集破空飛箭群
                ZStack {
                    ForEach(0..<9, id: \.self) { idx in
                        let offsetX = CGFloat((idx % 3 - 1) * 10)
                        let offsetY = CGFloat((idx / 3 - 1) * 8)
                        
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(LinearGradient(colors: [.clear, .gray.opacity(0.5), .white], startPoint: .leading, endPoint: .trailing))
                                .frame(width: 14, height: 2)
                            
                            TriangleArrowHead()
                                .fill(Color.white)
                                .frame(width: 5, height: 6)
                        }
                        .rotationEffect(.radians(Double(angle)))
                        .offset(x: offsetX, y: offsetY)
                    }
                }
                .shadow(color: .cyan.opacity(0.6), radius: 3)
                
            case .towerArrow:
                // 前面兩座公主塔射出的單發高速穿雲箭
                HStack(spacing: 0) {
                    // 光痕拖尾
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, proj.faction == .player ? .cyan.opacity(0.4) : .red.opacity(0.4), .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 18, height: 2.2)
                    
                    // 箭身木紋與金屬箭頭
                    Rectangle()
                        .fill(Color(red: 0.85, green: 0.70, blue: 0.40))
                        .frame(width: 8, height: 2)
                    
                    TriangleArrowHead()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .shadow(color: proj.faction == .player ? .cyan : .yellow, radius: 2)
                }
                .rotationEffect(.radians(Double(angle)))
                .shadow(color: .white.opacity(0.8), radius: 2)
                
            case .towerCannonball:
                // 中間國王塔射出的小顆砲彈 (附帶火花尾跡)
                ZStack {
                    // 砲彈後方煙霧與火星拖尾
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.orange.opacity(0.8), .red.opacity(0.5), .clear],
                                center: .center,
                                startRadius: 1,
                                endRadius: 8
                            )
                        )
                        .frame(width: 16, height: 16)
                        .offset(x: -8)
                    
                    // 核心鐵質砲彈
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(white: 0.8), Color(white: 0.35), Color(white: 0.15)],
                                center: UnitPoint(x: 0.35, y: 0.35),
                                startRadius: 1,
                                endRadius: 6
                            )
                        )
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 0.8))
                        .shadow(color: .orange.opacity(0.9), radius: 3)
                }
                .rotationEffect(.radians(Double(angle)))
            }
        }
        .position(x: posX, y: posY)
    }
}

// 箭頭三角形小元件
struct TriangleArrowHead: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 防禦塔擊中特效 (弓箭火花 / 砲彈爆擊)
struct TowerHitRenderView: View {
    let hit: TowerHitEffect
    let scaleX: CGFloat
    let scaleY: CGFloat
    
    var body: some View {
        let posX = hit.position.x * scaleX
        let posY = hit.position.y * scaleY
        
        ZStack {
            if hit.type == .towerArrow {
                // 弓箭擊中金色/銀色星芒火花
                Image(systemName: "sparkle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 4)
                    .scaleEffect(hit.scale * 1.5)
            } else {
                // 砲彈命中爆炸火光
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, .yellow, .orange, .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 16
                        )
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(hit.scale)
                
                Text("💥")
                    .font(.system(size: 18))
                    .scaleEffect(hit.scale * 1.2)
            }
        }
        .opacity(hit.opacity)
        .position(x: posX, y: posY)
    }
}

// MARK: - 法術爆炸著陸衝擊波視覺
struct SpellExplosionRenderView: View {
    let exp: SpellExplosionEffect
    let scaleX: CGFloat
    let scaleY: CGFloat
    
    var body: some View {
        let posX = exp.position.x * scaleX
        let posY = exp.position.y * scaleY
        
        ZStack {
            if exp.type == .fireball {
                Circle()
                    .stroke(
                        RadialGradient(
                            colors: [.white, .yellow, .orange, .red, .clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: exp.radius
                        ),
                        lineWidth: 8
                    )
                    .background(Circle().fill(Color.orange.opacity(0.35)))
                    .frame(width: exp.radius * 2, height: exp.radius * 2)
                    .scaleEffect(exp.scale)
                
                Text("💥")
                    .font(.system(size: 32))
                    .scaleEffect(exp.scale * 1.2)
            } else {
                Circle()
                    .stroke(
                        LinearGradient(colors: [.cyan, .white, .blue.opacity(0.2)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 4
                    )
                    .background(Circle().fill(Color.cyan.opacity(0.2)))
                    .frame(width: exp.radius * 2, height: exp.radius * 2)
                    .scaleEffect(exp.scale)
                
                Text("🎯")
                    .font(.system(size: 26))
                    .scaleEffect(exp.scale)
            }
        }
        .opacity(exp.opacity)
        .position(x: posX, y: posY)
    }
}

// MARK: - 競技場地圖繪製 (支援 5 大競技場背景圖)
struct MapBackgroundView: View {
    let mapWidth: CGFloat
    let mapHeight: CGFloat
    let arena: ArenaLevel
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // 1. 競技場背景圖 (依序為巨龍訓練場、冰火重天學院、烈焰龍骨墳場、寒冰茫星廣場、龍騎士死鬥場)
                if !arena.imageName.isEmpty {
                    if arena.number == 5 {
                        // 第 5 關圖片含有黑色留白；以等比例填滿並裁切留白。
                        ZStack {
                            LinearGradient(
                                colors: arena.backgroundColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            Image(arena.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: w, height: h)
                                .clipped()
                        }
                    } else {
                        Image(arena.imageName)
                            .resizable()
                            .frame(width: w, height: h)
                    }
                } else {
                    LinearGradient(
                        colors: arena.backgroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
    }
}

// MARK: - 防禦塔繪製 (支援弓箭/砲彈攻擊特效、休眠狀態與啟動狀態，安置於大正方形上)
struct TowerRenderView: View {
    let tower: Tower
    let scaleX: CGFloat
    let scaleY: CGFloat
    
    var body: some View {
        let posX = tower.position.x * scaleX
        let posY = tower.position.y * scaleY
        let towerSize: CGFloat = tower.isKingTower ? 46 : 36
        let isRecentlyShot = Date().timeIntervalSince(tower.lastShotTime) < 0.25
        
        ZStack {
            if !tower.isDestroyed {
                // 1. 攻擊特效光圈 (公主塔射箭光環 / 國王塔砲火氣浪)
                if tower.isAttacking {
                    Circle()
                        .stroke(
                            tower.isKingTower ? Color.orange.opacity(0.85) : tower.faction.color.opacity(0.75),
                            lineWidth: tower.isKingTower ? 4 : 2.5
                        )
                        .frame(width: towerSize + 16, height: towerSize + 16)
                        .scaleEffect(1.25)
                        .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: tower.isAttacking)
                }
                
                // 2. 開火瞬間的發射火花特效 (弓箭射出瞬間金芒 / 砲彈發射瞬間煙火氣體)
                if isRecentlyShot {
                    if tower.isKingTower {
                        // 國王塔砲口開火煙硝衝擊波
                        Circle()
                            .fill(RadialGradient(colors: [.white, .yellow, .orange, .clear], center: .center, startRadius: 2, endRadius: 20))
                            .frame(width: 40, height: 40)
                            .scaleEffect(1.3)
                    } else {
                        // 公主塔弓弦射擊閃光
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                            .shadow(color: .white, radius: 4)
                    }
                }
                
                // 3. 塔主體 (安置在大正方形石基座上)
                RoundedRectangle(cornerRadius: tower.isKingTower ? 10 : 8)
                    .fill(
                        LinearGradient(
                            colors: tower.faction == .player
                                ? [Color(red: 0.15, green: 0.40, blue: 0.85), Color(red: 0.08, green: 0.22, blue: 0.55)]
                                : [Color(red: 0.85, green: 0.20, blue: 0.20), Color(red: 0.55, green: 0.10, blue: 0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: towerSize + 6, height: towerSize + 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: tower.isKingTower ? 10 : 8)
                            .stroke(tower.isKingTower ? (tower.isActivated ? Color.yellow : Color.white.opacity(0.5)) : Color.white, lineWidth: tower.isKingTower ? 2.5 : 2)
                    )
                    .shadow(color: tower.faction == .player ? .blue.opacity(0.5) : .red.opacity(0.5), radius: 4)
                    .scaleEffect(isRecentlyShot ? 1.08 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isRecentlyShot)
                
                // 4. 圖示：國王塔 (依休眠/啟動狀態變化) / 公主塔
                if tower.isKingTower {
                    ZStack {
                        Text("👑")
                            .font(.system(size: 26))
                            .scaleEffect(tower.isActivated ? 1.05 : 0.9)
                        
                        // 若尚未啟動，顯示休眠提示小標記
                        if !tower.isActivated {
                            Text("💤")
                                .font(.system(size: 13))
                                .offset(x: 14, y: -12)
                        } else {
                            // 已啟動狀態：砲台準備標誌
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                                .offset(x: 14, y: -12)
                                .shadow(color: .orange, radius: 2)
                        }
                    }
                } else {
                    Text("🏰")
                        .font(.system(size: 20))
                }
                
                // 5. 生命值血量條與數值
                VStack(spacing: 2) {
                    ProgressView(value: tower.hpRatio)
                        .tint(tower.hpRatio > 0.4 ? (tower.faction == .player ? .blue : .red) : .orange)
                        .frame(width: towerSize + 14, height: 6)
                        .clipShape(Capsule())
                    
                    Text("\(Int(tower.hp))")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(3)
                }
                .offset(y: -(towerSize / 2 + 13))
            } else {
                Text("💥")
                    .font(.system(size: 26))
            }
        }
        .position(x: posX, y: posY)
    }
}

// MARK: - 戰場單位繪製
struct UnitRenderView: View {
    let unit: GameUnit
    let scaleX: CGFloat
    let scaleY: CGFloat
    
    var body: some View {
        let posX = unit.position.x * scaleX
        let posY = unit.position.y * scaleY
        
        let unitSize: CGFloat = {
            switch unit.cardType {
            case .giant: return 34
            case .babyDragon, .hogRider, .knight: return 26
            case .archer: return 22
            case .goblin: return 20
            default: return 24
            }
        }()
        
        ZStack {
            Circle()
                .fill(unit.faction.color.opacity(unit.movementType == .flying ? 0.2 : 0.4))
                .frame(width: unitSize + 6, height: unitSize + 6)
                .overlay(
                    Circle().stroke(unit.faction.color, lineWidth: unit.movementType == .flying ? 1 : 2)
                )
            
            Group {
                if !unit.cardType.imageName.isEmpty {
                    Image(unit.cardType.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: unitSize, height: unitSize)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.2))
                } else {
                    Text(unit.cardType.icon)
                        .font(.system(size: unitSize * 0.75))
                }
            }
            .shadow(radius: 2)
            .scaleEffect(unit.isAttacking ? 1.2 : 1.0)
            .offset(y: unit.movementType == .flying ? -6 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: unit.isAttacking)
            
            VStack(spacing: 1) {
                ProgressView(value: unit.hpRatio)
                    .tint(unit.faction == .player ? .green : .red)
                    .frame(width: unitSize + 2, height: 3.5)
                    .clipShape(Capsule())
            }
            .offset(y: -(unitSize / 2 + (unit.movementType == .flying ? 12 : 5)))
        }
        .position(x: posX, y: posY)
    }
}
