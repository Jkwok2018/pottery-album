import SwiftUI
import PhotosUI

struct PhotoThumbnail: View {
    let photo: PotteryPhoto
    var isJiggling: Bool = false
    var showTag: Bool = true
    var onDelete: () -> Void
    var size: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if showTag {
                Text(photo.stageTag)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            
            if isJiggling {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white, .red)
                        .font(.title3)
                }
                .padding(-6)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
    }
}
