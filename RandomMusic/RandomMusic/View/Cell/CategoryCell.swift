import UIKit

class CategoryCell: UICollectionViewCell {
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var mainLabel: UILabel!

    var genre: Genre?

    func configureUI(with genre: Genre) {
        self.genre = genre
        mainLabel.text = "+ \(genre.rawValue)"
        mainView.layer.cornerRadius = mainView.frame.height / 2
        mainView.layer.borderWidth = 1
        mainView.layer.borderColor = genre.color.cgColor
    }
}
