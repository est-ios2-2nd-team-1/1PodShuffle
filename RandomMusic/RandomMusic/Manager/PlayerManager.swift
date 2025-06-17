import AVFoundation

extension Notification.Name {
    /// 현재 재생 중인 곡이 변경되었을 때 발생하는 알림
        static let currentSongChanged = Notification.Name("CurrentSongChanged")
    /// 피드백 상태가 변경되었을 때 발생하는 알림
    static let feedbackChanged = Notification.Name("FeedbackChanged")
    /// 재생 상태가 변경되었을 때 발생하는 알림
    static let playStateChanged = Notification.Name("PlayStateChanged")
    /// 재생 시간이 변경되었을 때 발생하는 알림
    static let playbackTimeChanged = Notification.Name("PlaybackTimeChanged")
    /// 플레이리스트가 변경되었을 때 발생하는 알림
    static let playlistChanaged = Notification.Name("PlaylistChanaged")
}

/// AVPlayer 기반의 오디오 재생을 관리하는 클래스입니다.
///
/// 싱글톤 패턴을 사용하여 전체 앱에서 오디오 재생을 관리합니다.
/// 플레이리스트 관리, 재생 제어, 피드백 처리 등의 기능을 제공합니다.
final class PlayerManager {
    /// PlayerManager의 공유 인스턴스
    static let shared = PlayerManager()

    private let songService: SongService
    private let preferenceManager: PreferenceManager

    /// 현재 사용 중인 AVPlayer 인스턴스
    private(set) var player: AVPlayer?

    /// 현재 플레이리스트
    ///
    /// 플레이리스트가 변경될 때마다 `.playlistChanaged` 알림이 발생합니다.
    private(set) var playlist: [SongModel] = [] {
        didSet { NotificationCenter.default.post(name: .playlistChanaged, object: nil) }
    }

    /// 현재 재생 중인 곡의 인덱스
    private(set) var currentIndex: Int = 0

    /// 현재 재생 상태
    private(set) var isPlaying = false

    /// 현재 재생 시간 (초 단위)
    private(set) var currentPlaybackTime: Double = 0.0

    private var timeObserverToken: Any?

    /// 반복 재생 활성화 여부
    var isRepeatEnabled = false

    /// 현재 재생 속도
    var currentPlaybackSpeed: Float = 1.0

    /// 현재 재생 중인 곡
    var currentSong: SongModel? {
        guard !playlist.isEmpty && isValidIndex(currentIndex) else { return nil }
        return playlist[currentIndex]
    }

    private init(songService: SongService = SongService(), preferenceManager: PreferenceManager = PreferenceManager()) {
        self.songService = songService
        self.preferenceManager = preferenceManager
        loadPlaylistFromDB()
    }

    var onRemote: ((SongModel?) -> Void)?

    /// 플레이리스트 초기화를 완료합니다.
    ///
    /// 플레이리스트가 비어있는 경우 랜덤곡을 추가합니다.
    func initializePlaylistIfNeeded() async {
        if playlist.isEmpty {
            print("플레이리스트가 비어있어서 랜덤곡을 추가합니다.")
            await addRandomSong()
            notifySongChanged()
        }
    }

    // MARK: - Playback Controls

    /// 현재 곡을 재생합니다.
    ///
    /// 현재 곡이 없거나 유효하지 않은 에셋인 경우 재생이 시작되지 않습니다.
    /// 재생이 시작되면 마지막 재생 곡 정보를 저장합니다.
    func play() {
        guard let currentSong else {
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
        saveLastPlayedSong()
    }

    /// 현재 오디오 재생을 일시정지합니다.
    ///
    /// 재생 상태가 변경되면 `.playStateChanged` 알림이 발생합니다.
    func pause() {
        player?.pause()
        updatePlayingState(false)
    }

    /// 일시정지된 오디오 재생을 다시 시작합니다.
    ///
    /// 현재 재생 속도로 재생을 재개하며, 재생 상태가 변경되면 `.playStateChanged` 알림이 발생합니다.
    func resume() {
        player?.play()
        player?.rate = currentPlaybackSpeed
        updatePlayingState(true)
    }

    /// 재생/일시정지를 토글합니다.
    ///
    /// 현재 재생 중이면 일시정지하고, 일시정지 중이면 재생을 재개합니다.
    /// 플레이어가 없는 경우 새로 재생을 시작합니다.
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if player != nil {
            resume()
        } else {
            play()
        }
    }

    /// 반복 재생 모드를 토글합니다.
    func toggleRepeat() {
        isRepeatEnabled.toggle()
    }

