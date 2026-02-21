import SwiftUI
import PhotosUI

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






