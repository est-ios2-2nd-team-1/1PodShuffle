import UIKit
import MarqueeLabel

class SongTableViewCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var artistLabel: MarqueeLabel!
    
    private var isPlaying: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupMarqueeLabels()
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
    
    /// cell setting
    ///
    /// - Parameter model: SongMel을 파라미터로 받아 lebel, image를 세팅하기 위한 파라미터
    /// - Parameter isPlaing: 재생 상태를 파라미터로 받아 cell의 backgrounColor를 세팅하기 위한 파라미터
    ///
    /// PlayListVC로 부터 전달 값 전달 받아 cell을 세탕합니다
    func configureCell(model: SongModel, isPlaying: Bool) {
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
    private func setCellBgColor() {
        UIView.animate(withDuration: 0.4) {
            self.backgroundColor = self.isPlaying ? .main : .clear
        }
    }
    
    /// MarqueeLabel 초기화 설정
    private func setupMarqueeLabels() {
        // Title Label 마키 설정
        titleLabel.type = .continuous
        titleLabel.speed = .duration(15.0)
        titleLabel.animationCurve = .linear
        titleLabel.fadeLength = 10.0
        titleLabel.leadingBuffer = 0
        titleLabel.trailingBuffer = 0
        
        // Artist Label 마키 설정
        artistLabel.type = .continuous
        artistLabel.speed = .duration(18.0)
        artistLabel.animationCurve = .linear
        artistLabel.fadeLength = 10.0
        artistLabel.leadingBuffer = 0
        artistLabel.trailingBuffer = 0
    }
}