    /// 이전 곡으로 이동하거나 현재 곡을 처음부터 재생합니다.
    ///
    /// 재생 시간이 3초 미만인 경우 이전 곡으로 이동하고,
    /// 3초 이상인 경우 현재 곡을 처음부터 재생합니다.
    ///
    /// - Returns: 작업이 성공적으로 수행되었는지 여부
    func moveBackward() -> Bool {
        if currentPlaybackTime < 3.0 {
            return moveToPreviousSong()
    	} else {
        	seek(to: 0)
            play()
            return true
    	}
    }

    /// 다음 곡으로 이동합니다.
    ///
    /// 플레이리스트의 마지막 곡인 경우 랜덤곡을 추가한 후 재생합니다.
    func moveForward() async {
        if currentIndex < playlist.count - 1 {
            setCurrentIndex(currentIndex + 1)
        } else {
            await addRandomSong()
        }

        await MainActor.run {
            play()
        }
    }

    /// 재생 위치를 지정한 시간으로 이동합니다.
    ///
    /// - Parameter seconds: 이동할 시간(초)
    func seek(to seconds: Float64) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player?.seek(to: time)
    }

    /// 플레이리스트를 설정합니다.
    ///
    /// - Parameter value: 새로운 플레이리스트
    func setPlaylist(_ value: [SongModel]) {
        playlist = value
    }

	/// 현재 곡의 인덱스를 설정합니다.
    ///
    /// - Parameter value: 새로운 인덱스 (0 이상의 값으로 제한됨)
    func setCurrentIndex(_ value: Int) {
        currentIndex = max(0, value)
        notifySongChanged()
    }

    /// 노래를 한 곡 추가합니다.
    ///
    /// - Parameter song: 추가할 노래
    func addSong(_ song: SongModel) {
        playlist.append(song)
        Task {
            await Toast.shared.showToast(message: "\(song.title)이 추가되었습니다.")
        }
    }

    /// 장르별로 10곡을 추가합니다.
    ///
    /// 비동기적으로 곡을 가져와서 플레이리스트에 추가하고 데이터베이스에도 저장합니다.
    ///
    /// - Parameter genre: 추가할 곡의 장르
    func addSongs(from genre: Genre) {
        Task {
            do {
                let songs = try await songService.getMusics(genre: genre)
                songs.forEach { DataManager.shared.insertSongData(from: $0) }
                playlist.append(contentsOf: songs)
                await Toast.shared.showToast(message: "\(genre.rawValue) \(songs.count)곡이 추가되었습니다.")
            } catch {
                print("장르별 곡 추가 실패: \(error)")
            }
        }
    }

    /// 랜덤 곡을 가져와서 플레이리스트에 추가합니다.
    ///
    /// 비동기적으로 랜덤곡을 가져와서 플레이리스트 끝에 추가하고,
    /// 현재 인덱스를 새로 추가된 곡으로 설정합니다.
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
    ///
    /// 곡을 제거하면 데이터베이스에도 삭제되며, 현재 재생 중인 곡의 인덱스가 적절히 조정됩니다.
    /// 플레이리스트가 비게 되면 재생을 중지합니다.
    ///
    /// - Parameter index: 제거할 곡의 인덱스
    func removeSong(at index: Int) {
        guard isValidIndex(index) else { return }

        // 현재 재생 중인 곡은 삭제하지 않음
        if index == currentIndex {
            Task {
                await Toast.shared.showToast(message: "현재 재생 중인 곡은 삭제할 수 없습니다.")
            }
            return
        }

        DataManager.shared.deleteSongData(to: playlist[index])
        playlist.remove(at: index)

        if playlist.isEmpty {
            handleEmptyPlaylist()
        } else {
            handleSongRemoval(at: index)
        }
    }
    
    /// 플레이리스트 순서를 업데이트합니다.
    ///
    /// 곡의 순서를 변경하고 데이터베이스에 반영합니다.
    /// 현재 재생 중인 곡의 인덱스도 적절히 보정됩니다.
    ///
    /// - Parameters:
    /// 	- sourceIndex: 이동할 곡의 현재 인덱스
    /// 	- destinationIndex: 이동할 목표 인덱스
    func updateOrder(from sourceIndex: Int, to destinationIndex: Int) {
        guard isValidOrderUpdate(sourceIndex: sourceIndex, destinationIndex: destinationIndex) else { return }

        var newList = playlist
        let movedSong = newList.remove(at: sourceIndex)
        newList.insert(movedSong, at: destinationIndex)
        setPlaylist(newList)
        
        // CoreData 반영 (DataManager가 영구저장 책임)
        DataManager.shared.updateOrder(for: playlist)
        
        /// 현재 재생 중인 곡 인덱스 보정
        updateCurrentIndexAfterReorder(sourceIndex: sourceIndex, destinationIndex: destinationIndex)
    }

    /// 플레이리스트를 초기화합니다.
    ///
    /// 모든 곡을 제거하고, 재생을 중지하며, 저장된 마지막 재생 곡 정보도 초기화합니다.
    func clearPlaylist() {
        let preservedSong = currentSong // 현재 재상중
        playlist.enumerated().forEach { index, song in
            if song != preservedSong {
                DataManager.shared.deleteSongData(to: song)
            }
        }

        playlist = preservedSong.map { [$0] } ?? []
        currentIndex = 0
        UserDefaults.standard.set(currentIndex, forKey: "heardLastSong")

        NotificationCenter.default.post(name: .playlistChanaged, object: nil)
    }

    // MARK: - Feedback Management

    /// 현재 곡의 피드백 상태를 가져옵니다.
    ///
    /// - Returns: 현재 곡의 피드백 상태 (좋아요/싫어요/없음)
    func getCurrentSongFeedback() -> FeedbackType {
        guard let currentSong else { return .none }
        return preferenceManager.getUserFeedback(for: currentSong.id)
    }

    /// 현재 곡에 좋아요를 표시합니다.
    ///
    /// 이미 좋아요가 표시된 경우 좋아요를 취소합니다.
    /// 피드백이 변경되면 `.feedbackChanged` 알림이 발생합니다.
    func likeSong() {
        handleFeedback(isLike: true)
    }

    /// 현재 곡에 싫어요를 표시합니다.
    ///
    /// 이미 싫어요가 표시된 경우 싫어요를 취소합니다.
    /// 피드백이 변경되면 `.feedbackChanged` 알림이 발생합니다.
    func dislikeSong() {
        handleFeedback(isLike: false)
    }

    /// 현재 곡의 전체 재생 시간을 반환합니다.
    ///
    /// 비동기적으로 오디오 에셋의 duration을 로드합니다.
    ///
    /// - Returns: 전체 재생 시간(초), 로드 실패시 `nil`
    func loadDuration() async -> Double? {
        guard let currentSong else { return nil }

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
    private enum Constants {
        // 이전곡으로 이동하는 기준 시간 (초)
        static let backwardThreshold = 3.0
        /// 마지막 재생 곡을 저장하는 UserDefaults 키
        static let lastSongKey = "heardLastSong"
    }

    /// 앱 시작 시 DataManager에서 playlist를 로드합니다.
    ///
    /// 저장된 플레이리스트와 마지막 재생 곡 인덱스를 복원합니다.
    func loadPlaylistFromDB() {
        let savedSongs = DataManager.shared.fetchSongData()
        playlist = savedSongs
        currentIndex = UserDefaults.standard.integer(forKey: Constants.lastSongKey)
    }

    /// 이전 곡으로 이동합니다.
    ///
    /// - Returns: 이동 성공 여부 (첫 번째 곡인 경우 `false`)
    func moveToPreviousSong() -> Bool {
        guard currentIndex > 0 else { return false }

        setCurrentIndex(currentIndex - 1)
        play()
        return true
    }

    /// 현재 재생 중인 곡의 인덱스를 UserDefaults에 저장합니다.
    func saveLastPlayedSong() {
        UserDefaults.standard.set(currentIndex, forKey: Constants.lastSongKey)
    }

    /// 주어진 인덱스가 유효한지 확인합니다.
    ///
    /// - Parameter index: 확인할 인덱스
    /// - Returns: 유효한 인덱스인지 여부
    func isValidIndex(_ index: Int) -> Bool {
        return index >= 0 && index < playlist.count
    }

    /// 순서 변경 작업이 유효한지 확인합니다.
    ///
    /// - Parameters:
    ///     - sourceIndex: 출발 인덱스
    /// 	- destinationIndex: 목표 인덱스
 	/// - Returns: 유효한 작업인지 여부
    func isValidOrderUpdate(sourceIndex: Int, destinationIndex: Int) -> Bool {
        return sourceIndex != destinationIndex &&
               isValidIndex(sourceIndex) &&
               destinationIndex >= 0 && destinationIndex <= playlist.count
    }

    /// 플레이리스트가 비어있을 때의 처리를 수행합니다.
    ///
    /// 재생을 중지하고 플레이어를 정리한 후 상태 변경을 알립니다.
    func handleEmptyPlaylist() {
        pause()
        cleanupPlayer()
        notifySongChanged()
    }

    /// 곡이 제거되었을 때의 처리를 수행합니다.
    ///
    /// - Parameter index: 제거된 곡의 인덱스
    func handleSongRemoval(at index: Int) {
        if index == currentIndex {
            // 현재 재생 중인 곡이 삭제되는 경우
            handleCurrentSongRemoval(at: index)
        } else if index < currentIndex {
            // 현재 곡보다 앞의 곡이 삭제되면 인덱스 조정
            currentIndex -= 1
            NotificationCenter.default.post(name: .playlistChanaged, object: nil)
        } else {
            NotificationCenter.default.post(name: .playlistChanaged, object: nil)
        }
    }

    /// 현재 재생 중인 곡이 제거되었을 때의 처리를 수행합니다.
    ///
    /// - Parameter index: 제거된 곡의 인덱스
    func handleCurrentSongRemoval(at index: Int) {
        updateCurrentIndexAfterRemoval(at: index)
        notifySongChanged()

        if isPlaying {
            play()
        } else {
            player = nil
        }
    }

    /// 곡 제거 후 현재 인덱스를 업데이트합니다.
    ///
    /// - Parameter index: 제거된 곡의 인덱스
    func updateCurrentIndexAfterRemoval(at index: Int) {
        if playlist.count > 1 {
            currentIndex = (index == playlist.count) ? max(0, playlist.count - 1) : index
        } else {
            currentIndex = 0
        }
    }

    /// 순서 변경 후 인덱스를 업데이트합니다.
    ///
    /// - Parameters:
    /// 	- sourceIndex: 이동된 곡의 원래 인덱스
    /// 	- destinationIndex: 이동된 곡의 새 인덱스
    func updateCurrentIndexAfterReorder(sourceIndex: Int, destinationIndex: Int) {
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

    /// 피드백 처리 (좋아요/싫어요/취소)를 수행합니다.
	///
    /// 같은 피드백이 이미 있는 경우 취소하고, 없는 경우 새로 등록합니다.
    /// 피드백 변경 후 `.feedbackChanged` 알림을 발생시킵니다.
	///
    /// - Parameter isLike: `true`면 좋아요, `false`면 싫어요
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

        NotificationCenter.default.post(name: .feedbackChanged, object: newFeedback)
    }

    /// 현재 곡 변경 알림을 발생시킵니다.
    func notifySongChanged() {
        NotificationCenter.default.post(name: .currentSongChanged, object: nil)
    }

    /// 주어진 에셋으로 플레이어를 설정합니다.
    ///
    /// 기존 플레이어를 정리한 후 새로운 플레이어를 생성하고,
    /// 필요한 알림과 시간 옵저버를 설정합니다.
    ///
    /// - Parameter asset: 재생할 오디오 에셋
    func setupPlayer(with asset: AVURLAsset) {
        cleanupPlayer()

        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        setupNotifications(for: item)
        addPeriodicTimeObserver()
    }

    /// 플레이어 아이템에 대한 알림을 설정합니다.
    ///
    /// 재생 완료 재생 실패에 대한 알림을 등록합니다.
    ///
    /// - Parameter item: 알림을 설정할 플레이어 아이템
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

    /// 재생 완료 시의 처리를 수행합니다.
    ///
    /// 반복 모드가 활성화되어 있으면 처음부터 다시 재생하고,
    /// 그렇지 않으면 다음 곡으로 이동합니다.
    func handlePlaybackEnd() {
        if isRepeatEnabled {
            seek(to: 0)
            player?.play()
        } else {
            updatePlayingState(false)
            Task { @MainActor in
                await moveForward()
            }
        }
    }

    /// 재생 상태를 업데이트하고 알림을 발생시킵니다.
    ///
    /// - Parameter playing: 새로운 재생 상태
    func updatePlayingState(_ playing: Bool) {
        isPlaying = playing

        NotificationCenter.default.post(name: .playStateChanged, object: playing)
    }

    /// 재생 시간 정보를 주기적으로 업데이트합니다.
    /// 
    /// 1초마다 현재 재생 시간을 업데이트하고 관련 알림을 발생시킵니다.
    func addPeriodicTimeObserver() {
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }

            let seconds = CMTimeGetSeconds(time)
            currentPlaybackTime = Double(seconds)
            onRemote?(currentSong)

            NotificationCenter.default.post(name: .playbackTimeChanged, object: seconds)
        }
    }

    /// 플레이어 리소스를 정리합니다.
    ///
    /// 시간 옵저버를 제거하고 알림 등록을 해제합니다.
    func cleanupPlayer() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }

        NotificationCenter.default.removeObserver(self)
    }

}
