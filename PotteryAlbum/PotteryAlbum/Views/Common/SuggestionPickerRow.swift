import SwiftUI
import PhotosUI

struct SuggestionPickerRow: View {
    let label: String
    @Binding var value: String
    let suggestions: [String]
    @Binding var enteringOther: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { enteringOther ? "Other" : (suggestions.contains(value) ? value : "Other") },
                    set: { newValue in
                        if newValue == "Other" {
                            enteringOther = true
                        } else {
                            enteringOther = false
                            value = newValue
                        }
                    }
                )) {
                    ForEach(suggestions, id: \.self) { s in
                        Text(s).tag(s)
                    }
                    Text("New...").tag("Other")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            
            if enteringOther || !suggestions.contains(value) || value.isEmpty {
                TextField("Enter new \(label.lowercased())", text: $value)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}
