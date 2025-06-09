import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var singerLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var speedButton: UIButton!

    // TODO: UI 체크용 임시 로컬 변수 -> 추후 제거
    var isPlaying = false
    var isDisliked = false
    var isLiked = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bindData()
    }

    private func setupUI() {
        // 앨범 커버 원형 설정
    	coverImageView.layer.cornerRadius = coverImageView.frame.width / 2
        coverImageView.clipsToBounds = true
    }

    private func bindData() {
        titleLabel.text = "Willow"
        singerLabel.text = "Taylor Swift"
    }
}
