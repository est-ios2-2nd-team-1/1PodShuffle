import UIKit

final class RecommendCell: UICollectionViewCell {
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!

    var songModel: SongModel?

    func configureUI(with songModel: SongModel) {
        mainImageView.layer.cornerRadius = 10
        mainImageView.image = UIImage(data: songModel.thumbnailData ?? Data())
        titleLabel.text = songModel.title
        artistLabel.text = songModel.artist
        self.songModel = songModel
    }
}
