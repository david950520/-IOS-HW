import SwiftUI

// MARK: - 陣營
enum Faction: String, Codable {
    case player // 藍方 (玩家)
    case ai     // 紅方 (電腦)
    
    var color: Color {
        switch self {
        case .player: return .blue
        case .ai: return .red
        }
    }
    
    var title: String {
        switch self {
        case .player: return "玩家"
        case .ai: return "AI 電腦"
        }
    }
}

// MARK: - 卡牌種類 (部隊、法術、建築)
enum CardCategory: String, Codable {
    case troop   // 地面/空中部隊
    case spell   // 法術 (可全圖任意施放，如火球、萬箭齊發)
    case building // 建築
    
    var title: String {
        switch self {
        case .troop: return "部隊"
        case .spell: return "法術"
        case .building: return "建築"
        }
    }
}

// MARK: - 攻擊優先目標
enum TargetPriority: String, Codable {
    case any      // 任何敵方單位或建築
    case building // 僅建築（防禦塔/主塔）
    
    var title: String {
        switch self {
        case .any: return "全體目標"
        case .building: return "僅限建築"
        }
    }
}

// MARK: - 移動類型
enum MovementType: String, Codable {
    case ground // 地面部隊（必須走左右兩座橋，無法涉水）
    case flying // 飛行部隊（直接飛越河流）
    
    var title: String {
        switch self {
        case .ground: return "地面"
        case .flying: return "空中飛行"
        }
    }
}

