import SwiftUI
import CoreText

extension Font {
    static func battle(_ size: CGFloat) -> Font {
        .custom("BlackOpsOne-Regular", size: size)
    }
}

@main struct MyApp: App {
    @StateObject private var audioManager = AudioManager.shared

    init() {
        UserDefaults.standard.register(defaults: [
            "backgroundMusicEnabled": true,
            "musicVolume": 0.8
        ])
        registerBattleFont()
    }

    private func registerBattleFont() {
        guard let fontURL = Bundle.main.url(forResource: "BlackOpsOne-Regular", withExtension: "ttf") else {
            return
        }

        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }

    var body: some Scene {
        WindowGroup {
            GameHubView()
                .onAppear {
                    audioManager.updatePlayback()
                }
        }
    }
}
