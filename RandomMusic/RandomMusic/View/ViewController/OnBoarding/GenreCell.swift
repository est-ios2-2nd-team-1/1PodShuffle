//
//  GenreCell.swift
//  RandomMusic
//
//  Created by 이유정 on 6/9/25.
//

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

<<<<<<< Updated upstream:RandomMusic/RandomMusic/View/ViewController/OnBoarding/GenreCell.swift
    func configure(with genre: Genre, selected: Bool) {
        genreButton.setImage(UIImage(named: genre.iconName), for: .normal)
        genreLabel.text = genre.name
=======
    func configure(with genre: OnboardingGenre, selected: Bool) {

        let imageSize = CGSize(
            width: genreButton.bounds.width - 24,
            height: genreButton.bounds.height - 24
        )

        if let image = UIImage(named: genre.iconName)?.resize(to: imageSize) {
            genreButton.setImage(image, for: .normal)
        }

>>>>>>> Stashed changes:RandomMusic/RandomMusic/View/Cell/GenreCell.swift
        genreButton.isSelected = selected
        let checkmarkImage = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
        genreButton.setImage(checkmarkImage, for: .selected)
        genreButton.backgroundColor = selected ? UIColor(named: "SelectedColor") : UIColor(named: "MainColor")

        genreLabel.text = genre.name
    }

}