// MARK: - 8 張核心經典卡牌 (錦標賽 11 級標準數據)
enum CardType: String, CaseIterable, Identifiable, Codable {
    case knight     // 🛡️ 小騎士 (3費)
    case archer     // 🏹 弓箭手 (3費)
    case giant      // 🗿 巨人 (5費)
    case goblin     // 🗡️ 哥布林 (2費)
    case fireball   // 🔥 火球術 (4費，全圖飛行轟炸)
    case arrows     // 🎯 萬箭齊發 (3費，箭雨齊飛清群怪)
    case hogRider   // 🐗 野豬騎士 (4費，極速攻城)
    case babyDragon // 🐲 飛龍寶寶 (4費，空中範圍噴火)
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .knight: return "小騎士"
        case .archer: return "弓箭手"
        case .giant: return "巨人"
        case .goblin: return "哥布林"
        case .fireball: return "火球術"
        case .arrows: return "萬箭齊發"
        case .hogRider: return "野豬騎士"
        case .babyDragon: return "飛龍寶寶"
        }
    }
    
    var icon: String {
        switch self {
        case .knight: return "🛡️"
        case .archer: return "🏹"
        case .giant: return "🗿"
        case .goblin: return "🗡️"
        case .fireball: return "🔥"
        case .arrows: return "🎯"
        case .hogRider: return "🐗"
        case .babyDragon: return "🐲"
        }
    }
    
    var category: CardCategory {
        switch self {
        case .fireball, .arrows: return .spell
        default: return .troop
        }
    }
    
    var movementType: MovementType {
        switch self {
        case .babyDragon: return .flying
        default: return .ground
        }
    }
    
    var isAoe: Bool {
        switch self {
        case .fireball, .arrows, .babyDragon: return true
        default: return false
        }
    }
    
    var aoeRadius: Double {
        switch self {
        case .fireball: return 65.0
        case .arrows: return 80.0
        case .babyDragon: return 40.0
        default: return 0.0
        }
    }
    
    var imageName: String {
        switch self {
        case .knight: return "騎士"
        case .archer: return "弓箭手"
        case .giant: return "巨人"
        case .goblin: return "哥布林"
        case .fireball: return "火球"
        case .arrows: return "萬箭齊發"
        case .hogRider: return "野豬騎士"
        case .babyDragon: return "飛龍寶寶"
        }
    }
    
    // 聖水消耗
    var elixirCost: Int {
        switch self {
        case .goblin: return 2
        case .knight, .archer, .arrows: return 3
        case .fireball, .hogRider, .babyDragon: return 4
        case .giant: return 5
        }
    }
    
    // 11 級生命值
    var maxHp: Double {
        switch self {
        case .knight: return 1766
        case .archer: return 304
        case .giant: return 3968
        case .goblin: return 202
        case .fireball, .arrows: return 0
        case .hogRider: return 1696
        case .babyDragon: return 1152
        }
    }
    
    // 11 級單次傷害 (法術對建築傷害約為 30%~35%)
    var atk: Double {
        switch self {
        case .knight: return 202
        case .archer: return 112
        case .giant: return 253
        case .goblin: return 120
        case .fireball: return 689 // 對塔 207
        case .arrows: return 366   // 對塔 110
        case .hogRider: return 318
        case .babyDragon: return 160
        }
    }
    
    // 戰場一格為 45 點；所有部隊均在相鄰一格內攻擊。
    var attackRange: Double {
        45
    }
    
    // 攻擊間隔 (Hit Speed)
    var attackInterval: Double {
        switch self {
        case .knight: return 1.2
        case .archer: return 0.9
        case .giant: return 1.5
        case .goblin: return 1.1
        case .fireball, .arrows: return 0.0
        case .hogRider: return 1.6
        case .babyDragon: return 1.5
        }
    }
    
    // 每秒傷害 (DPS)
    var dps: Double {
        attackInterval > 0 ? atk / attackInterval : 0
    }
    
    // 所有可移動部隊的速度調整為原本的 0.5 倍。
    var moveSpeed: Double {
        let standardSpeed: Double

        switch self {
        case .giant: standardSpeed = 45
        case .knight, .archer: standardSpeed = 60
        case .babyDragon: standardSpeed = 90
        case .hogRider, .goblin: standardSpeed = 120
        case .fireball, .arrows: standardSpeed = 0
        }

        return standardSpeed * 0.5
    }
    
    var speedTitle: String {
        switch self {
        case .giant: return "慢速"
        case .knight, .archer: return "中速"
        case .babyDragon: return "快速"
        case .hogRider, .goblin: return "極速"
        case .fireball, .arrows: return "即時/飛行"
        }
    }
    
    // 目標優先
    var targetPriority: TargetPriority {
        switch self {
        case .giant, .hogRider: return .building
        default: return .any
        }
    }

    // 小騎士與哥布林的近戰武器無法攻擊飛行單位。
    var canTargetFlyingUnits: Bool {
        switch self {
        case .knight, .goblin:
            return false
        default:
            return true
        }
    }
    
    // 生成數量：哥布林 4 隻，弓箭手 2 隻，其餘 1
    var spawnCount: Int {
        switch self {
        case .archer: return 2
        case .goblin: return 4
        case .fireball, .arrows: return 0
        default: return 1
        }
    }
    
    var description: String {
        switch self {
        case .knight: return "中速近戰劍士，血量厚實攻守兼備（召喚 1 名）"
        case .archer: return "中速遠程射手，一次召喚 2 名雙人聯防"
        case .giant: return "超高血量攻城坦克，直奔敵方防禦塔（召喚 1 名）"
        case .goblin: return "極速短刀突襲兵，一次召喚 4 名包圍敵軍"
        case .fireball: return "呼嘯飛馳的巨大火球，造成毀滅性範圍爆炸"
        case .arrows: return "漫天箭雨破空齊發，覆蓋大範圍秒殺小兵群"
        case .hogRider: return "極速攻城騎士，跨步衝鋒直撲敵方防禦塔"
        case .babyDragon: return "空中飛行噴火龍，對地面與空中造成範圍 AOE 傷害"
        }
    }
    
    var strategyTip: String {
        switch self {
        case .knight: return "萬用近戰防守核心，能以低費單挑眾多中小型部隊，亦可作為副坦。"
        case .archer: return "站位靠後進行穩定輸出，兩人分開射擊不易被一次全滅。"
        case .giant: return "推進陣容的厚實護盾，後方搭配遠程或空中輸出部隊能摧毀防禦塔。"
        case .goblin: return "超低費高瞬間傷害，適合近身圍殺落單坦克或突襲敵方建築。"
        case .fireball: return "針對聚集部隊或防禦塔的重型法術，可一舉消滅中量生命值單位。"
        case .arrows: return "清群法寶，大範圍箭雨能在瞬間消滅哥布林等輕量部隊。"
        case .hogRider: return "無視其他部隊直奔防線，擅長出其不意對敵塔發動致命衝擊。"
        case .babyDragon: return "極佳的空中範圍輸出者，能防禦空中與地面群怪並牽制防線。"
        }
    }
}

// MARK: - 五座競技場
struct ArenaLevel: Identifiable, Equatable {
    let number: Int
    let title: String
    let subtitle: String
    let icon: String
    let imageName: String
    let backgroundColors: [Color]
    let riverColors: [Color]
    let aiHealthMultiplier: Double
    let aiDamageMultiplier: Double
    let aiElixirRate: Double
    let aiSpawnInterval: ClosedRange<Double>

