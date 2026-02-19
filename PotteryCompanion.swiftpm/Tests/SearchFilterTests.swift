import XCTest
@testable import AppModule

final class SearchFilterTests: XCTestCase {
    func testSearchNameMatching() {
        let entries = [
            PotteryEntry(name: "Tall Vase"),
            PotteryEntry(name: "Small Bowl"),
            PotteryEntry(name: "Red Plate")
        ]
        
        let searchText = "vase"
        let filtered = entries.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Tall Vase")
    }
    
    func testSearchTagMatching() {
        let entry1 = PotteryEntry(name: "Bowl 1")
        entry1.photos.append(PotteryPhoto(imageData: Data(), stageTag: "Glazed"))
        
        let entry2 = PotteryEntry(name: "Bowl 2")
        entry2.photos.append(PotteryPhoto(imageData: Data(), stageTag: "Bisque"))
        
        let entries = [entry1, entry2]
        
        let searchText = "glazed"
        let filtered = entries.filter { entry in
            entry.photos.contains { $0.stageTag.localizedCaseInsensitiveContains(searchText) }
        }
        
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Bowl 1")
    }
}
