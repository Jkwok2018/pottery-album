import SwiftData
import Foundation
import SwiftUI

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
