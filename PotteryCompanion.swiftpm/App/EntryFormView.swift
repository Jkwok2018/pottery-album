import SwiftUI
import SwiftData
import PhotosUI

struct EntryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Query to find existing clay types
    @Query private var allEntries: [PotteryEntry]
    
    var entry: PotteryEntry?
    
    // Form State
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var clayType: String = ""
    @State private var clayWeight: Double?
    @State private var firingMethod: String = ""
    @State private var glazes: String = ""
    @State private var notes: String = ""
    @State private var shape: String = ""
    @State private var status: String = "In Progress"
    
    // Photo State
    @State private var selectedItem: PhotosPickerItem?
    @State private var temporaryPhotos: [PotteryPhoto] = []
    @State private var pendingPhoto: PhotoDraft?
    
    var uniqueClayTypes: [String] {
        Array(Set(allEntries.map { $0.clayType }))
            .filter { !$0.isEmpty }
            .sorted()
    }
    
    var uniqueShapes: [String] {
        Array(Set(allEntries.map { $0.shape }))
            .filter { !$0.isEmpty }
            .sorted()
    }
    
    var body: some View {
        Form {
            Section("General Info") {
                TextField("Title (e.g., Blue Bowl)", text: $name)
                DatePicker("Date Created", selection: $date, displayedComponents: .date)
                
                Picker("Status", selection: $status) {
                    Text("In Progress").tag("In Progress")
                    Text("Completed").tag("Completed")
                    Text("Stopped").tag("Stopped")
                }
            }
            
            Section("Specs") {
                // Clay Type with Suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Clay Type", selection: Binding(
                        get: { uniqueClayTypes.contains(clayType) ? clayType : "Other" },
                        set: { newValue in
                            if newValue != "Other" {
                                clayType = newValue
                            }
                        }
                    )) {
                        ForEach(uniqueClayTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                        Text("New Type...").tag("Other")
                    }
                    .pickerStyle(.menu)
                    
                    // Show text field if "New Type..." is selected or if the current value isn't in our list
                    if !uniqueClayTypes.contains(clayType) || clayType.isEmpty {
                        TextField("Enter new clay type", text: $clayType)
                    }
                }
                
                // Shape with Suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Shape", selection: Binding(
                        get: { uniqueShapes.contains(shape) ? shape : "Other" },
                        set: { newValue in
                            if newValue != "Other" {
                                shape = newValue
                            }
                        }
                    )) {
                        ForEach(uniqueShapes, id: \.self) { s in
                            Text(s).tag(s)
                        }
                        Text("New Shape...").tag("Other")
                    }
                    .pickerStyle(.menu)
                    
                    if !uniqueShapes.contains(shape) || shape.isEmpty {
                        TextField("Enter new shape (e.g., Mug)", text: $shape)
                    }
                }
                
                HStack {
                    Text("Weight (lbs)")
                    Spacer()
                    TextField("Optional", value: $clayWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }
            }
            
            Section("Process") {
                TextField("Firing Method (e.g. Cone 6 Electric)", text: $firingMethod)
                TextField("Glazes Used", text: $glazes)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Photos") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Existing Photos
                        if let entry = entry {
                            ForEach(entry.photos) { photo in
                                PhotoThumbnail(photo: photo) {
                                    deletePhoto(photo, from: entry)
                                }
                            }
                        }
                        
                        // New Photos
                        ForEach(temporaryPhotos) { photo in
                            PhotoThumbnail(photo: photo) {
                                deleteTemporaryPhoto(photo)
                            }
                        }
                        
                        // Add Button
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                            .foregroundStyle(.secondary)
                                    )
                                Image(systemName: "plus")
                                    .font(.largeTitle)
                                    .foregroundStyle(.tint)
                            }
                        }
                        .onChange(of: selectedItem) { oldValue, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    pendingPhoto = PhotoDraft(data: data)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(name.isEmpty)
            }
        }
        .onAppear {
            if let entry = entry {
                name = entry.name
                date = entry.date
                clayType = entry.clayType
                clayWeight = entry.clayWeight
                firingMethod = entry.firingMethod
                glazes = entry.glazes
                notes = entry.notes
                shape = entry.shape
                status = entry.status
            }
        }
        .sheet(item: $pendingPhoto) { draft in
            PhotoMetadataView(imageData: draft.data) { tag, note in
                let newPhoto = PotteryPhoto(imageData: draft.data, stageTag: tag, note: note)
                if let entry = entry {
                    // If editing existing, add directly
                    entry.photos.append(newPhoto)
                } else {
                    // If new, add to temp
                    temporaryPhotos.append(newPhoto)
                }
                selectedItem = nil
                pendingPhoto = nil
            }
        }
        .alert("Save Failed", isPresented: $showingError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(saveError?.localizedDescription ?? "Unknown error")
        })
    }

    struct PhotoDraft: Identifiable {
        let id = UUID()
        let data: Data
    }
        
    @State private var saveError: Error?
    @State private var showingError = false

    private func save() {
        do {
            if let entry = entry {
                // Update existing
                entry.name = name
                entry.date = date
                entry.clayType = clayType
                entry.clayWeight = clayWeight
                entry.firingMethod = firingMethod
                entry.glazes = glazes
                entry.notes = notes
                entry.shape = shape
                entry.status = status
            } else {
                // Create new
                let newEntry = PotteryEntry(name: name, date: date)
                newEntry.clayType = clayType
                newEntry.clayWeight = clayWeight
                newEntry.firingMethod = firingMethod
                newEntry.glazes = glazes
                newEntry.notes = notes
                newEntry.shape = shape
                newEntry.status = status
                newEntry.photos = temporaryPhotos
                modelContext.insert(newEntry)
            }
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving entry: \(error)")
            saveError = error
            showingError = true
        }
    }
    
    private func deletePhoto(_ photo: PotteryPhoto, from entry: PotteryEntry) {
        if let index = entry.photos.firstIndex(of: photo) {
            entry.photos.remove(at: index)
            modelContext.delete(photo)
        }
    }
    
    private func deleteTemporaryPhoto(_ photo: PotteryPhoto) {
        if let index = temporaryPhotos.firstIndex(of: photo) {
            temporaryPhotos.remove(at: index)
        }
    }
}

struct PhotoThumbnail: View {
    let photo: PotteryPhoto
    var onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Tag Label
            Text(photo.stageTag)
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(4)
                .background(.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .red)
                    .font(.title3)
            }
            .padding(-6)
        }
        .frame(width: 100, height: 100)
    }
}
