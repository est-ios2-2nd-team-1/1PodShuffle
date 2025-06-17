// 온보딩 화면에서 선택하는 장르
// 셀 사이즈 유동적이게 조절 가능하도록 설정

import UIKit

extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

class GenreCell: UICollectionViewCell {
    @IBOutlet weak var genreButton: UIButton!
    @IBOutlet weak var genreLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        genreButton.imageView?.contentMode = .scaleAspectFit
        genreButton.clipsToBounds = true
        genreButton.backgroundColor = UIColor(named: "MainColor")
        genreButton.tintColor = UIColor(named: "MainColor")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        genreButton.layer.cornerRadius = genreButton.bounds.height / 2
    }

    func configure(with genre: Genre, selected: Bool) {

        let imageSize = CGSize(width: genreButton.bounds.width - 24, height: genreButton.bounds.height - 24)
        if let image = UIImage(named: genre.rawValue.lowercased())?.resize(to: imageSize) {
            genreButton.setImage(image, for: .normal)
        }

        genreButton.isSelected = selected
        let checkmarkImage = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
        genreButton.setImage(checkmarkImage, for: .selected)
        genreButton.backgroundColor = selected ? UIColor(named: "SelectedColor") : UIColor(named: "MainColor")

        genreLabel.text = genre.rawValue
    }
}
