import UIKit

class SettingViewController: UIViewController {

    private let preferenceManager = PreferenceManager()

    private let resetButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {

        resetButton.setTitle("추천 알고리즘 초기화ㅏ", for: .normal)
        resetButton.backgroundColor = UIColor.systemBackground
    }


    @objc private func resetButtonTapped() {
        let alert = UIAlertController(
            title: "추천 알고리즘 초기화",
            message: "데이터가 모두 삭제됩니다. 계속하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
//        alert.addAction(UIAlertAction(title: "초기화", style: .destructive, handler: { _ in
//            self.preferenceManager.resetPreferences()
//        }))

        present(alert, animated: true, completion: nil)

    }

}


