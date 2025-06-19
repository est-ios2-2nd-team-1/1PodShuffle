import UIKit

/// 플레이리스트 View에서 10곡씩 추가에 사용하는 셀입니다.
class CategoryCell: UICollectionViewCell {
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var mainLabel: UILabel!

    var genre: Genre?
    
    /// 장르를 통해 UI를 구성합니다.
    /// - Parameter genre: 어떤 장르인지 받습니다.
    func configureUI(with genre: Genre) {
        self.genre = genre
        mainLabel.text = "+ \(genre.rawValue)"
        mainView.layer.cornerRadius = mainView.frame.height / 2
        mainView.layer.borderWidth = 1
        mainView.layer.borderColor = genre.color.cgColor
    }
}
