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

        if UIDevice.current.userInterfaceIdiom != .pad {
                // iPhone일 때만 높이 고정
                collectionView.heightAnchor.constraint(equalToConstant: 300).isActive = true
            }
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

        let spacing: CGFloat = 8

        if isPad {
            // iPad에서는 가로 셀 수를 해상도에 따라 유동적으로 결정
            let isLandscape = view.frame.width > view.frame.height
            let numberOfColumns: CGFloat = isLandscape ? 5 : 4
            let totalSpacing = spacing * (numberOfColumns + 1)
            let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
            let cellHeight = min(width, screenHeight * 0.12)
            return CGSize(width: width, height: cellHeight)

        } else {
            // iPhone은 무조건 3 x 2 고정
            let numberOfColumns: CGFloat = 3
            let numberOfRows: CGFloat = 2

            let totalHorizontalSpacing = spacing * (numberOfColumns + 1)
            let width = (collectionView.bounds.width - totalHorizontalSpacing) / numberOfColumns

            // ⚠️ CollectionView 높이도 2줄에 맞게 고정해줘야 함!
            let totalVerticalSpacing = spacing * (numberOfRows + 1)
            let height = (collectionView.bounds.height - totalVerticalSpacing) / numberOfRows

            return CGSize(width: width, height: height)
        }
    }
}

