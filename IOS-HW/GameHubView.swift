import SwiftUI

struct GameHubView: View {
    @AppStorage("backgroundMusicEnabled") private var backgroundMusicEnabled = true
    @AppStorage("musicVolume") private var musicVolume = 0.8
    @State private var isShowingSettings = false
    @State private var isShowingCardGuide = false
    @State private var isShowingBattle = false
    @State private var selectedLevel = 1

    var body: some View {
        ZStack {
            // 初始頁面背景圖
            Image("初始頁面背景")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 漸層覆蓋層，確保文字與按鈕清晰易讀
            LinearGradient(
                colors: [
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                ArenaTitleView()

                Text("選擇競技場後立即開戰")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(radius: 3)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                    spacing: 12
                ) {
                    ForEach(ArenaLevel.all) { arena in
                        Button {
                            selectedLevel = arena.number
                            isShowingBattle = true
                        } label: {
                            ArenaLevelTile(arena: arena)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)

                // 卡牌介紹跳轉至專屬精美卡牌圖鑑頁面
                Button {
                    isShowingCardGuide = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.stack.fill")
                            .foregroundColor(.yellow)
                        Text("卡牌介紹與戰術圖鑑")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.85), Color.red.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.8), lineWidth: 1.5))
                    .shadow(color: .orange.opacity(0.5), radius: 8, y: 3)
                }
                .padding(.top, 4)

                Button {
                    isShowingSettings = true
                } label: {
                    Label(
                        backgroundMusicEnabled ? "背景音樂・音量" : "背景音樂已關閉",
                        systemImage: backgroundMusicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.48), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))
                }

                Text("拖曳卡牌至戰場，摧毀敵方塔樓！")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.bottom, 16)
            }
        }
        .fullScreenCover(isPresented: $isShowingBattle) {
            ContentView(level: selectedLevel) {
                isShowingBattle = false
            }
        }
        .fullScreenCover(isPresented: $isShowingCardGuide) {
            CardGuideView()
        }
        .sheet(isPresented: $isShowingSettings) {
            SoundSettingsView(
                backgroundMusicEnabled: $backgroundMusicEnabled,
                musicVolume: $musicVolume
            )
                .presentationDetents([.medium])
        }
    }
}

struct ArenaLevelTile: View {
    let arena: ArenaLevel

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: arena.icon)
                .font(.title2)
            Text("第 \(arena.number) 關")
                .font(.battle(19))
            Text(arena.title)
                .font(.battle(15))
            Text(arena.subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(colors: arena.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
    }
}

struct ArenaTitleView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
                .shadow(color: .orange.opacity(0.9), radius: 10)

            Text("皇室戰場")
                .font(.battle(42))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 3)

            Text("CLASH ARENA")
                .font(.battle(17))
                .tracking(3)
                .foregroundStyle(.yellow.opacity(0.95))
        }
    }
}

struct SoundSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var backgroundMusicEnabled: Bool
    @Binding var musicVolume: Double

    var body: some View {
        NavigationStack {
            Form {
                Section("音樂設定") {
                    Toggle(isOn: Binding(
                        get: { backgroundMusicEnabled },
                        set: { enabled in
                            backgroundMusicEnabled = enabled
                            AudioManager.shared.isEnabled = enabled
                        }
                    )) {
                        Label("背景音樂", systemImage: "music.note")
                    }

                    HStack {
                        Label("音量", systemImage: "speaker.wave.2")
                        Slider(value: Binding(
                            get: { musicVolume },
                            set: { volume in
                                musicVolume = volume
                                AudioManager.shared.setVolume(volume)
                            }
                        ), in: 0...1)
                    }
                }

                Section {
                    Text("開啟後將於主畫面與對戰中播放熱血皇室背景音樂。")
                        .font(.footnote)
                }
            }
            .navigationTitle("音效設定")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
