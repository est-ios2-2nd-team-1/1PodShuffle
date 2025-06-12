import UIKit
import CoreData
import AVKit

class PlayListViewController: UIViewController {
    @IBOutlet weak var playListTableView: UITableView!
    @IBOutlet weak var playProgressView: UIProgressView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forButton: UIButton!

    // 의존성 주입
    private lazy var songService = SongService()

    /// 재생, 이전곡, 다음곡 버튼 UIImage Symbol size
    let playConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
    let backforConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular, scale: .large)
    var playImage: UIImage?
    var duration: Double?

    override func viewDidLoad() {
        super.viewDidLoad()
        setButtonUI()
        callbackFunc()
        playProgressView.progress = 0
    }

    /// 재생/일시정지 버튼 UI
    private func setPlayPauseButton() {
        playImage = PlayerManager.shared.isPlaying ?
                        UIImage(systemName: "pause.circle", withConfiguration: playConfig) :
                        UIImage(systemName: "play.circle.fill", withConfiguration: playConfig)
        playButton.setImage(playImage, for: .normal)
    }

    /// 재생, 이전곡, 다음곡 버튼 UI Setting
    private func setButtonUI() {
        let backImage = UIImage(systemName: "backward.frame.fill", withConfiguration: backforConfig)
        let forImage = UIImage(systemName: "forward.frame.fill", withConfiguration: backforConfig)

        backButton.setImage(backImage, for: .normal)
        forButton.setImage(forImage, for: .normal)

        setPlayPauseButton()
    }

    /// 재생/일시정지 버튼
    func playSong(streamUrl: String) {
        PlayerManager.shared.play()
        callbackFunc()
    }

    /// ProgressView Update
    private func callbackFunc() {
        PlayerManager.shared.onPlayStateChangedToPlaylistView = { [weak self] isPlaying in
            self?.setPlayPauseButton()
        }

        PlayerManager.shared.loadDuration { [weak self] seconds in
            self?.duration = seconds
        }

        PlayerManager.shared.onTimeUpdateToPlaylistView = { [weak self] seconds in
            guard let self = self, let duration = self.duration, duration > 0 else { return }
            let progress = Float(seconds / duration)
            DispatchQueue.main.async {
                self.playProgressView.progress = progress
            }
        }

        PlayerManager.shared.onPlayList = { [weak self] in
            self?.playListTableView.reloadData()
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
        Task {
            await PlayerManager.shared.moveForward()
        }
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

        if let thumbnailImage = model.thumbnailData {
            cell.thumbnailImageView.image = UIImage(data: thumbnailImage)
        }
        cell.artistLabel.text = model.artist
        cell.titleLabel.text = model.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            PlayerManager.shared.pause()
            setPlayPauseButton()
        }
    }
}

// MARK: - TableView Delegate
extension PlayListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = PlayerManager.shared.playlist[indexPath.row]
        PlayerManager.shared.setCurrentIndex(indexPath.row)
        
        let streamUrl = song.streamUrl
        playSong(streamUrl: streamUrl)
        setPlayPauseButton()

        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
    }
}
