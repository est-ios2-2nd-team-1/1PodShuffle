import UIKit

extension Song {
    var thumbnailData: Data? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsDirectory.appendingPathComponent(self.thumbnail ?? "")
        return try? Data(contentsOf: url)
    }

    func toModel() -> SongModel {
        SongModel(from: self)
    }
}
