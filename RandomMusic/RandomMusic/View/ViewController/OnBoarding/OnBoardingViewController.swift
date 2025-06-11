import UIKit

struct OnboardingGenre {
    let name: String
    let iconName: String
}


class OnBoardingViewController: UIViewController {

    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!

    var genres: [OnboardingGenre] = [
        OnboardingGenre(name: "Rock", iconName: "rock"),
        OnboardingGenre(name: "HipHop", iconName: "hiphop"),
        OnboardingGenre(name: "Jazz", iconName: "jazz"),
        OnboardingGenre(name: "Pop", iconName: "pop"),
        OnboardingGenre(name: "R&B", iconName: "rb"),
        OnboardingGenre(name: "Classic", iconName: "classic"),
        OnboardingGenre(name: "Dance", iconName: "dance"),
        OnboardingGenre(name: "Ballad", iconName: "ballad"),
        OnboardingGenre(name: "EDM", iconName: "edm")
    ]

    var selectedGenres: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupTitleLabel()
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    private func setupTitleLabel() {
        let fullText = "선호하는 장르를 선택해주세요 (최대 3개 선택 가능)"
        let targetText = "(최대 3개 선택 가능)"

        let attributedString = NSMutableAttributedString(string: fullText)

        let titleFont = UIFont.systemFont(ofSize: 19)
        attributedString.addAttribute(.font, value: titleFont, range: (fullText as NSString).range(of: "선호하는 장르를 선택해주세요"))

        // 폰트 부분변경
        let subFont = UIFont.systemFont(ofSize: 13)
        attributedString.addAttribute(.font, value: subFont, range: (fullText as NSString).range(of: targetText))

        titleLabel.attributedText = attributedString
    }
}


extension OnBoardingViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return genres.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GenreCell", for: indexPath) as! GenreCell
        let genre = genres[indexPath.item]
        let isSelected = selectedGenres.contains(genre.name)

        cell.configure(with: genre, selected: isSelected)
        cell.genreButton.tag = indexPath.item
        cell.genreButton.addTarget(self, action: #selector(genreButtonTapped(_:)), for: .touchUpInside)
        return cell
    }
}

extension OnBoardingViewController: UICollectionViewDelegate {
}

extension OnBoardingViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 40) / 3
        let height = width + 20
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
}

extension OnBoardingViewController {

    // 장르 선택 제한: 3개 이하
    @objc func genreButtonTapped(_ sender: UIButton) {
        let genre = genres[sender.tag]
        if selectedGenres.contains(genre.name) {
            selectedGenres.remove(genre.name)
        } else if selectedGenres.count < 3 {
            selectedGenres.insert(genre.name)
        }
        collectionView.reloadItems(at: [IndexPath(item: sender.tag, section: 0)])
    }


    @IBAction func skipButtonTapped(_ sender: UIButton) {
        // 건너뛰기 버튼을 눌렀을 때
        toMainVC()
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        // 확인 버튼을 눌렀을 때
        toMainVC()
    }

    private func toMainVC() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainVC = mainStoryboard.instantiateInitialViewController() {
            if let windowScene = view.window?.windowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate,
               let window = sceneDelegate.window {

                window.rootViewController = mainVC
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            }
        }

        UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
    }
}
