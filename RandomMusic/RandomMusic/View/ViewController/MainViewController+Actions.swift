import UIKit

extension MainViewController {
    @IBAction func dislikeTapped(_ sender: Any) {
        isDisliked.toggle()
        if isDisliked { isLiked = false }
        updateLikeDislikeButtons()
    }
    
    @IBAction func likeTapped(_ sender: Any) {
        isLiked.toggle()
        if isLiked { isDisliked = false }
        updateLikeDislikeButtons()
    }

    @IBAction func repeatTapped(_ sender: Any) {
        // TODO: 한곡반복 버튼 클릭 로직 추가
    }

    @IBAction func playPauseTapped(_ sender: UIButton) {
        isPlaying.toggle()
        updatePlayPauseButton()
    }

    @IBAction func speedTapped(_ sender: Any) {
        // TODO: 재생속도 버튼 클릭 로직 추가
    }
}
