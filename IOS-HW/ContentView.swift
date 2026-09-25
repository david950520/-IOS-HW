import SwiftUI

struct ContentView: View {
    @StateObject private var engine: GameEngine
    let level: Int
    var onExit: (() -> Void)? = nil
    @State private var showRulesSheet = false
    
    init(level: Int = 1, onExit: (() -> Void)? = nil) {
        self.level = level
        self.onExit = onExit
        _engine = StateObject(wrappedValue: GameEngine(level: level))
    }
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                gradient: Gradient(colors: engine.arena.backgroundColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // 1. 頂部記分板與資訊欄
                HeaderScoreView(engine: engine, showRulesSheet: $showRulesSheet)
                
                // 2. 戰場主畫面 (雙方三座塔安置在圖片上的三個大正方形，前面兩座射弓箭，中間國王塔砲彈)
                BattlefieldView(engine: engine)
                    .padding(.horizontal, 12)
                
                // 3. 底部卡牌選擇列與聖水計
                CardBarView(engine: engine)
            }
            .padding(.vertical, 4)

            if engine.isElixirAnnouncementVisible {
                DoubleElixirAnnouncementView(
                    title: engine.elixirAnnouncementTitle,
                    detail: engine.elixirAnnouncementDetail
                )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
            
            // 遊戲結束結算彈窗
            if engine.gameStatus == .victory || engine.gameStatus == .defeat {
                GameOverOverlay(engine: engine, onExit: onExit)
            }

            if let onExit {
                VStack {
                    HStack {
                        Text("第 \(level) 關・\(engine.arena.title)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.35), in: Capsule())

                        Spacer()

                        Button(action: onExit) {
                            Label("大廳", systemImage: "house.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.black.opacity(0.35), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showRulesSheet) {
            CardGuideView()
        }
        .task {
            if engine.gameStatus == .idle {
                engine.startGame()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: engine.isElixirAnnouncementVisible)
    }
}

struct DoubleElixirAnnouncementView: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.battle(24))
            Text(detail)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(colors: [.purple, .pink, .orange], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.8), lineWidth: 2)
        }
        .shadow(color: .purple.opacity(0.7), radius: 12)
    }
}

// MARK: - 頂部對戰狀態列
struct HeaderScoreView: View {
    @ObservedObject var engine: GameEngine
    @Binding var showRulesSheet: Bool
    
    var body: some View {
        HStack {
            // AI 皇冠
            HStack(spacing: 4) {
                Text("👑")
                    .font(.title2)
                Text("\(engine.aiCrowns)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.4))
            .cornerRadius(12)
            
            Spacer()
            
            // 倒數計時與狀態提示
            VStack(spacing: 2) {
                Text(timeString(from: engine.remainingTime))
                    .font(.battle(24))
                    .foregroundColor(engine.remainingTime <= 30 ? .red : .white)
                
                Text(engine.statusMessage)
                    .font(.battle(13))
                    .foregroundColor(.yellow)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 規則說明按鈕
            Button {
                showRulesSheet = true
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.trailing, 4)
            
            // 玩家皇冠
            HStack(spacing: 4) {
                Text("\(engine.playerCrowns)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.blue)
                Text("👑")
                    .font(.title2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.4))
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
    
    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - 遊戲結算彈窗
struct GameOverOverlay: View {
    @ObservedObject var engine: GameEngine
    var onExit: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(engine.gameStatus == .victory ? "🏆 勝利！" : "💀 失敗！")
                    .font(.system(size: 42, weight: .black))
                    .foregroundColor(engine.gameStatus == .victory ? .yellow : .red)
                    .shadow(radius: 10)
                
                HStack(spacing: 24) {
                    VStack {
                        Text("你的皇冠")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(engine.playerCrowns)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    Text("VS")
                        .font(.title2.weight(.black))
                        .foregroundColor(.gray)
                    
                    VStack {
                        Text("敵方皇冠")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(engine.aiCrowns)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                
                Text(engine.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 16) {
                    Button("再來一局") {
                        engine.startGame()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(25)
                    .shadow(radius: 5)

                    if let onExit {
                        Button("返回大廳") {
                            onExit()
                        }
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                    }
                }
            }
            .padding(32)
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(engine.gameStatus == .victory ? Color.yellow : Color.red, lineWidth: 3)
            )
            .padding(24)
        }
    }
}

#Preview {
    ContentView()
}
