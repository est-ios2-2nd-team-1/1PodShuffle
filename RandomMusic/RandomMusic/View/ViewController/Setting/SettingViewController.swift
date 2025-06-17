import UIKit

class SettingViewController: UIViewController {
    @IBOutlet weak var resetPreferenceButton: UIButton!
    @IBOutlet weak var resetPlaylistButton: UIButton!
    @IBOutlet weak var themeSwitch: UISwitch!
    @IBOutlet weak var statsStackView: UIStackView!

    private let preferenceManager = PreferenceManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 16.0, *) {
            themeSwitch.isOn = UITraitCollection.current.userInterfaceStyle == .dark
        } else {
            themeSwitch.isOn = false
        }
        themeSwitch.addTarget(self, action: #selector(themeSwitchChanged), for: .valueChanged)

        // 선호도 통계
        showGenreStatistics()
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

    // 다크모드 설정
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

    // 선호도 통계 나타내는 스택뷰: 바 + 선호도 퍼센트
    private func showGenreStatistics() {
        let percentages = preferenceManager.getGenrePercentage()

        statsStackView.arrangedSubviews.forEach{ $0.removeFromSuperview() }

        for (genre, percent) in percentages {
            let barCount = Int(percent / 10)
            let bar = String(repeating: "▓", count: barCount)
            let percentString = String(format: "%.2f", percent)
            let label = UILabel()
            label.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
            label.text = "[\(genre.rawValue): \(bar) \(percentString)%]"
            statsStackView.addArrangedSubview(label)
        }
    }
}


