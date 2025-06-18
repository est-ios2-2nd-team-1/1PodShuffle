import CoreData
import Foundation

extension PreferenceData {
    convenience init(context: NSManagedObjectContext, genre: Genre, score: Double, isImmutable: Bool = false) {
        self.init(context: context)
        self.id = UUID()
        self.genre = genre.rawValue
        self.score = score
        self.insertDate = Date()
        self.isImmutable = isImmutable
    }
}
