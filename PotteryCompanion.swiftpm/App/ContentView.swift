import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PotteryEntry.date, order: .reverse) private var entries: [PotteryEntry]
    
    @State private var showingAddSheet = false
    @State private var showingFilterSheet = false
    @State private var searchText = ""
    @State private var filterConfig = FilterConfig()
    @State private var path = NavigationPath()

    var filteredEntries: [PotteryEntry] {
        var result = entries
        
        // 1. Text Search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.glazes.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                $0.photos.contains { photo in photo.stageTag.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // 2. Filter by Clay Type
        if let clay = filterConfig.selectedClayType {
            result = result.filter { $0.clayType == clay }
        }
        
        // 3. Filter by Shape
        if let shape = filterConfig.selectedShape {
            result = result.filter { $0.shape == shape }
        }
        
        // 4. Filter by Weight
        if filterConfig.minWeight > 0 {
            result = result.filter { ($0.clayWeight ?? 0) >= filterConfig.minWeight }
        }
        
        // 5. Filter by Status
        if let status = filterConfig.selectedStatus {
            result = result.filter { $0.status == status }
        }
        
        return result
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                // Custom Search & Filter Header
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search names...", text: $searchText)
                    }
                    .padding(10)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    
                    Button(action: { showingFilterSheet = true }) {
                        Image(systemName: filterConfig.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                if filteredEntries.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(value: entry) {
                                PotteryCardView(entry: entry)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Pottery Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Reset button still useful in toolbar, or move to sheet? 
                    // Let's keep a small indicator/reset if active, it's helpful.
                    if filterConfig.isActive {
                        Button("Reset") {
                            withAnimation {
                                filterConfig = FilterConfig()
                            }
                        }
                        .font(.caption)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.tint)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                EntryFormView(entry: nil) { newEntry in
                    path.append(newEntry)
                }
                .modelContext(modelContext)
            }
            .navigationDestination(for: PotteryEntry.self) { entry in
                EntryDetailView(entry: entry)
            }
            .sheet(isPresented: $showingFilterSheet) {
                NavigationStack {
                    FilterSheet(config: $filterConfig, entries: entries)
                }
                .presentationDetents([.medium])
            }
        }
    }
}

struct FilterConfig: Equatable {
    var selectedClayType: String?
    var selectedShape: String?
    var selectedStatus: String?
    var minWeight: Double = 0
    
    var isActive: Bool {
        selectedClayType != nil || selectedShape != nil || selectedStatus != nil || minWeight > 0
    }
}

struct FilterSheet: View {
    @Binding var config: FilterConfig
    let entries: [PotteryEntry]
    @Environment(\.dismiss) private var dismiss
    
    var uniqueClayTypes: [String] {
        Array(Set(entries.map { $0.clayType })).filter { !$0.isEmpty }.sorted()
    }
    
    var uniqueShapes: [String] {
        Array(Set(entries.map { $0.shape })).filter { !$0.isEmpty }.sorted()
    }
    
    var maxWeightFound: Double {
        entries.compactMap { $0.clayWeight }.max() ?? 10.0
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Status", selection: $config.selectedStatus) {
                    Text("Any").tag(Optional<String>.none)
                    Text("In Progress").tag(Optional("In Progress"))
                    Text("Completed").tag(Optional("Completed"))
                    Text("Stopped").tag(Optional("Stopped"))
                }
                .pickerStyle(.menu)

                Picker("Clay Type", selection: $config.selectedClayType) {
                    Text("Any").tag(Optional<String>.none)
                    ForEach(uniqueClayTypes, id: \.self) { type in
                        Text(type).tag(Optional(type))
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Shape", selection: $config.selectedShape) {
                    Text("Any").tag(Optional<String>.none)
                    ForEach(uniqueShapes, id: \.self) { shape in
                        Text(shape).tag(Optional(shape))
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Criteria").font(.footnote).bold().foregroundStyle(.secondary)
            }
            
            Section {
                Slider(value: $config.minWeight, in: 0...max(5, maxWeightFound), step: 0.5) {
                    Text("Weight")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(Int(max(5, maxWeightFound)))")
                }
            } header: {
                Text("Minimum Weight: \(String(format: "%.1f", config.minWeight)) lbs").font(.footnote).bold().foregroundStyle(.secondary)
            }
            
            Section {
                Button("Clear All Filters", role: .destructive) {
                    config = FilterConfig()
                    dismiss()
                }
                .disabled(!config.isActive)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Filter Entries")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

struct PotteryCardView: View {
    let entry: PotteryEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Photo
            if let firstPhoto = entry.photos.first,
               let uiImage = UIImage(data: firstPhoto.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "camera.macro")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                    }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.name.isEmpty ? "Untitled Piece" : entry.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    // Status Badge
                    Text(entry.status)
                        .font(.footnote).bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(for: entry.status).opacity(0.1))
                        .foregroundStyle(statusColor(for: entry.status))
                        .clipShape(Capsule())
                    
                }
                .padding(.top, 2)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func statusColor(for status: String) -> Color {
        guard let stage = PotteryStage(rawValue: status) else { return .blue }
        switch stage {
        case .greenware: return .green
        case .trimmed: return .orange
        case .bisque: return .brown
        case .glazed: return .purple
        case .finished: return .blue
        }
    }
}
