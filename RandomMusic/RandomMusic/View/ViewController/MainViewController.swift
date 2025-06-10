//import UIKit
//
//class MainViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//}


import UIKit
import AVFoundation

class MainViewController: UIViewController {
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var singerLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var speedButton: UIButton!

    var isDisliked = false
    var isLiked = false
    var isPlaying = false
    var currentSong: SongModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchRandomSongFromNetwork()
        bindPlayerCallbacks()
    }

    /// 초기 UI 상태를 설정합니다.
    private func setupUI() {
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.width / 2
        thumbnailImageView.clipsToBounds = true
        progressSlider.value = 0
    }

    /// NetworkManager를 통해 랜덤 곡을 비동기적으로 가져옵니다.
    ///
    /// 이 메서드는 async/await 기반으로 `SongModel`을 요청하며,
    /// 썸네일 이미지까지 포함된 모델을 반환받습니다.
    private func fetchRandomSongFromNetwork() {
        Task {
            do {
                let song = try await NetworkManager.shared.getMusic()
                await MainActor.run {
                    configure(with: song)
                }
            } catch {
                print(error)
            }
        }
    }

    /// 곡 정보를 UI와 AVPlayer에 반영합니다.
    ///
    /// - Parameter song: 썸네일이 포함된 `SongModel`입니다.
    private func configure(with song: SongModel) {
        currentSong = song
        titleLabel.text = song.title
        singerLabel.text = song.artist
        thumbnailImageView.image = song.thumbnailData.flatMap { UIImage(data: $0) }

        guard let asset = NetworkManager.shared.createAssetWithHeaders(url: song.streamUrl) else {
            print("asset error")
            return
        }

        PlayerManager.shared.loadDuration(with: asset) { [weak self] seconds in
            guard let self, let duration = seconds else { return }

            self.progressSlider.maximumValue = Float(duration)
            self.totalTimeLabel.text = formatTime(duration)
        }
    }

    /// AVPlayer 콜백을 바인딩합니다.
    private func bindPlayerCallbacks() {
        PlayerManager.shared.onTimeUpdate = { [weak self] seconds in
            self?.progressSlider.value = Float(seconds)
            self?.currentTimeLabel.text = self?.formatTime(seconds)
        }

        PlayerManager.shared.onPlaybackFinished = { [weak self] in
            self?.isPlaying = false
            self?.updatePlayPauseButton()
        }
    }

    /// 좋아요 버튼을 탭했을 때 호출됩니다.
    @IBAction func likeTapped(_ sender: UIButton) {
        toggleLikeDislike(like: true)
    }

    /// 싫어요 버튼을 탭했을 때 호출됩니다.
    @IBAction func dislikeTapped(_ sender: UIButton) {
        toggleLikeDislike(like: false)
    }

    /// 좋아요/싫어요 버튼의 아이콘을 상태에 따라 갱신합니다.
    private func toggleLikeDislike(like: Bool) {
        if like {
            isLiked.toggle()
            if isLiked { isDisliked = false }
        } else {
            isDisliked.toggle()
            if isDisliked { isLiked = false }
        }
        updateLikeDislikeButtons()
    }

    /// 재생/일시정지 버튼을 탭했을 때 호출됩니다.
    @IBAction func playPauseTapped(_ sender: UIButton) {
        defer {
            isPlaying.toggle()
            updatePlayPauseButton()
        }

        if isPlaying {
            PlayerManager.shared.pause()
            return
        }

        if PlayerManager.shared.isPlayerReady {
            PlayerManager.shared.resume()
        } else if let song = currentSong,
                  let asset = NetworkManager.shared.createAssetWithHeaders(url: song.streamUrl) {
            PlayerManager.shared.play(asset: asset)
        }
    }


    /// 슬라이더의 값을 변경했을 때 재생 위치를 이동합니다.
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        PlayerManager.shared.seek(to: Double(sender.value))
    }

    /// 반복 버튼을 탭했을 때 호출됩니다.
    @IBAction func repeatTapped(_ sender: UIButton) {
        // TODO: 한곡반복 버튼 클릭 로직 추가
    }

    /// 재생속도 버튼을 탭했을 때 호출됩니다.
    @IBAction func speedTapped(_ sender: UIButton) {
        // TODO: 재생속도 버튼 클릭 로직 추가
    }

    /// 재생/일시정지 버튼의 아이콘을 상태에 따라 갱신합니다.
    private func updatePlayPauseButton() {
        let icon = isPlaying ? "pause.circle.fill" : "play.circle.fill"

        playPauseButton.setImage(UIImage(systemName: icon), for: .normal)
    }

    /// 좋아요/싫어요 버튼의 아이콘을 상태에 따라 갱신합니다.
    private func updateLikeDislikeButtons() {
        let likeIcon = isLiked ? "hand.thumbsup.fill" : "hand.thumbsup"
        let dislikeIcon = isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown"

        likeButton.setImage(UIImage(systemName: likeIcon), for: .normal)
        dislikeButton.setImage(UIImage(systemName: dislikeIcon), for: .normal)
    }

    /// 시간을 "MM:SS" 형식의 문자열로 변환합니다.
    ///
    /// - Parameter time: 초 단위 시간입니다.
    /// - Returns: 변환된 시간 문자열입니다.
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }
   let name = Bundle.main.object(forInfoDictionaryKey: "NAME") as? String ?? ""
   let token = Bundle.main.object(forInfoDictionaryKey: "TOKEN") as? String ?? ""

   let name = Bundle.main.object(forInfoDictionaryKey: "NAME") as? String ?? ""
   let token = Bundle.main.object(forInfoDictionaryKey: "TOKEN") as? String ?? ""


   override func viewDidLoad() {
       super.viewDidLoad()


       print("Name: \(name)")  // "aaa"
       print("Token: \(token)") // "bbb"
   }

}
