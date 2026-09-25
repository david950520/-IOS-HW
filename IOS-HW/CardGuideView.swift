import SwiftUI

struct CardGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: CardFilter = .all
    @State private var inspectingCard: CardType? = nil
    
    enum CardFilter: String, CaseIterable {
        case all = "全部"
        case troop = "部隊"
        case flying = "飛行"
        case spell = "法術"
        case siege = "攻城"
    }
    
    var filteredCards: [CardType] {
        switch selectedFilter {
        case .all:
            return CardType.allCases
        case .troop:
            return CardType.allCases.filter { $0.category == .troop && $0.movementType == .ground }
        case .flying:
            return CardType.allCases.filter { $0.movementType == .flying }
        case .spell:
            return CardType.allCases.filter { $0.category == .spell }
        case .siege:
            return CardType.allCases.filter { $0.targetPriority == .building }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 深色高質感漸層背景
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.12, blue: 0.22),
                        Color(red: 0.04, green: 0.06, blue: 0.14)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 頂部橫幅標題
                        VStack(spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.stack.fill")
                                    .foregroundColor(.yellow)
                                Text("卡牌圖鑑與戰術指南")
                                    .font(.title2.weight(.black))
                                    .foregroundColor(.white)
                            }
                            
                            Text("8 張經典核心卡牌深度解析，掌握每張卡牌的攻防克制！")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 10)
                        
                        // 分類篩選標籤
                        Picker("篩選", selection: $selectedFilter) {
                            ForEach(CardFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        
                        // 卡牌格狀陳列
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 14),
                                GridItem(.flexible(), spacing: 14)
                            ],
                            spacing: 16
                        ) {
                            ForEach(filteredCards) { card in
                                CardShowcaseTile(card: card) {
                                    inspectingCard = card
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 底部提示
                        Text("點擊任一卡牌以查看完整戰術屬性與實戰進攻/防守訣竅")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 10)
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("卡牌介紹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("關閉")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2), in: Capsule())
                    }
                }
            }
            .sheet(item: $inspectingCard) { card in
                CardDetailSheetView(card: card)
            }
        }
    }
}

// MARK: - 單張卡牌展示磁磚
struct CardShowcaseTile: View {
    let card: CardType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack(alignment: .topLeading) {
                    // 卡牌立繪藝術圖
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: card.category == .spell
                                        ? [Color(red: 0.45, green: 0.15, blue: 0.10), Color(red: 0.20, green: 0.05, blue: 0.05)]
                                        : [Color(red: 0.15, green: 0.25, blue: 0.40), Color(red: 0.08, green: 0.12, blue: 0.22)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        if !card.imageName.isEmpty {
                            Image(card.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 105)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black.opacity(0.4), radius: 4)
                        } else {
                            Text(card.icon)
                                .font(.system(size: 54))
                        }
                    }
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.80, blue: 0.45), Color(red: 0.60, green: 0.45, blue: 0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    
                    // 聖水滴徽章
                    HStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.pink)
                        Text("\(card.elixirCost)")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.purple.opacity(0.85), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                    .padding(6)
                }
                
                // 卡名與定位
                VStack(spacing: 3) {
                    Text(card.name)
                        .font(.headline.weight(.black))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text(card.category.title)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 4))
                        
                        Text(card.targetPriority == .building ? "攻城" : card.movementType.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.18), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.bottom, 6)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.14).opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 卡牌詳細規格與戰術解說彈窗
struct CardDetailSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let card: CardType
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // 大立繪與聖水滴
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.18, green: 0.28, blue: 0.45), Color(red: 0.08, green: 0.12, blue: 0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.yellow.opacity(0.6), lineWidth: 2)
                            )
                        
                        if !card.imageName.isEmpty {
                            Image(card.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text(card.icon)
                                .font(.system(size: 80))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        // 聖水消耗大徽章
                        HStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .font(.title3)
                                .foregroundColor(.pink)
                            Text("\(card.elixirCost)")
                                .font(.title.weight(.black))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.9), in: Capsule())
                        .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
                        .shadow(radius: 4)
                        .padding(14)
                    }
                    
                    // 卡牌名稱與基本定位
                    VStack(spacing: 6) {
                        Text(card.name)
                            .font(.title.weight(.black))
                            .foregroundColor(.white)
                        
                        Text(card.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    
                    // 屬性數值面板 (2x3 網格)
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        StatBadge(title: "生命值", value: card.maxHp > 0 ? "\(Int(card.maxHp))" : "—", icon: "heart.fill", color: .green)
                        StatBadge(title: "單次傷害", value: "\(Int(card.atk))", icon: "bolt.fill", color: .orange)
                        StatBadge(title: "攻擊間隔", value: card.attackInterval > 0 ? "\(String(format: "%.1f", card.attackInterval)) 秒" : "即時", icon: "clock.fill", color: .yellow)
                        StatBadge(title: "每秒傷害 (DPS)", value: card.dps > 0 ? "\(Int(card.dps))" : "—", icon: "flame.fill", color: .red)
                        StatBadge(title: "移動速度", value: card.speedTitle, icon: "figure.run", color: .cyan)
                        StatBadge(title: "目標偏好", value: card.targetPriority.title, icon: "target", color: .purple)
                    }
                    
                    // 戰術運用訣竅
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("實戰戰術運用指南")
                                .font(.headline.weight(.black))
                                .foregroundColor(.white)
                        }
                        
                        Text(card.strategyTip)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .padding(20)
            }
            .background(Color(red: 0.07, green: 0.10, blue: 0.18).ignoresSafeArea())
            .navigationTitle("卡牌詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.yellow)
                }
            }
        }
    }
}

// 屬性微型徽章
struct StatBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.65))
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}
