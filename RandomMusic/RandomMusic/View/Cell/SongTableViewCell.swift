import UIKit

class SongTableViewCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    private var isPlaying: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isPlaying = false
        setCellBgColor()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setCellBgColor()
    }
    
    func setUI(model: SongModel, isPlaying: Bool) {
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.bounds.width / 3
        
        if let thumbnailImage = model.thumbnailData {
            thumbnailImageView.image = UIImage(data: thumbnailImage)
        }
        
        artistLabel.text = model.artist
        titleLabel.text = model.title
        
        self.isPlaying = isPlaying
        setCellBgColor()
    }
    
    /// select cell backgroundColor setting
    func setCellBgColor() {
        UIView.animate(withDuration: 0.4) {
            self.backgroundColor = self.isPlaying ? .main : .clear
        }
    }
}
