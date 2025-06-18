import UIKit
import MarqueeLabel

/// 플로팅 플레이어 뷰가 적용된 커스텀 탭바 컨트롤러입니다.
final class PlayerBarController: UITabBarController {
    let playerBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .main
        v.clipsToBounds = true
        return v
    }()

    let mainImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = .gray
        iv.clipsToBounds = true
        return iv
    }()

    let titleLabel: MarqueeLabel = {
        let l = MarqueeLabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Loading..."
        l.type = .continuous
        l.speed = .rate(30)
        l.fadeLength = 10.0
        l.leadingBuffer = 10.0
        l.trailingBuffer = 10.0
        l.numberOfLines = 1
        return l
    }()

    let artistLabel: MarqueeLabel = {
        let l = MarqueeLabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Loading..."
        l.type = .continuous
        l.speed = .rate(30)
        l.fadeLength = 10.0
        l.leadingBuffer = 10.0
        l.trailingBuffer = 10.0
        l.numberOfLines = 1
        return l
    }()

    lazy var labelStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, artistLabel])
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        return sv
    }()

    lazy var playPauseButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        let image = UIImage(systemName: "play.circle.fill", withConfiguration: config)
        b.setImage(image, for: .normal)
        b.tintColor = .secondaryLabel
        b.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        return b
    }()

    lazy var forwardButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "forward.frame.fill"), for: .normal)
        b.tintColor = .secondaryLabel
        b.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)
        return b
    }()

    lazy var backwardButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "backward.frame.fill"), for: .normal)
        b.tintColor = .secondaryLabel
        b.addTarget(self, action: #selector(backwardTapped), for: .touchUpInside)
        return b
    }()

    lazy var buttonStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [backwardButton, playPauseButton, forwardButton])
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .fill
        sv.spacing = 5
        return sv
    }()

    /// 현재 곡 변경 알림 옵저버
    private var currentSongObserver: NSObjectProtocol?

    /// 재생 상태 변경 옵저버
    private var playStateObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        updatePlayerBar()
        setupTapGestureForPlaylist()
        setupNotificationObservers()
    }
    
    /// 메모리에서 해제될 때 호출됩니다.
    ///
    /// 등록된 모든 NotificationCenter 옵저버를 제거하여 메모리 누수를 방지합니다.
    deinit {
        if let observer = currentSongObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = playStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// UI를 구성합니다.
    private func configureUI() {
        self.delegate = self
        tabBar.tintColor = .player
        buttonStackView.isHidden = true
        playerBar.layer.cornerRadius = 10
        mainImageView.layer.cornerRadius = 10

        view.addSubview(playerBar)
        playerBar.addSubview(mainImageView)
        playerBar.addSubview(labelStackView)
        playerBar.addSubview(buttonStackView)

        if UIDevice.current.userInterfaceIdiom == .pad {
            playerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
            playerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
            playerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
            titleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)
            artistLabel.font = UIFont.systemFont(ofSize: 16.0)
        } else {
            playerBar.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: -10).isActive = true
            playerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
            playerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
            titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
            artistLabel.font = UIFont.systemFont(ofSize: 13.0)
        }

        labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        labelStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        buttonStackView.setContentHuggingPriority(.required, for: .horizontal)
        buttonStackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            playerBar.heightAnchor.constraint(equalToConstant: 70),

            mainImageView.centerYAnchor.constraint(equalTo: playerBar.centerYAnchor),
            mainImageView.leadingAnchor.constraint(equalTo: playerBar.leadingAnchor, constant: 10),
            mainImageView.widthAnchor.constraint(equalToConstant: 60),
            mainImageView.heightAnchor.constraint(equalToConstant: 60),

            buttonStackView.trailingAnchor.constraint(equalTo: playerBar.trailingAnchor, constant: -10),
            buttonStackView.widthAnchor.constraint(equalToConstant: 110),
            buttonStackView.centerYAnchor.constraint(equalTo: playerBar.centerYAnchor),

            labelStackView.leadingAnchor.constraint(equalTo: mainImageView.trailingAnchor, constant: 5),
            labelStackView.trailingAnchor.constraint(equalTo: buttonStackView.leadingAnchor),
            labelStackView.centerYAnchor.constraint(equalTo: playerBar.centerYAnchor),
        ])
    }

    /// 플레이어 바의 UI를 업데이트 합니다.
    ///
    /// 현재 음악이 변경될 때와 뷰가 처음으로 초기화될 때 실행됩니다.
    private func updatePlayerBar() {
        guard let currentSong = PlayerManager.shared.currentSong else { return }
        Task { @MainActor in
            mainImageView.image = UIImage(data: currentSong.thumbnailData ?? Data())
            titleLabel.text = currentSong.title
            artistLabel.text = currentSong.artist
        }
    }

    /// 재생목록 영역에 탭 제스처를 설정합니다.
    ///
    /// 사용자가 재생목록 영역을 탭하면 재생목록 화면으로 전환됩니다.
    private func setupTapGestureForPlaylist() {
        playerBar.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playerBarTapped))
        playerBar.addGestureRecognizer(tapGesture)
    }

    /// 변화를 감지할 Notification을 등록합니다.
    private func setupNotificationObservers() {
        currentSongObserver = NotificationCenter.default.addObserver(
            forName: .currentSongChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlayerBar()
        }

        playStateObserver = NotificationCenter.default.addObserver(
            forName: .playStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let isPlaying = notification.object as? Bool else { return }
            self?.updatePlayPauseButton(isPlaying)
        }
    }

    /// 재생/일시정지 버튼의 아이콘을 현재 재생 상태에 따라 업데이트합니다.
    ///
    /// 재생 중일 때는 일시정지 아이콘을, 일시정지 상태일 때는 재생 아이콘을 표시합니다.
    private func updatePlayPauseButton(_ isPlaying: Bool) {
        let iconName = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        playPauseButton.setImage(image, for: .normal)
    }
    
    /// 플레이어 바가 클릭됐을 때 호출하고, 플레이리스트 화면을 모달로 띄웁니다.
    @objc private func playerBarTapped() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "PlayListView") else {
            return
        }

        present(vc, animated: true)
    }

    /// 재생/일시정지 버튼이 탭되었을 때 호출됩니다.
    ///
    /// 현재 재생 상태를 토글합니다.
    @objc private func playPauseTapped() {
        PlayerManager.shared.togglePlayPause()
    }

    /// 다음 곡 버튼이 탭되었을 때 호출됩니다.
    ///
    /// 재생목록에서 다음 곡으로 이동합니다.
    /// 마지막 곡인 경우 새로운 곡을 비동기적으로 로드합니다.
    @objc private func forwardTapped() {
        let throttle = Throttle()
        throttle.run {
            Task { await PlayerManager.shared.moveForward() }
        }
    }

    /// 이전 곡 버튼이 탭되었을 때 호출됩니다.
    ///
    /// 재생목록에서 이전 곡으로 이동합니다.
    /// 현재 곡이 첫 번째 곡인 경우 토스트 메시지로 사용자에게 알립니다.
    @objc private func backwardTapped() {
        let throttle = Throttle()
        throttle.run {
            let canMoveToPrevious = PlayerManager.shared.moveBackward()

            if !canMoveToPrevious {
                Toast.shared.showToast(message: "가장 최신 곡입니다.")
            }
        }
    }
}

extension PlayerBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let _ = viewController as? MainViewController {
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.buttonStackView.alpha = 0
            } completion: { [weak self] _ in
                self?.buttonStackView.isHidden = true
            }
        } else {
            buttonStackView.isHidden = false
            buttonStackView.alpha = 0

            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.buttonStackView.alpha = 1
            }
        }
    }
}
