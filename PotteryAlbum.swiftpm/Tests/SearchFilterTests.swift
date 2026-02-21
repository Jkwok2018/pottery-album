import XCTest
@testable import Pottery_Album

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
    
    func testStatusFilteringGrouping() {
        let entries = [
            PotteryEntry(name: "P1"), // Greenware (In Progress)
            PotteryEntry(name: "P2"), // Greenware (In Progress)
            PotteryEntry(name: "P3"), // Will set to Finished
            PotteryEntry(name: "P4")  // Will set to Stopped
        ]
        entries[2].status = PotteryStage.finished.rawValue
        entries[3].status = PotteryStage.stopped.rawValue
        
        // Test "In Progress" filter (should include P1, P2)
        let inProgress = entries.filter { 
            $0.status != PotteryStage.finished.rawValue && 
            $0.status != PotteryStage.stopped.rawValue 
        }
        XCTAssertEqual(inProgress.count, 2)
        XCTAssertTrue(inProgress.contains { $0.name == "P1" })
        XCTAssertTrue(inProgress.contains { $0.name == "P2" })
        
        // Test "Finished" filter
        let finished = entries.filter { $0.status == PotteryStage.finished.rawValue }
        XCTAssertEqual(finished.count, 1)
        XCTAssertEqual(finished.first?.name, "P3")
        
        // Test "Stopped" filter
        let stopped = entries.filter { $0.status == PotteryStage.stopped.rawValue }
        XCTAssertEqual(stopped.count, 1)
        XCTAssertEqual(stopped.first?.name, "P4")
    }
}
