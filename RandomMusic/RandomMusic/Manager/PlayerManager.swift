import AVFoundation

/// AVPlayer 기반의 오디오 재생을 관리하는 클래스입니다.
///
final class PlayerManager {
    static let shared = PlayerManager()

    private(set) var playlist: [SongModel] = []
    private(set) var currentIndex: Int = 0
    private(set) var isPlaying = false
    private(set) var player: AVPlayer?
    private var timeObserverToken: Any?

    private let preferenceManager = PreferenceManager()

    /// 한 곡 반복 재생 여부를 설정합니다.
    var isRepeatEnabled = false

    var currentSong: SongModel? {
        guard !playlist.isEmpty && currentIndex >= 0 && currentIndex < playlist.count else { return nil }
        return playlist[currentIndex]
    }

    /// 플레이어가 초기화되었는지 여부를 나타냅니다.
    var isPlayerReady: Bool {
        return player != nil
    }

    // MARK: - Callbacks

    var onTimeUpdateToMainView: ((Double) -> Void)?
    var onTimeUpdateToPlaylistView: ((Double) -> Void)?
    var onPlayStateChangedToMainView: ((Bool) -> Void)?
    var onPlayStateChangedToPlaylistView: ((Bool) -> Void)?
    var onSongChanged: (() -> Void)? // Main에서만 사용 중
    var onNeedNewSong: (() -> Void)? // Main에서만 사용 중
    var onFeedbackChanged: ((FeedbackType) -> Void)? // Main에서만 사용 중
    var onRemote: ((SongModel?) -> Void)?

    private init() {}

    // MARK: - Playlist Management
    func setPlaylist(_ value: [SongModel]) {
        playlist = value
    }

    func setCurrentIndex(_ value: Int) {
        currentIndex = value
    }

    // MARK: - Feedback Management
    /// 현재 곡의 피드백 상태를 가져옵니다.
    func getCurrentSongFeedback() -> FeedbackType {
        guard let currentSong = currentSong else { return .none }
        return preferenceManager.getUserFeedback(for: currentSong.id)
    }

    /// 좋아요 처리
    func likeSong() {
        handleFeedback(isLike: true)
    }

    /// 싫어요 처리
    func dislikeSong() {
        handleFeedback(isLike: false)
    }

    // MARK: - Playback Controls

    func play() {
        guard let currentSong = currentSong else {
            print("No current song available")
            return
        }

        guard let asset = NetworkManager.shared.createAssetWithHeaders(url: currentSong.streamUrl) else {
            print("Invalid asset")
            return
        }

        setupPlayer(with: asset)
        player?.play()
        updatePlayingState(true)
    }

    /// 현재 오디오 재생을 일시정지합니다.
    func pause() {
        player?.pause()
        updatePlayingState(false)
    }

    /// 일시정지된 오디오 재생을 다시 시작합니다.
    func resume() {
        player?.play()
        updatePlayingState(true)
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            if isPlayerReady {
                resume()
            } else {
                play()
            }
        }
    }

    func toggleRepeat() {
        isRepeatEnabled.toggle()
    }

    func moveBackward() {
        guard currentIndex > 0 else {
            print("첫번째 곡입니다.")
            return
        }

        setCurrentIndex(currentIndex - 1)
        onSongChanged?()
        play()
    }

    func moveForward() {
        if currentIndex < playlist.count - 1 {
            setCurrentIndex(currentIndex + 1)
            onSongChanged?()
            play()
        } else {
            onNeedNewSong?()
        }
    }

    /// 재생 위치를 지정한 시간으로 이동합니다.
    ///
    /// - Parameter seconds: 이동할 시간(초)입니다.
    func seek(to seconds: Float64) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player?.seek(to: time)
    }

    // MARK: - Duration Loading

    func loadDuration(completion: @escaping (Double?) -> Void) {
        guard let currentSong = currentSong else {
            print("No current song available")
            completion(nil)
            return
        }

        guard let asset = NetworkManager.shared.createAssetWithHeaders(url: currentSong.streamUrl) else {
            print("Invalid asset")
            completion(nil)
            return
        }

        Task {
            do {
                let duration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(duration)

                await MainActor.run {
                    completion(seconds.isFinite ? seconds : nil)
                }
            } catch {
                print("Duration load error: ", error)
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Private Methods

    /// 피드백 처리 (좋아요/싫어요/취소)
    private func handleFeedback(isLike: Bool) {
        guard let currentSong else {
            print("현재 재생 중인 곡이 없습니다.")
            return
        }

        let currentFeedback = getCurrentSongFeedback()
        let targetFeedback: FeedbackType = isLike ? .like : .dislike

        let newFeedback: FeedbackType

        // 이미 같은 피드백이 있는 경우 -> 취소
        if currentFeedback == targetFeedback {
            if preferenceManager.cancelFeedback(for: currentSong.id) {
                newFeedback = .none
            } else {
                newFeedback = currentFeedback
            }
        } else {
            // 새로운 피드백 등록 또는 변경
            preferenceManager.recordAction(genre: currentSong.genre, songId: currentSong.id, isLike: isLike)
            newFeedback = targetFeedback
        }

        // UI 업데이트를 위한 콜백 호출
        onFeedbackChanged?(newFeedback)
    }

    private func setupPlayer(with asset: AVURLAsset) {
        cleanupPlayer()

        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)

        setupNotifications(for: item)
        addPeriodicTimeObserver()
    }

    private func setupNotifications(for item: AVPlayerItem) {
        // 재생 완료 알림
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackEnd()
        }

        // 재생 실패 알림
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlayingState(false)
        }
    }

    private func handlePlaybackEnd() {
        if self.isRepeatEnabled {
            self.seek(to: 0)
            self.player?.play()
        } else {
            self.updatePlayingState(false)
            self.moveForward()
        }
    }

    private func updatePlayingState(_ playing: Bool) {
        isPlaying = playing
        onPlayStateChangedToMainView?(playing)
        onPlayStateChangedToPlaylistView?(playing)
    }

    /// 재생 시간 정보를 주기적으로 업데이트합니다.
    private func addPeriodicTimeObserver() {
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            onTimeUpdateToMainView?(seconds)
            onTimeUpdateToPlaylistView?(seconds)
            onRemote?(currentSong)
        }
    }

    private func cleanupPlayer() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }

        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        cleanupPlayer()
    }
}
