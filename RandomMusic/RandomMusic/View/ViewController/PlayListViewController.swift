import UIKit
import CoreData

class PlayListViewController: UIViewController {
    @IBOutlet weak var playListTableView: UITableView!
    @IBOutlet weak var playProgressView: UIProgressView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forButton: UIButton!
    
    /// 재생버튼 토글 Bool 변수
    var isPlay = true
    
    /// 재생, 이전곡, 다음곡 버튼 UIImage Symbol size
    let playConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular, scale: .large)
    let backforConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular, scale: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 재생, 뒤로, 앞으로 버튼 UI Setting
        setButtonUI()
        DataManager.shared.fetchedResults.delegate = self
    }
    
    /// 재생, 이전곡, 다음곡 버튼 UI Setting
    func setButtonUI() {
        let backImage = UIImage(systemName: "backward.frame.fill", withConfiguration: backforConfig)
        let playImage = UIImage(systemName: "play.circle.fill", withConfiguration: playConfig)
        let forImage = UIImage(systemName: "forward.frame.fill", withConfiguration: backforConfig)
        
        backButton.setImage(backImage, for: .normal)
        playButton.setImage(playImage, for: .normal)
        forButton.setImage(forImage, for: .normal)
    }
    
    /// 이전곡 버튼 터치
    @IBAction func backwardButton(_ sender: Any) {
        print("backward button")
    }
    
    /// 재생 버튼 터치
    @IBAction func playButton(_ sender: Any) {
        print("play button")
        
        isPlay.toggle()
        let image = isPlay ? UIImage(systemName: "play.circle.fill", withConfiguration: playConfig) : UIImage(systemName: "pause.circle", withConfiguration: playConfig)
        playButton.setImage(image, for: .normal)
    }
    
    /// 다음곡 버튼 터치
    @IBAction func forwardButton(_ sender: Any) {
        print("forward button")
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
            
        }
    }
}

// MARK: - TableView Delegate
extension PlayListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PlayListViewController: NSFetchedResultsControllerDelegate {

}
