import SwiftData
import Foundation
import SwiftUI

@Model
public final class PotteryEntry {
    public var id: UUID
    public var name: String
    public var date: Date
    public var dateTrimmed: Date?
    public var dateGlazed: Date?
    
    // Simplified Trim Reminder
    public var enableTrimReminder: Bool = false
    public var trimReminderDays: Int = 3
    
    public var clayType: String // Keeping non-optional string for simplicity, empty string = none
    public var clayWeight: Double? // in pounds
    public var glazes: [String]
    public var notes: String
    
    // Dimensions
    // Shape
    public var shape: String
    public var status: String // E.g., PotteryStage.greenware.rawValue (In Progress), Finished, Stopped
    
    @Relationship(deleteRule: .cascade) public var photos: [PotteryPhoto] = []
    
    public init(name: String = "", date: Date = .now) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.clayType = ""
        // clayWeight is optional, defaults to nil
        self.glazes = []
        self.notes = ""
        self.shape = ""
        self.status = PotteryStage.greenware.rawValue
        self.enableTrimReminder = false
        self.trimReminderDays = 3
    }
    
    public func updateStatusFromPhotos() {
        let stages = photos.compactMap { PotteryStage(rawValue: $0.stageTag) }
        if let latestStage = stages.max() {
            self.status = latestStage.rawValue
        }
    }
    
    public var sortedPhotos: [PotteryPhoto] {
        photos.sorted { $0.orderIndex < $1.orderIndex }
    }
}

public enum PotteryStage: String, CaseIterable, Codable, Comparable {
    case greenware = "Greenware"
    case trimmed = "Trimmed"
    case bisque = "Bisque"
    case glazed = "Glazed"
    case finished = "Finished"
    case stopped = "Stopped"
    
    public static func < (lhs: PotteryStage, rhs: PotteryStage) -> Bool {
        let allCases = self.allCases
        return allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}
