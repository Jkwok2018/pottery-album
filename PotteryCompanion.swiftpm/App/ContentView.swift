import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PotteryEntry.date, order: .reverse) private var entries: [PotteryEntry]
    
    @State private var showingAddSheet = false
    @State private var searchText = ""

    var filteredEntries: [PotteryEntry] {
        if searchText.isEmpty {
            return entries
        } else {
            return entries.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.clayType.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredEntries) { entry in
                        NavigationLink(destination: EntryDetailView(entry: entry)) {
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
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Pottery Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("\(entries.count) items")
                        .font(.caption)
                        .foregroundStyle(.red)
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
                NavigationStack {
                    EntryFormView(entry: nil)
                }
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
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name.isEmpty ? "Untitled Piece" : entry.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !entry.clayType.isEmpty {
                    Text(entry.clayType)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
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
}
