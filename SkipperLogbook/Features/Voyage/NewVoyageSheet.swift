import SwiftUI

/// Starts a new voyage: name + optional destination name. Location is captured
/// live by the recorder once tracking begins.
struct NewVoyageSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(LocationManager.self) private var location
    @Environment(VoyageRecorder.self) private var recorder

    @State private var name: String = ""
    @State private var destination: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("voyage.details") {
                    TextField("voyage.name_placeholder", text: $name)
                    TextField("voyage.destination_placeholder", text: $destination)
                }
                Section {
                    Text("voyage.start_hint")
                        .font(AppFont.footnote)
                        .foregroundStyle(theme.inkSecondary)
                }
            }
            .navigationTitle("voyage.new_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("voyage.start") { start() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func start() {
        let voyageName = name.trimmingCharacters(in: .whitespaces)
        recorder.startVoyage(named: voyageName,
                             destination: nil,
                             destinationName: destination.isEmpty ? nil : destination)
        location.start()
        dismiss()
        router.select(.today)
    }
}
