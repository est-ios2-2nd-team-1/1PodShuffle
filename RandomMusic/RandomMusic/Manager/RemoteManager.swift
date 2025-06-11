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
            guard let player = playerManager.player else { return .noActionableNowPlayingItem }

            switch player.timeControlStatus {
            case .paused:
                player.play()
                return .success
            case .waitingToPlayAtSpecifiedRate:
                player.play()
                return .success
            case .playing:
                return .success
            default:
                return .noActionableNowPlayingItem
            }
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.playerManager.pause()
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playerManager.moveForward()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playerManager.moveBackward()
            return .success
        }

        

        playerManager.onRemote = { [weak self] model in
            guard let self = self, let model = model else { return }

            var nowPlayingInfo: [String: Any] = [:]

            if let data = model.thumbnailData, let image = UIImage(data: data) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }

            nowPlayingInfo[MPMediaItemPropertyTitle] = model.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = model.artist

            if let durationSeconds = playerManager.player?.currentItem?.duration.seconds {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = durationSeconds.isNaN ? 0.0 : durationSeconds
            }

            if let durationSeconds = playerManager.player?.currentTime().seconds {
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = durationSeconds.isNaN ? 0.0 : durationSeconds
            }

            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playerManager.player?.rate ?? 1.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}
