import SwiftUI
import SwiftData
import PhotosUI
import UserNotifications

struct EntryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Query to find existing clay types
    @Query private var allEntries: [PotteryEntry]
    
    var entry: PotteryEntry?
    var onSave: ((PotteryEntry) -> Void)? = nil
    
    @State private var path = NavigationPath()
    
    // Form State
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var dateTrimmed: Date?
    @State private var dateGlazed: Date?
    
    // Reminder State
    @State private var enableTrimReminder: Bool = false
    @State private var trimReminderDays: Int = 3
    
    @State private var clayType: String = ""
    @State private var clayWeight: Double?
    @State private var glazes: [String] = []
    @State private var notes: String = ""
    @State private var shape: String = ""
    @State private var status: String = PotteryStage.greenware.rawValue
    
    @State private var showingNewGlazeField = false
    @State private var newGlazeName = ""
    
    // Photo State
    @State private var selectedItem: PhotosUI.PhotosPickerItem?
    @State private var showingCamera = false
    @State private var temporaryPhotos: [PotteryPhoto] = []
    @State private var draggedPhoto: PotteryPhoto?
    @State private var showingAddPhotoOptions = false
    @State private var showingPhotosPicker = false
    @State private var isJiggling = false
    @State private var photoToDelete: PotteryPhoto?
    @State private var showingPhotoDeleteConfirmation = false
    
    @State private var enteringNewClayType = false
    @State private var enteringNewShape = false
    
    // Error Handling
    @State private var saveError: Error?
    @State private var showingError = false
    
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
        NavigationStack(path: $path) {
            formContent
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
                        dateTrimmed = entry.dateTrimmed
                        dateGlazed = entry.dateGlazed
                        enableTrimReminder = entry.enableTrimReminder
                        trimReminderDays = entry.trimReminderDays
                        
                        clayType = entry.clayType
                        clayWeight = entry.clayWeight
                        glazes = entry.glazes
                        notes = entry.notes
                        shape = entry.shape
                        status = entry.status
                    }
                }
                .navigationDestination(for: PhotoDraft.self) { draft in
                    PhotoMetadataView(item: draft.item, preloadedData: draft.preloadedData) { data, tag, note in
                        let newPhoto = PotteryPhoto(imageData: data, stageTag: tag, note: note)
                        if let entry = entry {
                            newPhoto.orderIndex = entry.photos.count
                            entry.photos.append(newPhoto)
                            entry.updateStatusFromPhotos()
                            status = entry.status
                        } else {
                            newPhoto.orderIndex = temporaryPhotos.count
                            temporaryPhotos.append(newPhoto)
                            updateStatusFromTemporaryPhotos()
                        }
                        path.removeLast()
                    }
                }
                .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedItem, matching: .images)
                .alert("Save Failed", isPresented: $showingError, actions: {
                    Button("OK", role: .cancel) { }
                }, message: {
                    Text(saveError?.localizedDescription ?? "Unknown error")
                })
                .alert("Delete Photo?", isPresented: $showingPhotoDeleteConfirmation, presenting: photoToDelete) { photo in
                    Button("Delete", role: .destructive) {
                        if let entry = entry {
                            deletePhoto(photo, from: entry)
                        } else {
                            deleteTemporaryPhoto(photo)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: { _ in
                    Text("Are you sure you want to remove this photo?")
                }
                .onChange(of: selectedItem) { oldValue, newValue in
                    if let newValue = newValue {
                        let draft = PhotoDraft(item: newValue)
                        DispatchQueue.main.async {
                            path.append(draft)
                        }
                        selectedItem = nil
                    }
                }
                .sheet(isPresented: $showingCamera) {
                    ImagePicker { image in
                        if let data = image.jpegData(compressionQuality: 0.8) {
                            let draft = PhotoDraft(data: data)
                            DispatchQueue.main.async {
                                path.append(draft)
                            }
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            generalInfoSection
            specsSection
            processSection
            photosSection
            remindersSection
        }
        .scrollContentBackground(.hidden)
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
    }
    
    @ViewBuilder
    private var generalInfoSection: some View {
        Section {
            TextField("Title (e.g., Blue Bowl)", text: $name)
            
            HStack {
                Text("Status")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $status) {
                    ForEach(PotteryStage.allCases, id: \.self) { stage in
                        Text(stage.rawValue).tag(stage.rawValue)
                    }
                }
                .labelsHidden()
            }
            
            HStack {
                Text("Date Created")
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
            }
            OptionalDatePickerRow(label: "Date Trimmed", selection: $dateTrimmed)
            OptionalDatePickerRow(label: "Date Glazed", selection: $dateGlazed)
        } header: {
            Text("📝 General Info").font(.footnote).bold().foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var specsSection: some View {
        Section {
            shapePicker
            clayTypePicker
            weightField
            glazeManagementView
        } header: {
            Text("🏗️ Specs").font(.footnote).bold().foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var clayTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Clay Type")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { enteringNewClayType ? "Other" : (uniqueClayTypes.contains(clayType) ? clayType : "Other") },
                    set: { newValue in
                        if newValue == "Other" {
                            enteringNewClayType = true
                        } else {
                            enteringNewClayType = false
                            clayType = newValue
                        }
                    }
                )) {
                    ForEach(uniqueClayTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                    Text("New Type...").tag("Other")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            
            if enteringNewClayType || !uniqueClayTypes.contains(clayType) || clayType.isEmpty {
                TextField("Enter new clay type", text: $clayType)
            }
        }
    }
    
    @ViewBuilder
    private var shapePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Shape")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { enteringNewShape ? "Other" : (uniqueShapes.contains(shape) ? shape : "Other") },
                    set: { newValue in
                        if newValue == "Other" {
                            enteringNewShape = true
                        } else {
                            enteringNewShape = false
                            shape = newValue
                        }
                    }
                )) {
                    ForEach(uniqueShapes, id: \.self) { s in
                        Text(s).tag(s)
                    }
                    Text("New Shape...").tag("Other")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            
            if enteringNewShape || !uniqueShapes.contains(shape) || shape.isEmpty {
                TextField("Enter new shape (e.g., Mug)", text: $shape)
            }
        }
    }
    
    @ViewBuilder
    private var weightField: some View {
        HStack {
            Text("Weight (lbs)")
                .foregroundStyle(.secondary)
            Spacer()
            TextField("Optional", value: $clayWeight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
    
    @ViewBuilder
    private var processSection: some View {
        Section {
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("📓 Notes").font(.footnote).bold().foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var glazeManagementView: some View {
        VStack(alignment: .leading, spacing: 12) {
            glazeFlowList
            glazePickerRow
        }
    }
    
    @ViewBuilder
    private var glazeFlowList: some View {
        if !glazes.isEmpty {
            FlowLayout(spacing: 8) {
                ForEach(glazes, id: \.self) { glaze in
                    HStack(spacing: 4) {
                        Text(glaze)
                            .font(.subheadline)
                        Button {
                            glazes.removeAll { $0 == glaze }
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
    
    @ViewBuilder
    private var glazePickerRow: some View {
        HStack {
            Picker("Add Glaze", selection: Binding(
                get: { "Add Glaze..." },
                set: { newValue in
                    if newValue == "New..." {
                        showingNewGlazeField = true
                    } else if newValue != "Add Glaze..." && !glazes.contains(newValue) {
                        glazes.append(newValue)
                    }
                }
            )) {
                Text("Add Glaze...").tag("Add Glaze...")
                ForEach(uniqueGlazes, id: \.self) { g in
                    if !glazes.contains(g) {
                        Text(g).tag(g)
                    }
                }
                Text("New...").tag("New...")
            }
            .pickerStyle(.menu)
            .labelsHidden()
            
            if showingNewGlazeField {
                TextField("Glaze name", text: $newGlazeName, onCommit: {
                    if !newGlazeName.isEmpty && !glazes.contains(newGlazeName) {
                        glazes.append(newGlazeName)
                        newGlazeName = ""
                        showingNewGlazeField = false
                    }
                })
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
                
                Button {
                    showingNewGlazeField = false
                    newGlazeName = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var remindersSection: some View {
        Section {
            Toggle("Reminder to Trim", isOn: $enableTrimReminder)
            
            if enableTrimReminder {
                HStack {
                    Text("Days after created")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("Days", value: $trimReminderDays, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        } header: {
            Text("🔔 Reminders").font(.footnote).bold().foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var photosSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if let entry = entry {
                        ForEach(entry.sortedPhotos) { photo in
                            PhotoThumbnail(photo: photo, isJiggling: isJiggling) {
                                photoToDelete = photo
                                showingPhotoDeleteConfirmation = true
                            }
                            .jiggle(isActive: isJiggling)
                            .opacity(draggedPhoto == photo ? 0.5 : 1.0)
                            .onDrag {
                                self.draggedPhoto = photo
                                return NSItemProvider(object: photo.id.uuidString as NSString)
                            }
                            .onDrop(of: [.text], delegate: PhotoDropDelegate(item: photo, photos: entry.sortedPhotos, draggedItem: $draggedPhoto, onMove: moveExistingPhotos))
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.5)
                                    .onEnded { _ in
                                        withAnimation {
                                            isJiggling = true
                                        }
                                    }
                            )
                        }
                    }
                    
                    ForEach(temporaryPhotos) { photo in
                        PhotoThumbnail(photo: photo, isJiggling: isJiggling) {
                            photoToDelete = photo
                            showingPhotoDeleteConfirmation = true
                        }
                        .jiggle(isActive: isJiggling)
                        .opacity(draggedPhoto == photo ? 0.5 : 1.0)
                        .onDrag {
                            self.draggedPhoto = photo
                            return NSItemProvider(object: photo.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: PhotoDropDelegate(item: photo, photos: temporaryPhotos, draggedItem: $draggedPhoto, onMove: moveTemporaryPhotos))
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    withAnimation {
                                        isJiggling = true
                                    }
                                }
                        )
                    }
                    
                    Button {
                        showingAddPhotoOptions = true
                    } label: {
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
                    .confirmationDialog("Add Photo", isPresented: $showingAddPhotoOptions) {
                        Button("Take Photo") {
                            showingCamera = true
                        }
                        Button("Choose from Library") {
                            showingPhotosPicker = true
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        } header: {
            Text("📸 Photos").font(.footnote).bold().foregroundStyle(.secondary)
        }
    }

    struct PhotoDraft: Identifiable, Hashable {
        let id = UUID()
        let item: PhotosUI.PhotosPickerItem?
        let preloadedData: Data?
        
        init(item: PhotosUI.PhotosPickerItem) {
            self.item = item
            self.preloadedData = nil
        }
        
        init(data: Data) {
            self.item = nil
            self.preloadedData = data
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: PhotoDraft, rhs: PhotoDraft) -> Bool {
            lhs.id == rhs.id
        }
    }

    private var uniqueGlazes: [String] {
        Array(Set(allEntries.flatMap { $0.glazes })).filter { !$0.isEmpty }.sorted()
    }

    private func save() {
        do {
            let savedEntry: PotteryEntry
            if let entry = entry {
                entry.name = name
                entry.date = date
                entry.dateTrimmed = dateTrimmed
                entry.dateGlazed = dateGlazed
                entry.enableTrimReminder = enableTrimReminder
                entry.trimReminderDays = trimReminderDays
                
                entry.clayType = clayType
                entry.clayWeight = clayWeight
                entry.glazes = glazes
                entry.notes = notes
                entry.shape = shape
                entry.status = status
                
                scheduleNotifications(for: entry)
                savedEntry = entry
            } else {
                let newEntry = PotteryEntry(name: name, date: date)
                newEntry.dateTrimmed = dateTrimmed
                newEntry.dateGlazed = dateGlazed
                newEntry.enableTrimReminder = enableTrimReminder
                newEntry.trimReminderDays = trimReminderDays
                
                newEntry.clayType = clayType
                newEntry.clayWeight = clayWeight
                newEntry.glazes = glazes
                newEntry.notes = notes
                newEntry.shape = shape
                newEntry.status = status
                
                // Add temporary photos with correct order indices
                for (index, photo) in temporaryPhotos.enumerated() {
                    photo.orderIndex = index
                    newEntry.photos.append(photo)
                }
                
                modelContext.insert(newEntry)
                
                scheduleNotifications(for: newEntry)
                savedEntry = newEntry
            }
            try modelContext.save()
            onSave?(savedEntry)
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
            entry.updateStatusFromPhotos()
            status = entry.status
        }
    }
    
    private func deleteTemporaryPhoto(_ photo: PotteryPhoto) {
        if let index = temporaryPhotos.firstIndex(of: photo) {
            temporaryPhotos.remove(at: index)
            updateStatusFromTemporaryPhotos()
        }
    }
    
    private func updateStatusFromTemporaryPhotos() {
        let stages = temporaryPhotos.compactMap { PotteryStage(rawValue: $0.stageTag) }
        if let latestStage = stages.max() {
            status = latestStage.rawValue
        }
    }

    private func scheduleNotifications(for entry: PotteryEntry) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications for this entry
        center.removePendingNotificationRequests(withIdentifiers: [
            "\(entry.id.uuidString)-trim"
        ])
        
        guard entry.enableTrimReminder else { return }
        
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Pottery Reminder"
            content.body = "Time to trim \"\(entry.name)\"! It was created \(entry.trimReminderDays) days ago."
            content.sound = .default
            
            let triggerDate = Calendar.current.date(byAdding: .day, value: entry.trimReminderDays, to: entry.date) ?? entry.date
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(identifier: "\(entry.id.uuidString)-trim", content: content, trigger: trigger)
        }
    }
    
    private func moveExistingPhotos(from source: IndexSet, to destination: Int) {
        guard let entry = entry else { return }
        var revisedPhotos = entry.sortedPhotos
        revisedPhotos.move(fromOffsets: source, toOffset: destination)
        for (index, photo) in revisedPhotos.enumerated() {
            photo.orderIndex = index
        }
    }
    
    private func moveTemporaryPhotos(from source: IndexSet, to destination: Int) {
        temporaryPhotos.move(fromOffsets: source, toOffset: destination)
    }
}

struct PhotoThumbnail: View {
    let photo: PotteryPhoto
    var isJiggling: Bool = false
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
            
            Text(photo.stageTag)
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(4)
                .background(.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            
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
        .frame(width: 100, height: 100)
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

