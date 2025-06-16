import AVFoundation

/// AVPlayer 기반의 오디오 재생을 관리하는 클래스입니다.
///
final class PlayerManager {
    static let shared = PlayerManager()

    private let songService: SongService
    private let preferenceManager: PreferenceManager

    private(set) var player: AVPlayer?
    private(set) var playlist: [SongModel] = [] {
        didSet { onPlayListChanged?() }
    }
    private(set) var currentIndex: Int = 0
    private(set) var isPlaying = false
    private(set) var currentPlaybackTime: Double?

    var isRepeatEnabled = false
    var currentPlaybackSpeed: Float = 1.0

    private var timeObserverToken: Any?

    var currentSong: SongModel? {
        guard !playlist.isEmpty && currentIndex >= 0 && currentIndex < playlist.count else { return nil }
        return playlist[currentIndex]
    }

    // MARK: - Callbacks
    var onTimeUpdateToPlaylistView: ((Double) -> Void)? {
        didSet { onTimeUpdateToPlaylistView?(currentPlaybackTime ?? 0.0) }
    }
    var onTimeUpdateToMainView: ((Double) -> Void)?
    var onPlayStateChangedToMainView: ((Bool) -> Void)?
    var onPlayStateChangedToPlaylistView: ((Bool) -> Void)?
    var onSongChangedToMainView: (() -> Void)?
    var onSongChangedToPlaylistView: (() -> Void)?
    var onFeedbackChanged: ((FeedbackType) -> Void)?
    var onRemote: ((SongModel?) -> Void)?
    var onPlayListChanged: (() -> Void)?

    private init(songService: SongService = SongService(), preferenceManager: PreferenceManager = PreferenceManager()) {
        self.songService = songService
        self.preferenceManager = preferenceManager
        loadPlaylistFromDB()
    }

    /// 플레이리스트 초기화를 완료합니다. UI가 준비된 후 호출해야 합니다.
    func initializePlaylistIfNeeded() async {
        if playlist.isEmpty {
            print("플레이리스트가 비어있어서 랜덤곡을 추가합니다.")
            await addRandomSong()
            onSongChangedToMainView?()
            onSongChangedToPlaylistView?()
        }
    }

    // MARK: - Playback Controls
    func play() {
        guard let currentSong = currentSong else {
            print("No current song available")
            return
        }

        guard let asset = try? songService.createAssetWithHeaders(url: currentSong.streamUrl) else {
            print("Invalid asset")
            return
        }

        setupPlayer(with: asset)
        player?.play()
        player?.rate = currentPlaybackSpeed
        updatePlayingState(true)
        UserDefaults.standard.set(currentIndex, forKey: "heardLastSong")
    }

    /// 현재 오디오 재생을 일시정지합니다.
    func pause() {
        player?.pause()
        updatePlayingState(false)
    }

    /// 일시정지된 오디오 재생을 다시 시작합니다.
    func resume() {
        player?.play()
        player?.rate = currentPlaybackSpeed
        updatePlayingState(true)
    }

    func togglePlayPause() {
        isPlaying ? pause() : player != nil ? resume() : play()
    }

    func toggleRepeat() {
        isRepeatEnabled.toggle()
    }

    func moveBackward() -> Bool {
        if currentPlaybackTime ?? 0 < 3.0 {
            if currentIndex == 0 {
                return false
            } else {
                setCurrentIndex(currentIndex - 1)
            	play()
            	return true
        	}
    	} else {
        	seek(to: 0)
            play()
            return true
    	}
    }

    func moveForward() async {
        currentIndex < playlist.count - 1 ? setCurrentIndex(currentIndex + 1) : await addRandomSong()
        Task { @MainActor in play() }
    }

