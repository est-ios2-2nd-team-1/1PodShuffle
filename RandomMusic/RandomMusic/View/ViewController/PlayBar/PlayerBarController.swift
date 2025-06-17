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

    private var currentSongObserver: NSObjectProtocol?
    private var playStateObserver: NSObjectProtocol?
    private let throttle = Throttle()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        updatePlayerBar()
        setupTapGestureForPlaylist()

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

    /// UI를 구성합니다.
    private func configureUI() {
        tabBar.tintColor = .player
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

    /// 재생/일시정지 버튼의 아이콘을 현재 재생 상태에 따라 업데이트합니다.
    ///
    /// 재생 중일 때는 일시정지 아이콘을, 일시정지 상태일 때는 재생 아이콘을 표시합니다.
    private func updatePlayPauseButton(_ isPlaying: Bool) {
        let iconName = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        playPauseButton.setImage(image, for: .normal)
    }

    @objc private func playerBarTapped() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "PlayListView") else {
            return
        }

        present(vc, animated: true)
    }

    @objc private func playPauseTapped() {
        PlayerManager.shared.togglePlayPause()
    }

    @objc private func forwardTapped() {
        throttle.run {
            Task { await PlayerManager.shared.moveForward() }
        }
    }

    @objc private func backwardTapped() {
        throttle.run {
            let canMoveToPrevious = PlayerManager.shared.moveBackward()

            if !canMoveToPrevious {
                Toast.shared.showToast(message: "가장 최신 곡입니다.")
            }
        }
    }
}
