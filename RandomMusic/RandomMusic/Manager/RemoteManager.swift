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
        commandCenter.playCommand.addTarget { [weak self] _ in
            // TODO: PlayerManager에게 재생을 요청해야 한다 어떻게?
            // self?.playerManager?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            // TODO: PlayManager에 퍼즈를 요청해야 한다.
            self?.playerManager?.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { _ in
            // TODO: PlayManager에 이전 곡을 요청해야 한다.
            //self?.playerManager?.before()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { _ in
			// TODO: PlayManager에 다음 곡을 요청해야 한다.
            // self?.playerManager?.next()
            return .success
        }
    }
}
