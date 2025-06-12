import UIKit

class SongTableViewCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setUI(model: SongModel) {
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.bounds.width / 3

        if let thumbnailImage = model.thumbnailData {
            thumbnailImageView.image = UIImage(data: thumbnailImage)
        }

        artistLabel.text = model.artist
        titleLabel.text = model.title
    }
}
