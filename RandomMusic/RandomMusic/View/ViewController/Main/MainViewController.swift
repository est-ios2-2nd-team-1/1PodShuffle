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

    var isDisliked = false
    var isLiked = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchRandomSong()
        bindPlayerCallbacks()
        setupTapGestureForPlaylist()
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
        let likeIcon = isLiked ? "hand.thumbsup.fill" : "hand.thumbsup"
        let dislikeIcon = isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown"

        likeButton.setImage(UIImage(systemName: likeIcon), for: .normal)
        dislikeButton.setImage(UIImage(systemName: dislikeIcon), for: .normal)
    }

    /// AVPlayer의 시간 업데이트 및 재생 완료 콜백을 바인딩합니다.
    private func bindPlayerCallbacks() {
        PlayerManager.shared.onTimeUpdate = updateProgressUI

        PlayerManager.shared.onPlayStateChanged = { [weak self] isPlaying in
            self?.updatePlayPauseButton()
        }

        PlayerManager.shared.onSongChanged = { [weak self] in
            self?.updateSongUI()
        }

        PlayerManager.shared.onNeedNewSong = { [weak self] in
            self?.fetchRandomSong(shouldPlay: true)
        }
    }

    private func updateProgressUI(seconds: Double) {
        progressSlider.value = Float(seconds)
        currentTimeLabel.text = TimeFormatter.formatTime(seconds)
    }

    private func fetchRandomSong(shouldPlay: Bool = false) {
        Task {
            do {
                let song = try await NetworkManager.shared.getMusic()
                await MainActor.run {
                    let currentPlaylist = PlayerManager.shared.playlist
                    let newPlaylist = currentPlaylist + [song]
                    let newIndex = currentPlaylist.count

                    PlayerManager.shared.setPlaylist(newPlaylist)
                    PlayerManager.shared.setCurrentIndex(newIndex)

                    updateSongUI()

                    if shouldPlay {
                        PlayerManager.shared.play()
                    }
                }
            } catch {
                print(error)
            }
        }
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
        toggleLikeDislike(like: true)
    }

    /// 싫어요 버튼을 탭했을 때 호출됩니다.
    @IBAction func dislikeTapped(_ sender: UIButton) {
        toggleLikeDislike(like: false)
    }

    /// 좋아요/싫어요 상태를 전환하고 버튼을 갱신합니다.
    /// - Parameter like: true이면 좋아요, false이면 싫어요 처리입니다.
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
        PlayerManager.shared.togglePlayPause()
    }

    /// 이전 곡 버튼을 탭했을 때 호출됩니다.
    @IBAction func backwardTapped(_ sender: UIButton) {
        PlayerManager.shared.moveBackward()
    }

    /// 다음 곡 버튼을 탭했을 때 호출됩니다.
    @IBAction func forwardTapped(_ sender: UIButton) {
        PlayerManager.shared.moveForward()
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
