import UIKit

class PlayListViewController: UIViewController {

    @IBOutlet weak var playListTableView: UITableView!
    @IBOutlet weak var playProgressView: UIProgressView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func backwardButton(_ sender: Any) {
        print("backward button")
    }
    
    @IBAction func playButton(_ sender: Any) {
        print("play button")
    }
    
    @IBAction func forwardButton(_ sender: Any) {
        print("forward button")
    }
}

extension PlayListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SongTableViewCell.self), for: indexPath) as! SongTableViewCell
        
        cell.thumbnailImageView.image = UIImage(systemName: "music.note.house")
        cell.titleLabel.text = "Willow"
        cell.artistLabel.text = "Taylor Swift"
        
        return cell
    }
}
