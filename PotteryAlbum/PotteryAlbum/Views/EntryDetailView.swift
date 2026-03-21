import SwiftUI
import SwiftData
import PhotosUI

struct EntryDetailView: View {
    @Bindable var entry: PotteryEntry
    @Binding var path: NavigationPath
    @State private var isEditing = false
    @State private var selectedPhoto: PotteryPhoto?
    @State private var selectedItem: PhotosUI.PhotosPickerItem?
    
    @State private var showingCamera = false
    @State private var showingNewGlazeField = false
    @State private var newGlazeName = ""
    @State private var showingDeleteConfirmation = false
    @State private var draggedPhoto: PotteryPhoto?
    @State private var showingPhotosPicker = false
    @State private var photoToDelete: PotteryPhoto?
    @State private var showingPhotoDeleteConfirmation = false
    @State private var isJiggling = false
    @State private var pendingDraft: PhotoDraft?
    
    @Query private var allEntries: [PotteryEntry]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var enteringNewShape = false
    @State private var enteringNewClayType = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                generalInfoSection
                specsSection
                notesSection
                photoGallerySection
                remindersSection
            }
            .padding(.bottom, 40)
        }
        .background(Color.appBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            if isJiggling {
                withAnimation {
                    isJiggling = false
                }
            }
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EntryFormView(entry: entry)
        }
        .navigationDestination(for: PhotoDraft.self) { draft in
            PhotoMetadataView(item: draft.item, preloadedData: draft.preloadedData) { data, tag, note in
                let newPhoto = PotteryPhoto(imageData: data, stageTag: tag, note: note, orderIndex: entry.photos.count)
                entry.photos.append(newPhoto)
                entry.updateStatusFromPhotos()
                selectedPhoto = newPhoto
                selectedItem = nil
                path.removeLast()
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            if let newValue = newValue {
                pendingDraft = PhotoDraft(item: newValue)
                selectedItem = nil
            }
        }
        .onChange(of: pendingDraft) { oldValue, newValue in
            if let draft = newValue {
                // Delay slightly to allow any pickers/sheets to fully dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    path.append(draft)
                    pendingDraft = nil
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker { image in
                if let data = image.jpegData(compressionQuality: 0.8) {
                    pendingDraft = PhotoDraft(data: data)
                }
            }
        }
        .alert("Delete Entry?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(entry.name)'? This action cannot be undone.")
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedItem, matching: .images)
        .alert("Delete Photo?", isPresented: $showingPhotoDeleteConfirmation, presenting: photoToDelete) { photo in
            Button("Delete", role: .destructive) {
                if let index = entry.photos.firstIndex(of: photo) {
                    if selectedPhoto == photo {
                        selectedPhoto = nil
                    }
                    entry.photos.remove(at: index)
                    modelContext.delete(photo)
                    entry.updateStatusFromPhotos()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }
    
    // MARK: - Section Views
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Name", text: $entry.name)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private var photoGallerySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📸 PHOTOS")
                .font(.footnote).bold()
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            
            VStack(alignment: .leading, spacing: 16) {
                // Main Photo Display
                ZStack {
                    Color(uiColor: .systemBackground)
                    
                    if let photo = selectedPhoto ?? entry.sortedPhotos.first,
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
                if let photo = selectedPhoto ?? entry.sortedPhotos.first {
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
                        ForEach(entry.sortedPhotos) { photo in
                            GalleryThumbnail(
                                photo: photo,
                                isSelected: photo == (selectedPhoto ?? entry.sortedPhotos.first),
                                isJiggling: isJiggling,
                                onAction: {
                                    if isJiggling {
                                        photoToDelete = photo
                                        showingPhotoDeleteConfirmation = true
                                    } else {
                                        selectedPhoto = photo
                                    }
                                }
                            )
                            .onDrag {
                                self.draggedPhoto = photo
                                return NSItemProvider(object: photo.id.uuidString as NSString)
                            }
                            .onDrop(of: [.text], delegate: PhotoDropDelegate(item: photo, photos: entry.sortedPhotos, draggedItem: $draggedPhoto, onMove: movePhotos))
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.5)
                                    .onEnded { _ in
                                        withAnimation {
                                            isJiggling = true
                                        }
                                    }
                            )
                        }
                        
                        Menu {
                            Button {
                                showingCamera = true
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                            }
                            Button {
                                showingPhotosPicker = true
                            } label: {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
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
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var generalInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📝 GENERAL INFO")
                .font(.footnote).bold()
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                statusPickerRow
                Divider().padding(.horizontal)
                HStack {
                    Text("Created")
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: $entry.date, displayedComponents: .date)
                        .labelsHidden()
                }
                .padding()
                Divider().padding(.horizontal)
                OptionalDatePickerRow(label: "Trimmed", selection: $entry.dateTrimmed)
                    .padding()
                Divider().padding(.horizontal)
                OptionalDatePickerRow(label: "Glazed", selection: $entry.dateGlazed)
                    .padding()
            }
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var specsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🏗️ SPECS")
                .font(.footnote).bold()
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                shapePickerRow
                clayPickerRow
                weightPickerRow
                Divider().padding(.horizontal)
                glazeManagementDetailView
            }
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var shapePickerRow: some View {
        SuggestionPickerRow(
            label: "Shape",
            value: $entry.shape,
            suggestions: uniqueShapes,
            enteringOther: $enteringNewShape
        )
        .padding()
    }
    
    @ViewBuilder
    private var statusPickerRow: some View {
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
    }
    
    @ViewBuilder
    private var clayPickerRow: some View {
        Divider().padding(.horizontal)
        SuggestionPickerRow(
            label: "Clay",
            value: $entry.clayType,
            suggestions: uniqueClayTypes,
            enteringOther: $enteringNewClayType
        )
        .padding()
    }
    
    @ViewBuilder
    private var weightPickerRow: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal)
            HStack {
                Text("Weight (lbs)")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("0.0", value: $entry.clayWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.medium)
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var glazeManagementDetailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Glazes")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { "Add..." },
                    set: { newValue in
                        if newValue == "New..." {
                            showingNewGlazeField = true
                        } else if newValue != "Add..." && !entry.glazes.contains(newValue) {
                            entry.glazes.append(newValue)
                        }
                    }
                )) {
                    Text("Add...").tag("Add...")
                    ForEach(uniqueGlazes, id: \.self) { g in
                        if !entry.glazes.contains(g) {
                            Text(g).tag(g)
                        }
                    }
                    Text("New...").tag("New...")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            
            if showingNewGlazeField {
                HStack {
                    TextField("Glaze name", text: $newGlazeName, onCommit: {
                        if !newGlazeName.isEmpty && !entry.glazes.contains(newGlazeName) {
                            entry.glazes.append(newGlazeName)
                            newGlazeName = ""
                            showingNewGlazeField = false
                        }
                    })
                    .textFieldStyle(.roundedBorder)
                    
                    Button {
                        showingNewGlazeField = false
                        newGlazeName = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }
            
            if !entry.glazes.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(entry.glazes, id: \.self) { glaze in
                        GlazeTag(name: glaze) {
                            entry.glazes.removeAll { $0 == glaze }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔔 REMINDER TO TRIM")
                .font(.footnote).bold()
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                Toggle("Enable Reminder", isOn: $entry.enableTrimReminder)
                    .padding()
                
                if entry.enableTrimReminder {
                    Divider().padding(.horizontal)
                    
                    HStack {
                        Text("Days after created")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Days", value: $entry.trimReminderDays, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .fontWeight(.medium)
                    }
                    .padding()
                }
            }
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📓 NOTES")
                .font(.footnote).bold()
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            
            TextEditor(text: $entry.notes)
                .font(.body)
                .padding(8)
                .frame(minHeight: 120)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
    }
    
    // Suggestion Helpers
    private var uniqueClayTypes: [String] {
        Array(Set(allEntries.map { $0.clayType })).filter { !$0.isEmpty }.sorted()
    }
    
    private var uniqueShapes: [String] {
        Array(Set(allEntries.map { $0.shape })).filter { !$0.isEmpty }.sorted()
    }
    
    private var uniqueGlazes: [String] {
        Array(Set(allEntries.flatMap { $0.glazes })).filter { !$0.isEmpty }.sorted()
    }
    
    private func movePhotos(from source: IndexSet, to destination: Int) {
        var revisedPhotos = entry.sortedPhotos
        revisedPhotos.move(fromOffsets: source, toOffset: destination)
        
        for (index, photo) in revisedPhotos.enumerated() {
            photo.orderIndex = index
        }
    }
}

private struct GalleryThumbnail: View {
    let photo: PotteryPhoto
    let isSelected: Bool
    let isJiggling: Bool
    let onAction: () -> Void
    
    var body: some View {
        PhotoThumbnail(
            photo: photo,
            isJiggling: isJiggling,
            showTag: false,
            onDelete: onAction,
            size: 55
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onAction)
    }
}

#Preview {
    ContentView()
}
