import UIKit

/// 앱의 설정 화면을 관리하는 ViewController입니다.
/// 1. 라이트/다크 모드 스위치로 시스템 테마 변경
/// 2. 장르별 사용자의 선호도 통계 표시
/// 3. 사용자 선호도 및 재생목록 데이터 초기화
class SettingViewController: UIViewController {
    @IBOutlet weak var themeSwitch: UISwitch!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var preferenceView: UIView!

    /// 사용자 선호도 데이터 관리 객체
    private let preferenceManager = PreferenceManager()
    private var preferenceDatas: [(genre: Genre, percent: Double)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureInitialTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showGenreStatistics()
    }
    
    /// UI를 구성합니다.
    private func configureUI() {
        backView.layer.cornerRadius = 15
        preferenceView.layer.cornerRadius = 15
    }

    /// 초기 테마 상태 설정
    private func configureInitialTheme() {
        if UserDefaults.standard.string(forKey: "colorScheme") == "dark" {
            themeSwitch.isOn = true
        } else {
            themeSwitch.isOn = false
        }
        themeSwitch.addTarget(self, action: #selector(themeSwitchChanged), for: .valueChanged)
    }

    /// 장르별 선호도 통계를 가져옵니다.
    private func showGenreStatistics() {
        let percentages = preferenceManager.getGenrePercentage()
        let data = percentages.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
        preferenceDatas = data
        tableView.reloadData()
    }

    /// 재생목록 초기화 버튼 액션
    /// - Parameter sender: 초기화 버튼
    @IBAction func resetPlaylist(_ sender: Any) {
        let alert = UIAlertController(
            title: "재생목록 초기화",
            message: "재생목록이 모두 삭제됩니다. 계속하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "초기화", style: .destructive) { _ in
            PlayerManager.shared.clearPlaylist()
        })
        present(alert, animated: true)
    }

    /// 선호도 데이터 초기화 버튼 액션
    /// - Parameter sender: 초기화 버튼
    @IBAction func resetPreference(_ sender: Any) {
        let alert = UIAlertController(
            title: "선호도 데이터 초기화",
            message: "데이터가 모두 삭제됩니다. 계속하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "초기화", style: .destructive) { [weak self] _ in
            self?.preferenceManager.resetAllPreferences()
            self?.showGenreStatistics()
        })
        present(alert, animated: true)
    }

    /// 다크모드 스위치 값 변경 액션
    /// Parameter sender: 다크모드 스위치
    @IBAction func themeSwitchChanged(_ sender: UISwitch) {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = sender.isOn ? .dark : .light
                UserDefaults.standard.set(sender.isOn ? "dark" : "light", forKey: "colorScheme")
            }
        }
    }
}

extension SettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return preferenceDatas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PreferenceCell", for: indexPath)
        let data = preferenceDatas[indexPath.row]
        cell.textLabel?.text = data.genre.iconString + data.genre.rawValue.capitalized
        cell.detailTextLabel?.text = data.percent.description + "%"

        return cell
    }
}
