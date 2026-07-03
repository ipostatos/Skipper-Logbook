import SwiftUI
import SwiftData

/// Composes a rich log entry: event type, free-text note, wind (direction +
/// speed), and — for sail events — mainsail / jib set percentages. Position &
/// heading are captured from the current fix.
struct AddLogEventSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(LocationManager.self) private var location
    @Environment(VoyageRecorder.self) private var recorder
    @Environment(AppState.self) private var appState

    @State private var type: LogEventType = .note
    @State private var note: String = ""
    @State private var windDirection: String = ""
    @State private var windSpeed: String = ""
    @State private var mainsail: Double = 100
    @State private var jib: Double = 100
    @State private var includeSails = false

    private let selectableTypes: [LogEventType] = [
        .note, .engineOn, .engineOff, .sailsUp, .sailsDown, .reef,
        .turnToWaypoint, .waypointReached, .anchorDown, .anchorUp, .weather
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("event.type") {
                    Picker("event.type", selection: $type) {
                        ForEach(selectableTypes) { t in
                            Label(t.titleKey, systemImage: t.symbol).tag(t)
                        }
                    }
                    .onChange(of: type) { _, newValue in
                        includeSails = newValue.carriesSailState
                    }
                }

                Section("event.note") {
                    TextField("event.note_placeholder", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("event.wind") {
                    TextField("event.wind_direction", text: $windDirection)
                    TextField("event.wind_speed_kn", text: $windSpeed)
                        .keyboardType(.numberPad)
                }

                Section {
                    Toggle("event.include_sails", isOn: $includeSails)
                    if includeSails {
                        sailSlider("status.mainsail", value: $mainsail)
                        sailSlider("status.jib", value: $jib)
                    }
                }
            }
            .navigationTitle("event.add_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { save() }
                }
            }
        }
    }

    private func sailSlider(_ label: LocalizedStringKey, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label).font(AppFont.subheadline)
                Spacer()
                Text("\(Int(value.wrappedValue))%")
                    .font(AppFont.subheadline.monospacedDigit())
                    .foregroundStyle(theme.inkSecondary)
            }
            Slider(value: value, in: 0...100, step: 5)
        }
    }

    private func save() {
        let coord = location.currentCoordinate
        let windKn = Double(windSpeed)
        let main = includeSails ? Int(mainsail) : nil
        let jibPct = includeSails ? Int(jib) : nil

        if recorder.isRecording {
            recorder.addEvent(type,
                              at: coord,
                              heading: location.effectiveHeading,
                              speedKn: Units.mpsToKnots(location.speedMps),
                              note: note.isEmpty ? nil : note,
                              windDirection: windDirection.isEmpty ? nil : windDirection,
                              windSpeedKn: windKn,
                              mainsailPercent: main,
                              jibPercent: jibPct)
        } else {
            // No active voyage — persist a standalone entry attached to nothing.
            let event = LogEvent(type: type,
                                 latitude: coord?.latitude, longitude: coord?.longitude,
                                 headingDegrees: location.effectiveHeading,
                                 speedKnots: Units.mpsToKnots(location.speedMps),
                                 note: note.isEmpty ? nil : note,
                                 windDirection: windDirection.isEmpty ? nil : windDirection,
                                 windSpeedKn: windKn,
                                 mainsailPercent: main, jibPercent: jibPct)
            context.insert(event)
            try? context.save()
        }

        // Reflect sail state in the dashboard chips.
        if includeSails { appState.mainsailPercent = main; appState.jibPercent = jibPct }
        dismiss()
    }
}
