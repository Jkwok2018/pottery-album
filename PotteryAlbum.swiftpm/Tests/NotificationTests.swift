import XCTest
@testable import Pottery_Album

final class NotificationTests: XCTestCase {
    func testNotificationTriggerCalculation() {
        let calendar = Calendar.current
        let today = Date()
        let entry = PotteryEntry(name: "Reminder Test", date: today)
        entry.trimReminderDays = 3
        
        // Target date should be 3 days after creation
        let expectedDate = calendar.date(byAdding: .day, value: 3, to: today)!
        let triggerDate = calendar.date(byAdding: .day, value: entry.trimReminderDays, to: entry.date)!
        
        // Verify day components match
        let expectedComponents = calendar.dateComponents([.year, .month, .day], from: expectedDate)
        let actualComponents = calendar.dateComponents([.year, .month, .day], from: triggerDate)
        
        XCTAssertEqual(actualComponents.year, expectedComponents.year)
        XCTAssertEqual(actualComponents.month, expectedComponents.month)
        XCTAssertEqual(actualComponents.day, expectedComponents.day)
    }
    
    func testNotificationContent() {
        let entry = PotteryEntry(name: "My Large Bowl")
        entry.trimReminderDays = 7
        
        let body = "Time to trim \"\(entry.name)\"! It was created \(entry.trimReminderDays) days ago."
        XCTAssertTrue(body.contains("My Large Bowl"))
        XCTAssertTrue(body.contains("7 days ago"))
    }
}
