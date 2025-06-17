//
//  HomeCell.swift
//  RandomMusic
//
//  Created by 강대훈 on 6/16/25.
//

import UIKit

final class HomeCell: UICollectionViewCell {
    @IBOutlet weak var mainImageView: UIImageView!

    var genre: Genre?

    func setTitle(genre: Genre) {
        DispatchQueue.global().async {
            let image = genre.image
            Task { @MainActor in
                self.mainImageView.image = image
            }
        }
        
        mainImageView.layer.cornerRadius = 10
        self.genre = genre
    }
}
