import UIKit

/// 음악 취향에 맞춘 음악 제공 뷰 컨트롤러 객체입니다.
class HomeViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!

    /// 추천할 음악을 저장하는 저장 프로퍼티입니다.
    private var songs: [SongModel] = []
    /// Pull To Refresh를 제공하기 위한 저장 프로퍼티입니다.
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setData()
        setRefresh()
    }
    
    /// UI를 구성하고 컬렉션뷰를 설정합니다.
    private func configureUI() {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            return self.createSection(for: sectionIndex, environment)
        }

        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        collectionView.collectionViewLayout = layout
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.register(UINib(nibName: "RecommendCell", bundle: nil), forCellWithReuseIdentifier: "RecommendCell")
    }
    
    /// 추천할 음악 데이터를 불러옵니다.
    private func setData() {
        Task {
            let songModels = try await SongService().getMusics()
            loadSongs(from: songModels)
        }
    }

    /// Pull To Refresh를 위해 구성하는 메소드입니다.
    private func setRefresh() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    /// 추천할 음악 데이터를 뷰에 띄웁니다.
    /// - Parameter songModels: 추천할 음악 데이터들입니다.
    @MainActor
    private func loadSongs(from songModels: [SongModel]) {
        songs = songModels
        collectionView.reloadSections(IndexSet(integer: 1))
    }
    
    /// 섹션을 생성하는 메소드입니다.
    /// - Parameters:
    ///   - sectionIndex: 몇 번째 섹션인지 받습니다.
    ///   - environment: Size Class에 대응하기 위한 파라미터입니다.
    /// - Returns: 섹션을 반환합니다.
    private func createSection(for sectionIndex: Int, _ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch sectionIndex {
        case 0:
            return createFirstSection(environment)
        case 1:
            return createSecondSection(environment)
        default:
            return createSecondSection(environment)
        }
    }
    
    /// 첫 번째 섹션을 생성하는 메소드입니다.
    /// - Parameter environment: Size Class에 대응하기 위한 파라미터입니다.
    /// - Returns: 첫 번째 섹션을 반환합니다.
    private func createFirstSection(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))

        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let isPad = environment.traitCollection.horizontalSizeClass == .regular && environment.traitCollection.verticalSizeClass == .regular

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(isPad ? 0.33 : 0.5), heightDimension: .fractionalHeight(0.9))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.2))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = NSCollectionLayoutSpacing.flexible(5.0)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 5.0

        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        section.boundarySupplementaryItems = [sectionHeader]

        return section
    }

    /// 두 번째 섹션을 생성하는 메소드입니다.
    /// - Parameter environment: Size Class에 대응하기 위한 파라미터입니다.
    /// - Returns: 두 번째 섹션을 반환합니다.
    private func createSecondSection(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))

        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let isPad = environment.traitCollection.horizontalSizeClass == .regular && environment.traitCollection.verticalSizeClass == .regular

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(isPad ? 0.5 : 1.0), heightDimension: .fractionalHeight(0.9))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        section.boundarySupplementaryItems = [sectionHeader]

        return section
    }
    
    /// Pull to Refresh에서 동작하는 메소드입니다.
    @objc private func handleRefresh() {
        Task {
            try await Task.sleep(for: .seconds(1))
            let songModels = try await SongService().getMusics()
            loadSongs(from: songModels)
            refreshControl.endRefreshing()
        }
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return Genre.allCases.count
        case 1:
            return 10
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell

        switch indexPath.section {
        case 0:
            cell = setSectionFirst(collectionView, indexPath: indexPath)
        case 1:
            cell = setSectionSecond(collectionView, indexPath: indexPath)
        default:
            cell = UICollectionViewCell()
            break
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "header",
                for: indexPath
            ) as? HeaderView else {
                return UICollectionReusableView()
            }

            let traitCollection = collectionView.traitCollection
            let fontSize: CGFloat = traitCollection.verticalSizeClass == .regular && traitCollection.horizontalSizeClass == .regular ? 45 : 30

            switch indexPath.section {
            case 0:
                header.titleLabel.text = "Find Your Music"
                header.titleLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            case 1:
                header.titleLabel.text = "Recommend You"
                header.titleLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            default:
                break
            }

            return header
        }

        return UICollectionReusableView()
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if let homeCell = collectionView.cellForItem(at: indexPath) as? HomeCell {
                if let genre = homeCell.genre {
                    PlayerManager.shared.addSongs(from: genre)
                }
            }
        case 1:
            if let recommendCell = collectionView.cellForItem(at: indexPath) as? RecommendCell {
                if let song = recommendCell.songModel {
                    PlayerManager.shared.addSong(song)
                }
            }
        default:
            break
        }
    }
}

private extension HomeViewController {
    /// 첫 번째 섹션에서 보여질 아이템(셀)을 구성합니다.
    /// - Parameters:
    ///   - collectionView: 루트 컬렉션뷰를 받습니다.
    ///   - indexPath: 셀의 위치를 받습니다.
    /// - Returns: 셀을 반환합니다.
    func setSectionFirst(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: HomeCell.self), for: indexPath) as! HomeCell
        cell.configureUI(genre: Genre.allCases[indexPath.item])
        return cell
    }

    /// 두 번째 섹션에서 보여질 아이템(셀)을 구성합니다.
    /// - Parameters:
    ///   - collectionView: 루트 컬렉션뷰를 받습니다.
    ///   - indexPath: 셀의 위치를 받습니다.
    /// - Returns: 셀을 반환합니다.
    func setSectionSecond(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: RecommendCell.self), for: indexPath) as! RecommendCell
        if songs.isEmpty { return cell }
        cell.configureUI(with: songs[indexPath.item])
        return cell
    }
}