    // 雙方六座塔在背景圖片三個大正方形（兩邊共六個）上的精確中心座標 (基於 360 x 540 邏輯尺寸)
    let aiLeftPrincessPos: CGPoint
    let aiRightPrincessPos: CGPoint
    let aiKingTowerPos: CGPoint
    let playerLeftPrincessPos: CGPoint
    let playerRightPrincessPos: CGPoint
    let playerKingTowerPos: CGPoint

    var id: Int { number }

    static let all: [ArenaLevel] = [
        ArenaLevel(
            number: 1,
            title: "巨龍訓練場",
            subtitle: "幼龍試煉",
            icon: "flame.fill",
            imageName: "巨龍訓練場",
            backgroundColors: [Color(red: 0.28, green: 0.45, blue: 0.22), Color(red: 0.15, green: 0.28, blue: 0.14)],
            riverColors: [.blue, .cyan],
            aiHealthMultiplier: 0.85,
            aiDamageMultiplier: 0.85,
            aiElixirRate: 0.55,
            aiSpawnInterval: 3.4...4.5,
            aiLeftPrincessPos: CGPoint(x: 86, y: 162),
            aiRightPrincessPos: CGPoint(x: 274, y: 162),
            aiKingTowerPos: CGPoint(x: 180, y: 76),
            playerLeftPrincessPos: CGPoint(x: 76, y: 388),
            playerRightPrincessPos: CGPoint(x: 284, y: 388),
            playerKingTowerPos: CGPoint(x: 180, y: 464)
        ),
        ArenaLevel(
            number: 2,
            title: "冰火重天學院",
            subtitle: "元素交鋒",
            icon: "sparkles",
            imageName: "冰火重天學院",
            backgroundColors: [Color(red: 0.20, green: 0.35, blue: 0.60), Color(red: 0.55, green: 0.22, blue: 0.15)],
            riverColors: [.cyan, .orange],
            aiHealthMultiplier: 1.0,
            aiDamageMultiplier: 1.0,
            aiElixirRate: 0.7,
            aiSpawnInterval: 2.8...4.0,
            aiLeftPrincessPos: CGPoint(x: 94, y: 162),
            aiRightPrincessPos: CGPoint(x: 266, y: 162),
            aiKingTowerPos: CGPoint(x: 180, y: 54),
            playerLeftPrincessPos: CGPoint(x: 83, y: 367),
            playerRightPrincessPos: CGPoint(x: 277, y: 367),
            playerKingTowerPos: CGPoint(x: 180, y: 486)
        ),
        ArenaLevel(
            number: 3,
            title: "烈焰龍骨墳場",
            subtitle: "焦土死戰",
            icon: "flame",
            imageName: "烈焰龍骨墳場",
            backgroundColors: [Color(red: 0.50, green: 0.18, blue: 0.10), Color(red: 0.25, green: 0.08, blue: 0.08)],
            riverColors: [.orange, .red],
            aiHealthMultiplier: 1.12,
            aiDamageMultiplier: 1.12,
            aiElixirRate: 0.78,
            aiSpawnInterval: 2.5...3.7,
            aiLeftPrincessPos: CGPoint(x: 101, y: 130),
            aiRightPrincessPos: CGPoint(x: 259, y: 130),
            aiKingTowerPos: CGPoint(x: 180, y: 97),
            playerLeftPrincessPos: CGPoint(x: 94, y: 400),
            playerRightPrincessPos: CGPoint(x: 266, y: 400),
            playerKingTowerPos: CGPoint(x: 180, y: 437)
        ),
        ArenaLevel(
            number: 4,
            title: "寒冰茫星廣場",
            subtitle: "霜星漫天",
            icon: "snowflake",
            imageName: "寒冰茫星廣場",
            backgroundColors: [Color(red: 0.15, green: 0.40, blue: 0.60), Color(red: 0.08, green: 0.18, blue: 0.35)],
            riverColors: [.cyan, .white],
            aiHealthMultiplier: 1.25,
            aiDamageMultiplier: 1.25,
            aiElixirRate: 0.88,
            aiSpawnInterval: 2.2...3.4,
            aiLeftPrincessPos: CGPoint(x: 79, y: 151),
            aiRightPrincessPos: CGPoint(x: 281, y: 151),
            aiKingTowerPos: CGPoint(x: 180, y: 97),
            playerLeftPrincessPos: CGPoint(x: 90, y: 388),
            playerRightPrincessPos: CGPoint(x: 270, y: 388),
            playerKingTowerPos: CGPoint(x: 180, y: 437)
        ),
        ArenaLevel(
            number: 5,
            title: "龍騎士死鬥場",
            subtitle: "終極榮耀",
            icon: "crown.fill",
            imageName: "龍騎士死鬥場",
            backgroundColors: [Color(red: 0.30, green: 0.15, blue: 0.45), Color(red: 0.12, green: 0.05, blue: 0.20)],
            riverColors: [.yellow, .purple],
            aiHealthMultiplier: 1.4,
            aiDamageMultiplier: 1.4,
            aiElixirRate: 1.0,
            aiSpawnInterval: 1.9...3.0,
            aiLeftPrincessPos: CGPoint(x: 86, y: 113),
            aiRightPrincessPos: CGPoint(x: 274, y: 113),
            aiKingTowerPos: CGPoint(x: 180, y: 102),
            playerLeftPrincessPos: CGPoint(x: 79, y: 378),
            playerRightPrincessPos: CGPoint(x: 281, y: 378),
            playerKingTowerPos: CGPoint(x: 180, y: 421)
        )
    ]

