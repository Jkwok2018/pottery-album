import SwiftData
import Foundation
import SwiftUI

enum PotteryStage: String, CaseIterable, Codable, Comparable {
    case greenware = "Greenware"
    case trimmed = "Trimmed"
    case bisque = "Bisque"
    case glazed = "Glazed"
    case finished = "Finished"
    
    static func < (lhs: PotteryStage, rhs: PotteryStage) -> Bool {
        let allCases = self.allCases
        return allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

@Model
final class PotteryEntry {
    var id: UUID
    var name: String
    var date: Date
    var dateTrimmed: Date?
    var dateGlazed: Date?
    
    // Simplified Trim Reminder
    var enableTrimReminder: Bool = false
    var trimReminderDays: Int = 3
    
    var clayType: String // Keeping non-optional string for simplicity, empty string = none
    var clayWeight: Double? // in pounds
    var glazes: [String]
    var notes: String
    
    // Dimensions
    // Shape
    var shape: String
    var status: String // "In Progress", "Completed", "Stopped"
    
    @Relationship(deleteRule: .cascade) var photos: [PotteryPhoto] = []
    
    init(name: String = "", date: Date = .now) {
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
    
    func updateStatusFromPhotos() {
        let stages = photos.compactMap { PotteryStage(rawValue: $0.stageTag) }
        if let latestStage = stages.max() {
            self.status = latestStage.rawValue
        }
    }
    
    var sortedPhotos: [PotteryPhoto] {
        photos.sorted { $0.orderIndex < $1.orderIndex }
    }
}

@Model
final class PotteryPhoto {
    var id: UUID
    var imageData: Data
    var stageTag: String // e.g., "Greenware"
    var note: String
    var orderIndex: Int
    var dateAdded: Date
    
    init(imageData: Data, stageTag: String = PotteryStage.greenware.rawValue, note: String = "", orderIndex: Int = 0) {
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
