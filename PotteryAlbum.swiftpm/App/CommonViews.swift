import SwiftUI
import PhotosUI

// MARK: - Reusable Section Components

struct SuggestionPickerRow: View {
    let label: String
    @Binding var value: String
    let suggestions: [String]
    @Binding var enteringOther: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { enteringOther ? "Other" : (suggestions.contains(value) ? value : "Other") },
                    set: { newValue in
                        if newValue == "Other" {
                            enteringOther = true
                        } else {
                            enteringOther = false
                            value = newValue
                        }
                    }
                )) {
                    ForEach(suggestions, id: \.self) { s in
                        Text(s).tag(s)
                    }
                    Text("New...").tag("Other")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            
            if enteringOther || !suggestions.contains(value) || value.isEmpty {
                TextField("Enter new \(label.lowercased())", text: $value)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct OptionalDatePickerRow: View {
    let label: String
    @Binding var selection: Date?
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            if let date = selection {
                DatePicker("", selection: Binding(
                    get: { date },
                    set: { selection = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                
                Button {
                    selection = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            } else {
                Button("Add Date") {
                    selection = .now
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Photo Components

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

// MARK: - Glaze Components

struct GlazeTag: View {
    let name: String
    var onRemove: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.subheadline)
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.tint.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Navigation Models

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
