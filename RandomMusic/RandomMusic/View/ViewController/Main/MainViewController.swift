import UIKit
import AVFoundation
import MarqueeLabel

class MainViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
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
    @IBOutlet weak var playlistContentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playlistThumbnailWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var singerLabel: MarqueeLabel!

    // MARK: - Properties

    /// 곡 관련 서비스를 제공하는 객체
    private lazy var songService = SongService()

    /// Throttle 객체
    private let throttle = Throttle()

    /// 현재 곡의 피드백 상태 (좋아요/싫어요/없음)
    private var currentFeedbackType: FeedbackType = .none

    /// 사용자가 슬라이더를 드래그 중인지 나타내는 플래그
    ///
    /// 이 플래그는 사용자가 슬라이더를 조작하는 동안 자동 시간 업데이트와의 충돌을 방지합니다.
    private var isSliderDragging = false

    // MARK: - Lifecycle

    /// 뷰가 메모리에 로드된 후 호출됩니다.
    ///
    /// 이 메서드에서는 UI 초기화, 콜백 바인딩, 제스처 설정 등의 초기 설정 작업을 수행합니다.
    override func viewDidLoad() {
        super.viewDidLoad()

        setupInitialButtonConfigurations()
        setupMarqueeLabels()
        setupSlider()
        updateSongUI()
        bindPlayerCallbacks()
        setupTapGestureForPlaylist()

        Task { @MainActor in
            await updateLayoutForCurrentTraitCollection()
        }
    }

    /// 뷰가 나타나기 직전에 호출됩니다.
 	///
 	/// 재생목록 초기화를 비동기적으로 수행합니다.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task {
            await PlayerManager.shared.initializePlaylistIfNeeded()
        }
    }

    /// Safe Area Insets가 변경되었을 때 호출됩니다.
    ///
    /// 재생목록 영역의 높이를 Safe Area에 맞춰 조정합니다.
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        Task { @MainActor in
            await updateLayoutForCurrentTraitCollection()
        }
    }

    /// 뷰의 레이아웃이 완료된 후 호출됩니다.
    ///
    /// 썸네일 이미지뷰를 원형으로 만들기 위해 cornerRadius를 설정합니다.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.width / 2
    }

    // MARK: - Setup Methods

    /// 모든 버튼의 초기 Configuration을 설정합니다.
    ///
    /// 각 버튼의 기본 이미지, 크기, 색상을 설정하고 초기 상태를 업데이트합니다.
    private func setupInitialButtonConfigurations() {
        // 각 버튼의 기본 이미지와 Configuration 설정
        setupButtonConfiguration(playPauseButton, imageName: "play.circle.fill", pointSize: 50)
        setupButtonConfiguration(backwardButton, imageName: "backward.frame.fill", pointSize: 20)
        setupButtonConfiguration(forwardButton, imageName: "forward.frame.fill", pointSize: 20)
        setupButtonConfiguration(likeButton, imageName: "hand.thumbsup", pointSize: 20)
        setupButtonConfiguration(dislikeButton, imageName: "hand.thumbsdown", pointSize: 20)
        setupButtonConfiguration(repeatButton, imageName: "repeat.1.circle", pointSize: 20)
        setupButtonConfiguration(speedButton, imageName: "gauge.with.dots.needle.50percent", pointSize: 20)

        // 초기 상태 업데이트
        updatePlayPauseButton()
        updateLikeDislikeButtons()
        updateRepeatButton()
    }

    /// 개별 버튼의 Configuration을 설정합니다.
    ///
    /// - Parameters:
    ///   - button: 설정할 버튼 객체
    ///   - imageName: SF Symbol 이미지 이름
    ///   - pointSize: 아이콘의 크기 (포인트 단위)
    private func setupButtonConfiguration(_ button: UIButton, imageName: String, pointSize: CGFloat) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: imageName)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: pointSize)

        // 색상 설정
        if button == playPauseButton {
            config.baseForegroundColor = UIColor(named: "MainColor")
        } else {
            config.baseForegroundColor = .secondaryLabel
        }

        button.configuration = config
    }

    /// MarqueeLabel들의 초기 설정을 수행합니다.
    ///
    /// 곡 제목과 아티스트명이 표시되는 레이블들을 MarqueeLabel로 설정하여,
    /// 텍스트가 레이블 영역을 넘어갈 때 자동으로 가로 스크롤 애니메이션이 적용되도록 합니다.
    private func setupMarqueeLabels() {
        titleLabel.type = .continuous
        titleLabel.speed = .duration(15.0)
        titleLabel.fadeLength = 10.0
        titleLabel.leadingBuffer = 20.0
        titleLabel.trailingBuffer = 20.0
        titleLabel.animationDelay = 1.0

        singerLabel.type = .continuous
        singerLabel.speed = .duration(12.0)
        singerLabel.fadeLength = 8.0
        singerLabel.leadingBuffer = 15.0
        singerLabel.trailingBuffer = 15.0
        singerLabel.animationDelay = 1.5
    }

    /// 진행률 슬라이더의 초기 설정을 수행합니다.
    ///
    /// 드래그 시작/종료 이벤트 핸들러를 등록하여 자동 업데이트와의 충돌을 방지합니다.
    private func setupSlider() {
        progressSlider.value = 0

        // 드래그 시작/종료만 감지
        progressSlider.addTarget(self, action: #selector(sliderDidBeginDragging), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(sliderDidEndDragging), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        // 드래그 중 값 변경 감지 (UI 업데이트용)
        progressSlider.addTarget(self, action: #selector(sliderValueChangedDuringDrag), for: .valueChanged)
    }

    /// 재생목록 영역에 탭 제스처를 설정합니다.
    ///
    /// 사용자가 재생목록 영역을 탭하면 재생목록 화면으로 전환됩니다.
    private func setupTapGestureForPlaylist() {
        playlistContent.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playlistTapped))
        playlistContent.addGestureRecognizer(tapGesture)
    }

    /// PlayerManager의 콜백 이벤트들을 바인딩합니다.
    ///
    /// 시간 업데이트, 재생 상태 변경, 곡 변경, 피드백 변경 이벤트를 처리합니다.
    /// 모든 UI 업데이트는 메인 스레드에서 실행되도록 보장됩니다.
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

        PlayerManager.shared.onSongChangedToMainView = { [weak self] in
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

    // MARK: - UI Update Methods

    /// 재생/일시정지 버튼의 아이콘을 현재 재생 상태에 따라 업데이트합니다.
    ///
    /// 재생 중일 때는 일시정지 아이콘을, 일시정지 상태일 때는 재생 아이콘을 표시합니다.
    private func updatePlayPauseButton() {
        let iconName = PlayerManager.shared.isPlaying ? "pause.circle.fill" : "play.circle.fill"
        guard var config = playPauseButton.configuration else { return }
        config.image = UIImage(systemName: iconName)
        playPauseButton.configuration = config
    }

    /// 좋아요/싫어요 버튼의 아이콘을 현재 피드백 상태에 따라 업데이트합니다.
    ///
    /// 활성화된 피드백은 채워진 아이콘으로, 비활성화된 피드백은 빈 아이콘으로 표시됩니다.
    private func updateLikeDislikeButtons() {
        // 좋아요 버튼
        let likeIconName = currentFeedbackType == .like ? "hand.thumbsup.fill" : "hand.thumbsup"
        guard var likeConfig = likeButton.configuration else { return }
        likeConfig.image = UIImage(systemName: likeIconName)
        likeButton.configuration = likeConfig

        // 싫어요 버튼
        let dislikeIconName = currentFeedbackType == .dislike ? "hand.thumbsdown.fill" : "hand.thumbsdown"
        guard var dislikeConfig = dislikeButton.configuration else { return }
        dislikeConfig.image = UIImage(systemName: dislikeIconName)
        dislikeButton.configuration = dislikeConfig
    }

    /// 재생 진행률 UI를 업데이트합니다.
    ///
    /// 사용자가 슬라이더를 드래그 중일 때는 업데이트를 건너뛰어 충돌을 방지합니다.
    ///
    /// - Parameter seconds: 현재 재생 시간 (초 단위)
    private func updateProgressUI(seconds: Double) {
        guard !isSliderDragging else { return }

        progressSlider.value = Float(seconds)
        currentTimeLabel.text = TimeFormatter.formatTime(seconds)
    }

    /// 현재 곡 정보에 따라 전체 UI를 업데이트합니다.
    ///
    /// 곡이 없는 경우 로그를 출력하고 함수를 종료합니다.
    private func updateSongUI() {
        guard let currentSong = PlayerManager.shared.currentSong else {
            print("No current song available")
            return
        }

        updateMainViewUI(with: currentSong)
        updatePlaylistViewUI(with: currentSong)
        updateFeedbackState()
        Task {
            await loadAndUpdateDuration()
        }
    }

    /// 메인 재생 화면의 UI를 업데이트합니다.
    ///
    /// 곡 제목, 아티스트, 썸네일 이미지를 설정합니다.
    ///
    /// - Parameter song: 표시할 곡 정보
    private func updateMainViewUI(with song: SongModel) {
        titleLabel.text = song.title
        singerLabel.text = song.artist

        titleLabel.restartLabel()
        singerLabel.restartLabel()

        guard let thumbnailData = song.thumbnailData,
              let image = UIImage(data: thumbnailData) else { return }

        thumbnailImageView.image = image
    }

    /// 재생목록 영역의 UI를 업데이트합니다.
    ///
    /// 곡 제목, 아티스트, 썸네일 이미지를 설정합니다.
    ///
    /// - Parameter song: 표시할 곡 정보
    private func updatePlaylistViewUI(with song: SongModel) {
        playlistTitleLabel.text = song.title
        playlistSingerLabel.text = song.artist

        guard let thumbnailData = song.thumbnailData,
              let image = UIImage(data: thumbnailData) else { return }

        playlistThumbnail.image = image
    }

    /// 현재 곡의 피드백 상태를 업데이트합니다.
    ///
    /// PlayerManager에서 현재 곡의 피드백 정보를 가져와 UI에 반영합니다.
    private func updateFeedbackState() {
        currentFeedbackType = PlayerManager.shared.getCurrentSongFeedback()
        updateLikeDislikeButtons()
    }

    /// 현재 곡의 총 재생 시간을 로드하고 UI를 업데이트합니다.
    ///
    /// 비동기적으로 곡의 길이를 가져와 슬라이더의 최대값과 총 시간 레이블을 설정합니다.
    @MainActor
    private func loadAndUpdateDuration() async {
        guard let duration = await PlayerManager.shared.loadDuration() else { return }

        progressSlider.maximumValue = Float(duration)
        totalTimeLabel.text = TimeFormatter.formatTime(duration)
    }

    // MARK: - Action Methods

    /// 재생목록 영역이 탭되었을 때 호출됩니다.
    ///
    /// 재생목록 화면을 모달로 표시합니다.
    @objc private func playlistTapped() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "PlayListView") else {
            print("PlayListView를 찾을 수 없습니다.")
            return
        }
        present(vc, animated: true)
    }

    /// 슬라이더 드래그가 시작되었을 때 호출됩니다.
    ///
    /// 자동 시간 업데이트와의 충돌을 방지하기 위해 플래그를 설정합니다.
    @objc private func sliderDidBeginDragging() {
        isSliderDragging = true
    }

    /// 슬라이더 드래그가 종료되었을 때 호출됩니다.
    ///
    /// 최종 위치로 seek하고 자동 시간 업데이트를 재개합니다.
    @objc private func sliderDidEndDragging() {
        isSliderDragging = false

        // 드래그 종료 시에만 실제 seek 수행
        let targetTime = Double(progressSlider.value)
        PlayerManager.shared.seek(to: targetTime)
    }

    /// 드래그 중 슬라이더 값이 변경될 때 호출됩니다.
    ///
    /// 실제 seek는 수행하지 않고 시간 레이블만 업데이트합니다.
    @objc private func sliderValueChangedDuringDrag() {
        guard isSliderDragging else { return }

        // 드래그 중에는 시간 레이블만 업데이트 (seek 없음)
        let targetTime = Double(progressSlider.value)
        currentTimeLabel.text = TimeFormatter.formatTime(targetTime)
    }

    /// 좋아요 버튼이 탭되었을 때 호출됩니다.
    ///
    /// 탭 애니메이션을 실행한 후 현재 곡에 대한 좋아요 피드백을 PlayerManager에 전달합니다.
    @IBAction func likeTapped(_ sender: UIButton) {
        animateButtonTap(sender)
        PlayerManager.shared.likeSong()
    }

    /// 싫어요 버튼이 탭되었을 때 호출됩니다.
    ///
    /// 탭 애니메이션을 실행한 후 현재 곡에 대한 싫어요 피드백을 PlayerManager에 전달합니다.
    @IBAction func dislikeTapped(_ sender: UIButton) {
        animateButtonTap(sender)
        PlayerManager.shared.dislikeSong()
    }

    /// 재생/일시정지 버튼이 탭되었을 때 호출됩니다.
    ///
    /// 현재 재생 상태를 토글합니다.
    @IBAction func playPauseTapped(_ sender: UIButton) {
        PlayerManager.shared.togglePlayPause()
    }

    /// 이전 곡 버튼이 탭되었을 때 호출됩니다.
    ///
    /// 재생목록에서 이전 곡으로 이동합니다.
    /// 첫 번째 곡인 경우 알림을 표시합니다.
    @IBAction func backwardTapped(_ sender: UIButton) {
        throttle.run {
            let canMoveToPrevious = PlayerManager.shared.moveBackward()

            if !canMoveToPrevious {
                Toast.shared.showToast(message: "가장 최신 곡입니다.")
            }
        }
    }

    /// 다음 곡 버튼이 탭되었을 때 호출됩니다.
    ///
    /// 재생목록에서 다음 곡으로 이동합니다. 비동기적으로 처리됩니다.
    @IBAction func forwardTapped(_ sender: UIButton) {
        throttle.run {
            Task { await PlayerManager.shared.moveForward() }
        }
    }

    /// 반복 버튼을 탭했을 때 호출됩니다.
    ///
    /// 반복 재생 모드를 토글하고 버튼 아이콘을 업데이트합니다.
    @IBAction func repeatTapped(_ sender: UIButton) {
        PlayerManager.shared.toggleRepeat()
        updateRepeatButton()
    }

    /// 반복 재생 버튼의 아이콘을 현재 설정에 따라 업데이트합니다.
    ///
    /// 반복 모드가 활성화되면 채워진 아이콘을, 비활성화되면 빈 아이콘을 표시합니다.
    private func updateRepeatButton() {
        let iconName = PlayerManager.shared.isRepeatEnabled ? "repeat.1.circle.fill" : "repeat.1.circle"
        guard var config = repeatButton.configuration else { return }
        config.image = UIImage(systemName: iconName)
        repeatButton.configuration = config
    }


    /// 재생속도 버튼을 탭했을 때 호출됩니다.
    ///
    /// 재생 속도 선택을 위한 액션 시트를 표시합니다.
    /// iPad에서는 popover로 표시됩니다.
    @IBAction func speedTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "재생 속도", message: nil, preferredStyle: .actionSheet)

        let speeds = [0.5, 0.75, 1.0, 1.25, 1.5]
        for speed in speeds {
            let action = UIAlertAction(title: "\(speed)x", style: .default) { _ in
                self.changePlaybackSpeed(Float(speed))
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)

        // iPad에서 popover 설정
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }

        present(alert, animated: true)
    }

    /// 재생속도를 변경하고 UI를 업데이트합니다.
    ///
    /// 이 메서드는 현재 재생 상태를 고려하여 배속을 적용합니다:
    /// - 재생 중인 경우: 즉시 새로운 배속으로 재생 계속
    /// - 일시정지 상태인 경우: 배속 설정만 저장하고 일시정지 상태 유지
    ///
    /// 배속 변경 후 속도 버튼의 아이콘도 새로운 배속에 맞게 자동으로 업데이트됩니다.
    ///
    /// - Parameter speed: 새로운 재생 속도 (0.5 ~ 1.5 범위의 배속 값)
    ///
    /// - Note: 지원되는 재생 속도는 0.5x, 0.75x, 1.0x, 1.25x, 1.5x입니다.
    private func changePlaybackSpeed(_ speed: Float) {
        PlayerManager.shared.currentPlaybackSpeed = speed

        if let player = PlayerManager.shared.player {
            if PlayerManager.shared.isPlaying {
                player.rate = speed
            } else {
                player.rate = 0.0
            }
        }

        // 배속에 따른 아이콘 변경
        let iconName = getSpeedIcon(for: speed)
        guard var config = speedButton.configuration else { return }
        config.image = UIImage(systemName: iconName)
        speedButton.configuration = config
    }

    /// 재생속도에 따른 적절한 SF Symbol 아이콘을 반환합니다.
    ///
    /// - Parameter speed: 재생 속도
    /// - Returns: 해당 속도에 맞는 SF Symbol 이름
    private func getSpeedIcon(for speed: Float) -> String {
        switch speed {
        case 0.5:
            return "gauge.with.dots.needle.0percent"
        case 0.75:
            return "gauge.with.dots.needle.33percent"
        case 1.0:
            return "gauge.with.dots.needle.50percent"
        case 1.25:
            return "gauge.with.dots.needle.67percent"
        case 1.5:
            return "gauge.with.dots.needle.100percent"
        default:
            return "gauge.with.dots.needle.50percent"
        }
    }

    // MARK: - Animation Methods

    /// 버튼 탭 애니메이션을 실행합니다.
    ///
    /// 버튼을 잠깐 확대했다가 원래 크기로 돌아오는 스케일 애니메이션을 적용합니다.
    ///
    /// - Parameter button: 애니메이션을 적용할 버튼
    private func animateButtonTap(_ button: UIButton) {
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                button.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }
        ) { _ in
            UIView.animate(
                withDuration: 0.1,
                delay: 0,
                options: [.curveEaseInOut],
                animations: {
                    button.transform = CGAffineTransform.identity
                }
            )
        }
    }
}

