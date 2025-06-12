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
    
    var playImage: UIImage?
    
    var duration: Double?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 재생, 뒤로, 앞으로 버튼 UI Setting
        setButtonUI()
        
        playProgressView.progress = 0
        updateProgressView()
        callbackFunc()
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
       let section = 0
       let totalRows = playListTableView.numberOfRows(inSection: section)
       
       if totalRows == 0 {
           fetchPlaySong()
       } else {
           PlayerManager.shared.moveForward()
           //fetchPlaySong(totalRows: totalRows)
           callbackFunc()
       }
        setPlayPauseButton()
    }
    
    /// 재생/일시정지 버튼 UI
    //func setPlayPauseButton(isPlay: Bool) {
    func setPlayPauseButton() {
        playImage = PlayerManager.shared.isPlaying ?
                        UIImage(systemName: "pause.circle", withConfiguration: playConfig) :
                        UIImage(systemName: "play.circle.fill", withConfiguration: playConfig)
        playButton.setImage(playImage, for: .normal)
    }
    
    /// 재생, 이전곡, 다음곡 버튼 UI Setting
    func setButtonUI() {
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
    
    // 랜덤으로 노래 재생
    func fetchPlaySong(totalRows: Int? = nil) {
        Task {
            let song =  try await NetworkManager.shared.getMusic()
            
            let currentPlaylist = PlayerManager.shared.playlist
            let newPlaylist = currentPlaylist + [song]
            let newIndex = currentPlaylist.count

            PlayerManager.shared.setPlaylist(newPlaylist)
            PlayerManager.shared.setCurrentIndex(newIndex)
            
            /// 음악 play
            playSong(streamUrl: song.streamUrl)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.playListTableView.refreshControl?.endRefreshing()
                
            }
        }
    }
    
    /// ProgressView Update
    private func updateProgressView() {
        PlayerManager.shared.onTimeUpdate = { [weak self] seconds in
            guard let self = self, let duration = self.duration, duration > 0 else { return }
            let progress = Float(seconds / duration)
            DispatchQueue.main.async {
                self.playProgressView.progress = progress
            }
        }
    }
    
    private func callbackFunc() {
        PlayerManager.shared.onPlayStateChanged = { [weak self] isPlaying in
            self?.setPlayPauseButton()
        }
        
        PlayerManager.shared.loadDuration { [weak self] seconds in
            self?.duration = seconds
            self?.updateProgressView()
        }
        
        //PlayerManager.shared.onPlayList = { [weak self] in
        //    self?.playListTableView.reloadData()
        //}
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
            DataManager.shared.deleteSongData(at: indexPath)
            
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
