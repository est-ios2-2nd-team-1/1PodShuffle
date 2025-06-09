import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var singerLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Willow"
        singerLabel.text = "Taylor Swift"
    }
}
