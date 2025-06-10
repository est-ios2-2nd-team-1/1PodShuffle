import UIKit
import MediaPlayer

final class RemoteManager {
    static let shared = RemoteManager()

    let commandCenter = MPRemoteCommandCenter.shared()
    var playerManager: PlayerManager?

    private init() {
        playerManager = .shared
    }

    func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            // TODO: PlayerManager에게 재생을 요청해야 한다 어떻게?
            // self?.playerManager?.play()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            // TODO: PlayManager에 퍼즈를 요청해야 한다.
            self?.playerManager?.pause()
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { _ in
            // TODO: PlayManager에 이전 곡을 요청해야 한다.
            //self?.playerManager?.before()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { _ in
			// TODO: PlayManager에 다음 곡을 요청해야 한다.
            // self?.playerManager?.next()
            return .success
        }

        var nowPlayingInfo: [String: Any] = [:]
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Hello" // 곡 제목
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Muse" // 아티스트 이름
        //nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = -> 총 재생 시간 (초)
        //nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = -> 현재 재생 위치 (초)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0 // 재생 속도

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
