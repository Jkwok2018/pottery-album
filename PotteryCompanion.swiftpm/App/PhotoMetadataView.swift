import SwiftUI
import PhotosUI

struct PhotoMetadataView: View {
    let item: PhotosUI.PhotosPickerItem
    var onSave: (Data, String, String) -> Void
    
    @State private var imageData: Data?
    @State private var selectedTag = "Finished"
    @State private var note = ""
    let tags = ["Greenware", "Trimmed", "Bisque", "Glazed", "Finished"]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .listRowInsets(EdgeInsets())
                        .frame(maxHeight: 300)
                } else {
                    HStack {
                        Spacer()
                        ProgressView("Loading Photo...")
                        Spacer()
                    }
                    .frame(height: 200)
                    .listRowBackground(Color.clear)
                }
            }
            
            Section {
                Picker("Stage", selection: $selectedTag) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag).tag(tag)
                    }
                }
                
                TextField("Add a note...", text: $note)
                    .disabled(imageData == nil)
            } header: {
                Text("Details").font(.footnote).bold().foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Tag Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    if let data = imageData {
                        onSave(data, selectedTag, note)
                        dismiss()
                    }
                }
                .disabled(imageData == nil)
            }
        }
        .task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                imageData = data
            }
        }
    }
}
