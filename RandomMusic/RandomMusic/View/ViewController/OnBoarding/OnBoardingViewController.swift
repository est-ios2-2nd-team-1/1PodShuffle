import UIKit

// 음악 재생 전 장르 선택을 위한 온보딩 화면
// 한 번 선택 후에는 초기화하지 않는다면 생기지 않는 화면


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

    // 음악 장르 선택 갯수 제한: 0개 ~ 3개 (4번째부터는 선택 불가능)
    private func setupTitleLabel() {
        let fullText = "선호하는 장르를 선택해주세요 (최대 3개 선택 가능)"
        let targetText = "(최대 3개 선택 가능)"
        
        let attributedString = NSMutableAttributedString(string: fullText)
        let titleFont = UIFont.systemFont(ofSize: 19)
        attributedString.addAttribute(.font, value: titleFont, range: (fullText as NSString).range(of: "선호하는 장르를 선택해주세요"))
        
        // 괄호 부분만 폰트 작은 크기로 변경
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

    // 장르 선택 버튼
    @objc func genreButtonTapped(_ sender: UIButton) {
        let genre = genres[sender.tag]
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else if selectedGenres.count < 3 {
            selectedGenres.insert(genre)
        }
        collectionView.reloadItems(at: [IndexPath(item: sender.tag, section: 0)])
    }
    

    // 건너뛰기 버튼: 전체 장르에 동일하게 기본 선호도 점수 부여
    @IBAction func skipButtonTapped(_ sender: UIButton) {
        preferenceManager.initializePreferences(initialPreferredGenres: Genre.allCases)
        
        toMainVC()
    }


    // 확인 버튼: 선택된 장르만 저장 - 선택된 장르에만 선호도 점수 부여
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        preferenceManager.initializePreferences(initialPreferredGenres: Array(selectedGenres))
        
        toMainVC()
    }

    // 메인 화면으로 이동
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

            let totalVerticalSpacing = spacing * (numberOfRows + 1)
            let height = (collectionView.bounds.height - totalVerticalSpacing) / numberOfRows

            return CGSize(width: width, height: height)
        }
    }
}

