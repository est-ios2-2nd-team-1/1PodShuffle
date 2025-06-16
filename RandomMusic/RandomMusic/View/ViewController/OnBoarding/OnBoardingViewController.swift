import UIKit


class OnBoardingViewController: UIViewController {
    
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var genres: [Genre] = Genre.allCases
    
    var selectedGenres: Set<Genre> = []
    private let preferenceManager = PreferenceManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupTitleLabel()
        adjustLayoutForDevice()
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
    
    private func adjustLayoutForDevice() {
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight <= 568 {
            let fullText = "선호하는 장르를 선택해주세요 (최대 3개 선택 가능)"
            let targetText = "(최대 3개 선택 가능)"
            let attributedString = NSMutableAttributedString(string: fullText)
            let titleFont = UIFont.systemFont(ofSize: 14)
            attributedString.addAttribute(.font, value: titleFont, range: (fullText as NSString).range(of: "선호하는 장르를 선택해주세요"))
            let subFont = UIFont.systemFont(ofSize: 11)
            attributedString.addAttribute(.font, value: subFont, range: (fullText as NSString).range(of: targetText))
            titleLabel.attributedText = attributedString
            skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            skipButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            confirmButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        }
    }

    // 장르 선택 제한: 3개 이하
    @objc func genreButtonTapped(_ sender: UIButton) {
        let genre = genres[sender.tag]
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else if selectedGenres.count < 3 {
            selectedGenres.insert(genre)
        }
        collectionView.reloadItems(at: [IndexPath(item: sender.tag, section: 0)])
    }
    
    
    @IBAction func skipButtonTapped(_ sender: UIButton) {
        // 건너뛰기: 전체 장르에 기본 점수 부여
        preferenceManager.initializePreferences(initialPreferredGenres: Genre.allCases)
        
        toMainVC()
    }
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        // 확인: 선택된 장르만 저장
        
        preferenceManager.initializePreferences(initialPreferredGenres: Array(selectedGenres))
        
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

extension OnBoardingViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return genres.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GenreCell", for: indexPath) as! GenreCell
        let genre = genres[indexPath.item]
        let isSelected = selectedGenres.contains(genre)
        cell.configure(with: genre, selected: isSelected)
        cell.genreButton.tag = indexPath.item
        cell.genreButton.addTarget(self, action: #selector(genreButtonTapped(_:)), for: .touchUpInside)
        return cell
    }
}

extension OnBoardingViewController: UICollectionViewDelegate {}

extension OnBoardingViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = view.frame.width > view.frame.height
        
        let numberOfColumns: CGFloat = {
            if isPad {
                return isLandscape ? 5 : 4
            } else {
                return screenHeight <= 568 ? 2 : 3
            }
        }()
        let spacing: CGFloat = screenHeight <= 568 ? 6 : 8
        let totalSpacing = spacing * (numberOfColumns + 1)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        let cellHeight = min(width, screenHeight * 0.12)
        return CGSize(width: width, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let screenHeight = UIScreen.main.bounds.height
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPad {
            return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        } else {
            let spacing: CGFloat = screenHeight <= 568 ? 4 : 6
            return UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        
        if isPad {
            return 6
        } else {
            return screenHeight <= 568 ? 3 : 5
        }
    }
}
