import UIKit
import CoreData
import AVKit

class PlayListViewController: UIViewController {
    @IBOutlet weak var playListTableView: UITableView!
    @IBOutlet weak var playProgressView: UIProgressView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forButton: UIButton!

    /// 재생, 이전곡, 다음곡 버튼 UIImage Symbol size
    let playConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
    let backforConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular, scale: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        setButtonUI()
        bindPlayerCallbacks()
    }

    /// 재생, 이전곡, 다음곡 버튼 UI Setting
    private func setButtonUI() {
        let backImage = UIImage(systemName: "backward.frame.fill", withConfiguration: backforConfig)
        let forImage = UIImage(systemName: "forward.frame.fill", withConfiguration: backforConfig)

        backButton.setImage(backImage, for: .normal)
        forButton.setImage(forImage, for: .normal)

        setPlayPauseButton()
    }

    /// 재생/일시정지 버튼 UI
    private func setPlayPauseButton() {
        let playImage = PlayerManager.shared.isPlaying ?
                        UIImage(systemName: "pause.circle", withConfiguration: playConfig) :
                        UIImage(systemName: "play.circle.fill", withConfiguration: playConfig)
        playButton.setImage(playImage, for: .normal)
    }

    /// 바인딩 메소드
    private func bindPlayerCallbacks() {
        PlayerManager.shared.onPlayStateChangedToPlaylistView = { [weak self] isPlaying in
            self?.setPlayPauseButton()
        }

        PlayerManager.shared.onTimeUpdateToPlaylistView = { [weak self] seconds in
            guard let duration = PlayerManager.shared.player?.currentItem?.duration.seconds, !duration.isNaN else { return }
            self?.playProgressView.progress = Float(seconds / duration)
        }

        PlayerManager.shared.onPlayList = { [weak self] in
            /// playlist 삭제 시 tableView reload 시점 지연 시키기 위한 Tesk
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초 = 300,000,000ns
                self?.playListTableView.reloadData()
            }
        }
    }

    /// 이전곡 버튼 터치
    @IBAction func backwardButton(_ sender: Any) {
        PlayerManager.shared.moveBackward()
    }
    
    /// 재생 버튼 터치
    @IBAction func playButton(_ sender: Any) {
        PlayerManager.shared.togglePlayPause()
        setPlayPauseButton()
    }
    
    /// 다음곡 버튼 터치
    @IBAction func forwardButton(_ sender: Any) {
        Task { await PlayerManager.shared.moveForward() }
        setPlayPauseButton()
    }

    deinit {
        PlayerManager.shared.onTimeUpdateToPlaylistView = nil
        PlayerManager.shared.onPlayStateChangedToPlaylistView = nil
    }
}

// MARK: - TabelView DataSource
extension PlayListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PlayerManager.shared.playlist.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SongTableViewCell.self), for: indexPath) as! SongTableViewCell
        let model = PlayerManager.shared.playlist[indexPath.row]
        cell.setUI(model: model)

        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            PlayerManager.shared.removeSong(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

// MARK: - TableView Delegate
extension PlayListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlayerManager.shared.setCurrentIndex(indexPath.row)
        PlayerManager.shared.play()
    }
}
