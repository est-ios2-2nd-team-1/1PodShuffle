import UIKit

struct OnboardingGenre {
    let name: String
    let iconName: String
}


class OnBoardingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

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
        collectionView.dataSource = self
        collectionView.delegate = self
    }

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

    @objc func genreButtonTapped(_ sender: UIButton) {
        let genre = genres[sender.tag]
        if selectedGenres.contains(genre.name) {
            selectedGenres.remove(genre.name)
        } else if selectedGenres.count < 3 {
            selectedGenres.insert(genre.name)
        }
        collectionView.reloadItems(at: [IndexPath(item: sender.tag, section: 0)])
    }

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

}
