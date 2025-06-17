import UIKit

/// 플로팅 플레이어 뷰가 적용된 커스텀 탭바 컨트롤러입니다.
final class PlayerBarController: UITabBarController {
    let playerBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .player.withAlphaComponent(0.9)
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

    let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Loading..."
        return l
    }()

    let artistLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Loading..."
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

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        updatePlayerBar()
        setupTapGestureForPlaylist()

        PlayerManager.shared.onSongChangedToPlayerBarView = { [weak self] in
            self?.updatePlayerBar()
        }
    }
    
    /// UI를 구성합니다.
    private func configureUI() {
        playerBar.layer.cornerRadius = 10
        mainImageView.layer.cornerRadius = 10

        view.addSubview(playerBar)
        playerBar.addSubview(mainImageView)
        playerBar.addSubview(labelStackView)

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

        NSLayoutConstraint.activate([
            playerBar.heightAnchor.constraint(equalToConstant: 70),

            mainImageView.centerYAnchor.constraint(equalTo: playerBar.centerYAnchor),
            mainImageView.leadingAnchor.constraint(equalTo: playerBar.leadingAnchor, constant: 10),
            mainImageView.widthAnchor.constraint(equalToConstant: 60),
            mainImageView.heightAnchor.constraint(equalToConstant: 60),

            labelStackView.leadingAnchor.constraint(equalTo: mainImageView.trailingAnchor, constant: 10),
            labelStackView.trailingAnchor.constraint(equalTo: playerBar.trailingAnchor, constant: -10),
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

    @objc private func playerBarTapped() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "PlayListView") else {
            return
        }

        present(vc, animated: true)
    }
}
