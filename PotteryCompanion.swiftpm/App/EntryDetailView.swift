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
                    Text(entry.name)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                        Text(entry.date.formatted(date: .long, time: .omitted))
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
                        DetailRow(label: "Type", value: entry.shape)
                        Divider().padding(.horizontal)
                        DetailRow(label: "Status", value: entry.status)
                        Divider().padding(.horizontal)
                        DetailRow(label: "Clay", value: entry.clayType)
                        Divider().padding(.horizontal)
                        DetailRow(label: "Glaze", value: entry.glazes)
                        Divider().padding(.horizontal)
                        DetailRow(label: "Firing", value: entry.firingMethod)
                        if let weight = entry.clayWeight {
                            Divider().padding(.horizontal)
                            DetailRow(label: "Weight", value: "\(String(format: "%.1f", weight)) lbs")
                        }
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
                        
                        Text(entry.notes)
                            .font(.body)
                            .lineSpacing(4)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
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
            Button("Edit") {
                isEditing = true
            }
        }
        .sheet(isPresented: $isEditing) {
            EntryFormView(entry: entry)
        }
        .navigationDestination(item: $pendingPhoto) { draft in
            PhotoMetadataView(item: draft.item) { data, tag, note in
                let newPhoto = PotteryPhoto(imageData: data, stageTag: tag, note: note)
                entry.photos.append(newPhoto)
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

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value.isEmpty ? "-" : value)
                .fontWeight(.medium)
        }
        .padding()
    }
}
