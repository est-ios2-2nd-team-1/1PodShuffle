//
//  GenreCell.swift
//  RandomMusic
//
//  Created by 이유정 on 6/9/25.
//

import UIKit

class GenreCell: UICollectionViewCell {

    @IBOutlet weak var genreButton: UIButton!
    @IBOutlet weak var genreLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        genreButton.layer.cornerRadius = genreButton.bounds.height / 2
        genreButton.clipsToBounds = true
    }

    func configure(with genre: OnboardingGenre, selected: Bool) {
        genreButton.setImage(UIImage(named: genre.iconName), for: .normal)
        genreLabel.text = genre.name
        genreButton.isSelected = selected
        genreButton.setImage(UIImage(systemName: selected ? "checkmark.circle.fill" : "circle"), for: .selected)
    }

}
