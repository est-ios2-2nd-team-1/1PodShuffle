//
//  HomeViewController.swift
//  RandomMusic
//
//  Created by 강대훈 on 6/16/25.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!

    private var songs: [SongModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    private func configureUI() {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            return self.createSection(for: sectionIndex, environment)
        }

        collectionView.collectionViewLayout = layout
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.register(UINib(nibName: "RecommendCell", bundle: nil), forCellWithReuseIdentifier: "RecommendCell")

        Task {
            let songModels = try await SongService().getMusics()
            loadSongs(from: songModels)
        }
    }

    @MainActor
    private func loadSongs(from songModels: [SongModel]) {
        songs = songModels
        collectionView.reloadSections(IndexSet(integer: 1))
    }

    private func createSection(for sectionIndex: Int, _ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch sectionIndex {
        case 0:
            return createFirstSection(environment)
        case 1:
            return createSecondSection(environment)
        default:
            return createSingleColumnSection()
        }
    }

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

    private func createSingleColumnSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.9))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.1))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

        return section
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
            cell = setSectionZero(collectionView, indexPath: indexPath)

        case 1:
            cell = setSectionOne(collectionView, indexPath: indexPath)
        default:
            cell = UICollectionViewCell()
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
    func setSectionZero(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: HomeCell.self), for: indexPath) as! HomeCell
        cell.setTitle(genre: Genre.allCases[indexPath.item])
        return cell
    }

    func setSectionOne(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: RecommendCell.self), for: indexPath) as! RecommendCell
        if songs.isEmpty { return cell }
        cell.configureUI(with: songs[indexPath.item])
        return cell
    }
}
