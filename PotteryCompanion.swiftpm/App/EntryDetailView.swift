import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: PotteryEntry
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image or Gallery
                if !entry.photos.isEmpty {
                    TabView {
                        ForEach(entry.photos) { photo in
                            if let uiImage = UIImage(data: photo.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .overlay(alignment: .bottomLeading) {
                                        Text(photo.stageTag)
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .padding(6)
                                            .background(.black.opacity(0.6))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .padding(16)
                                    }
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 350)
                } else {
                    Rectangle()
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(height: 200)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.largeTitle)
                                    .foregroundStyle(.tertiary)
                                Text("No Photos")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.name)
                            .font(.system(size: 32, weight: .bold, design: .serif)) // Premium font choice
                            .foregroundStyle(.primary)
                        
                        Text(entry.date.formatted(date: .long, time: .omitted))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // Key Specs
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Specifications")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        HStack(spacing: 20) {
                            SpecCard(title: "Clay", value: entry.clayType, icon: "cube.fill")
                            SpecCard(title: "Firing", value: entry.firingMethod, icon: "flame.fill")
                        }
                    }
                    
                    // Detailed Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], alignment: .leading, spacing: 20) {
                        // Safely unwrap optional values or default to nil for the helper function to decide logic
                        if let weight = entry.clayWeight, weight > 0 {
                            DetailItem(label: "Weight", value: "\(String(format: "%.1f", weight)) lbs")
                        } else {
                            DetailItem(label: "Weight", value: "-")
                        }
                        
                        DetailItem(label: "Glazes", value: entry.glazes)
                        
                        DetailItem(label: "Shape", value: entry.shape.isEmpty ? "-" : entry.shape)
                    }
                    .padding(.vertical)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.vertical, 8)

                    
                    // Notes
                    if !entry.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            Text(entry.notes)
                                .font(.body)
                                .lineSpacing(4)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(uiColor: .yellow).opacity(0.1)) // Subtle note paper feel
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(20)
            }
        }
        .ignoresSafeArea(edges: entry.photos.isEmpty ? [] : .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                isEditing = true
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                EntryFormView(entry: entry)
            }
        }
    }
}

struct SpecCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "-" : value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}
