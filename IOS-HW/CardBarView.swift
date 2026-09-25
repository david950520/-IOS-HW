import SwiftUI

struct CardBarView: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        VStack(spacing: 8) {
            // 1. 聖水條 (Elixir Bar)
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
                        .frame(width: 30, height: 30)
                        .shadow(radius: 2)
                    Text("💧")
                        .font(.system(size: 15))
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.purple.opacity(0.2))
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(engine.playerElixir / 10.0))))
                            .animation(.linear(duration: 0.1), value: engine.playerElixir)
                    }
                }
                .frame(height: 14)
                
                Text(String(format: "%.1f / 10", engine.playerElixir))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            
            // 2. 卡牌手牌列 (4 張可選手牌 + 1 張「下一張」預覽提示)
            HStack(spacing: 10) {
                // 「下一張」卡牌提示小窗
                if let next = engine.nextCard {
                    VStack(spacing: 2) {
                        Text("下一張")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        CardItemView(card: next, isMini: true)
                    }
                    .padding(.trailing, 4)
                }
                
                // 4 張當前可用手牌
                ForEach(engine.playerHand) { card in
                    let isSelected = engine.selectedCard == card
                    let canAfford = engine.playerElixir >= Double(card.elixirCost)
                    
                    Button {
                        if canAfford {
                            if isSelected {
                                engine.selectedCard = nil
                            } else {
                                engine.selectedCard = card
                            }
                        } else {
                            engine.statusMessage = "⚡️ 聖水不足！無法選擇 \(card.name)"
                        }
                    } label: {
                        VStack(spacing: 4) {
                            CardItemView(card: card, isSelected: isSelected, canAfford: canAfford)
                            
                            Text(card.name)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(canAfford ? .white : .secondary)
                        }
                    }
                    .opacity(canAfford ? 1.0 : 0.45)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.45))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
        }
    }
}

// 單張卡牌視圖元件
struct CardItemView: View {
    let card: CardType
    var isSelected: Bool = false
    var canAfford: Bool = true
    var isMini: Bool = false
    
    var body: some View {
        let size: CGFloat = isMini ? 38 : 54
        
        ZStack(alignment: .topTrailing) {
            // 背景框
            RoundedRectangle(cornerRadius: isMini ? 8 : 10)
                .fill(
                    LinearGradient(
                        colors: card.category == .spell ? [Color.orange.opacity(0.4), Color.red.opacity(0.6)] : [Color.blue.opacity(0.3), Color.indigo.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: isMini ? 8 : 10)
                        .stroke(
                            isSelected ? Color.yellow : (canAfford ? Color.white.opacity(0.8) : Color.gray.opacity(0.4)),
                            lineWidth: isSelected ? 3 : 1.5
                        )
                )
                .shadow(color: isSelected ? .yellow.opacity(0.8) : .black.opacity(0.3), radius: isSelected ? 5 : 2)
            
            // 圖片或圖示
            if !card.imageName.isEmpty {
                Image(card.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: isMini ? 8 : 10))
            } else {
                Text(card.icon)
                    .font(.system(size: isMini ? 20 : 30))
                    .frame(width: size, height: size)
            }
            
            // 聖水消耗標籤
            Text("\(card.elixirCost)")
                .font(.system(size: isMini ? 9 : 11, weight: .black))
                .foregroundColor(.white)
                .frame(width: isMini ? 15 : 18, height: isMini ? 15 : 18)
                .background(
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                .offset(x: isMini ? 3 : 4, y: isMini ? -3 : -4)
        }
    }
}
