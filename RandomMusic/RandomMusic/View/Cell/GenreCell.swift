/// 온보딩 화면에서 선택하는 장르 셀입니다.
///
/// 셀 크기는 컬렉션 뷰의 레이아웃에 따라 유동적으로 조절됩니다.
/// 셀은 사용자가 탭하면 선택/해제 상태가 바뀌며,
/// 선택시 체크마크 아이콘과 배경색이 변경됩니다.

import UIKit

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

    /// 셀을 장르와 선택 상태애 맞게 설정합니다.
    /// Parameter:
    /// - genre: 장르 정보
    /// - selected: 선택 여부. true면 체크마크와 선택 색상이 나타납니다.
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

/// 이미지를 지정한 크기로 리사이즈합니다.
/// Parameter size: 리사이즈할 크기
/// Returns: 리사이즈된 UIImage
extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
