import Foundation
import CoreData

struct SongEntity {
    let title: String
    let album: String
    let artist: String
    let genre: String
    let id: Int
    let streamUrl: String
    let thumbnail: Data?
}

final class DataManager {
    static let shared = DataManager()

    let mainContext: NSManagedObjectContext
    let persistentContainer: NSPersistentContainer
    let fetchedResults: NSFetchedResultsController<Song>
    
    /// 코어 데이터 초기화 및 데이터를 가져옵니다.
    private init() {
        let container = NSPersistentContainer(name: "RandomMusic")

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        persistentContainer = container
        mainContext = container.viewContext

        let request = Song.fetchRequest()
        let sortedByDate = NSSortDescriptor(keyPath: \Song.insertDate, ascending: false)
        request.sortDescriptors = [sortedByDate]

        fetchedResults = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        do {
            try fetchedResults.performFetch()
        } catch {
            print(error)
        }
    }
    
    /// 음악 데이터를 영구적으로 저장합니다.
    /// - Parameter song: 저장할 음악 데이터를 받습니다.
    func insertSongData(from song: SongEntity) {
        let newSong = Song(context: mainContext)
        newSong.title = song.title
        newSong.album = song.album
        newSong.artist = song.artist
        newSong.genre = song.genre
        newSong.id = Int64(song.id)
        newSong.streamUrl = song.streamUrl
        newSong.insertDate = .now

        let thumbnailFileName = String(newSong.id) + ".png"
        newSong.thumbnail = thumbnailFileName

        insertImageFile(name: newSong.thumbnail, data: song.thumbnail)
        saveContext()
    }

    // TODO: 오버로딩이 필요할 수도 있음. (다른 파라미터를 받는 Delete 메소드)
    /// 음악 데이터를 영구적으로 삭제합니다.
    /// - Parameter indexPath: 삭제할 음악 데이터의 IndexPath를 받습니다.
    func deleteSongData(at indexPath: IndexPath) {
        let deletedSong = fetchedResults.object(at: indexPath)

        deleteImageFile(name: deletedSong.thumbnail)
        mainContext.delete(deletedSong)
        saveContext()
    }

    // TODO: 알고리즘에 따라서 변경되는 수치는 바뀔 수 있음.
    /// 장르별 추천 수치를 변경합니다.
    /// - Parameters:
    ///   - genre: 음악의 장르를 받습니다. (String)
    ///   - upper: 추천하면 양수, 비추천하면 음수를 받습니다.
    func recommendGenre(to genre: String, upper: Int) {
        var genreCounts = UserDefaults.standard.dictionary(forKey: "Genre") as? [String: Int] ?? [:]

        if genreCounts[genre, default: 0] + upper < 0 {
            genreCounts[genre, default: 0] = 1
        } else {
            genreCounts[genre, default: 0] += upper
        }

        UserDefaults.standard.setValue(genreCounts, forKey: "Genre")
    }
    
    /// 장르별 추천 수치를 모두 반환합니다.
    /// - Returns: 장르별 추천 수치를 배열로 반환합니다.
    func fetchAllGenre() -> [(genre: String, count: Int)] {
        if let genreCounts = UserDefaults.standard.dictionary(forKey: "Genre") as? [String: Int] {
			return Array(genreCounts).sorted { $0.value > $1.value }.map { (genre: $0.key, count: $0.value) }
        }

        return []
    }

    /// Context에서 변경된 데이터를 영구적으로 저장합니다.
    func saveContext() {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

private extension DataManager {
    /// 디렉토리에 이미지 데이터를 저장합니다.
    /// - Parameters:
    ///   - name: 이미지 파일의 이름을 받습니다.
    ///   - data: 저장될 바이너리 데이터를 받습니다.
    func insertImageFile(name: String?, data: Data?) {
        if let fileName = name, let data = data {
            if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
                do {
                    try data.write(to: url)
                } catch {
                    print(error)
                }
            }
        }
    }

    /// 디렉토리에 존재하는 이미지를 삭제합니다.
    /// - Parameter name: 디렉토리에 저장된 파일 이름을 받습니다.
    func deleteImageFile(name: String?) {
        if let fileName = name {
            if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
                if FileManager.default.fileExists(atPath: fileName) {
                    do {
                        try FileManager.default.removeItem(at: url)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}
