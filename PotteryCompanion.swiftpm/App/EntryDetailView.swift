import SwiftUI
import SwiftData
import PhotosUI

struct EntryDetailView: View {
    @Bindable var entry: PotteryEntry
    @State private var isEditing = false
    @State private var selectedPhoto: PotteryPhoto?
    @State private var selectedItem: PhotosUI.PhotosPickerItem?
    @State private var pendingPhoto: EntryFormView.PhotoDraft?
    
    @State private var showingNewGlazeField = false
    @State private var newGlazeName = ""
    
    @Query private var allEntries: [PotteryEntry]
    
    @Environment(\.modelContext) private var modelContext
    
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
        VStack(alignment: .leading, spacing: 16) {
            Text("📸 PHOTOS")
                .font(.footnote).bold()
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            
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
        VStack(spacing: 0) {
            HStack {
                Text("Shape")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { enteringNewShape ? "Other" : (uniqueShapes.contains(entry.shape) ? entry.shape : "Other") },
                    set: { newValue in
                        if newValue == "Other" {
                            enteringNewShape = true
                        } else {
                            enteringNewShape = false
                            entry.shape = newValue
                        }
                    }
                )) {
                    ForEach(uniqueShapes, id: \.self) { s in
                        Text(s).tag(s)
                    }
                    Text("New...").tag("Other")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .padding()
            
            if enteringNewShape || !uniqueShapes.contains(entry.shape) || entry.shape.isEmpty {
                Divider().padding(.horizontal)
                TextField("Enter new shape", text: $entry.shape)
                    .padding()
                    .background(Color(uiColor: .tertiarySystemFill).opacity(0.3))
            }
        }
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
        VStack(spacing: 0) {
            Divider().padding(.horizontal)
            HStack {
                Text("Clay")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { enteringNewClayType ? "Other" : (uniqueClayTypes.contains(entry.clayType) ? entry.clayType : "Other") },
                    set: { newValue in
                        if newValue == "Other" {
                            enteringNewClayType = true
                        } else {
                            enteringNewClayType = false
                            entry.clayType = newValue
                        }
                    }
                )) {
                    ForEach(uniqueClayTypes, id: \.self) { t in
                        Text(t).tag(t)
                    }
                    Text("New...").tag("Other")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .padding()
            
            if enteringNewClayType || !uniqueClayTypes.contains(entry.clayType) || entry.clayType.isEmpty {
                Divider().padding(.horizontal)
                TextField("Enter new clay type", text: $entry.clayType)
                    .padding()
                    .background(Color(uiColor: .tertiarySystemFill).opacity(0.3))
            }
        }
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
                        HStack(spacing: 4) {
                            Text(glaze)
                                .font(.subheadline)
                            Button {
                                entry.glazes.removeAll { $0 == glaze }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.1))
                        .clipShape(Capsule())
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
