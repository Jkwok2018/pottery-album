import SwiftUI
import SwiftData
import PhotosUI

struct EntryDetailView: View {
    @Bindable var entry: PotteryEntry
    @State private var isEditing = false
    @State private var selectedPhoto: PotteryPhoto?
    @State private var selectedItem: PhotosUI.PhotosPickerItem?
    @State private var pendingPhoto: EntryFormView.PhotoDraft?
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Top Header (Name & Date)
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Name", text: $entry.name)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                        DatePicker("", selection: $entry.date, displayedComponents: .date)
                            .labelsHidden()
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Photo Gallery Container
                VStack(alignment: .leading, spacing: 16) {
                    // Main Photo Display
                    ZStack {
                        Color(uiColor: .systemBackground)
                        
                        if let photo = selectedPhoto ?? entry.photos.first,
                           let uiImage = UIImage(data: photo.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.tertiary)
                                Text("No Photos Yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Photo Notes/Caption
                    if let photo = selectedPhoto ?? entry.photos.first {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "quote.bubble")
                                .foregroundStyle(.secondary)
                            Text(photo.note.isEmpty ? photo.stageTag : "\(photo.stageTag): \(photo.note)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    // Thumbnail Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Existing Photos
                            ForEach(entry.photos) { photo in
                                Button {
                                    selectedPhoto = photo
                                } label: {
                                    if let uiImage = UIImage(data: photo.imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 55, height: 55)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedPhoto == photo || (selectedPhoto == nil && photo == entry.photos.first) ? Color.primary : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            
                            // Add Photo Button
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(uiColor: .tertiarySystemBackground))
                                        .frame(width: 55, height: 55)
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                }
                .padding(16)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
                
                // Details Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("DETAILS")
                        .font(.footnote).bold()
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                    
                    VStack(spacing: 0) {
                        EditableDetailRow(label: "Type", value: $entry.shape)
                        Divider().padding(.horizontal)
                        
                        HStack {
                            Text("Status")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("", selection: $entry.status) {
                                ForEach(PotteryStage.allCases, id: \.self) { stage in
                                    Text(stage.rawValue).tag(stage.rawValue)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                        .padding()
                        
                        Divider().padding(.horizontal)
                        
                        HStack {
                            Text("Clay")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Clay Type", text: $entry.clayType)
                                .multilineTextAlignment(.trailing)
                                .fontWeight(.medium)
                        }
                        .padding()
                        
                        Divider().padding(.horizontal)
                        
                        OptionalDatePickerRow(label: "Trimmed", selection: $entry.dateTrimmed)
                            .padding()
                        
                        Divider().padding(.horizontal)
                        
                        OptionalDatePickerRow(label: "Glazed", selection: $entry.dateGlazed)
                            .padding()
                        
                        Divider().padding(.horizontal)
                        
                        HStack {
                            Text("Glaze")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Glaze Used", text: $entry.glazes)
                                .multilineTextAlignment(.trailing)
                                .fontWeight(.medium)
                        }
                        .padding()
                        
                        Divider().padding(.horizontal)
                        
                        HStack {
                            Text("Weight")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("0.0", value: $entry.clayWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .fontWeight(.medium)
                        }
                        .padding()
                    }
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                
                // Notes Section
                if !entry.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(.footnote).bold()
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                        
                        TextEditor(text: $entry.notes)
                            .font(.body)
                            .padding(8)
                            .frame(minHeight: 100)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // No Edit button needed as fields are directly editable
            }
        }
        .sheet(isPresented: $isEditing) {
            EntryFormView(entry: entry)
        }
        .navigationDestination(item: $pendingPhoto) { draft in
            PhotoMetadataView(item: draft.item) { data, tag, note in
                let newPhoto = PotteryPhoto(imageData: data, stageTag: tag, note: note)
                entry.photos.append(newPhoto)
                entry.updateStatusFromPhotos()
                selectedPhoto = newPhoto
                selectedItem = nil
                pendingPhoto = nil
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            if let newValue = newValue {
                pendingPhoto = EntryFormView.PhotoDraft(item: newValue)
            }
        }
    }
}

struct EditableDetailRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("None", text: $value)
                .multilineTextAlignment(.trailing)
                .fontWeight(.medium)
        }
        .padding()
    }
}
