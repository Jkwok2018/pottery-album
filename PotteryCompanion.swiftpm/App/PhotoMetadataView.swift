import SwiftUI

struct PhotoMetadataView: View {
    let imageData: Data
    var onSave: (String) -> Void
    
    @State private var selectedTag = "Finished"
    let tags = ["Greenware", "Bone Dry", "Bisque", "Glazed", "Finished", "In Use"]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 5)
                }
                
                Picker("Stage", selection: $selectedTag) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag).tag(tag)
                    }
                }
                .pickerStyle(.wheel)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Tag Photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedTag)
                    }
                }
            }
        }
    }
}