    static func level(_ number: Int) -> ArenaLevel {
        all.first(where: { $0.number == number }) ?? all[0]
    }
}

// MARK: - 戰場實體單位 (Unit)
struct GameUnit: Identifiable {
    let id: UUID = UUID()
    let faction: Faction
    let cardType: CardType
    var position: CGPoint
    var hp: Double
    let maxHp: Double
    let atk: Double
    let range: Double
    let speed: Double
    let attackInterval: Double
    let targetPriority: TargetPriority
    let movementType: MovementType
    let canTargetFlyingUnits: Bool
    var lockedTowerID: UUID?
    var lastAttackTime: Date = Date.distantPast
    var isAttacking: Bool = false
    
    var hpRatio: Double {
        max(0, hp / maxHp)
    }
}

// MARK: - 防禦塔與主塔 (Tower)
struct Tower: Identifiable {
    let id: UUID = UUID()
    let faction: Faction
    let isKingTower: Bool
    let name: String
    var position: CGPoint
    var hp: Double
    let maxHp: Double
    let atk: Double
    let range: Double
    let attackInterval: Double
    var lastAttackTime: Date = Date.distantPast
    var isAttacking: Bool = false
    var isActivated: Bool = false // 國王塔專用：受到攻擊或任一座公主塔被擊毀時啟動
    var lastShotTime: Date = Date.distantPast // 用於塔射擊特效瞬間的動畫
    
    var hpRatio: Double {
        max(0, hp / maxHp)
    }
    
    var isDestroyed: Bool {
        hp <= 0
    }
}

// MARK: - 投射飛行物 (火球術、萬箭齊發、塔弓箭、塔砲彈等飛行軌跡)
enum ProjectileType {
    case fireball        // 火球術
    case arrows          // 萬箭齊發
    case towerArrow      // 前面兩座公主塔射出的弓箭
    case towerCannonball // 中間國王塔射出的小顆砲彈
}

struct Projectile: Identifiable {
    let id: UUID = UUID()
    let type: ProjectileType
    let faction: Faction
    let startPosition: CGPoint
    let targetPosition: CGPoint
    var currentPosition: CGPoint
    let speed: CGFloat // 飛行速度 (像素/秒)
    let radius: Double
    let damage: Double
    let totalDistance: CGFloat
    var progress: CGFloat = 0.0 // 0.0 ~ 1.0
    var targetUnitId: UUID? = nil
}

// MARK: - 浮點傷害效果與擊中反饋
struct DamageEffect: Identifiable {
    let id: UUID = UUID()
    let damage: Int
    let position: CGPoint
    var opacity: Double = 1.0
    var offsetY: CGFloat = 0
    var isSpell: Bool = false
}

// MARK: - 法術著陸爆炸衝擊波
struct SpellExplosionEffect: Identifiable {
    let id: UUID = UUID()
    let type: ProjectileType
    let position: CGPoint
    let radius: CGFloat
    var scale: CGFloat = 0.3
    var opacity: Double = 1.0
}

// MARK: - 防禦塔擊中特效 (弓箭命中火花 / 砲彈爆炸衝擊)
struct TowerHitEffect: Identifiable {
    let id: UUID = UUID()
    let type: ProjectileType
    let position: CGPoint
    var scale: CGFloat = 0.3
    var opacity: Double = 1.0
}
