import XCTest
@testable import PotteryAlbum

final class PhotoLogicTests: XCTestCase {
    func testUpdateStatusFromPhotos() {
        let entry = PotteryEntry(name: "Status Test")
        
        // No photos -> default status (Greenware)
        XCTAssertEqual(entry.status, PotteryStage.greenware.rawValue)
        
        // Add a Trimmed photo
        let photo1 = PotteryPhoto(imageData: Data(), stageTag: PotteryStage.trimmed.rawValue)
        entry.photos.append(photo1)
        entry.updateStatusFromPhotos()
        XCTAssertEqual(entry.status, PotteryStage.trimmed.rawValue)
        
        // Add a Finished photo
        let photo2 = PotteryPhoto(imageData: Data(), stageTag: PotteryStage.finished.rawValue)
        entry.photos.append(photo2)
        entry.updateStatusFromPhotos()
        XCTAssertEqual(entry.status, PotteryStage.finished.rawValue)
        
        // Add a Bisque photo (should NOT downgrade status, Finished is higher than Bisque)
        let photo3 = PotteryPhoto(imageData: Data(), stageTag: PotteryStage.bisque.rawValue)
        entry.photos.append(photo3)
        entry.updateStatusFromPhotos()
        XCTAssertEqual(entry.status, PotteryStage.finished.rawValue)
        
        // Add a Stopped photo (Stopped is higher than Finished in our enum order now)
        let photo4 = PotteryPhoto(imageData: Data(), stageTag: PotteryStage.stopped.rawValue)
        entry.photos.append(photo4)
        entry.updateStatusFromPhotos()
        XCTAssertEqual(entry.status, PotteryStage.stopped.rawValue)
    }
    
    func testPhotoOrderIndexSorting() {
        let entry = PotteryEntry(name: "Ordering Test")
        let photo0 = PotteryPhoto(imageData: Data(), orderIndex: 0)
        let photo1 = PotteryPhoto(imageData: Data(), orderIndex: 1)
        let photo2 = PotteryPhoto(imageData: Data(), orderIndex: 2)
        
        // Add them out of order
        entry.photos = [photo2, photo0, photo1]
        
        let sorted = entry.sortedPhotos
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].orderIndex, 0)
        XCTAssertEqual(sorted[1].orderIndex, 1)
        XCTAssertEqual(sorted[2].orderIndex, 2)
        XCTAssertEqual(sorted[0].id, photo0.id)
    }
    
    func testPhotoDraftInitialization() {
        let data = "test-image-data".data(using: .utf8)!
        let draft = PhotoDraft(data: data)
        XCTAssertEqual(draft.preloadedData, data)
        XCTAssertNil(draft.item)
    }
}
