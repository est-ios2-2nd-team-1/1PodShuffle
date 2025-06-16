import UIKit
import MediaPlayer

final class RemoteManager {
    static let shared = RemoteManager()

    let commandCenter = MPRemoteCommandCenter.shared()
    let playerManager: PlayerManager

    private init() {
        playerManager = .shared
    }
    
    /// MPRemoteCommandCenter의 초기 세팅입니다.
    func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .noActionableNowPlayingItem }
            guard let player = playerManager.player else { return .noActionableNowPlayingItem }

            switch player.timeControlStatus {
            case .paused, .waitingToPlayAtSpecifiedRate:
                player.play()
                return .success
            case .playing:
                return .success
            default:
                return .noActionableNowPlayingItem
            }
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.playerManager.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task {
                await self?.playerManager.moveForward()
            }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            _ = self?.playerManager.moveBackward()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, let player = playerManager.player else { return .noActionableNowPlayingItem }
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

            let seekTime = CMTime(seconds: event.positionTime, preferredTimescale: 1)
            player.seek(to: seekTime)

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
