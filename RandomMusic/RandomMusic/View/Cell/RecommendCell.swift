import UIKit

/// HomeView에서 사용하는 셀입니다. 사용자의 장르에 따라 노래를 추천하는 셀입니다.
final class RecommendCell: UICollectionViewCell {
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!

    var songModel: SongModel?
    
    /// 음악 데이터를 통해 UI를 구성합니다.
    /// - Parameter songModel: 음악 데이터를 받습니다.
    func configureUI(with songModel: SongModel) {
        mainImageView.layer.cornerRadius = 10
        mainImageView.image = UIImage(data: songModel.thumbnailData ?? Data())
        titleLabel.text = songModel.title
        artistLabel.text = songModel.artist
        self.songModel = songModel
    }
}
