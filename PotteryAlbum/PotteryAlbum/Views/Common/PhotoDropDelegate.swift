import SwiftData
import Foundation
import SwiftUI

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
