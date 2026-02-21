import SwiftUI
import PhotosUI

struct PhotoDraft: Identifiable, Hashable {
    let id = UUID()
    var item: PhotosUI.PhotosPickerItem?
    var data: Data?
    
    var preloadedData: Data? {
        data
    }
    
    init(item: PhotosUI.PhotosPickerItem? = nil, data: Data? = nil) {
        self.item = item
        self.data = data
    }
}