// MARK: - Adaptive Layout Support

/// 아이패드와 아이폰에 대한 적응형 레이아웃 지원을 위한 확장
extension MainViewController {

    /// Trait Collection이 변경될 때 호출됩니다.
    ///
    /// Horizontal Size Class가 변경되면 레이아웃을 다시 구성합니다.
    ///
    /// - Parameter previousTraitCollection: 이전 Trait Collection
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            Task { @MainActor in
                await updateLayoutForCurrentTraitCollection()
            }
        }
    }

    /// 현재 Trait Collection에 맞게 레이아웃을 업데이트합니다.
    ///
    /// Regular Width (아이패드)와 Compact Width (아이폰)에 따라 다른 레이아웃을 적용합니다.
    @MainActor
    private func updateLayoutForCurrentTraitCollection() async {
        if traitCollection.horizontalSizeClass == .regular {
			setupLayoutForPad()
        } else {
            setupLayoutForPhone()
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    /// 아이패드용 레이아웃을 설정합니다.
    ///
    /// 큰 화면에 맞춰 썸네일 크기, 버튼 크기를 조정합니다.
    @MainActor
    private func setupLayoutForPad() {
        updateButtonSizes(subPointSize: 30, mainPointSize: 60)

        let contentHeight: CGFloat = 120
        updatePlaylistLayout(contentHeight: contentHeight)
    }

    /// 아이폰용 레이아웃을 설정합니다.
    ///
    /// 작은 화면에 맞춰 썸네일 크기, 버튼 크기를 조정합니다.
    @MainActor
    private func setupLayoutForPhone() {
        updateButtonSizes(subPointSize: 20, mainPointSize: 50)

        let contentHeight: CGFloat = 80
        updatePlaylistLayout(contentHeight: contentHeight)
    }

    /// 모든 버튼의 크기를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - subPointSize: 보조 버튼들의 아이콘 크기 (포인트 단위)
    ///   - mainPointSize: 메인 재생 버튼의 아이콘 크기 (포인트 단위)
    private func updateButtonSizes(subPointSize: CGFloat, mainPointSize: CGFloat) {
        let targetButtons = [dislikeButton, likeButton, repeatButton, backwardButton, forwardButton, speedButton]

        // 보조 버튼들 크기 업데이트
        for button in targetButtons {
            guard let button = button, var config = button.configuration else { continue }
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: subPointSize)
            button.configuration = config
        }

        // 메인 버튼 크기 업데이트
        guard var mainConfig = playPauseButton.configuration else { return }
        mainConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: mainPointSize)
        playPauseButton.configuration = mainConfig
    }

    /// 하단 재생목록 영역의 레이아웃을 업데이트합니다.
    ///
    /// Safe Area에 맞춰 높이를 조정하고 썸네일 크기를 설정합니다.
    ///
    /// - Parameter contentHeight: 재생목록 컨텐츠의 높이 (포인트 단위)
    private func updatePlaylistLayout(contentHeight: CGFloat) {
        let bottomInset = view.safeAreaInsets.bottom
        playlistContentHeightConstraint.constant = contentHeight
        playlistBackgroundHeightConstraint.constant = bottomInset + contentHeight
        playlistThumbnailWidthConstraint.constant = contentHeight - (contentHeight > 100 ? 40 : 20)
    }
}
