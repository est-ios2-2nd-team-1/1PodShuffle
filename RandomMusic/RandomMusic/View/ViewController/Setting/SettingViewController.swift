import UIKit

class SettingViewController: UIViewController {

    @IBOutlet weak var resetButton: UIButton!


    private let preferenceManager = PreferenceManager()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // 선호도 데이터 초기화
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "추천 알고리즘 초기화",
            message: "데이터가 모두 삭제됩니다. 계속하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "초기화", style: .destructive, handler: { _ in
            self.preferenceManager.resetAllPreferences()
            PlayerManager.shared.clearPlaylist()
        }))

        present(alert, animated: true, completion: nil)

    }
}



