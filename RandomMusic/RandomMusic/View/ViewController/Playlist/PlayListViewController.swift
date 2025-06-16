import UIKit

class PlayListViewController: UIViewController {
    @IBOutlet weak var playListTableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var playProgressView: UIProgressView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forButton: UIButton!
    @IBOutlet weak var dismissImageButton: UIButton!

    /// Throttle 객체
    private let throttle = Throttle()

    /// 재생, 이전곡, 다음곡 버튼 UIImage Symbol size
    private let playConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular, scale: .large)
    private let backforConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setConfigureUI()
        bindPlayerCallbacks()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollSelectPlaySong()
    }

    /// UI Setting
    private func setConfigureUI() {
        let backImage = UIImage(systemName: "backward.frame.fill", withConfiguration: backforConfig)
        let forImage = UIImage(systemName: "forward.frame.fill", withConfiguration: backforConfig)

        backButton.setImage(backImage, for: .normal)
        forButton.setImage(forImage, for: .normal)

        setPlayPauseButton()

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 30
        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        collectionView.collectionViewLayout = flowLayout
        
        setDismissImageButton()
    }

    /// 재생/일시정지 버튼 UI
    private func setPlayPauseButton() {
        let playImage = PlayerManager.shared.isPlaying ?
        UIImage(systemName: "pause.circle", withConfiguration: playConfig) :
        UIImage(systemName: "play.circle.fill", withConfiguration: playConfig)
        playButton.setImage(playImage, for: .normal)
    }

    /// 바인딩 메소드
    private func bindPlayerCallbacks() {
        PlayerManager.shared.onPlayStateChangedToPlaylistView = { [weak self] isPlaying in
            self?.setPlayPauseButton()
        }

        PlayerManager.shared.onTimeUpdateToPlaylistView = { [weak self] seconds in
            guard let duration = PlayerManager.shared.player?.currentItem?.duration.seconds, !duration.isNaN else { return }
            self?.playProgressView.progress = Float(seconds / duration)
        }

        PlayerManager.shared.onPlayListChanged = { [weak self] in
            Task { @MainActor in
                self?.playListTableView.reloadData()
            }
        }
        
        PlayerManager.shared.onSongChangedToPlaylistView = { [weak self] in
            Task { @MainActor in
                self?.playListTableView.reloadData()
                try? await Task.sleep(nanoseconds: 1_000_000)
                self?.scrollSelectPlaySong()
            }
        }
    }
    
    /// 재생곡 select 및 위치로 스크롤 이동
    private func scrollSelectPlaySong() {
        let index = PlayerManager.shared.currentIndex
        let rowCount = PlayerManager.shared.playlist.count
        
        guard index >= 0 && index < rowCount else { return }
        
        let indexPath = IndexPath(row: index, section: 0)
        playListTableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
    }
    
    /// Dismiss Image Button 이미지 세팅
    private func setDismissImageButton() {
        guard let song = PlayerManager.shared.currentSong,
              let thumanilData = song.thumbnailData,
              let image = UIImage(data: thumanilData) else { return }
        
        dismissImageButton.clipsToBounds = true
        dismissImageButton.layer.cornerRadius = dismissImageButton.bounds.height / 3
        
        let buttonSize = dismissImageButton.bounds.size
        let resizedImage = resizeImage(image: image, targetSize: buttonSize)
        dismissImageButton.setImage(resizedImage, for: .normal)
    }
    
    /// image resize
    /// - targetSize에 맞게 이미지 사이즈를 조정합니다
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // 비율을 유지하면서 크기 조정
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // 실제 이미지 리사이즈
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// 이전곡 버튼 터치
    @IBAction func backwardButton(_ sender: UIButton) {
        throttle.run {
            let canMoveToPrevious = PlayerManager.shared.moveBackward()

            if !canMoveToPrevious {
                self.showFirstSongAlert()
            }
        }
    }
    
    /// 재생 버튼 터치
    @IBAction func playButton(_ sender: UIButton) {
        PlayerManager.shared.togglePlayPause()
    }
    
    /// 다음곡 버튼 터치
    @IBAction func forwardButton(_ sender: UIButton) {
        throttle.run {
            Task { await PlayerManager.shared.moveForward() }
        }
    }
    
    /// edit 버튼 터치
    /// Edit Mode로 전환되어 삭제 맟 플레이리스트 순서 변경이 가능합니다
    @IBAction func editButton(_ sender: UIBarButtonItem) {
        playListTableView.setEditing(!playListTableView.isEditing, animated: true)
    }
    
    /// dismiss 버튼, 이미지 버튼 터치
    /// 플레이리스트 화면은 dismiss되고 재생화면으로 돌아갑니다
    /// - dismiss 버튼: 화면 좌측 상단
    /// - 이미지 버튼: 화면 우측 하단의 이미지로 현재 재생중인 곡의 thumailImage가 표시됩니다
    @IBAction func dismissButton(_ sender: Any) {
        dismiss(animated: true)
    }
    
    deinit {
        PlayerManager.shared.onTimeUpdateToPlaylistView = nil
        PlayerManager.shared.onPlayStateChangedToPlaylistView = nil
        PlayerManager.shared.onPlayListChanged = nil
        PlayerManager.shared.onSongChangedToPlaylistView = nil
    }
}

// MARK: - TabelView DataSource
extension PlayListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PlayerManager.shared.playlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SongTableViewCell.self), for: indexPath) as! SongTableViewCell
        let model = PlayerManager.shared.playlist[indexPath.row]
        let isPlaying = indexPath.row == PlayerManager.shared.currentIndex
        cell.selectionStyle = .none
        cell.setUI(model: model, isPlaying: isPlaying)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            PlayerManager.shared.removeSong(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    /// 행이동 가능하도록 설정
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        PlayerManager.shared.updateOrder(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
}

// MARK: - TableView Delegate
extension PlayListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlayerManager.shared.setCurrentIndex(indexPath.row)
        PlayerManager.shared.play()
    }
}

// MARK: - CollectionView Delegate
extension PlayListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Genre.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CategoryCell.self), for: indexPath) as! CategoryCell
        cell.configureUI(with: Genre.allCases[indexPath.item])

        return cell
    }
}

extension PlayListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CategoryCell {
            if let genre = cell.genre {
                PlayerManager.shared.addSongs(from: genre)
            }
        }
    }
}

extension PlayListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
}
