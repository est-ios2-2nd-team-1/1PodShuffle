import UIKit

/// HomeView에서 사용하는 셀입니다. 장르를 표현합니다.
final class HomeCell: UICollectionViewCell {
    @IBOutlet weak var mainImageView: UIImageView!

    var genre: Genre?

    /// 장르를 통해 UI를 구성합니다.
    /// - Parameter genre: 어떤 장르인지 받습니다.
    func configureUI(genre: Genre) {
        mainImageView.image = genre.image
        mainImageView.layer.cornerRadius = 10
        self.genre = genre
    }
}
