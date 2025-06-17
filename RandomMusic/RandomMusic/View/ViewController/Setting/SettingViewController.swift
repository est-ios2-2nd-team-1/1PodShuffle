import UIKit

class SettingViewController: UIViewController {
    @IBOutlet weak var resetPreferenceButton: UIButton!
    @IBOutlet weak var resetPlaylistButton: UIButton!
    @IBOutlet weak var themeSwitch: UISwitch!

    private let preferenceManager = PreferenceManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 16.0, *) {
            themeSwitch.isOn = UITraitCollection.current.userInterfaceStyle == .dark
        } else {
            themeSwitch.isOn = false
        }
        themeSwitch.addTarget(self, action: #selector(themeSwitchChanged), for: .valueChanged)
    }

    // 선호도 데이터 초기화
    @IBAction func resetPreferenceButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "선호도 데이터 초기화",
            message: "데이터가 모두 삭제됩니다. 계속하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "초기화", style: .destructive) { _ in
            self.preferenceManager.resetAllPreferences()
        })
        present(alert, animated: true, completion: nil)

    }

    // 재생목록 초기화
    @IBAction func resetPlaylistButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "재생목록 초기화",
            message: "재생목록이 모두 삭제됩니다. 계속하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "초기화", style: .destructive) { _ in
            PlayerManager.shared.clearPlaylist()
        })
        present(alert, animated: true, completion: nil)
    }

    @IBAction func themeSwitchChanged(_ sender: UISwitch) {
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = sender.isOn ? .dark :  .light
                }
            }
        }
    }
}



