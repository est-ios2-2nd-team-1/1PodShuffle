import UIKit
import MediaPlayer

final class RemoteManager {
    static let shared = RemoteManager()

    let commandCenter = MPRemoteCommandCenter.shared()
    var playerManager: PlayerManager

    private init() {
        playerManager = .shared
    }

    func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .noActionableNowPlayingItem }
            // TODO: PlayerManager에게 재생을 요청해야 한다 어떻게?

            // 현재 플레이중일 때

            // 현재 pause 상태일 때

            // stop상태일 때

            // self?.playerManager?.play()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .noActionableNowPlayingItem }
            playerManager.pause()
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { _ in
            // TODO: PlayManager에 이전 곡을 요청해야 한다.
            // self?.playerManager
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { _ in
			// TODO: PlayManager에 다음 곡을 요청해야 한다.
            // self?.playerManager?.next()
            return .success
        }

        // TODO: 아래있는 작업은 아마도 PlayerManager에서 곡이 바뀔 때 데이터를 바인딩해서 받아와야 할 거 같습니다.
        // TODO: (곡의 메타 데이터가 들어가기 때문에)
        var nowPlayingInfo: [String: Any] = [:]
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Hello" // 곡 제목
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Muse" // 아티스트 이름
        // TODO: 아래 있는 작업은 AVPlayer 객체를 사용해서 작업해야 합니다.
        //nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = -> 총 재생 시간 (초) (Double) (player.currentItem.duration)
        //nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = -> 현재 재생 위치 (초) (Double) (player.currentTime)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0 // 재생 속도

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
