import UIKit

class CategoryCell: UICollectionViewCell {
    @IBOutlet weak var categoryButton: UIButton!

    var genre: Genre?

    func configureUI(with genre: Genre) {
        self.genre = genre
        categoryButton.setTitle(genre.rawValue, for: .normal)
        categoryButton.layer.cornerRadius = categoryButton.frame.height / 2
        categoryButton.layer.borderWidth = 1
        categoryButton.layer.borderColor = UIColor.red.cgColor
    }
}
