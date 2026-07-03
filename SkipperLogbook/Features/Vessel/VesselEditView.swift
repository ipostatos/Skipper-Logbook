import SwiftUI
import SwiftData
import PhotosUI

/// Edit form for the vessel, including a PhotosPicker for the boat photo.
struct VesselEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var vessel: Vessel

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("vessel.photo") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("vessel.choose_photo", systemImage: "photo")
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task { await loadPhoto(newItem) }
                    }
                }

                Section("vessel.identity") {
                    TextField("vessel.name", text: $vessel.name)
                    TextField("vessel.type", text: $vessel.type)
                    Toggle("vessel.is_sail", isOn: $vessel.isSail)
                    TextField("vessel.registration", text: Binding.optionalText($vessel.registration))
                    TextField("vessel.mmsi", text: Binding.optionalText($vessel.mmsi))
                    TextField("vessel.call_sign", text: Binding.optionalText($vessel.callSign))
                }

                Section("vessel.dimensions") {
                    numberField("vessel.length", $vessel.lengthMeters)
                    numberField("vessel.beam", $vessel.beamMeters)
                    numberField("vessel.draft", $vessel.draftMeters)
                }

                Section("vessel.machinery") {
                    TextField("vessel.engine", text: Binding.optionalText($vessel.engineModel))
                    numberField("vessel.fuel_tank", $vessel.fuelCapacityLiters)
                    numberField("vessel.water_tank", $vessel.waterCapacityLiters)
                }

                Section("vessel.notes") {
                    TextField("vessel.notes_placeholder", text: $vessel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("vessel.edit_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { try? context.save(); dismiss() }
                }
            }
        }
    }

    private func numberField(_ label: LocalizedStringKey, _ value: Binding<Double?>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return }
        vessel.photoData = data
    }
}
