import Foundation
import CoreData

struct SongDTO {
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
    func insertSongData(from song: SongDTO) {
        let newSong = Song(context: mainContext)
        newSong.title = song.title
        newSong.album = song.album
        newSong.artist = song.artist
        newSong.genre = song.genre
        newSong.id = Int64(song.id)
        newSong.streamUrl = song.streamUrl
        newSong.insertDate = .now

        // 이미지 데이터는 용량이 크기 때문에 디렉토리에 따로 저장해두고 해당 디렉토리를 가르키는 URL만 따로 CoreData에 저장합니다.
        let thumbnailFileName = String(newSong.id) + ".png"
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(thumbnailFileName) {
            do {
                try song.thumbnail?.write(to: url)
                newSong.thumbnail = thumbnailFileName
                saveContext()
            } catch {
                print(error)
            }
        }
    }

    /// Context에 임시 저장된 데이터를 영구적으로 저장합니다.
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
