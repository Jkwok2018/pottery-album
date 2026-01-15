import SwiftData
import Foundation
import SwiftUI

@Model
final class PotteryEntry {
    var id: UUID
    var name: String
    var date: Date
    var clayType: String // Keeping non-optional string for simplicity, empty string = none
    var clayWeight: Double? // in pounds
    var firingMethod: String
    var glazes: String
    var notes: String
    
    // Dimensions
    // Shape
    var shape: String
    
    @Relationship(deleteRule: .cascade) var photos: [PotteryPhoto] = []
    
    init(name: String = "", date: Date = .now) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.clayType = ""
        // clayWeight is optional, defaults to nil
        self.firingMethod = ""
        self.glazes = ""
        self.notes = ""
        self.shape = ""
    }
}

@Model
final class PotteryPhoto {
    var id: UUID
    var imageData: Data
    var stageTag: String // e.g., "Greenware", "Bone Dry", "Bisque", "Glazed", "Finished"
    var dateAdded: Date
    
    init(imageData: Data, stageTag: String = "Finished") {
        self.id = UUID()
        self.imageData = imageData
        self.stageTag = stageTag
        self.dateAdded = .now
    }
}
