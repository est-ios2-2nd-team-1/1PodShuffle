import UIKit
import CoreData
import AVKit

class PlayListViewController: UIViewController {
    @IBOutlet weak var playListTableView: UITableView!
    @IBOutlet weak var playProgressView: UIProgressView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forButton: UIButton!
    
    /// 재생중인지 확인
    var isPlaying = true
    
    /// 재생, 이전곡, 다음곡 버튼 UIImage Symbol size
    let playConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular, scale: .large)
    let backforConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular, scale: .large)
    
    var playImage: UIImage? {
        isPlaying ? UIImage(systemName: "play.circle.fill", withConfiguration: playConfig) : UIImage(systemName: "pause.circle", withConfiguration: playConfig)
    }
    
    // AVPlayer
    var player: AVPlayer?
    var playerItem: AVPlayerItem?

    //var song: SongModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 재생, 뒤로, 앞으로 버튼 UI Setting
        setButtonUI()
        
        /// NSFetchedResultsControllerDelegate Delegate
        DataManager.shared.fetchedResults.delegate = self
    }
    
    /// 재생, 이전곡, 다음곡 버튼 UI Setting
    func setButtonUI() {
        let backImage = UIImage(systemName: "backward.frame.fill", withConfiguration: backforConfig)
        let forImage = UIImage(systemName: "forward.frame.fill", withConfiguration: backforConfig)
        
        backButton.setImage(backImage, for: .normal)
        playButton.setImage(playImage, for: .normal)
        forButton.setImage(forImage, for: .normal)
    }
    
    /// 이전곡 버튼 터치
    @IBAction func backwardButton(_ sender: Any) {
        
    }
    
    /// 재생 버튼 터치
    @IBAction func playButton(_ sender: Any) {
        isPlaying.toggle()
        playButton.setImage(playImage, for: .normal)
        
        isPlaying ? PlayerManager.shared.pause() : PlayerManager.shared.resume()
    }
    
    /// 다음곡 버튼 터치
    @IBAction func forwardButton(_ sender: Any) {
        Task {
            let song =  try await NetworkManager.shared.getMusic()
            
            /// 음악 play
            playSong(streamUrl: song.streamUrl)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.playListTableView.refreshControl?.endRefreshing()
                
                /// tableView 맨밑으로 이동
                //let section = 0
                //let rowCount = self?.playListTableView.numberOfRows(inSection: section) ?? 0
                //if rowCount > 0 {
                //    let indexPath = IndexPath(row: rowCount - 1, section: section)
                //    self?.playListTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                //}
            }
            
            playButton.setImage(playImage, for: .normal)
        }
    }
    
    // MARK: - 스트리밍 시작
    func playSong(streamUrl: String) {
        player?.pause()
        player = nil
        
        PlayerManager.shared.play()
       
        isPlaying = false
    }
}

// MARK: - TabelView DataSource
extension PlayListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return DataManager.shared.fetchedResults.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = DataManager.shared.fetchedResults.sections else {
            return 0
        }

        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SongTableViewCell.self), for: indexPath) as! SongTableViewCell
        
        let model = DataManager.shared.fetchedResults.object(at: indexPath)

        cell.thumbnailImageView.image = model.thumbnailImage
        cell.artistLabel.text = model.artist
        cell.titleLabel.text = model.title

        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            DataManager.shared.deleteSongData(at: indexPath)
            
            PlayerManager.shared.pause()
            
            isPlaying = true
            playButton.setImage(playImage, for: .normal)
        }
    }
}

// MARK: - TableView Delegate
extension PlayListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let song = DataManager.shared.fetchedResults.object(at: indexPath)

        Task {
            guard let streamUrl = song.streamUrl else { return }
            playSong(streamUrl: streamUrl)

            playButton.setImage(playImage, for: .normal)
        }
    }
}

// MARK: - NSFetchedResultsController Delegate
extension PlayListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        playListTableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                if let insertIndexPath = newIndexPath {
                    playListTableView.insertRows(at: [insertIndexPath], with: .automatic)
                }
            case .delete:
                if let deleteIndexPath = indexPath {
                    playListTableView.deleteRows(at: [deleteIndexPath], with: .automatic)
                }
            case .move:
                if let originalIndexPath = indexPath, let targetIndexPath = newIndexPath {
                    playListTableView.moveRow(at: originalIndexPath, to: targetIndexPath)
                }
            default:
                break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        playListTableView.endUpdates()
    }
}
