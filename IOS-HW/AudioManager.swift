import SwiftUI
import AVFoundation
import Combine

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    @AppStorage("backgroundMusicEnabled") var isEnabled: Bool = true {
        didSet {
            updatePlayback()
        }
    }
    
    @AppStorage("musicVolume") var volume: Double = 0.8 {
        didSet {
            audioPlayer?.volume = Float(volume)
        }
    }
    
    private init() {
        configureAudioSession()
        setupAudioPlayer()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音訊設定失敗: \(error.localizedDescription)")
        }
    }
    
    func setupAudioPlayer() {
        let musicNames = [
            "皇室戰爭 背景音樂 (Clash Royale Music )",
            "皇室戰爭 背景音樂",
            "Clash Royale Music"
        ]
        
        var musicURL: URL? = nil
        for name in musicNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
                musicURL = url
                break
            }
        }
        
        // 如果檔名有微小差異，從 Bundle 搜尋所有 mp3
        if musicURL == nil {
            if let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) {
                musicURL = urls.first(where: { $0.lastPathComponent.contains("皇室戰爭") || $0.lastPathComponent.contains("Music") }) ?? urls.first
            }
        }
        
        guard let finalURL = musicURL else {
            print("⚠️ 未找到背景音樂檔案")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: finalURL)
            audioPlayer?.numberOfLoops = -1 // 無限循環播放
            audioPlayer?.volume = Float(volume)
            audioPlayer?.prepareToPlay()
            if isEnabled {
                audioPlayer?.play()
            }
        } catch {
            print("⚠️ 音訊播放器初始化失敗: \(error.localizedDescription)")
        }
    }
    
    func updatePlayback() {
        if isEnabled {
            if audioPlayer == nil {
                setupAudioPlayer()
            }
            audioPlayer?.volume = Float(volume)
            audioPlayer?.play()
        } else {
            audioPlayer?.pause()
        }
    }
    
    func toggleMute() {
        isEnabled.toggle()
    }
    
    func setVolume(_ newVolume: Double) {
        volume = max(0.0, min(1.0, newVolume))
        if volume > 0 && !isEnabled {
            isEnabled = true
        } else if volume == 0 && isEnabled {
            isEnabled = false
        }
    }
}
