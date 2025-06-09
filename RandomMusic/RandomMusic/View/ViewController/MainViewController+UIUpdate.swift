import UIKit

extension MainViewController {
    func updatePlayPauseButton() {
        let icon = isPlaying ? "pause.circle.fill" : "play.circle.fill"

        playPauseButton.setImage(UIImage(systemName: icon), for: .normal)
    }

    func updateLikeDislikeButtons() {
        let likeIcon = isLiked ? "hand.thumbsup.fill" : "hand.thumbsup"
        let dislikeIcon = isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown"

        likeButton.setImage(UIImage(systemName: likeIcon), for: .normal)
        dislikeButton.setImage(UIImage(systemName: dislikeIcon), for: .normal)
    }
}
