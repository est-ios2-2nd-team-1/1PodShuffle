import UIKit

/// CoreData에 저장되는 음악 엔티티입니다.
extension Song {
    /// 이미지 데이터를 반환합니다.
    var thumbnailData: Data? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsDirectory.appendingPathComponent(self.thumbnail ?? "")
        return try? Data(contentsOf: url)
    }

    /// View에서 사용할 음악 데이터 모델로 변환하는 메소드입니다.
    /// - Returns: View에 사용할 음악 데이터를 반환합니다.
    func toModel() -> SongModel {
        SongModel(from: self)
    }
}
