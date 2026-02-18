import SwiftUI
import PhotosUI

struct PhotoMetadataView: View {
    let item: PhotosUI.PhotosPickerItem
    var onSave: (Data, String, String) -> Void
    
    @State private var imageData: Data?
    @State private var selectedTag = PotteryStage.finished
    @State private var note = ""
    let stages = PotteryStage.allCases
    
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
                    ForEach(stages, id: \.self) { stage in
                        Text(stage.rawValue).tag(stage)
                    }
                }
                
                TextField("Add a note...", text: $note)
                    .disabled(imageData == nil)
            } header: {
                Text("Details").font(.footnote).bold().foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Tag Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    if let data = imageData {
                        onSave(data, selectedTag.rawValue, note)
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
