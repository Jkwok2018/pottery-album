import SwiftUI

struct PhotoMetadataView: View {
    let imageData: Data
    var onSave: (String, String) -> Void
    
    @State private var selectedTag = "Finished"
    @State private var note = ""
    let tags = ["Greenware", "Bone Dry", "Bisque", "Glazed", "Finished", "In Use"]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .listRowInsets(EdgeInsets())
                            .frame(maxHeight: 300)
                    }
                }
                
                Section("Details") {
                    Picker("Stage", selection: $selectedTag) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag).tag(tag)
                        }
                    }
                    
                    TextField("Add a note...", text: $note)
                }
            }
            .navigationTitle("Tag Photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedTag, note)
                    }
                }
            }
        }
    }
}
