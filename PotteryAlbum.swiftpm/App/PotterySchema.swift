import SwiftData
import Foundation
import SwiftUI

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

@Model
public final class PotteryPhoto {
    public var id: UUID
    public var imageData: Data
    public var stageTag: String // e.g., "Greenware"
    public var note: String
    public var orderIndex: Int
    public var dateAdded: Date
    
    public init(imageData: Data, stageTag: String = PotteryStage.greenware.rawValue, note: String = "", orderIndex: Int = 0) {
        self.id = UUID()
        self.imageData = imageData
        self.stageTag = stageTag
        self.note = note
        self.orderIndex = orderIndex
        self.dateAdded = .now
    }
}

struct PhotoDropDelegate: DropDelegate {
    let item: PotteryPhoto
    let photos: [PotteryPhoto]
    @Binding var draggedItem: PotteryPhoto?
    var onMove: (IndexSet, Int) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem != item,
              let from = photos.firstIndex(of: draggedItem),
              let to = photos.firstIndex(of: item) else { return }
              
        if photos[to] != draggedItem {
            onMove(IndexSet(integer: from), to > from ? to + 1 : to)
        }
    }
}
