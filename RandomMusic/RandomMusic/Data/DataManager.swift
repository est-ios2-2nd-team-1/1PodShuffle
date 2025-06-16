import Foundation
import CoreData

final class DataManager {
    static let shared = DataManager()

    let mainContext: NSManagedObjectContext
    let persistentContainer: NSPersistentContainer

    /// 초기화 및 Context를 생성합니다.
    private init() {
        let container = NSPersistentContainer(name: "RandomMusic")

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        persistentContainer = container
        mainContext = container.viewContext
    }
    
    /// 음악 데이터를 모두 가져옵니다.
    /// (PlayerManager로부터 호출받습니다.)
    /// - Returns: 음악 데이터를 날짜순으로 반환합니다.
    func fetchSongData() -> [SongModel] {
        let request = Song.fetchRequest()
        let sortedByOrderDesc = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortedByOrderDesc]

        do {
            let songList = try mainContext.fetch(request)
            return songList.map { $0.toModel() }
        } catch {
            print(error)
        }

        return []
    }

    /// 음악 데이터를 영구적으로 저장합니다.
    /// (PlayerManager로부터 호출받습니다.)
    /// - Parameter song: 저장할 음악 데이터를 받습니다.
    func insertSongData(from song: SongModel) {
        let newSong = Song(context: mainContext)
        newSong.title = song.title
        newSong.album = song.album
        newSong.artist = song.artist
        newSong.genre = song.genre.rawValue
        newSong.id = Int64(song.id)
        newSong.streamUrl = song.streamUrl
        newSong.insertDate = .now

        let thumbnailFileName = String(newSong.id) + ".jpg"
        newSong.thumbnail = thumbnailFileName
        
        let maxOrderValue = fetchMaxOrderValue()
        newSong.order = maxOrderValue + 1

        insertImageFile(fileName: thumbnailFileName, data: song.thumbnailData)
        saveContext()
    }

    /// 음악 데이터를 영구적으로 삭제합니다.
    /// (PlaylistView로부터 호출받습니다.)
    /// - Parameter indexPath: 삭제할 음악 데이터의 IndexPath를 받습니다.
    func deleteSongData(to song: SongModel) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        fetchRequest.predicate = NSPredicate(format: "id == %ld", song.id)
        fetchRequest.fetchLimit = 1

        do {
            if let results = try mainContext.fetch(fetchRequest) as? [NSManagedObject], let deletedSong = results.first {
                deleteImageFile(fileName: String(song.id) + ".jpg")
                mainContext.delete(deletedSong)
                saveContext()
            }
        } catch {
            print(error)
        }
    }
    
    /// 음악 데이터 순서를 영구적으로 변경합니다.
    /// (PlayManager로부터 호출받습니다.)
    /// - Parameter model: 순서를 변경할 음악 데이터를 받습니다
    func updateOrder(for models: [SongModel]) {
        let request = Song.fetchRequest()
        do {
            let songs = try mainContext.fetch(request)
            for (index, model) in models.enumerated() {
                if let song = songs.first(where: { $0.id == Int64(model.id) }) {
                    song.setValue(Int64(index), forKey: "order")
                }
            }
            saveContext()
        } catch {
            print("Order update failed: \(error)")
        }
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
    func insertImageFile(fileName: String, data: Data?) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pathUrl = documentDirectory.appending(path: fileName)

        do {
            try data?.write(to: pathUrl)
        } catch {
            print(error.localizedDescription)
        }
    }

    /// 디렉토리에 존재하는 이미지를 삭제합니다.
    /// - Parameter fileName: 디렉토리에 저장된 파일 이름을 받습니다.
    func deleteImageFile(fileName: String?) {
        if let fileName {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let pathUrl = documentDirectory.appending(path: fileName)

            do {
                try FileManager.default.removeItem(at: pathUrl)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func fetchMaxOrderValue() -> Int64 {
        let request = NSFetchRequest<NSDictionary>(entityName: "Song")
        request.resultType = .dictionaryResultType
        let expressionDesc = NSExpressionDescription()
        expressionDesc.name = "maxOrder"
        expressionDesc.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "order")])
        expressionDesc.expressionResultType = .integer64AttributeType
        request.propertiesToFetch = [expressionDesc]
        
        do {
            if let result = try mainContext.fetch(request).first,
               let maxValue = result["maxOrder"] as? Int64 {
                return maxValue
            }
        } catch {
            print("fetchMaxOrderValue 에러: \(error)")
        }
        return 0
    }
}