    /// 재생 위치를 지정한 시간으로 이동합니다.
    ///
    /// - Parameter seconds: 이동할 시간(초)입니다.
    func seek(to seconds: Float64) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player?.seek(to: time)
    }

    func setPlaylist(_ value: [SongModel]) {
        playlist = value
    }

    func setCurrentIndex(_ value: Int) {
        currentIndex = max(0, value)
        onSongChangedToMainView?()
        onSongChangedToPlaylistView?()
    }

    /// 장르별로 10곡을 추가합니다.
    /// - Parameter genre: 장르를 받습니다.
    func addSongs(from genre: Genre) {
        Task {
            let songs = try await songService.getMusics(genre: genre)
            songs.forEach { DataManager.shared.insertSongData(from: $0) }
            playlist.append(contentsOf: songs)
        }
    }

    /// 랜덤 곡을 가져와서 플레이리스트에 추가합니다.
    func addRandomSong() async {
        do {
            let song = try await songService.getMusic()

            await MainActor.run {
                let newIndex = playlist.count
                DataManager.shared.insertSongData(from: song)
                playlist.append(song)
                setCurrentIndex(newIndex)
            }
        } catch {
            print("랜덤 곡 추가 실패: \(error)")
        }
    }

    /// 플레이리스트에서 곡을 제거합니다.
    func removeSong(at index: Int) {
        guard index >= 0 && index < playlist.count else { return }
        
        DataManager.shared.deleteSongData(to: playlist[index])
        playlist.remove(at: index)

        if playlist.isEmpty {
            handleEmptyPlaylist()
        } else {
            handleSongRemoval(at: index)
        }
    }
    
    /// 플레이리스트 순서를 업데이트합니다
    func updateOrder(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < playlist.count,
              destinationIndex >= 0, destinationIndex <= playlist.count else { return }
        
        var newList = playlist
        let movedSong = newList.remove(at: sourceIndex)
        newList.insert(movedSong, at: destinationIndex)
        setPlaylist(newList)
        
        // CoreData 반영 (DataManager가 영구저장 책임)
        DataManager.shared.updateOrder(for: playlist)
        
        /// 현재 재생 중인 곡 인덱스 보정
        if currentIndex == sourceIndex {
            // 이동된 곡이 현재 재생 중인 곡인 경우
            setCurrentIndex(destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex)
        } else if sourceIndex < currentIndex && destinationIndex >= currentIndex {
            // 현재 곡보다 앞에서 뒤로 이동한 경우
            setCurrentIndex(currentIndex - 1)
        } else if sourceIndex > currentIndex && destinationIndex <= currentIndex {
            // 현재 곡보다 뒤에서 앞으로 이동한 경우
            setCurrentIndex(currentIndex + 1)
        }
    }

    /// 플레이리스트를 초기화합니다.
    func clearPlaylist() {
        pause()
        cleanupPlayer()

        for song in playlist {
            DataManager.shared.deleteSongData(to: song)
        }
        playlist.removeAll()
        UserDefaults.standard.set(0, forKey: "heardLastSong")
        currentIndex = 0
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

    /// 노래의 전체 시간을 반환합니다.
    /// - Parameter completion: Completion 콜백 메소드입니다. 원하시는 작업을 입력해주세요.
    func loadDuration() async -> Double? {
        print(#function)
        guard let currentSong = currentSong else { return nil }

        guard let asset = try? songService.createAssetWithHeaders(url: currentSong.streamUrl) else {
            return nil
        }

        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return seconds.isFinite ? seconds : nil
        } catch {
            print("Duration load error: ", error)
            return nil
        }
    }

    deinit {
        cleanupPlayer()
    }
}

// MARK: - Private Methods
private extension PlayerManager {
    /// 앱 시작 시 DataManager에서 playlist를 로드합니다.
    private func loadPlaylistFromDB() {
        let savedSongs = DataManager.shared.fetchSongData()
        playlist = savedSongs
        currentIndex = UserDefaults.standard.integer(forKey: "heardLastSong")
    }

    private func handleEmptyPlaylist() {
        pause()
        cleanupPlayer()
        notifySongChanged()
    }

    private func handleSongRemoval(at index: Int) {
        if index == currentIndex {
            // 현재 재생 중인 곡이 삭제되는 경우
            handleCurrentSongRemoval(at: index)
        } else if index < currentIndex {
            // 현재 곡보다 앞의 곡이 삭제되면 인덱스 조정
            currentIndex -= 1
            notifySongChanged()
        }
    }

    private func handleCurrentSongRemoval(at index: Int) {
        if playlist.count > 1 {
            // 다음 곡으로 이동 (마지막 곡이면 이전 곡으로)
            if index == playlist.count {
                currentIndex = max(0, playlist.count - 1)
            } else {
                currentIndex = index
            }
        } else {
            currentIndex = 0
        }

        notifySongChanged()

        if isPlaying {
            play()
        } else {
            player = nil
        }
    }

    /// 피드백 처리 (좋아요/싫어요/취소)
    func handleFeedback(isLike: Bool) {
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

    private func notifySongChanged() {
        onSongChangedToMainView?()
        onSongChangedToPlaylistView?()
    }

    func setupPlayer(with asset: AVURLAsset) {
        cleanupPlayer()

        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        setupNotifications(for: item)
        addPeriodicTimeObserver()
    }

    func setupNotifications(for item: AVPlayerItem) {
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

    func handlePlaybackEnd() {
        if self.isRepeatEnabled {
            self.seek(to: 0)
            self.player?.play()
        } else {
            self.updatePlayingState(false)
            Task { @MainActor in
                await self.moveForward()
            }
        }
    }

    func updatePlayingState(_ playing: Bool) {
        isPlaying = playing
        onPlayStateChangedToMainView?(playing)
        onPlayStateChangedToPlaylistView?(playing)
    }

    /// 재생 시간 정보를 주기적으로 업데이트합니다.
    func addPeriodicTimeObserver() {
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            currentPlaybackTime = Double(seconds)
            onTimeUpdateToMainView?(seconds)
            onTimeUpdateToPlaylistView?(seconds)
            onRemote?(currentSong)
        }
    }

    func cleanupPlayer() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }

        NotificationCenter.default.removeObserver(self)
    }

}
