import UIKit

/// UIViewController에 공통 알림 기능을 추가하는 확장
extension UIViewController {

    /// 첫 번째 곡 알림을 표시합니다.
    func showFirstSongAlert() {
        let alert = UIAlertController(
            title: "첫번째 곡입니다.",
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
