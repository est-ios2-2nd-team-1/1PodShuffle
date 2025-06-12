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
    @IBOutlet weak var playlistContent: UIView!
    @IBOutlet weak var playlistBackground: UIView!
    @IBOutlet weak var playlistThumbnail: UIImageView!
    @IBOutlet weak var playlistTitleLabel: UILabel!
    @IBOutlet weak var playlistSingerLabel: UILabel!
    
    @IBOutlet weak var playlistBackgroundHeightConstraint: NSLayoutConstraint!


    // 의존성 주입
	private lazy var songService = SongService()


    // 현재 곡의 피드백 상태를 나타내는 변수
    private var currentFeedbackType: FeedbackType = .none

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        updateSongUI()
        bindPlayerCallbacks()
        setupTapGestureForPlaylist()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task {
            await PlayerManager.shared.initializePlaylistIfNeeded()
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        let bottomInset = view.safeAreaInsets.bottom
        let playlistHeight = 80
        playlistBackgroundHeightConstraint.constant = bottomInset + CGFloat(playlistHeight)
    }

    /// 썸네일과 슬라이더의 초기 UI 상태를 설정합니다.
    private func setupUI() {
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.width / 2
        thumbnailImageView.clipsToBounds = true
        progressSlider.value = 0
    }

    /// 재생/일시정지 버튼의 아이콘을 상태에 따라 갱신합니다.
    private func updatePlayPauseButton() {
        let icon = PlayerManager.shared.isPlaying ? "pause.circle.fill" : "play.circle.fill"
        playPauseButton.setImage(UIImage(systemName: icon), for: .normal)
    }

    /// 좋아요/싫어요 버튼의 아이콘을 상태에 따라 갱신합니다.
    private func updateLikeDislikeButtons() {
        let likeIcon = currentFeedbackType == .like ? "hand.thumbsup.fill" : "hand.thumbsup"
        let dislikeIcon = currentFeedbackType == .dislike ? "hand.thumbsdown.fill" : "hand.thumbsdown"

        likeButton.setImage(UIImage(systemName: likeIcon), for: .normal)
        dislikeButton.setImage(UIImage(systemName: dislikeIcon), for: .normal)
    }

    /// AVPlayer의 시간 업데이트 및 재생 완료 콜백을 바인딩합니다.
    private func bindPlayerCallbacks() {
        PlayerManager.shared.onTimeUpdateToMainView = { [weak self] seconds in
            Task { @MainActor in
                self?.updateProgressUI(seconds: seconds)
            }
        }

        PlayerManager.shared.onPlayStateChangedToMainView = { [weak self] isPlaying in
            Task { @MainActor in
                self?.updatePlayPauseButton()
            }
        }

        PlayerManager.shared.onSongChanged = { [weak self] in
            Task { @MainActor in
                self?.updateSongUI()
            }
        }

        PlayerManager.shared.onFeedbackChanged = { [weak self] feedbackType in
            Task { @MainActor in
                self?.currentFeedbackType = feedbackType
                self?.updateLikeDislikeButtons()
            }
        }
    }

    private func updateProgressUI(seconds: Double) {
        progressSlider.value = Float(seconds)
        currentTimeLabel.text = TimeFormatter.formatTime(seconds)
    }
  
    private func updateSongUI() {
        guard let currentSong = PlayerManager.shared.currentSong else {
            print("No current song available")
            return
        }

        // 메인 재생 뷰 UI 갱신
        titleLabel.text = currentSong.title
        singerLabel.text = currentSong.artist
        thumbnailImageView.image = currentSong.thumbnailData.flatMap { UIImage(data: $0) }

        // 재생목록 뷰 UI 갱신
        playlistTitleLabel.text = currentSong.title
        playlistSingerLabel.text = currentSong.artist
        playlistThumbnail.image = currentSong.thumbnailData.flatMap { UIImage(data: $0) }

        // 현재 곡의 피드백 상태 조회
        currentFeedbackType = PlayerManager.shared.getCurrentSongFeedback()
        updateLikeDislikeButtons()

        PlayerManager.shared.loadDuration() { [weak self] seconds in
            guard let self, let duration = seconds else { return }

            self.progressSlider.maximumValue = Float(duration)
            self.totalTimeLabel.text = TimeFormatter.formatTime(duration)
        }
    }

    private func setupTapGestureForPlaylist() {
        playlistContent.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playlistTapped))
        playlistContent.addGestureRecognizer(tapGesture)
    }

    @objc private func playlistTapped() {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "PlayListView") {
            present(vc, animated: true)
        }
    }

    /// 좋아요 버튼을 탭했을 때 호출됩니다.
    @IBAction func likeTapped(_ sender: UIButton) {
        PlayerManager.shared.likeSong()
    }

    /// 싫어요 버튼을 탭했을 때 호출됩니다.
    @IBAction func dislikeTapped(_ sender: UIButton) {
        PlayerManager.shared.dislikeSong()
    }

    /// 재생/일시정지 버튼을 탭했을 때 호출됩니다.
    @IBAction func playPauseTapped(_ sender: UIButton) {
        PlayerManager.shared.togglePlayPause()
    }

    /// 이전 곡 버튼을 탭했을 때 호출됩니다.
    @IBAction func backwardTapped(_ sender: UIButton) {
        PlayerManager.shared.moveBackward()
    }

    /// 다음 곡 버튼을 탭했을 때 호출됩니다.
    @IBAction func forwardTapped(_ sender: UIButton) {
        Task {
            await PlayerManager.shared.moveForward()
        }
    }

    /// 슬라이더를 변경하여 재생 위치를 이동합니다.
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        PlayerManager.shared.seek(to: Double(sender.value))
    }

    /// 반복 버튼을 탭했을 때 반복 모드를 토글합니다.
    @IBAction func repeatTapped(_ sender: UIButton) {
        PlayerManager.shared.toggleRepeat()
        let icon = PlayerManager.shared.isRepeatEnabled ? "repeat.1.circle.fill" : "repeat.1.circle"
        repeatButton.setImage(UIImage(systemName: icon), for: .normal)
    }

    /// 재생속도 버튼을 탭했을 때 호출됩니다.
    @IBAction func speedTapped(_ sender: UIButton) {
        // TODO: 재생속도 클릭 로직 구현
    }
}
