import AVFoundation

/// AVPlayer 기반의 오디오 재생을 관리하는 클래스입니다.
///
/// 이 클래스는 AVURLAsset을 통해 스트리밍 오디오를 재생하고,
/// 재생 시간 갱신 및 재생 종료에 대한 콜백을 제공합니다.
final class PlayerManager {
    static let shared = PlayerManager()

    /// 플레이어가 초기화되었는지 여부를 나타냅니다.
    var isPlayerReady: Bool {
        return player != nil
    }

    /// 재생 시간이 주기적으로 업데이트될 때 호출되는 클로저입니다.
    var onTimeUpdate: ((Double) -> Void)?

    /// 현재 재생 항목이 끝까지 재생되었을 때 호출되는 클로저입니다.
    var onPlaybackFinished: (() -> Void)?

    private var player: AVPlayer?
    private var timeObserverToken: Any?

    /// 지정된 AVURLAsset을 사용하여 오디오를 재생합니다.
    ///
    /// 이전 재생 상태는 모두 초기화되며,
    /// AVPlayerItemDidPlayToEndTime 알림을 통해 재생 완료 이벤트를 수신합니다.
    /// - Parameter asset: 재생할 AVURLAsset입니다.
    func play(asset: AVURLAsset) {
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.onPlaybackFinished?()
        }

        addPeriodicTimeObserver()
        player?.play()
    }

    /// 현재 오디오 재생을 일시정지합니다.
    func pause() {
        player?.pause()
    }

    /// 일시정지된 오디오 재생을 다시 시작합니다.
    func resume() {
        player?.play()
    }

	/// 재생 위치를 지정한 시간으로 이동합니다.
	///
	/// - Parameter seconds: 이동할 시간(초)입니다.
    func seek(to seconds: Float64) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player?.seek(to: time)
    }

    /// AVURLAsset의 전체 재생 시간을 비동기적으로 로드합니다.
    ///
    /// - Parameters:
    ///   - asset: 재생 시간 정보를 가져올 AVURLAsset입니다.
    ///   - completion: 재생 시간이 성공적으로 로드되면 호출되는 클로저입니다. 실패 시 nil이 전달됩니다.
    func loadDuration(with asset: AVURLAsset,completion: @escaping (Double?) -> Void) {
        Task {
            do {
                let duration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(duration)

                DispatchQueue.main.async {
                    completion(seconds.isFinite ? seconds : nil)
                }
            } catch {
                print("Duration load error: ", error)

                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    /// 재생 시간 정보를 주기적으로 업데이트합니다.
    private func addPeriodicTimeObserver() {
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            let seconds = CMTimeGetSeconds(time)

            self?.onTimeUpdate?(seconds)
        }
    }

    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }

        NotificationCenter.default.removeObserver(self)
    }
}
