import UIKit

class OnBoardingViewController: UIViewController {

    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!

    var selectedGenres: Set<String> = []

    @IBAction func skipButtonTapped(_ sender: UIButton) {
        // 건너뛰기 버튼을 눌렀을 때
        let mainVC = storyboard?.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
//        mainVC.selectedGenres = []
        present(mainVC, animated: true)

        UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        // 확인 버튼을 눌렀을 때
        let mainVC = storyboard?.instantiateViewController(withIdentifier: "mainViewController") as! MainViewController
//        mainVC.selectedGenres = selectedGenres
        present(mainVC, animated: true)

        UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

    }
}
